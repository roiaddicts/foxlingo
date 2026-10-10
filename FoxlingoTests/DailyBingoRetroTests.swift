import XCTest
@testable import FoxlingoCore

final class DailyBingoRetroTests:XCTestCase {
    private struct Seeded:RandomNumberGenerator {
        var state:UInt64=42
        mutating func next()->UInt64 {state=state &* 6364136223846793005 &+ 1442695040888963407;return state}
    }
    private let now=Date(timeIntervalSince1970:1800000000)
    private func data() throws -> Data {try Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("ref/futbol11-daily/2026-10-09-d72036ad4a75.json"))}
    private func round() throws -> DailyBingoRetro {try XCTUnwrap(DailyChallengePack.load(data()).bingoRetro)}
    func testSourceBoardPlayersMembershipAndSeparateIdentity() throws {
        let r=try round();XCTAssertEqual(r.players.count,251);XCTAssertEqual(r.categories.count,12)
        XCTAssertEqual(r.categories.map(\.id),[2,32,18,6,11,30,23,36,65,72,3,53].map {"daily-bingo-retro-group-\($0)"})
        XCTAssertEqual(r.player("daily-bingo-retro-1")?.name,"Ibrahimovic")
        XCTAssertTrue(r.accepts("daily-bingo-retro-1",category:"daily-bingo-retro-group-3"))
        XCTAssertFalse(r.accepts("daily-general-1",category:"daily-bingo-retro-group-3"))
        XCTAssertTrue(r.categories.allSatisfy {!$0.playerIDs.isEmpty && $0.imageURL?.hasPrefix("https://") == true})
        XCTAssertEqual(try DailyChallengePack.load(data()).supportedModeIDs.count,11)
    }
    func testSourceOffersSkipsAndHelpfulThresholdRemainPlayable() throws {
        let r=try round();var p=BingoRetroProgress(round:r),rng=Seeded()
        XCTAssertFalse(p.skip(in:r,now:now,rng:&rng));XCTAssertFalse(p.start(round:r,timer:30,now:now,rng:&rng))
        XCTAssertTrue(p.start(round:r,timer:0,now:now,rng:&rng));XCTAssertFalse(p.start(round:r,timer:60,now:now,rng:&rng))
        // Only one open category remains. After the sampled 5–12 skips the offer
        // must fit it, rather than merely another already-filled category.
        for category in r.categories.dropLast() {p.placements[category.id]=category.playerIDs[0]}
        let open=r.categories.last!,threshold=p.helpThreshold
        for _ in 0..<threshold {XCTAssertTrue(p.skip(in:r,now:now,rng:&rng))}
        XCTAssertEqual(p.skipsSinceHelp,0);XCTAssertTrue(open.playerIDs.contains(p.currentPlayerID!));XCTAssertTrue(p.valid(for:r))
        let before=p.placements;XCTAssertFalse(p.place(category:r.categories[0].id,in:r,now:now,rng:&rng));XCTAssertEqual(p.placements,before)
        let wrong=try XCTUnwrap(r.players.first {!open.playerIDs.contains($0.id)})
        let helpful=p.currentPlayerID;p.currentPlayerID=wrong.id
        XCTAssertFalse(p.place(category:open.id,in:r,now:now,rng:&rng));XCTAssertEqual(p.mistakes.count,1)
        XCTAssertFalse(p.place(category:open.id,in:r,now:now,rng:&rng));XCTAssertEqual(p.mistakes.count,1);XCTAssertTrue(p.valid(for:r))
        p.currentPlayerID=helpful
        XCTAssertTrue(p.place(category:open.id,in:r,now:now,rng:&rng));XCTAssertEqual(p.status,.won)
    }
    func testRepeatedLegendIsPermittedAndOnlyFullBoardWinsOnce() throws {
        let r=try round();var p=BingoRetroProgress(round:r),rng=Seeded();XCTAssertTrue(p.start(round:r,timer:0,now:now,rng:&rng))
        let ibra="daily-bingo-retro-1",matches=r.categories.filter {$0.playerIDs.contains(ibra)};XCTAssertGreaterThan(matches.count,1)
        for category in matches {p.currentPlayerID=ibra;XCTAssertTrue(p.place(category:category.id,in:r,now:now,rng:&rng))}
        XCTAssertTrue(p.valid(for:r));XCTAssertEqual(p.status,.playing)
        for category in r.categories where p.placements[category.id] == nil {p.currentPlayerID=category.playerIDs[0];XCTAssertTrue(p.place(category:category.id,in:r,now:now,rng:&rng))}
        XCTAssertEqual(p.status,.won);XCTAssertTrue(p.valid(for:r));XCTAssertFalse(p.skip(in:r,now:now,rng:&rng))
        var state=LearnerState();XCTAssertTrue(state.completeGame(id:p.sessionID,kind:"bingo-retro",count:12,now:now));XCTAssertFalse(state.completeGame(id:p.sessionID,kind:"bingo-retro",count:12,now:now))
    }
    func testTimersExpireAtDeadlineBeforeAcceptingAPlacementAndUntimedDoesNot() throws {
        let r=try round();var rng=Seeded()
        for timer in [60,90] {
            var p=BingoRetroProgress(round:r);XCTAssertTrue(p.start(round:r,timer:timer,now:now,rng:&rng));XCTAssertEqual(p.remaining(at:now),timer)
            XCTAssertEqual(p.remaining(at:now.addingTimeInterval(Double(timer)-0.1)),1);XCTAssertFalse(p.expire(at:now.addingTimeInterval(Double(timer)-0.1)))
            let c=r.categories[0];p.currentPlayerID=c.playerIDs[0]
            XCTAssertFalse(p.place(category:c.id,in:r,now:now.addingTimeInterval(Double(timer)),rng:&rng));XCTAssertEqual(p.status,.lost);XCTAssertTrue(p.placements.isEmpty);XCTAssertEqual(p.remaining(at:now.addingTimeInterval(1000)),0);XCTAssertTrue(p.valid(for:r))
        }
        var untimed=BingoRetroProgress(round:r);XCTAssertTrue(untimed.start(round:r,timer:0,now:now,rng:&rng));XCTAssertNil(untimed.remaining(at:now));XCTAssertFalse(untimed.expire(at:now.addingTimeInterval(10000)))
    }
    func testSaveRestoreAndInvalidProgressAreRejected() throws {
        let r=try round();var p=BingoRetroProgress(round:r),rng=Seeded();XCTAssertTrue(p.start(round:r,timer:90,now:now,rng:&rng));XCTAssertTrue(p.skip(in:r,now:now,rng:&rng))
        let c=r.categories[0];p.currentPlayerID=c.playerIDs[0];XCTAssertTrue(p.place(category:c.id,in:r,now:now,rng:&rng))
        let dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer {try? FileManager.default.removeItem(at:dir)};let cache=DailyChallengeCache(directory:dir);try cache.save(p,for:r)
        var saved=try XCTUnwrap(cache.progress(for:r));XCTAssertEqual(saved.sessionID,p.sessionID);XCTAssertEqual(saved.deadline,p.deadline);XCTAssertEqual(saved.placements,p.placements);XCTAssertEqual(saved.currentPlayerID,p.currentPlayerID)
        saved.reviewRecorded=true;XCTAssertFalse(saved.valid(for:r));XCTAssertThrowsError(try cache.save(saved,for:r))
        saved=p;saved.placements[c.id]="daily-general-1";XCTAssertFalse(saved.valid(for:r));saved=p;saved.skipsSinceHelp=saved.helpThreshold;XCTAssertFalse(saved.valid(for:r))
        saved=p;saved.status = .won;XCTAssertFalse(saved.valid(for:r));saved=p;saved.deadline=Date(timeIntervalSince1970:.infinity);XCTAssertFalse(saved.valid(for:r))
        saved=p;XCTAssertTrue(saved.expire(at:now.addingTimeInterval(91)));saved.reviewRecorded=true;try cache.save(saved,for:r);XCTAssertEqual(cache.progress(for:r)?.status,.lost)
    }
    func testForgedCatalogBoardAndMembershipFailWhileOlderPacksLoad() throws {
        let original=try JSONSerialization.jsonObject(with:data()) as! [String:Any]
        func changed(_ mutation:(inout [String:Any])->Void) throws -> Data {var root=original;var games=root["games"] as! [[String:Any]],i=games.firstIndex {$0["id"] as? String == "bingo-retro"}!,selection=games[i]["selection"] as! [String:Any];mutation(&selection);games[i]["selection"]=selection;root["games"]=games;return try JSONSerialization.data(withJSONObject:root)}
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["boardDate"]="2026-10-08";s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var groups=s["groups"] as! [[String:Any]];groups[0]["name"]="Forged";s["groups"]=groups}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var groups=s["groups"] as! [[String:Any]];groups[0]=groups[1];s["groups"]=groups}))
        let old=try DailyChallengePack.load(changed {$0.removeValue(forKey:"catalog")});XCTAssertNil(old.bingoRetro);XCTAssertEqual(old.supportedModeIDs.count,10)
    }
}
