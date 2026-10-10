import XCTest
@testable import FoxlingoCore

final class DailyConnectionsTests:XCTestCase {
    func data() throws -> Data {try Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("ref/futbol11-daily/2026-10-10-295a178f00bc.json"))}
    func round() throws -> DailyConnections {try XCTUnwrap(DailyChallengePack.load(data()).connections)}
    func testSourceBoardsPortraitsAndHardUsesNormal() throws {
        let r=try round();XCTAssertEqual(try DailyChallengePack.load(data()).supportedModeIDs.count,13)
        XCTAssertEqual(r.normal.groups.map(\.title),["Played for Besiktas","Pichichi Winners","Played for West Ham","From Spain"])
        XCTAssertEqual(r.board(.hard).order,r.normal.order);XCTAssertEqual(r.board(.hard).groups.map(\.id),r.normal.groups.map(\.id));XCTAssertNotEqual(r.easy.order,r.normal.order)
        for board in [r.easy,r.normal] {XCTAssertEqual(board.groups.count,4);XCTAssertEqual(Set(board.order).count,16);XCTAssertEqual(Set(board.order),Set(board.groups.flatMap(\.playerIDs)));for id in board.order {XCTAssertNotNil(r.player(id)?.imageURL);XCTAssertTrue(id.hasPrefix("daily-general-"))}}
    }
    func testSelectionFourLimitExactWinsAndSingleCredit() throws {
        let r=try round()
        for level in ConnectionsLevel.allCases {
            var p=ConnectionsProgress(round:r);XCTAssertTrue(p.start(in:r,level:level));XCTAssertFalse(p.start(in:r,level:.normal));XCTAssertNil(p.check(in:r));p.select("daily-bingo-retro-1",in:r);XCTAssertTrue(p.selected.isEmpty)
            let board=r.board(level)
            for id in board.order.prefix(5) {p.select(id,in:r)};XCTAssertEqual(p.selected.count,4);p.clear();XCTAssertTrue(p.selected.isEmpty)
            for group in board.groups {for id in group.playerIDs {p.select(id,in:r)};XCTAssertEqual(p.check(in:r),.correct);XCTAssertTrue(p.selected.isEmpty);XCTAssertTrue(p.valid(for:r));for id in group.playerIDs {p.select(id,in:r)};XCTAssertTrue(p.selected.isEmpty)}
            XCTAssertEqual(p.status,.won);XCTAssertEqual(p.checks,4);XCTAssertEqual(p.errors,0);XCTAssertNil(p.check(in:r));XCTAssertFalse(p.giveUp(in:r))
            var state=LearnerState();XCTAssertTrue(state.completeGame(id:p.sessionID,kind:"connections",count:16,now:Date()));XCTAssertFalse(state.completeGame(id:p.sessionID,kind:"connections",count:16,now:Date()))
        }
    }
    func testNearMissHardFiveErrorsAndUnlimitedNormal() throws {
        let r=try round()
        for level in ConnectionsLevel.allCases {
            var p=ConnectionsProgress(round:r);XCTAssertTrue(p.start(in:r,level:level));let b=r.board(level)
            for id in Array(b.groups[0].playerIDs.prefix(3))+[b.groups[1].playerIDs[0]] {p.select(id,in:r)}
            let tries=level == .hard ? 5:8
            for i in 1...tries {XCTAssertEqual(p.check(in:r),.near);XCTAssertEqual(p.errors,i);XCTAssertTrue(p.valid(for:r))}
            XCTAssertEqual(p.mistakes.count,1);XCTAssertEqual(p.selected.count,4)
            if level == .hard {XCTAssertEqual(p.status,.lost);XCTAssertNil(p.check(in:r));XCTAssertFalse(p.giveUp(in:r))}
            else {XCTAssertEqual(p.status,.playing);p.clear();for id in b.groups.map({$0.playerIDs[0]}) {p.select(id,in:r)};XCTAssertEqual(p.check(in:r),.wrong);XCTAssertTrue(p.giveUp(in:r));XCTAssertEqual(p.status,.lost)}
            XCTAssertTrue(p.valid(for:r))
        }
    }
    func testSavedSelectionFoundOrderFinishedLossAndMalformedCache() throws {
        let r=try round(),dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer {try? FileManager.default.removeItem(at:dir)};let cache=DailyChallengeCache(directory:dir)
        var p=ConnectionsProgress(round:r);p.level = .hard;try cache.save(p,for:r);XCTAssertEqual(cache.progress(for:r)?.level,.hard)
        XCTAssertTrue(p.start(in:r,level:.hard));let b=r.board(.hard),first=b.groups[2];for id in first.playerIDs {p.select(id,in:r)};XCTAssertEqual(p.check(in:r),.correct)
        for id in b.groups[0].playerIDs.prefix(2) {p.select(id,in:r)};try cache.save(p,for:r)
        let saved=try XCTUnwrap(cache.progress(for:r));XCTAssertEqual(saved.selected,p.selected);XCTAssertEqual(saved.solved,[first.id]);XCTAssertEqual(saved.sessionID,p.sessionID);XCTAssertEqual(saved.level,.hard)
        var bad=p;bad.errors=Int.max;XCTAssertFalse(bad.valid(for:r));bad=p;bad.selected=Set(first.playerIDs);XCTAssertFalse(bad.valid(for:r));bad=p;bad.solved.append(first.id);XCTAssertThrowsError(try cache.save(bad,for:r));bad=p;bad.status = .won;XCTAssertFalse(bad.valid(for:r));bad=p;bad.reviewRecorded=true;XCTAssertFalse(bad.valid(for:r))
        p.clear();for id in Array(b.groups[0].playerIDs.prefix(3))+[b.groups[1].playerIDs[0]] {p.select(id,in:r)};for _ in 0..<5 {_ = p.check(in:r)};p.reviewRecorded=true;try cache.save(p,for:r);XCTAssertEqual(cache.progress(for:r)?.status,.lost)
    }
    func testForgedCategoryPortraitBindingEasyLevelAndOrderRejected() throws {
        let original=try JSONSerialization.jsonObject(with:data()) as! [String:Any]
        func changed(_ mutate:(inout [String:Any])->Void) throws -> Data {var root=original,games=root["games"] as! [[String:Any]],i=games.firstIndex {$0["id"] as? String == "connections"}!,s=games[i]["selection"] as! [String:Any];mutate(&s);games[i]["selection"]=s;root["games"]=games;return try JSONSerialization.data(withJSONObject:root)}
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["boardDate"]="2026-10-09";s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["playerSourceURL"]=c["categorySourceURL"];s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var boards=s["boards"] as! [[String:Any]],groups=boards[1]["groups"] as! [[String:Any]];groups[0]["title"]="Forged";boards[1]["groups"]=groups;s["boards"]=boards}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var boards=s["boards"] as! [[String:Any]];boards[1]=boards[0];s["boards"]=boards}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var boards=s["boards"] as! [[String:Any]],order=boards[0]["order"] as! [Int];order[0]=order[1];boards[0]["order"]=order;s["boards"]=boards}))
        let old=try DailyChallengePack.load(changed {$0.removeValue(forKey:"catalog")});XCTAssertNil(old.connections);XCTAssertEqual(old.supportedModeIDs.count,12)
    }
}
