import Foundation

public struct MemoryPairDefinition: Codable, Sendable {
    public let key: String
    public let subjectID: UUID
    public let factID: UUID?
    public let label: String?
}
public struct MemoryGamePair: Identifiable, Sendable {
    public var id: String {definition.key}
    public let definition: MemoryPairDefinition
    public let subject: Entity
    public let fact: Fact?
    public var answer: String {fact.map {"\($0.value.display)\n\(definition.label ?? "")"} ?? subject.name}
    public var relationship: Pair {Pair(left:id+"-image",right:id+"-answer")}
}
public struct MemoryProgress: Codable, Sendable {
    public let order: [String]
    public let matched: [String]
    public let moves: Int
    public init(order: [String],matched: [String],moves: Int) {self.order=order;self.matched=matched;self.moves=moves}
}
public enum MemoryGameDeck {
    public static func load(_ data: Data,pack: ContentPack) throws -> [MemoryGamePair] {
        let definitions=try JSONDecoder().decode([MemoryPairDefinition].self,from:data)
        guard definitions.count == 8,Set(definitions.map(\.key)).count == 8,Set(definitions.map(\.subjectID)).count == 8 else {throw ContentError.invalid("Memory requires eight distinct image pairs.")}
        let pairs=try definitions.map {definition -> MemoryGamePair in
            guard !definition.key.isEmpty,let subject=pack.entities.first(where:{$0.id == definition.subjectID}),["club","player"].contains(subject.type),subject.imageAsset != nil else {throw ContentError.invalid("Memory pair is missing its image.")}
            var fact: Fact?
            if let id=definition.factID {
                guard let found=pack.facts.first(where:{$0.id == id && $0.subjectID == subject.id}),found.value.kind == "number",let label=definition.label,!label.isEmpty else {throw ContentError.invalid("Memory stat must belong to its pictured subject.")}
                fact=found
            }
            return MemoryGamePair(definition:definition,subject:subject,fact:fact)
        }
        guard Set(pairs.map {Recall.normalize($0.answer)}).count == 8 else {throw ContentError.invalid("Memory answers must distinguish each pair.")}
        return pairs
    }
    public static func signature(_ pairs: [MemoryGamePair]) -> String {
        var data=Data()
        for pair in pairs.sorted(by:{$0.id < $1.id}) {
            data.append(ContentUpdateRules.bytes(pair.definition));data.append(ContentUpdateRules.bytes(pair.subject.name))
            if let fact=pair.fact {data.append(ContentUpdateRules.bytes(fact.value));data.append(ContentUpdateRules.bytes(fact.scope))}
        }
        return ContentUpdateRules.digest(data)
    }
    public static func restore(_ resume: GameResume,pairs: [MemoryGamePair],completedSessions: Set<UUID>) -> MemoryProgress? {
        let ids=Set(pairs.flatMap {[$0.relationship.left,$0.relationship.right]})
        guard resume.schemaVersion == 1,resume.signature == signature(pairs),resume.board == nil,resume.mystery == nil,!completedSessions.contains(resume.sessionID),let progress=resume.memory,
              progress.order.count == 16,Set(progress.order) == ids,
              Set(progress.matched).count == progress.matched.count,progress.matched.count < 8,
              Set(progress.matched).isSubset(of:Set(pairs.map { $0.relationship.left })),progress.moves >= progress.matched.count,progress.moves <= 100_000 else {return nil}
        return progress
    }
}
