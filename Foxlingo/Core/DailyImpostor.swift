import Foundation

public enum ImpostorLevel:String,Codable,CaseIterable,Sendable {case normal,hard}
public enum ImpostorStatus:String,Codable,Sendable {case ready,playing,won,lost}
public enum ImpostorMark:String,Codable,Sendable {case correct,wrong,missed}
public struct ImpostorEvidence:Sendable {public let title:String;public let url:String}
public struct ImpostorReview:Identifiable,Sendable {public let id:String;public let note:String;public let reviewedAt:String;public let removed:[String];public let sources:[ImpostorEvidence]}
public struct DailyImpostor:Sendable {
    public let title:String
    public let players:[GamePlayer]
    public let correct:[String]
    public let extra:[String]
    public let sourceExtra:[String]
    public let reviews:[ImpostorReview]
    public let impostors:[String]
    public let signature:String
    public func player(_ id:String)->GamePlayer? {players.first {$0.id == id}}
    public func positives(_ level:ImpostorLevel)->[String] {level == .hard ? correct+extra:correct}
    public func outsiders(_ level:ImpostorLevel)->[String] {level == .hard && !extra.isEmpty ? Array(impostors.dropLast(extra.count)):impostors}
    public func pool(_ level:ImpostorLevel)->[String] {outsiders(level)+positives(level)}
    static func load(root:[String:Any],general:[GamePlayer]) throws -> Self? {
        guard let game=(root["games"] as? [[String:Any]])?.first(where:{$0["id"] as? String == "impostor"}),let s=game["selection"] as? [String:Any],let c=s["catalog"] as? [String:Any] else {return nil}
        guard c["reviewVersion"] as? Int == 1,let reviewDigest=c["reviewsSHA256"] as? String,reviewDigest.range(of:"^[0-9a-f]{64}$",options:.regularExpression) != nil,c["boardDate"] as? String == root["gameDate"] as? String,let index=s["index"] as? Int,index == root["dayOfYear"] as? Int,let record=s["record"] as? [String:Any],let source=c["recordSourceURL"] as? String,let playerSource=c["playerSourceURL"] as? String,let tables=root["datasets"] as? [[String:Any]],
              let table=tables.first(where:{$0["sourceURL"] as? String == source && Set($0["fields"] as? [String] ?? []) == ["id","title","correctPl","addcorr","impostors"]}),let rows=table["data"] as? [[String:Any]],rows.indices.contains(index),NSDictionary(dictionary:rows[index]).isEqual(to:record),
              let playerTable=tables.first(where:{$0["sourceURL"] as? String == playerSource && Set($0["fields"] as? [String] ?? []) == ["bingo","countryID","firstName","grid","id","image","lastName","nickname"]}),let playerRows=playerTable["data"] as? [[String:Any]],
              let title=record["title"] as? String,!title.isEmpty,let correctCSV=record["correctPl"] as? String,let outsiderCSV=record["impostors"] as? String else {throw DailySource.failure()}
        let correct=try DailySource.ids(correctCSV),outsiders=try DailySource.ids(outsiderCSV),extra=try (record["addcorr"] as? String).flatMap {$0.isEmpty ? nil:try DailySource.ids($0)} ?? []
        guard correct == s["correctPlayerIDs"] as? [Int],extra == s["extraCorrectPlayerIDs"] as? [Int],outsiders == s["impostorPlayerIDs"] as? [Int],correct.count+outsiders.count == 10,extra.count < outsiders.count,Set(correct+extra+outsiders).count == correct.count+extra.count+outsiders.count else {throw DailySource.failure()}
        func typed(_ ids:[Int])->[String] {ids.map {"daily-general-\($0)"}}
        let ids=Set(typed(correct+extra+outsiders)),players=general.filter {ids.contains($0.id)}
        guard Set(players.map(\.id)) == ids,players.allSatisfy({$0.imageURL != nil}) else {throw DailySource.failure()}
        guard let playableExtra=s["playableExtraPlayerIDs"] as? [Int],let rawReviews=s["reviews"] as? [[String:Any]],rawReviews.count <= 20 else {throw DailySource.failure()}
        var reviews:[ImpostorReview]=[],removed:Set<Int>=[],reviewIDs:Set<String>=[]
        for review in rawReviews {
            guard let id=review["id"] as? String,UUID(uuidString:id) != nil,reviewIDs.insert(id).inserted,review["game"] as? String == "impostor",review["recordID"] as? Int == record["id"] as? Int,review["title"] as? String == title,
                  review["sourceCorrectPlayerIDs"] as? [Int] == correct,review["sourceExtraCorrectPlayerIDs"] as? [Int] == extra,review["sourceImpostorPlayerIDs"] as? [Int] == outsiders,let removals=review["removeExtraPlayerIDs"] as? [Int],!removals.isEmpty,Set(removals).count == removals.count,Set(removals).isSubset(of:Set(extra)),removed.isDisjoint(with:removals),
                  let names=review["playerNames"] as? [String:String],let note=review["note"] as? String,!note.isEmpty,let date=review["reviewedAt"] as? String,date.range(of:"^[0-9]{4}-[0-9]{2}-[0-9]{2}$",options:.regularExpression) != nil,let evidence=review["sources"] as? [[String:String]],!evidence.isEmpty else {throw DailySource.failure()}
            for raw in removals {guard let player=players.first(where:{$0.id == "daily-general-\(raw)"}),player.name == names[String(raw)] else {throw DailySource.failure()}}
            let sources=try evidence.map {source -> ImpostorEvidence in guard let title=source["title"],!title.isEmpty,let url=source["url"] else {throw DailySource.failure()};return ImpostorEvidence(title:title,url:try ContentUpdateRules.https(url).absoluteString)}
            removed.formUnion(removals);reviews.append(ImpostorReview(id:id,note:note,reviewedAt:date,removed:typed(removals),sources:sources))
        }
        guard playableExtra == extra.filter({!removed.contains($0)}) else {throw DailySource.failure()}
        let bytes=try JSONSerialization.data(withJSONObject:["date":root["gameDate"]!,"zone":root["timeZone"]!,"selection":s,"players":playerRows],options:.sortedKeys)
        return Self(title:title,players:players,correct:typed(correct),extra:typed(playableExtra),sourceExtra:typed(extra),reviews:reviews,impostors:typed(outsiders),signature:ContentUpdateRules.digest(bytes))
    }
}
public struct ImpostorProgress:Codable,Sendable {
    public let signature:String
    public let sessionID:UUID
    public var level:ImpostorLevel = .normal
    public var status:ImpostorStatus = .ready
    public var order:[String]=[]
    public var selected:Set<String>=[]
    public var marks:[String:ImpostorMark]=[:]
    public var checks=0
    public var revealed=false
    public var reviewRecorded=false
    public var revealReviewRecorded=false
    public init(round:DailyImpostor,sessionID:UUID=UUID()) {signature=round.signature;self.sessionID=sessionID}
    public var finished:Bool {status == .won || status == .lost}
    public var found:Int {marks.values.filter {$0 == .correct}.count}
    public func valid(for round:DailyImpostor)->Bool {
        let positive=Set(round.positives(level)),negative=Set(round.outsiders(level))
        guard signature == round.signature,checks >= 0,checks <= 11,selected.isSubset(of:Set(order)),!reviewRecorded || finished,!revealed || finished,!finished || selected.isEmpty,!revealReviewRecorded || level == .hard && revealed && finished,marks.allSatisfy({$0.value == .wrong ? negative.contains($0.key):positive.contains($0.key)}) else {return false}
        if status == .ready {return order.isEmpty && selected.isEmpty && marks.isEmpty && checks == 0 && !revealed}
        guard order.count == 10,Set(order) == positive.union(negative),selected.isDisjoint(with:Set(marks.keys)),level != .hard || selected.count <= 1 else {return false}
        let wrong=marks.values.filter {$0 == .wrong}.count,missed=marks.values.filter {$0 == .missed}.count
        if level == .normal {
            guard status != .playing || marks.isEmpty && checks == 0 && !revealed else {return false}
            if finished {guard checks == 1,selected.isEmpty,found+missed == positive.count,revealed else {return false}}
        } else {guard checks == found+wrong,wrong <= 1,!revealed || status == .lost && found+missed == positive.count,missed == 0 || revealed,status != .playing || wrong == 0 && !revealed else {return false}}
        switch status {case .ready:return false;case .playing:return found < positive.count;case .won:return found == positive.count && wrong == 0 && selected.isEmpty;case .lost:return level == .normal ? found < positive.count || wrong > 0:wrong == 1}
    }
    @discardableResult public mutating func start<R:RandomNumberGenerator>(in round:DailyImpostor,level:ImpostorLevel,rng:inout R)->Bool {guard valid(for:round),status == .ready else {return false};self.level=level;order=round.pool(level).shuffled(using:&rng);status = .playing;return true}
    public mutating func select(_ id:String) {guard status == .playing,order.contains(id),marks[id] == nil else {return};if selected.contains(id) {selected.remove(id)} else {if level == .hard {selected=[]};selected.insert(id)}}
    public mutating func clear() {guard status == .playing else {return};selected=[]}
    @discardableResult public mutating func check(in round:DailyImpostor)->Bool? {
        guard valid(for:round),status == .playing,level == .normal || selected.count == 1 else {return nil}
        checks+=1
        if level == .normal {for id in round.positives(level) {marks[id]=selected.contains(id) ? .correct:.missed};for id in round.outsiders(level) where selected.contains(id) {marks[id] = .wrong};revealed=true;status=selected == Set(round.positives(level)) ? .won:.lost}
        else {let id=selected.first!;marks[id]=round.positives(level).contains(id) ? .correct:.wrong;if marks[id] == .wrong {status = .lost} else if found == round.positives(level).count {status = .won}}
        selected=[];return status != .lost
    }
    @discardableResult public mutating func reveal(in round:DailyImpostor)->Bool {guard valid(for:round),status == .lost,level == .hard,!revealed else {return false};for id in round.positives(level) where marks[id] == nil {marks[id] = .missed};revealed=true;return true}
}
extension DailyChallengeCache {
    public func progress(for round:DailyImpostor)->ImpostorProgress? {guard let bytes=try? Data(contentsOf:impostorURL(round)),let p=try? JSONDecoder().decode(ImpostorProgress.self,from:bytes),p.valid(for:round) else {return nil};return p}
    public func save(_ p:ImpostorProgress,for round:DailyImpostor) throws {guard p.valid(for:round) else {throw DailySource.failure()};try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true);try JSONEncoder().encode(p).write(to:impostorURL(round),options:.atomic)}
    private func impostorURL(_ round:DailyImpostor)->URL {directory.appendingPathComponent("daily-impostor-"+round.signature+".json")}
}
