import Foundation

public enum GraphGroup: String, Codable, CaseIterable, Identifiable, Sendable {
    case history, events, places, origins, other
    public var id: String {rawValue}
    public var title: String {switch self {case .history:"Club history";case .events:"Matches & moments";case .places:"Cities & venues";case .origins:"Countries";case .other:"Other relationships"}}
}
/// Authored claims supplement entity-valued facts without inferring links from
/// lessons, provider IDs, matching names, or shared clubs.
public struct GraphRelationship: Codable, Identifiable, Sendable {
    public let id: UUID
    public let key: String
    public let subjectID: UUID
    public let objectID: UUID
    public let group: GraphGroup
    public let label: String
    public let claim: String
    public let scope: String
    public let factIDs: [UUID]
}
public struct GraphEdge: Identifiable, Sendable {
    public let id: UUID
    public let subjectID: UUID
    public let objectID: UUID
    public let group: GraphGroup
    public let label: String
    public let claim: String
    public let scope: String
    public let factIDs: [UUID]
    public func other(_ id: UUID) -> UUID? {id == subjectID ? objectID : id == objectID ? subjectID : nil}
}
public struct GraphStep: Identifiable, Sendable {
    public var id: UUID {edge.id}
    public let fromID: UUID
    public let toID: UUID
    /// Original direction is preserved even when a path traverses backward.
    public let edge: GraphEdge
}
public struct KnowledgeGraph: Sendable {
    public let nodes: [Entity]
    public let edges: [GraphEdge]
    public init(pack: ContentPack) {
        nodes=pack.entities
        let authored=(pack.relationships ?? []).map {GraphEdge(id:$0.id,subjectID:$0.subjectID,objectID:$0.objectID,group:$0.group,label:$0.label,claim:$0.claim,scope:$0.scope,factIDs:$0.factIDs)}
        let derived=pack.facts.compactMap {fact -> GraphEdge? in
            guard let target=fact.value.entityID,target != fact.subjectID else {return nil}
            let isCountry=fact.predicate == "country" || fact.predicate.hasSuffix("-country")
            let careerLabels=["arce-first-division-debut-club":"First-division debut club","arce-veracruz-transfer":"Club joined in Verano 2002","riascos-professional-debut-club":"Professional debut club","riascos-china-scoring-title-club":"Club for the 2010 scoring title"]
            let baseGroup:GraphGroup=switch fact.predicate {case "club","previous","player":.history;case "opponent":.events;case "city","stadium":.places;default:.other}
            let baseLabel:String=switch fact.predicate {case "club":"Club in this period";case "previous":"Previous club";case "player":"Historical player";case "opponent":"Opponent in this context";case "city":"City connection";case "stadium":"Home stadium";default:fact.predicate}
            let group:GraphGroup=isCountry ? .origins : careerLabels[fact.predicate] != nil ? .history : baseGroup
            let label:String=isCountry ? "Country connection" : careerLabels[fact.predicate] ?? baseLabel
            return GraphEdge(id:fact.id,subjectID:fact.subjectID,objectID:target,group:group,label:label,claim:fact.evidence,scope:fact.scope,factIDs:[fact.id])
        }
        edges=(authored+derived).sorted {$0.id.uuidString < $1.id.uuidString}
    }
    public func neighbors(of id: UUID,groups: Set<GraphGroup> = Set(GraphGroup.allCases)) -> [GraphEdge] {
        edges.filter {groups.contains($0.group) && $0.other(id) != nil}.sorted {a,b in
            let an=nodes.first {$0.id == a.other(id)}?.name ?? "",bn=nodes.first {$0.id == b.other(id)}?.name ?? ""
            return an == bn ? a.id.uuidString < b.id.uuidString : an < bn
        }
    }
    /// Fewest supported edges under the chosen filters; nil means unsupported
    /// in this library, rather than proof that no real-world connection exists.
    public func shortestPath(from start: UUID,to end: UUID,groups: Set<GraphGroup> = Set(GraphGroup.allCases)) -> [GraphStep]? {
        let known=Set(nodes.map(\.id))
        guard known.contains(start),known.contains(end) else {return nil}
        if start == end {return []}
        var queue=[start],cursor=0,visited:Set<UUID>=[start],previous=[UUID:GraphStep]()
        while cursor < queue.count {
            let current=queue[cursor];cursor += 1
            for edge in neighbors(of:current,groups:groups) {
                guard let next=edge.other(current),visited.insert(next).inserted else {continue}
                previous[next]=GraphStep(fromID:current,toID:next,edge:edge)
                if next == end {
                    var result=[GraphStep](),node=end
                    while let step=previous[node] {result.append(step);node=step.fromID}
                    return result.reversed()
                }
                queue.append(next)
            }
        }
        return nil
    }
}
