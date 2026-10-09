import Foundation

public enum DailyRevealMode: String, Codable, CaseIterable, Sendable {
    case statdle, legacy, link
    public var title: String {switch self {case .statdle:"Statdle";case .legacy:"Football Legacy";case .link:"Football Link"}}
    public var instruction: String {switch self {case .statdle:"Identify the player from this season’s stats.";case .legacy:"Who played for all four clubs?";case .link:"Who shared the pitch with these five players?"}}
    public var limit: Int {self == .legacy ? 4:5}
    public var revealStep: Int {self == .statdle ? 2:1}
}
public enum RevealDifficulty: String, Codable, Sendable {case normal, hard}
public struct DailyClue: Codable, Identifiable, Sendable {
    public enum Kind: String, Codable, Sendable {case text, flag, club, player}
    public let id: String
    public let title: String
    public let value: String
    public let imageURL: String?
    public let kind: Kind
}
public struct DailyRevealRound: Sendable {
    public let mode: DailyRevealMode
    public let answer: GamePlayer
    public let players: [GamePlayer]
    public let clues: [DailyClue]
    public let scope: String
    public let signature: String
    public func clueIDs(_ difficulty: RevealDifficulty) -> [String] {
        clues.filter {difficulty != .hard || !["country","club"].contains($0.id)}.map(\.id)
    }
    static func load(root: [String:Any],players: [GamePlayer]) throws -> [DailyRevealRound] {
        // Packages before these adapters remain usable for Top 10.
        guard let support=root["support"] as? [String:Any] else {return []}
        func fail() -> ContentError {.invalid("Daily player clues are incomplete or inconsistent with the source.")}
        guard let clubSupport=support["clubs"] as? [String:Any],let clubs=clubSupport["data"] as? [[String:Any]],
              let games=root["games"] as? [[String:Any]],let datasets=root["datasets"] as? [[String:Any]],
              let date=root["gameDate"] as? String,let zone=root["timeZone"] as? String,let ordinal=root["dayOfYear"] as? Int else {throw fail()}
        let playerMap=Dictionary(uniqueKeysWithValues:players.map {($0.id,$0)})
        func player(_ id: Int) throws -> GamePlayer {
            guard let p=playerMap["daily-general-\(id)"] else {throw fail()};return p
        }
        func image(_ value: String) throws -> String {
            if value.hasPrefix("https://") {return try ContentUpdateRules.https(value).absoluteString}
            guard value.hasPrefix("/"),!value.hasPrefix("//"),!value.contains("..") else {throw fail()}
            return try ContentUpdateRules.https("https://futbol11.com"+value).absoluteString
        }
        func numbers(_ value: String,count: Int) throws -> [Int] {
            let parts=value.split(separator:",",omittingEmptySubsequences:false)
            let ints=parts.compactMap {Int($0.trimmingCharacters(in:.whitespaces))}
            guard ints.count == count,parts.count == count,ints.allSatisfy({$0 >= 0}) else {throw fail()};return ints
        }
        var clubMap:[Int:DailyClue]=[:]
        for c in clubs {
            guard let id=c["id"] as? Int,clubMap[id] == nil,let name=c["lastName"] as? String,!name.isEmpty,let url=c["image"] as? String else {throw fail()}
            clubMap[id]=DailyClue(id:"club-\(id)",title:"Club",value:name,imageURL:url == "DELETE THIS SHIRT IN FOLDER" ? nil:try image(url),kind:.club)
        }
        let flagTables=datasets.filter {Set($0["fields"] as? [String] ?? []) == Set(["bgColor","flag","id","name"])}
        guard flagTables.count == 1,let countries=flagTables[0]["data"] as? [[String:Any]] else {throw fail()}
        var flagMap:[Int:DailyClue]=[:]
        for c in countries {
            guard let id=c["id"] as? Int,flagMap[id] == nil,let name=c["name"] as? String,let url=c["flag"] as? String else {throw fail()}
            flagMap[id]=DailyClue(id:"country-\(id)",title:"Country",value:name,imageURL:try image(url),kind:.flag)
        }
        var result:[DailyRevealRound]=[]
        for mode in DailyRevealMode.allCases {
            guard let game=games.first(where:{$0["id"] as? String == mode.rawValue}),let selection=game["selection"] as? [String:Any],
                  let record=selection["record"] as? [String:Any],let id=record["id"] as? Int,let index=selection["index"] as? Int,index == ordinal,
                  let module=game["sourceModule"] as? String,
                  let table=datasets.first(where:{$0["sourceURL"] as? String == module}),let rows=table["data"] as? [[String:Any]],rows.indices.contains(index),
                  NSDictionary(dictionary:rows[index]).isEqual(to:record) else {throw fail()}
            let answer=try player(id)
            var clues:[DailyClue]=[],scope=""
            switch mode {
            case .legacy:
                guard let csv=record["clubs"] as? String,let order=selection["clueOrder"] as? [Int] else {throw fail()}
                let ids=try numbers(csv,count:4)
                guard Set(ids).count == 4,Set(order) == Set(ids),order.count == 4 else {throw fail()}
                for id in order {guard let clue=clubMap[id] else {throw fail()};clues.append(clue)}
                scope="Four source-listed senior clubs. Clue order is shuffled, not a career timeline."
            case .link:
                guard let csv=record["teammates"] as? String,let order=selection["clueOrder"] as? [Int] else {throw fail()}
                let ids=try numbers(csv,count:5)
                guard Set(ids).count == 5,Set(order) == Set(ids),order.count == 5,!ids.contains(id) else {throw fail()}
                for id in order {
                    let p=try player(id)
                    clues.append(DailyClue(id:p.id,title:"Teammate",value:p.name,imageURL:p.imageURL,kind:.player))
                }
                scope="Source-authored senior teammate connections. Clues can span clubs and national teams; they are not in chronological order."
            case .statdle:
                guard let info=record["info"] as? String else {throw fail()}
                let fields=info.split(separator:";",omittingEmptySubsequences:false).map(String.init)
                guard fields.count == 7 else {throw fail()}
                let season=fields[2].split(separator:",",omittingEmptySubsequences:false)
                guard season.count == 2,season[0].range(of:"^[0-9]{4}/[0-9]{2}$",options:.regularExpression) != nil,
                      let leagueCountry=Int(season[1]),let leagueFlag=flagMap[leagueCountry] else {throw fail()}
                let stats=try numbers(fields[3],count:3),profile=try numbers(fields[1],count:2),teams=try numbers(fields[5],count:2)
                guard let country=flagMap[teams[0]],let club=clubMap[teams[1]],let position=["G":"Goalkeeper","D":"Defender","M":"Midfielder","F":"Forward"][fields[4]] else {throw fail()}
                let leagues=["England":"Premier League","Italy":"Serie A","Spain":"LaLiga","France":"Ligue 1","Netherlands":"Eredivisie","Portugal":"Liga Portugal","Turkey":"Süper Lig"]
                clues.append(DailyClue(id:"season",title:String(season[0]),value:leagues[leagueFlag.value] ?? leagueFlag.value,imageURL:leagueFlag.imageURL,kind:.flag))
                for (i,label) in ["Appearances","Goals","Assists"].enumerated() {clues.append(DailyClue(id:["apps","goals","assists"][i],title:label,value:String(stats[i]),imageURL:nil,kind:.text))}
                clues += [DailyClue(id:"position",title:"Position",value:position,imageURL:nil,kind:.text),DailyClue(id:"country",title:"Nationality",value:country.value,imageURL:country.imageURL,kind:.flag),DailyClue(id:"age",title:"Age that season",value:String(profile[1]),imageURL:nil,kind:.text),DailyClue(id:"value",title:"Value that season",value:"€\(profile[0])M",imageURL:nil,kind:.text),DailyClue(id:"club",title:"Club",value:club.value,imageURL:club.imageURL,kind:.club)]
                scope="Season \(season[0]) · Source-listed league appearances, goals, assists, age and valuation. These are historical clues, not live player stats."
            }
            let signature=ContentUpdateRules.digest(ContentUpdateRules.bytes(["daily-reveal-v1",mode.rawValue,date,zone,answer.id,answer.name,answer.imageURL ?? "",scope]+clues.flatMap {[$0.id,$0.title,$0.value,$0.imageURL ?? "",$0.kind.rawValue]}))
            result.append(Self(mode:mode,answer:answer,players:players,clues:clues,scope:scope,signature:signature))
        }
        return result
    }
}
public struct RevealAttempt: Codable, Sendable {public let playerID: String?}
public struct DailyRevealProgress: Codable, Sendable {
    public enum Outcome: String, Sendable {case playing,won,lost}
    public let signature: String
    public let sessionID: UUID
    public let difficulty: RevealDifficulty
    public let order: [String]
    public var attempts: [RevealAttempt] = []
    public var reviewRecorded=false
    public init(round: DailyRevealRound,difficulty: RevealDifficulty = .normal,randomized: Bool = true) {
        signature=round.signature;sessionID=UUID();self.difficulty=round.mode == .statdle ? difficulty:.normal
        let ids=round.clueIDs(self.difficulty)
        order=round.mode == .statdle && randomized ? [ids[0]]+Array(ids.dropFirst()).shuffled():ids
    }
    public func outcome(_ round: DailyRevealRound) -> Outcome {
        if attempts.last?.playerID == round.answer.id {return .won}
        return attempts.count >= round.mode.limit ? .lost:.playing
    }
    public func revealed(_ round: DailyRevealRound) -> Set<String> {
        let wrong=attempts.filter {$0.playerID != round.answer.id}.count
        return Set(order.prefix(min(order.count,1+wrong*round.mode.revealStep)))
    }
    public func valid(for round: DailyRevealRound) -> Bool {
        let ids=round.clueIDs(difficulty),guesses=attempts.compactMap(\.playerID)
        guard signature == round.signature,(round.mode == .statdle || difficulty == .normal),order.count == ids.count,Set(order) == Set(ids),order.first == ids.first,
              (round.mode == .statdle || order == ids),attempts.count <= round.mode.limit,Set(guesses).count == guesses.count,
              Set(guesses).isSubset(of:Set(round.players.map(\.id))),!reviewRecorded || outcome(round) != .playing else {return false}
        return !attempts.dropLast().contains {$0.playerID == round.answer.id}
    }
    /// A skipped turn consumes a chance and reveals clues, just like a wrong guess.
    @discardableResult public mutating func submit(_ id: String?,in round: DailyRevealRound) -> Bool {
        guard valid(for:round),outcome(round) == .playing else {return false}
        if let id {guard round.players.contains(where:{$0.id == id}),!attempts.contains(where:{$0.playerID == id}) else {return false}}
        attempts.append(RevealAttempt(playerID:id));return true
    }
}
extension DailyChallengeCache {
    public func progress(for round: DailyRevealRound) -> DailyRevealProgress? {
        guard let data=try? Data(contentsOf:revealURL(round)),let progress=try? JSONDecoder().decode(DailyRevealProgress.self,from:data),progress.valid(for:round) else {return nil};return progress
    }
    public func save(_ progress: DailyRevealProgress,for round: DailyRevealRound) throws {
        guard progress.valid(for:round) else {throw ContentError.invalid("Invalid player clue progress.")}
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        try JSONEncoder().encode(progress).write(to:revealURL(round),options:.atomic)
    }
    private func revealURL(_ round: DailyRevealRound) -> URL {directory.appendingPathComponent(round.mode.rawValue+"-"+round.signature+".json")}
}
