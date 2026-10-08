import XCTest
@testable import FoxlingoCore
final class SoundAssetTests: XCTestCase {
    func testEveryCatalogClipIsBundledUnmodifiedAndFeedbackFitsItsProfile() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        for asset in SoundAsset.allCases {
            let original=try Data(contentsOf:root.appendingPathComponent("sounds/\(asset.rawValue).mp3"))
            let bundled=try Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/Sounds/\(asset.rawValue).mp3"))
            XCTAssertEqual(bundled,original);XCTAssertGreaterThan(bundled.count,1000)
            XCTAssertGreaterThan(asset.volume,0);XCTAssertLessThanOrEqual(asset.volume,1)
            if let duration=asset.maximumFeedbackDuration {XCTAssertGreaterThan(duration,0)}
        }
        XCTAssertEqual(SoundEvent.correct.asset,.success)
        XCTAssertEqual(SoundEvent.connection.asset,.smallWin)
        XCTAssertEqual(SoundEvent.mismatch.asset,.smallDefeat)
        XCTAssertEqual(SoundEvent.completion.asset,.levelUp)
        // Ordinary mistakes have a short retry cue rather than an end-of-game event.
        XCTAssertNotEqual(SoundEvent.incorrect.asset,.gameOver)
        XCTAssertNotEqual(SoundEvent.mismatch.asset,.sadTrumpet)
        XCTAssertLessThan(SoundEvent.reveal.asset.maximumFeedbackDuration!,0.5)
    }
}
