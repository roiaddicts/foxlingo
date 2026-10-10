import XCTest
@testable import FoxlingoCore

final class DailyGoltextoTests:XCTestCase {
    private func data() throws -> Data {try Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Foxlingo/Resources/daily-en.json"))}
    private func round() throws -> DailyGoltexto {try XCTUnwrap(DailyChallengePack.load(data()).goltexto)}
    func testEveryEligibleGuessMatchesIndependentJavaScriptReference() throws {
        let r=try round(),url=try XCTUnwrap(Bundle.module.url(forResource:"goltexto-2026-10-09-oracle",withExtension:"json"))
        let fixture=try JSONSerialization.jsonObject(with:Data(contentsOf:url)) as! [String:Any],expected=fixture["scores"] as! [[String:Int]]
        XCTAssertEqual(fixture["answerID"] as? Int,465);XCTAssertEqual(expected.count,969);XCTAssertEqual(r.profiles.count,expected.count)
        for row in expected {let player=try XCTUnwrap(r.profile("daily-goltexto-\(row["id"]!)")),score=r.score(player);XCTAssertEqual(score.value,row["score"],player.player.name);XCTAssertEqual(score.parts.reduce(0) {$0+$1.points},score.value)}
    }
    func testSourceScopesNamespacesCountriesPortraitsAndIncompleteAge() throws {
        let r=try round();XCTAssertEqual(r.answer.player.id,"daily-goltexto-465");XCTAssertEqual(r.answer.player.name,"Marcos Leonardo");XCTAssertEqual(r.answer.rating,79);XCTAssertEqual(r.answer.age,23);XCTAssertEqual(r.answer.countryID,7);XCTAssertEqual(r.countries.count,71)
        XCTAssertEqual(r.countries.first {$0.id == 6}?.name,"England");XCTAssertEqual(r.countries.first {$0.id == 10}?.name,"France")
        let mbappe=try XCTUnwrap(r.profile("daily-goltexto-1")),general=try DailyChallengePack.load(data()).top10.players
        XCTAssertEqual(mbappe.player.name,"Kylian Mbappé");XCTAssertNotEqual(mbappe.player.imageURL,general.first {$0.id == "daily-general-1"}?.imageURL)
        XCTAssertNotNil(mbappe.player.imageURL)
        let missing=try XCTUnwrap(r.profile("daily-goltexto-610"));XCTAssertNil(missing.age);XCTAssertEqual(r.score(missing).parts.first {$0.id == "age"}?.points,0)
        XCTAssertEqual(r.score(r.answer).value,100)
    }
    func testWrongIdentitiesCapAtNinetyNineAndUnclassifiedGroupsMatchSource() throws {
        let r=try round(),a=r.answer
        let wrong=GoltextoPlayer(player:GamePlayer(id:"foreign-high-score",name:"Other player",aliases:[],imageURL:nil,imageAsset:nil),clubID:a.clubID,countryID:a.countryID,rating:a.rating,positions:a.positions,age:a.age)
        XCTAssertEqual(r.score(wrong).value,99)
        var progress=GoltextoProgress(round:r);XCTAssertFalse(progress.guess(wrong.player.id,in:r));XCTAssertFalse(progress.won(r))
        let unknownA=GoltextoPlayer(player:a.player,clubID:103,countryID:105,rating:a.rating,positions:a.positions,age:a.age)
        let unknownB=GoltextoPlayer(player:wrong.player,clubID:87,countryID:103,rating:a.rating,positions:a.positions,age:a.age)
        let synthetic=DailyGoltexto(answer:unknownA,profiles:[unknownA,unknownB],clubs:r.clubs,countries:r.countries,leagueGroups:r.leagueGroups,regionGroups:r.regionGroups,signature:"synthetic")
        XCTAssertNil(synthetic.league(103));XCTAssertNil(synthetic.league(87));XCTAssertEqual(synthetic.region(105),0);XCTAssertEqual(synthetic.region(103),0)
        let score=synthetic.score(unknownB);XCTAssertEqual(score.parts.first {$0.id == "league"}?.points,20);XCTAssertEqual(score.parts.first {$0.id == "region"}?.points,6)
    }
    func testAllBudgetsFinalChanceWinsLossesAndSingleCredit() throws {
        let r=try round(),wrong=r.profiles.filter {$0.player.id != r.answer.player.id}
        for limit in [10,20,100] {
            var p=GoltextoProgress(round:r,limit:limit)
            for player in wrong.prefix(limit-1) {XCTAssertTrue(p.guess(player.player.id,in:r))}
            XCTAssertFalse(p.guess(wrong[0].player.id,in:r));XCTAssertTrue(p.guess(r.answer.player.id,in:r));XCTAssertTrue(p.won(r));XCTAssertFalse(p.reveal(in:r));XCTAssertTrue(p.valid(for:r))
            var state=LearnerState();XCTAssertTrue(state.completeGame(id:p.sessionID,kind:"goltexto",count:limit,now:Date()));XCTAssertFalse(state.completeGame(id:p.sessionID,kind:"goltexto",count:limit,now:Date()))
            var loss=GoltextoProgress(round:r,limit:limit)
            for player in wrong.prefix(limit) {XCTAssertTrue(loss.guess(player.player.id,in:r))}
            XCTAssertTrue(loss.finished(r));XCTAssertFalse(loss.won(r));XCTAssertFalse(loss.guess(r.answer.player.id,in:r))
        }
        XCTAssertFalse(GoltextoProgress(round:r,limit:11).valid(for:r))
    }
    func testSavedBudgetGuessesRevealAndInvalidCompletedHistory() throws {
        let r=try round();var p=GoltextoProgress(round:r,limit:100);let first=try XCTUnwrap(r.profiles.first {$0.player.id != r.answer.player.id})
        XCTAssertTrue(p.guess(first.player.id,in:r))
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer {try? FileManager.default.removeItem(at:directory)}
        let cache=DailyChallengeCache(directory:directory);try cache.save(p,for:r);let restored=try XCTUnwrap(cache.progress(for:r));XCTAssertEqual(restored.limit,100);XCTAssertEqual(restored.guesses,p.guesses);XCTAssertEqual(restored.sessionID,p.sessionID)
        XCTAssertTrue(p.reveal(in:r));p.reviewRecorded=true;try cache.save(p,for:r);XCTAssertTrue(try XCTUnwrap(cache.progress(for:r)).gaveUp);XCTAssertFalse(p.won(r))
        p.gaveUp=false;XCTAssertFalse(p.valid(for:r));XCTAssertThrowsError(try cache.save(p,for:r))
        p.reviewRecorded=false;p.guesses=[r.answer.player.id,first.player.id];XCTAssertFalse(p.valid(for:r))
    }
    func testAlteredRecordsCrosswalkAndOrderFailAndOlderPacksRemainUsable() throws {
        var root=try JSONSerialization.jsonObject(with:data()) as! [String:Any],games=root["games"] as! [[String:Any]],i=games.firstIndex {$0["id"] as? String == "goltexto"}!,selection=games[i]["selection"] as! [String:Any]
        let original=selection
        var player=selection["player"] as! [String:Any];player["clubID"]=9;selection["player"]=player;games[i]["selection"]=selection;root["games"]=games
        XCTAssertThrowsError(try DailyChallengePack.load(JSONSerialization.data(withJSONObject:root)))
        selection=original;var order=selection["orderPlayerIDs"] as! [Int];order[0]=order[1];selection["orderPlayerIDs"]=order;games[i]["selection"]=selection;root["games"]=games
        XCTAssertThrowsError(try DailyChallengePack.load(JSONSerialization.data(withJSONObject:root)))
        selection=original;var catalog=selection["catalog"] as! [String:Any],map=catalog["portraitPlayerIDs"] as! [String:Int];map["1"]=1;catalog["portraitPlayerIDs"]=map;selection["catalog"]=catalog;games[i]["selection"]=selection;root["games"]=games
        XCTAssertThrowsError(try DailyChallengePack.load(JSONSerialization.data(withJSONObject:root)))
        selection=original;selection.removeValue(forKey:"catalog");games[i]["selection"]=selection;root["games"]=games
        let old=try DailyChallengePack.load(JSONSerialization.data(withJSONObject:root));XCTAssertNil(old.goltexto);XCTAssertEqual(old.supportedModeIDs.count,7)
    }
}
