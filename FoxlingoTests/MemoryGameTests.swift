import XCTest
@testable import FoxlingoCore
final class MemoryGameTests: XCTestCase {
    func testNewHiddenCardInterruptsMismatchWithoutLosingMatches() {
        var board=MemoryMatch(pairs:[Pair(left:"a",right:"A"),Pair(left:"b",right:"B"),Pair(left:"c",right:"C")])
        _ = board.flip("a");_ = board.flip("A")
        _ = board.flip("b");XCTAssertEqual(board.flip("C"),.mismatch)
        XCTAssertEqual(board.flip("C",advancingPendingMismatch:true),.ignored)
        XCTAssertEqual(board.faceUp,["b","C"])
        XCTAssertEqual(board.flip("c",advancingPendingMismatch:true),.revealed)
        XCTAssertEqual(board.faceUp,["c"]);XCTAssertEqual(board.matched,["a","A"])
        XCTAssertEqual(board.flip("C"),.matched("c"))
    }
    func fixture() throws -> (ContentPack,Data,[MemoryGamePair]) {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
        let data=try Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/memory-en.json"))
        return (pack,data,try MemoryGameDeck.load(data,pack:pack))
    }
    func testEightUniqueImageNameOrStatPairsHaveScopedEvidence() throws {
        let (_,_,pairs)=try fixture()
        XCTAssertEqual(pairs.count,8);XCTAssertEqual(pairs.filter {$0.fact != nil}.count,4)
        XCTAssertEqual(Set(pairs.flatMap {[$0.relationship.left,$0.relationship.right]}).count,16)
        for pair in pairs {XCTAssertNotNil(pair.subject.imageAsset);if let fact=pair.fact {XCTAssertEqual(fact.subjectID,pair.subject.id);XCTAssertFalse(fact.scope.isEmpty);XCTAssertFalse(fact.sourceKeys.isEmpty)}}
        var board=MemoryMatch(pairs:pairs.map(\.relationship))
        for pair in pairs {XCTAssertEqual(board.flip(pair.relationship.left),.revealed);XCTAssertEqual(board.flip(pair.relationship.right),.matched(pair.relationship.left))}
        XCTAssertEqual(board.matched.count,16)
    }
    func testResumePreservesOrderMatchedTurnsAndRejectsInvalidOrCompletedBoards() throws {
        let (_,_,pairs)=try fixture();let ids=pairs.flatMap {[$0.relationship.left,$0.relationship.right]}.reversed().map {$0}
        let progress=MemoryProgress(order:ids,matched:[pairs[0].relationship.left],moves:3)
        let saved=GameResume(signature:MemoryGameDeck.signature(pairs),sessionID:UUID(),memory:progress)
        var state=LearnerState();state.storeGame(saved,kind:"memory")
        let decoded=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        let restored=MemoryGameDeck.restore(decoded.savedGame("memory")!,pairs:pairs.reversed(),completedSessions:[])!
        XCTAssertEqual(restored.order,ids);XCTAssertEqual(restored.moves,3);XCTAssertEqual(restored.matched,progress.matched)
        XCTAssertNil(MemoryGameDeck.restore(saved,pairs:pairs,completedSessions:[saved.sessionID]))
        let malformed=GameResume(signature:saved.signature,sessionID:UUID(),memory:MemoryProgress(order:Array(repeating:ids[0],count:16),matched:[],moves:0))
        XCTAssertNil(MemoryGameDeck.restore(malformed,pairs:pairs,completedSessions:[]))
        XCTAssertTrue(state.completeGame(id:saved.sessionID,kind:"memory",count:8,now:Date()));state.removeSavedGame("memory")
        XCTAssertFalse(state.completeGame(id:saved.sessionID,kind:"memory",count:8,now:Date()));XCTAssertTrue(state.reviews.isEmpty);XCTAssertTrue(state.acquiredCards.isEmpty)
    }
    func testAmbiguousSubjectsAndUnrelatedStatAreRejected() throws {
        let (pack,data,_)=try fixture();var json=try JSONSerialization.jsonObject(with:data) as! [[String:Any]]
        json[1]["subjectID"]=json[0]["subjectID"]
        XCTAssertThrowsError(try MemoryGameDeck.load(JSONSerialization.data(withJSONObject:json),pack:pack))
        json=try JSONSerialization.jsonObject(with:data) as! [[String:Any]];json[4]["factID"]=json[5]["factID"]
        XCTAssertThrowsError(try MemoryGameDeck.load(JSONSerialization.data(withJSONObject:json),pack:pack))
    }
}
