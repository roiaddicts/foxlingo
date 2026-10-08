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
        XCTAssertTrue(app.staticTexts["lesson-complete"].waitForExistence(timeout:3))
        tap("back-roadmap")
    }
    func graphSelect(_ control:String,_ name:String,_ key:String) {
        tap(control)
        let search=app.searchFields.firstMatch;search.tap();search.typeText(name)
        tap("graph-select-entity-\(key)")
    }
    func choosePlayer(_ name:String,_ key:String) {
        for _ in 0..<6 {if app.buttons["switch-club"].isHittable {break};app.swipeDown()}
        tap("switch-club");app.segmentedControls["roadmap-subject-type"].buttons["Players"].tap()
        let search=app.searchFields.firstMatch;search.tap();search.typeText(name);tap("club-entity-\(key)")
    }
    func testPlayerRoadmapSharedProgressOptionalContextAndPersistence() {
        start();tap("choose-XT");choosePlayer("Sergio Ramos","ramos")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("0 of 1 starter lessons"))
        XCTAssertTrue(app.staticTexts["daily-lesson-subject"].label.contains("Sergio Ramos · Your roadmap"))
        completeLesson("lesson-madrid-ramos")
        XCTAssertTrue(app.staticTexts["Your player starter is complete."].exists)
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("1 of 1 starter lessons"))
        XCTAssertTrue(app.staticTexts["roadmap-optional-progress"].label.contains("0 of 1 optional"))
        app.terminate();start(reset:false)
        XCTAssertTrue(app.staticTexts["Sergio Ramos"].exists)
        tap("switch-club");let search=app.searchFields.firstMatch;search.tap();search.typeText("Real Madrid");tap("club-entity-madrid")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("1 of 6 lessons"))
        choosePlayer("Sergio Ramos","ramos")
        completeLesson("lesson-madrid-decima")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("1 of 1 starter lessons"))
        XCTAssertTrue(app.staticTexts["roadmap-optional-progress"].label.contains("1 of 1 optional"))
        app.terminate();start(reset:false,now:1_800_000_000+86401)
        XCTAssertTrue(app.staticTexts["daily-due-count"].label.contains("5 ready"))
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Player starter progress";shot.lifetime = .keepAlways;add(shot)
    }
    func testPlayerRoadmapAlbumEntryAndExplicitSelection() {
        start();tap("choose-XT");app.tabBars.buttons["Album"].tap();tap("card-cristiano");tap("card-player-roadmap")
        XCTAssertTrue(app.staticTexts["player-roadmap-progress"].label.contains("0 of 1 starter lessons"))
        XCTAssertTrue(app.staticTexts["Optional club context".uppercased()].exists)
        tap("player-roadmap-select");XCTAssertTrue(app.staticTexts["player-roadmap-selected"].exists)
        app.tabBars.buttons["Learn"].tap();XCTAssertTrue(app.staticTexts["Cristiano Ronaldo"].exists)
    }
    func testLargeTextPlayerRoadmap() {
        app.launchArguments=["-ui-testing","-reset-test-state","-test-now","1800000000","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"];app.launch()
        tap("choose-XT");choosePlayer("Cirilo Saucedo","saucedo")
        XCTAssertTrue(app.staticTexts["roadmap-progress"].label.contains("0 of 1 starter lessons"))
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
            tap("mystery-choose");tap("mystery-player-entity-"+key)
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
        XCTAssertFalse(app.staticTexts["Duvier Riascos"].exists)
        tap("mystery-choose");tap("mystery-player-entity-cristiano")
        XCTAssertTrue(app.staticTexts["mystery-feedback"].label.contains("cannot rule"))
        XCTAssertTrue(app.descendants(matching:.any)["mystery-clue-1"].firstMatch.exists)
        XCTAssertFalse(app.staticTexts["mystery-identity"].exists)
        tap("mystery-choose");tap("mystery-player-entity-riascos")
        XCTAssertEqual(app.staticTexts["mystery-identity"].label,"Duvier Riascos")
        tap("mystery-sources");XCTAssertTrue(app.navigationBars["Sources & context"].exists);app.buttons["Done"].tap()
        tap("mystery-next");XCTAssertFalse(app.staticTexts["Duvier Riascos"].exists)
        for key in ["arce","saucedo","cristiano","ramos","casillas"] {
            if key == "saucedo" {
                tap("mystery-choose");tap("mystery-player-entity-ramos")
                XCTAssertTrue(app.staticTexts["mystery-feedback"].label.contains("differs"))
                tap("mystery-reveal")
                XCTAssertEqual(app.descendants(matching:.any)["mystery-context-1"].firstMatch.label,"Club Tijuana")
                tap("mystery-reveal")
                XCTAssertTrue(app.descendants(matching:.any)["mystery-clue-2"].firstMatch.exists)
            }
            tap("mystery-choose");tap("mystery-player-entity-"+key);tap("mystery-next")
        }
        XCTAssertTrue(app.staticTexts["mystery-complete"].exists)
        let shot=XCTAttachment(screenshot:app.screenshot());shot.name="Mystery board complete";shot.lifetime = .keepAlways;add(shot)
        tap("mystery-replay");XCTAssertFalse(app.staticTexts["mystery-complete"].exists);XCTAssertFalse(app.staticTexts["mystery-identity"].exists)
        XCTAssertFalse(app.descendants(matching:.any)["mystery-clue-1"].firstMatch.exists)
        let restart=XCTAttachment(screenshot:app.screenshot());restart.name="Mystery hidden player";restart.lifetime = .keepAlways;add(restart)
    }

    func testLargeTextMysteryCluesAndPlayerPicker() {
        app.launchArguments=["-ui-testing","-reset-test-state","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch();tap("choose-XT");app.tabBars.buttons["Games"].tap();tap("game-mystery")
        tap("mystery-reveal")
        let clue=XCTAttachment(screenshot:app.screenshot());clue.name="Mystery clues at large text";clue.lifetime = .keepAlways;add(clue)
        tap("mystery-choose");tap("mystery-player-entity-riascos")
        XCTAssertTrue(app.staticTexts["mystery-identity"].exists)
        tap("mystery-next");XCTAssertFalse(app.staticTexts["mystery-identity"].exists)
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

    func testLessonUpdateActivatesNextLaunchAndRestartsChangedResume() {
        start();tap("choose-XT");completeLesson("lesson-xolos-identity")
        tap("lesson-xolos-identity");tap("lesson-next");tap("lesson-next")
        for _ in 0..<3 {tap("answer-choice-0");tap("answer-next")}
        XCTAssertTrue(app.buttons["answer-choice-0"].exists)
        app.terminate()
        app.launchArguments=["-ui-testing","-test-now","1800000000","-stage-test-lessons"];app.launch()
        app.tabBars.buttons["Album"].tap();app.buttons["Settings"].tap();tap("lesson-updates")
        XCTAssertTrue(app.descendants(matching:.any)["lesson-installed-version"].firstMatch.exists)
        XCTAssertEqual(app.descendants(matching:.any)["lesson-installed-version"].firstMatch.value as? String,"Version 5")
        XCTAssertTrue(app.descendants(matching:.any)["lesson-update-staged"].firstMatch.exists)
        let staged=XCTAttachment(screenshot:app.screenshot());staged.name="Lesson update waiting";staged.lifetime = .keepAlways;add(staged)
        app.terminate();start(reset:false)
        tap("lesson-xolos-identity")
        XCTAssertTrue(app.staticTexts["Updated story fixture"].exists)
        XCTAssertFalse(app.buttons["match-l-0"].exists)
        app.navigationBars.buttons["Close lesson"].tap()
        app.tabBars.buttons["Album"].tap();app.buttons["Settings"].tap();tap("lesson-updates")
        XCTAssertEqual(app.descendants(matching:.any)["lesson-installed-version"].firstMatch.value as? String,"Version 6")
        tap("lesson-rollback")
        app.buttons["Restore on next launch"].tap()
        app.swipeDown();app.swipeDown()
        XCTAssertTrue(app.descendants(matching:.any)["lesson-update-staged"].firstMatch.exists)
        app.terminate();start(reset:false)
        app.tabBars.buttons["Album"].tap();app.buttons["Settings"].tap();tap("lesson-updates")
        XCTAssertEqual(app.descendants(matching:.any)["lesson-installed-version"].firstMatch.value as? String,"Version 5")
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
        XCTAssertEqual(app.buttons["memory-memory-cristiano-image"].value as? String,"Face down")
        let hidden=NSPredicate(format:"value == %@","Face down")
        expectation(for:hidden,evaluatedWith:app.buttons[image]);waitForExpectations(timeout:5)
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
        XCTAssertTrue(app.staticTexts["album-count"].label.contains("1 of 8 discovered"))
        app.switches["album-discovered-only"].coordinate(withNormalizedOffset:CGVector(dx:0.93,dy:0.5)).tap()
        XCTAssertTrue(app.staticTexts["album-count"].label.contains("1 of 8 discovered"))
        tap("card-xolos")
        XCTAssertTrue(app.staticTexts["card-coverage"].label.contains("3 of 9 connections introduced"))
        XCTAssertTrue(app.staticTexts["card-current-recall"].label.contains("6 to discover"))
        app.navigationBars.buttons.element(boundBy:0).tap()
        for _ in 0..<4 {if app.buttons["album-collection"].isHittable {break};app.swipeDown()}
        tap("album-collection");app.buttons["Champions League"].tap();tap("album-show-all")
        XCTAssertTrue(app.staticTexts["album-count"].label.contains("0 of 39 discovered"))
        let search=app.searchFields.firstMatch
        if !search.isHittable {app.swipeDown()};search.tap();search.typeText("Arsenal")
        XCTAssertTrue(app.staticTexts["album-results"].label.contains("1 search result"))
        XCTAssertTrue(app.staticTexts["album-count"].label.contains("0 of 39 discovered"))
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
