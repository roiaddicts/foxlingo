import XCTest
@testable import FoxlingoCore

final class TimelineTests: XCTestCase {
    func fixture() throws -> (ContentPack,Data,[TimelineRound]) {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
        let data=try Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/timeline-en.json"))
        return (pack,data,try TimelineDeck.load(data,pack:pack))
    }
    func changed(_ pack: ContentPack,_ change: (inout [String:Any])->Void) throws -> ContentPack {
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any];change(&json)
        return try JSONDecoder().decode(ContentPack.self,from:JSONSerialization.data(withJSONObject:json))
    }
    func testSourcedChronologyAndNeverStartsSolved() throws {
        let (_,_,rounds)=try fixture();XCTAssertEqual(rounds.count,2)
        XCTAssertEqual(rounds[0].events.map(\.year),[2007,2011,2012])
        XCTAssertEqual(rounds[1].events.map(\.year),[1902,1956,1999,2014])
        for round in rounds {
            XCTAssertTrue(round.accepts(round.answer));XCTAssertFalse(round.accepts(Array(round.answer.reversed())))
            for _ in 0..<100 {let order=round.shuffledOrder();XCTAssertFalse(round.accepts(order));XCTAssertEqual(Set(order),Set(round.answer))}
            for event in round.events {XCTAssertNotNil(event.subject.imageAsset);XCTAssertFalse(event.fact.sourceKeys.isEmpty)}
        }
    }
    func testMovesPreserveCountsAndRejectInvalidOffsetsWithoutTrapping() throws {
        let (_,_,rounds)=try fixture();let order=Array(rounds[0].answer.reversed())
        let progress=TimelineProgress(roundID:rounds[0].id,order:order,checks:2)
        let moved=progress.moving(order[0],by:1)
        XCTAssertEqual(moved.order,[order[1],order[0],order[2]]);XCTAssertEqual(moved.checks,2);XCTAssertEqual(moved.moves,1)
        for offset in [Int.min,Int.max,-2,0,2,-1] {XCTAssertEqual(progress.moving(order[0],by:offset).order,order)}
        XCTAssertEqual(progress.moving("missing",by:1).order,order)
    }
    func testResumeKeepsWrongOrderMovesAndChecksAcrossRoundReordering() throws {
        let (_,_,rounds)=try fixture();let round=rounds[1]
        let progress=TimelineProgress(roundID:round.id,order:Array(round.answer.reversed()),checks:3,moves:8)
        let saved=GameResume(signature:round.signature,sessionID:UUID(),timeline:progress)
        var state=LearnerState();state.storeGame(saved,kind:"timeline")
        let decoded=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        let restored=try XCTUnwrap(TimelineDeck.restore(decoded.savedGame("timeline")!,rounds:rounds.reversed(),completedSessions:[]))
        XCTAssertEqual(restored.roundID,round.id);XCTAssertEqual(restored.order,progress.order);XCTAssertEqual(restored.checks,3);XCTAssertEqual(restored.moves,8)
        XCTAssertNil(TimelineDeck.restore(saved,rounds:rounds,completedSessions:[saved.sessionID]))
        let invalid=GameResume(signature:round.signature,sessionID:UUID(),timeline:TimelineProgress(roundID:round.id,order:Array(repeating:round.answer[0],count:4),checks:0))
        XCTAssertNil(TimelineDeck.restore(invalid,rounds:rounds,completedSessions:[]))
        let mixed=GameResume(signature:round.signature,sessionID:UUID(),memory:MemoryProgress(order:[],matched:[],moves:0),timeline:progress)
        XCTAssertNil(TimelineDeck.restore(mixed,rounds:rounds,completedSessions:[]))
    }
    func testMeaningChangesInvalidateButArtworkAndSourceWordingPreserveBoard() throws {
        let (pack,data,rounds)=try fixture();let round=rounds[0]
        let changedDate=try changed(pack) {json in
            var facts=json["facts"] as! [[String:Any]];let i=facts.firstIndex {$0["key"] as? String == "fact-xolos-climb-founded"}!
            facts[i]["value"]=["kind":"number","display":"2008","number":2008,"unit":"year"];json["facts"]=facts
        }
        XCTAssertNotEqual(try TimelineDeck.load(data,pack:changedDate)[0].signature,round.signature)
        let artwork=try changed(pack) {json in
            var entities=json["entities"] as! [[String:Any]];entities[0]["imageAsset"]="new-art";json["entities"]=entities
            var sources=json["sources"] as! [[String:Any]];sources[0]["title"]="Updated source wording";json["sources"]=sources
        }
        XCTAssertEqual(try TimelineDeck.load(data,pack:artwork)[0].signature,round.signature)
        var definitions=try JSONSerialization.jsonObject(with:data) as! [[String:Any]]
        definitions[0]["events"]=Array((definitions[0]["events"] as! [[String:Any]]).reversed())
        XCTAssertEqual(try TimelineDeck.load(JSONSerialization.data(withJSONObject:definitions),pack:pack)[0].signature,round.signature)

    }
    func testWrongClubContextAndDateLeakageRejected() throws {
        let (pack,data,_)=try fixture();var json=try JSONSerialization.jsonObject(with:data) as! [[String:Any]]
        json[0]["subjectID"]=json[1]["subjectID"]
        XCTAssertThrowsError(try TimelineDeck.load(JSONSerialization.data(withJSONObject:json),pack:pack))
        json=try JSONSerialization.jsonObject(with:data) as! [[String:Any]]
        var events=json[0]["events"] as! [[String:Any]];events[0]["title"]="Founded in 2007";json[0]["events"]=events
        XCTAssertThrowsError(try TimelineDeck.load(JSONSerialization.data(withJSONObject:json),pack:pack))
        let noContext=try changed(pack) {json in
            var facts=json["facts"] as! [[String:Any]];let i=facts.firstIndex {$0["key"] as? String == "fact-madrid-casillas-debut"}!
            facts[i]["evidence"]="A general first-team debut in 1999.";facts[i]["scope"]="Career history";json["facts"]=facts
        }
        XCTAssertThrowsError(try TimelineDeck.load(data,pack:noContext))
    }
    func testImpossibleDateTiedYearsNonYearAndDuplicateEventsRejected() throws {
        let (pack,data,_)=try fixture()
        for value: [String:Any] in [
            ["kind":"date","display":"February 30, 2012","text":"2012-02-30"],
            ["kind":"number","display":"2011","number":2011,"unit":"year"],
            ["kind":"number","display":"2012","number":2012,"unit":"goals"]
        ] {
            let modified=try changed(pack) {json in var facts=json["facts"] as! [[String:Any]];let i=facts.firstIndex {$0["key"] as? String == "fact-xolos-final-date"}!;facts[i]["value"]=value;json["facts"]=facts}
            XCTAssertThrowsError(try TimelineDeck.load(data,pack:modified))
        }
        var json=try JSONSerialization.jsonObject(with:data) as! [[String:Any]];var events=json[0]["events"] as! [[String:Any]];events[1]=events[0];json[0]["events"]=events
        XCTAssertThrowsError(try TimelineDeck.load(JSONSerialization.data(withJSONObject:json),pack:pack))
    }
    func testRetiredFactKeepsUnaffectedRoundAndCreditsActivityOnlyOnce() throws {
        let (pack,data,rounds)=try fixture()
        let retired=try changed(pack) {json in json["facts"]=(json["facts"] as! [[String:Any]]).filter {$0["key"] as? String != "fact-xolos-final-date"}}
        XCTAssertEqual(try TimelineDeck.load(data,pack:retired).map(\.id),[rounds[1].id])
        var state=LearnerState();let id=UUID(),now=Date()
        state.storeGame(GameResume(signature:rounds[0].signature,sessionID:id,timeline:TimelineProgress(roundID:rounds[0].id,order:rounds[0].answer,checks:1)),kind:"timeline")
        state.removeSavedGame("timeline");XCTAssertTrue(state.completeGame(id:id,kind:"timeline",count:3,now:now))
        XCTAssertFalse(state.completeGame(id:id,kind:"timeline",count:3,now:now));XCTAssertNil(state.savedGame("timeline"))
        XCTAssertTrue(state.reviews.isEmpty);XCTAssertTrue(state.acquiredCards.isEmpty);XCTAssertEqual(state.sessions.count,1)
    }
}
