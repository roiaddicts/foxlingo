import Foundation

extension ContentPack {
    public var clubRoadmaps: [Roadmap] {roadmaps.filter {entity($0.entityID).type == "club"}}
    public var competitionRoadmaps: [Roadmap] {roadmaps.filter {entity($0.entityID).type == "competition"}}
    public var playerRoadmaps: [Roadmap] {roadmaps.filter {entity($0.entityID).type == "player"}}
}
extension LearnerState {
    public func activeRoadmap(_ pack: ContentPack) -> Roadmap? {
        if let id=selectedRoadmapID,let selected=pack.roadmaps.first(where:{$0.id == id}) {return selected}
        return pack.clubRoadmaps.first {$0.clubID == selectedClub} ?? pack.clubRoadmaps.first ?? pack.roadmaps.first
    }
    public mutating func selectRoadmap(_ roadmap: Roadmap,pack: ContentPack) {
        selectedRoadmapID=roadmap.id
        if pack.entity(roadmap.entityID).type == "club" {selectedClub=roadmap.clubID}
    }
    public mutating func selectClub(_ id: UUID) {selectedClub=id;selectedRoadmapID=nil}
}
public struct RoadmapProgress: Sendable {
    public let requiredLessonIDs: [UUID]
    public let optionalLessonIDs: [UUID]
    public let completedRequired: Int
    public let completedOptional: Int
    public let requiredObjectiveIDs: Set<UUID>
    public let optionalObjectiveIDs: Set<UUID>
    public var isComplete: Bool {!requiredLessonIDs.isEmpty && completedRequired == requiredLessonIDs.count}
    public static func make(roadmap: Roadmap,pack: ContentPack,state: LearnerState) -> Self {
        let required=roadmap.chapters.filter {$0.isOptional != true}.flatMap(\.lessonIDs)
        let optional=roadmap.chapters.filter {$0.isOptional == true}.flatMap(\.lessonIDs)
        let memories=Set(required.flatMap {pack.lesson($0).objectiveIDs})
        return Self(requiredLessonIDs:required,optionalLessonIDs:optional,completedRequired:required.filter {state.completedLessons.contains($0)}.count,completedOptional:optional.filter {state.completedLessons.contains($0)}.count,requiredObjectiveIDs:memories,optionalObjectiveIDs:Set(optional.flatMap {pack.lesson($0).objectiveIDs}).subtracting(memories))
    }
}
