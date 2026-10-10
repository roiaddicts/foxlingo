import Foundation

public struct DailyBingoRetro:Sendable {
    public let players:[GamePlayer]
    public let categories:[GameCategory]
    public let signature:String
    public func player(_ id:String)->GamePlayer? {players.first {$0.id == id}}
    public func accepts(_ player:String,category:String)->Bool {categories.first {$0.id == category}?.playerIDs.contains(player) == true}
    static func load(root:[String:Any]) throws -> Self? {
        guard let game=(root["games"] as? [[String:Any]])?.first(where:{$0["id"] as? String == "bingo-retro"}),let selection=game["selection"] as? [String:Any],let catalog=selection["catalog"] as? [String:Any] else {return nil}
        guard let module=game["sourceModule"] as? String,catalog["playerSourceURL"] as? String == module,catalog["boardDate"] as? String == root["gameDate"] as? String,
              let tables=root["datasets"] as? [[String:Any]],let table=tables.first(where:{$0["sourceURL"] as? String == module && Set($0["fields"] as? [String] ?? []) == ["id","name","image","groups"]}),let rows=table["data"] as? [[String:Any]],
              let groups=catalog["groups"] as? [[String:Any]],let selected=selection["groups"] as? [[String:Any]],selected.count == 12 else {throw DailySource.failure()}
        var players:[GamePlayer]=[],members:[Int:Set<Int>]=[:],known:Set<Int>=[]
        for row in rows {
            guard let id=row["id"] as? Int,id > 0,known.insert(id).inserted,let name=row["name"] as? String,!name.isEmpty,let image=row["image"] as? String,let ids=row["groups"] as? [Int],!ids.isEmpty,ids.allSatisfy({$0 > 0}),Set(ids).count == ids.count else {throw DailySource.failure()}
            players.append(GamePlayer(id:"daily-bingo-retro-\(id)",name:name,aliases:[name],imageURL:try DailySource.image(image),imageAsset:nil));members[id]=Set(ids)
        }
        guard !players.isEmpty else {throw DailySource.failure()}
        var groupByID:[Int:[String:Any]]=[:]
        let types:Set<String>=["club","club2","country","award","continent","other"]
        for group in groups {
            guard Set(group.keys) == ["id","name","logo","type"],let id=group["id"] as? Int,id > 0,groupByID[id] == nil,let type=group["type"] as? String,types.contains(type),let name=group["name"] as? String,!name.isEmpty,let logo=group["logo"] as? String else {throw DailySource.failure()}
            _ = try DailySource.image(logo);groupByID[id]=group
        }
        var categories:[GameCategory]=[],counts:[String:Int]=[:],ids:Set<Int>=[]
        for group in selected {
            guard let id=group["id"] as? Int,ids.insert(id).inserted,let original=groupByID[id],NSDictionary(dictionary:original).isEqual(to:group),let type=group["type"] as? String,let name=group["name"] as? String,let logo=group["logo"] as? String else {throw DailySource.failure()}
            let eligible=players.filter {members[Int($0.id.split(separator:"-").last!)!]!.contains(id)}.map(\.id)
            guard !eligible.isEmpty else {throw DailySource.failure()}
            counts[type,default:0] += 1
            categories.append(GameCategory(id:"daily-bingo-retro-group-\(id)",title:name,playerIDs:eligible,imageAsset:nil,imageURL:try DailySource.image(logo),flag:nil))
        }
        guard counts == ["club":4,"club2":2,"country":3,"award":1,"continent":1,"other":1] else {throw DailySource.failure()}
        // Source memberships may contain retired category IDs. Only the reviewed
        // selected categories are playable; unknown historical IDs imply no facts.
        let data=try JSONSerialization.data(withJSONObject:["date":root["gameDate"]!,"zone":root["timeZone"]!,"selection":selection,"players":rows],options:.sortedKeys)
        return Self(players:players,categories:categories,signature:ContentUpdateRules.digest(data))
    }
}
public struct BingoRetroMistake:Codable,Equatable,Sendable {public let playerID:String;public let categoryID:String}
public enum BingoRetroStatus:String,Codable,Sendable {case ready,playing,won,lost}
public struct BingoRetroProgress:Codable,Sendable {
    public let signature:String
    public let sessionID:UUID
    public var status:BingoRetroStatus = .ready
    public var timer:Int = 0
    public var deadline:Date?
    public var placements:[String:String]=[:]
    public var currentPlayerID:String?
    public var skipsSinceHelp:Int = 0
    public var helpThreshold:Int = 5
    public var mistakes:[BingoRetroMistake]=[]
    public var reviewRecorded:Bool = false
    public init(round:DailyBingoRetro,sessionID:UUID=UUID()) {signature=round.signature;self.sessionID=sessionID}
    public var finished:Bool {status == .won || status == .lost}
    public func remaining(at now:Date)->Int? {deadline.map {Int(max(0,min(Double(timer),ceil($0.timeIntervalSince(now)))))}}
    public func valid(for round:DailyBingoRetro)->Bool {
        guard signature == round.signature,[0,60,90].contains(timer),(5...12).contains(helpThreshold),(0..<helpThreshold).contains(skipsSinceHelp),placements.allSatisfy({round.accepts($0.value,category:$0.key)}),placements.count <= 12,
              mistakes.count <= 250,mistakes.allSatisfy({mistake in round.player(mistake.playerID) != nil && round.categories.contains(where:{$0.id == mistake.categoryID}) && !round.accepts(mistake.playerID,category:mistake.categoryID)}),
              currentPlayerID.map({round.player($0) != nil}) ?? (status == .ready),!reviewRecorded || finished else {return false}
        if status == .ready {return timer == 0 && deadline == nil && placements.isEmpty && mistakes.isEmpty && currentPlayerID == nil}
        guard (timer == 0 && deadline == nil) || (timer != 0 && deadline?.timeIntervalSince1970.isFinite == true) else {return false}
        switch status {case .ready:return false;case .playing:return placements.count < 12;case .won:return placements.count == 12;case .lost:return timer != 0 && placements.count < 12}
    }
    @discardableResult public mutating func start<R:RandomNumberGenerator>(round:DailyBingoRetro,timer:Int,now:Date,rng:inout R)->Bool {
        guard valid(for:round),status == .ready,[0,60,90].contains(timer) else {return false}
        self.timer=timer;deadline=timer == 0 ? nil:now.addingTimeInterval(Double(timer));status = .playing
        currentPlayerID=round.players.randomElement(using:&rng)!.id;helpThreshold=Int.random(in:5...12,using:&rng);return true
    }
    @discardableResult public mutating func expire(at now:Date)->Bool {
        guard status == .playing,let deadline,now >= deadline else {return false};status = .lost;return true
    }
    @discardableResult public mutating func place<R:RandomNumberGenerator>(category:String,in round:DailyBingoRetro,now:Date,rng:inout R)->Bool {
        guard valid(for:round),!expire(at:now),status == .playing,placements[category] == nil,let currentPlayerID,round.categories.contains(where:{$0.id == category}) else {return false}
        guard round.accepts(currentPlayerID,category:category) else {
            let mistake=BingoRetroMistake(playerID:currentPlayerID,categoryID:category)
            if !mistakes.contains(mistake),mistakes.count < 250 {mistakes.append(mistake)}
            return false
        }
        placements[category]=currentPlayerID;skipsSinceHelp=0
        if placements.count == 12 {status = .won} else {self.currentPlayerID=round.players.randomElement(using:&rng)!.id}
        return true
    }
    @discardableResult public mutating func skip<R:RandomNumberGenerator>(in round:DailyBingoRetro,now:Date,rng:inout R)->Bool {
        guard valid(for:round),!expire(at:now),status == .playing else {return false}
        skipsSinceHelp += 1
        let pool:[GamePlayer]
        if skipsSinceHelp == helpThreshold {
            let open=round.categories.filter {placements[$0.id] == nil}
            let eligible=Set(open.flatMap(\.playerIDs));pool=round.players.filter {eligible.contains($0.id)}
            skipsSinceHelp=0;helpThreshold=Int.random(in:5...12,using:&rng)
        } else {pool=round.players}
        currentPlayerID=pool.randomElement(using:&rng)!.id;return true
    }
}
extension DailyChallengeCache {
    public func progress(for round:DailyBingoRetro)->BingoRetroProgress? {
        guard let data=try? Data(contentsOf:bingoRetroURL(round)),let p=try? JSONDecoder().decode(BingoRetroProgress.self,from:data),p.valid(for:round) else {return nil};return p
    }
    public func save(_ p:BingoRetroProgress,for round:DailyBingoRetro) throws {
        guard p.valid(for:round) else {throw DailySource.failure()};try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true);try JSONEncoder().encode(p).write(to:bingoRetroURL(round),options:.atomic)
    }
    private func bingoRetroURL(_ round:DailyBingoRetro)->URL {directory.appendingPathComponent("bingo-retro-"+round.signature+".json")}
}
