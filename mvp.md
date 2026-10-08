# Foxlingo MVP — Xolos & Real Madrid

Status: baseline implementation specification for the first personal iPhone release. The current build also includes the club expansion, visual football games, daily planning, and offline comparison packs documented in README.md. The full ambition lives in [vision.md](vision.md).

## The first release

Build a native, English-language iOS app in which she can learn about her two favorite teams, collect cards, and return for short reviews. The first release proves this loop:

**Choose a team → read a short story → answer questions → unlock a card → return for spaced recall → improve the card.**

Deliver two team roadmaps, 12 lessons, 36 lesson objective slots (35 unique memories; the Ramos equalizer is shared), eight collectible cards, three exercise formats, a shared review queue, a daily streak, and a friendly leopard companion.

Start with durable historical knowledge and explicitly scoped historical statistics. Live squads, valuations, automated AI generation, remote content publishing, accounts, social features, match preparation, and the graph explorer follow after this loop works. The first app must be useful offline without a backend subscription.

## Curriculum

Each roadmap has three chapters: **Meet the club** (two lessons), **A defining night** (one lesson), and **Meet the players** (three lessons). Each lesson introduces exactly three learning objectives and approximately 100–150 words of original English teaching content, followed by practice. Target roughly three minutes per lesson, without imposing a timer.

Player choices below are an editorial starting selection, not a ranking or a current squad. Selecting historical figures keeps the curriculum coherent with each club's defining event.

| Roadmap | Lesson | Three objective topics |
| --- | --- | --- |
| Xolos | Meet Xolos | Club identity and nickname; home city; Estadio Caliente |
| Xolos | The climb | Foundation in 2007; promotion in 2011; first top-flight championship in Apertura 2012 |
| Xolos | The 2012 final | Toluca as opponent; 4–1 aggregate result; title secured on December 2, 2012 |
| Xolos | Duvier Riascos | Colombian origin; forward position; Puebla before joining Xolos for Clausura 2012 |
| Xolos | Fernando Arce | Midfield role; Tijuana connection; Xolos association during Apertura 2012 |
| Xolos | Cirilo Saucedo | Goalkeeper role; 11 goals conceded in the Clausura 2012 regular phase; 17 regular-phase appearances in that tournament |
| Real Madrid | Meet Madrid | Club identity; home city; founding year 1902 |
| Real Madrid | European roots | First European Cup in 1956; five consecutive wins through 1960; Di Stéfano's association with that era |
| Real Madrid | La Décima | Atlético as opponent; 2014 final; Ramos's equalizer sending the match to extra time |
| Real Madrid | Cristiano Ronaldo | Forward role; Real Madrid career association; scoring in the 2014 final |
| Real Madrid | Sergio Ramos | Defender role; 2014 final equalizer; 101 goals during his Real Madrid career, as recorded by the club |
| Real Madrid | Iker Casillas | Goalkeeper role; first-team debut in 1999; 725 official Real Madrid appearances |

The eight cards are the two clubs and these six players. Each club card has nine objectives from its first three lessons; each player card has three objectives from its lesson. Supporting entities such as Toluca and Atlético can appear in facts and answers without becoming collectible cards in this release.

Do not add current title totals, current clubs, or career-goal figures from seeds without resolving their scope and sourcing. In particular, a seed rating such as `ovr` is not a real-world performance ranking. Any starter objective whose evidence cannot be confirmed must be replaced with another supported fact about the same subject before shipping; do not fill gaps with invented content.

### Source anchors

These official pages support the selected curriculum; record evidence per fact when producing the content JSON. Checking a source page is not a blanket endorsement of every statement in it. Keep original lesson prose factual and distinct from promotional language.

- Xolos identity, founding and promotion: [club history](https://www.xolos.com.mx/historia-del-club).
- Xolos venue and early milestones: [Estadio Caliente anniversary](https://xolos.com.mx/noticias/primer-equipo/11738).
- Xolos championship timing: [club historical recap](https://xolos.com.mx/noticias/primer-equipo/7815); aggregate result: [2012 final recap](https://xolos.com.mx/noticias/primer-equipo/3342).
- Riascos's origin, position and previous club: [official signing announcement](https://xolos.com.mx/noticias/xoloitzcuintles/2515/%E2%80%9C).
- Arce's position and Tijuana connection: [Apertura 2012 interview](https://xolos.com.mx/noticias/primer-equipo/7521).
- Saucedo's historically scoped statistics: [Clausura 2012 award nominations](https://xolos.com.mx/noticias/xoloitzcuintles/2189/www.codersmx.com).
- Madrid founding and early European era: [124-year historical recap](https://www.realmadrid.com/en-US/news/club/latest-news/124-anos-de-leyenda-06-03-2026).
- The 2014 final and its participants: [La Décima anniversary](https://www.realmadrid.com/es-ES/noticias/club/actualidad/octavo-aniversario-de-la-decima).
- Player context: [Cristiano Ronaldo](https://www.realmadrid.com/en-US/the-club/history/football-legends/cristiano-ronaldo-dos-santos-aveiro/), [Sergio Ramos](https://www.realmadrid.com/en-US/the-club/history/football-legends/sergio-ramos-garcia?pid=1384791177940), and [Iker Casillas](https://www.realmadrid.com/en-US/the-club/history/football-legends/iker-casillas-fernandez).

Research date: October 8, 2026. Importers must retain source URLs, verification date, and historical scope. Review related source discrepancies explicitly rather than choosing whichever number is most convenient.

## Screens and session flow

Use four bottom tabs: **Learn**, **Practice**, **Games**, and **Album**. Put settings behind a toolbar button; a separate profile tab is unnecessary for one personal learner.

### First launch

Welcome with the leopard, show both starting clubs, and ask which one she wants to study first. This sets the initial roadmap without limiting access to the other one. Default session suggestion is three minutes. No signup or permission prompt is required to start learning.

### Learn

Show the selected club's roadmap, a club switcher, lesson progress, streak, and a single recommended next action. Use chapter labels and a connected vertical lesson path. Visually distinguish new, started, and completed lessons.

All lessons remain selectable. The recommended sequence follows the chapter order. An interrupted lesson resumes locally; completed lessons can be replayed.

Each lesson has two short story screens followed by four multiple-choice questions and one matching board. Every objective must be assessed at least once; the fourth question rephrases one objective. A wrong answer shows the correct answer and explanation, then offers a retry. Completion requires finishing the activities, not a perfect first-attempt score. Preserve first-attempt results; retries are not independent mastery evidence.

The result screen shows what was practiced, any card unlocked, and the actual next review date. New objectives enter review after lesson completion, including those missed during practice; replaying a lesson preserves existing schedules.

### Practice

Show the number of due objectives across both teams. Choose sessions of up to five, ten, or twenty due objectives, with no duplicate objective in a session. Prioritize oldest due time, then higher lapse count, then stable objective key. Do not introduce unlearned facts here.

If nothing is due, offer optional practice of learned objectives and a link to the next lesson. Do not pretend reviews are overdue or award retention upgrades for early rehearsal.

Opening the app may suggest due review but never blocks navigation or forces a test.

### Album

Show eight cards grouped by club. Locked cards show the subject and how to discover it. Acquired cards show tier, the learned fraction of their knowledge set, due review count, and a link to the related lesson or practice.

Unlock a cardboard card when its first associated lesson is completed. Player cards therefore unlock after their individual lessons; club cards unlock after their first club lessons. Keep discovery and retention indicators distinct.

### Settings

Provide sound and haptic toggles, a clear explanation of streaks and card tiers, source information, and a destructive reset with explicit confirmation. Notifications are deferred; initial retention is validated through voluntary use.

## Exercises and learning rules

### Exercise formats

1. **Multiple choice:** four distinct choices, shuffled, with one or more explicitly accepted choice IDs. A submission gets explanatory feedback.
2. **Relationship matching:** three clue cards and three fact cards, shuffled together and concealed until tapped. Store allowed pair edges rather than assuming matching display labels establish correctness. For this MVP author boards with unambiguous one-to-one pairings; validate that constraint before loading them. Correct pairs remain visible and disabled. Wrong pairs offer generic feedback and conceal again after a reading delay; VoiceOver uses explicit closure. This format supports acquisition and rehearsal, not tier upgrades.
3. **Recall:** a short-answer prompt, submitted before showing the answer. Accept authored aliases after trimming, case folding, whitespace normalization, and diacritic normalization. Use exact normalized comparison, without AI grading or fuzzy matching. Author prompts that have concise answers, such as a year, position, country, opponent, or player name. Include legitimate alternate spellings. A hint or reveal counts as unsuccessful independent recall.

Use recall for scheduled retention reviews. This makes card upgrades reflect more than recognition of visible options. Voice input, narrative answer grading, and timed challenges are deferred.

### Scheduling

Use a simple deterministic scheduler for v1, rather than claiming to implement a fully calibrated memory model. Store an independent review state for each objective, shared by all lessons that reference it.

After first learning, an objective is at stage 0 and due in 24 hours. A correct, unhinted recall on a due objective advances one stage:

| New stage | Next interval | Contribution to card tier |
| --- | --- | --- |
| 1 | 3 days | Bronze |
| 2 | 7 days | Silver |
| 3 | 14 days | Gold |
| 4 | 30 days | Diamond |

Further due successes at stage 4 keep the 30-day interval. Incorrect, hinted, or revealed answers reset current stage to 0 and schedule review in 24 hours. They receive corrective feedback and may be retried in the current session, but that retry cannot advance the stage. Early practice does not change the stage or due date.

Use elapsed-hour intervals from UTC timestamps, not midnight rounding. A clean sequence reaches stage 4 approximately 25 days after initial learning. These intervals are a transparent starting heuristic, to be tuned after observing her recall.

Store each objective's highest earned stage separately from its current stage. A card's tier is the minimum highest earned stage across its entire defined objective set. Until every objective has been learned and passed its first due recall, its tier remains cardboard. Tiers are permanent achievements; mistakes change current review needs, not earned tiers.

### Streaks

A completed lesson or practice session counts once toward that day's activity. A practice session requires answering at least one objective before reaching its result screen; merely opening a screen does not count. Replaying a lesson can maintain a streak but cannot advance retention stages.

Capture a home time zone at onboarding from the device's current zone and use it consistently to derive activity dates. Do not change it automatically during travel. Save UTC completion times and derived day keys.

Start with one available streak freeze. It can preserve continuity over one missed day but does not increase the number of actual practice days. Refill the freeze after seven distinct active days since the previous refill, with a maximum balance of one. Track active days and protected days separately. Longer gaps reset the active streak; longest streak and earned cards remain. Relaunches, offline sessions, and duplicate session saves must not double-count a day or consume a freeze twice.

## Native implementation and content contract

Use **SwiftUI**, a minimum deployment target of **iOS 17**, and a standard Xcode project with no third-party runtime dependencies for the first release. Xcode and Swift are installed in this workspace. Use XCTest for model and scheduling tests.

Keep presentation separate from plain Swift content, exercise, and review logic. Persist learner state as a versioned Codable JSON file in Application Support, using atomic writes and retaining the last working state. A corrupt save must produce a recovery message and preserve the damaged file rather than silently erase progress.

Bundle an English JSON content pack. No Firebase or AI keys are needed to run v1. Keep loading behind a content-repository interface so future remote delivery does not change the lesson engine.

### Pack records

- **Pack:** schema version, stable key, content version, language, entity/fact/objective/roadmap/exercise/card arrays, and source registry.
- **Entity:** stable internal UUID, human-readable key, type, display name, aliases, optional namespaced external references, and visual token.
- **Source:** stable key, URL, title, verification timestamp, and optional publication date.
- **Fact:** stable UUID/key, subject UUID, predicate, typed literal or entity reference, historical scope, source references, and evidence note.
- **Objective:** stable UUID/key, fact references, recall prompt, accepted answer strings, feedback, and revision. Each MVP objective tests one concise fact.
- **Roadmap:** club reference and ordered chapters with lesson references.
- **Lesson:** stable UUID/key, title, story screens, three objective references, and exercise references.
- **Exercise:** UUID/key, kind, objective references, prompt, feedback, and kind-specific choices, answer IDs, or allowed matching edges.
- **Card:** entity reference, ordered objective references, knowledge-set version, and associated lessons.

Treat illustrative JSON in the vision as a sketch; these records establish the v1 contract. Pin a UUID to its canonical record on first creation and never regenerate it on each import. Updates preserve IDs for unchanged meanings. A semantic fact correction creates a new objective revision and invalidates current mastery evidence for that revision while preserving past earned achievements.

Reject a pack with unknown schema version, broken references, duplicate keys/UUIDs, missing evidence, invalid answer IDs, empty recall aliases, or ambiguous matching boards. Display a usable content error instead of crashing. With only a bundled pack, invalid content is also a build-validation failure.

### Learner records

Persist selected club, home time zone, settings, lesson completion/resume state, session attempts, per-objective review stage/due date/lapses/highest earned stage, acquired cards, activity days, and freeze state. Session IDs make completion handling idempotent.

Replay choices and matching order may be randomized, but scoring and scheduling remain deterministic for a given attempt, timestamp, and state. Use injected clocks and random generators for tests.

### Seed usage

Extract Futbol11 data with a small offline importer without executing the reference bundle. Produce a dataset inventory and namespaced source mappings. Real Madrid appears in multiple datasets with different IDs; no explicit Xolos/Tijuana record was found in the inspected extracted JSON arrays.

Use the bundle to identify matching Madrid records and retain provenance. Verify every released teaching fact against its evidence. Build the Xolos starter records from official sources. Do not import thousands of unreviewed players into the visible album merely because they exist in the seed.

## Visual direction

Build an original football identity: warm cream surfaces, dark ink, green primary actions, generous type, a connected roadmap, and strong collectible-card typography. Use red/black accents for Xolos and white/gold accents for Madrid while preserving readable contrast.

Use original lettermark artwork for clubs and initials or jersey-style player cards in v1; do not depend on missing remote image paths. The leopard is a simple original illustration with welcome, encouragement, and celebration poses. Its UI name is “your leopard” until a character name is chosen.

Use short celebratory transitions and optional haptics. Support Dynamic Type, VoiceOver labels, sufficient tap targets, and Reduce Motion. Tier appearance must include text, not color alone. An album card must remain readable without animated or reflective effects.

## Delivery and acceptance

Implement in this order:

1. Create the native project, content models, importer inventory, verified pack, and content validator.
2. Build roadmap switching, lesson screens, multiple choice, and matching.
3. Add persisted attempts, recall practice, scheduling, album tiers, and streaks.
4. Integrate leopard artwork, accessibility, and complete the visual pass.
5. Validate on an available iPhone simulator and prepare device instructions. TestFlight distribution follows once signing and developer-account configuration are available.

The first playable version is accepted when she can finish a lesson for each club, collect the correct cards, quit and resume without losing progress, and complete the appropriate due review after a time shift in a test environment.

Required model checks cover pack/reference validation, accepted aliases, invalid matching pairs, due queue ordering, early practice not advancing stages, hinted answers, stage resets, diamond spacing, full-set card tiers, semantic revisions, duplicate completions, streak gaps and freezes, fixed-zone day boundaries, and save recovery.

Manual checks cover both complete roadmaps, club switching, lesson interruption, empty review state, locked/unlocked album cards, source visibility, offline launch, accessibility text sizes, VoiceOver, Reduce Motion, and returning after a missed day. Use a test clock for long-term behavior; never expose a mastery fast-forward control in the normal product.

Observe whether she recalls facts days later, finds sessions manageable, understands the album, and wants to return. Keep feedback local and conversational initially; analytics services are not necessary to learn from one user.
