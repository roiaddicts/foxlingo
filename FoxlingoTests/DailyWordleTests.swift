import XCTest
@testable import FoxlingoCore

final class DailyWordleTests:XCTestCase {
    private func data() throws -> Data {try Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("ref/futbol11-daily/2026-10-09-d72036ad4a75.json"))}
    private func round() throws -> DailyWordle {try XCTUnwrap(DailyChallengePack.load(data()).wordle)}
    func testDailyAnswerExactWholeFieldNamesAndSourcePlayerExamples() throws {
        let r=try round();XCTAssertEqual(r.answer,"TERRY");XCTAssertEqual(r.matchingPlayers.map(\.id),["daily-general-417"]);XCTAssertEqual(r.matchingPlayers.first?.name,"John Terry")
        XCTAssertTrue(r.accepted.contains("KYLIAN"));XCTAssertTrue(r.accepted.contains("BELLINGHAM"));XCTAssertFalse(r.accepted.contains("KYLIÁN"))
        XCTAssertTrue(r.accepts("MESSI",mode:.normal));XCTAssertFalse(r.accepts("ZZZZZ",mode:.normal));XCTAssertTrue(r.accepts("ZZZZZ",mode:.easy));XCTAssertFalse(r.accepts("TÉRRY",mode:.easy));XCTAssertFalse(r.accepts("TE RY",mode:.easy));XCTAssertFalse(r.accepts("TERRYX",mode:.easy))
        XCTAssertEqual(try DailyChallengePack.load(data()).supportedModeIDs.count,11)
    }
    func testDifficultyLocksAfterFirstGuessUnknownNamesRetainInputAndDuplicatesAreAllowed() throws {
        let r=try round();var p=DailyWordleProgress(round:r)
        for c in "ZZZZZ" {XCTAssertTrue(p.type(c,in:r))};XCTAssertFalse(p.type("A",in:r));XCTAssertFalse(p.submit(in:r));XCTAssertEqual(p.input,"ZZZZZ");XCTAssertTrue(p.guesses.isEmpty)
        XCTAssertTrue(p.setMode(.easy,in:r));XCTAssertTrue(p.submit(in:r));XCTAssertEqual(p.guesses,["ZZZZZ"]);XCTAssertTrue(p.input.isEmpty);XCTAssertFalse(p.setMode(.normal,in:r))
        for c in "ZZZZZ" {XCTAssertTrue(p.type(c,in:r))};XCTAssertTrue(p.submit(in:r));XCTAssertEqual(p.guesses,["ZZZZZ","ZZZZZ"]);XCTAssertTrue(p.valid(for:r))
        XCTAssertTrue(p.type("T",in:r));XCTAssertTrue(p.delete(in:r));XCTAssertFalse(p.delete(in:r));XCTAssertFalse(p.type("é",in:r))
    }
    func testDuplicateLetterFeedbackAndKeyboardPriority() throws {
        let r=try round()
        XCTAssertEqual(FootballWordle.feedback(guess:"RARER",answer:"TERRY"),[.present,.absent,.correct,.present,.absent])
        XCTAssertEqual(FootballWordle.feedback(guess:"RRRRR",answer:"TERRY"),[.absent,.absent,.correct,.correct,.absent])
        XCTAssertEqual(r.keyMark("R",guesses:["RARER","RRRRR"]),.correct);XCTAssertEqual(r.keyMark("A",guesses:["RARER"]),.absent);XCTAssertNil(r.keyMark("Z",guesses:["RARER"]))
    }
    func testFinalChanceWinAndSixGuessesLossRemainFinishedAndSingleCredit() throws {
        let r=try round();var p=DailyWordleProgress(round:r)
        for _ in 0..<5 {p.input="MESSI";XCTAssertTrue(p.submit(in:r))};XCTAssertFalse(p.finished(r));p.input="TERRY";XCTAssertTrue(p.submit(in:r));XCTAssertTrue(p.won(r));XCTAssertTrue(p.valid(for:r));XCTAssertFalse(p.type("A",in:r));XCTAssertFalse(p.submit(in:r))
        var state=LearnerState();XCTAssertTrue(state.completeGame(id:p.sessionID,kind:"wordle",count:p.guesses.count,now:Date()));XCTAssertFalse(state.completeGame(id:p.sessionID,kind:"wordle",count:p.guesses.count,now:Date()))
        var loss=DailyWordleProgress(round:r);for _ in 0..<6 {loss.input="MESSI";XCTAssertTrue(loss.submit(in:r))};XCTAssertTrue(loss.finished(r));XCTAssertFalse(loss.won(r));XCTAssertTrue(loss.valid(for:r))
    }
    func testSavedPartialInputDifficultyCompletedOutcomeAndInvalidProgress() throws {
        let r=try round(),dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer {try? FileManager.default.removeItem(at:dir)};let cache=DailyChallengeCache(directory:dir)
        var p=DailyWordleProgress(round:r);XCTAssertTrue(p.setMode(.easy,in:r));p.input="ZZZZZ";XCTAssertTrue(p.submit(in:r));p.input="TER";try cache.save(p,for:r)
        let restored=try XCTUnwrap(cache.progress(for:r));XCTAssertEqual(restored.input,"TER");XCTAssertEqual(restored.mode,.easy);XCTAssertEqual(restored.guesses,p.guesses);XCTAssertEqual(restored.sessionID,p.sessionID)
        p.input="TERRY";XCTAssertTrue(p.submit(in:r));p.reviewRecorded=true;try cache.save(p,for:r);XCTAssertTrue(try XCTUnwrap(cache.progress(for:r)).won(r))
        p.guesses.append("MESSI");XCTAssertFalse(p.valid(for:r));XCTAssertThrowsError(try cache.save(p,for:r))
        var bad=DailyWordleProgress(round:r);bad.reviewRecorded=true;XCTAssertFalse(bad.valid(for:r));bad.reviewRecorded=false;bad.input="TOO LONG";XCTAssertFalse(bad.valid(for:r));bad.input="";bad.guesses=["ZZZZZ"];XCTAssertFalse(bad.valid(for:r))
    }
    func testForgedAnswerIndexCatalogAndPlayerBindingFailAndOlderPackLoads() throws {
        let original=try JSONSerialization.jsonObject(with:data()) as! [String:Any]
        func changed(_ mutation:(inout [String:Any])->Void) throws -> Data {var root=original;var games=root["games"] as! [[String:Any]],i=games.firstIndex {$0["id"] as? String == "wordle"}!,selection=games[i]["selection"] as! [String:Any];mutation(&selection);games[i]["selection"]=selection;root["games"]=games;return try JSONSerialization.data(withJSONObject:root)}
        XCTAssertThrowsError(try DailyChallengePack.load(changed {$0["answer"]="MESSI"}));XCTAssertThrowsError(try DailyChallengePack.load(changed {$0["index"]=281}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["playerSourceURL"]="https://futbol11.com/fake.js";s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any],words=c["words"] as! [String];words[0]="GÖTZE";c["words"]=words;s["catalog"]=c}))
        let old=try DailyChallengePack.load(changed {$0.removeValue(forKey:"catalog")});XCTAssertNil(old.wordle);XCTAssertEqual(old.supportedModeIDs.count,10)
    }
}
