import Foundation

public struct DailyBingo:DailyBingoRound {
    public let players:[GamePlayer]
    public let categories:[GameCategory]
    public let signature:String
    public let kind="bingo"
    public let helpRange=2...5
    public func player(_ id:String)->GamePlayer? {players.first {$0.id == id}}
    public func accepts(_ player:String,category:String)->Bool {categories.first {$0.id == category}?.playerIDs.contains(player) == true}
    static func load(root:[String:Any],general:[GamePlayer]) throws -> Self? {
        guard let game=(root["games"] as? [[String:Any]])?.first(where:{$0["id"] as? String == "bingo"}),let selection=game["selection"] as? [String:Any],let catalog=selection["catalog"] as? [String:Any] else {return nil}
        guard catalog["boardDate"] as? String == root["gameDate"] as? String,let playerURL=catalog["playerSourceURL"] as? String,let groupURL=catalog["categorySourceURL"] as? String,
              let tables=root["datasets"] as? [[String:Any]],let pt=tables.first(where:{$0["sourceURL"] as? String == playerURL && Set($0["fields"] as? [String] ?? []) == ["bingo","countryID","firstName","grid","id","image","lastName","nickname"]}),let rows=pt["data"] as? [[String:Any]],
              let gt=tables.first(where:{$0["sourceURL"] as? String == groupURL && Set($0["fields"] as? [String] ?? []) == ["id","logo","name","type"]}),let groups=gt["data"] as? [[String:Any]],let selected=selection["groups"] as? [[String:Any]],selected.count == 12 else {throw DailySource.failure()}
        var memberships:[String:Set<Int>]=[:]
        for row in rows {
            guard let id=row["id"] as? Int else {throw DailySource.failure()}
            if let csv=row["bingo"] as? String,!csv.isEmpty {
                let pieces=csv.split(separator:","),ids=pieces.compactMap {Int($0.trimmingCharacters(in:.whitespaces))}
                guard ids.count == pieces.count,!ids.isEmpty else {throw DailySource.failure()}
                memberships["daily-general-\(id)"]=Set(ids)
            }
        }
        let players=general.filter {memberships[$0.id] != nil}
        guard !players.isEmpty,Set(players.map(\.id)) == Set(memberships.keys) else {throw DailySource.failure()}
        var originals:[Int:[String:Any]]=[:]
        for group in groups {guard let id=group["id"] as? Int,originals[id] == nil else {throw DailySource.failure()};originals[id]=group}
        var categories:[GameCategory]=[],counts:[String:Int]=[:],ids:Set<Int>=[]
        for group in selected {
            guard let id=group["id"] as? Int,ids.insert(id).inserted,let original=originals[id],NSDictionary(dictionary:original).isEqual(to:group),let type=group["type"] as? String,let name=group["name"] as? String,!name.isEmpty,let logo=group["logo"] as? String else {throw DailySource.failure()}
            let eligible=players.filter {memberships[$0.id]!.contains(id)}.map(\.id)
            guard !eligible.isEmpty else {throw DailySource.failure()}
            counts[type == "country2" || type == "continent" ? "country2|continent":type,default:0] += 1
            categories.append(GameCategory(id:"daily-bingo-group-\(id)",title:name,playerIDs:eligible,imageAsset:nil,imageURL:try DailySource.image(logo),flag:nil))
        }
        guard counts == ["club":4,"club2":1,"country":2,"country2|continent":1,"extra":1,"award":2,"league":1] else {throw DailySource.failure()}
        let bytes=try JSONSerialization.data(withJSONObject:["date":root["gameDate"]!,"zone":root["timeZone"]!,"selection":selection,"players":rows],options:.sortedKeys)
        return Self(players:players,categories:categories,signature:ContentUpdateRules.digest(bytes))
    }
}
