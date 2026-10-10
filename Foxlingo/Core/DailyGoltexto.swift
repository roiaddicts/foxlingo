import Foundation

public struct GoltextoPlayer: Sendable {
    public let player: GamePlayer
    public let clubID: Int
    public let countryID: Int
    public let rating: Int
    public let positions: [String]
    public let age: Int?
}
public struct GoltextoScorePart: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let points: Int
}
public struct GoltextoScore: Sendable {
    public let value: Int
    public let parts: [GoltextoScorePart]
    public let mismatches: Int
    public var fraction: Double {min(1,max(0,Double(value+60)/160))}
}
public struct DailyGoltexto: Sendable {
    public let answer: GoltextoPlayer
    public let profiles: [GoltextoPlayer]
    public let clubs: [DailyClub]
    public let countries: [GuessWhoOption]
    public let leagueGroups: [Int:Set<Int>]
    public let regionGroups: [Int:Set<Int>]
    public let signature: String
    public var players: [GamePlayer] {profiles.map(\.player)}
    public func profile(_ id:String) -> GoltextoPlayer? {profiles.first {$0.player.id == id}}
    public func league(_ club:Int) -> Int? {leagueGroups.first {$0.value.contains(club)}?.key}
    public func region(_ country:Int) -> Int {regionGroups.first {$0.value.contains(country)}?.key ?? 0}
    private func role(_ position:String) -> Int {
        if ["CAM","CM","CDM","LM","RM"].contains(position) {return 1}
        if ["ST","CF","LW","RW"].contains(position) {return 2}
        if ["CB","LB","RB","LWB","RWB"].contains(position) {return 3}
        return 0 // Source default is goalkeeper.
    }
    public func score(_ guess:GoltextoPlayer) -> GoltextoScore {
        let a=answer,b=guess
        var parts:[GoltextoScorePart]=[],mismatches=0
        func add(_ id:String,_ title:String,_ points:Int) {parts.append(GoltextoScorePart(id:id,title:title,points:points))}
        if a.clubID == b.clubID {add("club","Same catalog club",40)} else {add("club","Different catalog club",0);mismatches += 2}
        let ratingGap=abs(a.rating-b.rating)
        add("rating",ratingGap < 5 ? "Rating within four points":"Ratings farther apart",ratingGap < 5 ? 5-ratingGap:0)
        if let left=a.age,let right=b.age {
            let gap=abs(left-right)
            add("age",gap <= 3 ? "Ages within three years":gap >= 10 ? "Ages ten or more years apart":"Age difference of four to nine years",gap <= 3 ? 7-gap:gap >= 10 ? -Int(floor(Double(gap)/3+0.5)):0)
        } else {add("age","Age not supplied",0)}
        let overlap = !Set(a.positions).isDisjoint(with:Set(b.positions))
        let primary = a.positions.first == b.positions.first
        add("position",overlap ? (primary ? "Same primary position":"Shared playing position"):"No shared playing position",overlap ? (primary ? 15:10):-5)
        let sameRole=role(a.positions[0]) == role(b.positions[0])
        add("role",sameRole ? "Same broad playing role":"Different broad playing role",sameRole ? 10:0)
        let wings:Set<String>=["LW","RW"],backs:Set<String>=["LB","RB"]
        let wide = (!Set(a.positions).isDisjoint(with:wings) && !Set(b.positions).isDisjoint(with:wings)) || (!Set(a.positions).isDisjoint(with:backs) && !Set(b.positions).isDisjoint(with:backs))
        add("wide",wide ? "Both wingers or both fullbacks":"No shared wide-position group",wide ? 10:0)
        if !sameRole && !wide {add("role-mismatch","Role mismatch",-5);mismatches += 1}
        let sameLeague=league(a.clubID) == league(b.clubID)
        add("league",sameLeague ? "Matching source league group":"Different source league groups",sameLeague ? 20:-5)
        if !sameLeague {mismatches += 1}
        let sameRegion=region(a.countryID) == region(b.countryID)
        add("region",sameRegion ? "Matching source regional group":"Different source regional groups",sameRegion ? 6:-2)
        let sameCountry=a.countryID == b.countryID
        add("country",sameCountry ? "Same nationality":"Different nationalities",sameCountry ? 20:-5)
        if !sameCountry {mismatches += 1}
        add("combination","Combined mismatch penalty",mismatches == 4 ? -15:mismatches >= 5 ? -mismatches*6:0)
        let raw=parts.reduce(0) {$0+$1.points}
        let value=raw > 99 ? (a.player.id == b.player.id ? 100:99):raw
        if value != raw {add("cap",a.player.id == b.player.id ? "Exact identity score":"Wrong-player score capped at 99",value-raw)}
        return GoltextoScore(value:value,parts:parts,mismatches:mismatches)
    }
    static func load(root:[String:Any],general:[GamePlayer]) throws -> Self? {
        guard let game=(root["games"] as? [[String:Any]])?.first(where:{$0["id"] as? String == "goltexto"}),let selection=game["selection"] as? [String:Any],let catalog=selection["catalog"] as? [String:Any] else {return nil}
        guard let index=selection["index"] as? Int,index == root["dayOfYear"] as? Int,let selected=selection["player"] as? [String:Any],let answerID=selected["id"] as? Int,
              let order=selection["orderPlayerIDs"] as? [Int],order.indices.contains(index),order[index] == answerID,
              let url=catalog["playerSourceURL"] as? String,let datasets=root["datasets"] as? [[String:Any]],
              let table=datasets.first(where:{$0["sourceURL"] as? String == url}),Set(table["fields"] as? [String] ?? []) == ["id","birthday","clubID","countryID","firstName","lastName","nickname","ovr","positions"],let rows=table["data"] as? [[String:Any]],
              let sourceAnswer=rows.first(where:{$0["id"] as? Int == answerID}),NSDictionary(dictionary:sourceAnswer).isEqual(to:selected),
              let map=catalog["portraitPlayerIDs"] as? [String:Int],let flagRows=catalog["countries"] as? [[String:Any]],
              let support=root["support"] as? [String:Any],let clubSupport=support["clubs"] as? [String:Any],let clubRows=clubSupport["data"] as? [[String:Any]],
              let zone=TimeZone(identifier:root["timeZone"] as! String) else {throw DailySource.failure()}
        let eligible=rows.filter {($0["clubID"] as? Int) != nil && !($0["birthday"] as? String ?? "").isEmpty}.prefix(366)
        let eligibleIDs=eligible.compactMap {$0["id"] as? Int}
        guard order.count == eligibleIDs.count,Set(order).count == order.count,Set(order) == Set(eligibleIDs) else {throw DailySource.failure()}
        var clubs:[DailyClub]=[],countries:[GuessWhoOption]=[]
        for row in clubRows {guard let id=row["id"] as? Int,let name=row["lastName"] as? String,let image=row["image"] as? String else {throw DailySource.failure()};clubs.append(DailyClub(id:id,name:name,imageURL:image == "DELETE THIS SHIRT IN FOLDER" ? nil:try DailySource.image(image)))}
        for row in flagRows {guard let id=row["id"] as? Int,let name=row["name"] as? String,let image=row["logo"] as? String else {throw DailySource.failure()};countries.append(GuessWhoOption(id:id,name:name,imageURL:try DailySource.image(image),imageAsset:nil,countryID:nil))}
        guard Set(clubs.map(\.id)).count == clubs.count,Set(countries.map(\.id)).count == countries.count else {throw DailySource.failure()}
        func groups(_ key:String,known:Set<Int>) throws -> [Int:Set<Int>] {
            guard let input=catalog[key] as? [String:[Int]],!input.isEmpty else {throw DailySource.failure()}
            var result:[Int:Set<Int>]=[:],used=Set<Int>()
            for (key,ids) in input {guard let id=Int(key),id > 0,!ids.isEmpty,Set(ids).count == ids.count,Set(ids).isSubset(of:known),used.isDisjoint(with:Set(ids)) else {throw DailySource.failure()};result[id]=Set(ids);used.formUnion(ids)}
            return result
        }
        let leagueGroups=try groups("leagueGroups",known:Set(clubs.map(\.id))),regionGroups=try groups("regionGroups",known:Set(countries.map(\.id)))
        let candidates=rows.filter {($0["clubID"] as? Int ?? 0) > 0}
        let generalRows=try DailySource.table(["id","firstName","lastName","nickname","image","countryID","grid","bingo"],root:root)
        func full(_ row:[String:Any]) -> String {guard let first=row["firstName"] as? String,!first.isEmpty,let last=row["lastName"] as? String,!last.isEmpty else {return ""};return Recall.normalize(first+" "+last)}
        let candidateNames=Dictionary(grouping:candidates,by:full),generalNames=Dictionary(grouping:generalRows,by:full),generalMap=Dictionary(uniqueKeysWithValues:general.map {($0.id,$0)})
        for (raw,portrait) in map {
            guard let id=Int(raw),let candidate=candidates.first(where:{$0["id"] as? Int == id}),generalMap["daily-general-\(portrait)"] != nil else {throw DailySource.failure()}
            let name=full(candidate)
            guard !name.isEmpty,candidateNames[name]?.count == 1,generalNames[name]?.count == 1,generalNames[name]?[0]["id"] as? Int == portrait else {throw DailySource.failure()}
        }
        let formatter=DateFormatter();formatter.locale=Locale(identifier:"en_US_POSIX");formatter.timeZone=zone;formatter.dateFormat="yyyy-MM-dd";formatter.isLenient=false
        guard let day=formatter.date(from:root["gameDate"] as! String) else {throw DailySource.failure()}
        formatter.dateFormat="MMMM d, yyyy"
        var calendar=Calendar(identifier:.gregorian);calendar.timeZone=zone
        var profiles:[GoltextoPlayer]=[]
        for row in candidates {
            guard let id=row["id"] as? Int,let club=row["clubID"] as? Int,clubs.contains(where:{$0.id == club}),let country=row["countryID"] as? Int,countries.contains(where:{$0.id == country}),
                  let ratingString=row["ovr"] as? String,let rating=Int(ratingString),(0...99).contains(rating),let positionsCSV=row["positions"] as? String else {throw DailySource.failure()}
            let positions=positionsCSV.split(separator:",").map {$0.trimmingCharacters(in:.whitespaces)}
            guard !positions.isEmpty,positions.allSatisfy({!$0.isEmpty}) else {throw DailySource.failure()}
            let first=row["firstName"] as? String ?? "",last=row["lastName"] as? String ?? "",nickname=row["nickname"] as? String ?? ""
            let fullName=(first+" "+last).trimmingCharacters(in:.whitespaces),name=nickname.isEmpty ? fullName:nickname
            guard !name.isEmpty else {throw DailySource.failure()}
            let photo=map[String(id)].flatMap {generalMap["daily-general-\($0)"]}
            let birth=(row["birthday"] as? String).flatMap {formatter.date(from:$0)}
            let age=birth.flatMap {$0 <= day ? calendar.dateComponents([.year],from:$0,to:day).year:nil}
            let player=GamePlayer(id:"daily-goltexto-\(id)",name:name,aliases:[name,fullName,first,last].filter {!$0.isEmpty},imageURL:photo?.imageURL,imageAsset:nil)
            profiles.append(GoltextoPlayer(player:player,clubID:club,countryID:country,rating:rating,positions:positions,age:age))
        }
        guard Set(profiles.map {$0.player.id}).count == profiles.count,let answer=profiles.first(where:{$0.player.id == "daily-goltexto-\(answerID)"}) else {throw DailySource.failure()}
        let portraitIDs=Set(map.values)
        let identity:[String:Any]=["version":1,"date":root["gameDate"]!,"zone":root["timeZone"]!,"selection":selection,"profiles":candidates,"clubs":clubRows,"portraits":generalRows.filter {portraitIDs.contains($0["id"] as? Int ?? -1)}]
        let signature=ContentUpdateRules.digest(try JSONSerialization.data(withJSONObject:identity,options:.sortedKeys))
        return Self(answer:answer,profiles:profiles,clubs:clubs,countries:countries,leagueGroups:leagueGroups,regionGroups:regionGroups,signature:signature)
    }
}
public struct GoltextoProgress: Codable, Sendable {
    public let signature:String
    public let sessionID:UUID
    public let limit:Int
    public var guesses:[String]=[]
    public var gaveUp=false
    public var reviewRecorded=false
    public init(round:DailyGoltexto,limit:Int=20) {signature=round.signature;sessionID=UUID();self.limit=limit}
    public func won(_ round:DailyGoltexto) -> Bool {guesses.last == round.answer.player.id}
    public func finished(_ round:DailyGoltexto) -> Bool {gaveUp || won(round) || guesses.count == limit}
    public func valid(for round:DailyGoltexto) -> Bool {signature == round.signature && [10,20,100].contains(limit) && guesses.count <= limit && Set(guesses).count == guesses.count && Set(guesses).isSubset(of:Set(round.players.map(\.id))) && !guesses.dropLast().contains(round.answer.player.id) && !(gaveUp && won(round)) && (!reviewRecorded || finished(round))}
    @discardableResult public mutating func guess(_ id:String,in round:DailyGoltexto) -> Bool {guard valid(for:round),!finished(round),round.profile(id) != nil,!guesses.contains(id) else {return false};guesses.append(id);return true}
    @discardableResult public mutating func reveal(in round:DailyGoltexto) -> Bool {guard valid(for:round),!finished(round) else {return false};gaveUp=true;return true}
}
extension DailyChallengeCache {
    public func progress(for round:DailyGoltexto) -> GoltextoProgress? {guard let data=try? Data(contentsOf:goltextoURL(round)),let value=try? JSONDecoder().decode(GoltextoProgress.self,from:data),value.valid(for:round) else {return nil};return value}
    public func save(_ value:GoltextoProgress,for round:DailyGoltexto) throws {guard value.valid(for:round) else {throw DailySource.failure()};try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true);try JSONEncoder().encode(value).write(to:goltextoURL(round),options:.atomic)}
    private func goltextoURL(_ round:DailyGoltexto) -> URL {directory.appendingPathComponent("goltexto-"+round.signature+".json")}
}
