import Foundation

public enum SoundAsset: String, CaseIterable, Identifiable, Sendable {
    case levelUp="level-up",wrong,gameOver="game-over",interface="ui-interface",success,smallWin="small-win",sadTrumpet="sad-trumpet",smallDefeat="small-defeat"
    public var id: String {rawValue}
    public var title: String {switch self {case .levelUp:"Level up";case .wrong:"Wrong answer";case .gameOver:"Game over";case .interface:"Interface";case .success:"Success";case .smallWin:"Small win";case .sadTrumpet:"Sad trumpet";case .smallDefeat:"Small setback"}}
    public var usage: String {switch self {case .levelUp:"Completed session, new card or earned tier";case .wrong:"Answer to try again";case .gameOver,.sadTrumpet:"Available for future game modes";case .interface:"Card reveal, clue reveal or skip";case .success:"Correct lesson or recall answer";case .smallWin:"Mini-game connection or matching pair";case .smallDefeat:"Mini-game move to try again"}}
    public var volume: Float {switch self {case .interface:0.2;case .wrong,.smallDefeat:0.28;case .smallWin:0.35;default:0.45}}
    public var maximumFeedbackDuration: Double? {switch self {case .interface:0.24;case .wrong,.smallDefeat:0.9;case .levelUp:2.8;default:nil}}
}
public enum SoundEvent: Sendable {
    case reveal,correct,connection,incorrect,mismatch,completion,unlock
    public var asset: SoundAsset {switch self {case .reveal:.interface;case .correct:.success;case .connection:.smallWin;case .incorrect:.wrong;case .mismatch:.smallDefeat;case .completion:.levelUp;case .unlock:.levelUp}}
}
