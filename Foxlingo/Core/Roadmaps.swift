import Foundation

extension ContentPack {
    public var clubRoadmaps: [Roadmap] {roadmaps.filter {entity($0.entityID).type == "club"}}
    public var competitionRoadmaps: [Roadmap] {roadmaps.filter {entity($0.entityID).type == "competition"}}
    public var playerRoadmaps: [Roadmap] {roadmaps.filter {entity($0.entityID).type == "player"}}
}
extension LearnerState {
    private func defaultSavedRoadmapIDs(_ pack: ContentPack) -> [UUID] {
        // Canonical IDs survive a first launch against a pack that retires a
        // favorite. Rollback can then restore its bookmark without re-migration.
        [UUID(uuidString:"778bc70b-5f93-56c1-8313-e2608dbf8098")!,UUID(uuidString:"bddbc932-cbaf-53b0-b140-826944a89ce2")!]
    }
    public mutating func initializeSavedRoadmaps(_ pack: ContentPack) {
        if savedRoadmapIDs == nil {savedRoadmapIDs=defaultSavedRoadmapIDs(pack)}
        var seen=Set<UUID>()
        savedRoadmapIDs=savedRoadmapIDs!.filter {seen.insert($0).inserted}
    }
    public func savedRoadmaps(_ pack: ContentPack) -> [Roadmap] {
        let paths=Dictionary(uniqueKeysWithValues:pack.roadmaps.map {($0.id,$0)})
        var seen=Set<UUID>()
        return (savedRoadmapIDs ?? defaultSavedRoadmapIDs(pack)).filter {seen.insert($0).inserted}.compactMap {paths[$0]}
    }
    public func unavailableSavedRoadmapCount(_ pack: ContentPack) -> Int {
        Set(savedRoadmapIDs ?? defaultSavedRoadmapIDs(pack)).count-savedRoadmaps(pack).count
    }
    public mutating func setRoadmapSaved(_ id: UUID,saved: Bool,pack: ContentPack) {
        initializeSavedRoadmaps(pack)
        if saved {
            guard pack.roadmaps.contains(where:{$0.id == id}),!savedRoadmapIDs!.contains(id) else {return}
            savedRoadmapIDs!.append(id)
        } else {savedRoadmapIDs!.removeAll {$0 == id}}
    }
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
