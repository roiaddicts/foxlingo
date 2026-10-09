import Foundation

/// Common checks for source rows; numeric identifiers never cross player catalogs.
enum DailySource {
    static func failure() -> ContentError {.invalid("This daily board has missing or inconsistent source relationships.")}
    static func selection(_ id: String,root: [String:Any],indexKey: String = "dayOfYear") throws -> ([String:Any],[String:Any]) {
        guard let games=root["games"] as? [[String:Any]],let game=games.first(where:{$0["id"] as? String == id}),let module=game["sourceModule"] as? String,
              let selection=game["selection"] as? [String:Any],let record=selection["record"] as? [String:Any],let index=selection["index"] as? Int,index == root[indexKey] as? Int,
              let datasets=root["datasets"] as? [[String:Any]] else {throw failure()}
        let matches=datasets.filter {dataset in
            guard dataset["sourceURL"] as? String == module,let rows=dataset["data"] as? [[String:Any]],rows.indices.contains(index) else {return false}
            return NSDictionary(dictionary:rows[index]).isEqual(to:record)
        }
        guard matches.count == 1 else {throw failure()};return (record,selection)
    }
    static func image(_ value: String) throws -> String {
        if value.hasPrefix("https://") {return try ContentUpdateRules.https(value).absoluteString}
        guard value.hasPrefix("/"),!value.hasPrefix("//"),!value.contains("..") else {throw failure()}
        return try ContentUpdateRules.https("https://futbol11.com"+value).absoluteString
    }
    static func ids(_ csv: String) throws -> [Int] {
        let parts=csv.split(separator:",",omittingEmptySubsequences:false),values=parts.compactMap {Int($0.trimmingCharacters(in:.whitespaces))}
        guard !values.isEmpty,parts.count == values.count,Set(values).count == values.count,values.allSatisfy({$0 > 0}) else {throw failure()};return values
    }
    static func table(_ fields: Set<String>,root: [String:Any]) throws -> [[String:Any]] {
        guard let datasets=root["datasets"] as? [[String:Any]] else {throw failure()}
        let matches=datasets.filter {Set($0["fields"] as? [String] ?? []) == fields}
        guard matches.count == 1,let rows=matches[0]["data"] as? [[String:Any]] else {throw failure()};return rows
    }
}
public struct DailyRankedPlayer: Sendable {
    public let player: GamePlayer
    public let value: Int
}
public struct DailyPyramid: Sendable {
    public let title: String
    public let offers: [DailyRankedPlayer]
    public let signature: String
    public var correctOrder: [String] {offers.sorted {$0.value > $1.value}.map { $0.player.id }}
    public func player(_ id: String) -> DailyRankedPlayer? {offers.first {$0.player.id == id}}
    public func hintBand(for id: String) -> Range<Int>? {
        guard let rank=correctOrder.firstIndex(of:id) else {return nil}
        return rank < 3 ? 0..<3:rank < 6 ? 3..<6:6..<10
    }
    static func load(root: [String:Any],players: [GamePlayer]) throws -> Self {
        let (record,selection)=try DailySource.selection("pyramid",root:root,indexKey:"elapsedDayFloor")
        guard let title=record["title"] as? String,!title.isEmpty,let csv=record["players"] as? String,let selected=selection["players"] as? [[String:Any]],selected.count == 10 else {throw DailySource.failure()}
        let profiles=Dictionary(uniqueKeysWithValues:players.map {($0.id,$0)})
        var firstValues:[Int:Int]=[:],seen=Set<Int>()
        for pair in csv.split(separator:".",omittingEmptySubsequences:false) {
            let fields=pair.split(separator:",",omittingEmptySubsequences:false)
            guard fields.count == 2,let id=Int(fields[0]),let value=Int(fields[1]),value >= 0 else {throw DailySource.failure()}
            if seen.insert(value).inserted {guard firstValues[id] == nil else {throw DailySource.failure()};firstValues[id]=value}
        }
        var offers:[DailyRankedPlayer]=[]
        for row in selected {
            guard let id=row["playerID"] as? Int,let value=row["value"] as? Int,firstValues[id] == value,let player=profiles["daily-general-\(id)"] else {throw DailySource.failure()}
            offers.append(DailyRankedPlayer(player:player,value:value))
        }
        guard Set(offers.map {$0.player.id}).count == 10,Set(offers.map(\.value)).count == 10 else {throw DailySource.failure()}
        let signature=ContentUpdateRules.digest(ContentUpdateRules.bytes(["daily-pyramid-v1",root["gameDate"] as! String,root["timeZone"] as! String,title]+offers.flatMap {[$0.player.id,$0.player.name,$0.player.imageURL ?? "",String($0.value)]}))
        return Self(title:title,offers:offers,signature:signature)
    }
}
public struct PyramidProgress: Codable, Sendable {
    public let signature: String
    public let sessionID: UUID
    public let easy: Bool
    public var slots: [String?] = Array(repeating:nil,count:10)
    public var helpUsed=false
    public var locked: Set<Int> = []
    public var finished=false
    public var reviewRecorded=false
    public init(round: DailyPyramid,easy: Bool = false) {signature=round.signature;sessionID=UUID();self.easy=easy}
    public var count: Int {slots.compactMap {$0}.count}
    public func offered(_ round: DailyPyramid) -> DailyRankedPlayer? {count < 10 ? round.offers[count]:nil}
    public func correctSlots(_ round: DailyPyramid) -> Set<Int> {Set(slots.indices.filter {slots[$0] == round.correctOrder[$0]})}
    public func won(_ round: DailyPyramid) -> Bool {finished && correctSlots(round).count == 10}
    public func valid(for round: DailyPyramid) -> Bool {
        guard signature == round.signature,slots.count == 10,Set(slots.compactMap {$0}).count == count,
              Set(slots.compactMap {$0}) == Set(round.offers.prefix(count).map {$0.player.id}),
              locked.isSubset(of:Set(0..<10)),locked.isSubset(of:correctSlots(round)),helpUsed || locked.isEmpty,
              !helpUsed || count == 10,!finished || count == 10,!reviewRecorded || finished else {return false};return true
    }
    @discardableResult public mutating func place(at slot: Int,in round: DailyPyramid) -> Bool {
        guard valid(for:round),!finished,slots.indices.contains(slot),slots[slot] == nil,let offered=offered(round) else {return false}
        slots[slot]=offered.player.id;return true
    }
    @discardableResult public mutating func move(from: Int,to: Int,in round: DailyPyramid) -> Bool {
        guard valid(for:round),!finished,slots.indices.contains(from),slots.indices.contains(to),from != to,slots[from] != nil,!locked.contains(from),!locked.contains(to) else {return false}
        slots.swapAt(from,to);return true
    }
    @discardableResult public mutating func help(in round: DailyPyramid) -> Bool {
        guard valid(for:round),!finished,count == 10,!helpUsed else {return false}
        helpUsed=true;locked=correctSlots(round);return true
    }
    @discardableResult public mutating func submit(in round: DailyPyramid) -> Bool {
        guard valid(for:round),!finished,count == 10 else {return false};finished=true;return true
    }
}
extension DailyChallengeCache {
    public func progress(for round: DailyPyramid) -> PyramidProgress? {
        guard let data=try? Data(contentsOf:pyramidURL(round)),let value=try? JSONDecoder().decode(PyramidProgress.self,from:data),value.valid(for:round) else {return nil};return value
    }
    public func save(_ value: PyramidProgress,for round: DailyPyramid) throws {
        guard value.valid(for:round) else {throw DailySource.failure()}
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        try JSONEncoder().encode(value).write(to:pyramidURL(round),options:.atomic)
    }
    private func pyramidURL(_ round: DailyPyramid) -> URL {directory.appendingPathComponent("pyramid-"+round.signature+".json")}
}
