import Foundation
import CryptoKit

public struct ContentManifest: Codable, Sendable {
    public let packKey: String
    public let contentVersion: Int
    public let schemaVersion: Int
    public let language: String
    public let contentURL: String
    public let sha256: String
    public func verify(_ data: Data, bundled: ContentPack) throws -> ContentPack {
        let pack=try ContentUpdateRules.decode(data,bundled:bundled)
        guard packKey == pack.key, contentVersion == pack.contentVersion,
              schemaVersion == pack.schemaVersion, language == pack.language,
              sha256.count == 64, sha256.lowercased() == ContentUpdateRules.digest(data) else {
            throw ContentError.invalid("The lesson file does not match its update manifest.")
        }
        return pack
    }
}
public enum ContentUpdateRules {
    public static let maximumBytes=16*1024*1024
    public static func digest(_ data: Data) -> String {SHA256.hash(data:data).map {String(format:"%02x",$0)}.joined()}
    public static func https(_ value: String) throws -> URL {
        guard let url=URL(string:value),url.scheme?.lowercased() == "https",url.host != nil,
              url.user == nil,url.password == nil else {throw ContentError.invalid("Use an HTTPS update address without embedded credentials.")}
        return url
    }
    public static func decode(_ data: Data,bundled: ContentPack,allowOlder: Bool=false) throws -> ContentPack {
        guard data.count <= maximumBytes else {throw ContentError.invalid("This lesson file is too large.")}
        let pack=try ContentPack.load(data)
        guard pack.key == bundled.key,pack.language == bundled.language,pack.schemaVersion == bundled.schemaVersion,
              (allowOlder || pack.contentVersion >= bundled.contentVersion),pack.contentVersion > 0,!pack.clubRoadmaps.isEmpty,!pack.lessons.isEmpty,
              pack.objectives.allSatisfy({$0.revision > 0}),pack.cards.allSatisfy({$0.knowledgeVersion > 0}) else {
            throw ContentError.invalid("This lesson file is incompatible with this app edition.")
        }
        for exercise in pack.exercises {
            if exercise.kind == "choice" {
                guard exercise.objectiveIDs.count == 1 else {throw ContentError.invalid("A choice question must assess one objective.")}
                let objective=pack.objective(exercise.objectiveIDs[0])
                let answers=Set(exercise.choices.filter {Recall.accepts($0.text,for:objective)}.map(\.id))
                guard answers == Set(exercise.answerIDs) else {throw ContentError.invalid("A question’s answer key conflicts with its objective: \(exercise.key).")}
            } else {
                for pair in exercise.pairs {
                    let index=exercise.left.firstIndex {$0.id == pair.left}!
                    let right=exercise.right.first {$0.id == pair.right}!
                    guard Recall.accepts(right.text,for:pack.objective(exercise.objectiveIDs[index])) else {throw ContentError.invalid("A memory pair conflicts with its objective: \(exercise.key).")}
                }
            }
        }
        return pack
    }
    static func bytes<T: Encodable>(_ value: T) -> Data {
        let encoder=JSONEncoder();encoder.outputFormatting=[.sortedKeys]
        return (try? encoder.encode(value)) ?? Data()
    }
    private struct Meaning: Encodable {
        let prompt: String
        let answers: [String]
        let facts: [FactMeaning]
    }
    private struct FactMeaning: Encodable {
        let id: UUID
        let subject: UUID
        let predicate: String
        let value: FactValue
        let scope: String
    }
    static func meaning(_ objective: Objective,in pack: ContentPack) -> Data {
        bytes(Meaning(prompt:objective.prompt,answers:objective.answers,facts:objective.factIDs.map {id in
            let fact=pack.facts.first {$0.id == id}!
            return FactMeaning(id:id,subject:fact.subjectID,predicate:fact.predicate,value:fact.value,scope:fact.scope)
        }))
    }
    public static func validateTransition(from old: ContentPack,to new: ContentPack) throws {
        func identities(_ p: ContentPack) -> [UUID:String] {
            var pairs=p.entities.map {($0.id,"entity/"+$0.type+"/"+$0.key)}
            pairs += p.facts.map {($0.id,"fact/"+$0.key)}
            pairs += p.objectives.map {($0.id,"objective/"+$0.key)}
            pairs += p.lessons.map {($0.id,"lesson/"+$0.key)}
            pairs += p.exercises.map {($0.id,"exercise/"+$0.key)}
            pairs += p.cards.map {($0.id,"card/"+$0.key+"/"+$0.entityID.uuidString)}
            pairs += p.roadmaps.map {($0.id,"roadmap/"+$0.key+"/"+$0.entityID.uuidString)}
            pairs += (p.relationships ?? []).map {relationship in
                let endpoints=relationship.subjectID.uuidString+"/"+relationship.objectID.uuidString
                return (relationship.id,"relationship/"+relationship.key+"/"+endpoints)
            }
            return Dictionary(uniqueKeysWithValues:pairs)
        }
        let prior=identities(old),next=identities(new)
        for (id,value) in prior where next[id] != nil {
            guard next[id] == value else {throw ContentError.invalid("An existing content identifier was reused for a different subject.")}
        }
        func keys(_ p: ContentPack) -> [String:UUID] {
            var pairs=p.entities.map {($0.key,$0.id)}
            pairs += p.facts.map {($0.key,$0.id)}
            pairs += p.objectives.map {($0.key,$0.id)}
            pairs += p.lessons.map {($0.key,$0.id)}
            pairs += p.exercises.map {($0.key,$0.id)}
            pairs += p.cards.map {($0.key,$0.id)}
            pairs += p.roadmaps.map {($0.key,$0.id)}
            pairs += (p.relationships ?? []).map {($0.key,$0.id)}
            return Dictionary(uniqueKeysWithValues:pairs)
        }
        let priorKeys=keys(old)
        for (key,id) in keys(new) where priorKeys[key] != nil {
            guard priorKeys[key] == id else {throw ContentError.invalid("An existing content key changed its identifier.")}
        }
        func scoreMapping(_ score: ScoreInput) -> [UUID:Int] {
            [score.leftEntityID:score.leftGoals,score.rightEntityID:score.rightGoals]
        }
        func scoreFacts(_ objective: Objective,_ pack: ContentPack) -> Data {
            bytes(objective.factIDs.map {id in
                let fact=pack.facts.first {$0.id == id}!
                return FactMeaning(id:id,subject:fact.subjectID,predicate:fact.predicate,value:fact.value,scope:fact.scope)
            })
        }
        for objective in new.objectives {
            guard let previous=old.objectives.first(where:{$0.id == objective.id}) else {continue}
            if let priorScore=old.scoreInput(for:previous.id),let nextScore=new.scoreInput(for:objective.id),scoreMapping(priorScore) != scoreMapping(nextScore) {
                guard objective.revision > previous.revision && scoreFacts(objective,new) != scoreFacts(previous,old) else {
                    throw ContentError.invalid("A changed score orientation needs a revised memory and updated factual context: \(objective.key).")
                }
            }
            guard objective.revision >= previous.revision,
                  objective.revision > previous.revision || meaning(objective,in:new) == meaning(previous,in:old) else {
                throw ContentError.invalid("A changed answer needs a higher objective revision: \(objective.key).")
            }
        }
        for card in new.cards {
            guard let previous=old.cards.first(where:{$0.id == card.id}) else {continue}
            guard card.knowledgeVersion >= previous.knowledgeVersion,
                  Set(card.objectiveIDs) == Set(previous.objectiveIDs) || card.knowledgeVersion > previous.knowledgeVersion else {
                throw ContentError.invalid("An expanded card needs a higher knowledge version: \(card.key).")
            }
        }
    }
    static func lessonSignature(_ lesson: Lesson,in pack: ContentPack) -> Data {
        var data=bytes(lesson)
        for id in lesson.exerciseIDs {data.append(bytes(pack.exercise(id)))}
        for id in lesson.objectiveIDs {let o=pack.objective(id);data.append(bytes(o));data.append(meaning(o,in:pack))}
        return data
    }
}

/// A single atomically written pending file prevents partial downloads from replacing lessons.
/// Activation only happens during startup; the live curriculum never changes under a game.
public struct ContentCache: Sendable {
    public let directory: URL
    public let bundledData: Data
    public let bundled: ContentPack
    public init(directory: URL,bundledData: Data) throws {
        self.directory=directory;self.bundledData=bundledData;bundled=try ContentPack.load(bundledData)
    }
    private struct Cached: Codable {
        let data: Data
        let digest: String
        let rollback: Bool
    }
    private func url(_ name: String) -> URL {directory.appendingPathComponent(name+".json")}
    private func entry(_ name: String) -> Cached? {
        let file=url(name)
        guard let size=try? file.resourceValues(forKeys:[.fileSizeKey]).fileSize,
              size <= ContentUpdateRules.maximumBytes*2,
              let raw=try? Data(contentsOf:file),let value=try? JSONDecoder().decode(Cached.self,from:raw),
              value.data.count <= ContentUpdateRules.maximumBytes,
              value.digest == ContentUpdateRules.digest(value.data+Data([value.rollback ? 1 : 0])),
              (try? ContentUpdateRules.decode(value.data,bundled:bundled,allowOlder:true)) != nil else {return nil}
        return value
    }
    private func read(_ name: String) -> Data? {entry(name)?.data}
    private func pack(_ data: Data?) -> ContentPack? {data.flatMap {try? ContentUpdateRules.decode($0,bundled:bundled)}}
    private func write(_ data: Data,name: String,rollback: Bool=false) throws {
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        let value=Cached(data:data,digest:ContentUpdateRules.digest(data+Data([rollback ? 1 : 0])),rollback:rollback)
        try JSONEncoder().encode(value).write(to:url(name),options:.atomic)
    }
    private var pending: Cached? {entry("pending")}
    public var pendingVersion: Int? {pending.flatMap {pack($0.data)?.contentVersion}}
    public var previousVersion: Int? {pack(read("previous"))?.contentVersion}
    public func previousPack(version: Int?) -> ContentPack? {
        if version == bundled.contentVersion {return bundled}
        for name in ["previous","active"] {
            if let data=read(name),let p=try? ContentUpdateRules.decode(data,bundled:bundled,allowOlder:true),p.contentVersion == version {return p}
        }
        return nil
    }
    public func stage(_ data: Data,active: ContentPack) throws {
        let candidate=try ContentUpdateRules.decode(data,bundled:bundled)
        guard candidate.contentVersion > active.contentVersion,candidate.contentVersion > (pendingVersion ?? 0) else {
            throw ContentError.invalid("Only a newer lesson version can replace the active or waiting update.")
        }
        try ContentUpdateRules.validateTransition(from:bundled,to:candidate)
        try ContentUpdateRules.validateTransition(from:active,to:candidate)
        if let priorData=read("previous"),let prior=try? ContentUpdateRules.decode(priorData,bundled:bundled,allowOlder:true) {try ContentUpdateRules.validateTransition(from:prior,to:candidate)}
        if let waiting=pending.flatMap({pack($0.data)}),!((pending?.rollback) ?? false) {try ContentUpdateRules.validateTransition(from:waiting,to:candidate)}
        try Task.checkCancellation()
        try write(data,name:"pending")
    }
    public func stageRollback(active: ContentPack) throws {
        guard let data=read("previous"),let prior=pack(data),prior.contentVersion != active.contentVersion else {
            throw ContentError.invalid("There is no compatible previous version to restore.")
        }
        try write(data,name:"pending",rollback:true)
    }
    public func cancelPending() throws {
        if FileManager.default.fileExists(atPath:url("pending").path) {try FileManager.default.removeItem(at:url("pending"))}
    }
    public func load() throws -> (pack: ContentPack,notice: String?) {
        let activeData=read("active"),previousData=read("previous")
        var data=activeData.flatMap {pack($0) == nil ? nil : $0} ?? previousData.flatMap {pack($0) == nil ? nil : $0} ?? bundledData
        var current=try ContentUpdateRules.decode(data,bundled:bundled)
        var notice: String? = nil
        if let activeData,let older=try? ContentUpdateRules.decode(activeData,bundled:bundled,allowOlder:true),older.contentVersion < bundled.contentVersion {
            do {try write(activeData,name:"previous")}
            catch {notice="Bundled lessons are ready, but the previous library could not be cached."}
        } else if FileManager.default.fileExists(atPath:url("active").path),pack(activeData) == nil {notice="We restored a working lesson library. Your learning history is preserved."}
        if let staged=pending,let next=pack(staged.data) {
            if next.contentVersion == current.contentVersion && ContentUpdateRules.digest(staged.data) == ContentUpdateRules.digest(data) {
                try? cancelPending()
            } else {
                do {
                    if !staged.rollback {
                        guard next.contentVersion > current.contentVersion else {throw ContentError.invalid("The waiting update is older than the installed lessons.")}
                        try ContentUpdateRules.validateTransition(from:current,to:next)
                        try ContentUpdateRules.validateTransition(from:bundled,to:next)
                    }
                    try write(data,name:"previous")
                    try write(staged.data,name:"active")
                    data=staged.data;current=next
                    try? cancelPending()
                    notice="Lesson version \(current.contentVersion) is ready. Your earned cards stay with you."
                } catch {notice="The waiting update could not be activated. Working lessons are still available: \(error.localizedDescription)"}
            }
        } else if FileManager.default.fileExists(atPath:url("pending").path) != false {
            notice="The waiting lesson file could not be read. Working lessons are still available."
        }
        if ContentUpdateRules.digest(read("active") ?? Data()) != ContentUpdateRules.digest(data) {
            do {try write(data,name:"active")}
            catch {notice="Working lessons are available, but the offline update cache could not be saved: \(error.localizedDescription)"}
        }
        return (current,notice)
    }
}

extension LearnerState {
    /// An incompatible partial lesson restarts; its original save is archived before migration.
    /// Its attempted answers remain historical acquisition attempts, never earned recall.
    public mutating func migrateContent(from old: ContentPack?,to new: ContentPack,now: Date) -> Int {
        guard installedContentVersion != new.contentVersion else {return 0}
        if let old {captureCardAchievements(old)}
        var retired=0
        for (id,resume) in resumes {
            let before=old?.lessons.first {$0.id == id},after=new.lessons.first {$0.id == id}
            if before == nil || after == nil || ContentUpdateRules.lessonSignature(before!,in:old!) != ContentUpdateRules.lessonSignature(after!,in:new) {
                attempts += resume.attempts;resumes.removeValue(forKey:id);retired += 1
            }
        }
        if let old {
            for id in completedLessons {
                guard let before=old.lessons.first(where:{$0.id == id}),let after=new.lessons.first(where:{$0.id == id}) else {continue}
                if Set(before.objectiveIDs) != Set(after.objectiveIDs) || after.objectiveIDs.contains(where:{id in
                    guard let a=old.objectives.first(where:{$0.id == id}) else {return true}
                    return a.revision != new.objective(id).revision
                }) {completedLessons.remove(id)}
            }
        } else {
            for lesson in new.lessons where completedLessons.contains(lesson.id) {
                if lesson.objectiveIDs.contains(where:{reviews[$0]?.revision != new.objective($0).revision}) {completedLessons.remove(lesson.id)}
            }
        }
        reconcile(new,now:now);installedContentVersion=new.contentVersion
        return retired
    }
}
