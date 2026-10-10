import XCTest
@testable import FoxlingoCore

final class DailyXITests:XCTestCase {
    let now=Date(timeIntervalSince1970:1791612000)
    private var root:URL {URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()}
    private func data() throws -> Data {try Data(contentsOf:root.appendingPathComponent("ref/futbol11-daily/2026-10-10-a4455be33294.json"))}
    private func rounds() throws -> [DailyXI] {try DailyChallengePack.load(data()).xi}
    func testAllFiveDailyAdaptersRetainExactFormationsGroupsAndScopedIdentities() throws {
        let pack=try DailyChallengePack.load(data());XCTAssertEqual(pack.supportedModeIDs,DailyChallengePack.modeIDs)
        XCTAssertEqual(pack.xi.map(\.id),["countries","clubs","retro","legends","america"])
        XCTAssertEqual(pack.xi.map {$0.normal.pack.formations[0].id},["343","352","433","352","532"])
        XCTAssertEqual(pack.xi.map {$0.normal.mode.groups[0].name},["England","Real Madrid","PSV 04/05","Italy","Defensa y Justicia"])
        XCTAssertEqual(pack.xi.map {$0.easy.mode.groups[0].name},["Uruguay","Real Madrid","Inter 22/23","Italy","Internacional"])
        for r in pack.xi {for level in DailyXILevel.allCases {let e=r.engine(level),b=r.initialBoard(level);XCTAssertEqual(b.groupIDs,e.mode.groups.map(\.id));XCTAssertNotNil(e.solution(b,nodeLimit:100_000));XCTAssertEqual(e.allowsRepeatedPlayers,r.id != "retro");XCTAssertTrue(e.pack.players.allSatisfy {$0.person.id.hasPrefix("daily-xi-\(r.id)-player-")})}}
        let legends=try XCTUnwrap(pack.xi.first {$0.id == "legends"})
        XCTAssertTrue(zip(legends.normal.mode.groups,legends.easy.mode.groups).contains {$0.playerIDs.count < $1.playerIDs.count})
    }
    func testEveryModeAndDifficultyCompletesAndReceivesCreditExactlyOnce() throws {
        for r in try rounds() {for level in DailyXILevel.allCases {
            var p=DailyXIProgress(round:r);XCTAssertTrue(p.start(in:r,level:level,timer:0,now:now));let e=r.engine(level),solution=try XCTUnwrap(e.solution(p.board!,nodeLimit:100_000))
            while let offered=p.board?.offeredID {let answer=try XCTUnwrap(solution.first {$0.value.groupID == offered});XCTAssertTrue(p.place(answer.value.playerID,at:answer.key,in:r,now:now,assisted:true))}
            XCTAssertEqual(p.status,.won);XCTAssertTrue(p.valid(for:r));XCTAssertEqual(p.board?.assisted.count,11);XCTAssertFalse(p.undo(in:r,now:now));XCTAssertFalse(p.reveal(in:r,now:now))
            var state=LearnerState();XCTAssertTrue(state.completeGame(id:p.sessionID,kind:r.kind,count:11,now:now));XCTAssertFalse(state.completeGame(id:p.sessionID,kind:r.kind,count:11,now:now));XCTAssertEqual(state.sessions.count,1)
        }}
    }
    func testWrongNamespacesSlotsOfferMembershipAndUndoKeepExactDailyOrder() throws {
        let r=try XCTUnwrap(rounds().first);var p=DailyXIProgress(round:r);XCTAssertTrue(p.start(in:r,level:.easy,timer:0,now:now));let e=r.easy,b=try XCTUnwrap(p.board),solution=try XCTUnwrap(e.solution(b)),answer=try XCTUnwrap(solution.first {$0.value.groupID == b.offeredID})
        XCTAssertFalse(p.place("daily-general-1",at:answer.key,in:r,now:now));XCTAssertFalse(p.place("draft-nations-player-1",at:answer.key,in:r,now:now));XCTAssertFalse(p.place(answer.value.playerID,at:-1,in:r,now:now))
        let wrong=try XCTUnwrap(e.pack.players.first {!e.groups[b.offeredID!]!.playerIDs.contains($0.person.id)})
        XCTAssertFalse(p.place(wrong.person.id,at:answer.key,in:r,now:now));XCTAssertTrue(p.board!.placed.isEmpty)
        XCTAssertTrue(p.place(answer.value.playerID,at:answer.key,in:r,now:now));XCTAssertNotEqual(p.board?.offeredID,b.offeredID);XCTAssertTrue(p.undo(in:r,now:now));XCTAssertEqual(p.board?.offeredID,b.offeredID)
        var forged=p;forged.board=DraftProgress(modeID:b.modeID,formationID:b.formationID,groupIDs:b.groupIDs.reversed(),placed:[:],history:[],assisted:[]);XCTAssertFalse(forged.valid(for:r))
    }
    func testTimerPreferencesPausedStateExpiryAndRevealNeverBecomeWins() throws {
        let r=try XCTUnwrap(rounds().first)
        for timer in [40,60,90] {
            var p=DailyXIProgress(round:r);XCTAssertTrue(p.start(in:r,level:.normal,timer:timer,now:now));p.pause(at:now.addingTimeInterval(12.5));XCTAssertEqual(p.timeLeft,Double(timer)-12.5);XCTAssertNil(p.deadline)
            p.resume(at:now.addingTimeInterval(1000));let end=now.addingTimeInterval(1000+Double(timer)-12.5);let solution=try XCTUnwrap(r.normal.solution(p.board!)),answer=try XCTUnwrap(solution.first {$0.value.groupID == p.board?.offeredID})
            XCTAssertFalse(p.place(answer.value.playerID,at:answer.key,in:r,now:end));XCTAssertEqual(p.status,.lost);XCTAssertTrue(p.valid(for:r));XCTAssertEqual(p.remaining(at:end),0)
        }
        var p=DailyXIProgress(round:r);XCTAssertTrue(p.start(in:r,level:.easy,timer:90,now:now));XCTAssertTrue(p.reveal(in:r,now:now.addingTimeInterval(10)));XCTAssertEqual(p.status,.revealed);XCTAssertEqual(p.timeLeft,80);XCTAssertTrue(p.valid(for:r));XCTAssertFalse(p.undo(in:r,now:now))
    }
    func testCacheStoresPreferencesPlacementsCompletedOutcomeAndRejectsInvalidStates() throws {
        let r=try XCTUnwrap(rounds().first),dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer {try? FileManager.default.removeItem(at:dir)};let cache=DailyChallengeCache(directory:dir)
        var p=DailyXIProgress(round:r);p.level = .easy;p.timer=40;try cache.save(p,for:r);XCTAssertEqual(cache.progress(for:r)?.level,.easy);XCTAssertEqual(cache.progress(for:r)?.timer,40)
        XCTAssertTrue(p.start(in:r,level:.easy,timer:40,now:now));let e=r.easy,answer=try XCTUnwrap(e.solution(p.board!)?.first {$0.value.groupID == p.board?.offeredID});XCTAssertTrue(p.place(answer.value.playerID,at:answer.key,in:r,now:now));p.pause(at:now.addingTimeInterval(5));try cache.save(p,for:r)
        let restored=try XCTUnwrap(cache.progress(for:r));XCTAssertEqual(restored.board?.placed.count,1);XCTAssertEqual(restored.timeLeft,35);XCTAssertNil(restored.deadline);XCTAssertEqual(restored.sessionID,p.sessionID)
        var bad=p;bad.timeLeft = .infinity;XCTAssertThrowsError(try cache.save(bad,for:r));bad=p;bad.status = .won;XCTAssertFalse(bad.valid(for:r));bad=p;bad.reviewRecorded=true;XCTAssertFalse(bad.valid(for:r))
        XCTAssertTrue(p.reveal(in:r,now:now));p.reviewRecorded=true;try cache.save(p,for:r);XCTAssertEqual(cache.progress(for:r)?.status,.revealed);XCTAssertEqual(cache.progress(for:r)?.reviewRecorded,true)
    }
    func testSharedEngineRepeatedPlayerRuleIsOptInAndDoesNotAlterPractice() throws {
        let r=try XCTUnwrap(rounds().first),e=r.normal
        XCTAssertTrue(e.allowsRepeatedPlayers)
        let practice=DraftEngine(pack:e.pack,mode:e.mode);XCTAssertFalse(practice.allowsRepeatedPlayers);XCTAssertNotEqual(e.signature,practice.signature)
        let profiles=[DraftProfile(person:GamePlayer(id:"p",name:"P",aliases:[],imageURL:nil,imageAsset:nil),positions:["CM"])]
        let groups=(0..<11).map {DraftGroup(id:"g\($0)",name:"G",distinctKey:String($0),imageAsset:"",imageURL:"https://example.com/flag.png",playerIDs:["p"])}
        let mode=DraftMode(id:"fixture",title:"",subtitle:"",scope:"fixture",sourceURL:"https://example.com",groups:groups),pack=DraftPack(schemaVersion:1,fetchedAt:"",sourceURL:"https://example.com",players:profiles,formations:[DraftFormation(id:"433",positions:Array(repeating:"CM",count:11),rows:[Array(0..<11)])],modes:[mode])
        let repeated=DraftEngine(pack:pack,mode:mode,allowsRepeatedPlayers:true),strict=DraftEngine(pack:pack,mode:mode),board=DraftProgress(modeID:mode.id,formationID:"433",groupIDs:groups.map(\.id),placed:[:],history:[],assisted:[])
        XCTAssertNotNil(repeated.solution(board));XCTAssertNil(strict.solution(board))
    }
    func testForgedCatalogsPositionsMembershipsPortraitsAndDateAreRejected() throws {
        let original=try JSONSerialization.jsonObject(with:data()) as! [String:Any]
        func changed(_ mutation:(inout [String:Any])->Void) throws -> Data {var root=original;var games=root["games"] as! [[String:Any]],i=games.firstIndex {$0["id"] as? String == "countries"}!,s=games[i]["selection"] as! [String:Any];mutation(&s);games[i]["selection"]=s;root["games"]=games;return try JSONSerialization.data(withJSONObject:root)}
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["boardDate"]="2026-10-09";s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["playerSourceURL"]="https://futbol11.com/_nuxt/sF1zb7uP.js";s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["portraitPlayerIDs"]=["1":1];s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var c=s["catalog"] as! [String:Any];c["excludedPositionPlayerIDs"]=[1];s["catalog"]=c}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var b=s["boards"] as! [[String:Any]],m=b[0]["memberships"] as! [[String:Any]];m[0]["playerIDs"]=[1];b[0]["memberships"]=m;s["boards"]=b}))
        XCTAssertThrowsError(try DailyChallengePack.load(changed {s in var b=s["boards"] as! [[String:Any]],g=b[0]["groups"] as! [[String:Any]];g[0]["name"]="Fake";b[0]["groups"]=g;s["boards"]=b}))
        let old=try DailyChallengePack.load(Data(contentsOf:root.appendingPathComponent("ref/futbol11-daily/2026-10-10-ce0e2fed5287.json")));XCTAssertTrue(old.xi.isEmpty);XCTAssertEqual(old.supportedModeIDs.count,14)
    }
}
