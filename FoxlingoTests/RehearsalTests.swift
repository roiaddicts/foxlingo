import XCTest
@testable import FoxlingoCore
final class RehearsalTests: XCTestCase {
    func fixture() throws -> (ContentPack,Data,[RehearsalTopic]) {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
        let data=try Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/rehearsal-en.json"))
        return (pack,data,try RehearsalTopic.load(data,pack:pack))
    }
    func testTopicsHaveThreeSourcedAnchorsAndOriginalDraftSurvivesSave() throws {
        let (_,_,topics)=try fixture();XCTAssertEqual(topics.count,6)
        for topic in topics {XCTAssertEqual(topic.objectives.count,3);XCTAssertEqual(topic.facts.count,3);XCTAssertTrue(topic.facts.flatMap {$0}.allSatisfy {!$0.sourceKeys.isEmpty})}
        let topic=topics[1];var draft=RehearsalDraft(topic:topic);draft.response="Ramos changed the final by taking it into extra time."
        var state=LearnerState();state.storeRehearsal(draft)
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONEncoder().encode(state))
        let saved=try XCTUnwrap(restored.rehearsals?.drafts[topic.id]);XCTAssertEqual(saved.response,draft.response);XCTAssertEqual(saved.sessionID,draft.sessionID);XCTAssertTrue(saved.canReveal);XCTAssertTrue(saved.valid(for:topic,completed:[]))
        draft.revealed=true;draft.revisedResponse="Add the opponent and year.";state.storeRehearsal(draft)
        XCTAssertEqual(state.rehearsals?.drafts[topic.id]?.response,saved.response)
    }
    func testExplicitMissesCanFinishButUnansweredAndUnexplainedCannot() throws {
        let (_,_,topics)=try fixture();let topic=topics[0];var draft=RehearsalDraft(topic:topic)
        draft.mode = .aloud;XCTAssertFalse(draft.canReveal);draft.explained=true;XCTAssertTrue(draft.canReveal);draft.revealed=true
        XCTAssertFalse(draft.canFinish(topic));draft.checks[topic.objectives[0].id] = .included;XCTAssertFalse(draft.canFinish(topic))
        draft.checks=Dictionary(uniqueKeysWithValues:topic.objectives.map {($0.id,RehearsalReflection.missed)});XCTAssertTrue(draft.canFinish(topic))
        draft.mode = .typed;draft.response="   ";XCTAssertFalse(draft.canReveal);XCTAssertFalse(draft.canFinish(topic))
    }
    func testCompletionOnceChangesOnlyRehearsalActivityAndStreak() throws {
        let (pack,_,topics)=try fixture();let topic=topics[1],now=Date(timeIntervalSince1970:1_800_000_000)
        var state=LearnerState();state.completeLesson(pack.lessons[0],pack:pack,sessionID:UUID(),attempts:[],now:now)
        let beforeCards=state.acquiredCards,beforeLessons=state.completedLessons,beforeSessions=state.sessions.count
        let objective=pack.objective(pack.lessons[0].objectiveIDs[0])
        state.recordRecall(Attempt(objectiveID:objective.id,answer:objective.answers[0],correct:true,hinted:false,mode:"due",timestamp:now.addingTimeInterval(86401)),objective:objective)
        let before=state.reviews,beforeAttempts=state.attempts.count
        var draft=RehearsalDraft(topic:topic);draft.response="My account";draft.revealed=true;draft.checks=Dictionary(uniqueKeysWithValues:topic.objectives.map {($0.id,RehearsalReflection.unsure)})
        state.storeRehearsal(draft);XCTAssertTrue(state.completeRehearsal(draft,topic:topic,now:now));XCTAssertFalse(state.completeRehearsal(draft,topic:topic,now:now))
        XCTAssertEqual(state.sessions.count,beforeSessions+1);XCTAssertEqual(state.sessions.last?.kind,"rehearsal");XCTAssertEqual(state.sessions.last?.attemptCount,0)
        XCTAssertEqual(state.rehearsals?.records.count,1);XCTAssertNil(state.rehearsals?.drafts[topic.id]);XCTAssertEqual(state.attempts.count,beforeAttempts)
        XCTAssertEqual(state.reviews.mapValues(\.stage),before.mapValues(\.stage));XCTAssertEqual(state.reviews.mapValues(\.due),before.mapValues(\.due));XCTAssertEqual(state.acquiredCards,beforeCards);XCTAssertEqual(state.completedLessons,beforeLessons)
        XCTAssertEqual(state.streak.current(at:now,zone:state.homeTimeZone),1);XCTAssertEqual(state.tier(pack.cards[0]),0)
    }
    func testMeaningChangeArchivesNotesAndCannotCompleteOldAssessment() throws {
        let (pack,data,topics)=try fixture();let topic=topics[1];var draft=RehearsalDraft(topic:topic);draft.response="Keep my notes";draft.revealed=true
        draft.checks=Dictionary(uniqueKeysWithValues:topic.objectives.map {($0.id,RehearsalReflection.included)})
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        var objectives=json["objectives"] as! [[String:Any]];let i=objectives.firstIndex {($0["id"] as! String).lowercased() == topic.objectives[0].id.uuidString.lowercased()}!;objectives[i]["revision"]=2;json["objectives"]=objectives
        let changed=try JSONDecoder().decode(ContentPack.self,from:JSONSerialization.data(withJSONObject:json));let updated=try RehearsalTopic.load(data,pack:changed)[1]
        XCTAssertNotEqual(updated.signature,topic.signature);XCTAssertFalse(draft.valid(for:updated,completed:[]))
        var state=LearnerState();state.storeRehearsal(draft);XCTAssertFalse(state.completeRehearsal(draft,topic:updated,now:Date()))
        state.archiveRehearsal(draft,title:topic.lesson.title,now:Date());XCTAssertEqual(state.rehearsals?.records.first?.draft.response,"Keep my notes");XCTAssertEqual(state.rehearsals?.records.first?.completed,false);XCTAssertTrue(state.sessions.isEmpty)
    }
    func testMalformedOptionalDraftDoesNotLoseLearningOrOtherDrafts() throws {
        let (_,_,topics)=try fixture();var state=LearnerState();state.storeRehearsal(RehearsalDraft(topic:topics[0]));state.storeRehearsal(RehearsalDraft(topic:topics[1]))
        let lessonID=topics[0].lesson.id;state.completedLessons.insert(lessonID)
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(state)) as! [String:Any]
        var collection=json["rehearsals"] as! [String:Any];var drafts=collection["drafts"] as! [String:Any];drafts[topics[0].id]="corrupt";collection["drafts"]=drafts;json["rehearsals"]=collection
        let restored=try JSONDecoder().decode(LearnerState.self,from:JSONSerialization.data(withJSONObject:json))
        XCTAssertTrue(restored.completedLessons.contains(lessonID));XCTAssertNotNil(restored.rehearsals?.drafts[topics[1].id]);XCTAssertNil(restored.rehearsals?.drafts[topics[0].id]);XCTAssertEqual(restored.rehearsals?.discardedDrafts,1)
    }
    func testRetiredTopicArchivesOriginalContextAndOldSessionCannotEraseNewDraft() throws {
        let (_,_,topics)=try fixture();let topic=topics[0];var old=RehearsalDraft(topic:topic);old.response="Old account";old.revealed=true
        old.checks=Dictionary(uniqueKeysWithValues:topic.objectives.map {($0.id,RehearsalReflection.missed)})
        var state=LearnerState();state.storeRehearsal(old);state.reconcileRehearsals(Array(topics.dropFirst()),now:Date())
        XCTAssertNil(state.rehearsals?.drafts[topic.id]);let archived=try XCTUnwrap(state.rehearsals?.records.first)
        XCTAssertEqual(archived.title,old.title);XCTAssertEqual(archived.draft.anchorTitles,old.anchorTitles);XCTAssertEqual(archived.draft.checks.count,3)
        let fresh=RehearsalDraft(topic:topic);state.storeRehearsal(fresh)
        XCTAssertFalse(state.completeRehearsal(old,topic:topic,now:Date()));XCTAssertEqual(state.rehearsals?.drafts[topic.id]?.sessionID,fresh.sessionID);XCTAssertEqual(state.rehearsals?.records.count,1)
        state.reconcileRehearsals(topics,now:Date());XCTAssertEqual(state.rehearsals?.drafts[topic.id]?.sessionID,fresh.sessionID)
    }
    func testInvalidChecksOversizedResponseAndUnsupportedSubjectRejected() throws {
        let (pack,data,topics)=try fixture();let topic=topics[0];var draft=RehearsalDraft(topic:topic);draft.response=String(repeating:"x",count:4001);XCTAssertFalse(draft.valid(for:topic,completed:[]))
        draft.response="x";draft.checks[UUID()] = .included;XCTAssertFalse(draft.valid(for:topic,completed:[]))
        var json=try JSONSerialization.jsonObject(with:data) as! [[String:Any]];json[0]["subjectID"]=topics[1].subject.id.uuidString
        XCTAssertThrowsError(try RehearsalTopic.load(JSONSerialization.data(withJSONObject:json),pack:pack))
    }
}
