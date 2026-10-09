import XCTest
@testable import FoxlingoCore

final class DailyChallengeTests: XCTestCase {
    private func data() throws -> Data {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/daily-en.json"))
    }
    private func changed(_ edit: (inout [String:Any]) -> Void) throws -> Data {
        var root=try JSONSerialization.jsonObject(with:data()) as! [String:Any];edit(&root)
        return try JSONSerialization.data(withJSONObject:root)
    }
    func testSourceRankingsFlagsAndNamespace() throws {
        let pack=try DailyChallengePack.load(data())
        XCTAssertEqual(pack.top10.title,"Chelsea 2023/24 - Most matches")
        XCTAssertEqual(pack.top10.rankedPlayers.count,10)
        XCTAssertEqual(pack.top10.rankedPlayers[0].id,"daily-general-919")
        XCTAssertEqual(pack.top10.rankedPlayers[0].name,"Conor Gallagher")
        XCTAssertTrue(pack.top10.flags.allSatisfy {$0.hasPrefix("https://futbol11.com/media/flags/")})
        XCTAssertEqual(pack.top10.players.count,3492)
        XCTAssertTrue(pack.isToday(ISO8601DateFormatter().date(from:"2026-10-10T05:59:00Z")!))
        XCTAssertFalse(pack.isToday(ISO8601DateFormatter().date(from:"2026-10-10T06:01:00Z")!))
    }
    func testIncompleteCatalogChangedAnswerAndInvalidDateRejected() throws {
        XCTAssertThrowsError(try DailyChallengePack.load(changed {$0["gameDate"]="2026-02-30"}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {$0["timeZone"]="Invalid/Zone"}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {
            var games=$0["games"] as! [[String:Any]];games.removeLast();$0["games"]=games
        }))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {
            var games=$0["games"] as! [[String:Any]];let i=games.firstIndex {$0["id"] as? String == "top10"}!
            var selection=games[i]["selection"] as! [String:Any];var record=selection["record"] as! [String:Any]
            record["players"]="1,2,3,4,5,6,7,8,9,10";selection["record"]=record;games[i]["selection"]=selection;$0["games"]=games
        }))
    }
    func testCacheKeepsLastGoodOnFailedInstallAndSurvivesCorruptCache() throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        let cache=DailyChallengeCache(directory:directory),raw=try data(),pack=try cache.install(raw)
        XCTAssertThrowsError(try cache.install(Data("{}".utf8)))
        XCTAssertEqual(try cache.load(bundled:Data()).digest,pack.digest)
        try Data("broken".utf8).write(to:directory.appendingPathComponent("daily.json"))
        XCTAssertEqual(try cache.load(bundled:raw).digest,pack.digest)
    }
    func testGuessesCompletionIdempotencyHelpAndResume() throws {
        let pack=try DailyChallengePack.load(data()),round=pack.top10
        var progress=Top10Progress(signature:round.signature)
        XCTAssertFalse(progress.guess("player-919",in:round))
        let wrong=try XCTUnwrap(round.players.first {round.rank(of:$0.id) == nil})
        XCTAssertFalse(progress.guess(wrong.id,in:round))
        XCTAssertTrue(progress.guess(round.rankedPlayers[0].id,in:round,helped:true))
        XCTAssertFalse(progress.guess(round.rankedPlayers[0].id,in:round))
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        let cache=DailyChallengeCache(directory:directory)
        try cache.save(progress,for:round)
        progress=try XCTUnwrap(cache.progress(for:round))
        XCTAssertEqual(progress.assisted,Set([round.rankedPlayers[0].id]))
        for player in round.rankedPlayers.dropFirst() {XCTAssertTrue(progress.guess(player.id,in:round))}
        XCTAssertTrue(progress.finished)
        var state=LearnerState()
        XCTAssertTrue(state.completeGame(id:progress.sessionID,kind:"top10",count:10,now:Date()))
        XCTAssertFalse(state.completeGame(id:progress.sessionID,kind:"top10",count:10,now:Date()))
        try cache.save(progress,for:round);XCTAssertTrue(cache.progress(for:round)!.finished)
        progress.found.append(progress.found[0]);XCTAssertFalse(progress.valid(for:round))
        XCTAssertThrowsError(try cache.save(progress,for:round))
        XCTAssertFalse(Top10Progress(signature:"other date").valid(for:round))
    }
    func testPointerChecksDigestDateAndRelativeSafeFile() throws {
        let raw=try data(),digest=ContentUpdateRules.digest(raw)
        func pointer(file: String? = nil,date: String = "2026-10-09",zone: String = "America/Mexico_City",hash: String? = nil) throws -> DailyChallengePointer {
            try JSONDecoder().decode(DailyChallengePointer.self,from:JSONSerialization.data(withJSONObject:["file":file ?? "2026-10-09-\(digest.prefix(12)).json","sha256":hash ?? digest,"gameDate":date,"timeZone":zone,"modes":19]))
        }
        let value=try pointer(),base=URL(string:"https://example.com/daily/latest.json")!
        XCTAssertEqual(try value.contentURL(relativeTo:base).host,"example.com")
        XCTAssertEqual(try value.verify(raw).digest,digest)
        XCTAssertThrowsError(try value.verify(Data("bad".utf8)))
        XCTAssertThrowsError(try pointer(file:"../escape.json").contentURL(relativeTo:base))
        XCTAssertThrowsError(try pointer(date:"2026-10-10").verify(raw))
        XCTAssertThrowsError(try pointer(zone:"Europe/Madrid").verify(raw))
        XCTAssertThrowsError(try pointer(hash:String(repeating:"0",count:64)).verify(raw))
    }
}
