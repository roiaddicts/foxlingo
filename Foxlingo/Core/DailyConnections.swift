import Foundation

public enum ConnectionsLevel:String,Codable,CaseIterable,Sendable {case easy,normal,hard}
public struct DailyConnectionGroup:Sendable {
    public let id:String
    public let title:String
    public let playerIDs:[String]
}
public struct DailyConnectionBoard:Sendable {
    public let groups:[DailyConnectionGroup]
    public let order:[String]
}
public struct DailyConnections:Sendable {
    public let players:[GamePlayer]
    public let easy:DailyConnectionBoard
    public let normal:DailyConnectionBoard
    public let signature:String
    public func board(_ level:ConnectionsLevel)->DailyConnectionBoard {level == .easy ? easy:normal}
    public func player(_ id:String)->GamePlayer? {players.first {$0.id == id}}
    static func load(root:[String:Any],general:[GamePlayer]) throws -> Self? {
        guard let game=(root["games"] as? [[String:Any]])?.first(where:{$0["id"] as? String == "connections"}),let s=game["selection"] as? [String:Any],let catalog=s["catalog"] as? [String:Any] else {return nil}
        guard catalog["boardDate"] as? String == root["gameDate"] as? String,let module=game["sourceModule"] as? String,catalog["categorySourceURL"] as? String == module,let playerURL=catalog["playerSourceURL"] as? String,let tables=root["datasets"] as? [[String:Any]],
              let pt=tables.first(where:{$0["sourceURL"] as? String == playerURL && Set($0["fields"] as? [String] ?? []) == ["bingo","countryID","firstName","grid","id","image","lastName","nickname"]}),let playerRows=pt["data"] as? [[String:Any]],
              let gt=tables.first(where:{$0["sourceURL"] as? String == module && Set($0["fields"] as? [String] ?? []) == ["id","title","level","players"]}),let rows=gt["data"] as? [[String:Any]],let boards=s["boards"] as? [[String:Any]],boards.count == 2 else {throw DailySource.failure()}
        let available=Set(general.filter {$0.imageURL != nil}.map(\.id))
        var originals:[Int:[String:Any]]=[:],members:[Int:Set<String>]=[:]
        for row in rows {
            guard let id=row["id"] as? Int,originals[id] == nil,let csv=row["players"] as? String else {throw DailySource.failure()}
            let parts=csv.split(separator:","),ids=parts.compactMap {Int($0.trimmingCharacters(in:.whitespaces))}
            guard parts.count == ids.count else {throw DailySource.failure()}
            originals[id]=row;members[id]=Set(ids.map {"daily-general-\($0)"}).intersection(available)
        }
        var parsed:[String:DailyConnectionBoard]=[:]
        for raw in boards {
            guard let mode=raw["mode"] as? String,["easy","normal"].contains(mode),parsed[mode] == nil,let groups=raw["groups"] as? [[String:Any]],groups.count == 4,let rawOrder=raw["order"] as? [Int],rawOrder.count == 16 else {throw DailySource.failure()}
            var result:[DailyConnectionGroup]=[],ids:Set<Int>=[]
            for g in groups {
                guard let id=g["id"] as? Int,ids.insert(id).inserted,let original=originals[id],let title=g["title"] as? String,!title.isEmpty,title == original["title"] as? String,mode != "easy" || original["level"] as? String == "easy",let chosen=g["playerIDs"] as? [Int],chosen.count == 4 else {throw DailySource.failure()}
                let typed=chosen.map {"daily-general-\($0)"}
                guard Set(typed).count == 4,Set(typed).isSubset(of:members[id]!) else {throw DailySource.failure()}
                result.append(DailyConnectionGroup(id:"daily-connections-group-\(id)",title:title,playerIDs:typed))
            }
            let order=rawOrder.map {"daily-general-\($0)"},all=Set(result.flatMap(\.playerIDs))
            guard all.count == 16,Set(order) == all else {throw DailySource.failure()}
            for g in result {for other in result where g.id != other.id {
                let id=Int(other.id.split(separator:"-").last!)!
                guard Set(g.playerIDs).isDisjoint(with:members[id]!) else {throw DailySource.failure()}
            }}
            parsed[mode]=DailyConnectionBoard(groups:result,order:order)
            if mode == "normal" {guard let originalGroups=s["groups"] as? [[String:Any]],let originalOrder=s["order"] as? [Int],NSArray(array:groups).isEqual(to:originalGroups),originalOrder == rawOrder else {throw DailySource.failure()}}
        }
        guard let easy=parsed["easy"],let normal=parsed["normal"] else {throw DailySource.failure()}
        let bytes=try JSONSerialization.data(withJSONObject:["date":root["gameDate"]!,"zone":root["timeZone"]!,"selection":s,"players":playerRows,"categories":rows],options:.sortedKeys)
        return Self(players:general,easy:easy,normal:normal,signature:ContentUpdateRules.digest(bytes))
    }
}
public enum ConnectionsStatus:String,Codable,Sendable {case ready,playing,won,lost}
public enum ConnectionsCheck:String,Codable,Sendable {case correct,near,wrong}
public struct ConnectionsProgress:Codable,Sendable {
    public let signature:String
    public let sessionID:UUID
    public var level:ConnectionsLevel = .normal
    public var status:ConnectionsStatus = .ready
    public var selected:Set<String>=[]
    public var solved:[String]=[]
    public var checks=0
    public var errors=0
    public var mistakes:[[String]]=[]
    public var lastCheck:ConnectionsCheck?
    public var reviewRecorded=false
    public init(round:DailyConnections,sessionID:UUID=UUID()) {signature=round.signature;self.sessionID=sessionID}
    public var finished:Bool {status == .won || status == .lost}
    public func available(in round:DailyConnections)->Set<String> {Set(round.board(level).order).subtracting(round.board(level).groups.filter {solved.contains($0.id)}.flatMap(\.playerIDs))}
    public func valid(for round:DailyConnections)->Bool {
        let board=round.board(level)
        guard signature == round.signature,Set(solved).count == solved.count,Set(solved).isSubset(of:Set(board.groups.map(\.id))),selected.count <= 4,selected.isSubset(of:available(in:round)),errors >= 0,errors <= 100_000,checks == errors+solved.count,checks <= 100_000,level != .hard || errors <= 5,mistakes.count <= 250,mistakes.count <= errors,!reviewRecorded || finished else {return false}
        for ids in mistakes {guard ids.count == 4,Set(ids).count == 4,Set(ids).isSubset(of:Set(board.order)),!board.groups.contains(where:{Set($0.playerIDs) == Set(ids)}) else {return false}}
        switch status {case .ready:return checks == 0 && selected.isEmpty && lastCheck == nil;case .playing:return solved.count < 4 && (level != .hard || errors < 5);case .won:return solved.count == 4 && selected.isEmpty;case .lost:return solved.count < 4 && (level != .hard || errors == 5)}
    }
    @discardableResult public mutating func start(in round:DailyConnections,level:ConnectionsLevel)->Bool {guard valid(for:round),status == .ready else {return false};self.level=level;status = .playing;return true}
    public mutating func select(_ id:String,in round:DailyConnections) {guard status == .playing,available(in:round).contains(id) else {return};if selected.contains(id) {selected.remove(id)} else if selected.count < 4 {selected.insert(id)};lastCheck=nil}
    public mutating func clear() {guard status == .playing else {return};selected=[];lastCheck=nil}
    @discardableResult public mutating func check(in round:DailyConnections)->ConnectionsCheck? {
        guard valid(for:round),status == .playing,selected.count == 4,checks < 100_000 else {return nil}
        checks+=1
        if let group=round.board(level).groups.first(where:{Set($0.playerIDs) == selected}) {solved.append(group.id);selected=[];lastCheck = .correct;if solved.count == 4 {status = .won}}
        else {errors+=1;lastCheck=round.board(level).groups.contains(where:{Set($0.playerIDs).intersection(selected).count == 3}) ? .near:.wrong;let ids=selected.sorted();if !mistakes.contains(ids),mistakes.count < 250 {mistakes.append(ids)};if level == .hard,errors == 5 {status = .lost}}
        return lastCheck
    }
    @discardableResult public mutating func giveUp(in round:DailyConnections)->Bool {guard valid(for:round),status == .playing,level != .hard else {return false};status = .lost;return true}
}
extension DailyChallengeCache {
    public func progress(for round:DailyConnections)->ConnectionsProgress? {guard let bytes=try? Data(contentsOf:connectionsURL(round)),let p=try? JSONDecoder().decode(ConnectionsProgress.self,from:bytes),p.valid(for:round) else {return nil};return p}
    public func save(_ p:ConnectionsProgress,for round:DailyConnections) throws {guard p.valid(for:round) else {throw DailySource.failure()};try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true);try JSONEncoder().encode(p).write(to:connectionsURL(round),options:.atomic)}
    private func connectionsURL(_ round:DailyConnections)->URL {directory.appendingPathComponent("daily-connections-"+round.signature+".json")}
}
