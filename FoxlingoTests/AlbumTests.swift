import XCTest
@testable import FoxlingoCore

final class AlbumTests: XCTestCase {
    var pack: ContentPack!
    let now=Date(timeIntervalSince1970:1_800_000_000)
    override func setUpWithError() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
    }
    func testCollectionCountsStayHonestUnderSearchAndDiscoveredFilter() {
        var state=LearnerState()
        state.acquiredCards=[pack.cards[0].id,UUID()]
        let collection=AlbumCollection.make(pack:pack,state:state,scope:.favorites,discoveredOnly:true,query:"")
        XCTAssertEqual(collection.total,14);XCTAssertEqual(collection.discovered,1);XCTAssertEqual(collection.visibleCount,1)
        let search=AlbumCollection.make(pack:pack,state:state,scope:.favorites,discoveredOnly:false,query:"no such player")
        XCTAssertEqual(search.total,14);XCTAssertEqual(search.discovered,1);XCTAssertEqual(search.visibleCount,0);XCTAssertTrue(search.sections.isEmpty)
    }
    func testCompetitionUsesHistoricalRoadmapMembershipAndDeduplicates() {
        let state=LearnerState()
        let all=AlbumCollection.make(pack:pack,state:state,scope:.all,discoveredOnly:false,query:"")
        XCTAssertEqual(all.total,136)
        XCTAssertEqual(Set(all.sections.flatMap{$0.cards.map(\.id)}).count,136)
        let champions=AlbumCollection.make(pack:pack,state:state,scope:.champions,discoveredOnly:false,query:"")
        let cards=champions.sections.flatMap(\.cards)
        XCTAssertTrue(cards.contains {$0.key == "card-cristiano"})
        XCTAssertFalse(cards.contains {$0.key == "card-xolos"})
        let german=AlbumCollection.make(pack:pack,state:state,scope:.bundesliga,discoveredOnly:false,query:"")
        XCTAssertEqual(german.total,31)
    }
    func testSharedCardSearchMatchesEveryRelatedClub() throws {
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        var cards=json["cards"] as! [[String:Any]]
        let index=cards.firstIndex {$0["key"] as! String == "card-riascos"}!
        let madrid=pack.roadmaps.first {$0.key == "roadmap-madrid"}!
        cards[index]["lessonIDs"]=(cards[index]["lessonIDs"] as! [String])+[madrid.chapters[0].lessonIDs[0].uuidString]
        json["cards"]=cards
        let shared=try ContentPack.load(JSONSerialization.data(withJSONObject:json))
        let collection=AlbumCollection.make(pack:shared,state:LearnerState(),scope:.favorites,discoveredOnly:false,query:"Real Madrid")
        XCTAssertEqual(collection.total,14)
        XCTAssertEqual(collection.sections.flatMap(\.cards).filter {$0.key == "card-riascos"}.count,1)
    }
    func testPartialCoverageAndLapsesAreDifferent() {
        var state=LearnerState()
        let lesson=pack.lessons[0],card=pack.cards.first {$0.key == "card-xolos"}!
        state.completeLesson(lesson,pack:pack,sessionID:UUID(),attempts:[],now:now)
        let partial=CardReadiness.make(card:card,pack:pack,state:state,now:now.addingTimeInterval(86401))
        XCTAssertEqual(partial.introduced,3);XCTAssertEqual(partial.missing,30);XCTAssertEqual(partial.due,3);XCTAssertNil(partial.currentStage)
        let intro=pack.cards.first {$0.key == "card-atlas"}!
        XCTAssertEqual(CardReadiness.scopeLabel(card:intro,pack:pack),"Intro · 3 connections")
        XCTAssertEqual(CardReadiness.scopeLabel(card:card,pack:pack),"Club foundations · 33 connections")
    }
    func testCorrectedFactsRequireRefreshUntilIndependentDueRecall() throws {
        var state=LearnerState();let card=pack.cards.first {$0.key == "card-riascos"}!
        state.acquiredCards.insert(card.id)
        for id in card.objectiveIDs {state.reviews[id]=ReviewState(revision:pack.objective(id).revision,stage:4,highestEarned:4,due:now,learnedAt:now.addingTimeInterval(-30*86400))}
        state.captureCardAchievements(pack)
        let id=card.objectiveIDs[0]
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        var objectives=json["objectives"] as! [[String:Any]]
        let index=objectives.firstIndex {($0["id"] as! String).lowercased() == id.uuidString.lowercased()}!
        objectives[index]["revision"]=2;json["objectives"]=objectives
        let revised=try ContentPack.load(JSONSerialization.data(withJSONObject:json))
        state.reconcile(revised,now:now)
        XCTAssertEqual(state.tier(card),4)
        var readiness=CardReadiness.make(card:card,pack:revised,state:state,now:now)
        XCTAssertEqual(readiness.refresh,1);XCTAssertEqual(readiness.introduced,card.objectiveIDs.count-1);XCTAssertNil(readiness.currentStage)
        let o=revised.objective(id),due=state.reviews[id]!.due
        state.recordRecall(Attempt(objectiveID:id,answer:o.answers[0],correct:true,hinted:true,mode:"early",timestamp:due),objective:o)
        XCTAssertTrue(state.reviews[id]!.refreshRequired == true)
        state.recordRecall(Attempt(objectiveID:id,answer:o.answers[0],correct:true,hinted:false,mode:"due",timestamp:due),objective:o)
        readiness=CardReadiness.make(card:card,pack:revised,state:state,now:due)
        XCTAssertEqual(readiness.refresh,0);XCTAssertEqual(readiness.currentStage,1);XCTAssertEqual(state.tier(card),4)
    }
    func testAddedObjectivePreservesEarnedVersionWithoutClaimingNewMastery() throws {
        var state=LearnerState();let card=pack.cards.first {$0.key == "card-riascos"}!
        state.acquiredCards.insert(card.id)
        for id in card.objectiveIDs {state.reviews[id]=ReviewState(revision:pack.objective(id).revision,stage:4,highestEarned:4,due:now,learnedAt:now)}
        state.captureCardAchievements(pack)
        let extra=pack.objectives.first {!card.objectiveIDs.contains($0.id)}!
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        var cards=json["cards"] as! [[String:Any]]
        let index=cards.firstIndex {$0["key"] as! String == card.key}!
        cards[index]["objectiveIDs"]=card.objectiveIDs.map(\.uuidString)+[extra.id.uuidString]
        cards[index]["knowledgeVersion"]=card.knowledgeVersion+1;json["cards"]=cards
        let expanded=try ContentPack.load(JSONSerialization.data(withJSONObject:json))
        let updated=expanded.cards[index]
        state.reconcile(expanded,now:now);state.captureCardAchievements(expanded)
        XCTAssertEqual(state.tier(updated),4);XCTAssertEqual(state.cardAchievements?[card.id]?.knowledgeVersion,card.knowledgeVersion)
        XCTAssertEqual(CardReadiness.make(card:updated,pack:expanded,state:state,now:now).missing,1)
        state.reviews[extra.id]=ReviewState(revision:extra.revision,stage:4,highestEarned:4,due:now,learnedAt:now)
        state.captureCardAchievements(expanded)
        XCTAssertEqual(state.cardAchievements?[card.id]?.knowledgeVersion,card.knowledgeVersion+1)
    }
    func testLegacyDiamondDoesNotClaimARevisedSetVersion() throws {
        var state=LearnerState();let card=pack.cards.first {$0.key == "card-riascos"}!
        state.acquiredCards.insert(card.id)
        for id in card.objectiveIDs {state.reviews[id]=ReviewState(revision:pack.objective(id).revision,stage:4,highestEarned:4,due:now,learnedAt:now)}
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        var cards=json["cards"] as! [[String:Any]],objectives=json["objectives"] as! [[String:Any]]
        let c=cards.firstIndex {$0["key"] as! String == card.key}!
        cards[c]["knowledgeVersion"]=2
        let o=objectives.firstIndex {($0["id"] as! String).lowercased() == card.objectiveIDs[0].uuidString.lowercased()}!
        objectives[o]["revision"]=2;json["cards"]=cards;json["objectives"]=objectives
        let changed=try ContentPack.load(JSONSerialization.data(withJSONObject:json))
        state.reconcile(changed,now:now)
        XCTAssertEqual(state.tier(changed.cards[c]),4)
        XCTAssertNil(state.cardAchievements?[card.id]?.knowledgeVersion)
        XCTAssertEqual(CardReadiness.make(card:changed.cards[c],pack:changed,state:state,now:now).refresh,1)
    }
    func testOldProgressLoadsAndAchievementsPersist() throws {
        let dir=URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:dir)}
        let store=StateStore(directory:dir);var state=LearnerState();let card=pack.cards[0]
        state.acquiredCards.insert(card.id);state.captureCardAchievements(pack);try store.save(state)
        XCTAssertEqual(try store.load()?.cardAchievements?[card.id]?.tier,0)
        var json=try JSONSerialization.jsonObject(with:Data(contentsOf:store.file)) as! [String:Any]
        json.removeValue(forKey:"cardAchievements")
        try JSONSerialization.data(withJSONObject:json).write(to:store.file)
        XCTAssertNil(try store.load()?.cardAchievements)
    }
}
