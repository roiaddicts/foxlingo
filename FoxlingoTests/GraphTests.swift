import XCTest
@testable import FoxlingoCore

final class GraphTests: XCTestCase {
    var pack: ContentPack!
    override func setUpWithError() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
    }
    func id(_ key:String) -> UUID {pack.entities.first {$0.key == "entity-"+key}!.id}
    func testSelfFactsStayDetailsNotPathEdges() {
        let graph=KnowledgeGraph(pack:pack)
        XCTAssertFalse(graph.edges.contains {$0.subjectID == $0.objectID})
        XCTAssertTrue(pack.facts.contains {$0.key == "fact-madrid-equalizer"})
        XCTAssertEqual(graph.shortestPath(from:id("xolos"),to:id("xolos"))?.count,0)
        XCTAssertNil(graph.shortestPath(from:UUID(),to:UUID()))
        XCTAssertEqual(graph.nodes.count,pack.entities.count)
        XCTAssertFalse(graph.nodes.contains {$0.name == "725"})
    }
    func testReverseTraversalPreservesClaimDirectionAndEvidence() throws {
        let graph=KnowledgeGraph(pack:pack)
        let forward=try XCTUnwrap(graph.shortestPath(from:id("arce"),to:id("xolos"),groups:[.history]))
        let backward=try XCTUnwrap(graph.shortestPath(from:id("xolos"),to:id("arce"),groups:[.history]))
        XCTAssertEqual(forward.count,1);XCTAssertEqual(backward.count,1)
        XCTAssertEqual(forward[0].edge.id,backward[0].edge.id)
        XCTAssertEqual(backward[0].edge.subjectID,id("arce"))
        XCTAssertEqual(backward[0].edge.objectID,id("xolos"))
        XCTAssertEqual(backward[0].fromID,id("xolos"))
        XCTAssertTrue(backward[0].edge.scope.contains("2012"))
        XCTAssertTrue(backward[0].edge.claim.contains("Arce"))
    }
    func testHistoricalClubPathDoesNotInventTeammates() throws {
        let path=try XCTUnwrap(KnowledgeGraph(pack:pack).shortestPath(from:id("di-stefano"),to:id("cristiano"),groups:[.history]))
        XCTAssertEqual(path.count,2);XCTAssertEqual(path[0].toID,id("madrid"))
        XCTAssertFalse(path.contains {$0.edge.claim.lowercased().contains("teammate")})
    }
    func testFiltersApplyToEveryStepAndDisconnectedIsUnsupported() {
        let graph=KnowledgeGraph(pack:pack)
        XCTAssertEqual(graph.shortestPath(from:id("arce"),to:id("caliente"),groups:[.history,.places])?.count,2)
        XCTAssertNil(graph.shortestPath(from:id("arce"),to:id("caliente"),groups:[.history]))
        XCTAssertNil(graph.shortestPath(from:id("xolos"),to:id("madrid")))
        XCTAssertNil(graph.shortestPath(from:id("riascos"),to:id("colombia"),groups:[.history,.events]))
        XCTAssertEqual(graph.shortestPath(from:id("riascos"),to:id("colombia"),groups:[.origins])?.count,1)
    }
    func testMatchGoalAndTieHaveSeparateCanonicalIdentity() throws {
        let graph=KnowledgeGraph(pack:pack)
        let path=try XCTUnwrap(graph.shortestPath(from:id("ramos"),to:id("cristiano"),groups:[.events]))
        XCTAssertEqual(path.count,3)
        XCTAssertEqual(path[0].toID,id("ramos-equalizer-2014"))
        XCTAssertEqual(path[1].toID,id("final-2014"))
        XCTAssertEqual(pack.entity(id("xolos-final-2012")).type,"tie")
        XCTAssertEqual(pack.entity(id("final-2014")).type,"match")
        XCTAssertEqual(pack.entity(id("ramos-equalizer-2014")).type,"goal")
        for edge in path.map(\.edge) {
            XCTAssertFalse(edge.factIDs.isEmpty)
            XCTAssertTrue(edge.scope.contains("2014"))
            XCTAssertTrue(edge.factIDs.allSatisfy {id in pack.facts.contains {$0.id == id && !$0.sourceKeys.isEmpty}})
        }
    }
    func testParallelClaimsRemainSeparateAndPathsDeterministic() throws {
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        var rows=json["relationships"] as! [[String:Any]]
        var extra=rows.first {$0["key"] as! String == "relationship-ramos-madrid"}!
        let extraID=UUID();extra["id"]=extraID.uuidString;extra["key"]="relationship-test-parallel";extra["scope"]="Separate historical scope"
        rows.append(extra);json["relationships"]=rows
        let extended=try ContentPack.load(JSONSerialization.data(withJSONObject:json)),graph=KnowledgeGraph(pack:extended)
        let parallel=graph.neighbors(of:id("ramos")).filter {$0.objectID == id("madrid")}
        XCTAssertEqual(parallel.count,2);XCTAssertEqual(Set(parallel.map(\.scope)).count,2)
        let expected=graph.shortestPath(from:id("ramos"),to:id("atletico"))!.map {$0.edge.id}
        for _ in 0..<20 {XCTAssertEqual(graph.shortestPath(from:id("ramos"),to:id("atletico"))?.map {$0.edge.id},expected)}
        json["relationships"]=Array(rows.reversed())
        json["entities"]=Array((json["entities"] as! [[String:Any]]).reversed())
        json["facts"]=Array((json["facts"] as! [[String:Any]]).reversed())
        let reordered=KnowledgeGraph(pack:try ContentPack.load(JSONSerialization.data(withJSONObject:json)))
        XCTAssertEqual(reordered.shortestPath(from:id("ramos"),to:id("atletico"))?.map {$0.edge.id},expected)
    }
    func testDuplicateNamesDoNotMergeIdentities() throws {
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        var entities=json["entities"] as! [[String:Any]],duplicate=entities.first {$0["key"] as! String == "entity-madrid"}!
        let duplicateID=UUID();duplicate["id"]=duplicateID.uuidString;duplicate["key"]="entity-test-duplicate-name";entities.append(duplicate);json["entities"]=entities
        let extended=try ContentPack.load(JSONSerialization.data(withJSONObject:json)),graph=KnowledgeGraph(pack:extended)
        XCTAssertNil(graph.shortestPath(from:duplicateID,to:id("madrid")))
        XCTAssertTrue(graph.neighbors(of:duplicateID).isEmpty)
    }
    func testAuthoredEdgesRejectMissingEvidenceBrokenEndpointsAndSelfLoops() throws {
        let base=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        for change in ["factIDs","objectID","claim","scope"] {
            var json=base,rows=json["relationships"] as! [[String:Any]]
            rows[0][change]=change == "factIDs" ? [] : change == "objectID" ? UUID().uuidString : ""
            json["relationships"]=rows
            XCTAssertThrowsError(try ContentPack.load(JSONSerialization.data(withJSONObject:json)),change)
        }
        var json=base,rows=json["relationships"] as! [[String:Any]]
        rows[0]["objectID"]=rows[0]["subjectID"];json["relationships"]=rows
        XCTAssertThrowsError(try ContentPack.load(JSONSerialization.data(withJSONObject:json)))
    }
    func testOlderPackWithoutAuthoredRelationshipsLoads() throws {
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        json.removeValue(forKey:"relationships")
        let old=try ContentPack.load(JSONSerialization.data(withJSONObject:json))
        XCTAssertNil(old.relationships)
        XCTAssertEqual(KnowledgeGraph(pack:old).edges.count,old.facts.filter {$0.value.entityID != nil && $0.value.entityID != $0.subjectID}.count)
    }
    func testClubCountriesAreCanonicalAndExcludedFromFootballPaths() throws {
        let graph=KnowledgeGraph(pack:pack)
        let arsenal=id("arsenal"),united=id("manchester-united")
        let path=try XCTUnwrap(graph.shortestPath(from:arsenal,to:united,groups:[.origins]))
        XCTAssertEqual(path.count,2);XCTAssertEqual(pack.entity(path[0].toID).name,"England")
        XCTAssertTrue(path.allSatisfy {$0.edge.group == .origins})
        XCTAssertNil(graph.shortestPath(from:arsenal,to:united,groups:[.history,.events]))
        let fact=pack.facts.first {$0.key == "fact-expansion-arsenal-country"}!
        XCTAssertEqual(fact.value.display,"England");XCTAssertEqual(fact.value.kind,"entity")
        XCTAssertEqual(pack.objectives.first {$0.factIDs.contains(fact.id)}?.revision,1)
    }
}
