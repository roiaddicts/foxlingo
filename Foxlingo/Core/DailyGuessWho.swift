import Foundation

public struct GuessWhoOption: Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let imageURL: String?
    public let imageAsset: String?
    public let countryID: Int?
}
public enum GuessWhoTopic: String, Codable, CaseIterable, Sendable {
    case club,league,country,position,age,height,pastClub,pastLeague
    public var title: String {switch self {case .club:"Club";case .league:"League";case .country:"Nationality";case .position:"Position";case .age:"Age";case .height:"Height";case .pastClub:"Past clubs";case .pastLeague:"Past leagues"}}
    public var icon: String {switch self {case .club,.pastClub:"shield.fill";case .league,.pastLeague:"trophy.fill";case .country:"flag.fill";case .position:"sportscourt.fill";case .age:"birthday.cake.fill";case .height:"ruler.fill"}}
}
public enum GuessWhoComparison: String, Codable, CaseIterable, Sendable {case equal,greater,less}
public struct GuessWhoQuestion: Codable, Hashable, Sendable {
    public let topic: GuessWhoTopic
    public let value: Int
    public let comparison: GuessWhoComparison
    public init(_ topic: GuessWhoTopic,value: Int,comparison: GuessWhoComparison = .equal) {self.topic=topic;self.value=value;self.comparison=comparison}
}
public struct DailyGuessWho: Sendable {
    public static let positions=["Goalkeeper","Defender","Midfielder","Forward"]
    public let answer: GamePlayer
    public let players: [GamePlayer]
    public let clubs: [GuessWhoOption]
    public let leagues: [GuessWhoOption]
    public let countries: [GuessWhoOption]
    public let currentClub: Int?
    public let country: Int
    public let position: Int
    public let age: Int
    public let height: Int
    public let previousClubs: Set<Int>
    public let previousLeagues: Set<Int>
    public let signature: String
    public func options(_ topic: GuessWhoTopic) -> [GuessWhoOption] {
        switch topic {case .club,.pastClub:clubs;case .league,.pastLeague:leagues;case .country:countries;default:[]}
    }
    public func valid(_ q: GuessWhoQuestion) -> Bool {
        if q.topic == .age {return (15...60).contains(q.value)}
        if q.topic == .height {return (140...220).contains(q.value)}
        guard q.comparison == .equal else {return false}
        return q.topic == .position ? Self.positions.indices.contains(q.value):options(q.topic).contains {$0.id == q.value}
    }
    /// "No" describes this supplied snapshot; it is not a complete career claim.
    public func response(_ q: GuessWhoQuestion) -> Bool? {
        guard valid(q) else {return nil}
        switch q.topic {
        case .club:return currentClub.map {$0 == q.value}
        case .league:return clubs.first {$0.id == currentClub}?.countryID.map {$0 == q.value}
        case .country:return country == q.value
        case .position:return position == q.value
        case .age,.height:
            let actual=q.topic == .age ? age:height
            switch q.comparison {case .equal:return actual == q.value;case .greater:return actual > q.value;case .less:return actual < q.value}
        case .pastClub:return previousClubs.contains(q.value) || currentClub == q.value
        case .pastLeague:
            return previousLeagues.contains(q.value) || clubs.contains {($0.id == currentClub || previousClubs.contains($0.id)) && $0.countryID == q.value}
        }
    }
    public func text(_ q: GuessWhoQuestion) -> String {
        let label=options(q.topic).first {$0.id == q.value}?.name ?? ""
        switch q.topic {
        case .club:return "Snapshot club: "+label+"?"
        case .league:return "Snapshot league: "+label+"?"
        case .country:return "Nationality: "+label+"?"
        case .pastClub:return "Listed career includes "+label+"?"
        case .pastLeague:return "Listed career includes "+label+"?"
        case .position:return "Position: "+Self.positions[q.value]+"?"
        case .age:return "Age \(q.comparison == .equal ? "exactly":q.comparison == .greater ? "over":"under") \(q.value)?"
        case .height:return "Height \(q.comparison == .equal ? "exactly":q.comparison == .greater ? "over":"under") \(q.value) cm?"
        }
    }
    static func load(root: [String:Any],general: [GamePlayer]) throws -> Self? {
        guard let game=(root["games"] as? [[String:Any]])?.first(where:{$0["id"] as? String == "guesswho"}),let selection=game["selection"] as? [String:Any],let catalog=selection["catalog"] as? [String:Any] else {return nil}
        let (record,_)=try DailySource.selection("guesswho",root:root)
        guard let id=record["id"] as? Int,let sec=record["secID"] as? Int,let height=record["height"] as? Int,(140...220).contains(height),
              let positionName=record["position"] as? String,let position=positions.firstIndex(of:positionName),let birthday=record["birthday"] as? String,
              let url=catalog["playerSourceURL"] as? String,let tables=root["datasets"] as? [[String:Any]],
              let rows=tables.first(where:{$0["sourceURL"] as? String == url})?["data"] as? [[String:Any]],
              Set(tables.first(where:{$0["sourceURL"] as? String == url})?["fields"] as? [String] ?? []) == ["id","clubID","firstName","lastName","nickname","positions"],
              let map=catalog["portraitPlayerIDs"] as? [String:Int],map[String(id)] == sec,
              let sourcePlayer=rows.first(where:{$0["id"] as? Int == id}),let generalPlayer=general.first(where:{$0.id == "daily-general-\(sec)"}),
              let clubRows=catalog["clubs"] as? [[String:Any]],let leagueRows=catalog["leagues"] as? [[String:Any]],
              let zone=TimeZone(identifier:root["timeZone"] as! String) else {throw DailySource.failure()}
        let flags=try DailySource.table(["id","name","flag","bgColor"],root:root)
        let generalRows=try DailySource.table(["id","firstName","lastName","nickname","image","countryID","grid","bingo"],root:root)
        guard let country=generalRows.first(where:{$0["id"] as? Int == sec})?["countryID"] as? Int else {throw DailySource.failure()}
        var countries:[GuessWhoOption]=[]
        for row in flags {guard let i=row["id"] as? Int,let name=row["name"] as? String,let image=row["flag"] as? String else {throw DailySource.failure()};countries.append(GuessWhoOption(id:i,name:name,imageURL:try DailySource.image(image),imageAsset:nil,countryID:nil))}
        let localBadges=["Bayern Munich":"bayern-munich","Dortmund":"borussia-dortmund","RB Leipzig":"rb-leipzig","Bayer Leverkusen":"bayer-leverkusen","Frankfurt":"eintracht-frankfurt"]
        var clubs:[GuessWhoOption]=[],leagues:[GuessWhoOption]=[]
        for row in clubRows {
            guard let i=row["id"] as? Int,let name=row["name"] as? String,let country=row["countryID"] as? Int,countries.contains(where:{$0.id == country}) else {throw DailySource.failure()}
            clubs.append(GuessWhoOption(id:i,name:name,imageURL:try (row["image"] as? String).map(DailySource.image),imageAsset:localBadges[name].map {"entity-"+$0},countryID:country))
        }
        for row in leagueRows {guard let i=row["id"] as? Int,let name=row["name"] as? String,let flag=countries.first(where:{$0.id == i}) else {throw DailySource.failure()};leagues.append(GuessWhoOption(id:i,name:name,imageURL:flag.imageURL,imageAsset:nil,countryID:i))}
        let sourceRows=try DailySource.table(["id","name","position","previousClubs","previousLeagues","height","birthday","secID"],root:root)
        let generalMap=Dictionary(uniqueKeysWithValues:general.map {($0.id,$0)})
        func fullName(_ row:[String:Any]) -> String {
            guard let first=row["firstName"] as? String,!first.trimmingCharacters(in:.whitespaces).isEmpty,let last=row["lastName"] as? String,!last.trimmingCharacters(in:.whitespaces).isEmpty else {return ""}
            return (first+" "+last).lowercased().split(whereSeparator:{$0.isWhitespace}).joined(separator:" ")
        }
        let playerNames=Dictionary(grouping:rows,by:fullName),generalNames=Dictionary(grouping:generalRows,by:fullName)
        for (raw,target) in map {
            guard let rawID=Int(raw),let candidate=rows.first(where:{$0["id"] as? Int == rawID}),generalMap["daily-general-\(target)"] != nil else {throw DailySource.failure()}
            if !sourceRows.contains(where:{$0["id"] as? Int == rawID && $0["secID"] as? Int == target}) {
                let name=fullName(candidate)
                guard !name.isEmpty,playerNames[name]?.count == 1,generalNames[name]?.count == 1,generalNames[name]?[0]["id"] as? Int == target else {throw DailySource.failure()}
            }
        }
        var players:[GamePlayer]=[]
        for row in rows {
            guard let i=row["id"] as? Int else {throw DailySource.failure()}
            let full=((row["firstName"] as? String ?? "")+" "+(row["lastName"] as? String ?? "")).trimmingCharacters(in:.whitespaces)
            let name=full.isEmpty ? row["nickname"] as? String ?? "":full
            guard !name.isEmpty else {throw DailySource.failure()}
            let portrait=map[String(i)].flatMap {generalMap["daily-general-\($0)"]}
            players.append(GamePlayer(id:"daily-guesswho-\(i)",name:name,aliases:[name,row["nickname"] as? String ?? ""].filter {!$0.isEmpty},imageURL:portrait?.imageURL,imageAsset:nil))
        }
        guard Set(players.map(\.id)).count == players.count,let answer=players.first(where:{$0.id == "daily-guesswho-\(id)"}),answer.imageURL == generalPlayer.imageURL,
              Set(clubs.map(\.id)).count == clubs.count,Set(leagues.map(\.id)).count == leagues.count else {throw DailySource.failure()}
        let formatter=DateFormatter();formatter.locale=Locale(identifier:"en_US_POSIX");formatter.timeZone=zone;formatter.dateFormat="M/d/yyyy";formatter.isLenient=false
        guard let born=formatter.date(from:birthday) else {throw DailySource.failure()}
        formatter.dateFormat="yyyy-MM-dd";guard let date=formatter.date(from:root["gameDate"] as! String),born < date else {throw DailySource.failure()}
        var utc=Calendar(identifier:.gregorian);utc.timeZone=TimeZone(secondsFromGMT:0)!
        let age=abs(utc.component(.year,from:Date(timeIntervalSince1970:date.timeIntervalSince(born)))-1970)
        guard (15...60).contains(age) else {throw DailySource.failure()}
        func listed(_ key:String) throws -> Set<Int> {
            guard let value=record[key] as? String,!value.trimmingCharacters(in:.whitespaces).isEmpty else {return []};return Set(try DailySource.ids(value))
        }
        let past=try listed("previousClubs"),pastLeagues=try listed("previousLeagues")
        guard past.isSubset(of:Set(clubs.map(\.id))),pastLeagues.isSubset(of:Set(leagues.map(\.id))),countries.contains(where:{$0.id == country}) else {throw DailySource.failure()}
        let portraitIDs=Set(map.values)
        let identity: [String:Any]=["version":1,"date":root["gameDate"]!,"zone":root["timeZone"]!,"record":record,"catalog":catalog,"players":rows,"flags":flags,"portraits":generalRows.filter {portraitIDs.contains($0["id"] as? Int ?? -1)}]
        let signature=ContentUpdateRules.digest(try JSONSerialization.data(withJSONObject:identity,options:.sortedKeys))
        return Self(answer:answer,players:players,clubs:clubs,leagues:leagues,countries:countries,currentClub:sourcePlayer["clubID"] as? Int,country:country,position:position,age:age,height:height,previousClubs:past,previousLeagues:pastLeagues,signature:signature)
    }
}
public struct GuessWhoProgress: Codable, Sendable {
    public let signature: String
    public let sessionID: UUID
    public var questions: [GuessWhoQuestion] = []
    public var guesses: [String] = []
    public var gaveUp=false
    public var reviewRecorded=false
    public init(round:DailyGuessWho) {signature=round.signature;sessionID=UUID()}
    public func won(_ round:DailyGuessWho) -> Bool {guesses.last == round.answer.id}
    public func finished(_ round:DailyGuessWho) -> Bool {gaveUp || won(round) || guesses.count == 3}
    public func valid(for round:DailyGuessWho) -> Bool {
        signature == round.signature && questions.count <= 10 && Set(questions).count == questions.count && questions.allSatisfy(round.valid) && guesses.count <= 3 && Set(guesses).count == guesses.count && Set(guesses).isSubset(of:Set(round.players.map(\.id))) && !guesses.dropLast().contains(round.answer.id) && !(gaveUp && won(round)) && (!reviewRecorded || finished(round))
    }
    @discardableResult public mutating func ask(_ q:GuessWhoQuestion,in round:DailyGuessWho) -> Bool {guard valid(for:round),!finished(round),questions.count < 10,round.valid(q),!questions.contains(q) else {return false};questions.append(q);return true}
    @discardableResult public mutating func guess(_ id:String,in round:DailyGuessWho) -> Bool {guard valid(for:round),!finished(round),round.players.contains(where:{$0.id == id}),!guesses.contains(id) else {return false};guesses.append(id);return true}
    @discardableResult public mutating func reveal(in round:DailyGuessWho) -> Bool {guard valid(for:round),!finished(round) else {return false};gaveUp=true;return true}
}
extension DailyChallengeCache {
    public func progress(for round:DailyGuessWho) -> GuessWhoProgress? {guard let data=try? Data(contentsOf:guessWhoURL(round)),let value=try? JSONDecoder().decode(GuessWhoProgress.self,from:data),value.valid(for:round) else {return nil};return value}
    public func save(_ value:GuessWhoProgress,for round:DailyGuessWho) throws {guard value.valid(for:round) else {throw DailySource.failure()};try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true);try JSONEncoder().encode(value).write(to:guessWhoURL(round),options:.atomic)}
    private func guessWhoURL(_ round:DailyGuessWho) -> URL {directory.appendingPathComponent("guesswho-"+round.signature+".json")}
}
