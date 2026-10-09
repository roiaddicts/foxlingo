import XCTest
@testable import FoxlingoCore

final class PlayerCatalogTests: XCTestCase {
    func fixture() throws -> (ContentPack,URL) {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        return (try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json"))),root)
    }
    func testAuthoredPlayersHaveDistinctPathsCardsPortraitsAndSupportedClubEdges() throws {
        let (pack,root)=try fixture()
        let draft=try JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("content/player-catalog.json"))) as! [String:Any]
        let rows=draft["players"] as! [[String:Any]]
        let all=AlbumCollection.make(pack:pack,state:LearnerState(),scope:.all,discoveredOnly:false,query:"")
        let visible=Set(all.sections.flatMap {$0.cards.map(\.entityID)})
        for row in rows {
            let subject=try XCTUnwrap(pack.entities.first {$0.key == row["key"] as? String})
            let path=try XCTUnwrap(pack.playerRoadmaps.first {$0.entityID == subject.id})
            let progress=RoadmapProgress.make(roadmap:path,pack:pack,state:LearnerState())
            XCTAssertEqual(progress.requiredLessonIDs.count,2);XCTAssertEqual(progress.requiredObjectiveIDs.count,6)
            XCTAssertEqual(progress.optionalLessonIDs.count,1)
            let card=try XCTUnwrap(pack.cards.first {$0.entityID == subject.id})
            XCTAssertEqual(Set(card.objectiveIDs),progress.requiredObjectiveIDs)
            XCTAssertEqual(card.knowledgeVersion,1);XCTAssertTrue(visible.contains(subject.id))
            let asset=try XCTUnwrap(subject.imageAsset)
            XCTAssertTrue(FileManager.default.fileExists(atPath:root.appendingPathComponent("Foxlingo/Resources/Assets.xcassets/\(asset).imageset/image.png").path))
            let edge=try XCTUnwrap(pack.relationships?.first {$0.subjectID == subject.id && $0.key.hasPrefix("relationship-catalog-")})
            XCTAssertEqual(edge.objectID,path.clubID)
            XCTAssertTrue(edge.factIDs.allSatisfy {identifier in pack.facts.first {$0.id == identifier}?.subjectID == subject.id})
        }
        XCTAssertEqual(rows.count,14)
    }
    func testCuratedFootballAliasesAcceptEquivalentsAndRejectDistractors() throws {
        let (pack,_)=try fixture()
        let cases=[("catalog-zidane-final-opponent","Leverkusen","Liverpool"),("catalog-roberto-carlos-previous-club","Inter Milan","Juventus"),("catalog-roberto-carlos-role","LB","Centre-back"),("catalog-raul-role","Striker","Goalkeeper"),("catalog-gerrard-england-caps","114","710")]
        for (predicate,right,wrong) in cases {
            let fact=try XCTUnwrap(pack.facts.first {$0.predicate == predicate})
            let objective=try XCTUnwrap(pack.objectives.first {$0.factIDs.contains(fact.id)})
            XCTAssertTrue(Recall.accepts(right,for:objective));XCTAssertFalse(Recall.accepts(wrong,for:objective))
        }
        let xavi=try XCTUnwrap(pack.objectives.first {$0.key == "objective-enrichment-xavi-career-final-barcelona-season"})
        XCTAssertTrue(xavi.prompt.contains("year"));XCTAssertTrue(Recall.accepts("2015",for:xavi))
    }
    func testOfficialAndNationalTeamTotalsKeepDifferentScopes() throws {
        let (pack,_)=try fixture()
        func fact(_ key:String) throws -> Fact {try XCTUnwrap(pack.facts.first {$0.predicate == key})}
        let appearances=try fact("messi-record-official-appearances")
        XCTAssertEqual(appearances.value.number,778);XCTAssertTrue(appearances.scope.contains("2021-05-27"))
        XCTAssertEqual(try fact("messi-record-official-goals").value.number,672)
        XCTAssertEqual(try fact("catalog-gerrard-appearances").value.number,710)
        let england=try fact("catalog-gerrard-england-caps")
        XCTAssertEqual(england.value.number,114);XCTAssertTrue(england.scope.contains("England"))
        let raul=try fact("catalog-raul-senior-debut")
        XCTAssertEqual(raul.value.number,1994);XCTAssertTrue(raul.scope.contains("1992"))
        let rush=try fact("catalog-rush-best-season-goals")
        XCTAssertEqual(rush.value.number,47);XCTAssertTrue(rush.scope.contains("1983/84"))
    }
    func testArsenalCareerTotalsStaySeparateFromLeagueTotals() throws {
        let (pack,_)=try fixture()
        for (player,appearances,goals,leagueGoals) in [("henry",377,228,175),("bergkamp",423,120,87)] {
            func record(_ suffix:String) throws -> Fact {
                try XCTUnwrap(pack.facts.first {$0.predicate == "catalog-\(player)-record-\(suffix)"})
            }
            XCTAssertEqual(try record("arsenal-appearances").value.number,Double(appearances))
            XCTAssertEqual(try record("arsenal-goals").value.number,Double(goals))
            let league=try record("premier-league-goals")
            XCTAssertEqual(league.value.number,Double(leagueGoals))
            XCTAssertTrue(league.scope.contains("Premier League"))
        }
        let nationality=try XCTUnwrap(pack.facts.first {$0.predicate == "catalog-bergkamp-career-nationality"})
        XCTAssertEqual(pack.entity(try XCTUnwrap(nationality.value.entityID)).imageAsset,"flag-netherlands")
    }
}
