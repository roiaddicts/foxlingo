import Foundation

public struct RehearsalDefinition: Codable, Sendable {
    public let lessonID: UUID
    public let subjectID: UUID
    public let prompt: String
    public let anchorTitles: [String]
}
public struct RehearsalTopic: Identifiable, Sendable {
    public var id: String {definition.lessonID.uuidString}
    public let definition: RehearsalDefinition
    public let subject: Entity
    public let lesson: Lesson
    public let objectives: [Objective]
    public let facts: [[Fact]]
    public var objectiveIDs: Set<UUID> {Set(objectives.map(\.id))}
    public var signature: String {
        var data=ContentUpdateRules.bytes(definition)
        for objective in objectives {data.append(ContentUpdateRules.bytes(objective.revision));data.append(ContentUpdateRules.meaning(objective,in:content))}
        return ContentUpdateRules.digest(data)
    }
    private let content: ContentPack
    public static func load(_ data: Data,pack: ContentPack) throws -> [Self] {
        let definitions=try JSONDecoder().decode([RehearsalDefinition].self,from:data)
        guard Set(definitions.map(\.lessonID)).count == definitions.count else {throw ContentError.invalid("Duplicate rehearsal stories.")}
        return try definitions.compactMap {definition in
            guard let lesson=pack.lessons.first(where:{$0.id == definition.lessonID}),let subject=pack.entities.first(where:{$0.id == definition.subjectID}) else {return nil}
            guard !definition.prompt.isEmpty,definition.anchorTitles.count == lesson.objectiveIDs.count,definition.anchorTitles.allSatisfy({!$0.isEmpty}),subject.imageAsset != nil,
                  pack.cards.contains(where:{$0.entityID == subject.id && $0.lessonIDs.contains(lesson.id)}) else {throw ContentError.invalid("Rehearsal needs sourced subject context and three anchors.")}
            let objectives=lesson.objectiveIDs.map(pack.objective)
            let facts=objectives.map {objective in objective.factIDs.map {id in pack.facts.first {$0.id == id}!}}
            return Self(definition:definition,subject:subject,lesson:lesson,objectives:objectives,facts:facts,content:pack)
        }
    }
}
public enum RehearsalMode: String, Codable, Sendable {case typed,aloud}
public enum RehearsalReflection: String, Codable, CaseIterable, Sendable {case included,missed,unsure}
public struct RehearsalDraft: Codable, Sendable {
    public let topicID: String
    public let signature: String
    public let title: String
    public let prompt: String
    public let anchorIDs: [UUID]
    public let anchorTitles: [String]
    public let sessionID: UUID
    public var mode: RehearsalMode = .typed
    public var response=""
    public var revisedResponse=""
    public var explained=false
    public var revealed=false
    public var checks: [UUID:RehearsalReflection]=[:]
    public init(topic: RehearsalTopic) {topicID=topic.id;signature=topic.signature;title=topic.lesson.title;prompt=topic.definition.prompt;anchorIDs=topic.objectives.map(\.id);anchorTitles=topic.definition.anchorTitles;sessionID=UUID()}
    public var canReveal: Bool {mode == .aloud ? explained : !response.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty}
    public func canFinish(_ topic: RehearsalTopic) -> Bool {revealed && canReveal && Set(checks.keys) == topic.objectiveIDs}
    public func valid(for topic: RehearsalTopic,completed: Set<UUID>) -> Bool {
        topicID == topic.id && signature == topic.signature && anchorIDs == topic.objectives.map(\.id) && anchorTitles == topic.definition.anchorTitles && !completed.contains(sessionID) && response.count <= 4000 && revisedResponse.count <= 4000 && Set(checks.keys).isSubset(of:topic.objectiveIDs) && (revealed || (checks.isEmpty && revisedResponse.isEmpty)) && (!revealed || canReveal)
    }
}
public struct RehearsalRecord: Codable, Sendable, Identifiable {
    public var id: UUID {draft.sessionID}
    public let draft: RehearsalDraft
    public let title: String
    public let savedAt: Date
    public let completed: Bool
}
/// Lossy only at the optional rehearsal boundary, never the learning save.
public struct RehearsalCollection: Codable, Sendable {
    public var drafts: [String:RehearsalDraft]=[:]
    public var records: [RehearsalRecord]=[]
    public private(set) var discardedDrafts=0
    public init() {}
    enum CodingKeys: String,CodingKey {case drafts,records}
    private struct Key: CodingKey {let stringValue: String;var intValue: Int? {nil};init?(stringValue:String) {self.stringValue=stringValue};init?(intValue:Int) {return nil}}
    private struct RecordBox: Decodable {let value: RehearsalRecord?;init(from decoder: Decoder) throws {value=try? RehearsalRecord(from:decoder)}}
    public init(from decoder: Decoder) throws {
        guard let container=try? decoder.container(keyedBy:CodingKeys.self) else {discardedDrafts=1;return}
        if let nested=try? container.nestedContainer(keyedBy:Key.self,forKey:.drafts) {
            for key in nested.allKeys {if let draft=try? nested.decode(RehearsalDraft.self,forKey:key) {drafts[key.stringValue]=draft} else {discardedDrafts += 1}}
        } else if container.contains(.drafts) {discardedDrafts += 1}
        records=(try? container.decode([RecordBox].self,forKey:.records))?.compactMap(\.value) ?? []
    }
    public func encode(to encoder: Encoder) throws {var container=encoder.container(keyedBy:CodingKeys.self);try container.encode(drafts,forKey:.drafts);try container.encode(records,forKey:.records)}
}
extension LearnerState {
    public mutating func storeRehearsal(_ draft: RehearsalDraft) {if rehearsals == nil {rehearsals=RehearsalCollection()};rehearsals?.drafts[draft.topicID]=draft}
    public mutating func archiveRehearsal(_ draft: RehearsalDraft,title: String,now: Date) {
        if rehearsals == nil {rehearsals=RehearsalCollection()}
        if rehearsals?.records.contains(where:{$0.id == draft.sessionID}) != true {rehearsals?.records.append(RehearsalRecord(draft:draft,title:draft.title,savedAt:now,completed:false))}
        if rehearsals?.drafts[draft.topicID]?.sessionID == draft.sessionID {rehearsals?.drafts.removeValue(forKey:draft.topicID)}
    }
    public mutating func reconcileRehearsals(_ topics: [RehearsalTopic],now: Date) {
        for draft in Array(rehearsals?.drafts.values ?? Dictionary<String,RehearsalDraft>().values) {
            if let topic=topics.first(where:{$0.id == draft.topicID}),draft.valid(for:topic,completed:Set(sessions.map(\.id))) {continue}
            archiveRehearsal(draft,title:draft.title,now:now)
        }
    }
    @discardableResult public mutating func completeRehearsal(_ draft: RehearsalDraft,topic: RehearsalTopic,now: Date) -> Bool {
        guard rehearsals?.records.contains(where:{$0.id == draft.sessionID}) != true,
              rehearsals?.drafts[topic.id].map({$0.sessionID == draft.sessionID}) ?? true,
              draft.valid(for:topic,completed:Set(sessions.map(\.id))),draft.canFinish(topic) else {return false}
        if rehearsals == nil {rehearsals=RehearsalCollection()}
        rehearsals?.records.append(RehearsalRecord(draft:draft,title:topic.lesson.title,savedAt:now,completed:true));if rehearsals?.drafts[topic.id]?.sessionID == draft.sessionID {rehearsals?.drafts.removeValue(forKey:topic.id)}
        sessions.append(SessionRecord(id:draft.sessionID,kind:"rehearsal",completedAt:now,attemptCount:0));streak.record(now,zone:homeTimeZone);return true
    }
}
