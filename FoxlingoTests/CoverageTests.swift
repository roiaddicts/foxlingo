import XCTest
@testable import FoxlingoCore

final class CoverageTests: XCTestCase {
    var pack: ContentPack!
    let now=Date(timeIntervalSince1970:1_800_000_000)
    var xolos: UUID {pack.entities.first {$0.key == "entity-xolos"}!.id}
    var madrid: UUID {pack.entities.first {$0.key == "entity-madrid"}!.id}
    override func setUpWithError() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
    }
    func testDistinctCanonicalClubSelectionAndUnknownRoadmap() {
        XCTAssertThrowsError(try CoverageStudyPack.make(pack:pack,firstID:xolos,secondID:xolos))
        XCTAssertThrowsError(try CoverageStudyPack.make(pack:pack,firstID:xolos,secondID:UUID()))
    }
    func testSharedObjectivesDeduplicateAndClubsInterleave() throws {
        let study=try CoverageStudyPack.make(pack:pack,firstID:xolos,secondID:madrid)
        XCTAssertEqual(study.objectiveIDs.count,Set(study.objectiveIDs).count)
        XCTAssertEqual(study.objectiveIDs[0],study.first.objectiveIDs[0])
        XCTAssertEqual(study.objectiveIDs[1],study.second.objectiveIDs[0])
        let raw=study.second.lessonIDs.flatMap {pack.lesson($0).objectiveIDs}
        XCTAssertGreaterThan(raw.count,study.second.objectiveIDs.count)
        for club in [study.first,study.second] {
            for id in club.factIDs {
                let fact=pack.facts.first {$0.id == id}!
                XCTAssertFalse(fact.scope.isEmpty);XCTAssertFalse(fact.sourceKeys.isEmpty)
                XCTAssertTrue(fact.sourceKeys.allSatisfy {key in pack.sources.contains {$0.key == key}})
            }
        }
    }
    func testPreviewDoesNotCreateLearningState() throws {
        let study=try CoverageStudyPack.make(pack:pack,firstID:xolos,secondID:madrid)
        var state=LearnerState();state.selectedClub=madrid
        XCTAssertTrue(study.learnedObjectiveIDs(pack:pack,state:state,now:now,limit:10).isEmpty)
        XCTAssertTrue(state.reviews.isEmpty);XCTAssertTrue(state.acquiredCards.isEmpty)
        XCTAssertEqual(state.selectedClub,madrid)
        let lesson=pack.lesson(study.first.lessonIDs[0])
        state.completeLesson(lesson,pack:pack,sessionID:UUID(),attempts:[],now:now)
        XCTAssertEqual(study.learnedObjectiveIDs(pack:pack,state:state,now:now,limit:10),lesson.objectiveIDs)
    }
    func testDeckExcludesObsoleteRevisionsAndKeepsSelectedIDs() throws {
        let study=try CoverageStudyPack.make(pack:pack,firstID:xolos,secondID:madrid)
        var state=LearnerState()
        for id in study.objectiveIDs {state.reviews[id]=ReviewState(revision:pack.objective(id).revision,due:now,learnedAt:now)}
        let first=study.objectiveIDs[0];state.reviews[first]?.revision += 1
        let deck=study.learnedObjectiveIDs(pack:pack,state:state,now:now,limit:5)
        XCTAssertEqual(deck.count,5);XCTAssertFalse(deck.contains(first))
        state.reviews.removeAll()
        XCTAssertEqual(deck.count,5)
        XCTAssertTrue(study.learnedObjectiveIDs(pack:pack,state:state,now:now,limit:5).isEmpty)
    }
    func testShortCoverageSessionsRotateAndPreviewKeepsDueUnchanged() throws {
        let study=try CoverageStudyPack.make(pack:pack,firstID:xolos,secondID:madrid)
        var state=LearnerState()
        for id in study.objectiveIDs {state.reviews[id]=ReviewState(revision:pack.objective(id).revision,due:now,learnedAt:now.addingTimeInterval(-86400))}
        let first=study.learnedObjectiveIDs(pack:pack,state:state,now:now,limit:5)
        for id in first {
            let objective=pack.objective(id)
            state.recordRecall(Attempt(objectiveID:id,answer:objective.answers[0],correct:true,hinted:true,mode:"early",timestamp:now),objective:objective)
            XCTAssertEqual(state.reviews[id]?.stage,0);XCTAssertEqual(state.reviews[id]?.due,now)
        }
        let second=study.learnedObjectiveIDs(pack:pack,state:state,now:now,limit:5)
        XCTAssertTrue(Set(first).isDisjoint(with:Set(second)))
        XCTAssertFalse(Set(second).isDisjoint(with:Set(study.first.objectiveIDs)))
        XCTAssertFalse(Set(second).isDisjoint(with:Set(study.second.objectiveIDs)))
    }
    func testMixedRecallAdvancesDueButNotEarlyObjectives() throws {
        let study=try CoverageStudyPack.make(pack:pack,firstID:xolos,secondID:madrid)
        var state=LearnerState()
        let a=pack.objective(study.objectiveIDs[0]), b=pack.objective(study.objectiveIDs[1])
        state.reviews[a.id]=ReviewState(revision:a.revision,due:now,learnedAt:now.addingTimeInterval(-86400))
        state.reviews[b.id]=ReviewState(revision:b.revision,due:now.addingTimeInterval(86400),learnedAt:now)
        for o in [a,b] {state.recordRecall(Attempt(objectiveID:o.id,answer:o.answers[0],correct:true,hinted:false,mode:"due",timestamp:now),objective:o)}
        XCTAssertEqual(state.reviews[a.id]?.stage,1);XCTAssertEqual(state.reviews[b.id]?.stage,0)
        XCTAssertEqual(state.reviews[b.id]?.due,now.addingTimeInterval(86400))
        XCTAssertTrue(state.acquiredCards.isEmpty)
    }
}
