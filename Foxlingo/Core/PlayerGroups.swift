import Foundation

public enum PlayerGroupMode: String, Codable, Sendable {
    case connections, impostor
}
public struct PlayerGroup: Codable, Sendable {
    public let categoryID: String
    public let playerIDs: [String]
}
public struct PlayerGroupProgress: Codable, Sendable {
    public let mode: PlayerGroupMode
    public let groups: [PlayerGroup]
    public let order: [String]
    public var selected: Set<String>
    public var solved: Set<String>
    public var checks: Int
    public var round: Int
    public var finished: Bool {mode == .connections ? solved.count == groups.count : round == groups.count}
    public var available: Set<String> {
        switch mode {
        case .connections:return Set(order).subtracting(groups.filter {solved.contains($0.categoryID)}.flatMap(\.playerIDs))
        case .impostor:
            guard groups.indices.contains(round) else {return []}
            let positives=groups[round].playerIDs
            let outsiders=groups[(round+1)%groups.count].playerIDs
            return Set(positives+outsiders)
        }
    }
    public mutating func select(_ id: String) {
        guard !finished,available.contains(id) else {return}
        if selected.contains(id) {selected.remove(id)} else if selected.count < 4 {selected.insert(id)}
    }
    /// Only exact round membership earns credit; this never grades scheduled recall.
    public mutating func check() -> Bool? {
        guard !finished,selected.count == 4 else {return nil}
        checks=min(checks+1,100_000)
        let found: PlayerGroup?
        if mode == .connections {found=groups.first {!solved.contains($0.categoryID) && Set($0.playerIDs) == selected}}
        else {found=Set(groups[round].playerIDs) == selected ? groups[round] : nil}
        guard let found else {return false}
        solved.insert(found.categoryID);selected=[]
        if mode == .impostor {round+=1}
        return true
    }
}
public enum PlayerGroupDeck {
    // Restrict seed-generated boards to explicit country categories with cached flags.
    // Arbitrary missing club membership is not evidence of an outsider's career.
    private static let categoryIDs=["category-23","category-24","category-28","category-30"]
    public static func signature(_ pack: GamePack) -> String {
        let categories=categoryIDs.compactMap(pack.category)
        let ids=Set(categories.flatMap(\.playerIDs))
        let players=pack.connectionPlayers.filter {ids.contains($0.id)}
        return ContentUpdateRules.digest(ContentUpdateRules.bytes(categories)+ContentUpdateRules.bytes(players))
    }
    public static func make(mode: PlayerGroupMode,pack: GamePack,randomized: Bool=true,availableArtwork: Set<String>=[]) -> PlayerGroupProgress? {
        let active=Set(pack.connectionPlayers.map(\.id))
        let categories=categoryIDs.compactMap(pack.category)
        guard categories.count == 4,categories.allSatisfy({$0.imageAsset?.hasPrefix("flag-") == true}) else {return nil}
        var groups: [PlayerGroup]=[]
        for category in categories {
            let others=Set(categories.filter {$0.id != category.id}.flatMap(\.playerIDs))
            let eligible=Set(category.playerIDs).intersection(active).subtracting(others)
            let players=pack.connectionPlayers.filter {eligible.contains($0.id)}
            // Prefer available portraits, then known names, without changing eligibility.
            let cached=players.filter {$0.imageAsset.map(availableArtwork.contains) ?? false}.sorted {$0.id < $1.id}
            let remote=players.filter {!($0.imageAsset.map(availableArtwork.contains) ?? false) && $0.imageURL != nil}.sorted {$0.id < $1.id}
            let fallback=players.filter {!($0.imageAsset.map(availableArtwork.contains) ?? false) && $0.imageURL == nil}.sorted {$0.id < $1.id}
            let candidates=randomized ? cached.shuffled()+remote.shuffled()+fallback.shuffled() : cached+remote+fallback
            guard candidates.count >= 4 else {return nil}
            groups.append(PlayerGroup(categoryID:category.id,playerIDs:candidates.prefix(4).map(\.id)))
        }
        if randomized {groups.shuffle()}
        let ids=groups.flatMap(\.playerIDs)
        // Interleave groups in deterministic test boards; do not display solved groups together.
        let order=randomized ? ids.shuffled() : (0..<4).flatMap {i in groups.map {$0.playerIDs[i]}}
        return PlayerGroupProgress(mode:mode,groups:groups,order:order,selected:[],solved:[],checks:0,round:0)
    }
    public static func restore(_ saved: GameResume,mode: PlayerGroupMode,pack: GamePack,completedSessions: Set<UUID>) -> PlayerGroupProgress? {
        guard saved.schemaVersion == 1,saved.signature == signature(pack),!completedSessions.contains(saved.sessionID),saved.board == nil,saved.memory == nil,saved.mystery == nil,saved.timeline == nil,saved.wordle == nil,
              let board=saved.grouping,board.mode == mode,!board.finished,board.groups.count == 4,Set(board.groups.map(\.categoryID)) == Set(categoryIDs),
              board.checks >= board.solved.count,board.checks <= 100_000,board.round >= 0,board.round < 4,
              Set(board.groups.flatMap(\.playerIDs)).count == 16,board.order.count == 16,Set(board.order) == Set(board.groups.flatMap(\.playerIDs)),
              board.solved.isSubset(of:Set(categoryIDs)),board.selected.count <= 4,board.selected.isSubset(of:board.available) else {return nil}
        let active=Set(pack.connectionPlayers.map(\.id))
        for group in board.groups {
            guard group.playerIDs.count == 4,let category=pack.category(group.categoryID),Set(group.playerIDs).isSubset(of:active.intersection(category.playerIDs)) else {return nil}
            for other in board.groups where other.categoryID != group.categoryID {
                guard let competing=pack.category(other.categoryID),Set(group.playerIDs).isDisjoint(with:competing.playerIDs) else {return nil}
            }
        }
        guard mode == .connections ? board.round == 0 : board.solved == Set(board.groups.prefix(board.round).map(\.categoryID)) else {return nil}
        return board
    }
}
