import Foundation

public enum DailyWordleDifficulty:String,Codable,CaseIterable,Sendable {case normal,easy}
public struct DailyWordle:Sendable {
    public let answer:String
    public let accepted:Set<String>
    public let matchingPlayers:[GamePlayer]
    public let signature:String
    public static func letters(_ text:String)->Bool {!text.isEmpty && text.allSatisfy {$0.isASCII && $0 >= "A" && $0 <= "Z"}}
    public func accepts(_ word:String,mode:DailyWordleDifficulty)->Bool {word.count == answer.count && Self.letters(word) && (mode == .easy || accepted.contains(word))}
    public func keyMark(_ letter:Character,guesses:[String])->LetterMark? {
        var best:LetterMark?
        for guess in guesses {
            guard let marks=FootballWordle.feedback(guess:guess,answer:answer) else {continue}
            for (i,c) in guess.enumerated() where c == letter {
                if marks[i] == .correct {return .correct}
                if marks[i] == .present || best == nil {best=marks[i]}
            }
        }
        return best
    }
    static func load(root:[String:Any],general:[GamePlayer]) throws -> Self? {
        guard let game=(root["games"] as? [[String:Any]])?.first(where:{$0["id"] as? String == "wordle"}),let selection=game["selection"] as? [String:Any],let catalog=selection["catalog"] as? [String:Any] else {return nil}
        guard let answer=selection["answer"] as? String,let index=selection["index"] as? Int,index == root["dayOfYear"] as? Int,
              let words=catalog["words"] as? [String],words.indices.contains(index),words[index] == answer,words.allSatisfy({(4...7).contains($0.count) && letters($0)}),
              let url=catalog["sourceURL"] as? String,let digest=catalog["assetSHA256"] as? String,digest.range(of:"^[a-f0-9]{64}$",options:.regularExpression) != nil,
              let playerURL=catalog["playerSourceURL"] as? String,let tables=root["datasets"] as? [[String:Any]],let table=tables.first(where:{$0["sourceURL"] as? String == playerURL && Set($0["fields"] as? [String] ?? []) == ["bingo","countryID","firstName","grid","id","image","lastName","nickname"]}),let rows=table["data"] as? [[String:Any]] else {throw DailySource.failure()}
        _ = try ContentUpdateRules.https(url)
        var accepted=Set(words),matching:Set<String>=[]
        for row in rows {
            guard let id=row["id"] as? Int else {throw DailySource.failure()}
            for key in ["firstName","lastName","nickname"] {
                if let raw=row[key] as? String {
                    // Source normal mode compares a whole field uppercased. It
                    // does not split names, remove accents or strip punctuation.
                    let word=raw.uppercased()
                    if letters(word) {accepted.insert(word)}
                    if word == answer {matching.insert("daily-general-\(id)")}
                }
            }
        }
        let players=general.filter {matching.contains($0.id)}
        guard Set(players.map(\.id)) == matching else {throw DailySource.failure()}
        let bytes=try JSONSerialization.data(withJSONObject:["date":root["gameDate"]!,"zone":root["timeZone"]!,"selection":selection,"accepted":accepted.sorted(),"players":players.map {[$0.id,$0.name,$0.imageURL ?? ""]}],options:.sortedKeys)
        return Self(answer:answer,accepted:accepted,matchingPlayers:players,signature:ContentUpdateRules.digest(bytes))
    }
}
public struct DailyWordleProgress:Codable,Sendable {
    public let signature:String
    public let sessionID:UUID
    public var mode:DailyWordleDifficulty = .normal
    public var guesses:[String]=[]
    public var input:String=""
    public var reviewRecorded:Bool=false
    public init(round:DailyWordle,sessionID:UUID=UUID()) {signature=round.signature;self.sessionID=sessionID}
    public func won(_ round:DailyWordle)->Bool {guesses.last == round.answer}
    public func finished(_ round:DailyWordle)->Bool {won(round) || guesses.count == 6}
    public func valid(for round:DailyWordle)->Bool {
        guard signature == round.signature,guesses.count <= 6,guesses.allSatisfy({round.accepts($0,mode:mode)}),!guesses.dropLast().contains(round.answer),input.count <= round.answer.count,(input.isEmpty || DailyWordle.letters(input)),!reviewRecorded || finished(round) else {return false}
        return !finished(round) || input.isEmpty
    }
    @discardableResult public mutating func setMode(_ new:DailyWordleDifficulty,in round:DailyWordle)->Bool {guard valid(for:round),guesses.isEmpty else {return false};mode=new;return true}
    @discardableResult public mutating func type(_ letter:Character,in round:DailyWordle)->Bool {guard valid(for:round),!finished(round),input.count < round.answer.count,DailyWordle.letters(String(letter)) else {return false};input.append(letter);return true}
    @discardableResult public mutating func delete(in round:DailyWordle)->Bool {guard valid(for:round),!finished(round),!input.isEmpty else {return false};input.removeLast();return true}
    @discardableResult public mutating func submit(in round:DailyWordle)->Bool {guard valid(for:round),!finished(round),round.accepts(input,mode:mode) else {return false};guesses.append(input);input="";return true}
}
extension DailyChallengeCache {
    public func progress(for round:DailyWordle)->DailyWordleProgress? {guard let data=try? Data(contentsOf:wordleURL(round)),let p=try? JSONDecoder().decode(DailyWordleProgress.self,from:data),p.valid(for:round) else {return nil};return p}
    public func save(_ p:DailyWordleProgress,for round:DailyWordle) throws {guard p.valid(for:round) else {throw DailySource.failure()};try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true);try JSONEncoder().encode(p).write(to:wordleURL(round),options:.atomic)}
    private func wordleURL(_ round:DailyWordle)->URL {directory.appendingPathComponent("daily-wordle-"+round.signature+".json")}
}
