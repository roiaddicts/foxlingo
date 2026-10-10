import XCTest
@testable import FoxlingoCore

final class DailyRevealTests: XCTestCase {
    private func data() throws -> Data {
        try Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("ref/futbol11-daily/2026-10-09-d72036ad4a75.json"))
    }
    private func removeNewSupport(_ root: inout [String:Any]) {
        root.removeValue(forKey:"support")
        var gridModes=root["games"] as! [[String:Any]];let gridIndex=gridModes.firstIndex {$0["id"] as? String == "grid"}!
        var grid=gridModes[gridIndex]["selection"] as! [String:Any];grid.removeValue(forKey:"catalog");gridModes[gridIndex]["selection"]=grid;root["games"]=gridModes
        var wordleModes=root["games"] as! [[String:Any]];let wordleIndex=wordleModes.firstIndex {$0["id"] as? String == "wordle"}!
        var wordle=wordleModes[wordleIndex]["selection"] as! [String:Any];wordle.removeValue(forKey:"catalog");wordleModes[wordleIndex]["selection"]=wordle;root["games"]=wordleModes
        var retroModes=root["games"] as! [[String:Any]];let retroIndex=retroModes.firstIndex {$0["id"] as? String == "bingo-retro"}!
        var retro=retroModes[retroIndex]["selection"] as! [String:Any];retro.removeValue(forKey:"catalog");retroModes[retroIndex]["selection"]=retro;root["games"]=retroModes
        var modes=root["games"] as! [[String:Any]];let similarityIndex=modes.firstIndex {$0["id"] as? String == "goltexto"}!
        var similarity=modes[similarityIndex]["selection"] as! [String:Any];similarity.removeValue(forKey:"catalog");modes[similarityIndex]["selection"]=similarity;root["games"]=modes
        var games=root["games"] as! [[String:Any]],i=games.firstIndex {$0["id"] as? String == "squadslice"}!
        let mysteryIndex=games.firstIndex {$0["id"] as? String == "guesswho"}!
        var mystery=games[mysteryIndex]["selection"] as! [String:Any];mystery.removeValue(forKey:"catalog");games[mysteryIndex]["selection"]=mystery
        var selection=games[i]["selection"] as! [String:Any]
        for key in ["slices","revealOrder","omittedPlayerIDs"] {selection.removeValue(forKey:key)}
        games[i]["selection"]=selection;root["games"]=games
    }
    private func pack() throws -> DailyChallengePack {try DailyChallengePack.load(data())}
    func testSourceAnswersClubsAndHistoricalSeasonStats() throws {
        let pack=try pack();XCTAssertEqual(pack.revealRounds.count,3)
        let legacy=try XCTUnwrap(pack.revealRounds.first {$0.mode == .legacy})
        XCTAssertEqual(legacy.answer.name,"Savinho");XCTAssertEqual(legacy.answer.id,"daily-general-820")
        XCTAssertEqual(legacy.clues.map(\.value),["PSV","Man City","Atletico Mineiro","Girona"])
        XCTAssertTrue(legacy.clues.allSatisfy {$0.imageURL?.contains("/media/shirts/") == true})
        let link=try XCTUnwrap(pack.revealRounds.first {$0.mode == .link})
        XCTAssertEqual(link.answer.name,"Pedro Rodriguez");XCTAssertEqual(link.answer.id,"daily-general-282")
        XCTAssertEqual(link.clues.map(\.value),["Luis Alberto","Javier Mascherano","Henrikh Mkhitaryan","Sergio Ramos","John Terry"])
        let stat=try XCTUnwrap(pack.revealRounds.first {$0.mode == .statdle})
        XCTAssertEqual(stat.answer.name,"Wayne Rooney")
        let values=Dictionary(uniqueKeysWithValues:stat.clues.map {($0.id,$0.value)})
        XCTAssertEqual(values["season"],"Premier League");XCTAssertEqual(stat.clues[0].title,"2005/06")
        XCTAssertEqual(values["apps"],"36");XCTAssertEqual(values["goals"],"16");XCTAssertEqual(values["assists"],"9")
        XCTAssertEqual(values["age"],"19");XCTAssertEqual(values["value"],"€36M")
        XCTAssertEqual(values["club"],"Man Utd");XCTAssertEqual(values["country"],"England")
    }
    func testRevealRatesFinalChanceAndWinningLocksEveryMode() throws {
        for round in try pack().revealRounds {
            var p=DailyRevealProgress(round:round,randomized:false)
            XCTAssertTrue(p.valid(for:round));XCTAssertEqual(p.revealed(round).count,1)
            for miss in 1..<round.mode.limit {
                XCTAssertTrue(p.submit(nil,in:round))
                XCTAssertEqual(p.revealed(round).count,min(round.clues.count,1+miss*round.mode.revealStep))
                XCTAssertEqual(p.outcome(round),.playing)
            }
            XCTAssertTrue(p.submit(round.answer.id,in:round));XCTAssertEqual(p.outcome(round),.won)
            XCTAssertTrue(p.valid(for:round));XCTAssertFalse(p.submit(nil,in:round))
            var state=LearnerState()
            XCTAssertTrue(state.completeGame(id:p.sessionID,kind:round.mode.rawValue,count:p.attempts.count,now:Date()))
            XCTAssertFalse(state.completeGame(id:p.sessionID,kind:round.mode.rawValue,count:p.attempts.count,now:Date()))
        }
    }
    func testLossWrongDuplicateAndForeignNamespaceCannotWin() throws {
        for round in try pack().revealRounds {
            var p=DailyRevealProgress(round:round,randomized:false)
            XCTAssertFalse(p.submit("draft-clubs-player-63",in:round))
            let wrong=try XCTUnwrap(round.players.first {$0.id != round.answer.id})
            XCTAssertTrue(p.submit(wrong.id,in:round));XCTAssertEqual(p.outcome(round),.playing)
            XCTAssertFalse(p.submit(wrong.id,in:round))
            for _ in 1..<round.mode.limit {XCTAssertTrue(p.submit(nil,in:round))}
            XCTAssertEqual(p.outcome(round),.lost);XCTAssertTrue(p.valid(for:round));XCTAssertFalse(p.submit(round.answer.id,in:round))
        }
    }
    func testHardStatdleRandomOrderPersistenceAndMixedRoundsRejected() throws {
        let rounds=try pack().revealRounds,stat=try XCTUnwrap(rounds.first {$0.mode == .statdle}),legacy=try XCTUnwrap(rounds.first {$0.mode == .legacy})
        var p=DailyRevealProgress(round:stat,difficulty:.hard)
        XCTAssertTrue(p.valid(for:stat));XCTAssertEqual(p.order.count,7);XCTAssertEqual(p.order.first,"season")
        XCTAssertFalse(p.order.contains("club"));XCTAssertFalse(p.order.contains("country"))
        for _ in 0..<3 {XCTAssertTrue(p.submit(nil,in:stat))}
        XCTAssertEqual(p.revealed(stat).count,7);XCTAssertEqual(p.outcome(stat),.playing)
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        let cache=DailyChallengeCache(directory:directory)
        try cache.save(p,for:stat)
        let restored=try XCTUnwrap(cache.progress(for:stat))
        XCTAssertEqual(restored.order,p.order);XCTAssertEqual(restored.sessionID,p.sessionID);XCTAssertEqual(restored.attempts.count,3)
        XCTAssertNil(cache.progress(for:legacy));XCTAssertFalse(restored.valid(for:legacy))
        p.reviewRecorded=true;XCTAssertFalse(p.valid(for:stat));XCTAssertThrowsError(try cache.save(p,for:stat))
    }
    func testChangedSourceAndInvalidProgressFailWithoutReplacingCache() throws {
        let original=try data(),pack=try DailyChallengePack.load(original)
        var root=try JSONSerialization.jsonObject(with:original) as! [String:Any]
        var games=root["games"] as! [[String:Any]],i=games.firstIndex {$0["id"] as? String == "link"}!
        var selection=games[i]["selection"] as! [String:Any];selection["clueOrder"]=[1,2,3,4,5];games[i]["selection"]=selection;root["games"]=games
        let invalid=try JSONSerialization.data(withJSONObject:root)
        XCTAssertThrowsError(try DailyChallengePack.load(invalid))
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        let cache=DailyChallengeCache(directory:directory);_ = try cache.install(original)
        XCTAssertThrowsError(try cache.install(invalid));XCTAssertEqual(try cache.load(bundled:Data()).digest,pack.digest)
        let round=pack.revealRounds[0]
        var p=DailyRevealProgress(round:round,randomized:false)
        p.attempts=[RevealAttempt(playerID:round.answer.id),RevealAttempt(playerID:nil)]
        XCTAssertFalse(p.valid(for:round))
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(p)) as! [String:Any]
        json["attempts"]=[];json["order"]=["season","season"]
        XCTAssertFalse(try JSONDecoder().decode(DailyRevealProgress.self,from:JSONSerialization.data(withJSONObject:json)).valid(for:round))
    }
    func testAppUpdatePrefersNewerBundledCapabilitiesOverOlderSameDayCache() throws {
        let bundled=try data();var root=try JSONSerialization.jsonObject(with:bundled) as! [String:Any]
        removeNewSupport(&root);let old=try JSONSerialization.data(withJSONObject:root)
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:directory)}
        let cache=DailyChallengeCache(directory:directory);_ = try cache.install(old)
        XCTAssertEqual(try cache.load(bundled:bundled).revealRounds.count,3)
        func redate(_ date: String,_ index: Int) throws {
            root["gameDate"]=date;root["dayOfYear"]=index;root["elapsedDayFloor"]=index
            var games=root["games"] as! [[String:Any]];let i=games.firstIndex {$0["id"] as? String == "top10"}!
            let url=games[i]["sourceModule"] as! String,datasets=root["datasets"] as! [[String:Any]]
            let rows=datasets.first {$0["sourceURL"] as? String == url}!["data"] as! [[String:Any]]
            var selection=games[i]["selection"] as! [String:Any];selection["index"]=index;selection["record"]=rows[index];games[i]["selection"]=selection
            let rankIndex=games.firstIndex {$0["id"] as? String == "pyramid"}!,rankURL=games[rankIndex]["sourceModule"] as! String
            let rankRows=datasets.first {$0["sourceURL"] as? String == rankURL}!["data"] as! [[String:Any]]
            var rankSelection=games[rankIndex]["selection"] as! [String:Any];rankSelection["index"]=index;rankSelection["record"]=rankRows[index]
            var values=Set<Int>(),selected:[[String:Int]]=[]
            for pair in (rankRows[index]["players"] as! String).split(separator:".") {
                let parts=pair.split(separator:",").map {Int($0)!}
                if values.insert(parts[1]).inserted {selected.append(["playerID":parts[0],"value":parts[1]])}
            }
            rankSelection["players"]=Array(selected.prefix(10));games[rankIndex]["selection"]=rankSelection
            let squadIndex=games.firstIndex {$0["id"] as? String == "squadslice"}!,squadURL=games[squadIndex]["sourceModule"] as! String
            let squadRows=datasets.first {$0["sourceURL"] as? String == squadURL}!["data"] as! [[String:Any]]
            var squadSelection=games[squadIndex]["selection"] as! [String:Any];squadSelection["index"]=index;squadSelection["record"]=squadRows[index];games[squadIndex]["selection"]=squadSelection;root["games"]=games
            _ = try cache.install(JSONSerialization.data(withJSONObject:root))
        }
        try redate("2026-10-08",281)
        XCTAssertEqual(try cache.load(bundled:bundled).gameDate,"2026-10-09")
        try redate("2026-10-10",283)
        XCTAssertEqual(try cache.load(bundled:bundled).gameDate,"2026-10-10")
    }
    func testOlderTop10OnlyPackagesStillLoadWithoutInventingOtherModes() throws {
        var root=try JSONSerialization.jsonObject(with:data()) as! [String:Any];removeNewSupport(&root)
        let pack=try DailyChallengePack.load(JSONSerialization.data(withJSONObject:root))
        XCTAssertTrue(pack.revealRounds.isEmpty);XCTAssertEqual(pack.top10.rankedPlayers.count,10)
    }
}
