import XCTest
@testable import FoxlingoCore

final class RoadmapTests: XCTestCase {
    var pack: ContentPack!
    let now=Date(timeIntervalSince1970:1_800_000_000)
    override func setUpWithError() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
    }
    func roadmap(_ key:String) -> Roadmap {pack.roadmaps.first {$0.key == key}!}
    func testPlayerPathsUseCanonicalLessonsAndOptionalContext() {
        XCTAssertEqual(pack.clubRoadmaps.count,70);XCTAssertEqual(pack.playerRoadmaps.count,103)
        XCTAssertEqual(pack.lessons.count,643);XCTAssertEqual(pack.objectives.count,1928);XCTAssertEqual(pack.cards.count,177)
        for path in pack.playerRoadmaps {
            let progress=RoadmapProgress.make(roadmap:path,pack:pack,state:LearnerState())
            let expectedLessons = path.key == "roadmap-player-cristiano" ? 8 : (path.key == "roadmap-player-xavi" ? 5 : 4)
            XCTAssertEqual(progress.requiredLessonIDs.count,expectedLessons);XCTAssertEqual(progress.optionalLessonIDs.count,1)
            XCTAssertEqual(progress.requiredObjectiveIDs.count,expectedLessons*3)
            XCTAssertTrue(path.chapters.first {$0.isOptional == true}!.note!.contains("player-specific"))
            let club=pack.clubRoadmaps.first {$0.clubID == path.clubID}!
            let optional=path.chapters.filter {$0.isOptional == true}.flatMap(\.lessonIDs)
            XCTAssertTrue(Set(optional).isSubset(of:Set(club.chapters.flatMap(\.lessonIDs))))
            if ["roadmap-player-riascos","roadmap-player-arce","roadmap-player-saucedo","roadmap-player-ramos","roadmap-player-casillas"].contains(path.key) {
                XCTAssertTrue(Set(path.chapters.flatMap(\.lessonIDs)).isSubset(of:Set(club.chapters.flatMap(\.lessonIDs))))
            }
        }
        XCTAssertEqual(RoadmapProgress.make(roadmap:roadmap("roadmap-player-ramos"),pack:pack,state:LearnerState()).optionalObjectiveIDs.count,2)
    }
    func testPlayerSelectionPreservesClubAndSurvivesSaveAndClubSwitch() throws {
        var state=LearnerState();state.selectClub(roadmap("roadmap-xolos").clubID!)
        let player=roadmap("roadmap-player-cristiano")
        state.selectRoadmap(player,pack:pack)
        XCTAssertEqual(state.activeRoadmap(pack)?.id,player.id);XCTAssertEqual(state.selectedClub,roadmap("roadmap-xolos").clubID!)
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        let store=StateStore(directory:directory);try store.save(state)
        var restored=try XCTUnwrap(store.load())
        XCTAssertEqual(restored.activeRoadmap(pack)?.id,player.id)
        restored.selectClub(roadmap("roadmap-madrid").clubID!)
        XCTAssertNil(restored.selectedRoadmapID);XCTAssertEqual(restored.activeRoadmap(pack)?.key,"roadmap-madrid")
    }
    func testUnknownRoadmapAndOldSaveFallBackToPreferredClub() throws {
        var state=LearnerState();state.selectedClub=roadmap("roadmap-madrid").clubID!;state.selectedRoadmapID=UUID()
        XCTAssertEqual(state.activeRoadmap(pack)?.key,"roadmap-madrid")
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(state)) as! [String:Any]
        json.removeValue(forKey:"selectedRoadmapID")
        let old=try JSONDecoder().decode(LearnerState.self,from:JSONSerialization.data(withJSONObject:json))
        XCTAssertNil(old.selectedRoadmapID);XCTAssertEqual(old.activeRoadmap(pack)?.key,"roadmap-madrid")
    }
    func testPlayerStarterCompletesWithoutRequiringOptionalClubContext() {
        var state=LearnerState();let path=roadmap("roadmap-player-ramos")
        state.savedRoadmapIDs=[]
        state.selectClub(roadmap("roadmap-xolos").clubID!);state.selectRoadmap(path,pack:pack)
        let required=path.chapters[0].lessonIDs[0]
        state.completeLesson(pack.lesson(required),pack:pack,sessionID:UUID(),attempts:[],now:now)
        XCTAssertFalse(RoadmapProgress.make(roadmap:path,pack:pack,state:state).isComplete)
        let honours=path.chapters.last!.lessonIDs[0]
        state.completeLesson(pack.lesson(honours),pack:pack,sessionID:UUID(),attempts:[],now:now)
        XCTAssertFalse(RoadmapProgress.make(roadmap:path,pack:pack,state:state).isComplete)
        for id in RoadmapProgress.make(roadmap:path,pack:pack,state:state).requiredLessonIDs where !state.completedLessons.contains(id) {
            state.completeLesson(pack.lesson(id),pack:pack,sessionID:UUID(),attempts:[],now:now)
        }
        let progress=RoadmapProgress.make(roadmap:path,pack:pack,state:state)
        XCTAssertTrue(progress.isComplete);XCTAssertEqual(progress.completedRequired,4);XCTAssertEqual(progress.completedOptional,0)
        XCTAssertNil(DailyStudyPlan.make(pack:pack,state:state,now:now).lessonID)
        let clubProgress=RoadmapProgress.make(roadmap:roadmap("roadmap-madrid"),pack:pack,state:state)
        XCTAssertEqual(clubProgress.completedRequired,4)
        XCTAssertEqual(state.reviews.count,12);XCTAssertEqual(state.acquiredCards.count,2)
        let existingDue=state.reviews.mapValues(\.due)
        state.completeLesson(pack.lesson(required),pack:pack,sessionID:UUID(),attempts:[],now:now.addingTimeInterval(3600))
        XCTAssertEqual(state.reviews.mapValues(\.due),existingDue);XCTAssertEqual(state.reviews.count,12)
    }
    func testCrossPathResumeAndOptionalResumeShareOneSession() {
        var state=LearnerState();let player=roadmap("roadmap-player-casillas"),lesson=player.chapters[0].lessonIDs[0]
        let resume=LessonResume(step:1)
        state.resumes[lesson]=resume;state.selectRoadmap(player,pack:pack)
        XCTAssertEqual(DailyStudyPlan.make(pack:pack,state:state,now:now).lessonID,lesson)
        state.selectClub(player.clubID!)
        XCTAssertEqual(DailyStudyPlan.make(pack:pack,state:state,now:now).lessonID,lesson)
        XCTAssertEqual(state.resumes[lesson]?.sessionID,resume.sessionID)
        state.resumes.removeAll();state.completedLessons.insert(lesson);state.selectRoadmap(player,pack:pack)
        let context=player.chapters[1].lessonIDs[0];state.resumes[context]=LessonResume(step:1)
        let plan=DailyStudyPlan.make(pack:pack,state:state,now:now)
        XCTAssertTrue(plan.isResuming);XCTAssertEqual(plan.lessonID,context)
    }
    func testClubOnlyConsumersIgnorePlayerPathsEvenWhenTheyComeFirst() throws {
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        let all=json["roadmaps"] as! [[String:Any]]
        json["roadmaps"]=all.filter {$0["subjectID"] != nil}+all.filter {$0["subjectID"] == nil}
        let reordered=try ContentPack.load(JSONSerialization.data(withJSONObject:json))
        let coverage=try CoverageStudyPack.make(pack:reordered,firstID:roadmap("roadmap-xolos").clubID!,secondID:roadmap("roadmap-madrid").clubID!)
        XCTAssertEqual(coverage.first.lessonIDs.count,17);XCTAssertEqual(coverage.second.lessonIDs.count,29)
        let album=AlbumCollection.make(pack:reordered,state:LearnerState(),scope:.all,discoveredOnly:false,query:"")
        XCTAssertEqual(album.total,177);XCTAssertEqual(album.sections.count,74)
        var state=LearnerState();state.selectClub(roadmap("roadmap-madrid").clubID!)
        XCTAssertEqual(state.activeRoadmap(reordered)?.key,"roadmap-madrid")
    }
    func testInvalidSubjectClubAndOptionalOnlyRoadmapsReject() throws {
        let base=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        for field in ["subjectID","clubID","chapters"] {
            var json=base,rows=json["roadmaps"] as! [[String:Any]]
            let index=rows.firstIndex {$0["key"] as! String == "roadmap-player-ramos"}!
            if field == "chapters" {var chapters=rows[index][field] as! [[String:Any]];for i in chapters.indices {chapters[i]["isOptional"]=true};rows[index][field]=chapters}
            else {rows[index][field]=field == "clubID" ? pack.playerRoadmaps[0].entityID.uuidString : UUID().uuidString}
            json["roadmaps"]=rows;XCTAssertThrowsError(try ContentPack.load(JSONSerialization.data(withJSONObject:json)))
        }
        var json=base,rows=(base["roadmaps"] as! [[String:Any]]).filter {$0["key"] as! String != "roadmap-madrid"}
        let index=rows.firstIndex {$0["key"] as! String == "roadmap-xolos"}!
        rows[index]["subjectID"]=roadmap("roadmap-madrid").clubID!.uuidString
        json["roadmaps"]=rows
        XCTAssertThrowsError(try ContentPack.load(JSONSerialization.data(withJSONObject:json)))
    }
    func testOlderClubOnlyPackWithoutSubjectMetadataLoads() throws {
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        var rows=(json["roadmaps"] as! [[String:Any]]).filter {$0["subjectID"] == nil}
        for i in rows.indices {rows[i].removeValue(forKey:"summary")}
        json["roadmaps"]=rows
        let old=try ContentPack.load(JSONSerialization.data(withJSONObject:json))
        XCTAssertEqual(old.clubRoadmaps.count,70);XCTAssertTrue(old.playerRoadmaps.isEmpty)
        XCTAssertEqual(old.roadmaps[0].entityID,old.roadmaps[0].clubID)
    }
}
