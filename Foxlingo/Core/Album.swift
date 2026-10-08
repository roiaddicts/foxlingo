import Foundation

public enum AlbumScope: String, CaseIterable, Identifiable, Sendable {
    case favorites, all, competitions, champions, bundesliga, ligamx
    public var id: String {rawValue}
    public var title: String {switch self {case .favorites:"Favorites";case .all:"All subjects";case .competitions:"Competitions";case .champions:"Champions League";case .bundesliga:"Bundesliga";case .ligamx:"Liga MX"}}
}
public struct AlbumSection: Identifiable, Sendable {
    public var id: UUID {subjectID}
    public let subjectID: UUID
    public let cards: [AlbumCard]
}
public struct AlbumCollection: Sendable {
    public let total: Int
    public let discovered: Int
    public let visibleCount: Int
    public let sections: [AlbumSection]
    public static func make(pack: ContentPack,state: LearnerState,scope: AlbumScope,discoveredOnly: Bool,query: String) -> Self {
        let clubs=pack.clubRoadmaps.filter {r in
            let club=pack.entity(r.entityID)
            switch scope {
            case .all:return true
            case .competitions:return false
            case .favorites:return ["entity-xolos","entity-madrid"].contains(club.key)
            default:return club.competitions?.contains(scope.rawValue) == true
            }
        }
        let competitions=pack.competitionRoadmaps.filter {r in
            switch scope {
            case .all,.competitions:return true
            case .favorites:return false
            default:return pack.entity(r.entityID).competitions?.contains(scope.rawValue) == true
            }
        }
        let roadmaps=competitions+clubs
        func linkedCards(_ roadmap: Roadmap) -> [AlbumCard] {
            if pack.entity(roadmap.entityID).type == "competition" {return pack.cards.filter {$0.entityID == roadmap.entityID}}
            let lessons=Set(roadmap.chapters.flatMap(\.lessonIDs))
            return pack.cards.filter {!lessons.isDisjoint(with:Set($0.lessonIDs))}
        }
        var associatedNames=[UUID:[String]]()
        for roadmap in roadmaps {
            let club=pack.entity(roadmap.entityID)
            for card in linkedCards(roadmap) {associatedNames[card.id,default:[]] += [club.name]+club.aliases}
        }
        var seen=Set<UUID>(), total=0, discovered=0, visible=0
        var sections=[AlbumSection]()
        let search=Recall.normalize(query)
        for r in roadmaps {
            let cards=linkedCards(r).filter {seen.insert($0.id).inserted}
            total += cards.count;discovered += cards.filter {state.acquiredCards.contains($0.id)}.count
            let matches=cards.filter {card in
                let entity=pack.entity(card.entityID)
                return (!discoveredOnly || state.acquiredCards.contains(card.id)) && (search.isEmpty || ([entity.name,card.caption]+entity.aliases+(associatedNames[card.id] ?? [])).contains {Recall.normalize($0).contains(search)})
            }
            if !matches.isEmpty {sections.append(AlbumSection(subjectID:r.entityID,cards:matches));visible += matches.count}
        }
        return Self(total:total,discovered:discovered,visibleCount:visible,sections:sections)
    }
}
public struct CardAchievement: Codable, Sendable {
    public let tier: Int
    public let knowledgeVersion: Int?
}
public struct CardReadiness: Sendable {
    public let introduced: Int
    public let missing: Int
    public let refresh: Int
    public let due: Int
    public let currentStage: Int?
    public static func make(card: AlbumCard,pack: ContentPack,state: LearnerState,now: Date) -> Self {
        var introduced=0,missing=0,refresh=0,due=0,stages=[Int]()
        for id in Set(card.objectiveIDs) {
            guard let review=state.reviews[id] else {missing += 1;continue}
            let current=review.revision == pack.objective(id).revision
            if !current || review.refreshRequired == true {refresh += 1} else {introduced += 1;stages.append(review.stage)}
            if current && review.due <= now {due += 1}
        }
        return Self(introduced:introduced,missing:missing,refresh:refresh,due:due,currentStage:missing == 0 && refresh == 0 ? stages.min() : nil)
    }
    public static func scopeLabel(card: AlbumCard,pack: ContentPack) -> String {
        let type=pack.entity(card.entityID).type
        let title=type == "player" ? "Player story" : type == "club" ? (card.objectiveIDs.count == 3 ? "Intro" : "Club foundations") : type == "competition" ? "Competition foundations" : "Knowledge set"
        return "\(title) · \(card.objectiveIDs.count) connections"
    }
}
extension LearnerState {
    /// Cache achievements before future additive set changes. Current recall
    /// remains tied to the active pack; an older earned version stays visible.
    public mutating func captureCardAchievements(_ pack: ContentPack) {
        for card in pack.cards where acquiredCards.contains(card.id) {
            let derived=card.objectiveIDs.map {reviews[$0]?.highestEarned ?? 0}.min() ?? 0
            let previous=cardAchievements?[card.id]
            let current=card.objectiveIDs.allSatisfy {id in reviews[id].map {$0.revision == pack.objective(id).revision && $0.refreshRequired != true} ?? false}
            let demonstrated=card.objectiveIDs.allSatisfy {reviews[$0].map {$0.stage >= derived} ?? false}
            if previous == nil || (current && derived > previous!.tier && (previous!.knowledgeVersion == card.knowledgeVersion || demonstrated)) {
                if cardAchievements == nil {cardAchievements=[:]}
                cardAchievements?[card.id]=CardAchievement(tier:derived,knowledgeVersion:derived == 0 || (current && demonstrated) ? card.knowledgeVersion : nil)
            } else if current,let previous,previous.knowledgeVersion != card.knowledgeVersion,card.objectiveIDs.allSatisfy({reviews[$0]!.stage >= previous.tier}) {
                cardAchievements?[card.id]=CardAchievement(tier:previous.tier,knowledgeVersion:card.knowledgeVersion)
            }
        }
    }
}
