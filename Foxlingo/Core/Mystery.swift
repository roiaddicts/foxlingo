import Foundation

public struct MysteryClue: Codable, Sendable {
    public let label: String
    public let predicate: String?
    public let contextEntityID: UUID?
    public let factID: UUID?
    public let comparisonFactIDs: [UUID]
    public let initials: Bool
}
public struct MysteryDefinition: Codable, Identifiable, Sendable {
    public let id: UUID
    public let key: String
    public let subjectID: UUID
    public let clues: [MysteryClue]
}
public struct MysteryRound: Identifiable, Sendable {
    public var id: UUID {definition.id}
    public let definition: MysteryDefinition
    public let player: Entity
    public let facts: [UUID:Fact]
    public let sources: [Source]
    public static func initials(_ entity: Entity) -> String {entity.name.split(whereSeparator: \.isWhitespace).compactMap(\.first).map(String.init).joined()}
    public func value(at index: Int) -> String {
        let clue=definition.clues[index]
        return clue.initials ? Self.initials(player) : facts[clue.factID!]!.value.display
    }
    public func visualType(at index: Int,pack: ContentPack) -> String? {
        guard let id=definition.clues[index].factID,let fact=facts[id] else {return nil}
        if fact.predicate == "country" {return "country"}
        guard let entity=fact.value.entityID else {return nil}
        let type=pack.entity(entity).type
        return ["club","player"].contains(type) ? type : nil
    }
    public func scope(at index: Int) -> String? {
        guard let id=definition.clues[index].factID,let fact=facts[id] else {return nil}
        return fact.scope
    }
}
public enum MysteryDeck {
    public static func load(_ data: Data,pack: ContentPack) throws -> [MysteryRound] {
        let definitions=try JSONDecoder().decode([MysteryDefinition].self,from:data)
        guard Set(definitions.map(\.id)).count == definitions.count,Set(definitions.map(\.key)).count == definitions.count,
              Set(definitions.map(\.subjectID)).count == definitions.count else {throw ContentError.invalid("Duplicate mystery players.")}
        let facts=Dictionary(uniqueKeysWithValues:pack.facts.map {($0.id,$0)})
        // A delivered curriculum may retire a subject/fact. Hide its affected rounds safely.
        let compatible=definitions.compactMap {definition -> MysteryRound? in
            guard let subject=pack.entities.first(where:{$0.id == definition.subjectID && $0.type == "player"}),
                  definition.clues.count == 3,definition.clues.last?.initials == true,
                  definition.clues.dropLast().allSatisfy({!$0.initials && $0.factID != nil}),
                  definition.clues.allSatisfy({!$0.label.isEmpty}) else {return nil}
            func mentionsSubject(_ text: String) -> Bool {
                func words(_ value: String) -> String {Recall.normalize(value).components(separatedBy:CharacterSet.alphanumerics.inverted).filter {!$0.isEmpty}.joined(separator:" ")}
                let haystack=" "+words(text)+" "
                return ([subject.name]+subject.aliases).contains {name in
                    let needle=words(name)
                    return !needle.isEmpty && haystack.contains(" "+needle+" ")
                }
            }
            var comparable: [UUID:Fact]=[:]
            for clue in definition.clues.dropLast() {
                guard let id=clue.factID,let fact=facts[id],fact.subjectID == subject.id,fact.predicate == clue.predicate,
                      fact.value.entityID != subject.id,
                      !mentionsSubject(fact.value.display),!mentionsSubject(fact.scope),!mentionsSubject(clue.label),!clue.comparisonFactIDs.isEmpty,clue.comparisonFactIDs.contains(id) else {return nil}
                if let context=clue.contextEntityID,!pack.entities.contains(where:{$0.id == context && $0.type == "club"}) {return nil}
                for otherID in clue.comparisonFactIDs {
                    guard let other=facts[otherID],other.predicate == fact.predicate,
                          pack.entities.contains(where:{$0.id == other.subjectID && $0.type == "player"}),
                          // Missing or changed comparison evidence becomes unknown.
                          other.predicate == "position" || other.scope == fact.scope else {continue}
                    comparable[otherID]=other
                }
            }
            let references=definition.clues.flatMap(\.comparisonFactIDs).compactMap {comparable[$0]}
            let sourceKeys=Set(references.flatMap(\.sourceKeys))
            return MysteryRound(definition:definition,player:subject,facts:comparable,sources:pack.sources.filter {sourceKeys.contains($0.key)})
        }
        guard Set(compatible.map {MysteryRound.initials($0.player)}).count == compatible.count else {throw ContentError.invalid("Mystery initials do not distinguish this player pool.")}
        return compatible
    }
}
public struct MysteryTurn: Sendable {
    public enum Guess: Equatable {case identified,moreClues,contradicted,ignored}
    public private(set) var revealed=1
    public private(set) var solved=false
    public private(set) var guesses=0
    public init() {}
    public mutating func reveal(in round: MysteryRound) {guard !solved else {return};revealed=min(round.definition.clues.count,revealed+1)}
    public mutating func guess(_ player: Entity,in round: MysteryRound) -> Guess {
        guard !solved else {return .ignored}
        guesses += 1
        if player.id == round.player.id {solved=true;return .identified}
        for clue in round.definition.clues.prefix(revealed) {
            if clue.initials {
                if MysteryRound.initials(player) != MysteryRound.initials(round.player) {return .contradicted}
            } else if let id=clue.factID,let expected=round.facts[id] {
                let known=clue.comparisonFactIDs.compactMap {round.facts[$0]}.filter {$0.subjectID == player.id}
                // No recorded fact means unknown, not a negative football claim.
                if !known.isEmpty && !known.contains(where:{Recall.normalize($0.value.display) == Recall.normalize(expected.value.display)}) {return .contradicted}
            }
        }
        reveal(in:round);return .moreClues
    }
}
