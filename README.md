# Foxlingo

An offline-first iPhone football-learning app with **68 club roadmaps**, **six player starters**, **78 JSON-authored lessons**, **74 collectible cards**, a small leopard companion, spaced reviews, and forgiving streaks. Xolos and Real Madrid keep their deeper six-lesson courses; every other club has a three-fact introductory lesson.

The catalog covers the **2026/27 Champions League league phase**, **2026/27 Bundesliga**, and **Liga MX Apertura 2026**, verified as snapshots on October 8, 2026. The Games tab offers **football bingo**, a **club × country grid**, **four classic Real Madrid lineup challenges**, and **Who am I?** with six sourced featured players.

## Run on an iPhone simulator

1. Open `Foxlingo.xcodeproj` in Xcode.
2. Select the **Foxlingo** scheme and an installed iPhone simulator.
3. Press Run. No Firebase account, API key, or network connection is required.

For a physical iPhone, choose your Apple development team under **Signing & Capabilities**, connect your device, and run. TestFlight needs Apple Developer distribution signing; no upload is part of this repository's local MVP build.

Minimum iOS: **17.0**. The project uses SwiftUI and Apple's frameworks, with no third-party runtime dependencies.

## Content and progress

- `Foxlingo/Resources/starter-en.json` is the bundled, validated English curriculum.
- `scripts/build_content.py` rebuilds it with stable UUIDs. Facts retain official source references and historical scope.
- `scripts/inventory_seeds.py` inventories embedded Futbol11 JSON without executing the source bundle. The report is `ref/seed-inventory.json`.
- The initial 36 favorite-club objective slots share one Ramos equalizer objective. The expanded curriculum totals **233 unique review memories**.
- `content/club-expansion.json` contains sourced club lesson drafts; `scripts/merge_expansion.py` compiles them into the starter pack without replacing existing progress IDs.
- `Foxlingo/Resources/games-en.json` contains 2,300 namespaced player records, category relationships, and season squad positions. `scripts/build_games.py` extracts them deterministically.
- `content/club-artwork.json` and `Foxlingo/Resources/artwork-manifest.json` record badge and portrait provenance. Selected artwork is bundled; other seed portraits load over HTTPS with initials as an offline fallback.
- Club, player, and country answers in authored lessons use cached badges, portraits, and flags, including all distractors. Game category clues are also bundled, and classic lineup boards show their club badge. Text facts retain their meaning and visual controls keep spoken names for accessibility.
- `content/mystery-rounds.json` configures Who am I? using canonical player and fact UUIDs. Roles, scoped records and unique final name initials reveal progressively; plausible or unknown guesses reveal more evidence without a false error. Portraits/sources stay hidden until identification. The order shuffles on normal entry/replay.
- Game validation ensures boards can be solved with distinct players. Undo and hints support recovery. A helped game counts toward the streak but does not advance recall stages or unlock cards.
- Free-text recall uses authored aliases after case, accent, and whitespace normalization. Game search selects a concrete player ID, then checks exact category intersections or squad membership and position; there are no embeddings or model calls.
- Learning progress is stored locally in Application Support. Writes are atomic; recovery preserves damaged saves and can restore the previous working save.
- Fact values distinguish entity relationships, numbers with units, text, and historical dates.
- Settings → Lesson updates imports a newer full curriculum JSON through Files or a supplied HTTPS manifest. Updates are validated and cached separately from progress, then activate after quitting Foxlingo from the app switcher and reopening. Compatible previous versions can be restored; earned history remains. No feed is published by default.
- Content updates must preserve identifiers and increment an objective's revision when its meaning changes. See [content update authoring and recovery](docs/content-updates.md) for the manifest format, bounds, migration rules, and local manifest tool.
- A review session keeps its starting deck stable while the due queue updates behind it.

## Checks

```sh
swift test
xcodebuild -project Foxlingo.xcodeproj -scheme Foxlingo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

The Swift package tests validate content, scoring, due review ordering, tier spacing, semantic revisions, streaks, time zones, and save recovery. The Xcode UI tests exercise lessons, matching, resume, the album, due review, club browsing, all three games, incorrect-name recovery, daily plans, and club comparison study packs.

The UI-test launch flags (`-ui-testing`, `-reset-test-state`, and `-test-now`) exist only in Debug builds. They use a separate test save directory. The normal app has no time-travel or mastery bypass controls.

## Product documents

- [Vision](vision.md): the complete long-term product.
- [MVP specification](mvp.md): the initial learning loop and acceptance criteria.
- [Answer validation](docs/answer-validation.md): current grading and future typo/model options.

Expanded lessons were drafted with a cheaper subagent and checked against official sources and the app’s schema. Deeper courses for the added clubs, live statistics, Firebase publishing and live fixture briefings remain future work. See [expansion notes](content/expansion-notes.md).

## Artwork

Original leopard artwork and its app icon are bundled in the asset catalog. Generation prompts and asset locations are recorded in [artwork notes](Foxlingo/Resources/ARTWORK.md).

Lesson matching now uses six shuffled, face-down cards. Mismatches remain visible briefly, then conceal; completed pairs and board order survive a restart. Hidden text is also concealed from accessibility labels. This is playful acquisition practice; it does not substitute for scheduled independent recall.

Game clues use offline club badges and country flags, including the player picker. Lesson identity answers reuse badges, faces, and flags; dates, statistics, and historical statements retain readable text. All visual clues expose their names to VoiceOver. Unmatched memory cards remain revealed for VoiceOver until the learner turns them over.

### Daily study plan

Learn suggests a short review across all learned clubs, an unfinished lesson, or the next lesson in the selected roadmap. Choose 5, 10, or 20 memories; the preference is saved locally. The total due queue stays visible while the session deck is bounded and frozen on launch. Recent tricky connections are distinct objectives with a failed or assisted most recent recall in the last week; later independent recall clears them. Optional rehearsal rotates toward least recently attempted knowledge. Corrected content starts a new learning window and ignores attempts from its previous revision.

### Coverage preparation

Open **Practice → Prepare with two clubs**. Choose two distinct canonical clubs without changing the main roadmap. The pack gathers their supported stories and fact scopes with source links. It is a historical comparison, not an upcoming fixture or a current squad briefing. New facts link to lessons; recall includes only learned objectives at the current revision. Short decks rotate while balancing the selected clubs and deduplicating shared objectives. Facts opened during this preparation visit count as assisted rehearsal: they cannot earn independent recall credit or change a due schedule. Other due answers update normally; the result reports how many scheduled reviews actually changed. Answers save immediately, but leaving an unfinished recall session starts a fresh rotating deck next time.

### Album collections

The album starts with Xolos and Real Madrid. Switch to a competition or all clubs, search club/player names, or show discovered cards only. Collection totals stay fixed while filtering, and shared cards count once. Each card states its depth: a three-connection introduction, club foundations, or a player story.

Card details separate introduced connections, remaining lessons, refreshed facts, and current recall stage. Earned tiers remain visible when a knowledge set expands or a fact changes. Saved achievements record their knowledge-set version where known; older saves with uncertain provenance retain their tier without inventing a version. Opening card context or a source marks that connection as assisted for the card's next practice session, preserving its due schedule.

### Connection explorer

Open **Album → Explore connections**, or explore from a card. Tap nearby badges, faces, or moment nodes to move through the map. Choose two subjects to find the fewest supported links, then inspect each step's original claim, historical scope, evidence, and source links. At accessibility text sizes, a readable list replaces the spatial map.

The default filter uses club history and events. Country and place relationships can be included explicitly. The graph combines entity-valued facts with curated, fact-backed relationships in `content/graph-connections.json`; the build script compiles both into the canonical starter JSON. Country answers share canonical country UUIDs without changing taught answers or review revisions. The 2014 final, Ramos's equalizer, and the two-leg 2012 final are separate occurrence records. Self-references remain facts rather than graph edges; literal statistics remain scoped details. Traversing an edge backward preserves the original claim. Shared club history never implies teammates.

Graph coverage is limited to this library. A missing path means no supported path under the selected filters, not that two subjects have no real-world connection. Structural validation rejects broken references or missing provenance; curated claims still need factual review. Explorer visits earn no XP, streak activity, or recall credit. Entering the explorer from a card conservatively marks its whole knowledge set assisted for that card visit. Wider match/goal histories and richer league connections remain future content work.

### Player roadmaps

Open Learn's roadmap chooser and select **Players**, or open a player roadmap from its album card. Riascos, Arce, Saucedo, Ronaldo, Ramos, and Casillas each have a three-memory starter and a separately counted optional club-history chapter. These starters organize the existing sourced curriculum; they are not full career courses or new statistics datasets. The definitions live in `content/player-roadmaps.json` and compile into the same JSON pack.

Player selection persists while preserving the preferred club. Required completion excludes optional chapters; daily plans stop recommending new player lessons when the starter is finished. An intentionally interrupted optional lesson can still resume. Shared lesson UUIDs mean club and player paths share completion, saved sessions, cards, and one coordinated recall queue. For Ramos, the starter and optional final together introduce five unique memories rather than six. Club browsers, album competition collections, and comparison packs continue using only club roadmaps.

Roadmaps may specify a canonical `subjectID`; older club-only JSON falls back to `clubID`. A contextual `clubID` remains required, and a club subject must match it. Chapters may specify `isOptional` and explanatory `note` text. Opening a linked player roadmap from a card counts as preview for that card visit's practice.
