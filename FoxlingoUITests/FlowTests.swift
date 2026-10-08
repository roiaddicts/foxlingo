import XCTest
final class FlowTests: XCTestCase {
    let app=XCUIApplication()
    override func setUp() {continueAfterFailure=false}
    func start(reset: Bool = true, now: Double = 1_800_000_000) {
        app.launchArguments=["-ui-testing","-test-now",String(now)] + (reset ? ["-reset-test-state"] : [])
        app.launch()
    }
    func tap(_ id: String) {
        let b=app.buttons[id]
        for _ in 0..<8 {if b.exists && b.isHittable {break};app.swipeUp()}
        if !b.exists {XCTAssertTrue(b.waitForExistence(timeout:5),id)};b.tap()
    }
    func completeLesson(_ key: String) {
        tap(key);tap("lesson-next");tap("lesson-next")
        for _ in 0..<4 {tap("answer-choice-0");tap("answer-next")}
        for i in 0..<3 {tap("match-l-\(i)");tap("match-r-\(i)")}
        tap("finish-lesson")
        XCTAssertTrue(app.staticTexts["lesson-complete"].waitForExistence(timeout:3))
        tap("back-roadmap")
    }
    func testBothClubsLessonResumeAlbumAndReview() {
        start();tap("choose-XT")
        tap("lesson-xolos-identity");tap("lesson-next")
        app.terminate();start(reset:false)
        tap("lesson-xolos-identity")
        XCTAssertTrue(app.staticTexts["The home ground"].exists)
        tap("lesson-next")
        tap("answer-choice-1");XCTAssertTrue(app.staticTexts["answer-feedback"].exists);tap("answer-next")
        for _ in 0..<4 {tap("answer-choice-0");tap("answer-next")}
        tap("match-l-0");tap("match-r-1");XCTAssertTrue(app.staticTexts["answer-feedback"].exists)
        let hidden=NSPredicate(format:"value == %@","Face down")
        expectation(for:hidden,evaluatedWith:app.buttons["match-l-0"]);waitForExpectations(timeout:5)
        for i in 0..<3 {tap("match-l-\(i)");tap("match-r-\(i)")}
        tap("finish-lesson");tap("back-roadmap")
        app.tabBars.buttons["Album"].tap();tap("card-xolos")
        XCTAssertTrue(app.staticTexts["Your knowledge set"].exists)
        app.tabBars.buttons["Practice"].tap();XCTAssertTrue(app.staticTexts["You're all caught up."].exists)
        tap("optional-practice");tap("reveal-recall");tap("recall-next");tap("reveal-recall");tap("recall-next");tap("reveal-recall");tap("recall-next")
        XCTAssertTrue(app.staticTexts["practice-complete"].exists);tap("practice-done")
        app.terminate();start(reset:false,now:1_800_000_000+86401)
        app.tabBars.buttons["Practice"].tap();tap("start-review")
        for _ in 0..<3 {tap("reveal-recall");tap("recall-next")}
        tap("practice-done")
        app.tabBars.buttons["Learn"].tap();tap("switch-club");tap("club-entity-madrid")
        completeLesson("lesson-madrid-identity")
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Madrid roadmap";shot.lifetime = .keepAlways;add(shot)
    }
    func testIndependentRecallAndSourcesAndSettings() {
        start();tap("choose-XT");completeLesson("lesson-xolos-identity")
        app.terminate();start(reset:false,now:1_800_000_000+86401)
        app.tabBars.buttons["Practice"].tap();tap("start-review")
        for answer in ["Tijuana","Xolos","Estadio Caliente"] {
            let input=app.descendants(matching:.any)["recall-answer"].firstMatch
            XCTAssertTrue(input.waitForExistence(timeout:5));input.tap();input.typeText(answer)
            tap("check-recall");XCTAssertTrue(app.staticTexts["You remembered"].exists);tap("recall-next")
        }
        XCTAssertTrue(app.staticTexts["3 of 3 recalled independently."].exists);tap("practice-done")
        app.tabBars.buttons["Learn"].tap();tap("lesson-xolos-identity")
        app.buttons["Sources & context"].tap()
        XCTAssertTrue(app.navigationBars["Sources & context"].exists)
        XCTAssertTrue(app.staticTexts["Verified 2026-10-08"].firstMatch.exists)
        app.terminate();start(reset:false)
        app.buttons["Settings"].tap();XCTAssertTrue(app.staticTexts["Your experience"].exists)
        let sound=app.switches["Sound"];let old=sound.value as? String;sound.coordinate(withNormalizedOffset:CGVector(dx:0.93,dy:0.5)).tap()
        let changed=NSPredicate { _,_ in sound.value as? String != old };expectation(for:changed,evaluatedWith:nil);waitForExpectations(timeout:5)
        app.buttons["Done"].tap()
    }
    func testLargeTextWelcomeAndLesson() {
        app.launchArguments=["-ui-testing","-reset-test-state","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch();tap("choose-XT");tap("lesson-xolos-identity")
        XCTAssertTrue(app.staticTexts["A name to remember"].exists)
        tap("lesson-next");XCTAssertTrue(app.staticTexts["The home ground"].exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Accessibility text size";shot.lifetime = .keepAlways;add(shot)
    }

    func testAllTwelveLessonsAndAlbum() {
        start();tap("choose-XT")
        for key in ["identity","climb","final","riascos","arce","saucedo"] {completeLesson("lesson-xolos-\(key)")}
        app.swipeDown();app.swipeDown();tap("switch-club");tap("club-entity-madrid")
        for key in ["identity","roots","decima","cristiano","ramos","casillas"] {completeLesson("lesson-madrid-\(key)")}
        app.tabBars.buttons["Album"].tap();XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@", "8 of ")).firstMatch.exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Complete album";shot.lifetime = .keepAlways;add(shot)
    }
    func testThreeGamesAndFreeTextIdentitySelection() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap()
        tap("game-grid");tap("game-cell-0")
        let search=app.textFields["game-player-search"]
        XCTAssertTrue(search.waitForExistence(timeout:5));search.tap();search.typeText("Cristiano Ronaldo")
        tap("game-player-player-1");XCTAssertTrue(app.staticTexts["game-answer-error"].exists)
        search.tap()
        search.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:50)+"Casillas")
        tap("game-player-player-53")
        for _ in 0..<8 {tap("game-hint")}
        XCTAssertTrue(app.staticTexts["game-complete"].exists)
        let grid=XCTAttachment(screenshot:app.screenshot());grid.name="Football grid";grid.lifetime = .keepAlways;add(grid)
        app.navigationBars.buttons.element(boundBy:0).tap()
        tap("game-lineup");tap("game-cell-10")
        let keeper=app.textFields["game-player-search"];keeper.tap();keeper.typeText("Casillas");tap("game-player-classic-player-77")
        for _ in 0..<10 {tap("game-hint")}
        XCTAssertTrue(app.staticTexts["game-complete"].exists)
        let lineup=XCTAttachment(screenshot:app.screenshot());lineup.name="Classic lineup";lineup.lifetime = .keepAlways;add(lineup)
        app.navigationBars.buttons.element(boundBy:0).tap()
        tap("game-bingo");tap("bingo-skip")
        for _ in 0..<12 {tap("game-hint")}
        XCTAssertTrue(app.staticTexts["game-complete"].exists)
        let bingo=XCTAttachment(screenshot:app.screenshot());bingo.name="Football bingo";bingo.lifetime = .keepAlways;add(bingo)
    }

    func testExpandedClubLibraryAndStarterLesson() {
        start();tap("choose-XT");tap("switch-club")
        let search=app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout:5));search.tap();search.typeText("Atlas")
        tap("club-entity-atlas");completeLesson("lesson-atlas-starter")
        tap("switch-club");let again=app.searchFields.firstMatch;again.tap();again.typeText("Paderborn")
        tap("club-entity-paderborn-07");completeLesson("lesson-paderborn-07-starter")
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Expanded club roadmap";shot.lifetime = .keepAlways;add(shot)
    }

    func testMemoryCardsConcealMismatchAndResumePairs() {
        start();tap("choose-XT");tap("lesson-xolos-identity");tap("lesson-next");tap("lesson-next")
        for _ in 0..<4 {tap("answer-choice-0");tap("answer-next")}
        XCTAssertEqual(app.buttons["match-l-0"].value as? String,"Face down")
        XCTAssertTrue(app.buttons["match-l-0"].label.hasPrefix("Hidden card"))
        tap("match-r-0");XCTAssertEqual(app.buttons["match-r-0"].value as? String,"Revealed")
        tap("match-l-0");XCTAssertEqual(app.buttons["match-l-0"].value as? String,"Matched")
        let position=app.buttons["match-l-1"].label
        app.terminate();start(reset:false);tap("lesson-xolos-identity")
        XCTAssertEqual(app.buttons["match-l-0"].value as? String,"Matched")
        XCTAssertEqual(app.buttons["match-l-1"].label,position)
        tap("match-l-1");tap("match-l-2")
        XCTAssertEqual(app.buttons["match-l-1"].value as? String,"Revealed")
        XCTAssertFalse(app.buttons["finish-lesson"].exists)
        let hidden=NSPredicate(format:"value == %@","Face down")
        expectation(for:hidden,evaluatedWith:app.buttons["match-l-1"]);waitForExpectations(timeout:5)
        XCTAssertEqual(app.buttons["match-l-2"].value as? String,"Face down")
        for i in 1..<3 {tap("match-r-\(i)");tap("match-l-\(i)")}
        XCTAssertTrue(app.buttons["finish-lesson"].exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Memory pairs";shot.lifetime = .keepAlways;add(shot)
        tap("finish-lesson");XCTAssertTrue(app.staticTexts["lesson-complete"].exists)
    }

    func testDailyPlanResumesAndShowsRealBacklog() {
        start();tap("choose-XT")
        tap("daily-lesson");tap("lesson-next")
        app.terminate();start(reset:false)
        XCTAssertTrue(app.buttons["daily-lesson"].label.hasPrefix("Continue:"))
        tap("daily-lesson");XCTAssertTrue(app.staticTexts["The home ground"].exists)
        tap("lesson-next")
        for _ in 0..<4 {tap("answer-choice-0");tap("answer-next")}
        for i in 0..<3 {tap("match-l-\(i)");tap("match-r-\(i)")}
        tap("finish-lesson");tap("back-roadmap")
        completeLesson("lesson-xolos-climb")
        app.terminate();start(reset:false,now:1_800_000_000+86401)
        tap("session-size");app.buttons["Quick · 5"].tap()
        XCTAssertTrue(app.staticTexts["daily-due-count"].label.contains("5 in this session · 6 ready"))
        tap("daily-review")
        XCTAssertTrue(app.staticTexts["SCHEDULED RECALL · 1 OF 5"].waitForExistence(timeout:5))
        for _ in 0..<5 {tap("reveal-recall");tap("recall-next")}
        tap("practice-done")
        XCTAssertTrue(app.staticTexts["daily-due-count"].label.contains("1 ready"))
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Daily study plan";shot.lifetime = .keepAlways;add(shot)
        app.terminate();start(reset:false,now:1_800_000_000+2*86400+2)
        XCTAssertTrue(app.staticTexts["daily-due-count"].label.contains("5 in this session · 6 ready"))
    }

    func testCoveragePreviewLessonRecallAndIndependentClubSelection() {
        start();tap("choose-XT");app.tabBars.buttons["Practice"].tap();tap("coverage-open")
        XCTAssertTrue(app.staticTexts["coverage-scope"].exists)
        XCTAssertTrue(app.staticTexts["coverage-new-learner"].exists)
        XCTAssertFalse(app.buttons["coverage-recall"].exists)
        tap("coverage-story-lesson-xolos-identity")
        XCTAssertTrue(app.staticTexts["Checked 2026-10-08"].firstMatch.exists)
        tap("coverage-learn-lesson-xolos-identity")
        tap("lesson-next");tap("lesson-next")
        for _ in 0..<4 {tap("answer-choice-0");tap("answer-next")}
        for i in 0..<3 {tap("match-l-\(i)");tap("match-r-\(i)")}
        tap("finish-lesson");tap("back-roadmap")
        for _ in 0..<6 {if app.buttons["coverage-recall"].isHittable {break};app.swipeDown()}
        tap("coverage-recall")
        for _ in 0..<3 {tap("reveal-recall");tap("recall-next")}
        XCTAssertTrue(app.staticTexts["This was rehearsal. Scheduled recall is what improves your cards."].exists)
        tap("practice-done")
        for _ in 0..<6 {if app.buttons["coverage-second"].isHittable {break};app.swipeDown()}
        tap("coverage-second")
        XCTAssertFalse(app.buttons["club-entity-xolos"].isEnabled)
        let search=app.searchFields.firstMatch;search.tap();search.typeText("Atlas");tap("club-entity-atlas")
        XCTAssertTrue(app.buttons["coverage-second"].label.contains("Atlas"))
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Coverage comparison";shot.lifetime = .keepAlways;add(shot)
        app.navigationBars.buttons.element(boundBy:0).tap();app.tabBars.buttons["Learn"].tap()
        XCTAssertTrue(app.staticTexts["Xolos"].exists)
    }
    func testCoverageMixedDueAndRehearsalSummary() {
        start();tap("choose-XT");completeLesson("lesson-xolos-identity")
        app.terminate();start(reset:false,now:1_800_000_000+86401)
        tap("switch-club");tap("club-entity-madrid");completeLesson("lesson-madrid-identity")
        app.tabBars.buttons["Practice"].tap();tap("coverage-open");tap("coverage-recall")
        for _ in 0..<6 {tap("reveal-recall");tap("recall-next")}
        XCTAssertTrue(app.staticTexts["3 scheduled reviews updated. Early answers were rehearsal."].exists)
        tap("practice-done")
    }

    func testCoveragePreviewCannotEarnIndependentRecall() {
        start();tap("choose-XT");completeLesson("lesson-xolos-identity")
        app.terminate();start(reset:false,now:1_800_000_000+86401)
        app.tabBars.buttons["Practice"].tap();tap("coverage-open")
        tap("coverage-story-lesson-xolos-identity")
        for _ in 0..<6 {if app.buttons["coverage-recall"].isHittable {break};app.swipeDown()}
        tap("coverage-recall")
        for answer in ["Xolos","Tijuana","Estadio Caliente"] {
            let input=app.descendants(matching:.any)["recall-answer"].firstMatch
            input.tap();input.typeText(answer);tap("check-recall")
            XCTAssertTrue(app.staticTexts["You previewed this fact in the study pack. This answer counts as rehearsal."].exists)
            XCTAssertFalse(app.staticTexts["You remembered"].exists);tap("recall-next")
        }
        XCTAssertTrue(app.staticTexts["0 of 3 recalled independently."].exists)
        XCTAssertTrue(app.staticTexts["This was rehearsal. Scheduled recall is what improves your cards."].exists)
        tap("practice-done")
        app.navigationBars.buttons.element(boundBy:0).tap();app.tabBars.buttons["Learn"].tap()
        XCTAssertTrue(app.staticTexts["daily-due-count"].label.contains("3 ready"))
    }

}
