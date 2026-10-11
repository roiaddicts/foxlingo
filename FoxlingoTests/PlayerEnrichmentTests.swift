import XCTest
@testable import FoxlingoCore

final class PlayerEnrichmentTests: XCTestCase {
    var pack: ContentPack!
    let now=Date(timeIntervalSince1970:1_800_000_000)
    let keys=["lesson-player-cristiano-madrid-records","lesson-player-arce-career-milestones","lesson-player-riascos-tijuana-and-beyond","lesson-player-saucedo-career-milestones"]
    override func setUpWithError() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
    }
    func testSharedRequiredStoriesAndSubjectScopedCards() throws {
        for key in keys {
            let lesson=try XCTUnwrap(pack.lessons.first {$0.key == key})
            let fact=pack.facts.first {$0.id == pack.objective(lesson.objectiveIDs[0]).factIDs[0]}!
            let player=pack.playerRoadmaps.first {$0.entityID == fact.subjectID}!
            let club=pack.clubRoadmaps.first {$0.entityID == player.clubID}!
            for path in [player,club] {XCTAssertTrue(RoadmapProgress.make(roadmap:path,pack:pack,state:LearnerState()).requiredLessonIDs.contains(lesson.id))}
            let card=pack.cards.first {$0.entityID == player.entityID}!
            XCTAssertEqual(card.knowledgeVersion,player.key == "roadmap-player-cristiano" ? 4 : 3);XCTAssertEqual(card.objectiveIDs.count,player.key == "roadmap-player-cristiano" ? 24 : 12)
            XCTAssertTrue(Set(lesson.objectiveIDs).isSubset(of:Set(card.objectiveIDs)))
            XCTAssertTrue(card.objectiveIDs.allSatisfy {pack.objective($0).factIDs.allSatisfy {id in pack.facts.first {$0.id == id}?.subjectID == player.entityID}})
            var state=LearnerState();state.selectRoadmap(player,pack:pack)
            state.completeLesson(lesson,pack:pack,sessionID:UUID(),attempts:[],now:now)
            XCTAssertEqual(RoadmapProgress.make(roadmap:player,pack:pack,state:state).completedRequired,1)
            XCTAssertEqual(RoadmapProgress.make(roadmap:club,pack:pack,state:state).completedRequired,1)
            let due=state.reviews.mapValues(\.due)
            state.completeLesson(lesson,pack:pack,sessionID:UUID(),attempts:[],now:now.addingTimeInterval(3600))
            XCTAssertEqual(state.reviews.count,3);XCTAssertEqual(state.reviews.mapValues(\.due),due)
        }
    }
    func testOldPlayerAchievementRetainsTierAndNewFactsRemainUnlearned() throws {
        for key in keys {
            let lesson=pack.lessons.first {$0.key == key}!
            let card=pack.cards.first {$0.lessonIDs.contains(lesson.id)}!
            let old=card.objectiveIDs.filter {!lesson.objectiveIDs.contains($0)}
            var state=LearnerState();state.acquiredCards.insert(card.id)
            state.cardAchievements=[card.id:CardAchievement(tier:4,knowledgeVersion:1)]
            for id in old {state.reviews[id]=ReviewState(revision:pack.objective(id).revision,stage:4,highestEarned:4,due:now.addingTimeInterval(86400),learnedAt:now)}
            state.reconcile(pack,now:now)
            XCTAssertEqual(state.tier(card),4);XCTAssertEqual(state.cardAchievements?[card.id]?.knowledgeVersion,1)
            XCTAssertEqual(CardReadiness.make(card:card,pack:pack,state:state,now:now).missing,3)
            XCTAssertTrue(lesson.objectiveIDs.allSatisfy {state.reviews[$0] == nil})
            XCTAssertTrue(state.dueObjectives(pack,now:now,limit:20).isEmpty)
            state.completeLesson(lesson,pack:pack,sessionID:UUID(),attempts:[],now:now)
            XCTAssertEqual(CardReadiness.make(card:card,pack:pack,state:state,now:now).missing,0)
            XCTAssertEqual(state.tier(card),4)
            XCTAssertEqual(state.cardAchievements?[card.id]?.knowledgeVersion,1)
        }
    }
    func testPreviouslyCompletedFavoritesGainOnlyTheNewRequiredStories() {
        let newIDs=Set(pack.lessons.filter {keys.contains($0.key)}.map(\.id))
        var state=LearnerState();state.savedRoadmapIDs=[]
        for key in ["roadmap-xolos","roadmap-madrid"] {
            let path=pack.clubRoadmaps.first {$0.key == key}!
            let required=RoadmapProgress.make(roadmap:path,pack:pack,state:state).requiredLessonIDs
            for id in required where !newIDs.contains(id) {state.completeLesson(pack.lesson(id),pack:pack,sessionID:UUID(),attempts:[],now:now)}
        }
        let completed=state.completedLessons,sessionCount=state.sessions.count,due=state.reviews.mapValues(\.due)
        state.reconcile(pack,now:now)
        XCTAssertEqual(state.completedLessons,completed);XCTAssertEqual(state.sessions.count,sessionCount);XCTAssertEqual(state.reviews.mapValues(\.due),due)
        for key in ["roadmap-xolos","roadmap-madrid"] {
            let path=pack.clubRoadmaps.first {$0.key == key}!
            state.selectRoadmap(path,pack:pack)
            let progress=RoadmapProgress.make(roadmap:path,pack:pack,state:state)
            XCTAssertFalse(progress.isComplete)
            let missing=Set(progress.requiredLessonIDs.filter {!state.completedLessons.contains($0)})
            XCTAssertEqual(missing.count,key == "roadmap-xolos" ? 3 : 1);XCTAssertTrue(missing.isSubset(of:newIDs))
            XCTAssertTrue(missing.contains(DailyStudyPlan.make(pack:pack,state:state,now:now).lessonID!))
        }
    }
    func testTypedAliasesAndHistoricallyScopedRecords() throws {
        let total=pack.objectives.first {$0.key == "objective-enrichment-cristiano-madrid-goals-total"}!
        XCTAssertTrue(total.prompt.contains("official profile"));XCTAssertTrue(Recall.accepts("four hundred fifty one",for:total));XCTAssertFalse(Recall.accepts("450",for:total))
        let debut=pack.objectives.first {$0.key == "objective-enrichment-arce-mexico-debut-year"}!
        XCTAssertTrue(Recall.accepts("two thousand and three",for:debut));XCTAssertFalse(Recall.accepts("2004",for:debut))
        let riascos=pack.facts.first {$0.key == "fact-enrichment-riascos-xolos-goals-total"}!
        XCTAssertTrue(riascos.scope.contains("17 March 2019"))
        let america=try XCTUnwrap(AnswerArtwork.entity("América de Cali",type:"club",pack:pack))
        let mexico=try XCTUnwrap(AnswerArtwork.entity("Club América",type:"club",pack:pack))
        XCTAssertNotEqual(america.id,mexico.id);XCTAssertNotEqual(america.imageAsset,mexico.imageAsset)
        let irapuato=pack.objectives.first {$0.key == "objective-enrichment-arce-first-division-debut-club"}!
        XCTAssertTrue(Recall.accepts("Club Deportivo Irapuato",for:irapuato))
        let veracruz=pack.objectives.first {$0.key == "objective-enrichment-arce-veracruz-transfer"}!
        XCTAssertTrue(Recall.accepts("CD Veracruz",for:veracruz));XCTAssertFalse(Recall.accepts("Irapuato",for:veracruz))
        for lesson in pack.lessons where keys.contains(lesson.key) {
            for exercise in lesson.exerciseIDs.map(pack.exercise) {
                if let type=AnswerArtwork.type(objectiveID:exercise.objectiveIDs[0],pack:pack) {
                    XCTAssertEqual(type,"club")
                    XCTAssertTrue(exercise.choices.allSatisfy {AnswerArtwork.canShow($0.text,type:type,pack:pack)})
                }
            }
        }
    }
    func testCareerClubConnectionsHaveReadableScopedGraphEdges() {
        let graph=KnowledgeGraph(pack:pack)
        let factIDs=Set(pack.lessons.filter {keys.contains($0.key)}.flatMap(\.objectiveIDs).flatMap {pack.objective($0).factIDs})
        let careers=pack.facts.filter {factIDs.contains($0.id) && $0.value.entityID != nil}
        XCTAssertEqual(careers.count,5)
        for fact in careers {
            let edge=graph.edges.first {$0.id == fact.id}!
            XCTAssertEqual(edge.group,.history);XCTAssertNotEqual(edge.label,fact.predicate);XCTAssertEqual(edge.scope,fact.scope)
            XCTAssertEqual(edge.objectID,fact.value.entityID);XCTAssertEqual(edge.factIDs,[fact.id])
        }
    }
    func testSaucedoSourceScopeAliasesAndOldStatisticsRemainDistinct() throws {
        let lesson=pack.lessons.first {$0.key == "lesson-player-saucedo-career-milestones"}!
        let facts=lesson.objectiveIDs.flatMap {pack.objective($0).factIDs}.map {id in pack.facts.first {$0.id == id}!}
        XCTAssertEqual(facts.count,3)
        XCTAssertTrue(facts.first {$0.value.display == "Bronze"}!.scope.contains("under-23"))
        XCTAssertTrue(facts.first {$0.value.display == "2013"}!.scope.contains("Senior Mexico"))
        let previous=try XCTUnwrap(facts.first {$0.predicate == "saucedo-xolos-previous-club"})
        XCTAssertTrue(previous.scope.contains("Apertura 2011"))
        XCTAssertEqual(pack.entity(previous.value.entityID!).name,"Tigres UANL")
        let objective=pack.objectives.first {$0.factIDs.contains(previous.id)}!
        XCTAssertTrue(Recall.accepts("TIGRES",for:objective));XCTAssertTrue(Recall.accepts("Tigres de la UANL",for:objective))
        XCTAssertFalse(Recall.accepts("Xolos",for:objective))
        let old=pack.lessons.first {$0.key == "lesson-xolos-saucedo"}!
        XCTAssertTrue(Set(old.objectiveIDs).isDisjoint(with:Set(lesson.objectiveIDs)))
        XCTAssertEqual(Set(old.objectiveIDs.map {pack.objective($0).answers[0]}),Set(["Goalkeeper","11","17"]))
    }
    func testRecallContextDoesNotRevealIdentityButRetainsStatSubject() throws {
        for key in ["objective-madrid-equalizer","objective-madrid-identity-name","objective-xolos-identity-nickname"] {
            let objective=try XCTUnwrap(pack.objectives.first {$0.key == key})
            XCTAssertNil(Recall.subjectArtwork(for:objective,pack:pack),key)
            XCTAssertNotNil(Recall.subjectArtwork(for:objective,pack:pack,answerRevealed:true),key)
        }
        let goals=pack.objectives.first {$0.key == "objective-enrichment-cristiano-madrid-goals-total"}!
        XCTAssertEqual(Recall.subjectArtwork(for:goals,pack:pack)?.name,"Cristiano Ronaldo")
        let saucedo=pack.objectives.first {$0.key == "objective-enrichment-saucedo-xolos-previous-club"}!
        XCTAssertEqual(Recall.subjectArtwork(for:saucedo,pack:pack)?.name,"Cirilo Saucedo")
        let mixed=Objective(id:UUID(),key:"mixed",factIDs:goals.factIDs+saucedo.factIDs,prompt:"Mixed",answers:["answer"],feedback:"",revision:1)
        XCTAssertNil(Recall.subjectArtwork(for:mixed,pack:pack))
        XCTAssertNil(Recall.subjectArtwork(for:mixed,pack:pack,answerRevealed:true))
    }

    func testScoreWheelsHaveExplicitTeamsAndRejectReversedGoals() throws {
        let scores=pack.exercises.compactMap(\.scoreInput)
        XCTAssertEqual(scores.count,81)
        let aggregate=pack.exercises.first {$0.key == "exercise-xolos-final-choice-1"}!.scoreInput!
        XCTAssertEqual(pack.entity(aggregate.leftEntityID).name,"Club Tijuana")
        XCTAssertEqual(pack.entity(aggregate.rightEntityID).name,"Toluca")
        XCTAssertTrue(aggregate.accepts(left:4,right:1));XCTAssertFalse(aggregate.accepts(left:1,right:4))
        let shootout=pack.exercises.first {$0.key == "exercise-competition-champions-league-istanbul-choice-2"}!.scoreInput!
        XCTAssertEqual(pack.entity(shootout.leftEntityID).name,"Liverpool")
        XCTAssertEqual(pack.entity(shootout.rightEntityID).name,"AC Milan")
        XCTAssertTrue(shootout.accepts(left:3,right:2));XCTAssertFalse(shootout.accepts(left:2,right:3))
        XCTAssertEqual(ScoreInput.pair(in:"Milan 3–0 Liverpool"),[3,0])
        XCTAssertNil(ScoreInput.pair(in:"1932–33"));XCTAssertNil(ScoreInput.pair(in:"3–0 and 4–1"))
        XCTAssertEqual(pack.scoreInput(for:pack.exercises.first {$0.key == "exercise-xolos-final-choice-1"}!.objectiveIDs[0]),aggregate)
    }
    func testMalformedScoreMetadataRejectsAndOlderChoicesStillLoad() throws {
        let base=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        for field in ["leftEntityID","rightEntityID","leftGoals","maximum"] {
            var json=base,exercises=json["exercises"] as! [[String:Any]]
            let i=exercises.firstIndex {$0["scoreInput"] != nil}!
            var score=exercises[i]["scoreInput"] as! [String:Any]
            if field == "leftEntityID" {score[field]=UUID().uuidString}
            else if field == "rightEntityID" {score[field]=score["leftEntityID"]}
            else {score[field]=field == "maximum" ? 101 : 18}
            exercises[i]["scoreInput"]=score;json["exercises"]=exercises
            XCTAssertThrowsError(try ContentPack.load(JSONSerialization.data(withJSONObject:json)),field)
        }
        var old=base,rows=old["exercises"] as! [[String:Any]]
        for i in rows.indices {rows[i].removeValue(forKey:"scoreInput")};old["exercises"]=rows
        let restored=try ContentPack.load(JSONSerialization.data(withJSONObject:old))
        XCTAssertTrue(restored.exercises.allSatisfy {$0.scoreInput == nil})
    }

}
