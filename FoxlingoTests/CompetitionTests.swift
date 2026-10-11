import XCTest
@testable import FoxlingoCore

final class CompetitionTests: XCTestCase {
    var pack: ContentPack!
    let now=Date(timeIntervalSince1970:1_800_000_000)
    override func setUpWithError() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
    }
    func testIndependentCoursesShareOnlyOptionalClubContext() {
        XCTAssertEqual(pack.competitionRoadmaps.count,4)
        for path in pack.competitionRoadmaps {
            XCTAssertNil(path.clubID)
            let progress=RoadmapProgress.make(roadmap:path,pack:pack,state:LearnerState())
            XCTAssertEqual(progress.requiredLessonIDs.count,3);XCTAssertEqual(progress.requiredObjectiveIDs.count,9)
            XCTAssertEqual(progress.optionalLessonIDs.count,1)
            XCTAssertTrue(pack.clubRoadmaps.contains { $0.chapters.flatMap(\.lessonIDs).contains(progress.optionalLessonIDs[0]) })
            let card=pack.cards.first {$0.entityID == path.entityID}!
            XCTAssertEqual(Set(card.objectiveIDs),progress.requiredObjectiveIDs)
            XCTAssertEqual(Set(card.lessonIDs),Set(progress.requiredLessonIDs))
            XCTAssertTrue(progress.requiredObjectiveIDs.isDisjoint(with:progress.optionalObjectiveIDs))
        }
    }
    func testSelectionAndSavePreservePreferredClub() throws {
        var state=LearnerState()
        let club=pack.clubRoadmaps.first {$0.key == "roadmap-xolos"}!
        let course=pack.competitionRoadmaps[0]
        state.selectClub(club.entityID);state.selectRoadmap(course,pack:pack)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        XCTAssertEqual(restored.activeRoadmap(pack)?.id,course.id);XCTAssertEqual(restored.selectedClub,club.entityID)
        XCTAssertThrowsError(try CoverageStudyPack.make(pack:pack,firstID:club.entityID,secondID:course.entityID))
    }
    func testOptionalStoryDoesNotCompleteFoundationsOrDuplicateMemories() {
        var state=LearnerState();let course=pack.competitionRoadmaps.first {$0.key == "roadmap-competition-liga-mx"}!
        state.savedRoadmapIDs=[]
        let p=RoadmapProgress.make(roadmap:course,pack:pack,state:state)
        let optional=pack.lesson(p.optionalLessonIDs[0])
        state.completeLesson(optional,pack:pack,sessionID:UUID(),attempts:[],now:now)
        XCTAssertEqual(RoadmapProgress.make(roadmap:course,pack:pack,state:state).completedRequired,0)
        let card=pack.cards.first {$0.entityID == course.entityID}!
        XCTAssertFalse(state.acquiredCards.contains(card.id))
        for id in p.requiredLessonIDs {state.completeLesson(pack.lesson(id),pack:pack,sessionID:UUID(),attempts:[],now:now)}
        XCTAssertTrue(RoadmapProgress.make(roadmap:course,pack:pack,state:state).isComplete)
        XCTAssertTrue(state.acquiredCards.contains(card.id));XCTAssertEqual(state.reviews.count,12)
        let due=state.reviews.mapValues(\.due)
        state.completeLesson(optional,pack:pack,sessionID:UUID(),attempts:[],now:now.addingTimeInterval(3600))
        XCTAssertEqual(state.reviews.mapValues(\.due),due)
        state.selectRoadmap(course,pack:pack)
        XCTAssertNil(DailyStudyPlan.make(pack:pack,state:state,now:now).lessonID)
    }
    func testAlbumCollectionsExposeCompetitionWithoutBorrowingClubCards() {
        let state=LearnerState()
        let courses=AlbumCollection.make(pack:pack,state:state,scope:.competitions,discoveredOnly:false,query:"")
        XCTAssertEqual(courses.total,4)
        XCTAssertTrue(courses.sections.flatMap(\.cards).allSatisfy {pack.entity($0.entityID).type == "competition"})
        let favorites=AlbumCollection.make(pack:pack,state:state,scope:.favorites,discoveredOnly:false,query:"")
        XCTAssertEqual(favorites.total,14)
        XCTAssertFalse(favorites.sections.flatMap(\.cards).contains {pack.entity($0.entityID).type == "competition"})
        let league=AlbumCollection.make(pack:pack,state:state,scope:.bundesliga,discoveredOnly:false,query:"German league")
        XCTAssertEqual(league.total,25);XCTAssertEqual(league.visibleCount,1)
    }
    func testMissingSubjectAndFalseClubContextAreRejected() throws {
        let base=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        for falseContext in [false,true] {
            var json=base,rows=base["roadmaps"] as! [[String:Any]]
            let index=rows.firstIndex {$0["key"] as? String == "roadmap-competition-bundesliga"}!
            if falseContext {rows[index]["clubID"]=pack.clubRoadmaps[0].entityID.uuidString}
            else {rows[index].removeValue(forKey:"subjectID");rows[index].removeValue(forKey:"clubID")}
            json["roadmaps"]=rows
            XCTAssertThrowsError(try ContentPack.load(JSONSerialization.data(withJSONObject:json)))
        }
    }
    func testTypedReviewAcceptsEquivalentNamesButRejectsDistractors() {
        for (key,answers,wrong) in [
            ("ligamx-first-professional-season",["1943/44","1943-44"],"1944/45"),
            ("ucl-original-name",["European Cup","European Champion Clubs’ Cup"],"European Super Cup"),
            ("ligamx-original-short-names",["Invierno y Verano","Verano and Invierno"],"Apertura and Clausura"),
            ("ligamx-later-short-names",["Clausura y Apertura","Apertura and Clausura"],"Invierno and Verano")
        ] {
            let objective=pack.objectives.first {$0.key == "objective-competition-"+key}!
            for answer in answers {XCTAssertTrue(Recall.accepts(answer,for:objective),answer)}
            XCTAssertFalse(Recall.accepts(wrong,for:objective))
        }
    }
}
