import Foundation

public struct ReviewState: Codable, Sendable {
    public var revision: Int
    public var stage = 0
    public var highestEarned = 0
    public var due: Date
    public var lapses = 0
    public var refreshRequired: Bool? = nil
    public var learnedAt: Date
}
public struct Attempt: Codable, Sendable {
    public let objectiveID: UUID
    public let answer: String
    public let correct: Bool
    public let hinted: Bool
    public let mode: String
    public let timestamp: Date
}
public struct SessionRecord: Codable, Identifiable, Sendable {
    public let id: UUID
    public let kind: String
    public let completedAt: Date
    public let attemptCount: Int
}
public struct LessonResume: Codable, Sendable {
    public var step: Int = 0
    public var attempts: [Attempt] = []
    public var matched: [String] = []
    public var memoryOrder: [String]? = nil
    public var sessionID = UUID()
}
public struct LearnerState: Codable, Sendable {
    public var schemaVersion = 1
    public var installedContentVersion: Int? = nil
    public var selectedClub: UUID?
    public var selectedRoadmapID: UUID? = nil
    public var homeTimeZone: String
    public var preferredSessionSize: Int? = nil
    public var sound = true
    public var haptics = true
    public var completedLessons: Set<UUID> = []
    public var resumes: [UUID: LessonResume] = [:]
    public var gameResumes: GameResumeCollection? = nil
    public var reviews: [UUID: ReviewState] = [:]
    public var acquiredCards: Set<UUID> = []
    public var cardAchievements: [UUID:CardAchievement]? = nil
    public var attempts: [Attempt] = []
    public var sessions: [SessionRecord] = []
    public var streak = StreakState()
    public init(timeZone: String = TimeZone.current.identifier) { homeTimeZone = timeZone }
    public mutating func reconcile(_ pack: ContentPack, now: Date) {
        captureCardAchievements(pack)
        for o in pack.objectives {
            if let old = reviews[o.id], old.revision != o.revision {
                reviews[o.id] = ReviewState(revision:o.revision, highestEarned:old.highestEarned, due:now.addingTimeInterval(86400), refreshRequired:true, learnedAt:now)
            }
        }
    }
    @discardableResult public mutating func completeLesson(_ lesson: Lesson, pack: ContentPack, sessionID: UUID, attempts newAttempts: [Attempt], now: Date) -> Bool {
        guard !sessions.contains(where:{$0.id == sessionID}) else { return false }
        completedLessons.insert(lesson.id)
        resumes.removeValue(forKey:lesson.id)
        for id in lesson.objectiveIDs where reviews[id] == nil {
            let o = pack.objective(id)
            reviews[id] = ReviewState(revision:o.revision, due:now.addingTimeInterval(86400), learnedAt:now)
        }
        for card in pack.cards where card.lessonIDs.contains(lesson.id) { acquiredCards.insert(card.id) }
        captureCardAchievements(pack)
        attempts += newAttempts
        sessions.append(SessionRecord(id:sessionID, kind:"lesson", completedAt:now, attemptCount:newAttempts.count))
        streak.record(now, zone:homeTimeZone)
        return true
    }
    public func dueObjectives(_ pack: ContentPack, now: Date, limit: Int = 10) -> [Objective] {
        pack.objectives.filter { objective in reviews[objective.id].map { $0.due <= now && $0.revision == objective.revision } ?? false }.sorted {
            let a = reviews[$0.id]!, b = reviews[$1.id]!
            if a.due != b.due { return a.due < b.due }
            if a.lapses != b.lapses { return a.lapses > b.lapses }
            return $0.key < $1.key
        }.prefix(limit).map{$0}
    }
    public mutating func recordRecall(_ attempt: Attempt, objective: Objective) {
        guard attempt.objectiveID == objective.id, var r = reviews[objective.id], r.revision == objective.revision else { return }
        attempts.append(attempt)
        guard attempt.mode == "due", r.due <= attempt.timestamp else { return }
        if attempt.correct && !attempt.hinted {
            r.refreshRequired=false
            r.stage = min(4, r.stage + 1)
            r.highestEarned = max(r.highestEarned, r.stage)
            let days = [1,3,7,14,30][r.stage]
            r.due = attempt.timestamp.addingTimeInterval(Double(days)*86400)
        } else {
            r.stage = 0; r.lapses += 1
            r.due = attempt.timestamp.addingTimeInterval(86400)
        }
        reviews[objective.id] = r
    }
    @discardableResult public mutating func completeGame(id: UUID, kind: String, count: Int, now: Date) -> Bool {
        guard ["bingo","lineup","grid","mystery","memory","timeline"].contains(kind), count > 0, !sessions.contains(where:{$0.id == id}) else {return false}
        sessions.append(SessionRecord(id:id,kind:"game-"+kind,completedAt:now,attemptCount:count))
        streak.record(now,zone:homeTimeZone);return true
    }
    @discardableResult public mutating func completePractice(id: UUID, count: Int, now: Date) -> Bool {
        guard count > 0 && !sessions.contains(where:{$0.id == id}) else { return false }
        sessions.append(SessionRecord(id:id, kind:"practice", completedAt:now, attemptCount:count))
        streak.record(now, zone:homeTimeZone)
        return true
    }
    public func tier(_ card: AlbumCard) -> Int {
        guard acquiredCards.contains(card.id) else { return -1 }
        if let achievement=cardAchievements?[card.id],achievement.knowledgeVersion != card.knowledgeVersion {return achievement.tier}
        return max(cardAchievements?[card.id]?.tier ?? 0,card.objectiveIDs.map { reviews[$0]?.highestEarned ?? 0 }.min() ?? 0)
    }
    public static let tierNames = ["Cardboard", "Bronze", "Silver", "Gold", "Diamond"]
}
public struct StreakState: Codable, Sendable {
    public var activeDays: Set<String> = []
    public var protectedDays: Set<String> = []
    public var freezes = 1
    public var daysSinceRefill = 0
    public var longest = 0
    public init() {}
    public static func dayKey(_ date: Date, zone: String) -> String {
        let f = DateFormatter(); f.calendar = Calendar(identifier:.gregorian); f.locale = Locale(identifier:"en_US_POSIX"); f.timeZone = TimeZone(identifier:zone) ?? .gmt; f.dateFormat = "yyyy-MM-dd"
        return f.string(from:date)
    }
    private func calendar(_ zone: String) -> Calendar { var c = Calendar(identifier:.gregorian); c.timeZone = TimeZone(identifier:zone) ?? .gmt; return c }
    public mutating func record(_ date: Date, zone: String) {
        let key = Self.dayKey(date,zone:zone)
        guard activeDays.insert(key).inserted else { return }
        daysSinceRefill += 1
        let c = calendar(zone)
        let previous = c.date(byAdding:.day,value:-1,to:date)!, prior = c.date(byAdding:.day,value:-2,to:date)!
        let yesterday = Self.dayKey(previous,zone:zone)
        if !activeDays.contains(yesterday) && !protectedDays.contains(yesterday) && activeDays.contains(Self.dayKey(prior,zone:zone)) && freezes > 0 {
            protectedDays.insert(yesterday); freezes -= 1
        }
        if daysSinceRefill >= 7 { freezes = 1; daysSinceRefill = 0 }
        longest = max(longest, current(at:date,zone:zone))
    }
    public func current(at date: Date, zone: String) -> Int {
        let c = calendar(zone)
        var d = date
        if !activeDays.contains(Self.dayKey(d,zone:zone)) { d = c.date(byAdding:.day,value:-1,to:d)! }
        var count = 0
        while true {
            let key = Self.dayKey(d,zone:zone)
            if activeDays.contains(key) { count += 1 }
            else if !protectedDays.contains(key) { break }
            d = c.date(byAdding:.day,value:-1,to:d)!
        }
        return count
    }
}
public enum SaveError: Error, LocalizedError {
    case recovery(String)
    public var errorDescription: String? { if case .recovery(let s) = self { return s }; return nil }
}
public struct StateStore {
    public let directory: URL
    public init(directory: URL) { self.directory = directory }
    public var file: URL { directory.appendingPathComponent("learner.json") }
    public var backup: URL { directory.appendingPathComponent("learner-backup.json") }
    public func save(_ state: LearnerState) throws {
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        let data = try JSONEncoder().encode(state)
        if let old = try? Data(contentsOf:file), (try? decode(old)) != nil { try old.write(to:backup, options:.atomic) }
        try data.write(to:file,options:.atomic)
    }
    private func decode(_ data: Data) throws -> LearnerState {
        let s = try JSONDecoder().decode(LearnerState.self,from:data)
        guard s.schemaVersion == 1, (s.cardAchievements?.values.allSatisfy({(0...4).contains($0.tier) && ($0.knowledgeVersion.map {$0 > 0} ?? true)}) ?? true), (s.preferredSessionSize == nil || [5,10,20].contains(s.preferredSessionSize!)), TimeZone(identifier:s.homeTimeZone) != nil,
              s.reviews.values.allSatisfy({ (0...4).contains($0.stage) && (0...4).contains($0.highestEarned) && $0.highestEarned >= $0.stage && $0.lapses >= 0 && $0.revision > 0 }),
              s.resumes.values.allSatisfy({ (0...6).contains($0.step) && Set($0.matched).count == $0.matched.count && Set($0.matched).isSubset(of:["l-0","l-1","l-2"]) && ($0.memoryOrder == nil || ($0.memoryOrder!.count == 6 && Set($0.memoryOrder!) == Set(["l-0","l-1","l-2","r-0","r-1","r-2"]))) }),
              (0...1).contains(s.streak.freezes), (0..<7).contains(s.streak.daysSinceRefill), s.streak.longest >= 0,
              Set(s.sessions.map(\.id)).count == s.sessions.count else { throw SaveError.recovery("Unsupported saved progress.") }
        return s
    }
    public func archiveBeforeContentUpdate(_ state: LearnerState) throws {
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        let file=directory.appendingPathComponent("learner-before-content-update-\(UUID().uuidString).json")
        try JSONEncoder().encode(state).write(to:file,options:.atomic)
    }
    public func load() throws -> LearnerState? { try loadWithNotice().state }
    public func loadWithNotice() throws -> (state: LearnerState?, notice: String?) {
        guard FileManager.default.fileExists(atPath:file.path) else { return (nil,nil) }
        do { return (try decode(Data(contentsOf:file)),nil) }
        catch {
            let preserved = directory.appendingPathComponent("learner-damaged-\(UUID().uuidString).json")
            try FileManager.default.copyItem(at:file,to:preserved)
            if let b = try? decode(Data(contentsOf:backup)) { return (b,"Your latest save could not be read. We restored the previous working save and preserved the damaged file.") }
            throw SaveError.recovery("Your saved progress could not be read. It has been preserved. You can retry or explicitly reset it in Settings.")
        }
    }
}
