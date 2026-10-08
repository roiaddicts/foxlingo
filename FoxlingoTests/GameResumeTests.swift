import XCTest
@testable import FoxlingoCore

final class GameResumeTests: XCTestCase {
    var games: GamePack!
    var rounds: [MysteryRound]!
    var root: URL!
    override func setUpWithError() throws {
        root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        games=try GamePack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/games-en.json")))
        let pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
        rounds=try MysteryDeck.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/mystery-en.json")),pack:pack)
    }
    func savedBoard(_ kind: String="grid",pack: GamePack?=nil) -> GameResume {
        let p=pack ?? games!,squad=kind == "lineup" ? p.lineups[0].id : nil
        let candidates=GameResumeRules.candidates(kind:kind,pack:p,squadID:squad)!
        let solution=BoardMatcher.solution(candidates)!
        let placed=[0:solution[0]!]
        let offered=kind == "bingo" ? solution[1] : nil
        return GameResume(signature:GameResumeRules.boardSignature(kind:kind,pack:p,squadID:squad)!,sessionID:UUID(),board:BoardProgress(squadID:squad,placed:placed,history:[0],assisted:[0],offered:offered))
    }
    func changedGames(_ edit: (inout [String:Any]) -> Void) throws -> GamePack {
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(games)) as! [String:Any];edit(&json)
        return try GamePack.load(JSONSerialization.data(withJSONObject:json))
    }
    func testAllClassicBoardsRestoreWithOfferedPlayerAssistanceAndSession() throws {
        for kind in ["grid","bingo","lineup"] {
            let saved=savedBoard(kind)
            let restored=GameResumeRules.restoreBoard(saved,kind:kind,pack:games,completedSessions:[])!
            XCTAssertEqual(restored.placed,saved.board?.placed);XCTAssertEqual(restored.offered,saved.board?.offered)
            XCTAssertEqual(restored.history,[0]);XCTAssertEqual(restored.assisted,[0])
            var learner=LearnerState();learner.storeGame(saved,kind:kind)
            let restoredState=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(learner))
            XCTAssertEqual(restoredState.savedGame(kind)?.sessionID,saved.sessionID)
        }
    }
    func testLineupStableSquadIDSurvivesReorderedRecords() throws {
        let saved=savedBoard("lineup")
        let reordered=try changedGames {$0["lineups"]=(($0["lineups"] as! [[String:Any]]).reversed().map {$0})}
        XCTAssertNotNil(GameResumeRules.restoreBoard(saved,kind:"lineup",pack:reordered,completedSessions:[]))
        XCTAssertEqual(saved.board?.squadID,games.lineups[0].id)
    }
    func testArtworkDoesNotInvalidateButGridOrientationDoes() throws {
        let saved=savedBoard()
        let art=try changedGames {j in
            var players=j["players"] as! [[String:Any]];players[0]["imageURL"]="https://example.com/new.png";players[0]["imageAsset"]="new-art";j["players"]=players
            var categories=j["categories"] as! [[String:Any]];categories[0]["imageURL"]="https://example.com/badge.png";j["categories"]=categories
        }
        XCTAssertNotNil(GameResumeRules.restoreBoard(saved,kind:"grid",pack:art,completedSessions:[]))
        let changed=try changedGames {$0["gridColumnIDs"]=(($0["gridColumnIDs"] as! [String]).reversed().map {$0})}
        XCTAssertNil(GameResumeRules.restoreBoard(saved,kind:"grid",pack:changed,completedSessions:[]))
    }
    func testLegalDeadEndWithNoOfferedPlayerStillRestoresForUndo() {
        let players=[GamePlayer(id:"a",name:"A",aliases:["A"],imageURL:nil,imageAsset:nil),GamePlayer(id:"b",name:"B",aliases:["B"],imageURL:nil,imageAsset:nil)]
        let categories=[GameCategory(id:"x",title:"X",playerIDs:["a","b"],imageAsset:nil,imageURL:nil,flag:nil),GameCategory(id:"y",title:"Y",playerIDs:["a"],imageAsset:nil,imageURL:nil,flag:nil)]
        let p=GamePack(schemaVersion:1,scope:"Test board",sourceURL:"https://example.com",players:players,categories:categories,bingoCategoryIDs:["x","y"],gridRowIDs:[],gridColumnIDs:[],lineups:[])
        let board=BoardProgress(squadID:nil,placed:[0:"a"],history:[0],assisted:[],offered:nil)
        let saved=GameResume(signature:GameResumeRules.boardSignature(kind:"bingo",pack:p,squadID:nil)!,sessionID:UUID(),board:board)
        XCTAssertNil(BoardMatcher.solution([Set(["a","b"]),Set(["a"])],fixed:board.placed))
        XCTAssertNotNil(GameResumeRules.restoreBoard(saved,kind:"bingo",pack:p,completedSessions:[]))
    }
    func testMalformedBoardAndAlreadyCreditedSessionAreRejected() {
        let saved=savedBoard(),b=saved.board!
        let wrong=GameResume(signature:saved.signature,sessionID:saved.sessionID,board:BoardProgress(squadID:nil,placed:b.placed,history:[0,0],assisted:[1],offered:nil))
        XCTAssertNil(GameResumeRules.restoreBoard(wrong,kind:"grid",pack:games,completedSessions:[]))
        XCTAssertNil(GameResumeRules.restoreBoard(saved,kind:"grid",pack:games,completedSessions:[saved.sessionID]))
    }
    func mysteryProgress(solved: Bool=false) -> MysteryProgress {
        MysteryProgress(roundIDs:rounds.map(\.id).reversed(),index:2,revealed:3,solved:solved,guesses:2,clueCounts:[1,2])
    }
    func testMysteryOrderRevealsAndSolvedRoundRestore() {
        let progress=mysteryProgress(solved:true)
        let saved=GameResume(signature:GameResumeRules.mysterySignature(rounds),sessionID:UUID(),mystery:progress)
        let restored=GameResumeRules.restoreMystery(saved,rounds:rounds.reversed(),completedSessions:[])!
        XCTAssertEqual(restored.roundIDs,progress.roundIDs);XCTAssertEqual(restored.index,2);XCTAssertEqual(restored.clueCounts,[1,2])
        let turn=MysteryTurn(restoring:restored);XCTAssertEqual(turn.revealed,3);XCTAssertTrue(turn.solved);XCTAssertEqual(turn.guesses,2)
    }
    func testMysteryComparisonMeaningInvalidatesButEvidenceMetadataDoesNot() throws {
        let pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
        let definitions=try Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/mystery-en.json"))
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        var facts=json["facts"] as! [[String:Any]]
        let referenced=Set(rounds.flatMap {$0.facts.keys}.map {$0.uuidString.lowercased()})
        let unrelated=facts.firstIndex {!referenced.contains(($0["id"] as! String).lowercased())}!
        var unrelatedValue=facts[unrelated]["value"] as! [String:Any]
        unrelatedValue["display"]="Unrelated updated fact";facts[unrelated]["value"]=unrelatedValue;json["facts"]=facts
        let unrelatedRounds=try MysteryDeck.load(definitions,pack:ContentPack.load(JSONSerialization.data(withJSONObject:json)))
        XCTAssertEqual(GameResumeRules.mysterySignature(rounds),GameResumeRules.mysterySignature(unrelatedRounds))
        let id=rounds[0].definition.clues[0].comparisonFactIDs[1].uuidString.lowercased()
        let index=facts.firstIndex {($0["id"] as! String).lowercased() == id}!
        facts[index]["evidence"]="Updated editorial wording";json["facts"]=facts
        let metadata=try MysteryDeck.load(definitions,pack:ContentPack.load(JSONSerialization.data(withJSONObject:json)))
        XCTAssertEqual(GameResumeRules.mysterySignature(rounds),GameResumeRules.mysterySignature(metadata))
        var value=facts[index]["value"] as! [String:Any];value["display"]="A changed role";value["text"]="A changed role";facts[index]["value"]=value;json["facts"]=facts
        let changed=try MysteryDeck.load(definitions,pack:ContentPack.load(JSONSerialization.data(withJSONObject:json)))
        XCTAssertNotEqual(GameResumeRules.mysterySignature(rounds),GameResumeRules.mysterySignature(changed))
    }
    func testInvalidGameSnapshotDoesNotLoseLearnerProgressOrOtherBoard() throws {
        var state=LearnerState();state.selectedClub=UUID();state.streak.record(Date(),zone:state.homeTimeZone)
        let good=savedBoard();state.storeGame(good,kind:"grid")
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(state)) as! [String:Any]
        var snapshots=json["gameResumes"] as! [String:Any];snapshots["bingo"]=["board":"broken"];snapshots["unknown-game"]=false;json["gameResumes"]=snapshots
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONSerialization.data(withJSONObject:json))
        XCTAssertEqual(restored.selectedClub,state.selectedClub);XCTAssertEqual(restored.streak.activeDays,state.streak.activeDays)
        XCTAssertEqual(restored.savedGame("grid")?.sessionID,good.sessionID)
        XCTAssertNil(GameResumeRules.restoreBoard(restored.savedGame("bingo")!,kind:"bingo",pack:games,completedSessions:[]))
    }
    func testOlderSaveWithoutGameFieldLoadsAndCompletionSaveHasNoDraft() throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        var state=LearnerState();let saved=savedBoard();state.storeGame(saved,kind:"grid")
        XCTAssertTrue(state.completeGame(id:saved.sessionID,kind:"grid",count:9,now:Date()))
        state.removeSavedGame("grid")
        let store=StateStore(directory:directory);try store.save(state)
        var restored=try store.load()!;XCTAssertNil(restored.savedGame("grid"));XCTAssertEqual(restored.sessions.count,1)
        XCTAssertFalse(restored.completeGame(id:saved.sessionID,kind:"grid",count:9,now:Date()))
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(state)) as! [String:Any];json.removeValue(forKey:"gameResumes")
        XCTAssertNil(try JSONDecoder().decode(LearnerState.self,from:JSONSerialization.data(withJSONObject:json)).gameResumes)
    }
}
