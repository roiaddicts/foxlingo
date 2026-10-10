import Foundation

/// Raw source identifiers stay inside this snapshot's namespace.
public struct DailyTop10: Sendable {
    public let title: String
    public let rankedPlayers: [GamePlayer]
    public let flags: [String]
    public let players: [GamePlayer]
    public let signature: String
    public func rank(of id: String) -> Int? {rankedPlayers.firstIndex {$0.id == id}}
}
public struct DailyChallengePack: Sendable {
    public static let modeIDs: Set<String> = ["top10","statdle","legacy","link","squadslice","guesswho","pyramid","wordle","countries","clubs","retro","legends","america","goltexto","impostor","bingo","bingo-retro","grid","connections"]
    public let gameDate: String
    public let timeZone: String
    public let scope: String
    public let bingoRetro: DailyBingoRetro?
    public let revealRounds: [DailyRevealRound]
    public let goltexto: DailyGoltexto?
    public let guessWho: DailyGuessWho?
    public let pyramid: DailyPyramid
    public let squadSlice: DailySquadSlice?
    public var supportedModeIDs: Set<String> {Set(["top10","pyramid"]+revealRounds.map { $0.mode.rawValue }+(squadSlice == nil ? []:["squadslice"])+(guessWho == nil ? []:["guesswho"])+(goltexto == nil ? []:["goltexto"])+(bingoRetro == nil ? []:["bingo-retro"]))}
    public let top10: DailyTop10
    public let digest: String
    public func isToday(_ date: Date) -> Bool {
        var calendar=Calendar(identifier:.gregorian);calendar.timeZone=TimeZone(identifier:timeZone)!
        let c=calendar.dateComponents([.year,.month,.day],from:date)
        return String(format:"%04d-%02d-%02d",c.year!,c.month!,c.day!) == gameDate
    }
    public static func load(_ data: Data) throws -> Self {
        func fail() -> ContentError {.invalid("This daily challenge file is incomplete or incompatible.")}
        guard data.count <= ContentUpdateRules.maximumBytes,
              let root=try JSONSerialization.jsonObject(with:data) as? [String:Any],root["schemaVersion"] as? Int == 1,
              let date=root["gameDate"] as? String,let zone=root["timeZone"] as? String,TimeZone(identifier:zone) != nil,
              let scope=root["scope"] as? String,!scope.isEmpty,
              let games=root["games"] as? [[String:Any]],games.count == modeIDs.count,
              Set(games.compactMap {$0["id"] as? String}) == modeIDs,
              let datasets=root["datasets"] as? [[String:Any]],
              let game=games.first(where:{$0["id"] as? String == "top10"}),
              let module=game["sourceModule"] as? String,
              let selection=game["selection"] as? [String:Any],let index=selection["index"] as? Int,
              let record=selection["record"] as? [String:Any],let title=record["title"] as? String,!title.isEmpty,
              let csv=record["players"] as? String,
              let table=datasets.first(where:{$0["sourceURL"] as? String == module}),let rows=table["data"] as? [[String:Any]],rows.indices.contains(index),
              NSDictionary(dictionary:rows[index]).isEqual(to:record) else {throw fail()}
        let format=DateFormatter();format.locale=Locale(identifier:"en_US_POSIX");format.timeZone=TimeZone(identifier:zone);format.dateFormat="yyyy-MM-dd";format.isLenient=false
        guard let parsed=format.date(from:date),format.string(from:parsed) == date else {throw fail()}
        var calendar=Calendar(identifier:.gregorian);calendar.timeZone=TimeZone(identifier:zone)!
        let year=calendar.component(.year,from:parsed)
        guard let jan1=calendar.date(from:DateComponents(year:year,month:1,day:1)),let jan0=calendar.date(byAdding:.day,value:-1,to:jan1) else {throw fail()}
        let ordinal=Int(floor(parsed.timeIntervalSince(jan0)/86400+0.5))
        guard root["dayOfYear"] as? Int == ordinal,index == ordinal,root["elapsedDayFloor"] as? Int == Int(floor(parsed.timeIntervalSince(jan0)/86400)) else {throw fail()}

        let ids=csv.split(separator:",").compactMap {Int($0.trimmingCharacters(in:.whitespaces))}
        guard ids.count == 10,Set(ids).count == 10,csv.split(separator:",").count == 10 else {throw fail()}
        let playerTables=datasets.filter {Set($0["fields"] as? [String] ?? []) == Set(["bingo","countryID","firstName","grid","id","image","lastName","nickname"])}
        let flagTables=datasets.filter {Set($0["fields"] as? [String] ?? []) == Set(["bgColor","flag","id","name"])}
        guard playerTables.count == 1,flagTables.count == 1,let playerRows=playerTables[0]["data"] as? [[String:Any]],let flagRows=flagTables[0]["data"] as? [[String:Any]] else {throw fail()}
        var players:[Int:GamePlayer]=[:],countries:[Int:Int]=[:],flags:[Int:String]=[:]
        func image(_ value: String) throws -> String {
            if value.hasPrefix("https://") {return try ContentUpdateRules.https(value).absoluteString}
            guard value.hasPrefix("/"),!value.hasPrefix("//"),!value.contains(".."),let url=URL(string:"https://futbol11.com"+value),url.host == "futbol11.com" else {throw fail()}
            return url.absoluteString
        }
        for row in flagRows {
            guard let id=row["id"] as? Int,flags[id] == nil,let flag=row["flag"] as? String else {throw fail()}
            flags[id]=try image(flag)
        }
        for row in playerRows {
            guard let id=row["id"] as? Int,players[id] == nil,let country=row["countryID"] as? Int else {throw fail()}
            let first=row["firstName"] as? String ?? "",last=row["lastName"] as? String ?? ""
            let full=(first+" "+last).trimmingCharacters(in:.whitespaces)
            let name=full.isEmpty ? row["nickname"] as? String ?? "":full
            guard !name.isEmpty else {throw fail()}
            let aliases=[name,first,last,row["nickname"] as? String ?? ""].filter {!$0.isEmpty}
            players[id]=GamePlayer(id:"daily-general-\(id)",name:name,aliases:aliases,imageURL:try (row["image"] as? String).map(image),imageAsset:nil)
            countries[id]=country
        }
        guard ids.allSatisfy({players[$0] != nil && countries[$0].flatMap {flags[$0]} != nil}) else {throw fail()}
        let digest=ContentUpdateRules.digest(data)
        let signature=ContentUpdateRules.digest(ContentUpdateRules.bytes(["daily-top10-v1",date,zone,title]+ids.flatMap {[String($0),players[$0]!.name,players[$0]!.imageURL ?? "",flags[countries[$0]!]!]}))
        let allPlayers=playerRows.compactMap {($0["id"] as? Int).flatMap {players[$0]}}
        return Self(gameDate:date,timeZone:zone,scope:scope,bingoRetro:try DailyBingoRetro.load(root:root),revealRounds:try DailyRevealRound.load(root:root,players:playerRows.compactMap {($0["id"] as? Int).flatMap {players[$0]}}),goltexto:try DailyGoltexto.load(root:root,general:allPlayers),guessWho:try DailyGuessWho.load(root:root,general:allPlayers),pyramid:try DailyPyramid.load(root:root,players:allPlayers),squadSlice:try DailySquadSlice.load(root:root,players:allPlayers),top10:DailyTop10(title:title,rankedPlayers:ids.map {players[$0]!},flags:ids.map {flags[countries[$0]!]!},players:playerRows.compactMap {($0["id"] as? Int).flatMap {players[$0]}},signature:signature),digest:digest)
    }
}
public struct Top10Progress: Codable, Sendable {
    public let signature: String
    public let sessionID: UUID
    public var found: [String] = []
    public var assisted: Set<String> = []
    public init(signature: String,sessionID: UUID = UUID()) {self.signature=signature;self.sessionID=sessionID}
    public func valid(for round: DailyTop10) -> Bool {
        signature == round.signature && Set(found).count == found.count && Set(found).isSubset(of:Set(round.rankedPlayers.map(\.id))) && assisted.isSubset(of:Set(found))
    }
    @discardableResult public mutating func guess(_ id: String,in round: DailyTop10,helped: Bool = false) -> Bool {
        guard valid(for:round),round.rank(of:id) != nil,!found.contains(id) else {return false}
        found.append(id);if helped {assisted.insert(id)};return true
    }
    public var finished: Bool {found.count == 10}
}
public struct DailyChallengeCache: Sendable {
    public let directory: URL
    public init(directory: URL) {self.directory=directory}
    public func load(bundled: Data) throws -> DailyChallengePack {
        let fallback=try? DailyChallengePack.load(bundled)
        if let saved=try? Data(contentsOf:directory.appendingPathComponent("daily.json")),let pack=try? DailyChallengePack.load(saved) {
            if let fallback,pack.gameDate < fallback.gameDate || (pack.gameDate == fallback.gameDate && pack.supportedModeIDs.isStrictSubset(of:fallback.supportedModeIDs)) {return fallback}
            return pack
        }
        if let fallback {return fallback}
        throw ContentError.invalid("No usable daily challenge set is available.")
    }
    public func install(_ data: Data) throws -> DailyChallengePack {
        let pack=try DailyChallengePack.load(data)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        try data.write(to:directory.appendingPathComponent("daily.json"),options:.atomic)
        return pack
    }
    public func progress(for round: DailyTop10) -> Top10Progress? {
        guard let data=try? Data(contentsOf:progressURL(round)),let progress=try? JSONDecoder().decode(Top10Progress.self,from:data),progress.valid(for:round) else {return nil}
        return progress
    }
    public func save(_ progress: Top10Progress,for round: DailyTop10) throws {
        guard progress.valid(for:round) else {throw ContentError.invalid("Invalid Top 10 progress.")}
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        try JSONEncoder().encode(progress).write(to:progressURL(round),options:.atomic)
    }
    private func progressURL(_ round: DailyTop10) -> URL {directory.appendingPathComponent("top10-"+round.signature+".json")}
}
public struct DailyChallengePointer: Decodable, Sendable {
    public let file: String
    public let sha256: String
    public let gameDate: String
    public let timeZone: String
    public let modes: Int
    public func contentURL(relativeTo pointer: URL) throws -> URL {
        guard file.range(of:"^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-f0-9]{12}\\.json$",options:.regularExpression) != nil,sha256.range(of:"^[a-f0-9]{64}$",options:.regularExpression) != nil,modes == 19,
              file == gameDate+"-"+sha256.prefix(12)+".json" else {throw ContentError.invalid("Invalid daily challenge feed.")}
        return try ContentUpdateRules.https(pointer.deletingLastPathComponent().appendingPathComponent(file).absoluteString)
    }
    public func verify(_ data: Data) throws -> DailyChallengePack {
        guard ContentUpdateRules.digest(data) == sha256 else {throw ContentError.invalid("The daily challenge checksum did not match.")}
        let pack=try DailyChallengePack.load(data)
        guard pack.gameDate == gameDate,pack.timeZone == timeZone else {throw ContentError.invalid("Daily challenge dates did not match the feed.")}
        return pack
    }
}
