import Foundation

public enum DailyXILevel:String,Codable,CaseIterable,Sendable {case normal,easy}
public struct DailyXI:Sendable,Identifiable {
    public let id:String
    public let title:String
    public let normal:DraftEngine
    public let easy:DraftEngine
    public let signature:String
    public var kind:String {"draft-"+(id == "countries" ? "nations":id)}
    public func engine(_ level:DailyXILevel)->DraftEngine {level == .normal ? normal:easy}
    public func initialBoard(_ level:DailyXILevel)->DraftProgress {
        let e=engine(level)
        return DraftProgress(modeID:e.mode.id,formationID:e.pack.formations[0].id,groupIDs:e.mode.groups.map(\.id),placed:[:],history:[],assisted:[])
    }
    static func load(root:[String:Any],general:[GamePlayer]) throws -> [Self] {
        guard let games=root["games"] as? [[String:Any]],let tables=root["datasets"] as? [[String:Any]] else {throw DailySource.failure()}
        let titles=["countries":"Nations XI","clubs":"Clubs XI","retro":"Retro XI","legends":"Legends XI","america":"America XI"]
        let codes:Set<String>=["GK","LB","CB","RB","LWB","RWB","CDM","CM","CAM","LM","RM","LW","RW","ST","CF"]
        let pitchRows=["442":[[9,10],[5,6,7,8],[1,2,3,4],[0]],"433":[[8,9,10],[5,6,7],[1,2,3,4],[0]],"532":[[9,10],[7,8],[6],[1,2,3,4,5],[0]],"352":[[9,10],[8],[6,4,5,7],[1,2,3],[0]],"343":[[8,10,9],[6,4,5,7],[1,2,3],[0]]]
        func name(_ row:[String:Any])->String {[(row["firstName"] as? String ?? ""),(row["lastName"] as? String ?? "")].filter {!$0.isEmpty}.joined(separator:" ").trimmingCharacters(in:.whitespaces)}
        func normalized(_ value:String)->String {value.folding(options:[.caseInsensitive,.diacriticInsensitive],locale:Locale(identifier:"en_US_POSIX"))}
        let generalRows=try DailySource.table(["id","firstName","lastName","nickname","image","countryID","grid","bingo"],root:root)
        let generalNames=Dictionary(grouping:generalRows,by:{normalized(name($0))})
        let generalPlayers=Dictionary(uniqueKeysWithValues:general.map {($0.id,$0)})
        var rounds:[Self]=[]
        for id in ["countries","clubs","retro","legends","america"] {
            guard let game=games.first(where:{$0["id"] as? String == id}),let selection=game["selection"] as? [String:Any] else {throw DailySource.failure()}
            guard let c=selection["catalog"] as? [String:Any] else {continue}
            let fields:Set<String>
            switch id {case "countries":fields=["birthday","clubID","countryID","firstName","id","lastName","nickname","ovr","positions"];case "clubs":fields=["clubID","firstName","id","lastName","nickname","positions"];case "america":fields=["clubID","firstName","id","lastName","positions"];default:fields=["active","clubID","firstName","id","lastName","nickname","positions"]}
            guard c["boardDate"] as? String == root["gameDate"] as? String,let playerURL=c["playerSourceURL"] as? String,let groupURL=c["groupSourceURL"] as? String,let formationURL=c["formationSourceURL"] as? String,
                  let table=tables.first(where:{$0["sourceURL"] as? String == playerURL && Set($0["fields"] as? [String] ?? []) == fields}),let players=table["data"] as? [[String:Any]],
                  let rawGroups=c["groups"] as? [[String:Any]],let rawForms=c["formations"] as? [[String:Any]],rawForms.count == 5,
                  let chosenForm=selection["formation"] as? [String:Any],let formID=chosenForm["name"] as? String,let rows=pitchRows[formID],
                  rawForms.contains(where:{NSDictionary(dictionary:$0).isEqual(to:chosenForm)}),let slots=chosenForm["players"] as? [[String:Any]],slots.count == 11,
                  let excluded=c["excludedPositionPlayerIDs"] as? [Int],Set(excluded).count == excluded.count,
                  let portraits=c["portraitPlayerIDs"] as? [String:Int],c["uniquePlayers"] as? Bool == (id == "retro"),c["timerSeconds"] as? [Int] == [0,40,60,90],
                  let rawBoards=selection["boards"] as? [[String:Any]],rawBoards.count == 2,let sourceURL=game["sourceURL"] as? String else {throw DailySource.failure()}
            for url in [playerURL,groupURL,formationURL,sourceURL] {_ = try ContentUpdateRules.https(url)}
            guard Set(rawForms.compactMap {$0["name"] as? String}) == Set(pitchRows.keys),rawForms.allSatisfy({f in guard let p=f["players"] as? [[String:Any]],p.count == 11 else {return false};return p.allSatisfy {codes.contains($0["position"] as? String ?? "") && $0["player"] is NSNull}}) else {throw DailySource.failure()}
            let positions=slots.compactMap {$0["position"] as? String}
            guard positions.count == 11 else {throw DailySource.failure()}
            let formation=DraftFormation(id:formID,positions:positions,rows:rows)
            var rawPlayers:[Int:[String:Any]]=[:],invalid:[Int]=[],profiles:[DraftProfile]=[]
            let ownNames=Dictionary(grouping:players,by:{normalized(name($0))})
            func playerID(_ n:Int)->String {"daily-xi-\(id)-player-\(n)"}
            for p in players {
                guard let n=p["id"] as? Int,rawPlayers[n] == nil else {throw DailySource.failure()};rawPlayers[n]=p
                let positions=(p["positions"] as? String ?? "").split(separator:",").map {$0.trimmingCharacters(in:.whitespaces)}.filter {!$0.isEmpty}
                if positions.isEmpty || !Set(positions).isSubset(of:codes) {invalid.append(n);continue}
                let full=name(p),nickname=p["nickname"] as? String ?? "",display=nickname.isEmpty ? full:nickname
                guard !display.isEmpty else {throw DailySource.failure()}
                var image:String?
                if let portrait=portraits[String(n)] {
                    let key=normalized(full)
                    guard !key.isEmpty,ownNames[key]?.count == 1,let matches=generalNames[key],matches.count == 1,matches[0]["id"] as? Int == portrait,let person=generalPlayers["daily-general-\(portrait)"],person.imageURL != nil else {throw DailySource.failure()}
                    image=person.imageURL
                }
                profiles.append(DraftProfile(person:GamePlayer(id:playerID(n),name:display,aliases:Array(Set([full,nickname,display].filter {!$0.isEmpty})).sorted(),imageURL:image,imageAsset:nil),positions:positions))
            }
            guard invalid == excluded,portraits.keys.allSatisfy({key in guard let n=Int(key),let p=rawPlayers[n],let portrait=portraits[key] else {return false};let k=normalized(name(p));return !k.isEmpty && ownNames[k]?.count == 1 && generalNames[k]?.count == 1 && generalNames[k]?[0]["id"] as? Int == portrait && generalPlayers["daily-general-\(portrait)"]?.imageURL != nil}) else {throw DailySource.failure()}
            var originals:[Int:[String:Any]]=[:]
            for g in rawGroups {guard let n=g["id"] as? Int,originals[n] == nil else {throw DailySource.failure()};originals[n]=g}
            var engines:[DailyXILevel:DraftEngine]=[:]
            for b in rawBoards {
                guard let level=DailyXILevel(rawValue:b["level"] as? String ?? ""),engines[level] == nil,let groups=b["groups"] as? [[String:Any]],groups.count == 11,let memberships=b["memberships"] as? [[String:Any]],memberships.count == 11 else {throw DailySource.failure()}
                var compiled:[DraftGroup]=[],seen:Set<Int>=[],distinct:Set<Int>=[]
                for (index,g) in groups.enumerated() {
                    guard let n=g["id"] as? Int,seen.insert(n).inserted,let original=originals[n],NSDictionary(dictionary:original).isEqual(to:g),let title=g["name"] as? String,!title.isEmpty,let logo=g["logo"] as? String,memberships[index]["id"] as? Int == n,let ids=memberships[index]["playerIDs"] as? [Int],!ids.isEmpty,Set(ids).count == ids.count else {throw DailySource.failure()}
                    let key=id == "retro" ? g["clubID"] as? Int:n
                    guard let key,distinct.insert(key).inserted else {throw DailySource.failure()}
                    let expected:[Int]
                    if id == "clubs" || id == "retro" {
                        guard let csv=g["players"] as? String else {throw DailySource.failure()}
                        let pieces=csv.split(separator:",");let all=pieces.compactMap {Int($0.trimmingCharacters(in:.whitespaces))}
                        guard all.count == pieces.count,Set(all).count == all.count,all.allSatisfy({rawPlayers[$0] != nil}) else {throw DailySource.failure()}
                        expected=all.filter {!invalid.contains($0)}
                    } else {
                        expected=players.compactMap {p in guard let pid=p["id"] as? Int,!invalid.contains(pid),p[id == "countries" ? "countryID":"clubID"] as? Int == n,(id != "legends" || level == .easy || p["active"] as? String != "yes") else {return nil};return pid}
                    }
                    guard ids == expected else {throw DailySource.failure()}
                    compiled.append(DraftGroup(id:"daily-xi-\(id)-group-\(n)",name:title,distinctKey:String(key),imageAsset:"",imageURL:try DailySource.image(logo),playerIDs:ids.map(playerID)))
                }
                if level == .normal {guard let selected=selection["groups"] as? [[String:Any]],NSArray(array:selected).isEqual(to:groups) else {throw DailySource.failure()}}
                let scope="Source squad and position pool; roster cutoff is not published."+(id == "legends" ? " Normal excludes source records marked active; Easy includes them.":"")
                let mode=DraftMode(id:id+"-"+level.rawValue,title:titles[id]!,subtitle:"Eleven offers. One daily formation.",scope:scope,sourceURL:sourceURL,groups:compiled)
                let draft=DraftPack(schemaVersion:1,fetchedAt:root["fetchedAt"] as? String ?? "",sourceURL:sourceURL,players:profiles,formations:[formation],modes:[mode])
                let engine=DraftEngine(pack:draft,mode:mode,allowsRepeatedPlayers:id != "retro")
                let initial=DraftProgress(modeID:mode.id,formationID:formID,groupIDs:compiled.map(\.id),placed:[:],history:[],assisted:[])
                guard engine.solution(initial,nodeLimit:100_000) != nil else {throw DailySource.failure()};engines[level]=engine
            }
            let bytes=try JSONSerialization.data(withJSONObject:["date":root["gameDate"]!,"zone":root["timeZone"]!,"selection":selection,"players":players,"portraits":generalRows.filter {portraits.values.contains($0["id"] as? Int ?? -1)}],options:.sortedKeys)
            rounds.append(Self(id:id,title:titles[id]!,normal:engines[.normal]!,easy:engines[.easy]!,signature:ContentUpdateRules.digest(bytes)))
        }
        return rounds
    }
}

public enum DailyXIStatus:String,Codable,Sendable {case ready,playing,won,lost,revealed}
public struct DailyXIProgress:Codable,Sendable {
    public let signature:String
    public let sessionID:UUID
    public var level:DailyXILevel = .normal
    public var status:DailyXIStatus = .ready
    public var timer=0
    public var timeLeft:Double?
    public var deadline:Date?
    public var board:DraftProgress?
    public var reviewRecorded=false
    public init(round:DailyXI,sessionID:UUID=UUID()) {signature=round.signature;self.sessionID=sessionID}
    public var finished:Bool {status == .won || status == .lost || status == .revealed}
    public func remaining(at now:Date)->Int? {timeLeft.map {Int(ceil(max(0,min($0,deadline.map {$0.timeIntervalSince(now)} ?? $0))))}}
    public func valid(for round:DailyXI)->Bool {
        guard signature == round.signature,[0,40,60,90].contains(timer),!reviewRecorded || finished else {return false}
        if status == .ready {return board == nil && timeLeft == nil && deadline == nil}
        guard let board,round.engine(level).valid(board,allowFinished:true),board.groupIDs == round.initialBoard(level).groupIDs,board.formationID == round.initialBoard(level).formationID else {return false}
        if timer == 0 {guard timeLeft == nil && deadline == nil else {return false}} else {guard let timeLeft,timeLeft.isFinite,(0...Double(timer)).contains(timeLeft),deadline?.timeIntervalSince1970.isFinite ?? true else {return false}}
        if finished && deadline != nil {return false}
        switch status {case .ready:return false;case .playing:return !board.finished && (timer == 0 || timeLeft! > 0);case .won:return board.finished;case .lost:return !board.finished && timer != 0 && timeLeft == 0;case .revealed:return !board.finished}
    }
    @discardableResult public mutating func start(in round:DailyXI,level:DailyXILevel,timer:Int,now:Date)->Bool {
        guard valid(for:round),status == .ready,[0,40,60,90].contains(timer) else {return false}
        self.level=level;self.timer=timer;board=round.initialBoard(level);timeLeft=timer == 0 ? nil:Double(timer);deadline=timer == 0 ? nil:now.addingTimeInterval(Double(timer));status = .playing;return true
    }
    @discardableResult public mutating func expire(at now:Date)->Bool {guard status == .playing,let deadline,now >= deadline else {return false};status = .lost;timeLeft=0;self.deadline=nil;return true}
    public mutating func pause(at now:Date) {guard status == .playing,!expire(at:now),let deadline else {return};timeLeft=max(0,deadline.timeIntervalSince(now));self.deadline=nil}
    public mutating func resume(at now:Date) {guard status == .playing,deadline == nil,let timeLeft else {return};deadline=now.addingTimeInterval(timeLeft)}
    @discardableResult public mutating func place(_ player:String,at slot:Int,in round:DailyXI,now:Date,assisted:Bool=false)->Bool {
        guard valid(for:round),!expire(at:now),status == .playing,var board,round.engine(level).place(player,at:slot,on:&board,assisted:assisted) else {return false}
        self.board=board
        if board.finished {pause(at:now);status = .won;deadline=nil}
        return true
    }
    @discardableResult public mutating func undo(in round:DailyXI,now:Date)->Bool {guard valid(for:round),!expire(at:now),status == .playing,board?.history.isEmpty == false else {return false};board?.undo();return true}
    @discardableResult public mutating func reveal(in round:DailyXI,now:Date)->Bool {guard valid(for:round),!expire(at:now),status == .playing else {return false};pause(at:now);status = .revealed;return true}
}
extension DailyChallengeCache {
    public func progress(for round:DailyXI)->DailyXIProgress? {guard let data=try? Data(contentsOf:xiURL(round)),let p=try? JSONDecoder().decode(DailyXIProgress.self,from:data),p.valid(for:round) else {return nil};return p}
    public func save(_ p:DailyXIProgress,for round:DailyXI) throws {guard p.valid(for:round) else {throw DailySource.failure()};try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true);try JSONEncoder().encode(p).write(to:xiURL(round),options:.atomic)}
    private func xiURL(_ round:DailyXI)->URL {directory.appendingPathComponent("daily-xi-"+round.id+"-"+round.signature+".json")}
}
