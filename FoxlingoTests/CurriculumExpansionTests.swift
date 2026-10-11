import XCTest
@testable import FoxlingoCore

final class CurriculumExpansionTests: XCTestCase {
    func testCristianoCareerSharesSportingProgressWithoutDuplicatingThePlayer() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
        let player=try XCTUnwrap(pack.entities.first {$0.key == "entity-cristiano"})
        let routes=pack.playerRoadmaps.filter {$0.entityID == player.id}
        XCTAssertEqual(routes.count,1)
        let route=try XCTUnwrap(routes.first)
        let sporting=try XCTUnwrap(pack.clubRoadmaps.first {$0.key == "roadmap-sporting-cp"})
        let madrid=try XCTUnwrap(pack.clubRoadmaps.first {$0.key == "roadmap-madrid"})
        let lesson=try XCTUnwrap(pack.lessons.first {$0.key == "lesson-curriculum-portugal-cristiano-career"})
        var state=LearnerState()
        state.completeLesson(lesson,pack:pack,sessionID:UUID(),attempts:[],now:Date())
        XCTAssertEqual(RoadmapProgress.make(roadmap:route,pack:pack,state:state).completedRequired,1)
        XCTAssertEqual(RoadmapProgress.make(roadmap:sporting,pack:pack,state:state).completedRequired,1)
        XCTAssertEqual(RoadmapProgress.make(roadmap:madrid,pack:pack,state:state).completedRequired,0)
        let card=try XCTUnwrap(pack.cards.first {$0.entityID == player.id})
        XCTAssertEqual(card.knowledgeVersion,4)
        XCTAssertEqual(Set(card.lessonIDs).count,8)
        XCTAssertTrue(Set(lesson.objectiveIDs).isSubset(of:Set(card.objectiveIDs)))
        let due=state.reviews.mapValues(\.due)
        state.completeLesson(lesson,pack:pack,sessionID:UUID(),attempts:[],now:Date())
        XCTAssertEqual(state.reviews.mapValues(\.due),due)
    }
    func testNewPlayerCoursesTeachTheirOwnFactsAndShareCanonicalClubLessons() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
        for key in ["entity-marco-reus","entity-patrik-schick","entity-buffon","entity-del-piero","entity-guillermo-ochoa","entity-jose-saturnino-cardozo","entity-hernan-cristante","entity-timo-werner","entity-mario-gomez","entity-hirving-lozano","entity-miguel-calero","entity-mbappe","entity-ibrahimovic","entity-aguero","entity-griezmann","entity-carlos-hermosillo","entity-oscar-perez","entity-hugo-sanchez","entity-jorge-campos","entity-victor-davila","entity-fidel-ambriz","entity-deco","entity-vitor-baia","entity-luis-figo","entity-claudio-pizarro","entity-miroslav-klose","entity-uwe-seeler","entity-kevin-keegan","entity-nils-petersen","entity-vincenzo-grifo","entity-jurgen-klopp","entity-stefan-bell","entity-ruud-van-nistelrooy","entity-arjen-robben","entity-dirk-kuyt","entity-robin-van-persie","entity-lothar-matthaus","entity-guenter-netzer","entity-helmut-haller","entity-daniel-baier","entity-andrej-kramaric","entity-niklas-sule","entity-maximilian-kruse","entity-taiwo-awoniyi","entity-wayne-rooney","entity-paul-scholes","entity-diego-forlan","entity-marcos-senna","entity-rafael-marquez","entity-camilo-vargas","entity-jared-borgetti","entity-oswaldo-sanchez","entity-joaquin-velazquez","entity-benito-pardo","entity-lukas-podolski","entity-anthony-modeste","entity-klaas-jan-huntelaar","entity-jefferson-farfan","entity-horacio-casarin","entity-ivo-basay","entity-ronaldinho","entity-tiago-volpi","entity-camilo-sanvezzo","entity-fernando-aristeguieta","entity-francesco-totti","entity-daniele-de-rossi","entity-paul-mcgrath","entity-dwight-yorke","entity-luca-schnellbacher","entity-manuel-feil","entity-uwe-huenemeier","entity-mahir-saglik"] {
            let player=try XCTUnwrap(pack.entities.first {$0.key == key})
            let route=try XCTUnwrap(pack.playerRoadmaps.first {$0.entityID == player.id})
            let club=try XCTUnwrap(pack.clubRoadmaps.first {$0.clubID == route.clubID})
            let progress=RoadmapProgress.make(roadmap:route,pack:pack,state:LearnerState())
            XCTAssertEqual(progress.requiredLessonIDs.count,4)
            XCTAssertEqual(progress.requiredObjectiveIDs.count,12)
            XCTAssertEqual(progress.optionalLessonIDs.count,1)
            XCTAssertTrue(Set(progress.requiredLessonIDs).isSubset(of:Set(club.chapters.flatMap(\.lessonIDs))))
            for id in progress.requiredObjectiveIDs {
                let objective=pack.objective(id)
                XCTAssertTrue(objective.factIDs.allSatisfy {factID in pack.facts.first {$0.id == factID}?.subjectID == player.id})
            }
            var state=LearnerState()
            state.selectRoadmap(route,pack:pack)
            let lesson=pack.lesson(progress.requiredLessonIDs[0])
            state.completeLesson(lesson,pack:pack,sessionID:UUID(),attempts:[],now:Date())
            XCTAssertEqual(RoadmapProgress.make(roadmap:club,pack:pack,state:state).completedRequired,1)
            XCTAssertEqual(state.reviews.count,3)
            XCTAssertFalse(RoadmapProgress.make(roadmap:route,pack:pack,state:state).isComplete)
        }
        for key in ["entity-jose-saturnino-cardozo","entity-hernan-cristante"] {
            let player=try XCTUnwrap(pack.entities.first {$0.key == key})
            XCTAssertNil(player.externalRefs["futbol11.gamePlayers"])
            XCTAssertNil(player.imageAsset)
        }
        let wolfsburg=try XCTUnwrap(pack.entities.first {$0.key == "entity-wolfsburg"})
        XCTAssertNotNil(wolfsburg.imageAsset)
        XCTAssertFalse(pack.clubRoadmaps.contains {$0.clubID == wolfsburg.id})
    }
    func testNewMatchScoresUseCorrectOrientationAndCachedVisualAnswers() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
        for (key,left,right,a,b) in [("hoffenheim-playoff-second-leg","entity-kaiserslautern","entity-hoffenheim",1,2),("hoffenheim-playoff-aggregate","entity-hoffenheim","entity-kaiserslautern",5,2),("uv-villarreal-arsenal-aggregate","entity-villarreal","entity-arsenal",0,1),("santos-2012-aggregate","entity-monterrey","entity-santos-laguna",3,2),("eighth-elv-lev-score","entity-elversberg","entity-bayer-leverkusen",4,3)] {
            let objective=try XCTUnwrap(pack.objectives.first {$0.key == "objective-enrichment-"+key})
            let exercise=try XCTUnwrap(pack.exercises.first {$0.objectiveIDs.contains(objective.id) && $0.scoreInput != nil})
            let score=try XCTUnwrap(exercise.scoreInput)
            XCTAssertEqual(pack.entity(score.leftEntityID).key,left)
            XCTAssertEqual(pack.entity(score.rightEntityID).key,right)
            XCTAssertTrue(score.accepts(left:a,right:b));XCTAssertFalse(score.accepts(left:b,right:a))
        }
        let subjects=Set(["entity-elversberg","entity-paderborn-07","entity-luca-schnellbacher","entity-manuel-feil","entity-uwe-huenemeier","entity-mahir-saglik","entity-aston-villa","entity-paul-mcgrath","entity-dwight-yorke","entity-hoffenheim","entity-union-berlin","entity-manchester-united","entity-villarreal","entity-atlas","entity-santos-laguna","entity-puebla","entity-andrej-kramaric","entity-niklas-sule","entity-maximilian-kruse","entity-taiwo-awoniyi","entity-wayne-rooney","entity-paul-scholes","entity-diego-forlan","entity-marcos-senna","entity-rafael-marquez","entity-camilo-vargas","entity-jared-borgetti","entity-oswaldo-sanchez","entity-joaquin-velazquez","entity-benito-pardo","entity-francesco-totti","entity-daniele-de-rossi"])
        for fact in pack.facts where subjects.contains(pack.entity(fact.subjectID).key) {
            let objective=try XCTUnwrap(pack.objectives.first {$0.factIDs.contains(fact.id)})
            guard let type=AnswerArtwork.type(objectiveID:objective.id,pack:pack) else {continue}
            for choice in pack.exercises.filter({$0.objectiveIDs.contains(objective.id)}).flatMap(\.choices) {
                XCTAssertTrue(AnswerArtwork.canShow(choice.text,type:type,pack:pack),fact.key+": "+choice.text)
                let asset=type == "country" ? AnswerArtwork.flags[Recall.normalize(choice.text)] : AnswerArtwork.entity(choice.text,type:type,pack:pack)?.imageAsset
                if let asset {XCTAssertTrue(FileManager.default.fileExists(atPath:root.appendingPathComponent("Foxlingo/Resources/Assets.xcassets/"+asset+".imageset/image.png").path),asset)}
            }
        }
    }

    func testClassicPlayerBindingPreservesNamespaceAndOfficialPortraitFallback() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
        let farfan=try XCTUnwrap(pack.entities.first {$0.key == "entity-jefferson-farfan"})
        XCTAssertEqual(farfan.externalRefs["futbol11.classicPlayers"],"2497")
        XCTAssertNil(farfan.externalRefs["futbol11.gamePlayers"])
        XCTAssertNil(farfan.imageAsset)
        let games=try JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/games-en.json"))) as! [String:Any]
        let seeds=games["players"] as! [[String:Any]]
        XCTAssertEqual(seeds.first {$0["id"] as? String == "classic-player-2497"}?["name"] as? String,farfan.name)
        let modeste=try XCTUnwrap(pack.entities.first {$0.key == "entity-anthony-modeste"})
        let artwork=try JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/artwork-manifest.json"))) as! [[String:Any]]
        let portrait=try XCTUnwrap(artwork.first {$0["asset"] as? String == modeste.imageAsset})
        XCTAssertEqual(portrait["cached"] as? Bool,true)
        XCTAssertTrue((portrait["sourceURL"] as? String)?.contains("datencenter.dfb.de/personen/anthony-modeste/") == true)
    }

    func testHistoricalMazatlanCourseAndDistinctShootoutScores() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
        let club=try XCTUnwrap(pack.entities.first {$0.key == "entity-mazatlan"})
        XCTAssertNil(club.competitions)
        XCTAssertNotNil(club.imageAsset)
        XCTAssertNotNil(pack.clubRoadmaps.first {$0.clubID == club.id})
        for (key,left,right) in [("fifth-maz-cup2024-regulation",2,2),("fifth-maz-cup2024-shootout",3,1)] {
            let objective=try XCTUnwrap(pack.objectives.first {$0.key == "objective-enrichment-"+key})
            let exercise=try XCTUnwrap(pack.exercises.first {$0.objectiveIDs.contains(objective.id) && $0.scoreInput != nil})
            let score=try XCTUnwrap(exercise.scoreInput)
            XCTAssertEqual(pack.entity(score.leftEntityID).key,"entity-mazatlan")
            XCTAssertEqual(pack.entity(score.rightEntityID).key,"entity-cruz-azul")
            XCTAssertTrue(score.accepts(left:left,right:right))
            if left != right {XCTAssertFalse(score.accepts(left:right,right:left))}
        }
        for key in ["entity-camilo-sanvezzo","entity-fernando-aristeguieta"] {
            let player=try XCTUnwrap(pack.entities.first {$0.key == key})
            XCTAssertNotNil(player.imageAsset)
            XCTAssertTrue(player.externalRefs.isEmpty)
        }
    }

    func testTolucaAddedFinalsPreserveScoreScopeAndCardVersion() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
        let club=try XCTUnwrap(pack.entities.first {$0.key == "entity-toluca"})
        let card=try XCTUnwrap(pack.cards.first {$0.entityID == club.id})
        XCTAssertEqual(card.knowledgeVersion,3)
        let path=try XCTUnwrap(pack.clubRoadmaps.first {$0.clubID == club.id})
        XCTAssertEqual(path.chapters.first {$0.title == "Defining moments"}?.lessonIDs.count,5)
        for (key,right,a,b) in [("toluca-next-1975-score","entity-leon",1,0),("toluca-next-2000-away","entity-santos-laguna",2,0),("toluca-next-2000-aggregate","entity-santos-laguna",7,1),("toluca-next-2005-home","entity-monterrey",3,3),("toluca-next-2005-away","entity-monterrey",3,0)] {
            let objective=try XCTUnwrap(pack.objectives.first {$0.key == "objective-enrichment-"+key})
            let score=try XCTUnwrap(pack.exercises.first {$0.objectiveIDs.contains(objective.id)}?.scoreInput)
            XCTAssertEqual(pack.entity(score.leftEntityID).key,"entity-toluca")
            XCTAssertEqual(pack.entity(score.rightEntityID).key,right)
            XCTAssertTrue(score.accepts(left:a,right:b))
            if a != b {XCTAssertFalse(score.accepts(left:b,right:a))}
        }
        let australia=try XCTUnwrap(pack.entities.first {$0.key == "entity-country-australia"})
        XCTAssertEqual(australia.imageAsset,"flag-australia")
        XCTAssertEqual(AnswerArtwork.flags["australia"],australia.imageAsset)
    }

    func testVillaNationalScoresUseCanonicalFlagsAndRejectPlayerSides() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        let url=root.appendingPathComponent("Foxlingo/Resources/starter-en.json")
        let data=try Data(contentsOf:url);let pack=try ContentPack.load(data)
        for (key,left,right,a,b) in [("villa-mcgrath-italy-score","entity-country-ireland","entity-country-italy",1,0),("villa-yorke-sweden-result","entity-country-trinidad-and-tobago","entity-country-sweden",0,0)] {
            let objective=try XCTUnwrap(pack.objectives.first {$0.key == "objective-enrichment-"+key})
            let score=try XCTUnwrap(pack.scoreInput(for:objective.id))
            XCTAssertEqual(pack.entity(score.leftEntityID).key,left)
            XCTAssertEqual(pack.entity(score.rightEntityID).key,right)
            XCTAssertTrue(score.accepts(left:a,right:b))
            XCTAssertFalse(score.accepts(left:a+1,right:b))
            XCTAssertTrue(pack.entity(score.leftEntityID).imageAsset?.hasPrefix("flag-") == true)
        }
        var json=try JSONSerialization.jsonObject(with:data) as! [String:Any]
        var entities=json["entities"] as! [[String:Any]]
        let i=try XCTUnwrap(entities.firstIndex {$0["key"] as? String == "entity-country-ireland"})
        entities[i]["type"]="player";json["entities"]=entities
        XCTAssertThrowsError(try ContentPack.load(JSONSerialization.data(withJSONObject:json)))
    }

}
