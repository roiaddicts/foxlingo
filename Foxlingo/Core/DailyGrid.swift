import Foundation

public enum DailyGridLevel:String,Codable,CaseIterable,Sendable {case easy,normal,hard,legend}
public struct DailyGridBoard:Sendable {
    public let level:DailyGridLevel
    public let rows:[GameCategory]
    public let columns:[GameCategory]
    public var candidates:[Set<String>] {rows.flatMap {r in columns.map {Set(r.playerIDs).intersection($0.playerIDs)}}}
}
public struct DailyGrid:Sendable {
    public let players:[GamePlayer]
    public let boards:[DailyGridBoard]
    public let signature:String
    public func player(_ id:String)->GamePlayer? {players.first {$0.id == id}}
    public func board(_ level:DailyGridLevel)->DailyGridBoard {boards.first {$0.level == level}!}
    static func load(root:[String:Any],general:[GamePlayer]) throws -> Self? {
        guard let game=(root["games"] as? [[String:Any]])?.first(where:{$0["id"] as? String == "grid"}),let selection=game["selection"] as? [String:Any],let catalog=selection["catalog"] as? [String:Any] else {return nil}
        guard catalog["boardDate"] as? String == root["gameDate"] as? String,let playerURL=catalog["playerSourceURL"] as? String,let groupURL=catalog["categorySourceURL"] as? String,
              let tables=root["datasets"] as? [[String:Any]],let pt=tables.first(where:{$0["sourceURL"] as? String == playerURL && Set($0["fields"] as? [String] ?? []) == ["bingo","countryID","firstName","grid","id","image","lastName","nickname"]}),let playerRows=pt["data"] as? [[String:Any]],
              let gt=tables.first(where:{$0["sourceURL"] as? String == groupURL && Set($0["fields"] as? [String] ?? []) == ["id","logo","name","type"]}),let groups=gt["data"] as? [[String:Any]],let rawBoards=selection["boards"] as? [[String:Any]],rawBoards.count == 4 else {throw DailySource.failure()}
        var memberships:[String:Set<Int>]=[:]
        for row in playerRows {
            guard let id=row["id"] as? Int else {throw DailySource.failure()}
            var ids:Set<Int>=[]
            for field in ["bingo","grid"] {if let csv=row[field] as? String {let pieces=csv.split(separator:",");let values=pieces.compactMap {Int($0.trimmingCharacters(in:.whitespaces))};guard values.count == pieces.count else {throw DailySource.failure()};ids.formUnion(values)}}
            memberships["daily-general-\(id)"]=ids
        }
        guard Set(general.map(\.id)) == Set(memberships.keys) else {throw DailySource.failure()}
        var originals:[Int:[String:Any]]=[:]
        for group in groups {guard let id=group["id"] as? Int,originals[id] == nil else {throw DailySource.failure()};originals[id]=group}
        var boards:[DailyGridBoard]=[],levels:Set<DailyGridLevel>=[]
        for raw in rawBoards {
            guard let name=raw["mode"] as? String,let level=DailyGridLevel(rawValue:name),levels.insert(level).inserted,let rowData=raw["rows"] as? [[String:Any]],let columnData=raw["columns"] as? [[String:Any]],rowData.count == 3,columnData.count == 3 else {throw DailySource.failure()}
            let types:Set<String>
            switch level {case .easy:types=["club","country"];case .normal:types=["club"];case .hard:types=["club","country","country2"];case .legend:types=["club","country","country2","club2"]}
            var ids:Set<Int>=[]
            func category(_ data:[String:Any]) throws -> GameCategory {
                guard let id=data["id"] as? Int,ids.insert(id).inserted,let original=originals[id],NSDictionary(dictionary:original).isEqual(to:data),let type=data["type"] as? String,types.contains(type),let title=data["name"] as? String,!title.isEmpty,let logo=data["logo"] as? String else {throw DailySource.failure()}
                return GameCategory(id:"daily-grid-group-\(id)",title:title,playerIDs:general.filter {memberships[$0.id]!.contains(id)}.map(\.id),imageAsset:nil,imageURL:try DailySource.image(logo),flag:nil)
            }
            let board=DailyGridBoard(level:level,rows:try rowData.map(category),columns:try columnData.map(category))
            guard board.candidates.allSatisfy({!$0.isEmpty}) else {throw DailySource.failure()};boards.append(board)
            if level == .easy {guard selection["mode"] as? String == "easy",let rows=selection["rows"] as? [[String:Any]],let cols=selection["columns"] as? [[String:Any]],NSArray(array:rows).isEqual(to:rowData),NSArray(array:cols).isEqual(to:columnData) else {throw DailySource.failure()}}
        }
        let bytes=try JSONSerialization.data(withJSONObject:["date":root["gameDate"]!,"zone":root["timeZone"]!,"selection":selection,"players":playerRows],options:.sortedKeys)
        return Self(players:general,boards:boards,signature:ContentUpdateRules.digest(bytes))
    }
}
public enum DailyGridStatus:String,Codable,Sendable {case ready,playing,won,lost,revealed}
public struct DailyGridMistake:Codable,Equatable,Sendable {public let slot:Int;public let playerID:String}
public struct DailyGridProgress:Codable,Sendable {
    public let signature:String
    public let sessionID:UUID
    public var level:DailyGridLevel = .easy
    public var status:DailyGridStatus = .ready
    public var timer:Int = 0
    public var timeLeft:Double?
    public var deadline:Date?
    public var placed:[Int:String]=[:]
    public var history:[Int]=[]
    public var mistakes:[DailyGridMistake]=[]
    public var reviewRecorded=false
    public init(round:DailyGrid,sessionID:UUID=UUID()) {signature=round.signature;self.sessionID=sessionID}
    public var finished:Bool {status == .won || status == .lost || status == .revealed}
    public func remaining(at now:Date)->Int? {timeLeft.map {Int(ceil(max(0,min($0,deadline.map {$0.timeIntervalSince(now)} ?? $0))))}}
    public func valid(for round:DailyGrid)->Bool {
        let candidates=round.board(level).candidates
        guard signature == round.signature,[0,60,90].contains(timer),Set(history).count == history.count,Set(history) == Set(placed.keys),Set(placed.values).count == placed.count,placed.allSatisfy({candidates.indices.contains($0.key) && candidates[$0.key].contains($0.value)}),mistakes.count <= 250,mistakes.allSatisfy({candidates.indices.contains($0.slot) && round.player($0.playerID) != nil && !candidates[$0.slot].contains($0.playerID)}),!reviewRecorded || finished else {return false}
        if status == .ready {return timeLeft == nil && deadline == nil && placed.isEmpty && mistakes.isEmpty}
        if timer == 0 {guard timeLeft == nil && deadline == nil else {return false}} else {guard let left=timeLeft,left.isFinite,(0...Double(timer)).contains(left),deadline?.timeIntervalSince1970.isFinite ?? true else {return false}}
        switch status {case .ready:return false;case .playing:return placed.count < 9 && (timer == 0 || timeLeft! > 0);case .won:return placed.count == 9;case .lost:return timer != 0 && timeLeft == 0 && placed.count < 9;case .revealed:return placed.count < 9}
    }
    @discardableResult public mutating func start(in round:DailyGrid,level:DailyGridLevel,timer:Int,now:Date)->Bool {
        guard valid(for:round),status == .ready,[0,60,90].contains(timer) else {return false};self.level=level;self.timer=timer;timeLeft=timer == 0 ? nil:Double(timer);deadline=timer == 0 ? nil:now.addingTimeInterval(Double(timer));status = .playing;return true
    }
    @discardableResult public mutating func expire(at now:Date)->Bool {guard status == .playing,let deadline,now >= deadline else {return false};status = .lost;timeLeft=0;self.deadline=nil;return true}
    public mutating func pause(at now:Date) {guard status == .playing,!expire(at:now),let deadline else {return};timeLeft=max(0,deadline.timeIntervalSince(now));self.deadline=nil}
    public mutating func resume(at now:Date) {guard status == .playing,deadline == nil,let timeLeft else {return};deadline=now.addingTimeInterval(timeLeft)}
    @discardableResult public mutating func place(_ player:String,at slot:Int,in round:DailyGrid,now:Date)->Bool {
        guard valid(for:round),!expire(at:now),status == .playing,round.board(level).candidates.indices.contains(slot),placed[slot] == nil,!placed.values.contains(player),round.player(player) != nil else {return false}
        guard round.board(level).candidates[slot].contains(player) else {let mistake=DailyGridMistake(slot:slot,playerID:player);if !mistakes.contains(mistake),mistakes.count < 250 {mistakes.append(mistake)};return false}
        placed[slot]=player;history.append(slot);if placed.count == 9 {status = .won};return true
    }
    @discardableResult public mutating func undo(in round:DailyGrid,now:Date)->Bool {guard valid(for:round),!expire(at:now),status == .playing,let slot=history.popLast() else {return false};placed.removeValue(forKey:slot);return true}
    @discardableResult public mutating func reveal(in round:DailyGrid,now:Date)->Bool {guard valid(for:round),!expire(at:now),status == .playing else {return false};pause(at:now);status = .revealed;return true}
}
extension DailyChallengeCache {
    public func progress(for round:DailyGrid)->DailyGridProgress? {guard let data=try? Data(contentsOf:gridURL(round)),let p=try? JSONDecoder().decode(DailyGridProgress.self,from:data),p.valid(for:round) else {return nil};return p}
    public func save(_ p:DailyGridProgress,for round:DailyGrid) throws {guard p.valid(for:round) else {throw DailySource.failure()};try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true);try JSONEncoder().encode(p).write(to:gridURL(round),options:.atomic)}
    private func gridURL(_ round:DailyGrid)->URL {directory.appendingPathComponent("daily-grid-"+round.signature+".json")}
}
