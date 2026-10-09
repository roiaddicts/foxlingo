import Foundation

/// A missed game connection is practice evidence, not a failed scheduled recall.
public struct PracticeGap: Codable, Identifiable, Sendable {
    public let id: UUID
    public let game: String
    public let context: String
    public let subjectIDs: [UUID]
    public let factIDs: [UUID]
    public let timestamp: Date
    public init(game: String,context: String,subjectIDs: [UUID],factIDs: [UUID]=[],timestamp: Date) {
        id=UUID();self.game=game;self.context=context;self.subjectIDs=subjectIDs;self.factIDs=factIDs;self.timestamp=timestamp
    }
}
public struct PracticeRecommendation: Identifiable, Sendable {
    public var id: UUID {lesson.id}
    public let lesson: Lesson
    public let context: String
    public let exactFact: Bool
}
public enum PracticeRecommendations {
    public static func lessons(pack: ContentPack,gaps: [PracticeGap],limit: Int=3) -> [PracticeRecommendation] {
        let recent=Array(gaps.suffix(100))
        let facts=Dictionary(uniqueKeysWithValues:pack.facts.map {($0.id,$0)})
        let objectives=Dictionary(uniqueKeysWithValues:pack.objectives.map {($0.id,$0)})
        let ranked=pack.lessons.compactMap {lesson -> (Int,Date,PracticeRecommendation)? in
            let ids=Set(lesson.objectiveIDs.flatMap {objectives[$0]?.factIDs ?? []})
            let subjects=Set(ids.compactMap {facts[$0]?.subjectID})
            let matches=recent.filter {!ids.isDisjoint(with:$0.factIDs) || !subjects.isDisjoint(with:$0.subjectIDs)}
            guard let latest=matches.max(by:{$0.timestamp < $1.timestamp}) else {return nil}
            let exact=matches.contains {!ids.isDisjoint(with:$0.factIDs)}
            let score=matches.reduce(0) {$0+(!ids.isDisjoint(with:$1.factIDs) ? 4 : 1)}
            return (score,latest.timestamp,PracticeRecommendation(lesson:lesson,context:latest.context,exactFact:exact))
        }.sorted {a,b in
            if a.0 != b.0 {return a.0 > b.0}
            if a.1 != b.1 {return a.1 > b.1}
            return a.2.lesson.key < b.2.lesson.key
        }
        return ranked.prefix(max(0,limit)).map {$0.2}
    }
}
extension LearnerState {
    public mutating func recordPracticeGap(_ gap: PracticeGap) {
        var gaps=practiceGaps ?? [];gaps.append(gap);practiceGaps=Array(gaps.suffix(500))
    }
}
