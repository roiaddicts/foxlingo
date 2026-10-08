import XCTest
@testable import FoxlingoCore

final class SavedRoadmapTests: XCTestCase {
    var pack: ContentPack!
    let now=Date(timeIntervalSince1970:1_800_000_000)
    override func setUpWithError() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
    }
    func testLegacyMigrationAndExplicitEmptyPersist() throws {
        var state=LearnerState();state.selectRoadmap(pack.playerRoadmaps[0],pack:pack)
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(state)) as! [String:Any]
        json.removeValue(forKey:"savedRoadmapIDs")
        state=try JSONDecoder().decode(LearnerState.self,from:JSONSerialization.data(withJSONObject:json))
        let selected=state.selectedRoadmapID
        state.reconcile(pack,now:now)
        XCTAssertEqual(state.savedRoadmaps(pack).map(\.key),["roadmap-xolos","roadmap-madrid"])
        XCTAssertEqual(state.selectedRoadmapID,selected)
        state.savedRoadmapIDs=[]
        var restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        restored.reconcile(pack,now:now)
        XCTAssertEqual(restored.savedRoadmapIDs,[])
    }
    func testStableDeduplicationRetainsUnavailableIDsAcrossPackChanges() throws {
        let a=pack.playerRoadmaps[0],b=pack.competitionRoadmaps[0],unknown=UUID()
        var state=LearnerState();state.savedRoadmapIDs=[b.id,unknown,a.id,b.id]
        state.reconcile(pack,now:now)
        XCTAssertEqual(state.savedRoadmapIDs,[b.id,unknown,a.id])
        XCTAssertEqual(state.savedRoadmaps(pack).map(\.id),[b.id,a.id]);XCTAssertEqual(state.unavailableSavedRoadmapCount(pack),1)
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        json["roadmaps"]=(json["roadmaps"] as! [[String:Any]]).filter {$0["key"] as? String != a.key}
        let smaller=try ContentPack.load(JSONSerialization.data(withJSONObject:json))
        state.reconcile(smaller,now:now)
        XCTAssertEqual(state.savedRoadmaps(smaller).map(\.id),[b.id]);XCTAssertEqual(state.unavailableSavedRoadmapCount(smaller),2)
        state.reconcile(pack,now:now)
        XCTAssertEqual(state.savedRoadmaps(pack).map(\.id),[b.id,a.id])
    }
    func testLegacyFavoriteMissingAtFirstMigrationReturnsOnRollback() throws {
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        json["roadmaps"]=(json["roadmaps"] as! [[String:Any]]).filter {$0["key"] as? String != "roadmap-madrid"}
        let smaller=try ContentPack.load(JSONSerialization.data(withJSONObject:json))
        var state=LearnerState();state.reconcile(smaller,now:now)
        XCTAssertEqual(state.savedRoadmapIDs?.count,2);XCTAssertEqual(state.unavailableSavedRoadmapCount(smaller),1)
        state.reconcile(pack,now:now)
        XCTAssertEqual(state.savedRoadmaps(pack).map(\.key),["roadmap-xolos","roadmap-madrid"])
    }
    func testSelectionDoesNotSaveAndRemovalPreservesLearningAndGlobalDue() throws {
        var state=LearnerState();state.savedRoadmapIDs=[]
        let path=pack.playerRoadmaps[0],lesson=pack.lesson(path.chapters[0].lessonIDs[0])
        state.selectRoadmap(path,pack:pack);XCTAssertEqual(state.savedRoadmapIDs,[])
        state.completeLesson(lesson,pack:pack,sessionID:UUID(),attempts:[],now:now)
        state.resumes[lesson.id]=LessonResume(step:1)
        let before=try JSONEncoder().encode(state)
        state.setRoadmapSaved(path.id,saved:true,pack:pack);state.setRoadmapSaved(path.id,saved:true,pack:pack)
        XCTAssertEqual(state.savedRoadmapIDs,[path.id])
        state.setRoadmapSaved(path.id,saved:false,pack:pack)
        XCTAssertEqual(try JSONEncoder().encode(state).count,before.count)
        let original=try JSONDecoder().decode(LearnerState.self,from:before)
        XCTAssertEqual(state.selectedRoadmapID,original.selectedRoadmapID)
        XCTAssertEqual(state.completedLessons,original.completedLessons);XCTAssertEqual(state.acquiredCards,original.acquiredCards)
        XCTAssertEqual(state.resumes[lesson.id]?.sessionID,original.resumes[lesson.id]?.sessionID)
        XCTAssertEqual(state.reviews.mapValues(\.due),original.reviews.mapValues(\.due))
        XCTAssertEqual(state.sessions.count,original.sessions.count)
        XCTAssertEqual(DailyStudyPlan.make(pack:pack,state:state,now:now.addingTimeInterval(86401)).totalDue,lesson.objectiveIDs.count)
    }
    func testSavedPriorityAndSharedLessonOwnerAvoidUnrelatedResume() {
        let selected=pack.competitionRoadmaps[0],player=pack.playerRoadmaps[0],other=pack.competitionRoadmaps[1]
        var state=LearnerState();state.selectRoadmap(selected,pack:pack);state.savedRoadmapIDs=[player.id,other.id]
        let unrelated=pack.clubRoadmaps[0].chapters[0].lessonIDs[0]
        state.resumes[unrelated]=LessonResume(step:2)
        XCTAssertEqual(DailyStudyPlan.make(pack:pack,state:state,now:now).lessonRoadmapID,selected.id)
        state.completedLessons=Set(selected.chapters.filter {$0.isOptional != true}.flatMap(\.lessonIDs))
        let suggested=DailyStudyPlan.make(pack:pack,state:state,now:now)
        XCTAssertEqual(suggested.lessonRoadmapID,player.id);XCTAssertFalse(suggested.isResuming)
        state.savedRoadmapIDs=[other.id,player.id]
        XCTAssertEqual(DailyStudyPlan.make(pack:pack,state:state,now:now).lessonRoadmapID,other.id)
        state.savedRoadmapIDs=[]
        XCTAssertNil(DailyStudyPlan.make(pack:pack,state:state,now:now).lessonID)
        XCTAssertEqual(state.resumes[unrelated]?.step,2)
    }
}
