import Foundation

/// Derived from canonical progress, never a second source of learning state.
/// A route copies these IDs at launch so answering cannot reshuffle its deck.
public struct DailyStudyPlan: Sendable {
    public let totalDue: Int
    public let dueObjectiveIDs: [UUID]
    public let lessonID: UUID?
    public let lessonRoadmapID: UUID?
    public let isResuming: Bool
    public let mistakeObjectiveIDs: [UUID]
    public let rehearsalObjectiveIDs: [UUID]

    public static func make(pack: ContentPack, state: LearnerState, now: Date, limit: Int = 10) -> Self {
        let size=max(1,min(20,limit))
        let due=state.dueObjectives(pack,now:now,limit:pack.objectives.count)
        let learned=pack.objectives.filter {state.reviews[$0.id]?.revision == $0.revision}
        let learnedIDs=Set(learned.map(\.id))
        var latest=[UUID:Attempt]()
        for attempt in state.attempts where learnedIDs.contains(attempt.objectiveID) && attempt.timestamp <= now && attempt.timestamp >= state.reviews[attempt.objectiveID]!.learnedAt && ["early","due"].contains(attempt.mode) {
            if latest[attempt.objectiveID].map({$0.timestamp <= attempt.timestamp}) ?? true {latest[attempt.objectiveID]=attempt}
        }
        // One current weakness per objective, bounded to the last week. A later
        // correct attempt clears it; seeing the answer does not count as recall.
        let mistakes=learned.filter {o in
            guard let a=latest[o.id] else {return false}
            return (!a.correct || a.hinted) && now.timeIntervalSince(a.timestamp) <= 7*86400
        }.sorted {a,b in
            let first=latest[a.id]!.timestamp, second=latest[b.id]!.timestamp
            return first == second ? a.key < b.key : first > second
        }
        // Rotate optional practice toward the least recently attempted facts,
        // rather than always rehearsing the first alphabetic ten.
        let rehearsal=learned.sorted {a,b in
            let first=latest[a.id]?.timestamp ?? state.reviews[a.id]!.learnedAt
            let second=latest[b.id]?.timestamp ?? state.reviews[b.id]!.learnedAt
            return first == second ? a.key < b.key : first < second
        }
        let selected=state.activeRoadmap(pack)
        let selectedLessons=selected?.chapters.flatMap(\.lessonIDs) ?? []
        let requiredLessons=selected?.chapters.filter {$0.isOptional != true}.flatMap(\.lessonIDs) ?? []
        var resumed=selectedLessons.first {state.resumes[$0] != nil}
        var next=resumed ?? requiredLessons.first {!state.completedLessons.contains($0)}
        var owner=next == nil ? nil : selected?.id
        if next == nil {
            for roadmap in state.savedRoadmaps(pack) where roadmap.id != selected?.id {
                let lessons=roadmap.chapters.filter {$0.isOptional != true}.flatMap(\.lessonIDs)
                let resume=lessons.first {state.resumes[$0] != nil}
                if let id=resume ?? lessons.first(where:{!state.completedLessons.contains($0)}) {
                    next=id;resumed=resume;owner=roadmap.id;break
                }
            }
        }
        return Self(totalDue:due.count,dueObjectiveIDs:Array(due.prefix(size)).map(\.id),lessonID:next,lessonRoadmapID:owner,isResuming:resumed != nil,mistakeObjectiveIDs:Array(mistakes.prefix(size)).map(\.id),rehearsalObjectiveIDs:Array(rehearsal.prefix(size)).map(\.id))
    }
}
