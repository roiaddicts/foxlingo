import XCTest
@testable import FoxlingoCore

final class DailyGridTests:XCTestCase {
    let now=Date(timeIntervalSince1970:1800000000)
    private func data() throws -> Data {try Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("ref/futbol11-daily/2026-10-09-d72036ad4a75.json"))}
    private func round() throws -> DailyGrid {try XCTUnwrap(DailyChallengePack.load(data()).grid)}
    func testCurrentBundledPacketLoadsWithAllCurrentAdapters() throws {
        let url=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Foxlingo/Resources/daily-en.json")
        let pack=try DailyChallengePack.load(Data(contentsOf:url));XCTAssertEqual(pack.supportedModeIDs.count,14);XCTAssertNotNil(pack.grid)
    }
    func testFourSourceBoardsAndExplicitUnionMemberships() throws {
        let r=try round();XCTAssertEqual(r.players.count,3492);XCTAssertEqual(r.boards.count,4);XCTAssertEqual(try DailyChallengePack.load(data()).supportedModeIDs.count,11)
        XCTAssertEqual(r.board(.easy).columns.map(\.title),["Argentina","Tottenham","Man Utd"]);XCTAssertEqual(r.board(.easy).rows.map(\.title),["Arsenal","Inter","Juventus"])
        XCTAssertEqual(r.board(.normal).columns.map(\.title),["Arsenal","Man City","Juventus"]);XCTAssertEqual(r.board(.hard).columns.map(\.title),["Ukraine","AC Milan","Wales"]);XCTAssertEqual(r.board(.legend).columns.map(\.title),["Lazio","Villarreal","PSV"])
        XCTAssertEqual(r.board(.hard).candidates[0],["daily-general-861"]);XCTAssertEqual(r.board(.hard).candidates[2],["daily-general-399"]);XCTAssertEqual(r.board(.hard).candidates[6],["daily-general-983"])
        XCTAssertFalse(r.board(.easy).candidates[0].contains("daily-bingo-retro-525"))
        for board in r.boards {XCTAssertNotNil(BoardMatcher.solution(board.candidates));XCTAssertTrue(board.candidates.allSatisfy {!$0.isEmpty})}
    }
    func testEveryDifficultyAcceptsNineDistinctSourceMatchesAndSingleWinCredit() throws {
        let r=try round()
        for level in DailyGridLevel.allCases {
            var p=DailyGridProgress(round:r);XCTAssertTrue(p.start(in:r,level:level,timer:0,now:now));XCTAssertFalse(p.start(in:r,level:.easy,timer:90,now:now))
            let solution=try XCTUnwrap(BoardMatcher.solution(r.board(level).candidates))
            for slot in 0..<9 {XCTAssertTrue(p.place(solution[slot]!,at:slot,in:r,now:now))}
            XCTAssertEqual(p.status,.won);XCTAssertTrue(p.valid(for:r));XCTAssertFalse(p.undo(in:r,now:now));XCTAssertFalse(p.reveal(in:r,now:now))
            var state=LearnerState();XCTAssertTrue(state.completeGame(id:p.sessionID,kind:"grid",count:9,now:now));XCTAssertFalse(state.completeGame(id:p.sessionID,kind:"grid",count:9,now:now))
        }
    }
    func testWrongPairDuplicateForeignIDAndUndoDoNotCorruptHistory() throws {
        let r=try round();var p=DailyGridProgress(round:r);XCTAssertTrue(p.start(in:r,level:.easy,timer:0,now:now))
        XCTAssertFalse(p.place("daily-general-1",at:0,in:r,now:now));XCTAssertEqual(p.mistakes.count,1);XCTAssertFalse(p.place("daily-general-1",at:0,in:r,now:now));XCTAssertEqual(p.mistakes.count,1)
        XCTAssertFalse(p.place("daily-bingo-retro-1",at:0,in:r,now:now));XCTAssertTrue(p.placed.isEmpty)
        // Sanchez fits Arsenal×Man United and Inter×Man United. Source
        // uniqueness prevents putting that same person in both squares.
        XCTAssertTrue(p.place("daily-general-178",at:2,in:r,now:now));XCTAssertFalse(p.place("daily-general-178",at:5,in:r,now:now));XCTAssertEqual(p.history,[2]);XCTAssertTrue(p.undo(in:r,now:now));XCTAssertTrue(p.placed.isEmpty);XCTAssertTrue(p.place("daily-general-178",at:5,in:r,now:now));XCTAssertTrue(p.valid(for:r))
    }
    func testActiveTimersPauseResumeAndRejectLatePlacementAndRevealDoesNotWin() throws {
        let r=try round()
        for timer in [60,90] {
            var p=DailyGridProgress(round:r);XCTAssertTrue(p.start(in:r,level:.normal,timer:timer,now:now));p.pause(at:now.addingTimeInterval(20));XCTAssertNil(p.deadline);XCTAssertEqual(p.remaining(at:now.addingTimeInterval(1000)),timer-20)
            p.resume(at:now.addingTimeInterval(1000));XCTAssertEqual(p.remaining(at:now.addingTimeInterval(1001)),timer-21)
            let end=now.addingTimeInterval(1000+Double(timer)-20),id=r.board(.normal).candidates[0].sorted()[0]
            XCTAssertFalse(p.place(id,at:0,in:r,now:end));XCTAssertEqual(p.status,.lost);XCTAssertTrue(p.valid(for:r));XCTAssertEqual(p.remaining(at:end),0)
        }
        var reveal=DailyGridProgress(round:r);XCTAssertTrue(reveal.start(in:r,level:.hard,timer:0,now:now));XCTAssertTrue(reveal.reveal(in:r,now:now));XCTAssertEqual(reveal.status,.revealed);XCTAssertFalse(reveal.undo(in:r,now:now));XCTAssertTrue(reveal.valid(for:r))
    }
    func testSavedPausedTimerPlacementsAndInvalidState() throws {
        let r=try round(),dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer {try? FileManager.default.removeItem(at:dir)};let cache=DailyChallengeCache(directory:dir)
        var p=DailyGridProgress(round:r);p.level = .legend;p.timer=90;XCTAssertTrue(p.valid(for:r));try cache.save(p,for:r);XCTAssertEqual(cache.progress(for:r)?.level,.legend)
        XCTAssertTrue(p.start(in:r,level:.legend,timer:90,now:now));let id=r.board(.legend).candidates[0].sorted()[0];XCTAssertTrue(p.place(id,at:0,in:r,now:now));p.pause(at:now.addingTimeInterval(12.5));try cache.save(p,for:r)
        let saved=try XCTUnwrap(cache.progress(for:r));XCTAssertEqual(saved.timeLeft,77.5);XCTAssertNil(saved.deadline);XCTAssertEqual(saved.placed,p.placed);XCTAssertEqual(saved.history,p.history);XCTAssertEqual(saved.sessionID,p.sessionID)
        var bad=p;bad.placed[1]=id;bad.history.append(1);XCTAssertFalse(bad.valid(for:r));bad=p;bad.history=[];XCTAssertFalse(bad.valid(for:r));bad=p;bad.timeLeft=100;XCTAssertFalse(bad.valid(for:r));bad=p;bad.reviewRecorded=true;XCTAssertFalse(bad.valid(for:r));XCTAssertThrowsError(try cache.save(bad,for:r))
    }
    func testForgedHeadersModesDateAndMembershipBindingFailAndOlderPackLoads() throws {
        let original=try JSONSerialization.jsonObject(with:data()) as! [String:Any]
        func changed(_ mutation:(inout [String:Any])->Void) throws -> Data {var root=original;var games=root["games"] as! [[String:Any]],i=games.firstIndex {$0["id"] as? String == "grid"}!,selection=games[i]["selection"] as! [String:Any];mutation(&selection);games[i]["selection"]=selection;root["games"]=games;return try JSONSerialization.data(withJSONObject:root)}
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["boardDate"]="2026-10-08";s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["playerSourceURL"]="https://futbol11.com/fake.js";s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var b=s["boards"] as! [[String:Any]],cols=b[0]["columns"] as! [[String:Any]];cols[0]["name"]="Fake";b[0]["columns"]=cols;s["boards"]=b}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var b=s["boards"] as! [[String:Any]];b[1]["mode"]="easy";s["boards"]=b}))
        let old=try DailyChallengePack.load(changed {$0.removeValue(forKey:"catalog")});XCTAssertNil(old.grid);XCTAssertEqual(old.supportedModeIDs.count,10)
    }
}
