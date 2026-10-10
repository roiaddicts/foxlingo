import XCTest
@testable import FoxlingoCore

final class DailyBingoTests:XCTestCase {
    let now=Date(timeIntervalSince1970:1_800_000_000)
    func data() throws -> Data {try Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("ref/futbol11-daily/2026-10-10-b9670b05ffc0.json"))}
    func round() throws -> DailyBingo {try XCTUnwrap(DailyChallengePack.load(data()).bingo)}
    struct RNG:RandomNumberGenerator {var n:UInt64=77;mutating func next()->UInt64 {n=n &* 6364136223846793005 &+ 1442695040888963407;return n}}
    func testSourceBoardCatalogAndBingoOnlyMemberships() throws {
        let bytes=try data(),pack=try DailyChallengePack.load(bytes),r=try XCTUnwrap(pack.bingo),root=try JSONSerialization.jsonObject(with:bytes) as! [String:Any]
        XCTAssertEqual(pack.supportedModeIDs.count,12);XCTAssertEqual(r.categories.count,12);XCTAssertEqual(r.helpRange,2...5)
        let rows=(root["datasets"] as! [[String:Any]]).first {Set($0["fields"] as! [String]) == ["bingo","countryID","firstName","grid","id","image","lastName","nickname"]}!["data"] as! [[String:Any]]
        let expected=rows.filter {!(($0["bingo"] as? String) ?? "").isEmpty}
        XCTAssertEqual(Set(r.players.map(\.id)),Set(expected.map {"daily-general-\($0["id"] as! Int)"}))
        for c in r.categories {
            let id=Int(c.id.split(separator:"-").last!)!
            XCTAssertEqual(Set(c.playerIDs),Set(expected.filter {($0["bingo"] as! String).split(separator:",").compactMap {Int($0.trimmingCharacters(in:.whitespaces))}.contains(id)}.map {"daily-general-\($0["id"] as! Int)"}))
            XCTAssertFalse(c.playerIDs.isEmpty);XCTAssertNotNil(c.imageURL)
        }
        XCTAssertTrue(r.players.allSatisfy {$0.id.hasPrefix("daily-general-")})
    }
    func testHelpfulOffersWrongPairRecoveryReuseAndSingleCredit() throws {
        let r=try round();var p=BingoRetroProgress(round:r),rng=RNG()
        XCTAssertTrue(p.valid(for:r));XCTAssertTrue(p.start(round:r,timer:0,now:now,rng:&rng));XCTAssertTrue((2...5).contains(p.helpThreshold))
        let category=r.categories[0],wrong=r.players.first {!r.accepts($0.id,category:category.id)}!
        p.currentPlayerID=wrong.id;XCTAssertFalse(p.place(category:category.id,in:r,now:now,rng:&rng));XCTAssertEqual(p.currentPlayerID,wrong.id);XCTAssertTrue(p.placements.isEmpty);XCTAssertEqual(p.mistakes.count,1)
        XCTAssertFalse(p.place(category:category.id,in:r,now:now,rng:&rng));XCTAssertEqual(p.mistakes.count,1)
        p.helpThreshold=2;p.skipsSinceHelp=1;XCTAssertTrue(p.skip(in:r,now:now,rng:&rng));XCTAssertTrue(r.categories.contains {r.accepts(p.currentPlayerID!,category:$0.id)});XCTAssertEqual(p.skipsSinceHelp,0)
        let reused=r.players.first {player in r.categories.filter {r.accepts(player.id,category:$0.id)}.count > 1}!
        let matches=r.categories.filter {r.accepts(reused.id,category:$0.id)}
        for c in matches {p.currentPlayerID=reused.id;XCTAssertTrue(p.place(category:c.id,in:r,now:now,rng:&rng));XCTAssertEqual(p.skipsSinceHelp,0)}
        for c in r.categories where p.placements[c.id] == nil {p.currentPlayerID=c.playerIDs[0];XCTAssertTrue(p.place(category:c.id,in:r,now:now,rng:&rng))}
        XCTAssertEqual(p.status,.won);XCTAssertTrue(p.valid(for:r));XCTAssertFalse(p.skip(in:r,now:now,rng:&rng))
        var state=LearnerState();XCTAssertTrue(state.completeGame(id:p.sessionID,kind:r.kind,count:12,now:now));XCTAssertFalse(state.completeGame(id:p.sessionID,kind:r.kind,count:12,now:now))
    }
    func testHelpfulThresholdFitsOnlyRemainingSquares() throws {
        let r=try round();var rng=RNG()
        for threshold in 2...5 {
            var p=BingoRetroProgress(round:r);XCTAssertTrue(p.start(round:r,timer:0,now:now,rng:&rng))
            let last=r.categories.last!;for c in r.categories.dropLast() {p.placements[c.id]=c.playerIDs[0]}
            p.helpThreshold=threshold;p.skipsSinceHelp=threshold-1
            XCTAssertTrue(p.skip(in:r,now:now,rng:&rng));XCTAssertTrue(last.playerIDs.contains(p.currentPlayerID!));XCTAssertEqual(p.skipsSinceHelp,0);XCTAssertTrue(p.valid(for:r))
        }
    }
    func testSavedRoundsTimersAndCacheSeparation() throws {
        let r=try round(),retro=try XCTUnwrap(DailyChallengePack.load(data()).bingoRetro),dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer {try? FileManager.default.removeItem(at:dir)}
        let cache=DailyChallengeCache(directory:dir);var rng=RNG(),p=BingoRetroProgress(round:r);XCTAssertTrue(p.start(round:r,timer:60,now:now,rng:&rng));XCTAssertTrue(p.skip(in:r,now:now,rng:&rng));try cache.save(p,for:r)
        let saved=try XCTUnwrap(cache.progress(for:r));XCTAssertEqual(saved.currentPlayerID,p.currentPlayerID);XCTAssertEqual(saved.helpThreshold,p.helpThreshold);XCTAssertEqual(saved.deadline,p.deadline);XCTAssertEqual(saved.sessionID,p.sessionID);XCTAssertNil(cache.progress(for:retro))
        var expired=saved;let c=r.categories[0];expired.currentPlayerID=c.playerIDs[0];XCTAssertFalse(expired.place(category:c.id,in:r,now:now.addingTimeInterval(60),rng:&rng));XCTAssertEqual(expired.status,.lost);XCTAssertTrue(expired.placements.isEmpty);try cache.save(expired,for:r)
        for timer in [0,90] {var p=BingoRetroProgress(round:r);XCTAssertTrue(p.start(round:r,timer:timer,now:now,rng:&rng));XCTAssertEqual(p.expire(at:now.addingTimeInterval(91)),timer != 0)}
        var bad=p;bad.helpThreshold=12;XCTAssertThrowsError(try cache.save(bad,for:r));bad=p;bad.currentPlayerID="daily-bingo-retro-1";XCTAssertFalse(bad.valid(for:r));bad=p;bad.reviewRecorded=true;XCTAssertFalse(bad.valid(for:r))
    }
    func testForgedBoardsBindingsAndOldPacketCompatibility() throws {
        let original=try JSONSerialization.jsonObject(with:data()) as! [String:Any]
        func changed(_ mutation:(inout [String:Any])->Void) throws -> Data {var root=original;var games=root["games"] as! [[String:Any]],i=games.firstIndex {$0["id"] as? String == "bingo"}!,s=games[i]["selection"] as! [String:Any];mutation(&s);games[i]["selection"]=s;root["games"]=games;return try JSONSerialization.data(withJSONObject:root)}
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["boardDate"]="2026-10-09";s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["playerSourceURL"]=c["categorySourceURL"];s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var groups=s["groups"] as! [[String:Any]];groups[0]["name"]="Forged";s["groups"]=groups}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var groups=s["groups"] as! [[String:Any]];groups[0]=groups[1];s["groups"]=groups}))
        let old=try DailyChallengePack.load(changed {$0.removeValue(forKey:"catalog")});XCTAssertNil(old.bingo);XCTAssertEqual(old.supportedModeIDs.count,11)
    }
}
