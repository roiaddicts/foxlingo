import Foundation

public struct CoverageClub: Sendable {
    public let clubID: UUID
    public let lessonIDs: [UUID]
    public let objectiveIDs: [UUID]
    public let factIDs: [UUID]
}
/// An evidence-backed comparison, not a fixture prediction. Selecting clubs
/// does not change the learner's roadmap or create acquisition/review progress.
public struct CoverageStudyPack: Sendable {
    public let first: CoverageClub
    public let second: CoverageClub
    public let objectiveIDs: [UUID]

    public static func make(pack: ContentPack, firstID: UUID, secondID: UUID) throws -> Self {
        guard firstID != secondID else {throw ContentError.invalid("Choose two different clubs.")}
        func club(_ id: UUID) throws -> CoverageClub {
            guard let roadmap=pack.clubRoadmaps.first(where:{$0.clubID == id}) else {throw ContentError.invalid("This club does not have a study roadmap yet.")}
            let lessons=roadmap.chapters.flatMap(\.lessonIDs)
            let objectives=unique(lessons.flatMap {pack.lesson($0).objectiveIDs})
            let facts=unique(objectives.flatMap {pack.objective($0).factIDs})
            return CoverageClub(clubID:id,lessonIDs:lessons,objectiveIDs:objectives,factIDs:facts)
        }
        let a=try club(firstID), b=try club(secondID)
        var mixed=[UUID]()
        for i in 0..<max(a.objectiveIDs.count,b.objectiveIDs.count) {
            if a.objectiveIDs.indices.contains(i) {mixed.append(a.objectiveIDs[i])}
            if b.objectiveIDs.indices.contains(i) {mixed.append(b.objectiveIDs[i])}
        }
        return Self(first:a,second:b,objectiveIDs:unique(mixed))
    }
    public func learnedObjectiveIDs(pack: ContentPack,state: LearnerState,now: Date,limit: Int) -> [UUID] {
        var latest=[UUID:Date]()
        for attempt in state.attempts where ["due","early"].contains(attempt.mode) && attempt.timestamp <= now {
            guard let review=state.reviews[attempt.objectiveID],attempt.timestamp >= review.learnedAt else {continue}
            latest[attempt.objectiveID]=max(latest[attempt.objectiveID] ?? .distantPast,attempt.timestamp)
        }
        func rotated(_ club: CoverageClub) -> [UUID] {
            club.objectiveIDs.filter {id in state.reviews[id]?.revision == pack.objective(id).revision}.enumerated().sorted {a,b in
                let first=latest[a.element] ?? state.reviews[a.element]!.learnedAt
                let second=latest[b.element] ?? state.reviews[b.element]!.learnedAt
                return first == second ? a.offset < b.offset : first < second
            }.map(\.element)
        }
        let a=rotated(first),b=rotated(second)
        var mixed=[UUID]()
        for i in 0..<max(a.count,b.count) {
            if a.indices.contains(i) {mixed.append(a[i])}
            if b.indices.contains(i) {mixed.append(b[i])}
        }
        return Array(Self.unique(mixed).prefix(max(1,min(20,limit))))
    }
    private static func unique(_ ids: [UUID]) -> [UUID] {
        var seen=Set<UUID>();return ids.filter {seen.insert($0).inserted}
    }
}
