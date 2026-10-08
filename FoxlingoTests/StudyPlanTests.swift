import XCTest
@testable import FoxlingoCore

final class StudyPlanTests: XCTestCase {
    var pack: ContentPack!
    let now=Date(timeIntervalSince1970:1_800_000_000)
    override func setUpWithError() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
    }
    func stateWithLearned(_ objectives: [Objective]) -> LearnerState {
        var state=LearnerState(timeZone:"America/Mexico_City")
        for o in objectives {state.reviews[o.id]=ReviewState(revision:o.revision,due:now.addingTimeInterval(-10),learnedAt:now.addingTimeInterval(-86400))}
        state.selectedClub=pack.roadmaps[0].clubID
        return state
    }
    func testBacklogIsTotalAndSessionRemainsFrozen() {
        let objectives=Array(pack.objectives.prefix(34))
        var state=stateWithLearned(objectives)
        let plan=DailyStudyPlan.make(pack:pack,state:state,now:now,limit:5)
        XCTAssertEqual(plan.totalDue,34);XCTAssertEqual(plan.dueObjectiveIDs.count,5)
        let first=pack.objective(plan.dueObjectiveIDs[0])
        state.recordRecall(Attempt(objectiveID:first.id,answer:first.answers[0],correct:true,hinted:false,mode:"due",timestamp:now),objective:first)
        XCTAssertEqual(plan.dueObjectiveIDs.count,5)
        XCTAssertEqual(DailyStudyPlan.make(pack:pack,state:state,now:now,limit:20).totalDue,33)
        XCTAssertEqual(DailyStudyPlan.make(pack:pack,state:state,now:now,limit:20).dueObjectiveIDs.count,20)
    }
    func testNewLearnerAndSelectedClubLesson() {
        var state=LearnerState();state.selectedClub=pack.roadmaps[1].clubID
        let plan=DailyStudyPlan.make(pack:pack,state:state,now:now)
        XCTAssertEqual(plan.lessonID,pack.roadmaps[1].chapters[0].lessonIDs[0]);XCTAssertFalse(plan.isResuming)
        XCTAssertTrue(plan.rehearsalObjectiveIDs.isEmpty);XCTAssertTrue(plan.dueObjectiveIDs.isEmpty)
        state.completedLessons=Set(pack.roadmaps[1].chapters.flatMap(\.lessonIDs))
        XCTAssertNil(DailyStudyPlan.make(pack:pack,state:state,now:now).lessonID)
    }
    func testResumeAcrossClubsKeepsSavedStep() {
        var state=LearnerState();state.selectedClub=pack.roadmaps[0].clubID
        let id=pack.roadmaps[1].chapters[0].lessonIDs[0]
        state.resumes[id]=LessonResume(step:3)
        let plan=DailyStudyPlan.make(pack:pack,state:state,now:now)
        XCTAssertEqual(plan.lessonID,id);XCTAssertTrue(plan.isResuming);XCTAssertEqual(state.resumes[id]?.step,3)
    }
    func testMistakesAreDistinctBoundedAndClearAfterCorrection() {
        let objectives=Array(pack.objectives.prefix(3));var state=stateWithLearned(objectives)
        func attempt(_ i: Int,_ seconds: Double,_ correct: Bool,_ hinted: Bool=false) -> Attempt {
            Attempt(objectiveID:objectives[i].id,answer:"answer",correct:correct,hinted:hinted,mode:"early",timestamp:now.addingTimeInterval(seconds))
        }
        state.attempts=[attempt(0,-5,false),attempt(0,-4,false),attempt(1,-8*86400,false),attempt(2,-3,false),attempt(2,-2,true)]
        XCTAssertEqual(DailyStudyPlan.make(pack:pack,state:state,now:now).mistakeObjectiveIDs,[objectives[0].id])
        state.attempts.append(attempt(0,-1,true,true))
        XCTAssertEqual(DailyStudyPlan.make(pack:pack,state:state,now:now).mistakeObjectiveIDs,[objectives[0].id])
        state.attempts.append(attempt(0,0,true))
        XCTAssertTrue(DailyStudyPlan.make(pack:pack,state:state,now:now).mistakeObjectiveIDs.isEmpty)
    }
    func testCorrectedContentIgnoresOldMistakesAndRecognitionCannotClearRecallMistake() {
        let objective=pack.objectives[0];var state=stateWithLearned([objective])
        state.attempts=[Attempt(objectiveID:objective.id,answer:"wrong",correct:false,hinted:false,mode:"due",timestamp:now.addingTimeInterval(-5)),Attempt(objectiveID:objective.id,answer:"seen",correct:true,hinted:false,mode:"acquisition",timestamp:now.addingTimeInterval(-1))]
        XCTAssertEqual(DailyStudyPlan.make(pack:pack,state:state,now:now).mistakeObjectiveIDs,[objective.id])
        state.reviews[objective.id]?.learnedAt=now
        XCTAssertTrue(DailyStudyPlan.make(pack:pack,state:state,now:now).mistakeObjectiveIDs.isEmpty)
    }
    func testOptionalPracticeRotatesAfterAttempt() {
        let objectives=Array(pack.objectives.prefix(12));var state=stateWithLearned(objectives)
        let original=DailyStudyPlan.make(pack:pack,state:state,now:now,limit:5).rehearsalObjectiveIDs
        for id in original {state.attempts.append(Attempt(objectiveID:id,answer:"answer",correct:true,hinted:false,mode:"early",timestamp:now))}
        let next=DailyStudyPlan.make(pack:pack,state:state,now:now,limit:5).rehearsalObjectiveIDs
        XCTAssertTrue(Set(original).isDisjoint(with:Set(next)))
    }
    func testSessionPreferencePersistsAndOldSaveLoads() throws {
        let dir=URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:dir)}
        let store=StateStore(directory:dir);var state=LearnerState();state.preferredSessionSize=5
        try store.save(state);XCTAssertEqual(try store.load()?.preferredSessionSize,5)
        var json=try JSONSerialization.jsonObject(with:Data(contentsOf:store.file)) as! [String:Any]
        json.removeValue(forKey:"preferredSessionSize")
        try JSONSerialization.data(withJSONObject:json).write(to:store.file)
        XCTAssertNil(try store.load()?.preferredSessionSize)
    }
}
