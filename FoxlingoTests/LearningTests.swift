import XCTest
#if canImport(FoxlingoCore)
@testable import FoxlingoCore
#else
@testable import Foxlingo
#endif

final class LearningTests: XCTestCase {
    var pack: ContentPack!
    let start = Date(timeIntervalSince1970:1_800_000_000)
    override func setUpWithError() throws {
        let root = URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        pack = try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
    }
    func learned(_ lesson: Lesson? = nil) -> LearnerState {
        var s=LearnerState(timeZone:"America/Mexico_City")
        _ = s.completeLesson(lesson ?? pack.lessons[0],pack:pack,sessionID:UUID(),attempts:[],now:start)
        return s
    }
    func attempt(_ o: Objective, at: Date, correct: Bool = true, hinted: Bool = false, mode: String = "due") -> Attempt { Attempt(objectiveID:o.id,answer:o.answers[0],correct:correct,hinted:hinted,mode:mode,timestamp:at) }
    func mutatePack(_ transform: (inout [String:Any]) -> Void) throws -> ContentPack {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data=try Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json"))
        var json=try JSONSerialization.jsonObject(with:data) as! [String:Any];transform(&json)
        return try ContentPack.load(JSONSerialization.data(withJSONObject:json))
    }
    func testCompletePackAndSharedFact() {
        XCTAssertEqual(pack.lessons.count,78);XCTAssertEqual(pack.cards.count,74);XCTAssertEqual(pack.objectives.count,233)
        XCTAssertEqual(pack.lessons.prefix(12).flatMap(\.objectiveIDs).count,36)
        XCTAssertEqual(pack.roadmaps.prefix(2).map{$0.chapters.flatMap(\.lessonIDs).count},[6,6])
        XCTAssertEqual(pack.lessons[8].objectiveIDs[2],pack.lessons[10].objectiveIDs[1])
    }
    func testCompetitionCoverageAndCanonicalEntities() {
        for (key,count) in [("champions",36),("bundesliga",18),("ligamx",18)] {
            let entities=pack.entities.filter{$0.competitions?.contains(key) == true}
            XCTAssertEqual(entities.count,count)
            XCTAssertTrue(entities.allSatisfy{club in pack.roadmaps.contains{$0.clubID == club.id}})
        }
        XCTAssertEqual(pack.entities.filter{$0.name == "Atlético de Madrid"}.count,1)
        XCTAssertEqual(pack.clubRoadmaps.count,68);XCTAssertEqual(pack.playerRoadmaps.count,6)
    }
    func testRejectInvalidSchemaAndDuplicateIDs() {
        XCTAssertThrowsError(try mutatePack{$0["schemaVersion"]=2})
        XCTAssertThrowsError(try mutatePack { j in var e=j["entities"] as! [[String:Any]];e[1]["id"]=e[0]["id"];j["entities"]=e })
    }
    func testRejectBrokenFactEvidenceAndReference() {
        XCTAssertThrowsError(try mutatePack { j in var f=j["facts"] as! [[String:Any]];f[0]["sourceKeys"]=[];j["facts"]=f })
        XCTAssertThrowsError(try mutatePack { j in var f=j["facts"] as! [[String:Any]];f[0]["subjectID"]=UUID().uuidString;j["facts"]=f })
    }
    func testRejectInvalidAnswersAndAliases() {
        XCTAssertThrowsError(try mutatePack {j in var e=j["exercises"] as! [[String:Any]];e[0]["answerIDs"]=["absent"];j["exercises"]=e})
        XCTAssertThrowsError(try mutatePack {j in var o=j["objectives"] as! [[String:Any]];o[0]["answers"]=["  "];j["objectives"]=o})
    }
    func testRejectAmbiguousMatching() {
        XCTAssertThrowsError(try mutatePack {j in var e=j["exercises"] as! [[String:Any]];var pairs=e[4]["pairs"] as! [[String:Any]];pairs[1]["right"]=pairs[0]["right"];e[4]["pairs"]=pairs;j["exercises"]=e})
    }
    func testRejectIncompleteAndOverlappingMemoryBoard() {
        XCTAssertThrowsError(try mutatePack {j in
            var e=j["exercises"] as! [[String:Any]]
            e[4]["objectiveIDs"]=Array((e[4]["objectiveIDs"] as! [String]).prefix(1));j["exercises"]=e
        })
        XCTAssertThrowsError(try mutatePack {j in
            var e=j["exercises"] as! [[String:Any]]
            var right=e[4]["right"] as! [[String:Any]], pairs=e[4]["pairs"] as! [[String:Any]]
            right[0]["id"]="l-0";pairs[0]["right"]="l-0"
            e[4]["right"]=right;e[4]["pairs"]=pairs;j["exercises"]=e
        })
    }
    func testVisualAnswersRespectSemanticMeaning() {
        let city=pack.objectives.first {$0.factIDs.contains {id in pack.facts.contains {$0.id == id && $0.predicate == "city"}}}!
        XCTAssertNil(AnswerArtwork.type(objectiveID:city.id,pack:pack))
        let nick=pack.objectives.first {$0.factIDs.contains {id in pack.facts.contains {$0.id == id && $0.predicate == "nickname"}}}!
        XCTAssertNil(AnswerArtwork.type(objectiveID:nick.id,pack:pack))
        XCTAssertNil(AnswerArtwork.entity("Monterrey",type:"city",pack:pack))
        XCTAssertNotNil(AnswerArtwork.entity("Monterrey",type:"club",pack:pack))
        XCTAssertEqual(AnswerArtwork.flags["spain"],"flag-spain")
    }
    func testMatchingScoringAndAliases() {
        let x=pack.exercises[4];XCTAssertTrue(x.accepts(left:"l-0",right:"r-0"));XCTAssertFalse(x.accepts(left:"l-0",right:"r-1"))
        let o=pack.objectives.first{$0.answers.contains("Alfredo Di Stéfano")}!
        XCTAssertTrue(Recall.accepts("  ALFREDO   DI STEFANO  ",for:o));XCTAssertFalse(Recall.accepts("Di Stefan",for:o))
    }
    func testLearnAndDuplicateSession() {
        var s=LearnerState();let session=UUID();let l=pack.lessons[0]
        XCTAssertTrue(s.completeLesson(l,pack:pack,sessionID:session,attempts:[],now:start))
        XCTAssertFalse(s.completeLesson(l,pack:pack,sessionID:session,attempts:[],now:start))
        XCTAssertEqual(s.reviews.count,3);XCTAssertEqual(s.acquiredCards.count,1);XCTAssertEqual(s.sessions.count,1)
        XCTAssertEqual(s.reviews[l.objectiveIDs[0]]?.due,start.addingTimeInterval(86400))
    }
    func testEarlyRecallDoesNotAdvance() {
        var s=learned();let o=pack.objective(pack.lessons[0].objectiveIDs[0]);let due=s.reviews[o.id]!.due
        s.recordRecall(attempt(o,at:start),objective:o)
        s.recordRecall(attempt(o,at:due,mode:"early"),objective:o)
        XCTAssertEqual(s.reviews[o.id]!.stage,0);XCTAssertEqual(s.reviews[o.id]!.due,due)
    }
    func testDiamondRequires25Days() {
        var s=learned();let o=pack.objective(pack.lessons[0].objectiveIDs[0])
        for stage in 1...4 { let d=s.reviews[o.id]!.due;s.recordRecall(attempt(o,at:d),objective:o);XCTAssertEqual(s.reviews[o.id]!.stage,stage);if stage == 4 {XCTAssertEqual(d.timeIntervalSince(start),25*86400)} }
        XCTAssertEqual(s.reviews[o.id]!.due.timeIntervalSince(start),55*86400)
    }
    func testWrongAndHintedRecallResetButKeepAchievement() {
        for hint in [true,false] {var s=learned();let o=pack.objective(pack.lessons[0].objectiveIDs[0]);let d=s.reviews[o.id]!.due
            s.recordRecall(attempt(o,at:d),objective:o);let next=s.reviews[o.id]!.due
            s.recordRecall(attempt(o,at:next,correct:hint,hinted:hint),objective:o)
            XCTAssertEqual(s.reviews[o.id]!.stage,0);XCTAssertEqual(s.reviews[o.id]!.highestEarned,1);XCTAssertEqual(s.reviews[o.id]!.lapses,1);XCTAssertEqual(s.reviews[o.id]!.due,next.addingTimeInterval(86400))
            s.recordRecall(attempt(o,at:next),objective:o);XCTAssertEqual(s.reviews[o.id]!.stage,0)
        }
    }
    func testTierRequiresWholeCard() {
        var s=learned();let card=pack.cards.first{$0.key=="card-xolos"}!
        for id in pack.lessons[0].objectiveIDs {let o=pack.objective(id);s.recordRecall(attempt(o,at:s.reviews[id]!.due),objective:o)}
        XCTAssertEqual(s.tier(card),0)
        for l in pack.lessons[1...2] {_ = s.completeLesson(l,pack:pack,sessionID:UUID(),attempts:[],now:start)}
        for id in card.objectiveIDs where s.reviews[id]!.highestEarned==0 {s.recordRecall(attempt(pack.objective(id),at:s.reviews[id]!.due),objective:pack.objective(id))}
        XCTAssertEqual(s.tier(card),1)
        let id=card.objectiveIDs[0];s.recordRecall(attempt(pack.objective(id),at:s.reviews[id]!.due,correct:false),objective:pack.objective(id));XCTAssertEqual(s.tier(card),1)
    }
    func testDueQueueOrderLimitAndNoDuplicate() {
        var s=learned();let l=pack.lessons[0];let ids=l.objectiveIDs
        s.reviews[ids[1]]!.lapses=3
        let due=s.dueObjectives(pack,now:start.addingTimeInterval(86400),limit:2)
        XCTAssertEqual(due.count,2);XCTAssertEqual(due[0].id,ids[1]);XCTAssertEqual(Set(due.map(\.id)).count,2)
        XCTAssertTrue(s.dueObjectives(pack,now:start).isEmpty)
    }
    func testSemanticRevisionAndSharedLearning() throws {
        var s=learned();let id=pack.lessons[0].objectiveIDs[0];s.reviews[id]!.stage=3;s.reviews[id]!.highestEarned=3
        let revised=try mutatePack{j in var o=j["objectives"] as! [[String:Any]];o[0]["revision"]=2;j["objectives"]=o}
        s.reconcile(revised,now:start);XCTAssertEqual(s.reviews[id]!.stage,0);XCTAssertEqual(s.reviews[id]!.highestEarned,3);XCTAssertEqual(s.reviews[id]!.revision,2)
        var shared=learned(pack.lessons[8]);let before=shared.reviews.count
        _ = shared.completeLesson(pack.lessons[10],pack:pack,sessionID:UUID(),attempts:[],now:start)
        XCTAssertEqual(shared.reviews.count,before+2)
    }
    func testPracticeMustContainAttemptAndBeIdempotent() {
        var s=learned();let id=UUID()
        XCTAssertFalse(s.completePractice(id:id,count:0,now:start));XCTAssertTrue(s.completePractice(id:id,count:1,now:start));XCTAssertFalse(s.completePractice(id:id,count:1,now:start))
    }
    func testStreakFreezeAndLongGap() {
        var s=StreakState();let z="UTC"
        s.record(start,zone:z);s.record(start,zone:z);XCTAssertEqual(s.daysSinceRefill,1)
        s.record(start.addingTimeInterval(2*86400),zone:z);XCTAssertEqual(s.freezes,0);XCTAssertEqual(s.protectedDays.count,1);XCTAssertEqual(s.current(at:start.addingTimeInterval(2*86400),zone:z),2)
        s.record(start.addingTimeInterval(5*86400),zone:z);XCTAssertEqual(s.current(at:start.addingTimeInterval(5*86400),zone:z),1);XCTAssertEqual(s.longest,2)
        XCTAssertEqual(s.current(at:start.addingTimeInterval(7*86400),zone:z),0)
    }
    func testFreezeRefillsAfterSevenDistinctDays() {
        var s=StreakState();s.freezes=0
        for day in 0..<7 {s.record(start.addingTimeInterval(Double(day)*86400),zone:"UTC")}
        XCTAssertEqual(s.freezes,1);XCTAssertEqual(s.daysSinceRefill,0);XCTAssertEqual(s.longest,7)
    }
    func testHomeZoneAndDSTDays() {
        let date=ISO8601DateFormatter().date(from:"2026-10-09T02:00:00Z")!
        XCTAssertEqual(StreakState.dayKey(date,zone:"America/Mexico_City"),"2026-10-08")
        XCTAssertEqual(StreakState.dayKey(date,zone:"UTC"),"2026-10-09")
        var s=StreakState();let a=ISO8601DateFormatter().date(from:"2026-03-07T18:00:00Z")!,b=ISO8601DateFormatter().date(from:"2026-03-08T17:00:00Z")!
        s.record(a,zone:"America/New_York");s.record(b,zone:"America/New_York");XCTAssertEqual(s.current(at:b,zone:"America/New_York"),2)
    }
    func testSaveRoundTripAndResume() throws {
        let d=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer{try? FileManager.default.removeItem(at:d)}
        let store=StateStore(directory:d);var s=learned();s.resumes[pack.lessons[1].id]=LessonResume(step:3,attempts:[],matched:["l-0"])
        try store.save(s);let restored=try XCTUnwrap(store.load());XCTAssertEqual(restored.reviews.count,3);XCTAssertEqual(restored.resumes[pack.lessons[1].id]?.step,3)
    }
    func testCorruptSavePreservedAndBackupUsed() throws {
        let d=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer{try? FileManager.default.removeItem(at:d)}
        let store=StateStore(directory:d);try store.save(learned());try store.save(learned());try Data("bad json".utf8).write(to:store.file)
        XCTAssertEqual(try store.load()?.reviews.count,3);XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath:d.path).contains{$0.hasPrefix("learner-damaged")})
    }
    func testDiamondCardAndPermanentAchievement() {
        let lesson=pack.lessons.first{$0.key=="lesson-xolos-riascos"}!,card=pack.cards.first{$0.key=="card-riascos"}!
        var s=learned(lesson)
        for stage in 1...4 {
            for id in card.objectiveIDs {let o=pack.objective(id);s.recordRecall(attempt(o,at:s.reviews[id]!.due),objective:o)}
            XCTAssertEqual(s.tier(card),stage)
        }
        let id=card.objectiveIDs[0],o=pack.objective(id)
        s.recordRecall(attempt(o,at:s.reviews[id]!.due,correct:false),objective:o)
        XCTAssertEqual(s.tier(card),4);XCTAssertEqual(s.reviews[id]!.stage,0)
    }
    func testTypedValuesAndBrokenEntityTarget() throws {
        XCTAssertTrue(pack.facts.contains{$0.value.kind=="number" && $0.value.unit=="goals"})
        XCTAssertTrue(pack.facts.contains{$0.value.kind=="entity"})
        XCTAssertThrowsError(try mutatePack{j in var f=j["facts"] as! [[String:Any]];var v=f[0]["value"] as! [String:Any];v["entityID"]=UUID().uuidString;f[0]["value"]=v;j["facts"]=f})
    }

    func testSemanticallyCorruptSaveIsPreserved() throws {
        let d=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer{try? FileManager.default.removeItem(at:d)}
        let store=StateStore(directory:d);var s=learned();let id=pack.lessons[0].objectiveIDs[0];s.reviews[id]!.stage=99
        try store.save(s);XCTAssertThrowsError(try store.load())
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath:d.path).contains{$0.hasPrefix("learner-damaged")})
    }
    func testRecoveryNoticeAndWrongObjectiveAttempt() throws {
        let d=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer{try? FileManager.default.removeItem(at:d)}
        let store=StateStore(directory:d);try store.save(learned());try store.save(learned());try Data("invalid".utf8).write(to:store.file)
        XCTAssertNotNil(try store.loadWithNotice().notice)
        var s=learned();let a=pack.objective(pack.lessons[0].objectiveIDs[0]),b=pack.objective(pack.lessons[0].objectiveIDs[1])
        s.recordRecall(attempt(b,at:s.reviews[a.id]!.due),objective:a);XCTAssertEqual(s.reviews[a.id]!.stage,0)
    }

    func testCorruptSaveWithoutBackupReportsRecovery() throws {
        let d=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);defer{try? FileManager.default.removeItem(at:d)}
        let store=StateStore(directory:d);try store.save(learned());try Data("bad".utf8).write(to:store.file)
        XCTAssertThrowsError(try store.load());XCTAssertTrue(FileManager.default.fileExists(atPath:store.file.path))
    }
}
