import XCTest
@testable import FoxlingoCore

final class DailyGuessWhoTests:XCTestCase {
    private func data() throws -> Data {try Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("ref/futbol11-daily/2026-10-09-d72036ad4a75.json"))}
    private func round() throws -> DailyGuessWho {try XCTUnwrap(DailyChallengePack.load(data()).guessWho)}
    func testSourceIdentityCatalogCrosswalkAndPortrait() throws {
        let r=try round();XCTAssertEqual(r.answer.id,"daily-guesswho-91");XCTAssertEqual(r.answer.name,"Nick Pope");XCTAssertEqual(r.currentClub,4);XCTAssertEqual(r.country,5);XCTAssertEqual(r.height,198);XCTAssertEqual(r.age,34)
        XCTAssertEqual(r.clubs.count,48);XCTAssertEqual(r.leagues.count,8);XCTAssertEqual(r.players.count,2614)
        let general=try DailyChallengePack.load(data()).top10.players
        XCTAssertEqual(r.answer.imageURL,general.first {$0.id == "daily-general-548"}?.imageURL)
        XCTAssertEqual(r.players.first {$0.id == "daily-guesswho-1056"}?.imageURL,general.first {$0.id == "daily-general-2"}?.imageURL)
        XCTAssertEqual(r.players.first {$0.id == "daily-guesswho-1622"}?.imageURL,general.first {$0.id == "daily-general-1"}?.imageURL)
        XCTAssertNotEqual(r.answer.imageURL,general.first {$0.id == "daily-general-91"}?.imageURL)
        XCTAssertEqual(r.clubs.first {$0.id == 14}?.imageURL,"https://futbol11.com/media/shirts/9.png")
        XCTAssertEqual(r.clubs.first {$0.id == 24}?.imageURL,"https://futbol11.com/media/shirts/12.png")
        XCTAssertEqual(r.clubs.first {$0.id == 29}?.imageAsset,"entity-bayern-munich")
    }
    func testEveryQuestionTypeUsesScopedFactsAndStrictNumericComparison() throws {
        let r=try round()
        for q in [GuessWhoQuestion(.club,value:4),GuessWhoQuestion(.league,value:5),GuessWhoQuestion(.country,value:5),GuessWhoQuestion(.position,value:0),GuessWhoQuestion(.age,value:34),GuessWhoQuestion(.height,value:198),GuessWhoQuestion(.pastClub,value:4),GuessWhoQuestion(.pastLeague,value:5)] {XCTAssertTrue(r.valid(q));XCTAssertEqual(r.response(q),true)}
        for q in [GuessWhoQuestion(.club,value:1),GuessWhoQuestion(.league,value:7),GuessWhoQuestion(.country,value:7),GuessWhoQuestion(.position,value:3),GuessWhoQuestion(.age,value:34,comparison:.greater),GuessWhoQuestion(.height,value:198,comparison:.less),GuessWhoQuestion(.pastClub,value:14),GuessWhoQuestion(.pastLeague,value:7)] {XCTAssertEqual(r.response(q),false)}
        XCTAssertEqual(r.response(GuessWhoQuestion(.height,value:190,comparison:.greater)),true)
        XCTAssertEqual(r.response(GuessWhoQuestion(.age,value:35,comparison:.less)),true)
        XCTAssertFalse(r.valid(GuessWhoQuestion(.position,value:4)));XCTAssertFalse(r.valid(GuessWhoQuestion(.height,value:999)));XCTAssertFalse(r.valid(GuessWhoQuestion(.club,value:4,comparison:.greater)))
    }
    func testQuestionLimitDoesNotSpendGuessesAndFinalChanceWinCreditsOnce() throws {
        let r=try round();var p=GuessWhoProgress(round:r)
        for age in 20..<30 {XCTAssertTrue(p.ask(GuessWhoQuestion(.age,value:age),in:r))}
        XCTAssertFalse(p.ask(GuessWhoQuestion(.height,value:190),in:r));XCTAssertEqual(p.guesses.count,0);XCTAssertFalse(p.finished(r))
        XCTAssertFalse(p.guess("daily-general-91",in:r))
        let wrong=Array(r.players.filter {$0.id != r.answer.id}.prefix(2))
        XCTAssertTrue(p.guess(wrong[0].id,in:r));XCTAssertFalse(p.guess(wrong[0].id,in:r));XCTAssertTrue(p.guess(wrong[1].id,in:r))
        XCTAssertTrue(p.guess(r.answer.id,in:r));XCTAssertTrue(p.won(r));XCTAssertFalse(p.reveal(in:r));XCTAssertFalse(p.ask(GuessWhoQuestion(.club,value:4),in:r))
        var state=LearnerState();XCTAssertTrue(state.completeGame(id:p.sessionID,kind:"guesswho",count:13,now:Date()));XCTAssertFalse(state.completeGame(id:p.sessionID,kind:"guesswho",count:13,now:Date()))
    }
    func testLossRevealDuplicatesAndPersistentQuestionHistory() throws {
        let r=try round();var p=GuessWhoProgress(round:r)
        let question=GuessWhoQuestion(.height,value:190,comparison:.greater)
        XCTAssertTrue(p.ask(question,in:r));XCTAssertFalse(p.ask(question,in:r))
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer {try? FileManager.default.removeItem(at:directory)}
        let cache=DailyChallengeCache(directory:directory);try cache.save(p,for:r)
        let restored=try XCTUnwrap(cache.progress(for:r));XCTAssertEqual(restored.questions,p.questions);XCTAssertEqual(restored.sessionID,p.sessionID)
        for player in r.players.filter({$0.id != r.answer.id}).prefix(3) {XCTAssertTrue(p.guess(player.id,in:r))}
        XCTAssertTrue(p.finished(r));XCTAssertFalse(p.won(r));XCTAssertFalse(p.guess(r.answer.id,in:r));try cache.save(p,for:r);XCTAssertTrue(try XCTUnwrap(cache.progress(for:r)).finished(r))
        var reveal=GuessWhoProgress(round:r);XCTAssertTrue(reveal.reveal(in:r));XCTAssertFalse(reveal.won(r));XCTAssertFalse(reveal.guess(r.answer.id,in:r))
        reveal.reviewRecorded=true;XCTAssertTrue(reveal.valid(for:r));reveal.gaveUp=false;XCTAssertFalse(reveal.valid(for:r))
        p.guesses=[r.answer.id,r.players.first {$0.id != r.answer.id}!.id];XCTAssertFalse(p.valid(for:r));XCTAssertThrowsError(try cache.save(p,for:r))
    }
    func testPastClubsLeaguesMissingCurrentClubAndChangedSource() throws {
        var root=try JSONSerialization.jsonObject(with:data()) as! [String:Any]
        let general=try DailyChallengePack.load(data()).top10.players
        var games=root["games"] as! [[String:Any]],g=games.firstIndex {$0["id"] as? String == "guesswho"}!
        var selection=games[g]["selection"] as! [String:Any],record=selection["record"] as! [String:Any]
        record["previousClubs"]="14, 24";record["previousLeagues"]="4";selection["record"]=record;games[g]["selection"]=selection;root["games"]=games
        var datasets=root["datasets"] as! [[String:Any]],d=datasets.firstIndex {$0["sourceURL"] as? String == games[g]["sourceModule"] as? String}!,rows=datasets[d]["data"] as! [[String:Any]]
        rows[282]=record;datasets[d]["data"]=rows;root["datasets"]=datasets
        let r=try XCTUnwrap(DailyGuessWho.load(root:root,general:general));XCTAssertEqual(r.response(GuessWhoQuestion(.pastClub,value:24)),true);XCTAssertEqual(r.response(GuessWhoQuestion(.pastLeague,value:7)),true);XCTAssertEqual(r.response(GuessWhoQuestion(.pastLeague,value:10)),true);XCTAssertEqual(r.response(GuessWhoQuestion(.pastLeague,value:4)),true)
        let playerURL=(selection["catalog"] as! [String:Any])["playerSourceURL"] as! String
        let p=datasets.firstIndex {$0["sourceURL"] as? String == playerURL}!;var playerRows=datasets[p]["data"] as! [[String:Any]];let i=playerRows.firstIndex {$0["id"] as? Int == 91}!;playerRows[i].removeValue(forKey:"clubID");datasets[p]["data"]=playerRows;root["datasets"]=datasets
        let missing=try XCTUnwrap(DailyGuessWho.load(root:root,general:general));XCTAssertNil(missing.response(GuessWhoQuestion(.club,value:4)));XCTAssertNil(missing.response(GuessWhoQuestion(.league,value:5)));XCTAssertNotEqual(missing.signature,r.signature)
    }
    func testMalformedCrosswalkAndOldPackCompatibility() throws {
        var root=try JSONSerialization.jsonObject(with:data()) as! [String:Any],games=root["games"] as! [[String:Any]],i=games.firstIndex {$0["id"] as? String == "guesswho"}!
        var selection=games[i]["selection"] as! [String:Any],catalog=selection["catalog"] as! [String:Any],map=catalog["portraitPlayerIDs"] as! [String:Int];map["91"]=91;catalog["portraitPlayerIDs"]=map;selection["catalog"]=catalog;games[i]["selection"]=selection;root["games"]=games
        XCTAssertThrowsError(try DailyChallengePack.load(JSONSerialization.data(withJSONObject:root)))
        selection.removeValue(forKey:"catalog");games[i]["selection"]=selection;root["games"]=games
        XCTAssertNil(try DailyChallengePack.load(JSONSerialization.data(withJSONObject:root)).guessWho)
    }
}
