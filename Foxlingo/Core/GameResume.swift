import Foundation

public struct BoardProgress: Codable, Sendable {
    public let squadID: String?
    public let placed: [Int:String]
    public let history: [Int]
    public let assisted: Set<Int>
    public let offered: String?
    public init(squadID: String?,placed: [Int:String],history: [Int],assisted: Set<Int>,offered: String?) {
        self.squadID=squadID;self.placed=placed;self.history=history;self.assisted=assisted;self.offered=offered
    }
}
public struct MysteryProgress: Codable, Sendable {
    public let roundIDs: [UUID]
    public let index: Int
    public let revealed: Int
    public let solved: Bool
    public let guesses: Int
    public let clueCounts: [Int]
    public let pendingMistake: Bool?
    public init(roundIDs: [UUID],index: Int,revealed: Int,solved: Bool,guesses: Int,clueCounts: [Int],pendingMistake: Bool?=nil) {
        self.roundIDs=roundIDs;self.index=index;self.revealed=revealed;self.solved=solved;self.guesses=guesses;self.clueCounts=clueCounts;self.pendingMistake=pendingMistake
    }
}
public struct GameResume: Codable, Sendable {
    public var schemaVersion=1
    public let signature: String
    public let sessionID: UUID
    public let board: BoardProgress?
    public let mystery: MysteryProgress?
    public let memory: MemoryProgress?
    public let timeline: TimelineProgress?
    public let wordle: WordleProgress?
    public let grouping: PlayerGroupProgress?
    public init(signature: String,sessionID: UUID,board: BoardProgress?=nil,mystery: MysteryProgress?=nil,memory: MemoryProgress?=nil,timeline: TimelineProgress?=nil,wordle: WordleProgress?=nil,grouping: PlayerGroupProgress?=nil) {
        self.signature=signature;self.sessionID=sessionID;self.board=board;self.mystery=mystery;self.memory=memory;self.timeline=timeline;self.wordle=wordle;self.grouping=grouping
    }
    static var invalid: Self {var value=Self(signature:"",sessionID:UUID());value.schemaVersion=0;return value}
}
/// Lossy only at the optional game boundary; a malformed board cannot erase learning history.
public struct GameResumeCollection: Codable, Sendable {
    public var values: [String:GameResume]
    public init(values: [String:GameResume]=[:]) {self.values=values}
    private struct Key: CodingKey {let stringValue: String;var intValue: Int? {nil};init?(stringValue: String) {self.stringValue=stringValue};init?(intValue: Int) {return nil}}
    public init(from decoder: Decoder) throws {
        guard let container=try? decoder.container(keyedBy:Key.self) else {values=["invalid":.invalid];return}
        values=[:]
        for key in container.allKeys {values[key.stringValue]=(try? container.decode(GameResume.self,forKey:key)) ?? .invalid}
    }
    public func encode(to encoder: Encoder) throws {try values.encode(to:encoder)}
}
public enum GameResumeRules {
    public static func candidates(kind: String,pack: GamePack,squadID: String?) -> [Set<String>]? {
        switch kind {
        case "bingo":return pack.bingoCategoryIDs.map {Set(pack.category($0)!.playerIDs)}
        case "grid":return (0..<9).map {pack.gridCandidates(row:$0/3,column:$0%3)}
        case "lineup":guard let squad=pack.lineups.first(where:{$0.id == squadID}) else {return nil};return (0..<11).map(squad.candidates)
        default:return nil
        }
    }
    private struct BoardIdentity: Encodable {
        let kind: String
        let scope: String
        let layout: [String]
        let candidates: [[String]]
        let names: [String:String]
    }
    public static func boardSignature(kind: String,pack: GamePack,squadID: String?) -> String? {
        guard let candidates=candidates(kind:kind,pack:pack,squadID:squadID) else {return nil}
        let layout: [String],scope: String
        switch kind {
        case "bingo":layout=pack.bingoCategoryIDs.flatMap {[$0,pack.category($0)!.title]};scope=pack.scope
        case "grid":layout=(pack.gridRowIDs+pack.gridColumnIDs).flatMap {[$0,pack.category($0)!.title]};scope=pack.scope
        default:
            let squad=pack.lineups.first {$0.id == squadID}!
            layout=[squad.id,squad.title]+squad.positions;scope=squad.scope
        }
        let ids=Set(candidates.flatMap {$0})
        let names=Dictionary(uniqueKeysWithValues:pack.players.filter {ids.contains($0.id)}.map {($0.id,$0.name)})
        return ContentUpdateRules.digest(ContentUpdateRules.bytes(BoardIdentity(kind:kind,scope:scope,layout:layout,candidates:candidates.map {$0.sorted()},names:names)))
    }
    public static func restoreBoard(_ resume: GameResume,kind: String,pack: GamePack,completedSessions: Set<UUID>) -> BoardProgress? {
        guard resume.grouping == nil,resume.wordle == nil,resume.schemaVersion == 1,!completedSessions.contains(resume.sessionID),resume.mystery == nil,resume.memory == nil,resume.timeline == nil,
              let board=resume.board,let candidates=candidates(kind:kind,pack:pack,squadID:board.squadID),
              resume.signature == boardSignature(kind:kind,pack:pack,squadID:board.squadID),
              board.placed.count < candidates.count,Set(board.placed.values).count == board.placed.count,
              board.history.count == board.placed.count,Set(board.history) == Set(board.placed.keys),
              board.assisted.isSubset(of:Set(board.placed.keys)),
              board.placed.allSatisfy({candidates.indices.contains($0.key) && candidates[$0.key].contains($0.value)}) else {return nil}
        if kind == "bingo" {
            if let offered=board.offered {
                guard pack.player(offered) != nil,!board.placed.values.contains(offered),
                      candidates.enumerated().contains(where:{board.placed[$0.offset] == nil && $0.element.contains(offered)}) else {return nil}
            } else {
                let used=Set(board.placed.values)
                guard !candidates.enumerated().contains(where:{board.placed[$0.offset] == nil && !$0.element.isSubset(of:used)}) else {return nil}
            }
        } else if board.offered != nil {return nil}
        // A legal dead end remains resumable and recoverable through Undo.
        return board
    }
    private struct FactIdentity: Encodable {
        let id: UUID
        let subjectID: UUID
        let predicate: String
        let value: FactValue
        let scope: String
    }
    public static func mysterySignature(_ rounds: [MysteryRound]) -> String {
        var data=Data()
        for round in rounds.sorted(by:{$0.id.uuidString < $1.id.uuidString}) {
            data.append(ContentUpdateRules.bytes(round.definition))
            data.append(ContentUpdateRules.bytes(round.player.name))
            for fact in round.facts.values.sorted(by:{$0.id.uuidString < $1.id.uuidString}) {data.append(ContentUpdateRules.bytes(FactIdentity(id:fact.id,subjectID:fact.subjectID,predicate:fact.predicate,value:fact.value,scope:fact.scope)))}
        }
        return ContentUpdateRules.digest(data)
    }
    public static func restoreMystery(_ resume: GameResume,rounds: [MysteryRound],completedSessions: Set<UUID>) -> MysteryProgress? {
        guard resume.grouping == nil,resume.wordle == nil,resume.schemaVersion == 1,!completedSessions.contains(resume.sessionID),resume.board == nil,resume.memory == nil,resume.timeline == nil,
              resume.signature == mysterySignature(rounds),let progress=resume.mystery,
              progress.roundIDs.count == rounds.count,Set(progress.roundIDs) == Set(rounds.map(\.id)),
              rounds.indices.contains(progress.index),progress.clueCounts.count == progress.index,
              progress.clueCounts.allSatisfy({(1...3).contains($0)}),
              (1...3).contains(progress.revealed),(0...100_000).contains(progress.guesses),
              !progress.solved || progress.guesses > 0 else {return nil}
        return progress
    }
}
extension LearnerState {
    public func savedGame(_ kind: String) -> GameResume? {gameResumes?.values[kind]}
    public mutating func storeGame(_ resume: GameResume,kind: String) {
        if gameResumes == nil {gameResumes=GameResumeCollection()}
        gameResumes?.values[kind]=resume
    }
    public mutating func removeSavedGame(_ kind: String) {gameResumes?.values.removeValue(forKey:kind)}
}
