import Foundation

public struct DraftProfile: Codable, Sendable {
    public let person: GamePlayer
    public let positions: [String]
}
public struct DraftGroup: Codable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let distinctKey: String
    public let imageAsset: String
    public let imageURL: String
    public let playerIDs: [String]
}
public struct DraftMode: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let scope: String
    public let sourceURL: String
    public let groups: [DraftGroup]
}
public struct DraftFormation: Codable, Sendable, Identifiable {
    public let id: String
    public let positions: [String]
    public let rows: [[Int]]
}
public struct DraftPack: Codable, Sendable {
    public let schemaVersion: Int
    public let fetchedAt: String
    public let sourceURL: String
    public let players: [DraftProfile]
    public let formations: [DraftFormation]
    public let modes: [DraftMode]
    public static func load(_ data: Data) throws -> Self {
        let pack=try JSONDecoder().decode(Self.self,from:data)
        let codes=Set(["GK","LB","CB","RB","LWB","RWB","CDM","CM","CAM","LM","RM","LW","RW","ST","CF"])
        let ids=Set(pack.players.map { $0.person.id })
        guard pack.schemaVersion == 1,!pack.players.isEmpty,ids.count == pack.players.count,
              pack.players.allSatisfy({!$0.person.name.isEmpty && !$0.positions.isEmpty && Set($0.positions).isSubset(of:codes)}),
              !pack.formations.isEmpty,Set(pack.formations.map(\.id)).count == pack.formations.count,
              pack.formations.allSatisfy({$0.positions.count == 11 && Set($0.positions).isSubset(of:codes) && $0.rows.flatMap {$0}.sorted() == Array(0..<11) && $0.rows.allSatisfy {!$0.isEmpty}}),
              Set(pack.modes.map(\.id)).count == pack.modes.count,!pack.modes.isEmpty,
              pack.modes.allSatisfy({mode in
                  !mode.scope.isEmpty && URL(string:mode.sourceURL)?.scheme == "https" && Set(mode.groups.map(\.id)).count == mode.groups.count && Set(mode.groups.map(\.distinctKey)).count >= 11 && mode.groups.allSatisfy {
                      !$0.name.isEmpty && !$0.playerIDs.isEmpty && Set($0.playerIDs).count == $0.playerIDs.count && Set($0.playerIDs).isSubset(of:ids) && URL(string:$0.imageURL)?.scheme == "https"
                  }
              }) else {throw ContentError.invalid("The XI drafting content contains invalid identities or positions.")}
        return pack
    }
}
public struct DraftPick: Codable, Sendable {
    public let groupID: String
    public let playerID: String
}
public struct DraftProgress: Codable, Sendable {
    public let modeID: String
    public let formationID: String
    public let groupIDs: [String]
    public var placed: [Int:DraftPick]
    public var history: [Int]
    public var assisted: Set<Int>
    public var finished: Bool {placed.count == 11}
    public var offeredID: String? {groupIDs.indices.contains(placed.count) ? groupIDs[placed.count] : nil}
    public mutating func undo() {
        guard let slot=history.popLast() else {return}
        placed.removeValue(forKey:slot);assisted.remove(slot)
    }
}
/// Indexed once per screen; source namespaces and explicit membership remain authoritative.
public struct DraftEngine: Sendable {
    public let pack: DraftPack
    public let mode: DraftMode
    public let profiles: [String:DraftProfile]
    public let groups: [String:DraftGroup]
    public let allowsRepeatedPlayers: Bool
    public init(pack: DraftPack,mode: DraftMode,allowsRepeatedPlayers: Bool=false) {
        self.pack=pack;self.mode=mode
        self.allowsRepeatedPlayers=allowsRepeatedPlayers
        profiles=Dictionary(uniqueKeysWithValues:pack.players.map {($0.person.id,$0)})
        groups=Dictionary(uniqueKeysWithValues:mode.groups.map {($0.id,$0)})
    }
    public func formation(_ board: DraftProgress) -> DraftFormation? {pack.formations.first {$0.id == board.formationID}}
    public func accepts(_ playerID: String,at slot: Int,on board: DraftProgress) -> Bool {
        guard let formation=formation(board),formation.positions.indices.contains(slot),board.placed[slot] == nil,
              (allowsRepeatedPlayers || !board.placed.values.contains(where:{$0.playerID == playerID})),let id=board.offeredID,let group=groups[id],
              group.playerIDs.contains(playerID),let player=profiles[playerID] else {return false}
        return player.positions.contains(formation.positions[slot])
    }
    public func place(_ playerID: String,at slot: Int,on board: inout DraftProgress,assisted: Bool=false) -> Bool {
        guard accepts(playerID,at:slot,on:board),let id=board.offeredID else {return false}
        board.placed[slot]=DraftPick(groupID:id,playerID:playerID);board.history.append(slot)
        if assisted {board.assisted.insert(slot)}
        return true
    }
    /// Finds a full matching of groups, people and positions, including already placed picks.
    /// Bounded work prevents an unsatisfiable historical pool from blocking the UI.
    public func solution(_ board: DraftProgress,nodeLimit: Int=30_000) -> [Int:DraftPick]? {
        guard valid(board,allowFinished:true),let formation=formation(board) else {return nil}
        var placed=board.placed,used=Set(placed.values.map(\.playerID)),budget=nodeLimit
        let remaining=Array(board.groupIDs.dropFirst(placed.count))
        func search(_ pending: [String]) -> Bool {
            if pending.isEmpty {return true}
            budget-=1;guard budget >= 0 else {return false}
            var chosen="",options: [(Int,String)]=[]
            for id in pending {
                guard let group=groups[id] else {return false}
                var eligible: [(Int,String)]=[]
                for slot in formation.positions.indices where placed[slot] == nil {
                    for playerID in group.playerIDs where (allowsRepeatedPlayers || !used.contains(playerID)) && profiles[playerID]?.positions.contains(formation.positions[slot]) == true {eligible.append((slot,playerID))}
                }
                if eligible.isEmpty {return false}
                if chosen.isEmpty || eligible.count < options.count {chosen=id;options=eligible}
            }
            let next=pending.filter {$0 != chosen}
            for (slot,player) in options {
                placed[slot]=DraftPick(groupID:chosen,playerID:player);if !allowsRepeatedPlayers {used.insert(player)}
                if search(next) {return true}
                placed.removeValue(forKey:slot);if !allowsRepeatedPlayers {used.remove(player)}
                if budget < 0 {return false}
            }
            return false
        }
        return search(remaining) ? placed : nil
    }
    public func make(formationID: String="433",randomized: Bool=true) -> DraftProgress? {
        guard pack.formations.contains(where:{$0.id == formationID}) else {return nil}
        for _ in 0..<40 {
            var seen=Set<String>()
            let candidates=randomized ? mode.groups.shuffled() : mode.groups
            let selected=candidates.filter {seen.insert($0.distinctKey).inserted}.prefix(11)
            let board=DraftProgress(modeID:mode.id,formationID:formationID,groupIDs:selected.map(\.id),placed:[:],history:[],assisted:[])
            if solution(board) != nil {return board}
            if !randomized {break}
        }
        return nil
    }
    public func valid(_ board: DraftProgress,allowFinished: Bool=false) -> Bool {
        guard board.modeID == mode.id,let f=formation(board),board.groupIDs.count == 11,
              Set(board.groupIDs).count == 11,board.groupIDs.allSatisfy({groups[$0] != nil}),
              Set(board.groupIDs.compactMap {groups[$0]?.distinctKey}).count == 11,
              board.placed.count <= (allowFinished ? 11 : 10),(allowsRepeatedPlayers || Set(board.placed.values.map(\.playerID)).count == board.placed.count),
              board.history.count == board.placed.count,Set(board.history) == Set(board.placed.keys),board.assisted.isSubset(of:Set(board.history)) else {return false}
        for (index,slot) in board.history.enumerated() {
            guard f.positions.indices.contains(slot),let pick=board.placed[slot],pick.groupID == board.groupIDs[index],
                  groups[pick.groupID]?.playerIDs.contains(pick.playerID) == true,profiles[pick.playerID]?.positions.contains(f.positions[slot]) == true else {return false}
        }
        return true
    }
    public var signature: String {
        let ids=Set(mode.groups.flatMap(\.playerIDs))
        let bytes=ContentUpdateRules.bytes(mode)+ContentUpdateRules.bytes(pack.formations)+ContentUpdateRules.bytes(pack.players.filter {ids.contains($0.person.id)})
        return ContentUpdateRules.digest(allowsRepeatedPlayers ? bytes+ContentUpdateRules.bytes(["repeated-source-picks"]):bytes)
    }
    public func restore(_ saved: GameResume,completedSessions: Set<UUID>) -> DraftProgress? {
        guard saved.schemaVersion == 1,saved.signature == signature,!completedSessions.contains(saved.sessionID),
              saved.board == nil,saved.mystery == nil,saved.memory == nil,saved.timeline == nil,saved.wordle == nil,saved.grouping == nil,
              let board=saved.draft,valid(board) else {return nil}
        return board
    }
}
