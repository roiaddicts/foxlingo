# Foxlingo — Product Vision

> Learn football’s stories, remember its facts, and feel prepared to cover it.

Status: full product vision, with an initial MVP direction. This document describes the ideal experience; it is not a commitment to build every feature in the first release.

## Who this is for

Foxlingo is an English-language iOS football-learning app designed first for my girlfriend, who works at Fox Sports. It helps her build general football fluency and prepare for coverage through short lessons, playful practice, and durable recall.

Her two favorite teams—**Club Tijuana (Xolos)** and **Real Madrid**—are the starting point. Personal interest should make the first lessons meaningful and returning enjoyable.

The long-term ambition is coverage across football leagues, clubs, players, competitions, and eras. Football comes first. The underlying model should accommodate other sports later without requiring their content or mechanics now.

## What success feels like

- She recognizes players and understands their careers, achievements, and significance.
- She can recall important team and competition history and explain why a moment mattered.
- She understands statistics in context and knows when a fact was last updated.
- She can prepare for an upcoming match without assembling information from many disconnected sources.
- She feels progress through her album and roadmaps, and enjoys returning with her leopard companion.
- Practice fits around work. Missing a day does not erase knowledge or make returning unpleasant.

The app succeeds when knowledge is retained and useful. Time spent, XP, and streak length are supporting signals, not substitutes for learning.

## The core experience

### Explore and learn

Choose multiple roadmaps and move between them freely. A league, club, player, or award can be a starting point. Suggested prerequisites provide context without preventing direct access to a useful subject.

Each roadmap contains chapters, short lessons, practice, and cumulative challenges. Shared facts connect roadmaps: learning a player’s championship win can advance relevant player, team, and competition objectives without teaching the same fact from scratch each time.

Roadmap structures adapt to the subject:

| Subject | Learning journey |
| --- | --- |
| League or competition | Origins and identity → format → historical eras → key moments and rivalries → defining teams and players → records → current season |
| Club or national team | Identity and origins → milestones → trophies and defining matches → rivalries → influential players → current squad and performance |
| Player | Identity and position → career timeline → clubs and national teams → breakthroughs and key moments → achievements and records → dated statistics |
| Award or tournament | Meaning and eligibility or format → historical editions → winners → decisive moments → connected players and teams |

Player discovery defaults to relevance within selected paths. Optional sorting includes market valuation, leaders in a selected statistic, and historical significance. There is no universal best-to-worst ordering: every ranking needs an explicit basis, source, and date.

### Daily practice

On opening the app, suggest a short review session based on due knowledge, recent mistakes, and selected interests. She can skip it and explore immediately. Reopening repeatedly should not force duplicate tests.

A typical session mixes retrieval of previous knowledge with a small amount of new material. Let her choose a shorter or longer session. Bound the review workload so an overdue queue remains approachable.

### Coverage preparation

Select an upcoming fixture or two teams to generate a focused study pack. Include:

- Team identities, relevant history, notable meetings, and rivalry context where supported.
- Current squads, likely relevant players, and dated performance statistics where available.
- Key opposing players and meaningful career connections: former teammates, shared clubs, national-team history, or notable previous encounters.
- Stories and questions she can use to test her readiness to explain the match.

Two selected teams do not need a direct head-to-head history. If none is supported, explain the gap and offer relevant comparisons and indirect connections. Manually selecting teams must not imply an actual scheduled fixture.

## The learning engine

Use retrieval practice and spaced practice as the foundation. Begin with accessible recognition, then develop independent recall and explanation. Provide immediate corrective feedback with context after mistakes.

Track learning at the level of a fact or learning objective and its retrieval prompts, rather than only lesson completion. Recognition, hinted answers, independent recall, and explanation provide different evidence. Seeing an answer is not equivalent to remembering it.

Practice scheduling should account for previous attempts, time since review, mistakes, and retrieval difficulty. Confident mistakes need correction, not extra credit. Session performance is evidence of learning, not proof of complete mastery.

The exact scheduling algorithm and tuning belong in the implementation specification. The product requires adaptive review, repeatable behavior, and a way to evaluate delayed recall.

### A reusable exercise system

Facts and relationships feed several game formats:

- Match players to clubs, nationalities, awards, positions, or statistics.
- Memory games with related pairs rather than merely identical pictures.
- Order career stops, milestones, or historical events.
- Identify a player, club, or event from progressively revealed clues.
- Compare statistics or rank subjects within a clearly defined context.
- Find an outlier and explain which relationship does not apply.
- Build connections between players, teams, competitions, and moments.
- Answer short recall questions and explain a story or comparison for coverage.

Every exercise defines its context and valid answers. A player may have represented several clubs or won multiple award editions. Matching must accept all applicable answers, or constrain the prompt sufficiently to make the intended answer clear.

Prefer contextual questions such as “Which club did this player represent in this season?” over ambiguous questions such as “What is this player’s club?” Avoid exact-value memorization for fast-changing estimates when comparison or approximate understanding better serves the learning goal.

## The album

Learning about a player, team, competition, or award unlocks its collectible card. Collection rewards discovery; card upgrades reward retention.

The intended progression is **cardboard → bronze → silver → gold → diamond**. Cards have a defined knowledge set, version, and historical or statistical scope. Upgrade criteria use repeated successful retrieval across spaced sessions and meaningful coverage of that set. A memory-game win or a completed lesson alone cannot establish diamond mastery.

Diamond means demonstrated mastery of the card’s defined, dated knowledge set. It does not mean knowing every possible statistic or guarantee perfect future recall.

New statistics create a refresh task without removing earned tiers. Show current recall and content freshness separately from collection achievements. Factual corrections can change the active knowledge set and its assessment without presenting an invalid answer as learned truth.

Album pages organize collections by favorite team, competition, era, national team, or award edition. Cards connect back to their lessons and graph relationships. Collection completion should reflect the selected collection, not imply exhaustive coverage of football.

## The leopard and game progression

A leopard mascot is the companion throughout the experience. It introduces stories, offers hints, reacts to answers, celebrates milestones, and welcomes her back. Its personality is playful, knowledgeable, and supportive. Its name and final visual identity remain design work for the MVP.

Use daily streaks, short quests, visible roadmap progress, chapter milestones, album upgrades, and cosmetic rewards to support returning. XP represents activity; it stays distinct from mastery.

One meaningful completed learning or review session counts toward the daily streak. Provide streak protection and forgiving recovery. Explain the day boundary and handle travel and offline completion consistently when implementing streaks.

Keep reminders optional and configurable. Avoid punitive lives, shame-based notifications, endless review obligations, and rewards that encourage repeating trivial questions without learning. The goal is an encouraging habit that serves her life and work.

Specific reward designs are hypotheses to test with her. An engaging interface does not by itself demonstrate better learning.

## The football knowledge graph

Use stable internal UUIDs for entities and occurrences. Human-readable keys help author and reference content; provider identifiers remain namespaced external mappings.

Core concepts include players, clubs, national teams, countries, leagues and competitions, seasons or editions, award definitions, award editions, matches, goals, and historical moments.

Separate recurring concepts from occurrences. The World Cup competition, its 2026 edition, a match in that edition, a goal in that match, and a team’s winning achievement are connected but distinct records. An individual award nomination is not the same as winning it; team success is not automatically an individual award.

Relationships carry their meaning and context:

- Club and national-team membership includes dates or a known season scope.
- Statistics specify metric, unit, subject, competition and season or career scope, source, and observation date.
- Market valuation includes currency, estimation source, and date; it is distinct from a transfer fee.
- A match links teams, competition edition, date, and supported participants and events.
- A goal links to its match, credited scorer or own-goal attribution, team, and other supported participants.
- Historical moments link to the relevant entities, evidence, and narrative.

Not every source will supply every goal or historical match. Model the capability without pretending the dataset is complete.

### Connection explorer

An Obsidian-like map lets her inspect nearby entities and discover the closest connection between two subjects. Explain each edge and show its context and evidence.

Offer meaningful relationship filters so a shortest path is useful rather than dominated by broad connections such as nationality. Shared club history does not prove two players were teammates unless their tenures overlap. The visual graph is an exploration feature; canonical JSON records remain its source of truth.

## JSON-defined content and AI generation

Keep three separate layers:

1. **Knowledge:** sourced entities, facts, relationships, and dated snapshots.
2. **Teaching:** roadmaps, chapters, lessons, objectives, exercise templates, and album knowledge sets.
3. **Personal learning:** attempts, review schedules, progress, streaks, and earned cards.

Versioned JSON packs define content and configure supported exercises. They can add a new roadmap without an app release. A genuinely new game mechanic still requires application code.

Illustrative structure—not the final schema:

```json
{
  "schemaVersion": 1,
  "key": "club-tijuana-foundations",
  "contentVersion": 1,
  "language": "en",
  "subjectKey": "club-tijuana",
  "chapters": [
    {
      "key": "identity-and-origins",
      "title": "Meet Xolos",
      "lessons": [
        {
          "key": "club-identity",
          "objectiveKeys": ["recognize-club-identity"],
          "factRefs": [],
          "exerciseTypes": ["multiple-choice", "relationship-match"]
        }
      ]
    }
  ]
}
```

This skeleton deliberately contains no fabricated football facts. Published lessons need populated, supported fact references and validated exercise content.

### Generate subjects on demand

When she requests an uncovered subject, retrieve available sources and structured data, resolve identities, normalize supported facts, generate a learning pack, validate it, and publish supported content automatically.

AI turns evidence into coherent teaching material. Its own assertion that a claim is verified is insufficient. Factual statements and answer keys must be traceable to supporting evidence. Unsupported, ambiguous, or conflicting claims remain outside graded practice.

Show whether generation is in progress, coverage is incomplete, or information is stale. Save validated packs for reuse. Do not make an AI call necessary for every lesson or app opening.

Changing facts produce dated versions. Corrections retire invalid questions and preserve valid learning history. Avoid teaching yesterday’s club association as an undated current fact.

### Delivery

Native iOS is the platform direction. Firebase is the preferred initial backend candidate for remote content and synchronized progress; its exact services belong in MVP architecture planning.

Support cached lessons and practice, eventual progress synchronization, pack validation, compatibility checks, and rollback to a working content version. Keep credentials for data providers and AI services on the server.

## Futbol11 as starter content

The local reference bundle, `ref/futbol11.js`, contains 37 embedded JSON datasets. These include player lists, club and nationality references, historical squads, career associations, teammate connections, themed lists, and game-oriented statistical and classification data.

Inspected examples include a player list with 2,729 records, 98 classic squads, 420 statistical lists, 369 themed lists, and 295 outlier challenges. These counts refer to individual datasets, not deduplicated players, independently verified facts, or complete football coverage.

Use these records as starter material for entity discovery, album subjects, relationships, and candidate exercises. Preserve the source bundle as a reference rather than executing its application code to import data.

The seed-import process should:

- Extract embedded JSON and inventory each dataset and its role.
- Namespace IDs by dataset: player `1` can represent different people in different lists.
- Decode comma-separated relationships and compact statistic encodings by inspecting how the original application uses them.
- Resolve references and reconcile overlapping identities before assigning canonical UUIDs. Names alone do not establish identity.
- Normalize aliases, position formats, dates, and numeric representations.
- Preserve original references and provenance, including uncertainty and unknown observation dates.
- Verify changing facts before publishing them as current; game ratings such as `ovr` are not objective performance rankings.
- Treat image paths as references that may require separate assets, not as bundled images guaranteed to work.

Do not assume a seed dataset contains Xolos or provides the complete history of either starting team. Inspect actual coverage, then enrich missing content from supported sources. Seeds provide a head start; AI and data feeds supply sourced enrichment and updates.

## First MVP direction: Xolos and Real Madrid

The first release should prove one complete learning loop across her two favorite teams:

1. Choose Xolos or Real Madrid.
2. Complete a short introductory lesson with supported club identity, history, and selected player content.
3. Practice through a small set of reusable exercises, starting with multiple choice and relationship matching.
4. Unlock an album card and see learning progress.
5. Return for spaced review, improve the card through recall, and maintain a streak with the leopard companion.

Provide a small, coherent roadmap for each team and let her alternate between them. Select players for relevance to these clubs and the introductory curriculum. Date any squad or statistical content explicitly.

Include the album concept, a basic leopard presence, and local learning persistence from the beginning. Keep the first knowledge sets small enough to complete and review. Exact lesson counts, initial player selection, tier thresholds, backend scope, and implementation architecture will be specified in the MVP plan.

The full graph explorer, on-demand AI generation, broad league coverage, advanced game formats, and comprehensive coverage preparation are later capabilities unless needed to validate the initial loop. Structure content so these additions do not require replacing the knowledge model.

The two starting clubs are independent learning paths. Their selection does not assume a head-to-head match or shared rivalry.

## Validation and acceptance

Evaluate delayed recall and her experience using the app, especially whether she feels more prepared and whether reviews remain manageable.

Important scenarios:

- Multiple roadmaps share one coordinated review queue and reuse relevant learned facts.
- Exercises accept all valid answers within their stated context.
- Transfers and statistical updates create dated practice without silently rewriting historical truth.
- Diamond requires successful recall across spaced sessions, beyond lesson completion or matching alone.
- Updated statistics create refresh tasks without removing earned tiers.
- Generated packs with unsupported answer keys cannot enter graded practice.
- Preparation packs explain missing evidence rather than inventing connections.
- Graph paths distinguish shared affiliation from simultaneous participation.
- Seed imports preserve dataset namespaces and avoid merging different people with the same name.
- Content updates preserve valid progress, and cached practice remains usable offline.
- Missed days lead to an approachable return rather than a punishing backlog.

## Evidence and open implementation work

Retrieval and spaced practice inform the learning foundation. Duolingo’s accounts offer product-design examples for habit formation; their outcomes are not guarantees for this app.

- [The Learning Scientists: learning-strategy FAQ](https://www.learningscientists.org/faq)
- [The Learning Scientists: spaced practice](https://www.learningscientists.org/blog/2016/7/21-1)
- [Duolingo: how streaks build habits](https://blog.duolingo.com/how-duolingo-streak-builds-habit/)
- [Sportmonks: league and data coverage](https://www.sportmonks.com/football-api/coverage/)
- [football-data.org: competition coverage](https://www.football-data.org/coverage)

Provider coverage, historical depth, supported statistics, and costs vary. “All leagues” is a long-term expansion goal, not a claim that a single source already supplies every required fact.

Next: define the MVP implementation around Xolos and Real Madrid, including the exact initial curriculum, source strategy, JSON contract, learning scheduler, album criteria, visual direction, and acceptance checks. Public accounts, social competition, and monetization are not priorities for this personal first release.
