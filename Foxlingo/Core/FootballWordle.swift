import Foundation

public enum LetterMark: String, Codable, Sendable {case absent,present,correct}
public enum FootballWordle {
    public static func name(_ value: String) -> String {
        Recall.normalize(value).uppercased().filter { $0.isASCII && $0.isLetter }
    }
    public static func names(_ player: GamePlayer) -> Set<String> {
        Set(player.aliases.flatMap {$0.split(separator:" ").map {name(String($0))}}.filter {(4...8).contains($0.count)})
    }
    public static func feedback(guess: String,answer: String) -> [LetterMark]? {
        let letters=Array(guess),target=Array(answer)
        guard letters.count == target.count else {return nil}
        var result=Array(repeating:LetterMark.absent,count:letters.count),remaining:[Character:Int]=[:]
        for i in target.indices {
            if letters[i] == target[i] {result[i] = .correct}
            else {remaining[target[i],default:0] += 1}
        }
        for i in letters.indices where result[i] != .correct {
            if remaining[letters[i],default:0] > 0 {result[i] = .present;remaining[letters[i],default:0] -= 1}
        }
        return result
    }
    public static func signature(player: GamePlayer,answer: String) -> String {
        ContentUpdateRules.digest(ContentUpdateRules.bytes(["football-wordle-v1",player.id,player.name,answer]))
    }
    public static func restore(_ resume: GameResume,pack: GamePack,completedSessions: Set<UUID>) -> WordleProgress? {
        guard resume.draft == nil,resume.grouping == nil,resume.schemaVersion == 1,!completedSessions.contains(resume.sessionID),resume.board == nil,resume.memory == nil,resume.mystery == nil,resume.timeline == nil,
              let progress=resume.wordle,let player=pack.player(progress.playerID),names(player).contains(progress.answer),
              signature(player:player,answer:progress.answer) == resume.signature,progress.guesses.count < 6,!progress.guesses.contains(progress.answer),
              Set(progress.guesses).count == progress.guesses.count else {return nil}
        let valid=Set(pack.players.flatMap {names($0)})
        guard progress.guesses.allSatisfy({$0.count == progress.answer.count && valid.contains($0)}) else {return nil}
        return progress
    }
}
public struct WordleProgress: Codable, Sendable {
    public let playerID: String
    public let answer: String
    public let guesses: [String]
    public init(playerID: String,answer: String,guesses: [String]) {self.playerID=playerID;self.answer=answer;self.guesses=guesses}
}
