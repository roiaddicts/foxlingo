import Foundation

public struct DailyClub: Codable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let imageURL: String?
}
public struct SquadCountry: Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let flagURL: String
    public let color: String
    public let players: [GamePlayer]
    public var count: Int {players.count}
}
public struct DailySquadSlice: Sendable {
    public let season: String
    public let answer: DailyClub
    public let clubs: [DailyClub]
    public let countries: [SquadCountry]
    public let randomOrder: [Int]
    public let signature: String
    public var total: Int {countries.reduce(0) {$0+$1.count}}
    public func visibleCountries(at misses: Int,clockwise: Bool,finished: Bool = false) -> Set<Int> {
        guard !finished,misses < 2 else {return Set(countries.map(\.id))}
        let order=clockwise ? countries.map(\.id):randomOrder,target=misses == 0 ? 0.3:0.6
        var fraction=0.0,best=Double.infinity,amount=1
        for (index,id) in order.enumerated() {
            fraction += Double(countries.first {$0.id == id}!.count)/Double(total)
            let delta=abs(fraction-target)
            if delta < best {best=delta;amount=index+1}
        }
        return Set(order.prefix(amount))
    }
    static func load(root: [String:Any],players: [GamePlayer]) throws -> Self? {
        let (record,selection)=try DailySource.selection("squadslice",root:root)
        guard let slices=selection["slices"] as? [[String:Any]] else {return nil} // Older packs predate the chart adapter.
        guard let id=record["clubID"] as? Int,let season=record["season"] as? String,season.range(of:"^[0-9]{4}/[0-9]{2}$",options:.regularExpression) != nil,
              let csv=record["players"] as? String,let order=selection["revealOrder"] as? [Int],
              let support=root["support"] as? [String:Any],let clubSupport=support["clubs"] as? [String:Any],let clubRows=clubSupport["data"] as? [[String:Any]] else {throw DailySource.failure()}
        var clubs:[DailyClub]=[]
        for row in clubRows {
            guard let id=row["id"] as? Int,let name=row["lastName"] as? String,!name.isEmpty,let image=row["image"] as? String else {throw DailySource.failure()}
            clubs.append(DailyClub(id:id,name:name,imageURL:image == "DELETE THIS SHIRT IN FOLDER" ? nil:try DailySource.image(image)))
        }
        guard Set(clubs.map(\.id)).count == clubs.count,let answer=clubs.first(where:{$0.id == id}) else {throw DailySource.failure()}
        let playerRows=try DailySource.table(["bingo","countryID","firstName","grid","id","image","lastName","nickname"],root:root)
        let flagRows=try DailySource.table(["bgColor","flag","id","name"],root:root)
        var nations:[Int:Int]=[:]
        for row in playerRows {guard let id=row["id"] as? Int,let country=row["countryID"] as? Int,nations[id] == nil else {throw DailySource.failure()};nations[id]=country}
        let roster=try DailySource.ids(csv),profileMap=Dictionary(uniqueKeysWithValues:players.map {($0.id,$0)})
        let known=roster.filter {profileMap["daily-general-\($0)"] != nil}
        guard selection["omittedPlayerIDs"] as? [Int] == roster.filter({!known.contains($0)}) else {throw DailySource.failure()}
        var countries:[SquadCountry]=[],used=Set<Int>()
        for slice in slices {
            guard let country=slice["countryID"] as? Int,!countries.contains(where:{$0.id == country}),let ids=slice["playerIDs"] as? [Int],!ids.isEmpty,
                  slice["count"] as? Int == ids.count,Set(ids).count == ids.count,used.isDisjoint(with:Set(ids)),
                  ids == known.filter({nations[$0] == country}),let flag=flagRows.first(where:{$0["id"] as? Int == country}),
                  let name=flag["name"] as? String,let url=flag["flag"] as? String else {throw DailySource.failure()}
            used.formUnion(ids)
            countries.append(SquadCountry(id:country,name:name,flagURL:try DailySource.image(url),color:flag["bgColor"] as? String ?? "#002D56",players:try ids.map {id in guard let p=profileMap["daily-general-\(id)"] else {throw DailySource.failure()};return p}))
        }
        guard !countries.isEmpty,used == Set(known),Set(order) == Set(countries.map(\.id)),order.count == countries.count,
              countries.map(\.id) == countries.sorted(by:{$0.count == $1.count ? $0.id < $1.id:$0.count > $1.count}).map(\.id) else {throw DailySource.failure()}
        var identity=["daily-squadslice-v1",root["gameDate"] as! String,root["timeZone"] as! String,String(id),answer.name,answer.imageURL ?? "",season]
        for country in countries {
            identity += [String(country.id),country.name,country.flagURL,country.color]
            for player in country.players {identity += [player.id,player.name,player.imageURL ?? ""]}
        }
        identity += order.map {String($0)}
        let signature=ContentUpdateRules.digest(ContentUpdateRules.bytes(identity))
        return Self(season:season,answer:answer,clubs:clubs,countries:countries,randomOrder:order,signature:signature)
    }
}
public struct SquadSliceProgress: Codable, Sendable {
    public let signature: String
    public let sessionID: UUID
    public let clockwise: Bool
    public var guesses: [Int?] = []
    public var reviewRecorded=false
    public init(round: DailySquadSlice,clockwise: Bool = false) {signature=round.signature;sessionID=UUID();self.clockwise=clockwise}
    public func won(_ round: DailySquadSlice) -> Bool {guesses.last == .some(.some(round.answer.id))}
    public func finished(_ round: DailySquadSlice) -> Bool {won(round) || guesses.count == 3}
    public func valid(for round: DailySquadSlice) -> Bool {
        let ids=guesses.compactMap {$0}
        return signature == round.signature && guesses.count <= 3 && Set(ids).count == ids.count && Set(ids).isSubset(of:Set(round.clubs.map(\.id))) && !guesses.dropLast().contains(.some(round.answer.id)) && (!reviewRecorded || finished(round))
    }
    @discardableResult public mutating func submit(_ id: Int?,in round: DailySquadSlice) -> Bool {
        guard valid(for:round),!finished(round) else {return false}
        if let id {guard round.clubs.contains(where:{$0.id == id}),!guesses.contains(.some(id)) else {return false}}
        guesses.append(id);return true
    }
}
extension DailyChallengeCache {
    public func progress(for round: DailySquadSlice) -> SquadSliceProgress? {
        guard let data=try? Data(contentsOf:squadURL(round)),let value=try? JSONDecoder().decode(SquadSliceProgress.self,from:data),value.valid(for:round) else {return nil};return value
    }
    public func save(_ value: SquadSliceProgress,for round: DailySquadSlice) throws {
        guard value.valid(for:round) else {throw DailySource.failure()}
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        try JSONEncoder().encode(value).write(to:squadURL(round),options:.atomic)
    }
    private func squadURL(_ round: DailySquadSlice) -> URL {directory.appendingPathComponent("squadslice-"+round.signature+".json")}
}
