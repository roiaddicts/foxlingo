import XCTest
@testable import FoxlingoCore

final class DraftXITests: XCTestCase {
    private func pack() throws -> DraftPack {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try DraftPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/drafts-en.json")))
    }
    func testEveryModeAndFormationHasACompleteDistinctXI() throws {
        let pack=try pack()
        XCTAssertEqual(pack.players.count,8958)
        XCTAssertEqual(Set(pack.modes.map(\.id)),Set(["nations","clubs","retro","legends","america"]))
        for mode in pack.modes {
            let engine=DraftEngine(pack:pack,mode:mode)
            for formation in pack.formations {
                var board=try XCTUnwrap(engine.make(formationID:formation.id,randomized:false),"\(mode.id) \(formation.id)")
                let solution=try XCTUnwrap(engine.solution(board))
                XCTAssertEqual(Set(solution.values.map(\.playerID)).count,11)
                XCTAssertEqual(Set(board.groupIDs.compactMap {engine.groups[$0]?.distinctKey}).count,11)
                while let offered=board.offeredID {
                    let answer=try XCTUnwrap(solution.first {$0.value.groupID == offered})
                    XCTAssertTrue(engine.place(answer.value.playerID,at:answer.key,on:&board))
                }
                XCTAssertTrue(board.finished);XCTAssertTrue(engine.valid(board,allowFinished:true))
                XCTAssertFalse(engine.valid(board))
                board.undo();XCTAssertFalse(board.finished);XCTAssertEqual(board.placed.count,10)
            }
        }
    }
    func testNamespaceMembershipPositionsUndoAndResumeCannotBeConfused() throws {
        let pack=try pack(),mode=try XCTUnwrap(pack.modes.first {$0.id == "nations"})
        let engine=DraftEngine(pack:pack,mode:mode)
        var board=try XCTUnwrap(engine.make(randomized:false))
        let offered=try XCTUnwrap(board.offeredID),solution=try XCTUnwrap(engine.solution(board))
        let answer=try XCTUnwrap(solution.first {$0.value.groupID == offered})
        XCTAssertFalse(engine.place("player-1",at:answer.key,on:&board))
        XCTAssertFalse(engine.place(answer.value.playerID,at:-1,on:&board))
        let wrong=try XCTUnwrap(pack.players.first {!engine.groups[offered]!.playerIDs.contains($0.person.id)})
        XCTAssertFalse(engine.place(wrong.person.id,at:answer.key,on:&board))
        XCTAssertTrue(engine.place(answer.value.playerID,at:answer.key,on:&board,assisted:true))
        XCTAssertFalse(engine.place(answer.value.playerID,at:answer.key,on:&board))
        let session=UUID(),saved=GameResume(signature:engine.signature,sessionID:session,draft:board)
        let decoded=try JSONDecoder().decode(GameResume.self,from:JSONEncoder().encode(saved))
        XCTAssertEqual(engine.restore(decoded,completedSessions:[])?.placed.count,1)
        XCTAssertNil(engine.restore(decoded,completedSessions:[session]))
        XCTAssertNil(engine.restore(GameResume(signature:"stale",sessionID:session,draft:board),completedSessions:[]))
        let mixed=GameResume(signature:engine.signature,sessionID:session,board:BoardProgress(squadID:nil,placed:[:],history:[],assisted:[],offered:nil),draft:board)
        XCTAssertNil(engine.restore(mixed,completedSessions:[]))
        board.history=[];XCTAssertFalse(engine.valid(board))
        var restored=try XCTUnwrap(engine.restore(saved,completedSessions:[]));restored.undo()
        XCTAssertTrue(restored.assisted.isEmpty);XCTAssertEqual(restored.offeredID,offered)
    }
    func testAmericaUsesClubsAndClassicCountryKeysRemainSeparate() throws {
        let pack=try pack(),america=try XCTUnwrap(pack.modes.first {$0.id == "america"}),legends=try XCTUnwrap(pack.modes.first {$0.id == "legends"})
        XCTAssertEqual(america.groups.first?.name,"Palmeiras")
        XCTAssertEqual(legends.groups.first?.name,"England")
        XCTAssertFalse(legends.groups.flatMap(\.playerIDs).contains("draft-classic-player-76"))
        let nations=try XCTUnwrap(pack.players.first {$0.person.id == "draft-nations-player-1"})
        XCTAssertEqual(nations.person.name,"Kylian Mbappé")
        XCTAssertEqual(pack.players.first {$0.person.id == "draft-classic-player-1"}?.person.name,"Peter Shilton")
        XCTAssertFalse(pack.players.contains {$0.person.id == "draft-classic-player-1452"})
    }
    func testLegalDeadEndRemainsResumableAndUndoRecovers() throws {
        let positions=["GK","CM"]+Array(repeating:"ST",count:9)
        let players=(0..<11).map {i in DraftProfile(person:GamePlayer(id:"p\(i)",name:"Player \(i)",aliases:["Player \(i)"],imageURL:nil,imageAsset:nil),positions:i == 0 ? ["GK","CM"] : [positions[i == 1 ? 0 : i]])}
        let groups=(0..<11).map {i in DraftGroup(id:"g\(i)",name:"Group \(i)",distinctKey:"\(i)",imageAsset:"test",imageURL:"https://example.com/flag.png",playerIDs:["p\(i)"])}
        let mode=DraftMode(id:"test",title:"Test",subtitle:"",scope:"Fixture",sourceURL:"https://example.com/",groups:groups)
        let pack=DraftPack(schemaVersion:1,fetchedAt:"fixture",sourceURL:mode.sourceURL,players:players,formations:[DraftFormation(id:"test",positions:positions,rows:[Array(0..<11)])],modes:[mode])
        let engine=DraftEngine(pack:pack,mode:mode)
        var board=try XCTUnwrap(engine.make(formationID:"test",randomized:false))
        XCTAssertTrue(engine.place("p0",at:0,on:&board))
        XCTAssertNil(engine.solution(board));XCTAssertTrue(engine.valid(board))
        let saved=GameResume(signature:engine.signature,sessionID:UUID(),draft:board)
        board=try XCTUnwrap(engine.restore(saved,completedSessions:[]))
        board.undo();XCTAssertNotNil(engine.solution(board))
        XCTAssertTrue(engine.place("p0",at:1,on:&board));XCTAssertNotNil(engine.solution(board))
    }
    func testCompletingDraftWithHintsOnlyAwardsOneGameAndDoesNotGradeRecall() throws {
        for kind in ["draft-nations","draft-clubs","draft-retro","draft-legends","draft-america","connections","impostor","wordle"] {
            var state=LearnerState();let session=UUID(),now=Date(timeIntervalSince1970:1800000000)
            XCTAssertTrue(state.completeGame(id:session,kind:kind,count:11,now:now))
            XCTAssertFalse(state.completeGame(id:session,kind:kind,count:11,now:now))
            XCTAssertEqual(state.sessions.count,1);XCTAssertTrue(state.reviews.isEmpty)
        }
        var state=LearnerState()
        XCTAssertFalse(state.completeGame(id:UUID(),kind:"invented",count:11,now:Date()))
        XCTAssertFalse(state.completeGame(id:UUID(),kind:"draft-nations",count:0,now:Date()))
    }
}
