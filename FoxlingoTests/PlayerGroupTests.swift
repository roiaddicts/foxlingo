import XCTest
@testable import FoxlingoCore

final class PlayerGroupTests: XCTestCase {
    private func pack() throws -> GamePack {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try GamePack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/games-en.json")))
    }
    func testGroupsHaveSixteenDistinctActivePlayersAndUnambiguousCountryMembership() throws {
        let pack=try pack()
        for mode in [PlayerGroupMode.connections,.impostor] {
            let board=try XCTUnwrap(PlayerGroupDeck.make(mode:mode,pack:pack,randomized:false))
            XCTAssertEqual(Set(board.order).count,16)
            for group in board.groups {
                XCTAssertNotNil(pack.category(group.categoryID)?.imageAsset)
                for id in group.playerIDs {
                    XCTAssertTrue(pack.connectionPlayers.contains {$0.id == id})
                    XCTAssertEqual(board.groups.filter {pack.category($0.categoryID)!.playerIDs.contains(id)}.count,1)
                }
            }
        }
    }
    func testAvailableCachedPortraitsArePreferredWithoutChangingTheAnswerGroups() throws {
        let pack=try pack()
        let assets=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Foxlingo/Resources/Assets.xcassets")
        let available=Set(try FileManager.default.contentsOfDirectory(atPath:assets.path).filter {$0.hasSuffix(".imageset")}.map {String($0.dropLast(9))})
        let board=try XCTUnwrap(PlayerGroupDeck.make(mode:.connections,pack:pack,randomized:false,availableArtwork:available))
        for id in board.order {XCTAssertTrue(available.contains(try XCTUnwrap(pack.player(id)?.imageAsset)))}
        XCTAssertEqual(board.order.count,16)
    }
    func testWrongAndPartialGroupsKeepBoardRecoverableThenCompletionOnlyOnce() throws {
        let pack=try pack()
        for mode in [PlayerGroupMode.connections,.impostor] {
            var board=try XCTUnwrap(PlayerGroupDeck.make(mode:mode,pack:pack,randomized:false))
            board.select(board.groups[0].playerIDs[0]);XCTAssertNil(board.check());XCTAssertEqual(board.checks,0)
            for id in board.groups[1].playerIDs.prefix(3) {board.select(id)}
            XCTAssertEqual(board.check(),false);XCTAssertEqual(board.checks,1);XCTAssertTrue(board.solved.isEmpty)
            board.selected=[]
            for group in board.groups {
                for id in group.playerIDs {board.select(id)}
                XCTAssertEqual(board.check(),true)
                XCTAssertFalse(board.available.contains(group.playerIDs[0]))
            }
            XCTAssertTrue(board.finished);XCTAssertNil(board.check());XCTAssertEqual(board.checks,5)
        }
    }
    func testBothModesResumeSelectionAndGroupsAndRejectInvalidOrCompletedBoards() throws {
        let pack=try pack()
        for mode in [PlayerGroupMode.connections,.impostor] {
            var board=try XCTUnwrap(PlayerGroupDeck.make(mode:mode,pack:pack,randomized:false))
            for id in board.groups[0].playerIDs {board.select(id)}
            XCTAssertEqual(board.check(),true)
            board.select(board.groups[1].playerIDs[0])
            let saved=GameResume(signature:PlayerGroupDeck.signature(pack),sessionID:UUID(),grouping:board)
            var state=LearnerState();state.storeGame(saved,kind:mode.rawValue)
            let decoded=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
            let resumed=try XCTUnwrap(PlayerGroupDeck.restore(decoded.savedGame(mode.rawValue)!,mode:mode,pack:pack,completedSessions:[]))
            XCTAssertEqual(resumed.selected,board.selected);XCTAssertEqual(resumed.order,board.order);XCTAssertEqual(resumed.solved,board.solved)
            XCTAssertNil(PlayerGroupDeck.restore(saved,mode:mode,pack:pack,completedSessions:[saved.sessionID]))
            XCTAssertNil(PlayerGroupDeck.restore(saved,mode:mode == .connections ? .impostor : .connections,pack:pack,completedSessions:[]))
            board.selected=["unknown-player"]
            XCTAssertNil(PlayerGroupDeck.restore(GameResume(signature:saved.signature,sessionID:UUID(),grouping:board),mode:mode,pack:pack,completedSessions:[]))
        }
    }
    func testOptionalNewGameFieldDoesNotBreakOlderSavesOrOtherGameRestore() throws {
        let pack=try pack(),board=try XCTUnwrap(PlayerGroupDeck.make(mode:.connections,pack:pack,randomized:false))
        let old=GameResume(signature:"old-signature",sessionID:UUID())
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(old)) as! [String:Any]
        json.removeValue(forKey:"grouping")
        XCTAssertNil(try JSONDecoder().decode(GameResume.self,from:JSONSerialization.data(withJSONObject:json)).grouping)
        let mixed=GameResume(signature:GameResumeRules.boardSignature(kind:"grid",pack:pack,squadID:nil)!,sessionID:UUID(),board:BoardProgress(squadID:nil,placed:[:],history:[],assisted:[],offered:nil),grouping:board)
        XCTAssertNil(GameResumeRules.restoreBoard(mixed,kind:"grid",pack:pack,completedSessions:[]))
        XCTAssertNil(PlayerGroupDeck.restore(mixed,mode:.connections,pack:pack,completedSessions:[]))
    }
}
