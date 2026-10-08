import Foundation

public struct Entity: Codable, Identifiable, Sendable {
    public let id: UUID
    public let key: String
    public let type: String
    public let name: String
    public let aliases: [String]
    public let visual: String
    public let externalRefs: [String: String]
    public let imageAsset: String?
    public let imageURL: String?
    public let competitions: [String]?
}
public struct Source: Codable, Identifiable, Sendable {
    public var id: String { key }
    public let key: String
    public let title: String
    public let url: String
    public let verifiedAt: String
}
public struct FactValue: Codable, Sendable {
    public let kind: String
    public let display: String
    public let text: String?
    public let number: Double?
    public let entityID: UUID?
    public let unit: String?
}
public struct Fact: Codable, Identifiable, Sendable {
    public let id: UUID
    public let key: String
    public let subjectID: UUID
    public let predicate: String
    public let value: FactValue
    public let scope: String
    public let sourceKeys: [String]
    public let evidence: String
}
public struct Objective: Codable, Identifiable, Sendable {
    public let id: UUID
    public let key: String
    public let factIDs: [UUID]
    public let prompt: String
    public let answers: [String]
    public let feedback: String
    public let revision: Int
}
public struct Choice: Codable, Identifiable, Sendable {
    public let id: String
    public let text: String
}
public struct Pair: Codable, Sendable {
    public let left: String
    public let right: String
}
public struct Exercise: Codable, Identifiable, Sendable {
    public let id: UUID
    public let key: String
    public let kind: String
    public let objectiveIDs: [UUID]
    public let prompt: String
    public let feedback: String
    public let choices: [Choice]
    public let answerIDs: [String]
    public let left: [Choice]
    public let right: [Choice]
    public let pairs: [Pair]
    public func accepts(_ answer: String) -> Bool { answerIDs.contains(answer) }
    public func accepts(left: String, right: String) -> Bool { pairs.contains { $0.left == left && $0.right == right } }
}
public struct StoryScreen: Codable, Sendable { public let title: String; public let body: String }
public struct Lesson: Codable, Identifiable, Sendable {
    public let id: UUID
    public let key: String
    public let title: String
    public let subtitle: String
    public let story: [StoryScreen]
    public let objectiveIDs: [UUID]
    public let exerciseIDs: [UUID]
}
public struct Chapter: Codable, Identifiable, Sendable {
    public var id: String { key }
    public let key: String
    public let title: String
    public let lessonIDs: [UUID]
    public let isOptional: Bool?
    public let note: String?
}
public struct Roadmap: Codable, Identifiable, Sendable {
    public let id: UUID
    public let key: String
    public let clubID: UUID
    public let subjectID: UUID?
    public let summary: String?
    public let chapters: [Chapter]
    public var entityID: UUID {subjectID ?? clubID}
}
public struct AlbumCard: Codable, Identifiable, Sendable {
    public let id: UUID
    public let key: String
    public let entityID: UUID
    public let objectiveIDs: [UUID]
    public let lessonIDs: [UUID]
    public let knowledgeVersion: Int
    public let caption: String
}
public enum ContentError: Error, LocalizedError {
    case invalid(String)
    public var errorDescription: String? { if case .invalid(let message) = self { return message }; return nil }
}
public struct ContentPack: Codable, Sendable {
    public let schemaVersion: Int
    public let key: String
    public let contentVersion: Int
    public let competitionScopes: [String:String]?
    public let language: String
    public let entities: [Entity]
    public let sources: [Source]
    public let facts: [Fact]
    public let objectives: [Objective]
    public let roadmaps: [Roadmap]
    public let lessons: [Lesson]
    public let exercises: [Exercise]
    public let cards: [AlbumCard]
    public let relationships: [GraphRelationship]?
    public static func load(_ data: Data) throws -> Self {
        let pack = try JSONDecoder().decode(Self.self, from: data)
        try pack.validate()
        return pack
    }
    public func entity(_ id: UUID) -> Entity { entities.first { $0.id == id }! }
    public func lesson(_ id: UUID) -> Lesson { lessons.first { $0.id == id }! }
    public func objective(_ id: UUID) -> Objective { objectives.first { $0.id == id }! }
    public func exercise(_ id: UUID) -> Exercise { exercises.first { $0.id == id }! }
    public func validate() throws {
        func require(_ condition: Bool, _ message: String) throws { if !condition { throw ContentError.invalid(message) } }
        try require(schemaVersion == 1 && language == "en", "Unsupported content version or language.")
        var ids = entities.map(\.id) + facts.map(\.id) + objectives.map(\.id) + roadmaps.map(\.id) + lessons.map(\.id) + exercises.map(\.id) + cards.map(\.id)
        var keys = entities.map(\.key) + facts.map(\.key) + objectives.map(\.key) + roadmaps.map(\.key) + lessons.map(\.key) + exercises.map(\.key) + cards.map(\.key) + sources.map(\.key)
        ids += (relationships ?? []).map(\.id)
        keys += (relationships ?? []).map(\.key)
        try require(Set(ids).count == ids.count && Set(keys).count == keys.count, "Duplicate content identifiers.")
        let ei = Set(entities.map(\.id)), fi = Set(facts.map(\.id)), oi = Set(objectives.map(\.id)), li = Set(lessons.map(\.id)), xi = Set(exercises.map(\.id)), sk = Set(sources.map(\.key))
        for s in sources { try require(URL(string:s.url)?.scheme == "https" && !s.verifiedAt.isEmpty, "Invalid source.") }
        for f in facts {
            try require(ei.contains(f.subjectID) && !f.sourceKeys.isEmpty && Set(f.sourceKeys).isSubset(of:sk) && !f.evidence.isEmpty && !f.scope.isEmpty && !f.value.display.isEmpty, "Missing evidence or subject for \(f.key).")
            let v=f.value
            switch v.kind {
            case "text", "date": try require(v.text?.isEmpty == false && v.number == nil && v.entityID == nil, "Invalid literal.")
            case "number": try require(v.number?.isFinite == true && v.unit?.isEmpty == false && v.text == nil && v.entityID == nil, "Invalid numeric value.")
            case "entity": try require(v.entityID.map {ei.contains($0)} == true && v.text == nil && v.number == nil, "Broken relationship value.")
            default: throw ContentError.invalid("Unknown fact value kind.")
            }
        }
        for o in objectives { try require(!o.factIDs.isEmpty && Set(o.factIDs).isSubset(of:fi) && !o.answers.isEmpty && o.answers.allSatisfy { !Recall.normalize($0).isEmpty } && o.revision > 0 && !o.prompt.isEmpty, "Invalid objective \(o.key).") }
        for r in relationships ?? [] {
            try require(ei.contains(r.subjectID) && ei.contains(r.objectID) && r.subjectID != r.objectID && !r.factIDs.isEmpty && Set(r.factIDs).isSubset(of:fi) && !r.label.isEmpty && !r.claim.isEmpty && !r.scope.isEmpty,"Invalid graph relationship \(r.key).")
        }
        for x in exercises {
            try require(!x.objectiveIDs.isEmpty && Set(x.objectiveIDs).isSubset(of:oi), "Broken exercise objective.")
            switch x.kind {
            case "choice":
                let ci = Set(x.choices.map(\.id))
                try require(x.choices.count == 4 && ci.count == 4 && Set(x.choices.map { Recall.normalize($0.text) }).count == 4 && !x.answerIDs.isEmpty && Set(x.answerIDs).isSubset(of:ci), "Invalid choices for \(x.key).")
            case "match":
                let left = Set(x.left.map(\.id)), right = Set(x.right.map(\.id))
                try require(x.objectiveIDs.count == 3 && Set(x.objectiveIDs).count == 3 && left == Set(["l-0","l-1","l-2"]) && right == Set(["r-0","r-1","r-2"]) && left.count == 3 && x.left.count == 3 && right.count == 3 && x.right.count == 3 && x.pairs.count == 3 && Set(x.pairs.map(\.left)) == left && Set(x.pairs.map(\.right)) == right && Set(x.left.map { Recall.normalize($0.text) }).count == 3 && Set(x.right.map { Recall.normalize($0.text) }).count == 3, "Ambiguous matching board \(x.key).")
            default: throw ContentError.invalid("Unknown exercise type.")
            }
        }
        for l in lessons {
            try require(l.story.count == 2 && l.objectiveIDs.count == 3 && Set(l.objectiveIDs).count == 3 && Set(l.objectiveIDs).isSubset(of:oi) && l.exerciseIDs.count == 5 && Set(l.exerciseIDs).isSubset(of:xi), "Invalid lesson \(l.key).")
            let activities = l.exerciseIDs.map(exercise)
            try require(activities.filter { $0.kind == "choice" }.count == 4 && activities.filter { $0.kind == "match" }.count == 1 && Set(activities.flatMap(\.objectiveIDs)) == Set(l.objectiveIDs), "Incomplete assessment \(l.key).")
        }
        try require(Set(roadmaps.map(\.entityID)).count == roadmaps.count,"Duplicate roadmap subjects.")
        for r in roadmaps {
            let lessons=r.chapters.flatMap(\.lessonIDs)
            try require(ei.contains(r.clubID) && entities.first(where:{$0.id == r.clubID})?.type == "club" && ei.contains(r.entityID) && !r.chapters.isEmpty && r.chapters.allSatisfy {!$0.lessonIDs.isEmpty} && r.chapters.contains {$0.isOptional != true} && Set(lessons).count == lessons.count && Set(lessons).isSubset(of:li), "Broken roadmap.")
            try require(entity(r.entityID).type != "club" || r.entityID == r.clubID,"Conflicting club roadmap subject.")
        }
        for c in cards { try require(ei.contains(c.entityID) && !c.objectiveIDs.isEmpty && Set(c.objectiveIDs).isSubset(of:oi) && !c.lessonIDs.isEmpty && Set(c.lessonIDs).isSubset(of:li), "Broken album card.") }
    }
}
public enum Recall {
    public static func normalize(_ value: String) -> String {
        value.folding(options:[.diacriticInsensitive, .caseInsensitive], locale:Locale(identifier:"en_US_POSIX")).split(whereSeparator: \.isWhitespace).joined(separator:" ")
    }
    public static func accepts(_ value: String, for objective: Objective) -> Bool { objective.answers.map(normalize).contains(normalize(value)) }
}
public protocol ContentRepository { func load() throws -> ContentPack }
public struct FileContentRepository: ContentRepository {
    public let url: URL
    public init(url: URL) { self.url = url }
    public func load() throws -> ContentPack { try ContentPack.load(Data(contentsOf:url)) }
}

public enum AnswerArtwork {
    public static let flags = ["spain":"flag-spain","mexico":"flag-mexico","germany":"flag-germany","brazil":"flag-brazil","portugal":"flag-portugal","argentina":"flag-argentina","france":"flag-france","england":"flag-england","colombia":"flag-colombia","austria":"flag-austria","azerbaijan":"flag-azerbaijan","belgium":"flag-belgium","greece":"flag-greece","italy":"flag-italy","netherlands":"flag-netherlands","norway":"flag-norway","slovakia":"flag-slovakia","ukraine":"flag-ukraine","uruguay":"flag-uruguay","chile":"flag-chile","czechia":"flag-czech-republic","turkiye":"flag-turkey","turkey":"flag-turkey"]
    public static func entity(_ text: String,type: String,pack: ContentPack) -> Entity? {
        guard ["club","player"].contains(type) else {return nil}
        return pack.entities.first {e in e.type == type && e.imageAsset != nil && ([e.name]+e.aliases).contains {Recall.normalize($0) == Recall.normalize(text)} }
    }
    public static func type(objectiveID: UUID,pack: ContentPack) -> String? {
        let o=pack.objective(objectiveID)
        guard o.factIDs.count == 1,let f=pack.facts.first(where:{$0.id == o.factIDs[0]}) else {return nil}
        if f.predicate == "country" || f.predicate.hasSuffix("-country") {return "country"}
        guard f.predicate != "nickname",let id=f.value.entityID else {return nil}
        let type=pack.entity(id).type
        return ["club","player"].contains(type) ? type : nil
    }
    public static func canShow(_ text: String,type: String,pack: ContentPack) -> Bool {
        type == "country" ? flags[Recall.normalize(text)] != nil : entity(text,type:type,pack:pack) != nil
    }
}
