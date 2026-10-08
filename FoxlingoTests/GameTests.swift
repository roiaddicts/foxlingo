import XCTest
@testable import FoxlingoCore

final class GameTests: XCTestCase {
    var games: GamePack!
    override func setUpWithError() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        games=try GamePack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/games-en.json")))
    }
    func testSeedNamespacesAndPortraits() {
        XCTAssertEqual(games.player("player-53")?.name,"Iker Casillas")
        XCTAssertEqual(games.player("classic-player-53")?.name,nil)
        XCTAssertEqual(games.player("classic-player-77")?.name,"Iker Casillas")
        XCTAssertEqual(games.player("classic-player-77")?.imageAsset,"seed-player-53")
    }
    func testEveryGameHasDistinctPlayerSolution() {
        let boards=[games.bingoCategoryIDs.map {Set(games.category($0)!.playerIDs)},(0..<9).map{games.gridCandidates(row:$0/3,column:$0%3)}]+games.lineups.map{s in (0..<11).map(s.candidates)}
        for board in boards {
            let solution=BoardMatcher.solution(board)!
            XCTAssertEqual(solution.count,board.count);XCTAssertEqual(Set(solution.values).count,board.count)
            var placed=[Int:String]()
            for slot in solution.keys.sorted() {let p=solution[slot]!;XCTAssertTrue(BoardMatcher.accepts(player:p,slot:slot,candidates:board,placed:placed));placed[slot]=p;XCTAssertNotNil(BoardMatcher.solution(board,fixed:placed))}
        }
    }
    func testGridRequiresBothCriteria() {
        XCTAssertTrue(games.gridCandidates(row:0,column:0).contains("player-53"))
        XCTAssertFalse(games.gridCandidates(row:0,column:0).contains("player-1"))
        XCTAssertTrue(games.gridCandidates(row:0,column:0).contains("player-57"))
    }
    func testDuplicateAndOccupiedSlotsAreRejected() {
        let board:[Set<String>]=[["a","b"],["a","b"]]
        XCTAssertFalse(BoardMatcher.accepts(player:"a",slot:1,candidates:board,placed:[0:"a"]))
        XCTAssertFalse(BoardMatcher.accepts(player:"b",slot:0,candidates:board,placed:[0:"a"]))
        XCTAssertFalse(BoardMatcher.accepts(player:"c",slot:1,candidates:board,placed:[:]))
    }
    func testMatcherFindsAlternativesAndDetectsDeadEnds() {
        let board:[Set<String>]=[["a","b"],["a"]]
        XCTAssertEqual(BoardMatcher.solution(board),[0:"b",1:"a"])
        XCTAssertNil(BoardMatcher.solution(board,fixed:[0:"a"]))
        XCTAssertNil(BoardMatcher.solution(board,fixed:[8:"a"]))
        XCTAssertNil(BoardMatcher.solution(board,fixed:[0:"a",1:"a"]))
    }
    func testInvalidBoardCannotLoad() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        var j=try JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/games-en.json"))) as! [String:Any]
        j["gridRowIDs"]=["missing","missing","missing"]
        XCTAssertThrowsError(try GamePack.load(JSONSerialization.data(withJSONObject:j)))
    }
    func testGameCompletionCountsStreakWithoutAdvancingRecall() {
        var state=LearnerState(timeZone:"America/Mexico_City")
        let id=UUID(), now=Date(timeIntervalSince1970:1_800_000_000)
        XCTAssertTrue(state.completeGame(id:id,kind:"grid",count:9,now:now))
        XCTAssertFalse(state.completeGame(id:id,kind:"grid",count:9,now:now))
        XCTAssertFalse(state.completeGame(id:UUID(),kind:"unknown",count:9,now:now))
        XCTAssertEqual(state.sessions.count,1);XCTAssertEqual(state.sessions[0].kind,"game-grid")
        XCTAssertEqual(state.streak.activeDays.count,1);XCTAssertTrue(state.reviews.isEmpty);XCTAssertTrue(state.acquiredCards.isEmpty)
    }

    func testMemoryTurnsHideUntilRevealedAndMatchInEitherOrder() {
        var memory=MemoryMatch(pairs:[Pair(left:"l-0",right:"r-0"),Pair(left:"l-1",right:"r-1")])
        XCTAssertFalse(memory.isVisible("l-0"))
        XCTAssertEqual(memory.flip("r-0"),.revealed)
        XCTAssertEqual(memory.flip("r-0"),.ignored)
        XCTAssertEqual(memory.flip("l-0"),.matched("l-0"))
        XCTAssertTrue(memory.isVisible("r-0"));XCTAssertEqual(memory.flip("r-0"),.ignored)
        XCTAssertEqual(memory.flip("l-1"),.revealed);XCTAssertEqual(memory.flip("r-1"),.matched("l-1"))
    }
    func testMemoryMismatchBlocksThirdRevealAndCanClose() {
        var memory=MemoryMatch(pairs:[Pair(left:"l-0",right:"r-0"),Pair(left:"l-1",right:"r-1")])
        XCTAssertEqual(memory.flip("unknown"),.ignored)
        XCTAssertEqual(memory.flip("l-0"),.revealed);XCTAssertEqual(memory.flip("l-1"),.mismatch)
        XCTAssertEqual(memory.flip("r-0"),.ignored);XCTAssertTrue(memory.waitingToClose)
        memory.closeMismatch();XCTAssertFalse(memory.isVisible("l-0"));XCTAssertTrue(memory.matched.isEmpty)
        XCTAssertEqual(memory.flip("l-0"),.revealed);XCTAssertEqual(memory.flip("r-0"),.matched("l-0"))
    }
    func testMemoryRestoresOnlyCompletedPairs() {
        let memory=MemoryMatch(pairs:[Pair(left:"l-0",right:"r-0"),Pair(left:"l-1",right:"r-1")],completed:["l-0","unknown"])
        XCTAssertEqual(memory.matched,Set(["l-0","r-0"]))
        XCTAssertTrue(memory.faceUp.isEmpty);XCTAssertFalse(memory.isVisible("l-1"))
    }

}
