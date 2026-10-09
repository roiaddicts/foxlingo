import XCTest
@testable import FoxlingoCore

final class DailyVisualBoardTests: XCTestCase {
    private func data() throws -> Data {try Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Foxlingo/Resources/daily-en.json"))}
    private func pack() throws -> DailyChallengePack {try DailyChallengePack.load(data())}
    func testPyramidSourceSelectionsAndExactRanking() throws {
        let round=try pack().pyramid
        XCTAssertEqual(round.title,"All Time Portugal Goals")
        XCTAssertEqual(round.offers.map {$0.player.id},[836,327,45,632,904,193,128,154,97,828].map {"daily-general-\($0)"})
        XCTAssertEqual(round.correctOrder,[327,154,836,97,128,828,45,193,632,904].map {"daily-general-\($0)"})
        XCTAssertEqual(round.offers[0].player.name,"Luis Nani")
        XCTAssertEqual(round.offers[1].player.name,"Pauleta")
        XCTAssertEqual(round.hintBand(for:round.correctOrder[0]),0..<3)
        XCTAssertEqual(round.hintBand(for:round.correctOrder[4]),3..<6)
        XCTAssertEqual(round.hintBand(for:round.correctOrder[9]),6..<10)
        XCTAssertNil(round.hintBand(for:"draft-nations-player-1"))
    }
    func testPyramidPartialMovesHelpLocksAndExactFinalWin() throws {
        let round=try pack().pyramid;var p=PyramidProgress(round:round,easy:true)
        XCTAssertFalse(p.submit(in:round));XCTAssertFalse(p.help(in:round))
        XCTAssertTrue(p.place(at:0,in:round));XCTAssertFalse(p.place(at:0,in:round))
        XCTAssertTrue(p.move(from:0,to:8,in:round));XCTAssertEqual(p.offered(round)?.player.id,round.offers[1].player.id)
        XCTAssertFalse(p.move(from:0,to:1,in:round));XCTAssertFalse(p.move(from:8,to:99,in:round))
        for rank in 0..<10 where p.slots[rank] == nil {XCTAssertTrue(p.place(at:rank,in:round))}
        for rank in 0..<10 {
            let correct=round.correctOrder[rank]
            if p.slots[rank] != correct {XCTAssertTrue(p.move(from:p.slots.firstIndex(of:correct)!,to:rank,in:round))}
        }
        XCTAssertTrue(p.help(in:round));XCTAssertEqual(p.locked.count,10);XCTAssertFalse(p.help(in:round))
        XCTAssertFalse(p.move(from:0,to:1,in:round));XCTAssertTrue(p.submit(in:round));XCTAssertTrue(p.won(round));XCTAssertTrue(p.valid(for:round))
        XCTAssertFalse(p.submit(in:round));XCTAssertFalse(p.place(at:0,in:round))
        var state=LearnerState();XCTAssertTrue(state.completeGame(id:p.sessionID,kind:"pyramid",count:10,now:Date()));XCTAssertFalse(state.completeGame(id:p.sessionID,kind:"pyramid",count:10,now:Date()))
    }
    func testPyramidIncorrectRankingIsACompletedLossAndResumePreservesMoves() throws {
        let round=try pack().pyramid;var p=PyramidProgress(round:round)
        for slot in 0..<10 {XCTAssertTrue(p.place(at:slot,in:round))}
        XCTAssertTrue(p.move(from:0,to:1,in:round))
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer {try? FileManager.default.removeItem(at:directory)}
        let cache=DailyChallengeCache(directory:directory);try cache.save(p,for:round)
        var saved=try XCTUnwrap(cache.progress(for:round));XCTAssertEqual(saved.slots,p.slots);XCTAssertEqual(saved.sessionID,p.sessionID)
        XCTAssertTrue(saved.help(in:round));XCTAssertEqual(saved.locked,saved.correctSlots(round))
        XCTAssertTrue(saved.submit(in:round));XCTAssertFalse(saved.won(round));try cache.save(saved,for:round)
        XCTAssertTrue(cache.progress(for:round)!.finished)
        saved.slots[1]=saved.slots[0];XCTAssertFalse(saved.valid(for:round));XCTAssertThrowsError(try cache.save(saved,for:round))
    }
    func testSquadExactRosterNationalitiesAndWholeSliceStages() throws {
        let round=try XCTUnwrap(pack().squadSlice)
        XCTAssertEqual(round.answer.id,12);XCTAssertEqual(round.answer.name,"AC Milan");XCTAssertEqual(round.season,"2016/17")
        XCTAssertEqual(round.total,28);XCTAssertEqual(round.countries.count,12)
        XCTAssertEqual(round.countries.first?.name,"Italy");XCTAssertEqual(round.countries.first?.count,13)
        XCTAssertEqual(round.randomOrder,[65,1,13,51,10,6,17,34,37,7,19,66])
        XCTAssertEqual(round.visibleCountries(at:0,clockwise:false),Set([65,1,13,51]))
        XCTAssertEqual(round.visibleCountries(at:1,clockwise:false),Set([65,1,13,51,10]))
        XCTAssertEqual(round.visibleCountries(at:0,clockwise:true),Set([10]))
        XCTAssertEqual(round.visibleCountries(at:1,clockwise:true),Set([10,1]))
        XCTAssertEqual(round.visibleCountries(at:2,clockwise:false).count,12)
        XCTAssertEqual(round.visibleCountries(at:0,clockwise:false,finished:true).count,12)
        XCTAssertEqual(Set(round.countries.flatMap {$0.players.map(\.id)}).count,28)
    }
    func testSquadWrongGuessDuplicateFinalChanceAndTerminalLoss() throws {
        let round=try XCTUnwrap(pack().squadSlice);var p=SquadSliceProgress(round:round)
        XCTAssertFalse(p.submit(99999,in:round));XCTAssertTrue(p.submit(1,in:round));XCTAssertFalse(p.submit(1,in:round))
        XCTAssertFalse(p.finished(round));XCTAssertTrue(p.submit(nil,in:round));XCTAssertFalse(p.finished(round))
        XCTAssertTrue(p.submit(round.answer.id,in:round));XCTAssertTrue(p.won(round));XCTAssertTrue(p.finished(round));XCTAssertTrue(p.valid(for:round))
        XCTAssertFalse(p.submit(nil,in:round))
        var state=LearnerState();XCTAssertTrue(state.completeGame(id:p.sessionID,kind:"squadslice",count:3,now:Date()));XCTAssertFalse(state.completeGame(id:p.sessionID,kind:"squadslice",count:3,now:Date()))
        var lost=SquadSliceProgress(round:round,clockwise:true)
        for _ in 0..<3 {XCTAssertTrue(lost.submit(nil,in:round))}
        XCTAssertTrue(lost.finished(round));XCTAssertFalse(lost.won(round));XCTAssertTrue(lost.valid(for:round));XCTAssertFalse(lost.submit(round.answer.id,in:round))
    }
    func testSquadCacheRejectsInvalidRoundAndKeepsFinishedResult() throws {
        let round=try XCTUnwrap(pack().squadSlice),directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        let cache=DailyChallengeCache(directory:directory);var p=SquadSliceProgress(round:round,clockwise:true)
        _ = p.submit(nil,in:round);try cache.save(p,for:round)
        var restored=try XCTUnwrap(cache.progress(for:round));XCTAssertTrue(restored.clockwise);XCTAssertEqual(restored.sessionID,p.sessionID);XCTAssertEqual(restored.guesses.count,1)
        _ = restored.submit(round.answer.id,in:round);try cache.save(restored,for:round);XCTAssertTrue(cache.progress(for:round)!.won(round))
        restored.guesses.append(nil);XCTAssertFalse(restored.valid(for:round));XCTAssertThrowsError(try cache.save(restored,for:round))
    }
    func testSourceRelationshipTamperingIsRejectedBeforeInstall() throws {
        let raw=try data()
        for mode in ["pyramid","squadslice"] {
            var root=try JSONSerialization.jsonObject(with:raw) as! [String:Any],games=root["games"] as! [[String:Any]],i=games.firstIndex {$0["id"] as? String == mode}!
            var selection=games[i]["selection"] as! [String:Any]
            if mode == "pyramid" {var players=selection["players"] as! [[String:Any]];players[0]["value"]=999;selection["players"]=players}
            else {var slices=selection["slices"] as! [[String:Any]];slices[0]["count"]=999;selection["slices"]=slices}
            games[i]["selection"]=selection;root["games"]=games
            XCTAssertThrowsError(try DailyChallengePack.load(JSONSerialization.data(withJSONObject:root)))
        }
        var root=try JSONSerialization.jsonObject(with:raw) as! [String:Any];root["elapsedDayFloor"]=1
        XCTAssertThrowsError(try DailyChallengePack.load(JSONSerialization.data(withJSONObject:root)))
    }
}
