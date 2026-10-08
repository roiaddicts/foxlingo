import XCTest
@testable import FoxlingoCore
final class MysteryTests: XCTestCase {
    var pack: ContentPack!
    var data: Data!
    var rounds: [MysteryRound]!
    override func setUpWithError() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent()
        pack=try ContentPack.load(Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/starter-en.json")))
        data=try Data(contentsOf:root.appendingPathComponent("Foxlingo/Resources/mystery-en.json"))
        rounds=try MysteryDeck.load(data,pack:pack)
    }
    func round(_ key: String) -> MysteryRound {rounds.first {$0.definition.key == "mystery-"+key}!}
    func testSixSourcedSubjectsDistinctFinalCluesAndNumericScope() {
        XCTAssertEqual(rounds.count,6)
        XCTAssertEqual(Set(rounds.map {MysteryRound.initials($0.player)}).count,6)
        for round in rounds {
            XCTAssertEqual(round.definition.clues.count,3);XCTAssertFalse(round.sources.isEmpty)
            for i in 0..<2 {
                let fact=round.facts[round.definition.clues[i].factID!]!
                XCTAssertFalse(fact.scope.isEmpty);XCTAssertFalse(fact.sourceKeys.isEmpty)
                XCTAssertNotEqual(Recall.normalize(round.value(at:i)),Recall.normalize(round.player.name))
                if fact.value.kind == "number" {XCTAssertNotNil(fact.value.unit)}
            }
        }
        XCTAssertEqual(round("saucedo").value(at:1),"11")
        XCTAssertEqual(round("saucedo").scope(at:1),"Clausura 2012 regular phase")
        XCTAssertNotNil(round("ramos").definition.clues[1].contextEntityID)
    }
    func testPlausibleForwardAndGoalkeeperAdvanceWithoutFalseContradiction() {
        var turn=MysteryTurn()
        XCTAssertEqual(turn.guess(round("cristiano").player,in:round("riascos")),.moreClues)
        XCTAssertEqual(turn.revealed,2);XCTAssertFalse(turn.solved)
        turn=MysteryTurn()
        XCTAssertEqual(turn.guess(round("casillas").player,in:round("saucedo")),.moreClues)
    }
    func testKnownRoleContradictionDoesNotRevealOrComplete() {
        var turn=MysteryTurn()
        XCTAssertEqual(turn.guess(round("ramos").player,in:round("casillas")),.contradicted)
        XCTAssertEqual(turn.revealed,1);XCTAssertFalse(turn.solved)
    }
    func testMissingStatEvidenceRemainsUnknownUntilFinalInitials() {
        var turn=MysteryTurn();turn.reveal(in:round("saucedo"))
        XCTAssertEqual(turn.guess(round("casillas").player,in:round("saucedo")),.moreClues)
        XCTAssertEqual(turn.revealed,3)
        XCTAssertEqual(turn.guess(round("casillas").player,in:round("saucedo")),.contradicted)
        XCTAssertEqual(turn.guess(round("saucedo").player,in:round("saucedo")),.identified)
        XCTAssertEqual(turn.guess(round("saucedo").player,in:round("saucedo")),.ignored)
        XCTAssertEqual(turn.guesses,3)
    }
    func testSolvedRoundLocksRevealsAndFinalInitialsIdentifyEverySubject() {
        for round in rounds {
            var turn=MysteryTurn();turn.reveal(in:round);turn.reveal(in:round);turn.reveal(in:round)
            XCTAssertEqual(turn.revealed,3)
            for other in rounds where other.id != round.id {XCTAssertEqual(turn.guess(other.player,in:round),.contradicted)}
            XCTAssertEqual(turn.guess(round.player,in:round),.identified)
            turn.reveal(in:round);XCTAssertEqual(turn.revealed,3)
        }
    }
    func testRetiredFactsHideAffectedRoundsAndUnsafeCluesDoNotPlay() throws {
        var definitions=try JSONSerialization.jsonObject(with:data) as! [[String:Any]]
        var clues=definitions[0]["clues"] as! [[String:Any]]
        clues[1]["factID"]=UUID().uuidString;definitions[0]["clues"]=clues
        XCTAssertEqual(try MysteryDeck.load(JSONSerialization.data(withJSONObject:definitions),pack:pack).count,5)
        clues[0]["predicate"]="unrelated";definitions[1]["clues"]=clues
        XCTAssertEqual(try MysteryDeck.load(JSONSerialization.data(withJSONObject:definitions),pack:pack).count,4)
    }
    func testMissingComparisonsBecomeUnknownAndScopeSpoilersHideRound() throws {
        var definitions=try JSONSerialization.jsonObject(with:data) as! [[String:Any]]
        for i in definitions.indices {
            var clues=definitions[i]["clues"] as! [[String:Any]]
            clues[0]["comparisonFactIDs"]=(clues[0]["comparisonFactIDs"] as! [String])+[UUID().uuidString]
            definitions[i]["clues"]=clues
        }
        XCTAssertEqual(try MysteryDeck.load(JSONSerialization.data(withJSONObject:definitions),pack:pack).count,6)
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        var facts=json["facts"] as! [[String:Any]]
        let target=round("ramos").definition.clues[1].factID!.uuidString
        let i=facts.firstIndex {($0["id"] as! String).lowercased() == target.lowercased()}!
        facts[i]["scope"]="Sergio Ramos’s Real Madrid career";json["facts"]=facts
        let changed=try ContentPack.load(JSONSerialization.data(withJSONObject:json))
        XCTAssertEqual(try MysteryDeck.load(data,pack:changed).count,5)
    }
    func testRetiringOnePlayersCourseLeavesOtherFiveRoundsPlayable() throws {
        var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(pack)) as! [String:Any]
        let subject=round("riascos").player.id.uuidString.lowercased()
        var facts=json["facts"] as! [[String:Any]]
        let retiredFacts=Set(facts.filter {($0["subjectID"] as! String).lowercased() == subject}.map {$0["id"] as! String})
        facts.removeAll {retiredFacts.contains($0["id"] as! String)};json["facts"]=facts
        var objectives=json["objectives"] as! [[String:Any]]
        let retiredObjectives=Set(objectives.filter {!Set($0["factIDs"] as! [String]).isDisjoint(with:retiredFacts)}.map {$0["id"] as! String})
        objectives.removeAll {retiredObjectives.contains($0["id"] as! String)};json["objectives"]=objectives
        var lessons=json["lessons"] as! [[String:Any]]
        let retiredLessons=Set(lessons.filter {!Set($0["objectiveIDs"] as! [String]).isDisjoint(with:retiredObjectives)}.map {$0["id"] as! String})
        lessons.removeAll {retiredLessons.contains($0["id"] as! String)};json["lessons"]=lessons
        json["exercises"]=(json["exercises"] as! [[String:Any]]).filter {Set($0["objectiveIDs"] as! [String]).isDisjoint(with:retiredObjectives)}
        json["cards"]=(json["cards"] as! [[String:Any]]).filter {Set($0["objectiveIDs"] as! [String]).isDisjoint(with:retiredObjectives)}
        json["relationships"]=(json["relationships"] as! [[String:Any]]).filter {Set($0["factIDs"] as! [String]).isDisjoint(with:retiredFacts)}
        var roadmaps=json["roadmaps"] as! [[String:Any]]
        roadmaps=roadmaps.compactMap {r in
            var r=r;var chapters=r["chapters"] as! [[String:Any]]
            for i in chapters.indices {chapters[i]["lessonIDs"]=(chapters[i]["lessonIDs"] as! [String]).filter {!retiredLessons.contains($0)}}
            chapters.removeAll {($0["lessonIDs"] as! [String]).isEmpty}
            guard chapters.contains(where:{$0["isOptional"] as? Bool != true}) else {return nil}
            r["chapters"]=chapters;return r
        };json["roadmaps"]=roadmaps
        let retired=try ContentPack.load(JSONSerialization.data(withJSONObject:json))
        XCTAssertEqual(try MysteryDeck.load(data,pack:retired).count,5)
    }
    func testDuplicateRoundIdentityIsRejected() throws {
        var definitions=try JSONSerialization.jsonObject(with:data) as! [[String:Any]]
        definitions.append(definitions[0])
        XCTAssertThrowsError(try MysteryDeck.load(JSONSerialization.data(withJSONObject:definitions),pack:pack))
    }
    func testGameCompletionCountsActivityOnceWithoutRecallOrCards() {
        var state=LearnerState();let id=UUID(),now=Date()
        XCTAssertTrue(state.completeGame(id:id,kind:"mystery",count:6,now:now))
        XCTAssertFalse(state.completeGame(id:id,kind:"mystery",count:6,now:now))
        XCTAssertEqual(state.sessions.count,1);XCTAssertEqual(state.streak.activeDays.count,1)
        XCTAssertTrue(state.reviews.isEmpty);XCTAssertTrue(state.acquiredCards.isEmpty)
    }
}
