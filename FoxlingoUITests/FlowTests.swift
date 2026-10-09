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
        for index in 0..<4 {
            if app.pickerWheels.count == 2 {
                let score = key == "lesson-necaxa-starter" ? ("9","0") : key == "lesson-competition-champions-league-istanbul" ? [("3","0"),("3","3"),("3","2"),("3","0")][index] : ("4","1")
                setScore(score.0,score.1);tap("check-score")
            } else {tap("answer-choice-0")}
            tap("answer-next")
        }
        XCTAssertTrue(app.staticTexts["lesson-complete"].waitForExistence(timeout:3))
        tap("back-roadmap")
    }
    func setScore(_ left: String,_ right: String) {
        let first=app.pickerWheels["score-left"].exists ? app.pickerWheels["score-left"] : app.pickerWheels.element(boundBy:0)
        let second=app.pickerWheels["score-right"].exists ? app.pickerWheels["score-right"] : app.pickerWheels.element(boundBy:1)
        XCTAssertTrue(first.waitForExistence(timeout:3));first.adjust(toPickerWheelValue:left)
        XCTAssertTrue(second.exists);second.adjust(toPickerWheelValue:right)
    }
    func graphSelect(_ control:String,_ name:String,_ key:String) {
        tap(control)
        let search=app.searchFields.firstMatch;search.tap();search.typeText(name)
        tap("graph-select-entity-\(key)")
    }
    func choosePlayer(_ name:String,_ key:String) {
        for _ in 0..<6 {if app.buttons["switch-club"].isHittable {break};app.swipeDown()}
        tap("switch-club")
        if app.segmentedControls["roadmap-subject-type"].exists {app.segmentedControls["roadmap-subject-type"].buttons["Players"].tap()}
        else {tap("roadmap-subject-type");app.buttons["Players"].tap()}
        let search=app.searchFields.firstMatch;search.tap();search.typeText(name);tap("club-entity-\(key)")
    }
    func chooseCompetition(_ name:String,_ key:String) {
        for _ in 0..<6 {if app.buttons["switch-club"].isHittable {break};app.swipeDown()}
        tap("switch-club")
        let search=app.searchFields.firstMatch;search.tap();search.typeText(name)
        tap("club-entity-competition-"+key)
    }
    func testCompetitionFoundationsPersistenceAndAlbum() {
        start();tap("choose-XT");chooseCompetition("Liga MX","liga-mx")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("0 of 3 foundation lessons"))
        let before=XCTAttachment(screenshot:app.screenshot());before.name="Liga MX foundations";before.lifetime = .keepAlways;add(before)
        completeLesson("lesson-competition-liga-mx-origins")
        app.terminate();start(reset:false)
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("1 of 3 foundation lessons"))
        completeLesson("lesson-competition-liga-mx-short-tournaments")
        completeLesson("lesson-competition-liga-mx-first-short-title")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("3 of 3 foundation lessons"))
        app.tabBars.buttons["Album"].tap();tap("album-collection");app.buttons["Competitions"].tap()
        tap("card-competition-liga-mx")
        XCTAssertTrue(app.staticTexts["card-coverage"].label.contains("9 of 9 connections introduced"))
        tap("card-competition-roadmap")
        XCTAssertTrue(app.staticTexts["competition-roadmap-selected"].exists)
        XCTAssertTrue(app.staticTexts["competition-roadmap-progress"].label.contains("3 of 3 foundation"))
        let detail=XCTAttachment(screenshot:app.screenshot());detail.name="Competition album roadmap";detail.lifetime = .keepAlways;add(detail)
    }
    func testPremierLeagueAndArsenalPlayerPaths() {
        start();tap("choose-XT");chooseCompetition("Premier League","premier-league")
        completeLesson("lesson-competition-premier-league-origins")
        completeLesson("lesson-competition-premier-league-invincibles")
        completeLesson("lesson-competition-premier-league-goalscorers")
        app.terminate();start(reset:false)
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("3 of 3 foundation lessons"))
        let course=XCTAttachment(screenshot:app.screenshot());course.name="Premier League completed path";course.lifetime = .keepAlways;add(course)
        choosePlayer("Thierry Henry","thierry-henry")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("0 of 2 starter lessons"))
        Thread.sleep(forTimeInterval:0.5) // Capture the settled sheet dismissal and numeric transition.
        let player=XCTAttachment(screenshot:app.screenshot());player.name="Henry player path";player.lifetime = .keepAlways;add(player)
        completeLesson("lesson-catalog-henry-career")
        completeLesson("lesson-catalog-henry-record")
        app.terminate();start(reset:false)
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("2 of 2 starter lessons"))
        choosePlayer("Dennis Bergkamp","dennis-bergkamp")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("0 of 2 starter lessons"))
    }
    func testCurrentPlayerNamespaceCanBeSelectedAndResumed() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-grid");tap("game-cell-4")
        let search=app.textFields["game-player-search"];search.tap();search.typeText("Neymar")
        XCTAssertTrue(app.buttons["game-player-current-player-5"].isHittable)
        XCTAssertFalse(app.buttons["game-player-player-5"].exists)
        let choices=XCTAttachment(screenshot:app.screenshot());choices.name="Current player search above keyboard";choices.lifetime = .keepAlways;add(choices)
        tap("game-player-current-player-5")
        XCTAssertTrue(app.buttons["game-cell-4"].label.contains("Neymar Jr"))
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-grid")
        XCTAssertTrue(app.buttons["game-cell-4"].label.contains("Neymar Jr"))
    }
    func testSavedRoadmapsSeparateSelectionRemovalAndPersistence() {
        start();tap("choose-XT")
        XCTAssertEqual(app.buttons["active-toggle-roadmap-xolos"].value as? String,"Saved")
        chooseCompetition("Bundesliga","bundesliga")
        XCTAssertEqual(app.buttons["active-toggle-roadmap-competition-bundesliga"].value as? String,"Not saved")
        tap("active-toggle-roadmap-competition-bundesliga")
        XCTAssertEqual(app.buttons["active-toggle-roadmap-competition-bundesliga"].value as? String,"Saved")
        app.terminate();start(reset:false)
        XCTAssertTrue(app.staticTexts["Bundesliga"].exists)
        XCTAssertEqual(app.buttons["active-toggle-roadmap-competition-bundesliga"].value as? String,"Saved")
        tap("active-toggle-roadmap-competition-bundesliga")
        XCTAssertTrue(app.staticTexts["Bundesliga"].exists)
        tap("switch-club")
        XCTAssertTrue(app.buttons["saved-entity-xolos"].exists);XCTAssertTrue(app.buttons["saved-entity-madrid"].exists)
        XCTAssertFalse(app.buttons["saved-entity-competition-bundesliga"].exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="My roadmaps";shot.lifetime = .keepAlways;add(shot)
        tap("saved-toggle-roadmap-xolos");tap("saved-toggle-roadmap-madrid")
        XCTAssertTrue(app.staticTexts["Save a club, player or competition with its bookmark. Removing a roadmap keeps everything you've learned."].exists)
        app.buttons["Done"].tap();app.terminate();start(reset:false);tap("switch-club")
        XCTAssertFalse(app.buttons["saved-entity-xolos"].exists);XCTAssertFalse(app.buttons["saved-entity-madrid"].exists)
    }
    func testSavedRoadmapsLargestText() {
        app.launchArguments=["-ui-testing","-reset-test-state","-test-now","1800000000","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"];app.launch()
        tap("choose-XT");tap("switch-club")
        tap("saved-toggle-roadmap-xolos")
        XCTAssertFalse(app.buttons["saved-entity-xolos"].exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="My roadmaps at largest text";shot.lifetime = .keepAlways;add(shot)
    }
    func testCompetitionChooserAndClubOnlyCoverage() {
        start();tap("choose-XT");tap("switch-club")
        tap("club-entity-competition-champions-league")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("0 of 3 foundation lessons"))
        chooseCompetition("German league","bundesliga")
        let marks=XCTAttachment(screenshot:app.screenshot());marks.name="Bundesliga foundations";marks.lifetime = .keepAlways;add(marks)
        app.tabBars.buttons["Practice"].tap();tap("coverage-open");tap("coverage-first")
        let search=app.searchFields.firstMatch;search.tap();search.typeText("Champions League")
        XCTAssertFalse(app.buttons["club-entity-competition-champions-league"].exists)
    }
    func testLargeTextCompetitionAlbumHeader() {
        app.launchArguments=["-ui-testing","-reset-test-state","-test-now","1800000000","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"];app.launch()
        tap("choose-XT");chooseCompetition("UEFA Champions League","champions-league")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].exists)
        app.tabBars.buttons["Album"].tap();tap("album-collection");app.buttons["Competitions"].tap();tap("card-competition-champions-league");tap("card-competition-roadmap")
        XCTAssertTrue(app.staticTexts["UEFA Champions League"].isHittable)
        let header=XCTAttachment(screenshot:app.screenshot());header.name="Large text competition header";header.lifetime = .keepAlways;add(header)
        for _ in 0..<6 {if app.staticTexts["competition-roadmap-progress"].isHittable {break};app.swipeUp()}
        XCTAssertTrue(app.staticTexts["competition-roadmap-progress"].isHittable)
    }
    func testCoverageRehearsalRevealPreservesDueRecall() {
        start();tap("choose-XT");completeLesson("lesson-xolos-final")
        app.terminate();start(reset:false,now:1_800_000_000+86401)
        app.tabBars.buttons["Practice"].tap();tap("coverage-open");tap("coverage-rehearse");tap("rehearsal-topic-lesson-xolos-final")
        app.segmentedControls["rehearsal-mode"].buttons["Say it aloud"].tap();app.switches["rehearsal-explained"].tap();tap("rehearsal-check")
        app.navigationBars.buttons.element(boundBy:0).tap();app.navigationBars.buttons.element(boundBy:0).tap();tap("coverage-recall")
        for answer in ["Toluca","4-1","December 2, 2012"] {
            if app.pickerWheels.count == 2 {setScore("4","1")} else {let input=app.descendants(matching:.any)["recall-answer"].firstMatch;input.tap();input.typeText(answer)};tap("check-recall")
            XCTAssertTrue(app.staticTexts["You previewed this fact in the study pack. This answer counts as rehearsal."].exists);tap("recall-next")
        }
        XCTAssertTrue(app.staticTexts["0 of 3 recalled independently."].exists);tap("practice-done")
        app.navigationBars.buttons.element(boundBy:0).tap();app.tabBars.buttons["Learn"].tap();XCTAssertTrue(app.staticTexts["daily-due-count"].label.contains("3 ready"))
    }
    func testSavedRehearsalHistoryPreviewsKeepDueRecall() {
        start();tap("choose-XT");completeLesson("lesson-xolos-final")
        app.tabBars.buttons["Practice"].tap();tap("rehearsal-open");tap("rehearsal-topic-lesson-xolos-final")
        app.segmentedControls["rehearsal-mode"].buttons["Say it aloud"].tap();app.switches["rehearsal-explained"].tap();tap("rehearsal-check")
        for index in 0..<3 {tap("rehearsal-reflection-\(index)");app.buttons["I missed this"].tap()}
        tap("rehearsal-finish")
        app.terminate();start(reset:false,now:1_800_000_000+86401)
        app.tabBars.buttons["Practice"].tap();tap("coverage-open");tap("coverage-rehearse");tap("rehearsal-history")
        XCTAssertTrue(app.staticTexts["The aggregate score: Missed"].exists)
        app.navigationBars.buttons.element(boundBy:0).tap();app.navigationBars.buttons.element(boundBy:0).tap();tap("coverage-recall")
        for answer in ["Toluca","4-1","December 2, 2012"] {
            if app.pickerWheels.count == 2 {setScore("4","1")} else {let input=app.descendants(matching:.any)["recall-answer"].firstMatch;input.tap();input.typeText(answer)};tap("check-recall")
            XCTAssertTrue(app.staticTexts["You previewed this fact in the study pack. This answer counts as rehearsal."].exists);tap("recall-next")
        }
        XCTAssertTrue(app.staticTexts["0 of 3 recalled independently."].exists);tap("practice-done")
        app.navigationBars.buttons.element(boundBy:0).tap();app.tabBars.buttons["Learn"].tap();XCTAssertTrue(app.staticTexts["daily-due-count"].label.contains("3 ready"))
    }
    func testWrittenRehearsalRestoresChecksAndSavedReflections() {
        start();tap("choose-XT");app.tabBars.buttons["Practice"].tap();tap("rehearsal-open");tap("rehearsal-topic-lesson-madrid-decima")
        XCTAssertFalse(app.staticTexts["The opponent"].exists)
        let response=app.textViews["rehearsal-response"];response.tap();response.typeText("Ramos sent the final into extra time.");app.buttons["Done"].tap()
        app.terminate();start(reset:false);app.tabBars.buttons["Practice"].tap();tap("rehearsal-open");tap("rehearsal-topic-lesson-madrid-decima")
        XCTAssertTrue(app.textViews["rehearsal-response"].value as? String == "Ramos sent the final into extra time.")
        tap("rehearsal-check");XCTAssertTrue(app.staticTexts["rehearsal-original"].label.contains("Ramos sent"))
        XCTAssertFalse(app.buttons["rehearsal-finish"].isEnabled)
        for (index,label) in ["I included this","I missed this","I'm unsure"].enumerated() {tap("rehearsal-reflection-\(index)");app.buttons[label].tap()}
        tap("rehearsal-finish");XCTAssertTrue(app.staticTexts["rehearsal-complete"].exists)
        app.navigationBars.buttons.element(boundBy:0).tap();tap("rehearsal-history")
        XCTAssertTrue(app.staticTexts["The opponent: Included"].exists);XCTAssertTrue(app.staticTexts["The year: Missed"].exists);XCTAssertTrue(app.staticTexts["The equalizer: Unsure"].exists)
        let saved=XCTAttachment(screenshot:app.screenshot());saved.name="Saved coverage explanation";saved.lifetime = .keepAlways;add(saved)
        app.tabBars.buttons["Learn"].tap();XCTAssertEqual(app.otherElements["streak-badge"].label,"1 active day streak")
        let flame=XCTAttachment(screenshot:app.screenshot());flame.name="Procedural streak flame";flame.lifetime = .keepAlways;add(flame)
    }
    func testAloudRehearsalAtLargestTextNeedsExplicitReflection() {
        app.launchArguments=["-ui-testing","-reset-test-state","-test-now","1800000000","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"];app.launch()
        tap("choose-XT");app.tabBars.buttons["Practice"].tap();tap("rehearsal-open");tap("rehearsal-topic-lesson-madrid-ramos-honours")
        app.segmentedControls["rehearsal-mode"].buttons["Say it aloud"].tap()
        XCTAssertFalse(app.buttons["rehearsal-check"].isEnabled)
        app.switches["rehearsal-explained"].tap();tap("rehearsal-check")
        for index in 0..<3 {tap("rehearsal-reflection-\(index)");app.buttons["I missed this"].tap()}
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Large text rehearsal reflection";shot.lifetime = .keepAlways;add(shot)
        tap("rehearsal-finish");XCTAssertTrue(app.staticTexts["rehearsal-complete"].exists)
    }
    func testFootballWordleRestoresAndHandlesRepeatedLetters() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-wordle")
        for letter in "RAMOS" {tap("wordle-key-\(letter)")};tap("wordle-submit")
        XCTAssertEqual(app.otherElements["wordle-row-0"].value as? String,"absent, absent, present, absent, present")
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-wordle")
        XCTAssertTrue(app.otherElements["wordle-row-0"].label.contains("RAMOS"))
        for letter in "MESSI" {tap("wordle-key-\(letter)")};tap("wordle-submit")
        XCTAssertEqual(app.staticTexts["wordle-identity"].label,"Lionel Messi")
        XCTAssertEqual(app.otherElements["wordle-row-1"].value as? String,"correct, correct, correct, correct, correct")
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Native Football Wordle solved";shot.lifetime = .keepAlways;add(shot)
        tap("wordle-replay");XCTAssertFalse(app.staticTexts["wordle-identity"].exists)
    }
    func tapGroupPlayer(_ id: String) {
        let button=app.buttons["groups-player-"+id]
        for step in 0..<12 {
            let top=app.navigationBars.firstMatch.frame.maxY+8
            let bottom=app.buttons["groups-check"].frame.minY-8
            if button.exists {
                if button.frame.midY < top {app.swipeDown();continue}
                if button.frame.midY > bottom {app.swipeUp();continue}
                if button.isHittable {break}
            }
            if step < 6 {app.swipeDown()} else {app.swipeUp()}
        }
        XCTAssertTrue(button.exists,id);XCTAssertTrue(button.isHittable,id);button.tap()
    }
    func tapDraftSlot(_ slot: Int) {
        let button=app.buttons["draft-slot-\(slot)"]
        for _ in 0..<10 {
            let top=app.navigationBars.firstMatch.frame.maxY+8
            let bottom=app.buttons["draft-search"].frame.minY-8
            if button.exists && button.frame.midY < top {app.swipeDown();continue}
            if button.exists && button.frame.midY > bottom {app.swipeUp();continue}
            if button.isHittable {break}
            app.swipeUp()
        }
        XCTAssertTrue(button.isHittable);button.tap()
    }
    func revealClue(_ id: String) -> XCUIElement {
        app.descendants(matching:.any).matching(identifier:"reveal-clue-"+id).firstMatch
    }
    func askGuessWhoOption(_ topic:String,_ name:String,_ id:Int) {
        tap("guesswho-topic-"+topic);tap("guesswho-choose-option")
        let search=app.textFields["guesswho-option-search"];XCTAssertTrue(search.waitForExistence(timeout:3));search.typeText(name);tap("guesswho-option-\(id)");tap("guesswho-ask")
    }
    func guessWhoClue(_ index:Int) -> XCUIElement {app.descendants(matching:.any).matching(identifier:"guesswho-clue-\(index)").firstMatch}
    func testDailyGuessWhoVisualQuestionsResumeAndFinalChanceWin() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-guesswho")
        askGuessWhoOption("club","Newcastle",4)
        XCTAssertTrue(guessWhoClue(0).label.contains("Yes"))
        app.swipeDown();Thread.sleep(forTimeInterval:0.3)
        let composer=XCTAttachment(screenshot:app.screenshot());composer.name="Guess the Footballer question composer";composer.lifetime = .keepAlways;add(composer)
        askGuessWhoOption("country","England",5)
        XCTAssertTrue(guessWhoClue(1).label.contains("Yes"))
        tap("guesswho-topic-position");tap("guesswho-position-3");tap("guesswho-ask")
        XCTAssertTrue(guessWhoClue(2).label.contains("No"))
        tap("guesswho-topic-age");app.segmentedControls["guesswho-comparison"].buttons["Over"].tap();tap("guesswho-ask")
        XCTAssertTrue(guessWhoClue(3).label.contains("Yes"))
        tap("guesswho-topic-height");app.segmentedControls["guesswho-comparison"].buttons["Over"].tap();tap("guesswho-ask")
        XCTAssertTrue(guessWhoClue(4).label.contains("Yes"))
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-guesswho")
        XCTAssertTrue(app.staticTexts["guesswho-questions"].label.contains("5 questions left"))
        tap("guesswho-guess");let search=app.textFields["game-player-search"];XCTAssertTrue(search.waitForExistence(timeout:3));search.typeText("Messi");tap("game-player-daily-guesswho-1056")
        tap("guesswho-guess");search.typeText("Ronaldo");tap("game-player-daily-guesswho-1622")
        XCTAssertTrue(app.staticTexts["guesswho-guesses"].label.contains("2 / 3"))
        tap("guesswho-guess");search.typeText("Pope");tap("game-player-daily-guesswho-91")
        XCTAssertTrue(app.staticTexts["guesswho-answer"].waitForExistence(timeout:3));XCTAssertEqual(app.staticTexts["guesswho-answer"].label,"Nick Pope")
        for _ in 0..<4 {app.swipeDown()}
        Thread.sleep(forTimeInterval:0.4)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Guess the Footballer portrait and yes-no clues";shot.lifetime = .keepAlways;add(shot)
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-guesswho")
        XCTAssertEqual(app.staticTexts["guesswho-answer"].label,"Nick Pope")
    }
    func tapPyramidSlot(_ slot:Int) {
        let button=app.buttons["pyramid-slot-\(slot)"]
        for _ in 0..<6 {
            if button.exists && button.isHittable && button.frame.midY < app.frame.maxY-100 && button.frame.midY > app.frame.minY+110 {break}
            if button.exists && button.frame.midY < app.frame.minY+110 {app.swipeDown()} else {app.swipeUp()}
        }
        button.tap()
    }
    func testDailyPyramidRankingSwapResumeAndGrade() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-pyramid")
        tapPyramidSlot(2);tapPyramidSlot(0)
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-pyramid")
        XCTAssertTrue(app.buttons["pyramid-slot-2"].label.contains("Nani"))
        XCTAssertTrue(app.buttons["pyramid-slot-0"].label.contains("Pauleta"))
        for slot in [6,8,9,7,4,1,3,5] {tapPyramidSlot(slot)}
        // Exercise the native drag path before restoring the correct ranks by tap.
        for _ in 0..<3 {app.swipeDown()}
        let from=app.buttons["pyramid-slot-1"],to=app.buttons["pyramid-slot-2"]
        from.press(forDuration:0.5,thenDragTo:to)
        XCTAssertTrue(to.label.contains("Figo"))
        tapPyramidSlot(1);tapPyramidSlot(2)
        tap("pyramid-help");tap("pyramid-submit")
        XCTAssertTrue(app.staticTexts["pyramid-complete"].waitForExistence(timeout:3))
        XCTAssertEqual(app.staticTexts["pyramid-complete"].label,"Perfect pyramid!")
        Thread.sleep(forTimeInterval:0.4)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Pyramid ranked portrait board";shot.lifetime = .keepAlways;add(shot)
    }
    func testDailySquadSliceFlagsSearchResumeAndFinalChance() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-squadslice")
        app.segmentedControls["squad-reveal-order"].buttons["Clockwise"].tap()
        XCTAssertEqual(app.staticTexts["squad-season"].label,"2016/17")
        XCTAssertTrue(app.buttons["squad-country-10"].exists)
        XCTAssertFalse(app.buttons["squad-country-1"].exists)
        let chart=app.otherElements.matching(identifier:"squad-chart").firstMatch
        XCTAssertTrue(chart.exists);chart.coordinate(withNormalizedOffset:CGVector(dx:0.85,dy:0.35)).tap()
        XCTAssertTrue(app.descendants(matching:.any).matching(identifier:"squad-selected-country").firstMatch.exists)
        tap("squad-country-10")
        XCTAssertTrue(app.descendants(matching:.any).matching(identifier:"squad-selected-country").firstMatch.exists)
        XCTAssertFalse(app.scrollViews["squad-country-players"].exists)
        tap("squad-guess")
        let search=app.textFields["squad-club-search"];XCTAssertTrue(search.waitForExistence(timeout:3));search.typeText("Arsenal");tap("squad-club-1")
        XCTAssertTrue(app.buttons["squad-country-1"].waitForExistence(timeout:3))
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-squadslice")
        XCTAssertTrue(app.staticTexts["squad-chances"].label.contains("1 / 3"))
        tap("squad-skip");tap("squad-guess");search.typeText("Milan");tap("squad-club-12")
        XCTAssertTrue(app.staticTexts["squad-answer"].waitForExistence(timeout:3))
        XCTAssertEqual(app.staticTexts["squad-answer"].label,"AC Milan")
        tap("squad-country-10")
        XCTAssertTrue(app.scrollViews["squad-country-players"].waitForExistence(timeout:3))
        Thread.sleep(forTimeInterval:0.4)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="SquadSlice nationality ring and portraits";shot.lifetime = .keepAlways;add(shot)
    }
    func testDailyLegacyAndLinkVisualCluesSearchAndResume() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-legacy")
        XCTAssertEqual(revealClue("club-89").label,"Club: PSV")
        XCTAssertEqual(revealClue("club-2").label,"Hidden clue")
        tap("reveal-guess")
        let search=app.textFields["game-player-search"];XCTAssertTrue(search.waitForExistence(timeout:3))
        search.typeText("Messi");tap("game-player-daily-general-2")
        XCTAssertEqual(revealClue("club-2").label,"Club: Man City")
        XCTAssertTrue(app.staticTexts["reveal-attempts"].label.contains("1 / 4"))
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-legacy")
        XCTAssertEqual(revealClue("club-2").label,"Club: Man City")
        tap("reveal-guess");search.typeText("Savi");tap("game-player-daily-general-820")
        XCTAssertTrue(app.staticTexts["reveal-answer"].waitForExistence(timeout:3));XCTAssertEqual(app.staticTexts["reveal-answer"].label,"Savinho")
        Thread.sleep(forTimeInterval:0.4)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Legacy answer and club shirt clues";shot.lifetime = .keepAlways;add(shot)
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-legacy")
        XCTAssertEqual(app.staticTexts["reveal-answer"].label,"Savinho")
        app.navigationBars.buttons.element(boundBy:0).tap();tap("game-link")
        XCTAssertEqual(revealClue("daily-general-910").label,"Teammate: Luis Alberto")
        tap("reveal-skip");XCTAssertEqual(revealClue("daily-general-190").label,"Teammate: Javier Mascherano")
        tap("reveal-guess");search.typeText("Pedro");tap("game-player-daily-general-282")
        XCTAssertEqual(app.staticTexts["reveal-answer"].label,"Pedro Rodriguez")
        Thread.sleep(forTimeInterval:0.4)
        let links=XCTAttachment(screenshot:app.screenshot());links.name="Link teammate portraits";links.lifetime = .keepAlways;add(links)
    }
    func testDailyStatdleHardCluesFinalChanceLossAndNormalWin() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-statdle")
        XCTAssertTrue(app.otherElements["reveal-season"].exists || app.staticTexts["Premier League · 2005/06"].exists)
        app.segmentedControls["statdle-difficulty"].buttons["Hard"].tap()
        XCTAssertFalse(revealClue("club").exists);XCTAssertFalse(revealClue("country").exists)
        for _ in 0..<4 {tap("reveal-skip")}
        XCTAssertTrue(app.staticTexts["reveal-attempts"].label.contains("4 / 5"))
        XCTAssertFalse(app.staticTexts["reveal-answer"].exists)
        Thread.sleep(forTimeInterval:0.3)
        let clues=XCTAttachment(screenshot:app.screenshot());clues.name="Statdle hard historical stats final chance";clues.lifetime = .keepAlways;add(clues)
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-statdle")
        XCTAssertTrue(app.staticTexts["reveal-attempts"].label.contains("4 / 5"))
        tap("reveal-skip");XCTAssertEqual(app.staticTexts["reveal-answer"].label,"Wayne Rooney")
        XCTAssertFalse(app.buttons["reveal-guess"].exists)
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-statdle")
        tap("reveal-guess");let search=app.textFields["game-player-search"]
        XCTAssertTrue(search.waitForExistence(timeout:3));search.typeText("Rooney");tap("game-player-daily-general-63")
        XCTAssertEqual(app.staticTexts["reveal-answer"].label,"Wayne Rooney")
    }
    func testDailyTop10SearchResumeAndCompletion() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-top10")
        XCTAssertEqual(app.staticTexts["top10-title"].label,"Chelsea 2023/24 - Most matches")
        tap("top10-choose")
        let search=app.textFields["game-player-search"];XCTAssertTrue(search.waitForExistence(timeout:3))
        search.typeText("Messi");tap("game-player-daily-general-2")
        XCTAssertTrue(app.staticTexts["game-answer-error"].exists)
        search.tap()
        // Replace through the delete key to keep the keyboard's result area exercised.
        search.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:5)+"Gallagher")
        tap("game-player-daily-general-919")
        XCTAssertTrue(app.staticTexts["Conor Gallagher"].exists)
        let settled=expectation(for:NSPredicate(format:"hittable == true"),evaluatedWith:app.buttons["top10-choose"])
        wait(for:[settled],timeout:5)
        Thread.sleep(forTimeInterval:0.35)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Daily Top 10 ranked flags and portrait";shot.lifetime = .keepAlways;add(shot)
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-top10")
        XCTAssertTrue(app.staticTexts["Conor Gallagher"].exists)
        for _ in 0..<9 {tap("top10-hint")}
        for _ in 0..<5 {if app.staticTexts["top10-complete"].isHittable {break};app.swipeUp()}
        XCTAssertTrue(app.staticTexts["top10-complete"].exists)
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-top10")
        for _ in 0..<5 {if app.staticTexts["top10-complete"].isHittable {break};app.swipeUp()}
        XCTAssertTrue(app.staticTexts["top10-complete"].exists)
        XCTAssertFalse(app.buttons["top10-choose"].exists)
    }
    func testDraftNationsSearchPositionsUndoAndResume() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-draft-nations")
        XCTAssertEqual(app.staticTexts["draft-offered"].label,"England")
        tap("draft-search")
        let search=app.textFields["game-player-search"];search.tap();search.typeText("Mbapp")
        tap("game-player-draft-nations-player-1")
        XCTAssertTrue(app.staticTexts["game-answer-error"].exists)
        search.tap();search.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:5));search.typeText("Kane")
        tap("game-player-draft-nations-player-7")
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Nations XI selected player and pitch";shot.lifetime = .keepAlways;add(shot)
        tapDraftSlot(9)
        XCTAssertEqual(app.staticTexts["draft-offered"].label,"Italy")
        let placedShot=XCTAttachment(screenshot:app.screenshot());placedShot.name="Nations XI placed portrait";placedShot.lifetime = .keepAlways;add(placedShot)
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-draft-nations")
        XCTAssertEqual(app.staticTexts["draft-offered"].label,"Italy")
        XCTAssertTrue(app.buttons["draft-slot-9"].label.contains("Harry Kane"))
        tap("draft-undo");XCTAssertEqual(app.staticTexts["draft-offered"].label,"England")
        for _ in 0..<11 {tap("draft-help")}
        XCTAssertTrue(app.staticTexts["draft-complete"].exists)
        tap("draft-replay");XCTAssertFalse(app.staticTexts["draft-complete"].exists)
    }
    func testDraftClubRetroLegendsAndAmericaCompletion() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap()
        for mode in ["clubs","retro","legends","america"] {
            for _ in 0..<5 {app.swipeDown()}
            tap("game-draft-"+mode)
            XCTAssertTrue(app.staticTexts["draft-offered"].exists,mode)
            let shot=XCTAttachment(screenshot:app.screenshot());shot.name=mode+" XI source artwork";shot.lifetime = .keepAlways;add(shot)
            tap("draft-help");tap("draft-undo")
            for _ in 0..<11 {tap("draft-help")}
            XCTAssertTrue(app.staticTexts["draft-complete"].exists,mode)
            let completeShot=XCTAttachment(screenshot:app.screenshot());completeShot.name=mode+" completed XI portraits";completeShot.lifetime = .keepAlways;add(completeShot)
            app.navigationBars.buttons.element(boundBy:0).tap()
        }
    }
    func testConnectionsWrongGroupSelectionResumeAndCompletion() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-connections")
        let groups=[["player-173","player-187","player-230","player-242"],["current-player-5","current-player-820","player-103","player-145"],["current-player-1165","player-1","player-128","player-210"],["player-129","player-1512","player-251","player-291"]]
        for id in [groups[0][0]]+Array(groups[1].prefix(3)) {tapGroupPlayer(id)}
        tap("groups-check");XCTAssertTrue(app.staticTexts["groups-feedback"].label.contains("don’t form"))
        tap("groups-clear");tapGroupPlayer(groups[0][0])
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-connections")
        XCTAssertEqual(app.buttons["groups-player-"+groups[0][0]].value as? String,"Selected")
        for id in groups[0].dropFirst() {tapGroupPlayer(id)}
        XCTAssertTrue(app.buttons["groups-check"].isEnabled)
        tap("groups-check")
        let solved=XCTAttachment(screenshot:app.screenshot());solved.name="Connections first group check";solved.lifetime = .keepAlways;add(solved)
        XCTAssertTrue(app.otherElements["groups-solved-category-23"].waitForExistence(timeout:3) || app.descendants(matching:.any)["groups-solved-category-23"].firstMatch.exists)
        expectation(for:NSPredicate(format:"exists == false"),evaluatedWith:app.buttons["groups-player-"+groups[0][0]]);waitForExpectations(timeout:3)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Connections grouped portraits";shot.lifetime = .keepAlways;add(shot)
        for group in groups.dropFirst() {for id in group {tapGroupPlayer(id)};tap("groups-check")}
        XCTAssertTrue(app.staticTexts["groups-complete"].exists)
        tap("groups-replay");XCTAssertFalse(app.staticTexts["groups-complete"].exists)
    }
    func testImpostorWrongSelectionResumeAndFourRounds() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-impostor")
        let groups=[["player-173","player-187","player-230","player-242"],["current-player-5","current-player-820","player-103","player-145"],["current-player-1165","player-1","player-128","player-210"],["player-129","player-1512","player-251","player-291"]]
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","groups-player-")).count,8)
        for id in groups[1] {tapGroupPlayer(id)};tap("groups-check")
        XCTAssertTrue(app.staticTexts["groups-feedback"].label.contains("don’t form"))
        tap("groups-clear")
        tapGroupPlayer(groups[0][0]);app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-impostor")
        XCTAssertEqual(app.buttons["groups-player-"+groups[0][0]].value as? String,"Selected")
        for id in groups[0].dropFirst() {tapGroupPlayer(id)};tap("groups-check")
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Impostor flag and player choices";shot.lifetime = .keepAlways;add(shot)
        for group in groups.dropFirst() {for id in group {tapGroupPlayer(id)};tap("groups-check")}
        XCTAssertTrue(app.staticTexts["groups-complete"].exists)
    }
    func testUnsolvedMysteryDoesNotRecommendItsHiddenAnswer() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-mystery")
        tap("mystery-reveal");tap("mystery-player-entity-casillas")
        XCTAssertTrue(app.staticTexts["mystery-feedback"].label.contains("differs"))
        app.navigationBars.buttons.element(boundBy:0).tap()
        XCTAssertFalse(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","game-recommend-")).firstMatch.exists)
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-mystery")
        tap("mystery-player-entity-riascos")
        app.navigationBars.buttons.element(boundBy:0).tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","game-recommend-")).firstMatch.exists)
    }
    func testShaderStreakAtOneAndSixtyFourDays() {
        for count in [1,64] {
            app.launchArguments=["-ui-testing","-reset-test-state","-test-now","1800000000","-test-streak-days",String(count)];app.launch()
            tap("choose-XT")
            XCTAssertEqual(app.otherElements["streak-badge"].label,"\(count) active day streak")
            Thread.sleep(forTimeInterval:0.3)
            let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Metal flame \(count) days";shot.lifetime = .keepAlways;add(shot)
            app.terminate()
        }
    }
    func testTimelineDragPersistsItsNewOrder() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-timeline")
        let rows=app.descendants(matching:.any).matching(NSPredicate(format:"identifier BEGINSWITH %@","timeline-event-"))
        let first=rows.element(boundBy:0),last=rows.element(boundBy:2)
        XCTAssertTrue(first.waitForExistence(timeout:5));let id=first.identifier
        first.press(forDuration:0.5,thenDragTo:last)
        let moved=app.descendants(matching:.any)[id].firstMatch
        XCTAssertTrue(moved.label.hasPrefix("3."))
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-timeline")
        XCTAssertTrue(app.descendants(matching:.any)[id].firstMatch.label.hasPrefix("3."))
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Draggable timeline restored";shot.lifetime = .keepAlways;add(shot)
    }
    func testTimelineWrongOrderResumeRestartAndIndependentCompletion() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-timeline")
        XCTAssertTrue(app.staticTexts["timeline-title"].label.contains("Xolos"))
        XCTAssertFalse(app.staticTexts["timeline-date-beginning"].exists)
        XCTAssertFalse(app.staticTexts["timeline-date-championship"].exists)
        let arrangement=XCTAttachment(screenshot:app.screenshot());arrangement.name="Timeline arrangement";arrangement.lifetime = .keepAlways;add(arrangement)
        tap("timeline-check");XCTAssertTrue(app.staticTexts["timeline-feedback"].exists)
        XCTAssertFalse(app.staticTexts["timeline-date-championship"].exists)
        tap("timeline-up-beginning")
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-timeline")
        XCTAssertTrue(app.staticTexts["timeline-notice"].exists)
        XCTAssertTrue(app.staticTexts["timeline-event-beginning"].label.hasPrefix("2."))
        tap("timeline-restart");app.alerts.buttons["Keep arranging"].tap()
        XCTAssertTrue(app.staticTexts["timeline-event-beginning"].label.hasPrefix("2."))
        tap("timeline-up-beginning");tap("timeline-up-promotion");tap("timeline-check")
        XCTAssertTrue(app.staticTexts["timeline-complete"].waitForExistence(timeout:3))
        XCTAssertEqual(app.staticTexts["timeline-date-beginning"].label,"2007")
        XCTAssertEqual(app.staticTexts["timeline-date-promotion"].label,"2011")
        XCTAssertEqual(app.staticTexts["timeline-date-championship"].label,"December 2, 2012")
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Completed Xolos timeline";shot.lifetime = .keepAlways;add(shot)
        tap("timeline-sources");XCTAssertTrue(app.staticTexts["Historical club record; checked 2026-10-08"].firstMatch.exists);tap("timeline-sources-done")
        tap("timeline-club");app.buttons["Real Madrid"].tap()
        XCTAssertTrue(app.staticTexts["timeline-title"].label.contains("Madrid"))
        tap("timeline-reveal");app.alerts.buttons["Keep arranging"].tap()
        XCTAssertFalse(app.staticTexts["timeline-date-casillas"].exists)
        tap("timeline-reveal");app.alerts.buttons["Reveal timeline"].tap()
        XCTAssertTrue(app.staticTexts["timeline-complete"].label.contains("revealed"))
        tap("timeline-replay");XCTAssertFalse(app.staticTexts["timeline-date-casillas"].exists)
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-timeline")
        XCTAssertTrue(app.staticTexts["timeline-title"].label.contains("Madrid"))
    }
    func testLargeTextTimelineHasReachableMovesAndDatedContext() {
        app.launchArguments=["-ui-testing","-reset-test-state","-test-now","1800000000","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"];app.launch()
        tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-timeline")
        tap("timeline-up-beginning")
        Thread.sleep(forTimeInterval:0.5) // Capture the settled spring, not its intermediate frame.
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Large text timeline arrangement";shot.lifetime = .keepAlways;add(shot)
        tap("timeline-reveal");app.alerts.buttons["Reveal timeline"].tap()
        tap("timeline-sources");XCTAssertTrue(app.staticTexts["2007"].exists)
        let context=XCTAttachment(screenshot:app.screenshot());context.name="Large text timeline sources";context.lifetime = .keepAlways;add(context)
        tap("timeline-sources-done");tap("timeline-replay")
    }
    func testNewPlayerCatalogLessonsAndAlbumEntry() {
        start();tap("choose-XT");choosePlayer("Lionel Messi","messi")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("0 of 2 starter lessons"))
        completeLesson("lesson-global-messi-career")
        completeLesson("lesson-global-messi-records")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("2 of 2 starter lessons"))
        app.tabBars.buttons["Album"].tap();tap("album-collection");app.buttons["All subjects"].tap();tap("card-messi")
        XCTAssertTrue(app.buttons["card-player-roadmap"].exists)
        let image=XCTAttachment(screenshot:app.screenshot());image.name="Messi learned career and official records";image.lifetime = .keepAlways;add(image)
        tap("card-player-roadmap")
        XCTAssertTrue(app.staticTexts["player-roadmap-progress"].label.contains("2 of 2 starter lessons"))
    }
    func testPlayerRoadmapSharedProgressOptionalContextAndPersistence() {
        start();tap("choose-XT");choosePlayer("Sergio Ramos","ramos")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("0 of 2 starter lessons"))
        XCTAssertTrue(app.staticTexts["daily-lesson-subject"].label.contains("Sergio Ramos · Your roadmap"))
        completeLesson("lesson-madrid-ramos")
        completeLesson("lesson-madrid-ramos-honours")
        XCTAssertTrue(app.staticTexts["daily-lesson-subject"].label.contains("My roadmaps"))
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("2 of 2 starter lessons"))
        XCTAssertTrue(app.staticTexts["roadmap-optional-progress"].label.contains("0 of 1 optional"))
        app.terminate();start(reset:false)
        XCTAssertTrue(app.staticTexts["Sergio Ramos"].exists)
        tap("switch-club");let search=app.searchFields.firstMatch;search.tap();search.typeText("Real Madrid");tap("club-entity-madrid")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("2 of 10 lessons"))
        choosePlayer("Sergio Ramos","ramos")
        completeLesson("lesson-madrid-decima")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("2 of 2 starter lessons"))
        XCTAssertTrue(app.staticTexts["roadmap-optional-progress"].label.contains("1 of 1 optional"))
        app.terminate();start(reset:false,now:1_800_000_000+86401)
        XCTAssertTrue(app.staticTexts["daily-due-count"].label.contains("8 ready"))
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Player starter progress";shot.lifetime = .keepAlways;add(shot)
    }
    func testPlayerRoadmapAlbumEntryAndExplicitSelection() {
        start();tap("choose-XT");app.tabBars.buttons["Album"].tap();tap("card-cristiano");tap("card-player-roadmap")
        XCTAssertTrue(app.staticTexts["player-roadmap-progress"].label.contains("0 of 2 starter lessons"))
        XCTAssertTrue(app.staticTexts["Optional club context".uppercased()].exists)
        tap("player-roadmap-select");XCTAssertTrue(app.staticTexts["player-roadmap-selected"].exists)
        app.tabBars.buttons["Learn"].tap();XCTAssertTrue(app.staticTexts["Cristiano Ronaldo"].exists)
    }
    func testCristianoCareerLessonSharedProgressAndAlbum() {
        start();tap("choose-XT");choosePlayer("Cristiano Ronaldo","cristiano")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("0 of 2 starter lessons"))
        completeLesson("lesson-madrid-cristiano")
        tap("lesson-player-cristiano-madrid-records");tap("lesson-next");tap("lesson-next")
        XCTAssertTrue(app.staticTexts["According to Real Madrid’s official profile, how many official goals did Cristiano Ronaldo score for the club?"].exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Cristiano scoped Madrid record";shot.lifetime = .keepAlways;add(shot)
        for _ in 0..<4 {tap("answer-choice-0");tap("answer-next")}
        tap("back-roadmap")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("2 of 2 starter lessons"))
        app.terminate();start(reset:false)
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("2 of 2 starter lessons"))
        app.tabBars.buttons["Album"].tap();tap("card-cristiano")
        XCTAssertTrue(app.staticTexts["card-coverage"].label.contains("6 of 6 connections introduced"))
        XCTAssertTrue(app.staticTexts["card-coverage"].label.contains("Active set version 2"))
    }
    func testRiascosCareerClubBadgesAndPersistence() {
        start();tap("choose-XT");choosePlayer("Duvier Riascos","riascos")
        tap("lesson-player-riascos-tijuana-and-beyond");tap("lesson-next");tap("lesson-next")
        let debut=XCTAttachment(screenshot:app.screenshot());debut.name="Riascos debut club badges";debut.lifetime = .keepAlways;add(debut)
        tap("answer-choice-0");tap("answer-next")
        let china=XCTAttachment(screenshot:app.screenshot());china.name="Riascos Chinese scoring club badges";china.lifetime = .keepAlways;add(china)
        for _ in 0..<3 {tap("answer-choice-0");tap("answer-next")}
        tap("back-roadmap")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("1 of 2 starter lessons"))
        app.terminate();start(reset:false)
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("1 of 2 starter lessons"))
        tap("switch-club");let search=app.searchFields.firstMatch;search.tap();search.typeText("Xolos");tap("club-entity-xolos")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("1 of 10 lessons"))
    }

    func testIstanbulScoreWheelsKeepMatchAndShootoutSeparate() {
        start();tap("choose-XT");chooseCompetition("Champions League","champions-league")
        tap("lesson-competition-champions-league-istanbul");tap("lesson-next");tap("lesson-next")
        for (index,score) in [("3","0"),("3","3"),("3","2"),("3","0")].enumerated() {
            XCTAssertEqual(app.pickerWheels.count,2)
            XCTAssertTrue(app.staticTexts[index == 2 ? "Liverpool" : "AC Milan"].exists)
            setScore(score.0,score.1)
            let shot=XCTAttachment(screenshot:app.screenshot());shot.name=index == 2 ? "Liverpool penalty shootout orientation" : "Istanbul match score wheels";shot.lifetime = .keepAlways;add(shot)
            tap("check-score");XCTAssertTrue(app.staticTexts["Good connection"].exists);tap("answer-next")
        }
        XCTAssertTrue(app.staticTexts["lesson-complete"].exists)
    }
    func testScoreWheelsAndImageChoiceGrid() {
        start();tap("choose-XT");tap("lesson-xolos-final");tap("lesson-next");tap("lesson-next")
        XCTAssertTrue(app.otherElements["image-choice-grid"].exists || app.buttons["answer-choice-0"].exists)
        let buttons=(0..<4).map {app.buttons["answer-choice-\($0)"]}
        let rows=Set(buttons.map {Int($0.frame.midY.rounded())})
        XCTAssertEqual(rows.count,2)
        let grid=XCTAttachment(screenshot:app.screenshot());grid.name="Club answers in two by two grid";grid.lifetime = .keepAlways;add(grid)
        tap("answer-choice-0");tap("answer-next")
        XCTAssertEqual(app.pickerWheels.count,2)
        setScore("1","4");tap("check-score")
        XCTAssertTrue(app.staticTexts["Let's build that memory"].exists);tap("answer-next")
        setScore("4","1")
        let prompt=app.staticTexts["What was the aggregate score in Xolos’s favor in the 2012 final?"]
        XCTAssertGreaterThanOrEqual(prompt.frame.minX,0);XCTAssertLessThanOrEqual(prompt.frame.maxX,app.frame.maxX)
        let wheels=XCTAttachment(screenshot:app.screenshot());wheels.name="Xolos aggregate score wheels";wheels.lifetime = .keepAlways;add(wheels)
        tap("check-score");XCTAssertTrue(app.staticTexts["Good connection"].exists);tap("answer-next")
        for _ in 0..<2 {tap("answer-choice-0");tap("answer-next")};tap("back-roadmap")
        app.terminate();start(reset:false,now:1_800_086_401)
        app.tabBars.buttons["Practice"].tap();tap("start-review")
        XCTAssertEqual(app.pickerWheels.count,2)
        setScore("4","1");tap("check-recall")
        XCTAssertTrue(app.staticTexts["You remembered"].exists)
        let recall=XCTAttachment(screenshot:app.screenshot());recall.name="Score wheel scheduled recall";recall.lifetime = .keepAlways;add(recall)
    }
    func testSaucedoCareerAndVisualRecall() {
        start()
        tap("choose-XT");choosePlayer("Cirilo Saucedo","saucedo")
        tap("lesson-player-saucedo-career-milestones");tap("lesson-next");tap("lesson-next")
        for _ in 0..<2 {tap("answer-choice-0");tap("answer-next")}
        XCTAssertTrue(app.staticTexts["lesson-subject"].isHittable)
        let badges=XCTAttachment(screenshot:app.screenshot());badges.name="Saucedo previous club badges";badges.lifetime = .keepAlways;add(badges)
        for _ in 0..<2 {tap("answer-choice-0");tap("answer-next")};tap("back-roadmap")
        app.terminate()
        start(reset:false,now:1_800_086_401)
        app.tabBars.buttons["Practice"].tap();tap("start-review")
        XCTAssertEqual(app.staticTexts["recall-subject"].label,"Cirilo Saucedo")
        for _ in 0..<3 {
            XCTAssertTrue(app.staticTexts["recall-subject"].isHittable)
            let recall=XCTAttachment(screenshot:app.screenshot());recall.name="Saucedo recall context";recall.lifetime = .keepAlways;add(recall)
            tap("reveal-recall");XCTAssertTrue(app.staticTexts["recall-feedback-heading"].isHittable);tap("recall-next")
        }
        XCTAssertTrue(app.staticTexts["practice-complete"].isHittable)
        XCTAssertTrue(app.staticTexts["0 of 3 recalled independently."].exists)
        tap("practice-done")
    }
    func testRecallConcealsClubIdentityUntilSubmission() {
        start();tap("choose-RM");completeLesson("lesson-madrid-identity")
        app.terminate();start(reset:false,now:1_800_086_401)
        app.tabBars.buttons["Practice"].tap();tap("start-review")
        // Due reviews are ordered by objective key: city, founded year, then identity.
        for _ in 0..<2 {tap("reveal-recall");tap("recall-next")}
        XCTAssertTrue(app.staticTexts["Which club is this roadmap about?"].exists)
        XCTAssertFalse(app.staticTexts["recall-subject"].exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Identity recall without answer artwork";shot.lifetime = .keepAlways;add(shot)
        tap("reveal-recall");XCTAssertEqual(app.staticTexts["recall-subject"].label,"Real Madrid");XCTAssertTrue(app.staticTexts["recall-feedback-heading"].isHittable)
        let feedback=XCTAttachment(screenshot:app.screenshot());feedback.name="Identity recall revealed feedback";feedback.lifetime = .keepAlways;add(feedback)
        tap("recall-next");XCTAssertTrue(app.staticTexts["practice-complete"].isHittable)
    }
    func testArceCareerBadgesAtLargestText() {
        app.launchArguments=["-ui-testing","-reset-test-state","-test-now","1800000000","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"];app.launch()
        tap("choose-XT");choosePlayer("Fernando Arce","arce")
        tap("lesson-player-arce-career-milestones");tap("lesson-next");tap("lesson-next")
        tap("answer-choice-0");tap("answer-next")
        XCTAssertTrue(app.staticTexts["lesson-subject"].isHittable)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Arce career badges at largest text";shot.lifetime = .keepAlways;add(shot)
        for _ in 0..<3 {tap("answer-choice-0");tap("answer-next")}
        tap("back-roadmap")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("1 of 2 starter lessons"))
    }
    func testLargeTextPlayerRoadmap() {
        app.launchArguments=["-ui-testing","-reset-test-state","-test-now","1800000000","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"];app.launch()
        tap("choose-XT");choosePlayer("Cirilo Saucedo","saucedo")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("0 of 2 starter lessons"))
        for _ in 0..<6 {if app.buttons["switch-club"].isHittable {break};app.swipeDown()}
        let header=XCTAttachment(screenshot:app.screenshot());header.name="Large text player roadmap";header.lifetime = .keepAlways;add(header)
        tap("lesson-xolos-saucedo");XCTAssertTrue(app.buttons["lesson-next"].exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Large text player lesson";shot.lifetime = .keepAlways;add(shot)
    }
    func testConnectionExplorerPathsFiltersAndEvidence() {
        start();tap("choose-XT");app.tabBars.buttons["Album"].tap();tap("graph-open")
        XCTAssertTrue(app.staticTexts["graph-neighbor-count"].label.contains("Football links"))
        XCTAssertTrue(app.buttons["graph-node-entity-cristiano"].isHittable)
        XCTAssertTrue(app.buttons["graph-node-entity-casillas"].isHittable)
        XCTAssertTrue(app.buttons["graph-node-entity-ramos"].isHittable)
        let map=XCTAttachment(screenshot:app.screenshot());map.name="Connections map";map.lifetime = .keepAlways;add(map)
        tap("graph-path-step-0")
        XCTAssertTrue(app.staticTexts["graph-edge-claim"].label.contains("101 goals"))
        XCTAssertTrue(app.staticTexts["Checked 2026-10-08"].exists)
        tap("graph-edge-done")
        graphSelect("graph-path-from","Sergio Ramos","ramos")
        graphSelect("graph-path-to","Cristiano Ronaldo","cristiano")
        for _ in 0..<6 {if app.buttons["graph-filter"].isHittable {break};app.swipeDown()}
        tap("graph-filter");app.buttons["Matches & moments"].tap()
        for _ in 0..<8 {if app.staticTexts["graph-path-result"].isHittable {break};app.swipeUp()}
        XCTAssertEqual(app.staticTexts["graph-path-result"].label,"3 links · shortest supported path")
        let path=XCTAttachment(screenshot:app.screenshot());path.name="Sourced event path";path.lifetime = .keepAlways;add(path)
        tap("graph-path-step-0")
        XCTAssertTrue(app.staticTexts["graph-edge-claim"].label.contains("equalizer"));tap("graph-edge-done")
        graphSelect("graph-path-from","Xolos","xolos")
        XCTAssertTrue(app.staticTexts["graph-path-result"].label.contains("No supported path in this library"))
        graphSelect("graph-path-to","Xolos","xolos")
        XCTAssertEqual(app.staticTexts["graph-path-result"].label,"Same subject · 0 links")
    }
    func testLargeTextExplorerAndCardEntry() {
        app.launchArguments=["-ui-testing","-reset-test-state","-test-now","1800000000","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"];app.launch()
        tap("choose-XT");app.tabBars.buttons["Album"].tap();tap("card-xolos");tap("card-graph-open")
        XCTAssertTrue(app.otherElements["graph-focus"].exists || app.staticTexts["graph-focus"].exists)
        tap("graph-find");let search=app.searchFields.firstMatch;search.tap();search.typeText("Arsenal");tap("graph-select-entity-arsenal")
        XCTAssertTrue(app.staticTexts["graph-neighbor-count"].label.contains("0 supported links"))
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Large text explorer";shot.lifetime = .keepAlways;add(shot)
    }
    func testCardExplorerPreviewKeepsRecallDue() {
        start();tap("choose-XT");completeLesson("lesson-xolos-identity")
        app.terminate();start(reset:false,now:1_800_000_000+86401)
        app.tabBars.buttons["Album"].tap();tap("card-xolos");tap("card-graph-open")
        XCTAssertTrue(app.buttons["graph-find"].exists)
        app.navigationBars.buttons.element(boundBy:0).tap();tap("card-practice")
        for answer in ["Xolos","Tijuana","Estadio Caliente"] {
            let field=app.descendants(matching:.any)["recall-answer"].firstMatch;field.tap();field.typeText(answer);tap("check-recall")
            XCTAssertTrue(app.staticTexts["You previewed this fact in the card context or explorer. This answer counts as rehearsal."].exists)
            tap("recall-next")
        }
        XCTAssertTrue(app.staticTexts["0 of 3 recalled independently."].exists);tap("practice-done")
        app.tabBars.buttons["Learn"].tap();XCTAssertTrue(app.staticTexts["daily-due-count"].label.contains("3 ready"))
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
        tap("back-roadmap")
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
    func testClassicBoardsResumeAcrossRelaunchAndRestartCancel() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap()
        for game in ["grid","lineup","bingo"] {
            tap("game-"+game);tap("game-hint")
            if game == "bingo" {tap("bingo-skip")}
            app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-"+game)
            XCTAssertTrue(app.staticTexts["game-resume-notice"].exists)
            let progress="1 / " + (game == "grid" ? "9" : game == "lineup" ? "11" : "12")
            XCTAssertTrue(app.staticTexts[progress].exists)
            tap("game-restart");app.buttons["Keep playing"].tap()
            XCTAssertTrue(app.staticTexts[progress].exists)
            let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Saved "+game;shot.lifetime = .keepAlways;add(shot)
            app.navigationBars.buttons.element(boundBy:0).tap()
        }
        tap("game-grid");tap("game-restart");app.buttons["Start a new board"].tap()
        XCTAssertTrue(app.staticTexts["0 / 9"].exists)
        app.navigationBars.buttons.element(boundBy:0).tap();tap("game-lineup")
        XCTAssertTrue(app.staticTexts["1 / 11"].exists)
    }

    func testMysteryRevealsAndSolvedFinalPlayerResume() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-mystery");tap("mystery-reveal")
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-mystery")
        XCTAssertTrue(app.staticTexts["mystery-resume-notice"].exists)
        XCTAssertTrue(app.descendants(matching:.any)["mystery-clue-1"].firstMatch.exists)
        tap("mystery-restart");app.buttons["Keep playing"].tap()
        XCTAssertTrue(app.descendants(matching:.any)["mystery-clue-1"].firstMatch.exists)
        for key in ["riascos","arce","saucedo","cristiano","ramos","casillas"] {
            tap("mystery-player-entity-"+key)
            if key != "casillas" {tap("mystery-next")}
        }
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-mystery")
        XCTAssertEqual(app.staticTexts["mystery-identity"].label,"Iker Casillas")
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Saved solved final mystery";shot.lifetime = .keepAlways;add(shot)
        tap("mystery-next");XCTAssertTrue(app.staticTexts["mystery-complete"].exists)
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-mystery")
        XCTAssertFalse(app.staticTexts["mystery-resume-notice"].exists)
        XCTAssertFalse(app.staticTexts["mystery-identity"].exists)
    }

    func testMysteryCluesNeutralGuessSourcesCompletionAndReplay() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-mystery")
        XCTAssertFalse(app.staticTexts["mystery-identity"].exists)
        XCTAssertTrue(app.buttons["mystery-player-entity-riascos"].exists)
        tap("mystery-player-entity-cristiano")
        XCTAssertTrue(app.staticTexts["mystery-feedback"].label.contains("cannot rule"))
        XCTAssertTrue(app.descendants(matching:.any)["mystery-clue-1"].firstMatch.exists)
        XCTAssertFalse(app.staticTexts["mystery-identity"].exists)
        tap("mystery-player-entity-riascos")
        XCTAssertEqual(app.staticTexts["mystery-identity"].label,"Duvier Riascos")
        tap("mystery-sources");XCTAssertTrue(app.navigationBars["Sources & context"].exists);app.buttons["Done"].tap()
        tap("mystery-next");XCTAssertTrue(app.buttons["mystery-player-entity-riascos"].exists)
        for key in ["arce","saucedo","cristiano","ramos","casillas"] {
            if key == "saucedo" {
                tap("mystery-player-entity-ramos")
                XCTAssertTrue(app.staticTexts["mystery-feedback"].label.contains("differs"))
                tap("mystery-reveal")
                XCTAssertEqual(app.descendants(matching:.any)["mystery-context-1"].firstMatch.label,"Club Tijuana")
                tap("mystery-reveal")
                XCTAssertTrue(app.descendants(matching:.any)["mystery-clue-2"].firstMatch.exists)
            }
            tap("mystery-player-entity-"+key);tap("mystery-next")
        }
        XCTAssertTrue(app.staticTexts["mystery-complete"].exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Mystery board complete";shot.lifetime = .keepAlways;add(shot)
        tap("mystery-replay");XCTAssertFalse(app.staticTexts["mystery-complete"].exists);XCTAssertFalse(app.staticTexts["mystery-identity"].exists)
        XCTAssertFalse(app.descendants(matching:.any)["mystery-clue-1"].firstMatch.exists)
        let restart=XCTAttachment(screenshot:app.screenshot());restart.name="Mystery hidden player";restart.lifetime = .keepAlways;add(restart)
        app.navigationBars.buttons.element(boundBy:0).tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","game-recommend-")).firstMatch.exists)
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap()
        let recommendation=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","game-recommend-")).firstMatch
        XCTAssertTrue(recommendation.waitForExistence(timeout:5));recommendation.tap()
        XCTAssertTrue(app.buttons["lesson-next"].waitForExistence(timeout:5))

    }

    func testLargeTextMysteryCluesAndPlayerPicker() {
        app.launchArguments=["-ui-testing","-reset-test-state","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-mystery")
        tap("mystery-reveal")
        let clue=XCTAttachment(screenshot:app.screenshot());clue.name="Mystery clues at large text";clue.lifetime = .keepAlways;add(clue)
        tap("mystery-player-entity-riascos")
        XCTAssertTrue(app.staticTexts["mystery-identity"].exists)
        tap("mystery-next");XCTAssertFalse(app.staticTexts["mystery-identity"].exists)
    }

    func testExpandedClassicSquadUsesSelectedClub() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-lineup")
        tap("lineup-squad")
        let ajax=app.buttons["Ajax 18/19"]
        XCTAssertTrue(ajax.waitForExistence(timeout:5));ajax.tap()
        XCTAssertTrue(app.staticTexts["Ajax"].exists)
        XCTAssertFalse(app.staticTexts["Real Madrid"].exists)
        tap("game-cell-0")
        let context=app.descendants(matching:.any)["game-lineup-context"].firstMatch
        XCTAssertTrue(context.waitForExistence(timeout:5))
        XCTAssertTrue(context.label.contains("Ajax"))
        XCTAssertFalse(context.label.contains("Real Madrid"))
        app.buttons["Cancel"].tap()
        for _ in 0..<11 {tap("game-hint")}
        XCTAssertTrue(app.staticTexts["game-complete"].exists)
        let image=XCTAttachment(screenshot:app.screenshot());image.name="Ajax historical squad";image.lifetime = .keepAlways;add(image)
    }
    func testThreeGamesAndFreeTextIdentitySelection() {
        start();tap("choose-XT");app.tabBars.buttons["Games"].tap()
        tap("game-grid");tap("game-cell-0")
        let search=app.textFields["game-player-search"]
        XCTAssertTrue(search.waitForExistence(timeout:5));search.tap();search.typeText("Cristiano Ronaldo")
        let result=app.buttons["game-player-player-1"]
        XCTAssertTrue(result.waitForExistence(timeout:5));XCTAssertTrue(result.isHittable)
        XCTAssertLessThan(result.frame.maxY,search.frame.minY)
        let keyboardShot=XCTAttachment(screenshot:app.screenshot());keyboardShot.name="Player results above keyboard search";keyboardShot.lifetime = .keepAlways;add(keyboardShot)
        tap("game-player-player-1");XCTAssertTrue(app.staticTexts["game-answer-error"].exists)
        search.tap()
        search.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:50)+"Casillas")
        tap("game-player-player-53")
        for _ in 0..<8 {tap("game-hint")}
        XCTAssertTrue(app.staticTexts["game-complete"].exists)
        let grid=XCTAttachment(screenshot:app.screenshot());grid.name="Football grid";grid.lifetime = .keepAlways;add(grid)
        app.navigationBars.buttons.element(boundBy:0).tap()
        tap("game-lineup")
        let first=app.buttons["game-cell-0"],defender=app.buttons["game-cell-6"]
        XCTAssertEqual(first.frame.width,defender.frame.width,accuracy:1)
        XCTAssertEqual(first.frame.height,defender.frame.height,accuracy:1)
        tap("game-cell-10")
        XCTAssertTrue(app.descendants(matching:.any)["game-lineup-context"].firstMatch.exists)
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

    func testLessonUpdateActivatesNextLaunchAndRestartsChangedResume() throws {
        start();tap("choose-XT");completeLesson("lesson-xolos-identity")
        tap("lesson-xolos-identity");tap("lesson-next");tap("lesson-next")
        for _ in 0..<3 {tap("answer-choice-0");tap("answer-next")}
        XCTAssertTrue(app.buttons["answer-choice-0"].exists)
        app.terminate()
        app.launchArguments=["-ui-testing","-test-now","1800000000","-stage-test-lessons"];app.launch()
        app.tabBars.buttons["Album"].tap();app.buttons["Settings"].tap();tap("lesson-updates")
        XCTAssertTrue(app.descendants(matching:.any)["lesson-installed-version"].firstMatch.exists)
        let baseline=try XCTUnwrap(app.descendants(matching:.any)["lesson-installed-version"].firstMatch.value as? String)
        let baseVersion=try XCTUnwrap(Int(baseline.split(separator:" ").last ?? ""))
        XCTAssertGreaterThan(baseVersion,0)
        XCTAssertTrue(app.descendants(matching:.any)["lesson-update-staged"].firstMatch.exists)
        let staged=XCTAttachment(screenshot:app.screenshot());staged.name="Lesson update waiting";staged.lifetime = .keepAlways;add(staged)
        app.terminate();start(reset:false)
        tap("lesson-xolos-identity")
        XCTAssertTrue(app.staticTexts["Updated story fixture"].exists)
        XCTAssertFalse(app.buttons["match-l-0"].exists)
        app.navigationBars.buttons["Close lesson"].tap()
        app.tabBars.buttons["Album"].tap();app.buttons["Settings"].tap();tap("lesson-updates")
        XCTAssertEqual(app.descendants(matching:.any)["lesson-installed-version"].firstMatch.value as? String,"Version \(baseVersion+1)")
        tap("lesson-rollback")
        app.buttons["Restore on next launch"].tap()
        app.swipeDown();app.swipeDown()
        XCTAssertTrue(app.descendants(matching:.any)["lesson-update-staged"].firstMatch.exists)
        app.terminate();start(reset:false)
        app.tabBars.buttons["Album"].tap();app.buttons["Settings"].tap();tap("lesson-updates")
        XCTAssertEqual(app.descendants(matching:.any)["lesson-installed-version"].firstMatch.value as? String,baseline)
        XCTAssertTrue(app.staticTexts["lesson-update-message"].label.lowercased().contains("earned cards"))
        let restored=XCTAttachment(screenshot:app.screenshot());restored.name="Lesson rollback installed";restored.lifetime = .keepAlways;add(restored)
    }

    func testUpdatedLibraryOnboardsWithoutFavoriteRoadmaps() {
        app.launchArguments=["-ui-testing","-reset-test-state","-stage-test-lessons","-test-library-without-favorites"];app.launch()
        app.terminate();start(reset:false)
        XCTAssertFalse(app.buttons["choose-XT"].exists);XCTAssertFalse(app.buttons["choose-RM"].exists)
        let choice=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","choose-")).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout:5));choice.tap()
        XCTAssertTrue(app.tabBars.buttons["Learn"].exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","lesson-")).firstMatch.exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Updated library club fallback";shot.lifetime = .keepAlways;add(shot)
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

    func testStandaloneMemoryConcealsFlipsRestoresAndCompletes() {
        start();tap("choose-XT");completeLesson("lesson-xolos-identity")
        XCTAssertFalse(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","match-")).firstMatch.exists)
        app.tabBars.buttons["Games"].tap();tap("game-memory")
        let image="memory-memory-riascos-image",answer="memory-memory-riascos-answer"
        XCTAssertEqual(app.buttons[image].value as? String,"Face down")
        XCTAssertTrue(app.buttons[image].label.hasPrefix("Hidden card"))
        tap(image);tap("memory-memory-arce-answer")
        XCTAssertEqual(app.buttons[image].value as? String,"Revealed")
        tap("memory-memory-cristiano-image")
        XCTAssertEqual(app.buttons["memory-memory-cristiano-image"].value as? String,"Revealed")
        let hidden=NSPredicate(format:"value == %@","Face down")
        expectation(for:hidden,evaluatedWith:app.buttons[image]);waitForExpectations(timeout:5)
        tap("memory-memory-cristiano-answer")
        tap(image);tap(answer);XCTAssertEqual(app.buttons[image].value as? String,"Matched")
        app.terminate();start(reset:false);app.tabBars.buttons["Games"].tap();tap("game-memory")
        XCTAssertEqual(app.buttons[image].value as? String,"Matched")
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Memory 4 by 4 saved board";shot.lifetime = .keepAlways;add(shot)
        tap("memory-restart");app.buttons["Keep playing"].tap()
        for key in ["arce","cristiano","madrid","saucedo","ramos","casillas","xolos"] {tap("memory-memory-"+key+"-image");tap("memory-memory-"+key+"-answer")}
        XCTAssertTrue(app.staticTexts["memory-complete"].exists)
        Thread.sleep(forTimeInterval:0.5)
        let done=XCTAttachment(screenshot:app.screenshot());done.name="Memory names and stats complete";done.lifetime = .keepAlways;add(done)
        tap("memory-replay");XCTAssertEqual(app.buttons[image].value as? String,"Face down")
    }

    func testBundledSoundPreviewsMuteAndPersist() {
        start();tap("choose-XT");app.buttons["Settings"].tap();tap("sound-assets")
        for (asset,title) in [("level-up","Level up"),("wrong","Wrong answer"),("game-over","Game over"),("ui-interface","Interface"),("success","Success"),("small-win","Small win"),("sad-trumpet","Sad trumpet"),("small-defeat","Small setback")] {
            tap("sound-preview-"+asset)
            XCTAssertEqual(app.staticTexts["sound-preview-status"].label,"Previewed "+title+".")
        }
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Bundled sound library";shot.lifetime = .keepAlways;add(shot)
        for _ in 0..<6 {if app.switches["sound-assets-toggle"].exists && app.switches["sound-assets-toggle"].isHittable {break};app.swipeDown()}
        app.switches["sound-assets-toggle"].coordinate(withNormalizedOffset:CGVector(dx:0.93,dy:0.5)).tap()
        XCTAssertFalse(app.buttons["sound-preview-success"].isEnabled)
        XCTAssertFalse(app.staticTexts["sound-preview-status"].exists)
        app.terminate();start(reset:false);app.buttons["Settings"].tap();tap("sound-assets")
        XCTAssertEqual(app.switches["sound-assets-toggle"].value as? String,"0")
        XCTAssertFalse(app.buttons["sound-preview-success"].isEnabled)
    }

    func testLargeTextStandaloneMemoryBoard() {
        app.launchArguments=["-ui-testing","-reset-test-state","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"];app.launch()
        tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-memory")
        tap("memory-memory-ramos-image");tap("memory-memory-ramos-answer")
        XCTAssertEqual(app.buttons["memory-memory-ramos-answer"].value as? String,"Matched")
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Memory at accessibility text size";shot.lifetime = .keepAlways;add(shot)
    }

    func testDailyPlanResumesAndShowsRealBacklog() {
        start();tap("choose-XT")
        tap("daily-lesson");tap("lesson-next")
        app.terminate();start(reset:false)
        XCTAssertTrue(app.buttons["daily-lesson"].label.hasPrefix("Continue:"))
        tap("daily-lesson");XCTAssertTrue(app.staticTexts["The home ground"].exists)
        tap("lesson-next")
        for _ in 0..<4 {tap("answer-choice-0");tap("answer-next")}
        tap("back-roadmap")
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
        tap("back-roadmap")
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

    func testAlbumFiltersSearchAndPartialKnowledge() {
        start();tap("choose-XT");app.tabBars.buttons["Album"].tap()
        app.switches["album-discovered-only"].coordinate(withNormalizedOffset:CGVector(dx:0.93,dy:0.5)).tap();tap("album-show-all")
        app.tabBars.buttons["Learn"].tap();completeLesson("lesson-xolos-identity")
        app.tabBars.buttons["Album"].tap()
        XCTAssertTrue(app.staticTexts["album-count"].label.contains("1 of 14 discovered"))
        app.switches["album-discovered-only"].coordinate(withNormalizedOffset:CGVector(dx:0.93,dy:0.5)).tap()
        XCTAssertTrue(app.staticTexts["album-count"].label.contains("1 of 14 discovered"))
        tap("card-xolos")
        XCTAssertTrue(app.staticTexts["card-coverage"].label.contains("3 of 12 connections introduced"))
        XCTAssertTrue(app.staticTexts["card-current-recall"].label.contains("9 to discover"))
        app.navigationBars.buttons.element(boundBy:0).tap()
        for _ in 0..<4 {if app.buttons["album-collection"].isHittable {break};app.swipeDown()}
        tap("album-collection");app.buttons["Champions League"].tap();tap("album-show-all")
        XCTAssertTrue(app.staticTexts["album-membership-scope"].label.contains("2026/27 UEFA Champions League league phase"))
        XCTAssertTrue(app.staticTexts["album-count"].label.contains("0 of 52 discovered"))
        let search=app.searchFields.firstMatch
        if !search.isHittable {app.swipeDown()};search.tap();search.typeText("Arsenal")
        XCTAssertTrue(app.staticTexts["album-results"].label.contains("1 search result"))
        XCTAssertTrue(app.staticTexts["album-count"].label.contains("0 of 52 discovered"))
        tap("card-arsenal")
        XCTAssertTrue(app.staticTexts["Intro · 3 connections"].exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Album knowledge scope";shot.lifetime = .keepAlways;add(shot)
    }
    func testAlbumContextPreviewKeepsRecallDue() {
        start();tap("choose-XT");completeLesson("lesson-xolos-identity")
        app.terminate();start(reset:false,now:1_800_000_000+86401)
        app.tabBars.buttons["Album"].tap();tap("card-xolos")
        for key in ["nickname","city","stadium"] {tap("card-context-objective-xolos-identity-\(key)")}
        tap("card-practice")
        for answer in ["Xolos","Tijuana","Estadio Caliente"] {
            let input=app.descendants(matching:.any)["recall-answer"].firstMatch
            input.tap();input.typeText(answer);tap("check-recall")
            XCTAssertTrue(app.staticTexts["You previewed this fact in the card context or explorer. This answer counts as rehearsal."].exists)
            tap("recall-next")
        }
        XCTAssertTrue(app.staticTexts["0 of 3 recalled independently."].exists);tap("practice-done")
        app.tabBars.buttons["Learn"].tap()
        XCTAssertTrue(app.staticTexts["daily-due-count"].label.contains("3 ready"))
    }
    func testLargeTextAlbum() {
        app.launchArguments=["-ui-testing","-reset-test-state","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch();tap("choose-XT");app.tabBars.buttons["Album"].tap();tap("card-xolos")
        for _ in 0..<6 {if app.staticTexts["card-coverage"].isHittable {break};app.swipeUp()}
        XCTAssertTrue(app.staticTexts["card-coverage"].isHittable)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Large text album";shot.lifetime = .keepAlways;add(shot)
    }

}
