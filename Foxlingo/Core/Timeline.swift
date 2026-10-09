import Foundation

public struct TimelineEventDefinition: Codable, Identifiable, Sendable {
    public let id: String
    public let factID: UUID
    public let title: String
}
public struct TimelineDefinition: Codable, Identifiable, Sendable {
    public let id: String
    public let subjectID: UUID
    public let title: String
    public let events: [TimelineEventDefinition]
}
public struct TimelineEvent: Identifiable, Sendable {
    public var id: String {definition.id}
    public let definition: TimelineEventDefinition
    public let fact: Fact
    public let subject: Entity
    public let year: Int
}
public struct TimelineRound: Identifiable, Sendable {
    public var id: String {definition.id}
    public let definition: TimelineDefinition
    public let subject: Entity
    public let events: [TimelineEvent]
    public var answer: [String] {events.sorted {$0.year < $1.year}.map(\.id)}
    public func accepts(_ order: [String]) -> Bool {order == answer}
    public func shuffledOrder() -> [String] {
        let shuffled=answer.shuffled()
        return shuffled == answer ? Array(shuffled.dropFirst()) + [shuffled[0]] : shuffled
    }
    public var signature: String {
        struct Identity: Encodable {let definition: TimelineDefinition;let facts: [Data]}
        struct Claim: Encodable {let id: UUID;let subjectID: UUID;let predicate: String;let value: FactValue;let scope: String}
        let claims=events.sorted {$0.id < $1.id}.map {ContentUpdateRules.bytes(Claim(id:$0.fact.id,subjectID:$0.fact.subjectID,predicate:$0.fact.predicate,value:$0.fact.value,scope:$0.fact.scope))}
        let canonical=TimelineDefinition(id:definition.id,subjectID:definition.subjectID,title:definition.title,events:definition.events.sorted {$0.id < $1.id})
        return ContentUpdateRules.digest(ContentUpdateRules.bytes(Identity(definition:canonical,facts:claims)))
    }
}
public struct TimelineProgress: Codable, Sendable {
    public let roundID: String
    public let order: [String]
    public let checks: Int
    public let moves: Int
    public init(roundID: String,order: [String],checks: Int,moves: Int=0) {self.roundID=roundID;self.order=order;self.checks=checks;self.moves=moves}
    public func moving(_ eventID: String,by offset: Int) -> Self {
        guard offset == -1 || offset == 1,let index=order.firstIndex(of:eventID),order.indices.contains(index+offset) else {return self}
        var moved=order;moved.swapAt(index,index+offset)
        return Self(roundID:roundID,order:moved,checks:checks,moves:min(moves+1,100_000))
    }
    public func moving(_ eventID: String,to destination: Int) -> Self {
        guard let index=order.firstIndex(of:eventID),order.indices.contains(destination),index != destination else {return self}
        var moved=order;moved.remove(at:index);moved.insert(eventID,at:destination)
        return Self(roundID:roundID,order:moved,checks:checks,moves:min(moves+1,100_000))
    }

}
public enum TimelineDeck {
    public static func load(_ data: Data,pack: ContentPack) throws -> [TimelineRound] {
        let definitions=try JSONDecoder().decode([TimelineDefinition].self,from:data)
        guard !definitions.isEmpty,definitions.count <= 30,Set(definitions.map(\.id)).count == definitions.count else {throw ContentError.invalid("Timeline boards need unique identifiers.")}
        return try definitions.compactMap {definition -> TimelineRound? in
            guard let subject=pack.entities.first(where:{$0.id == definition.subjectID}),
                  definition.events.allSatisfy({event in pack.facts.contains(where:{$0.id == event.factID})}) else {return nil}
            guard !definition.id.isEmpty,!definition.title.isEmpty,definition.title.rangeOfCharacter(from:.decimalDigits) == nil,subject.type == "club",subject.imageAsset != nil,
                  (3...6).contains(definition.events.count),Set(definition.events.map(\.id)).count == definition.events.count else {throw ContentError.invalid("Timeline needs a pictured club and three to six distinct events.")}
            let events=try definition.events.map {event -> TimelineEvent in
                guard !event.id.isEmpty,!event.title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,event.title.rangeOfCharacter(from:.decimalDigits) == nil,
                      let fact=pack.facts.first(where:{$0.id == event.factID}),let year=year(fact.value),
                      let pictured=pack.entities.first(where:{$0.id == fact.subjectID}),["club","player"].contains(pictured.type),pictured.imageAsset != nil else {throw ContentError.invalid("Timeline events need a sourced date, image and date-free title.")}
                if pictured.type == "club" {
                    guard pictured.id == subject.id else {throw ContentError.invalid("Timeline milestone belongs to another club.")}
                } else {
                    // A player's general career date cannot silently become a club
                    // milestone: require both supported affiliation and explicit
                    // club context in the dated fact's own claim.
                    let affiliated=(pack.relationships ?? []).contains {$0.subjectID == pictured.id && $0.objectID == subject.id && $0.group == .history}
                    let claim=Recall.normalize(fact.evidence+" "+fact.scope)
                    let named=([subject.name]+subject.aliases).contains {name in let normalized=Recall.normalize(name);return !normalized.isEmpty && claim.contains(normalized)}
                    guard affiliated,named else {throw ContentError.invalid("Player milestone lacks supported club context.")}
                }
                return TimelineEvent(definition:event,fact:fact,subject:pictured,year:year)
            }
            // Mixed date precision is safe only when the years differ. Same-year
            // events need a future explicit interval model, not an arbitrary tie.
            guard Set(events.map(\.year)).count == events.count,Set(events.map {$0.fact.id}).count == events.count,
                  Set(events.map {Recall.normalize($0.definition.title)}).count == events.count else {throw ContentError.invalid("Timeline chronology is ambiguous.")}
            return TimelineRound(definition:definition,subject:subject,events:events)
        }
    }
    private static func year(_ value: FactValue) -> Int? {
        if value.kind == "number",value.unit == "year",let number=value.number,number.isFinite,number.rounded() == number,(1...9999).contains(number) {return Int(number)}
        if value.kind == "date",let text=value.text,text.range(of:"^[0-9]{4}-[0-9]{2}-[0-9]{2}$",options:.regularExpression) != nil {
            let parts=text.split(separator:"-").compactMap {Int($0)}
            guard parts.count == 3,(1...9999).contains(parts[0]) else {return nil}
            var calendar=Calendar(identifier:.gregorian);calendar.timeZone=TimeZone(secondsFromGMT:0)!
            let components=DateComponents(year:parts[0],month:parts[1],day:parts[2])
            guard let date=calendar.date(from:components),calendar.dateComponents([.year,.month,.day],from:date) == components else {return nil}
            return parts[0]
        }
        return nil
    }
    public static func restore(_ resume: GameResume,rounds: [TimelineRound],completedSessions: Set<UUID>) -> TimelineProgress? {
        guard resume.grouping == nil,resume.wordle == nil,resume.schemaVersion == 1,resume.board == nil,resume.mystery == nil,resume.memory == nil,!completedSessions.contains(resume.sessionID),let progress=resume.timeline,
              let round=rounds.first(where:{$0.id == progress.roundID}),resume.signature == round.signature,
              progress.order.count == round.events.count,Set(progress.order) == Set(round.answer),(0...100_000).contains(progress.checks),(0...100_000).contains(progress.moves) else {return nil}
        return progress
    }
}
