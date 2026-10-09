import XCTest
@testable import FoxlingoCore
final class FootballWordleTests: XCTestCase {
    func fixture() throws -> GamePack {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try GamePack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/games-en.json")))
    }
    func testRepeatedLettersUseOnlyRemainingTargetCopies() {
        XCTAssertEqual(FootballWordle.feedback(guess:"SENSE",answer:"MESSI"),[.present,.correct,.absent,.correct,.absent])
        XCTAssertEqual(FootballWordle.feedback(guess:"SISSI",answer:"MESSI"),[.absent,.absent,.correct,.correct,.correct])
        XCTAssertNil(FootballWordle.feedback(guess:"PELE",answer:"MESSI"))
        XCTAssertEqual(FootballWordle.name("Pelé"),"PELE")
    }
    func testResumeRejectsDuplicateGuessesMixedPayloadsAndFinishedSessions() throws {
        let pack=try fixture(),player=pack.players.first {$0.name == "Lionel Messi"}!
        let progress=WordleProgress(playerID:player.id,answer:"MESSI",guesses:["RAMOS"]),id=UUID()
        let signature=FootballWordle.signature(player:player,answer:"MESSI")
        let resume=GameResume(signature:signature,sessionID:id,wordle:progress)
        XCTAssertEqual(FootballWordle.restore(resume,pack:pack,completedSessions:[])?.guesses,["RAMOS"])
        XCTAssertNil(FootballWordle.restore(resume,pack:pack,completedSessions:[id]))
        XCTAssertNil(FootballWordle.restore(GameResume(signature:signature,sessionID:id,wordle:WordleProgress(playerID:player.id,answer:"MESSI",guesses:["RAMOS","RAMOS"])),pack:pack,completedSessions:[]))
        XCTAssertNil(FootballWordle.restore(GameResume(signature:signature,sessionID:id,timeline:TimelineProgress(roundID:"x",order:[],checks:0),wordle:progress),pack:pack,completedSessions:[]))
    }
}
