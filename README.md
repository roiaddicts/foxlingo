# Foxlingo

An offline-first iPhone football-learning app with **68 club roadmaps**, **78 JSON-authored lessons**, **74 collectible cards**, a small leopard companion, spaced reviews, and forgiving streaks. Xolos and Real Madrid keep their deeper six-lesson courses; every other club has a three-fact introductory lesson.

The catalog covers the **2026/27 Champions League league phase**, **2026/27 Bundesliga**, and **Liga MX Apertura 2026**, verified as snapshots on October 8, 2026. The Games tab offers **football bingo**, a **club × country grid**, and **four classic Real Madrid lineup challenges**.

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
- Game validation ensures boards can be solved with distinct players. Undo and hints support recovery. A helped game counts toward the streak but does not advance recall stages or unlock cards.
- Free-text recall uses authored aliases after case, accent, and whitespace normalization. Game search selects a concrete player ID, then checks exact category intersections or squad membership and position; there are no embeddings or model calls.
- Learning progress is stored locally in Application Support. Writes are atomic; recovery preserves damaged saves and can restore the previous working save.
- Fact values distinguish entity relationships, numbers with units, text, and historical dates.
- Content updates must preserve identifiers and increment an objective's revision when its meaning changes.
- A review session keeps its starting deck stable while the due queue updates behind it.

## Checks

```sh
swift test
xcodebuild -project Foxlingo.xcodeproj -scheme Foxlingo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

The Swift package tests validate content, scoring, due review ordering, tier spacing, semantic revisions, streaks, time zones, and save recovery. The Xcode UI tests exercise lessons, matching, resume, the album, due review, club browsing, all three games, and incorrect-name recovery.

The UI-test launch flags (`-ui-testing`, `-reset-test-state`, and `-test-now`) exist only in Debug builds. They use a separate test save directory. The normal app has no time-travel or mastery bypass controls.

## Product documents

- [Vision](vision.md): the complete long-term product.
- [MVP specification](mvp.md): the initial learning loop and acceptance criteria.
- [Answer validation](docs/answer-validation.md): current grading and future typo/model options.

Expanded lessons were drafted with a cheaper subagent and checked against official sources and the app’s schema. Deeper courses for the added clubs, live statistics, Firebase publishing, match preparation, and a connection explorer remain future work. See [expansion notes](content/expansion-notes.md).

## Artwork

Original leopard artwork and its app icon are bundled in the asset catalog. Generation prompts and asset locations are recorded in [artwork notes](Foxlingo/Resources/ARTWORK.md).

Lesson matching now uses six shuffled, face-down cards. Mismatches remain visible briefly, then conceal; completed pairs and board order survive a restart. Hidden text is also concealed from accessibility labels. This is playful acquisition practice; it does not substitute for scheduled independent recall.

Game clues use offline club badges and country flags, including the player picker. Lesson identity answers reuse badges, faces, and flags; dates, statistics, and historical statements retain readable text. All visual clues expose their names to VoiceOver. Unmatched memory cards remain revealed for VoiceOver until the learner turns them over.

### Daily study plan

Learn suggests a short review across all learned clubs, an unfinished lesson, or the next lesson in the selected roadmap. Choose 5, 10, or 20 memories; the preference is saved locally. The total due queue stays visible while the session deck is bounded and frozen on launch. Recent tricky connections are distinct objectives with a failed or assisted most recent recall in the last week; later independent recall clears them. Optional rehearsal rotates toward least recently attempted knowledge. Corrected content starts a new learning window and ignores attempts from its previous revision.
