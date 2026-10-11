import XCTest
@testable import FoxlingoCore

final class CurriculumExpansionTests: XCTestCase {
    func testNewPlayerCoursesTeachTheirOwnFactsAndShareCanonicalClubLessons() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
        for key in ["entity-marco-reus","entity-patrik-schick","entity-buffon","entity-del-piero","entity-guillermo-ochoa","entity-jose-saturnino-cardozo","entity-hernan-cristante"] {
            let player=try XCTUnwrap(pack.entities.first {$0.key == key})
            let route=try XCTUnwrap(pack.playerRoadmaps.first {$0.entityID == player.id})
            let club=try XCTUnwrap(pack.clubRoadmaps.first {$0.clubID == route.clubID})
            let progress=RoadmapProgress.make(roadmap:route,pack:pack,state:LearnerState())
            XCTAssertEqual(progress.requiredLessonIDs.count,4)
            XCTAssertEqual(progress.requiredObjectiveIDs.count,12)
            XCTAssertEqual(progress.optionalLessonIDs.count,1)
            XCTAssertTrue(Set(progress.requiredLessonIDs).isSubset(of:Set(club.chapters.flatMap(\.lessonIDs))))
            for id in progress.requiredObjectiveIDs {
                let objective=pack.objective(id)
                XCTAssertTrue(objective.factIDs.allSatisfy {factID in pack.facts.first {$0.id == factID}?.subjectID == player.id})
            }
            var state=LearnerState()
            state.selectRoadmap(route,pack:pack)
            let lesson=pack.lesson(progress.requiredLessonIDs[0])
            state.completeLesson(lesson,pack:pack,sessionID:UUID(),attempts:[],now:Date())
            XCTAssertEqual(RoadmapProgress.make(roadmap:club,pack:pack,state:state).completedRequired,1)
            XCTAssertEqual(state.reviews.count,3)
            XCTAssertFalse(RoadmapProgress.make(roadmap:route,pack:pack,state:state).isComplete)
        }
        for key in ["entity-jose-saturnino-cardozo","entity-hernan-cristante"] {
            let player=try XCTUnwrap(pack.entities.first {$0.key == key})
            XCTAssertNil(player.externalRefs["futbol11.gamePlayers"])
            XCTAssertNil(player.imageAsset)
        }
        let wolfsburg=try XCTUnwrap(pack.entities.first {$0.key == "entity-wolfsburg"})
        XCTAssertNotNil(wolfsburg.imageAsset)
        XCTAssertFalse(pack.clubRoadmaps.contains {$0.clubID == wolfsburg.id})
    }
}
