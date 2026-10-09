import XCTest
@testable import FoxlingoCore
final class PracticeGapTests: XCTestCase {
    func testUnknownSeedNamesSurviveSaveWithoutInventingCanonicalSubjects() throws {
        let gap=PracticeGap(game:"grid",context:"Madrid × Brazil",subjectIDs:[],timestamp:Date(timeIntervalSince1970:100),referenceNames:["Savio","Savio"," "],referenceAssets:["entity-madrid","flag-brazil"],referencePlayerIDs:["current-player-820"])
        let decoded=try JSONDecoder().decode(PracticeGap.self,from:JSONEncoder().encode(gap))
        XCTAssertEqual(decoded.referencePlayerIDs,["current-player-820"]);XCTAssertEqual(decoded.referenceNames,["Savio"]);XCTAssertTrue(decoded.subjectIDs.isEmpty)
        XCTAssertEqual(decoded.referenceAssets,["entity-madrid","flag-brazil"])
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(gap)) as! [String:Any]
        json.removeValue(forKey:"referencePlayerIDs");json.removeValue(forKey:"referenceNames");json.removeValue(forKey:"referenceAssets")
        let old=try JSONDecoder().decode(PracticeGap.self,from:JSONSerialization.data(withJSONObject:json))
        XCTAssertNil(old.referencePlayerIDs);XCTAssertNil(old.referenceNames);XCTAssertNil(old.referenceAssets)
    }
    func fixture() throws -> ContentPack {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
    }
    func testOldProgressLoadsAndPracticeNeverChangesRecallOrStreak() throws {
        var state=LearnerState();var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(state)) as! [String:Any];json.removeValue(forKey:"practiceGaps")
        state=try JSONDecoder().decode(LearnerState.self,from:JSONSerialization.data(withJSONObject:json))
        XCTAssertNil(state.practiceGaps)
        for _ in 0..<501 {state.recordPracticeGap(PracticeGap(game:"memory",context:"pair",subjectIDs:[],timestamp:Date()))}
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        XCTAssertEqual(restored.practiceGaps?.count,500);XCTAssertTrue(restored.reviews.isEmpty);XCTAssertTrue(restored.sessions.isEmpty);XCTAssertTrue(restored.acquiredCards.isEmpty)
    }
    func testExactFactRecommendsItsLessonAndUnknownSeedHasNoInventedLesson() throws {
        let pack=try fixture(),lesson=pack.lessons[0],objective=pack.objective(lesson.objectiveIDs[0]),fact=pack.facts.first {$0.id == objective.factIDs[0]}!
        let gap=PracticeGap(game:"mystery",context:"Missed clue",subjectIDs:[fact.subjectID],factIDs:[fact.id],timestamp:Date())
        let recommendations=PracticeRecommendations.lessons(pack:pack,gaps:[gap])
        XCTAssertEqual(recommendations.first?.lesson.id,lesson.id);XCTAssertEqual(recommendations.first?.exactFact,true)
        XCTAssertTrue(PracticeRecommendations.lessons(pack:pack,gaps:[PracticeGap(game:"grid",context:"Unknown player",subjectIDs:[UUID()],timestamp:Date())]).isEmpty)
    }
}
