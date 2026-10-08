import XCTest
@testable import FoxlingoCore

final class ContentUpdateTests: XCTestCase {
    var data: Data!
    var bundled: ContentPack!
    var directory: URL!
    override func setUpWithError() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        data=try Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json"))
        bundled=try ContentPack.load(data)
        directory=FileManager.default.temporaryDirectory.appendingPathComponent("lesson-cache-"+UUID().uuidString)
    }
    override func tearDownWithError() throws {try? FileManager.default.removeItem(at:directory)}
    var baseVersion: Int {bundled.contentVersion}
    func cache() throws -> ContentCache {try ContentCache(directory:directory,bundledData:data)}
    func update(_ version: Int?=nil,_ edit: (inout [String:Any]) -> Void = {_ in}) throws -> Data {
        var json=try JSONSerialization.jsonObject(with:data) as! [String:Any]
        json["contentVersion"]=version ?? (baseVersion+1);edit(&json)
        return try JSONSerialization.data(withJSONObject:json,options:.sortedKeys)
    }
    func testStageActivationRollbackAndCancellation() throws {
        let c=try cache();let initial=try c.load().pack
        try c.stage(update(),active:initial)
        XCTAssertEqual(initial.contentVersion,baseVersion);XCTAssertEqual(c.pendingVersion,baseVersion+1)
        let installed=try c.load().pack
        XCTAssertEqual(installed.contentVersion,baseVersion+1);XCTAssertNil(c.pendingVersion);XCTAssertEqual(c.previousVersion,baseVersion)
        try c.stageRollback(active:installed);XCTAssertEqual(c.pendingVersion,baseVersion)
        try c.cancelPending();XCTAssertEqual(try c.load().pack.contentVersion,baseVersion+1)
        try c.stageRollback(active:installed)
        XCTAssertEqual(try c.load().pack.contentVersion,baseVersion);XCTAssertEqual(c.previousVersion,baseVersion+1)
    }
    func testNewerPendingWinsAndSameVersionIsRejected() throws {
        let c=try cache();let active=try c.load().pack
        try c.stage(update(baseVersion+3),active:active)
        XCTAssertThrowsError(try c.stage(update(baseVersion+2),active:active))
        XCTAssertThrowsError(try c.stage(update(baseVersion+3),active:active))
        XCTAssertEqual(c.pendingVersion,baseVersion+3)
    }
    func testInvalidDownloadsLeaveActiveAndPendingUntouched() throws {
        let c=try cache();let active=try c.load().pack;try c.stage(update(),active:active)
        for field in ["key","language","schemaVersion"] {
            let bad=try update(baseVersion+2) {$0[field]=field == "schemaVersion" ? 99 : "other"}
            XCTAssertThrowsError(try c.stage(bad,active:active))
            XCTAssertEqual(c.pendingVersion,baseVersion+1)
        }
        XCTAssertThrowsError(try c.stage(Data(repeating:32,count:ContentUpdateRules.maximumBytes+1),active:active))
        XCTAssertEqual(try c.load().pack.contentVersion,baseVersion+1)
    }
    func testRawManifestChecksumAndMetadataAgreement() throws {
        let next=try update();let pack=try ContentPack.load(next)
        let manifest=ContentManifest(packKey:pack.key,contentVersion:baseVersion+1,schemaVersion:1,language:"en",contentURL:"https://example.com/lessons.json",sha256:ContentUpdateRules.digest(next))
        XCTAssertEqual(try manifest.verify(next,bundled:bundled).contentVersion,baseVersion+1)
        XCTAssertThrowsError(try manifest.verify(next+Data([32]),bundled:bundled))
        let wrong=ContentManifest(packKey:pack.key,contentVersion:baseVersion+2,schemaVersion:1,language:"en",contentURL:manifest.contentURL,sha256:manifest.sha256)
        XCTAssertThrowsError(try wrong.verify(next,bundled:bundled))
        for address in ["http://example.com/feed.json","https://user:secret@example.com/feed.json","file:///tmp/feed.json"] {XCTAssertThrowsError(try ContentUpdateRules.https(address))}
    }
    func corrected(_ bump: Bool) throws -> Data {
        try update {j in
            var facts=j["facts"] as! [[String:Any]];var value=facts[0]["value"] as! [String:Any];value["display"]="A corrected answer";facts[0]["value"]=value;j["facts"]=facts
            if bump {
                var objectives=j["objectives"] as! [[String:Any]]
                for i in objectives.indices where (objectives[i]["factIDs"] as! [String]).contains(facts[0]["id"] as! String) {objectives[i]["revision"]=2}
                j["objectives"]=objectives
            }
        }
    }
    func testCorrectionsNeedRevisionButSourceMetadataDoesNot() throws {
        let c=try cache();let active=try c.load().pack
        XCTAssertThrowsError(try c.stage(corrected(false),active:active))
        try c.stage(corrected(true),active:active)
        let metadata=try update(baseVersion+2) {j in var sources=j["sources"] as! [[String:Any]];sources[0]["verifiedAt"]="2026-10-09";j["sources"]=sources}
        try c.cancelPending();XCTAssertNoThrow(try c.stage(metadata,active:active))
    }
    func testReassignedKeyAndGraphIdentityAreRejected() throws {
        let c=try cache();let active=try c.load().pack
        let bad=try update {j in
            var entities=j["entities"] as! [[String:Any]]
            let index=entities.firstIndex {$0["key"] as? String == "entity-bale"}!
            entities[index]["id"]=UUID().uuidString;entities[index]["type"]="club";j["entities"]=entities
        }
        XCTAssertThrowsError(try c.stage(bad,active:active))
        let graph=try update {j in
            var relationships=j["relationships"] as! [[String:Any]];relationships[0]["id"]=UUID().uuidString;j["relationships"]=relationships
        }
        XCTAssertThrowsError(try c.stage(graph,active:active))
    }
    func testCompatibleResumePreservedChangedResumeArchivedAndRecallRefreshed() throws {
        let lesson=bundled.lessons[0],now=Date(timeIntervalSince1970:1800000000)
        var learner=LearnerState();learner.installedContentVersion=baseVersion
        _ = learner.completeLesson(lesson,pack:bundled,sessionID:UUID(),attempts:[],now:now)
        var resume=LessonResume();resume.step=6;resume.matched=["l-0","l-1"]
        resume.attempts=[Attempt(objectiveID:lesson.objectiveIDs[0],answer:"old",correct:true,hinted:false,mode:"acquisition",timestamp:now)]
        learner.resumes[lesson.id]=resume
        let unchanged=try ContentPack.load(update())
        var retained=learner
        XCTAssertEqual(retained.migrateContent(from:bundled,to:unchanged,now:now),0)
        XCTAssertEqual(retained.resumes[lesson.id]?.sessionID,resume.sessionID)
        let changed=try ContentPack.load(corrected(true))
        let store=StateStore(directory:directory);try store.archiveBeforeContentUpdate(learner)
        XCTAssertEqual(learner.migrateContent(from:bundled,to:changed,now:now),1)
        XCTAssertNil(learner.resumes[lesson.id]);XCTAssertEqual(learner.attempts.count,1)
        XCTAssertFalse(learner.completedLessons.contains(lesson.id))
        XCTAssertFalse(learner.acquiredCards.isEmpty);XCTAssertEqual(learner.reviews[lesson.objectiveIDs[0]]?.revision,2)
        XCTAssertEqual(learner.reviews[lesson.objectiveIDs[0]]?.refreshRequired,true)
        try store.save(learner);XCTAssertEqual(try store.load()?.installedContentVersion,baseVersion+1)
        XCTAssertEqual(learner.migrateContent(from:bundled,to:changed,now:now),0)
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath:directory.path).contains {$0.hasPrefix("learner-before-content-update-")})
    }
    func testPairMeaningChangeRetiresResumeEvenIfObjectiveRevisionSame() throws {
        let lesson=bundled.lessons[0];var learner=LearnerState();learner.installedContentVersion=baseVersion
        var resume=LessonResume();resume.step=6;resume.matched=["l-0","l-1"];learner.resumes[lesson.id]=resume
        let changed=try update {j in
            var exercises=j["exercises"] as! [[String:Any]];let i=exercises.firstIndex {$0["id"] as? String == lesson.exerciseIDs.last!.uuidString.lowercased()}!
            var right=exercises[i]["right"] as! [[String:Any]];right[0]["text"]=(right[0]["text"] as! String).uppercased();exercises[i]["right"]=right;j["exercises"]=exercises
        }
        let next=try ContentPack.load(changed)
        XCTAssertEqual(learner.migrateContent(from:bundled,to:next,now:Date()),1)
        XCTAssertTrue(learner.resumes.isEmpty)
    }
    func testValidJSONCorruptionRecoversPreviousAndBadPendingCannotActivate() throws {
        let c=try cache();let active=try c.load().pack;try c.stage(update(),active:active);_ = try c.load()
        let file=directory.appendingPathComponent("active.json")
        var entry=try JSONSerialization.jsonObject(with:Data(contentsOf:file)) as! [String:Any]
        entry["data"]=try update(baseVersion+3).base64EncodedString()
        try JSONSerialization.data(withJSONObject:entry).write(to:file,options:.atomic)
        XCTAssertEqual(try c.load().pack.contentVersion,baseVersion)
        try Data("truncated".utf8).write(to:directory.appendingPathComponent("pending.json"))
        let result=try c.load();XCTAssertEqual(result.pack.contentVersion,baseVersion);XCTAssertNotNil(result.notice)
    }
    func testRollbackKeepsEarnedTierAndRefreshesCurrentRevision() throws {
        var learner=LearnerState();let lesson=bundled.lessons[0],now=Date()
        learner.installedContentVersion=baseVersion
        _ = learner.completeLesson(lesson,pack:bundled,sessionID:UUID(),attempts:[],now:now)
        let card=bundled.cards.first {$0.lessonIDs.contains(lesson.id)}!
        for id in card.lessonIDs where id != lesson.id {_ = learner.completeLesson(bundled.lesson(id),pack:bundled,sessionID:UUID(),attempts:[],now:now)}
        for id in card.objectiveIDs {learner.reviews[id]?.stage=3;learner.reviews[id]?.highestEarned=3}
        learner.captureCardAchievements(bundled)
        let revised=try ContentPack.load(corrected(true))
        _ = learner.migrateContent(from:bundled,to:revised,now:now)
        XCTAssertEqual(learner.tier(card),3)
        _ = learner.migrateContent(from:revised,to:bundled,now:now)
        XCTAssertEqual(learner.tier(card),3)
        XCTAssertEqual(learner.reviews[lesson.objectiveIDs[0]]?.revision,1)
        XCTAssertEqual(learner.reviews[lesson.objectiveIDs[0]]?.refreshRequired,true)
        XCTAssertEqual(learner.streak.activeDays.count,1)
    }
    func testUnknownOldContentRetiresIncompatibleCompletionWithoutErasingAchievements() throws {
        var learner=LearnerState();let lesson=bundled.lessons[0]
        _ = learner.completeLesson(lesson,pack:bundled,sessionID:UUID(),attempts:[],now:Date())
        learner.installedContentVersion=4;learner.reviews.removeValue(forKey:lesson.objectiveIDs[0])
        learner.resumes[lesson.id]=LessonResume()
        XCTAssertEqual(learner.migrateContent(from:nil,to:bundled,now:Date()),1)
        XCTAssertFalse(learner.completedLessons.contains(lesson.id));XCTAssertFalse(learner.acquiredCards.isEmpty)
    }
    func testConflictingGradedExerciseIsRejected() throws {
        let bad=try update {j in
            var exercises=j["exercises"] as! [[String:Any]];exercises[0]["answerIDs"]=["choice-1"];j["exercises"]=exercises
        }
        XCTAssertThrowsError(try ContentUpdateRules.decode(bad,bundled:bundled))
    }
    func testNewerBundledPackWinsAndUnwritableCacheKeepsOfflineLessons() throws {
        let c=try cache();let active=try c.load().pack;try c.stage(update(),active:active);_ = try c.load()
        let upgraded=try ContentCache(directory:directory,bundledData:update(baseVersion+2))
        XCTAssertEqual(try upgraded.load().pack.contentVersion,baseVersion+2)
        XCTAssertEqual(upgraded.previousPack(version:baseVersion+1)?.contentVersion,baseVersion+1)
        let blocked=directory.appendingPathComponent("blocked")
        try Data().write(to:blocked)
        let unavailable=try ContentCache(directory:blocked,bundledData:data)
        let result=try unavailable.load();XCTAssertEqual(result.pack.contentVersion,baseVersion);XCTAssertNotNil(result.notice)
    }
    func testScoreOrientationCannotChangeUnderExistingRecallMemory() throws {
        let active=try cache().load().pack
        func changed(_ revise: Bool,_ reviseFact: Bool) throws -> Data {
            try update {j in
                var rows=j["exercises"] as! [[String:Any]]
                var objectiveID=""
                for i in rows.indices where (rows[i]["key"] as! String).contains("istanbul-choice-0") || (rows[i]["key"] as! String).contains("istanbul-choice-3") {
                    var score=rows[i]["scoreInput"] as! [String:Any]
                    let left=score["leftEntityID"]!;score["leftEntityID"]=score["rightEntityID"];score["rightEntityID"]=left
                    rows[i]["scoreInput"]=score;objectiveID=(rows[i]["objectiveIDs"] as! [String])[0]
                }
                j["exercises"]=rows
                var objectives=j["objectives"] as! [[String:Any]]
                let index=objectives.firstIndex {$0["id"] as! String == objectiveID}!
                if revise {objectives[index]["revision"]=2};j["objectives"]=objectives
                if reviseFact {
                    let factID=(objectives[index]["factIDs"] as! [String])[0]
                    var facts=j["facts"] as! [[String:Any]]
                    let fi=facts.firstIndex {$0["id"] as! String == factID}!
                    facts[fi]["scope"]="Changed factual context for a test correction";j["facts"]=facts
                }
            }
        }
        for (revision,context) in [(false,false),(true,false)] {
            let candidate=try ContentPack.load(changed(revision,context))
            XCTAssertThrowsError(try ContentUpdateRules.validateTransition(from:active,to:candidate))
        }
        let correction=try ContentPack.load(changed(true,true))
        XCTAssertNoThrow(try ContentUpdateRules.validateTransition(from:active,to:correction))
        let range=try ContentPack.load(update {j in
            var rows=j["exercises"] as! [[String:Any]]
            for i in rows.indices where rows[i]["scoreInput"] != nil {var score=rows[i]["scoreInput"] as! [String:Any];score["maximum"]=25;rows[i]["scoreInput"]=score};j["exercises"]=rows
        })
        XCTAssertNoThrow(try ContentUpdateRules.validateTransition(from:active,to:range))
    }

}
