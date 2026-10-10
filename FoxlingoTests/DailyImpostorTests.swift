import XCTest
@testable import FoxlingoCore

final class DailyImpostorTests:XCTestCase {
    func data() throws -> Data {try Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("ref/futbol11-daily/2026-10-10-ce0e2fed5287.json"))}
    func round() throws -> DailyImpostor {try XCTUnwrap(DailyChallengePack.load(data()).impostor)}
    struct RNG:RandomNumberGenerator {var n:UInt64=71;mutating func next()->UInt64 {n=n &* 6364136223846793005 &+ 1442695040888963407;return n}}
    func testSourceRecordNormalAndOneByOnePools() throws {
        let r=try round();XCTAssertEqual(try DailyChallengePack.load(data()).supportedModeIDs.count,14);XCTAssertEqual(r.title,"Played for Athletic Club")
        XCTAssertEqual(r.correct,[760,129,370,1029].map {"daily-general-\($0)"});XCTAssertEqual(r.extra,["daily-general-113"]);XCTAssertEqual(r.player("daily-general-113")?.name,"Kepa Arrizabalaga");XCTAssertEqual(r.sourceExtra,r.extra);XCTAssertTrue(r.reviews.isEmpty);XCTAssertEqual(r.positives(.hard),r.correct+r.extra)
        XCTAssertEqual(r.outsiders(.hard),Array(r.impostors.dropLast()));XCTAssertFalse(r.pool(.hard).contains(r.impostors.last!));XCTAssertFalse(r.pool(.normal).contains(r.extra[0]))
        for level in ImpostorLevel.allCases {XCTAssertEqual(Set(r.pool(level)).count,10);XCTAssertTrue(r.pool(level).allSatisfy {r.player($0)?.imageURL != nil})}
    }
    func testBothExactWinPathsSelectionLockAndSingleCredit() throws {
        let r=try round();var rng=RNG()
        for level in ImpostorLevel.allCases {
            var p=ImpostorProgress(round:r);XCTAssertTrue(p.start(in:r,level:level,rng:&rng));XCTAssertFalse(p.start(in:r,level:.normal,rng:&rng));XCTAssertEqual(Set(p.order),Set(r.pool(level)));p.select("daily-bingo-retro-1");XCTAssertTrue(p.selected.isEmpty)
            for id in r.positives(level) {p.select(id);if level == .hard {XCTAssertEqual(p.check(in:r),true);p.select(id);XCTAssertTrue(p.selected.isEmpty)}}
            if level == .normal {XCTAssertEqual(p.check(in:r),true)}
            XCTAssertEqual(p.status,.won);XCTAssertEqual(p.found,r.positives(level).count);XCTAssertTrue(p.valid(for:r));XCTAssertNil(p.check(in:r));XCTAssertFalse(p.reveal(in:r))
            var state=LearnerState();XCTAssertTrue(state.completeGame(id:p.sessionID,kind:"impostor",count:p.found,now:Date()));XCTAssertFalse(state.completeGame(id:p.sessionID,kind:"impostor",count:p.found,now:Date()))
        }
    }
    func testNormalMissesWrongSelectionsAndEmptySubmissionAreTerminal() throws {
        let r=try round();var rng=RNG()
        for selection in [Array(r.correct.dropLast()),r.correct+[r.impostors[0]],[]] {
            var p=ImpostorProgress(round:r);XCTAssertTrue(p.start(in:r,level:.normal,rng:&rng));for id in selection {p.select(id)}
            XCTAssertEqual(p.check(in:r),false);XCTAssertEqual(p.status,.lost);XCTAssertTrue(p.revealed);XCTAssertTrue(p.selected.isEmpty);XCTAssertEqual(p.checks,1)
            XCTAssertEqual(p.found,Set(selection).intersection(r.correct).count);XCTAssertEqual(p.marks.values.filter {$0 == .missed}.count,Set(r.correct).subtracting(selection).count);XCTAssertEqual(p.marks.values.filter {$0 == .wrong}.count,Set(selection).intersection(r.impostors).count);XCTAssertTrue(p.valid(for:r));XCTAssertNil(p.check(in:r))
        }
    }
    func testOneByOneFirstErrorSavedSelectionRevealAndCacheIntegrity() throws {
        let r=try round(),dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer {try? FileManager.default.removeItem(at:dir)};let cache=DailyChallengeCache(directory:dir);var rng=RNG(),p=ImpostorProgress(round:r)
        p.level = .hard;try cache.save(p,for:r);XCTAssertEqual(cache.progress(for:r)?.level,.hard);XCTAssertTrue(p.start(in:r,level:.hard,rng:&rng));XCTAssertNil(p.check(in:r))
        p.select(r.correct[0]);p.select(r.extra[0]);XCTAssertEqual(p.selected,[r.extra[0]]);try cache.save(p,for:r)
        let saved=try XCTUnwrap(cache.progress(for:r));XCTAssertEqual(saved.order,p.order);XCTAssertEqual(saved.selected,p.selected);XCTAssertEqual(saved.sessionID,p.sessionID)
        XCTAssertEqual(p.check(in:r),true);p.select(r.outsiders(.hard)[0]);XCTAssertEqual(p.check(in:r),false);XCTAssertEqual(p.status,.lost);XCTAssertEqual(p.checks,2);XCTAssertFalse(p.revealed);XCTAssertEqual(p.marks.values.filter {$0 == .missed}.count,0);XCTAssertTrue(p.valid(for:r));try cache.save(p,for:r);XCTAssertEqual(cache.progress(for:r)?.status,.lost)
        XCTAssertTrue(p.reveal(in:r));XCTAssertEqual(p.marks.values.filter {$0 == .missed}.count,4);p.reviewRecorded=true;p.revealReviewRecorded=true;XCTAssertTrue(p.valid(for:r));try cache.save(p,for:r);XCTAssertTrue(cache.progress(for:r)!.revealed)
        var bad=p;bad.marks[r.correct[0]] = .wrong;XCTAssertFalse(bad.valid(for:r));bad=p;bad.order[0]=bad.order[1];XCTAssertThrowsError(try cache.save(bad,for:r));bad=p;bad.checks=Int.max;XCTAssertFalse(bad.valid(for:r));bad=saved;bad.reviewRecorded=true;XCTAssertFalse(bad.valid(for:r))
    }
    func testForgedDateIndexRecordBindingsAndSelectionsRejectWhileOldPacketsLoad() throws {
        let original=try JSONSerialization.jsonObject(with:data()) as! [String:Any]
        func changed(_ mutate:(inout [String:Any])->Void) throws -> Data {var root=original,games=root["games"] as! [[String:Any]],i=games.firstIndex {$0["id"] as? String == "impostor"}!,s=games[i]["selection"] as! [String:Any];mutate(&s);games[i]["selection"]=s;root["games"]=games;return try JSONSerialization.data(withJSONObject:root)}
        XCTAssertThrowsError(try DailyChallengePack.load(changed {$0["index"]=282}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var r=s["record"] as! [String:Any];r["title"]="Forged";s["record"]=r}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["playerSourceURL"]=c["recordSourceURL"];s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["boardDate"]="2026-10-09";s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {$0["extraCorrectPlayerIDs"]=[1]}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in
            let record=s["record"] as! [String:Any]
            s["reviews"]=[["id":UUID().uuidString,"game":"impostor","recordID":record["id"]!,"title":record["title"]!,"sourceCorrectPlayerIDs":s["correctPlayerIDs"]!,"sourceExtraCorrectPlayerIDs":s["extraCorrectPlayerIDs"]!,"sourceImpostorPlayerIDs":s["impostorPlayerIDs"]!,"removeExtraPlayerIDs":[113],"playerNames":["113":"Cesar Azpilicueta"],"note":"Wrong catalog identity","reviewedAt":"2026-10-10","sources":[["title":"Career record","url":"https://sevillafc.es/actualidad/noticias/cesar-azpilicueta-signs"]]]]
            s["playableExtraPlayerIDs"]=[]
        }))
        let old=try DailyChallengePack.load(changed {$0.removeValue(forKey:"catalog")});XCTAssertNil(old.impostor);XCTAssertEqual(old.supportedModeIDs.count,13)
    }
}
