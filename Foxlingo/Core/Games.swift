import Foundation

public struct GamePlayer: Codable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let aliases: [String]
    public let imageURL: String?
    public let imageAsset: String?
}
public struct GameCategory: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let playerIDs: [String]
    public let imageAsset: String?
    public let imageURL: String?
    public let flag: String?
}
public struct SquadMember: Codable, Sendable {
    public let playerID: String
    public let positions: [String]
}
public struct ClassicSquad: Codable, Identifiable, Sendable {
    public let clubName: String?
    public let imageURL: String?
    public let rows: [[Int]]?
    public let id: String
    public let title: String
    public let scope: String
    public let source: String
    public let members: [SquadMember]
    public let positions: [String]
    public func candidates(at index: Int) -> Set<String> {
        guard positions.indices.contains(index) else { return [] }
        return Set(members.filter { $0.positions.contains(positions[index]) }.map(\.playerID))
    }
}
public struct GamePack: Codable, Sendable {
    public let fetchedAt: String?
    public let schemaVersion: Int
    public let scope: String
    public let sourceURL: String
    public let players: [GamePlayer]
    public let categories: [GameCategory]
    public let bingoCategoryIDs: [String]
    public let gridRowIDs: [String]
    public let gridColumnIDs: [String]
    public let lineups: [ClassicSquad]
    public func player(_ id: String) -> GamePlayer? { players.first { $0.id == id } }
    public func category(_ id: String) -> GameCategory? { categories.first { $0.id == id } }
    public func gridCandidates(row: Int, column: Int) -> Set<String> {
        guard gridRowIDs.indices.contains(row), gridColumnIDs.indices.contains(column), let r=category(gridRowIDs[row]), let c=category(gridColumnIDs[column]) else {return []}
        return Set(r.playerIDs).intersection(c.playerIDs)
    }
    public static func load(_ data: Data) throws -> Self {
        let p=try JSONDecoder().decode(Self.self,from:data)
        try p.validate(); return p
    }
    public func validate() throws {
        let ids=Set(players.map(\.id)), cats=Set(categories.map(\.id))
        guard schemaVersion == 1, ids.count == players.count, cats.count == categories.count,
              players.allSatisfy({ !$0.name.isEmpty && !$0.aliases.isEmpty }),
              categories.allSatisfy({ !$0.playerIDs.isEmpty && Set($0.playerIDs).isSubset(of:ids) }),
              bingoCategoryIDs.count == 12, Set(bingoCategoryIDs).count == 12,
              gridRowIDs.count == 3, gridColumnIDs.count == 3, !lineups.isEmpty,
              Set(bingoCategoryIDs + gridRowIDs + gridColumnIDs).isSubset(of:cats) else {throw ContentError.invalid("Invalid game relationships.")}
        let bingo=bingoCategoryIDs.map {Set(category($0)!.playerIDs)}
        let grid=(0..<9).map {gridCandidates(row:$0/3,column:$0%3)}
        guard BoardMatcher.solution(bingo) != nil, BoardMatcher.solution(grid) != nil else {throw ContentError.invalid("Game board cannot be completed with distinct players.")}
        for s in lineups {
            if let rows=s.rows {
                guard !rows.isEmpty,rows.allSatisfy({!$0.isEmpty && $0.count <= 5}),rows.flatMap({$0}).sorted() == Array(0..<11) else {throw ContentError.invalid("Invalid formation rows.")}
            }
            guard s.positions.count == 11, Set(s.members.map(\.playerID)).count == s.members.count,
                  Set(s.members.map(\.playerID)).isSubset(of:ids), !s.scope.isEmpty,
                  BoardMatcher.solution((0..<11).map(s.candidates)) != nil else {throw ContentError.invalid("Invalid classic squad.")}
        }
    }
}
/// A bipartite matcher ensures every board remains solvable without reusing a player.
public enum BoardMatcher {
    public static func solution(_ candidates: [Set<String>], fixed: [Int:String] = [:], randomized: Bool = false) -> [Int:String]? {
        guard Set(fixed.values).count == fixed.count,
              fixed.allSatisfy({ candidates.indices.contains($0.key) && candidates[$0.key].contains($0.value) }) else {return nil}
        var playerToSlot=Dictionary(uniqueKeysWithValues:fixed.map{($0.value,$0.key)})
        func assign(_ slot: Int, _ visited: inout Set<String>) -> Bool {
            for player in (randomized ? Array(candidates[slot]).shuffled() : candidates[slot].sorted()) where !visited.contains(player) {
                visited.insert(player)
                if let other=playerToSlot[player] {
                    if fixed[other] != nil {continue}
                    if !assign(other,&visited) {continue}
                }
                playerToSlot[player]=slot;return true
            }
            return false
        }
        for slot in candidates.indices where fixed[slot] == nil {
            var seen=Set<String>();if !assign(slot,&seen) {return nil}
        }
        return Dictionary(uniqueKeysWithValues:playerToSlot.map{($0.value,$0.key)})
    }
    public static func accepts(player: String, slot: Int, candidates: [Set<String>], placed: [Int:String]) -> Bool {
        candidates.indices.contains(slot) && placed[slot] == nil && !placed.values.contains(player) && candidates[slot].contains(player)
    }
}

/// Face-down association matching. A pending mismatch must close before another turn.
public struct MemoryMatch: Sendable {
    public enum Turn: Equatable {case ignored, revealed, matched(String), mismatch}
    public let pairs: [Pair]
    public private(set) var faceUp: [String] = []
    public private(set) var matched: Set<String>
    public init(pairs: [Pair], completed: [String] = []) {
        self.pairs=pairs
        matched=Set(pairs.filter{completed.contains($0.left)}.flatMap{[$0.left,$0.right]})
    }
    public func isVisible(_ id: String) -> Bool {matched.contains(id) || faceUp.contains(id)}
    public var waitingToClose: Bool {faceUp.count == 2}
    public mutating func flip(_ id: String) -> Turn {
        guard !waitingToClose, !isVisible(id), pairs.contains(where:{$0.left == id || $0.right == id}) else {return .ignored}
        faceUp.append(id)
        guard faceUp.count == 2 else {return .revealed}
        if let pair=pairs.first(where:{Set([$0.left,$0.right]) == Set(faceUp)}) {
            matched.formUnion(faceUp);faceUp=[];return .matched(pair.left)
        }
        return .mismatch
    }
    public mutating func closeMismatch() {faceUp=[]}
}
