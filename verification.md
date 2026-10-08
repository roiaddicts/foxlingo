# Foxlingo verification

Verified October 8, 2026, using Xcode 26.3 and an iPhone 17 Pro simulator running iOS 26.3.1.

## Result

**76 core tests pass.** The initial six end-to-end scenarios and subsequent focused simulator checks are recorded below. The original full regression and later feature checks are separate runs, rather than a fresh run of every UI test after every change. Debug and optimized Release builds have passed; the Release executable excludes the Debug-only test launch flags.

## Requirements and evidence

| Requirement | Evidence |
| --- | --- |
| 68 club roadmaps, 82 lessons | Content checks confirm 36 Champions League, 18 Bundesliga, 18 Liga MX memberships; full simulator walkthrough completes the 12 favorite-club lessons and sample Atlas/Paderborn starters |
| JSON-authored content and 74 album cards | Pack validation covers 245 objectives; favorite-club walkthrough unlocks its original eight cards |
| Matching and multiple choice | Correct pairs, wrong pairs, wrong choices and retries exercised in simulator |
| Independent recall | Typed correct answers scored 3/3; answer reveals tested separately |
| Shared facts and review queue | Core tests verify one shared Ramos objective, ordering and bounded queues; integration verifies due review |
| Stable active review sessions | Full due session passes while its underlying due queue changes |
| Spacing and diamond criteria | Tests verify the 25-day clean sequence, all-objective tier requirements, and permanent diamond after a lapse |
| Streaks and protection | Tests cover duplicate days, one-day freezes, long gaps, refills, home-zone boundaries and DST |
| Resume and saved progress | Simulator quit/relaunch resumes the second story page; persistence round-trip and resume-state tests pass |
| Corrupt-save recovery | Tests preserve damaged files, restore backup with a notice, and reject semantically invalid state |
| Historical scope and sources | Typed fact validation and source-reference checks; in-app source screen verified |
| Local operation | Lessons, game relationships, badges and selected portraits are bundled; additional seed portraits use HTTPS with offline initials fallback; progress uses local atomic files; scoring has no network-service dependency |
| Settings and large text | Sound control exercised; accessibility-size welcome and lesson navigation pass |
| Leopard, badges and faces | Small cub and matching icon; all 68 badges and featured player portraits bundled; game screenshots inspected |
| Bingo, grid and classic lineups | Solvability, distinct identities, club × country intersections, squad positions, wrong-answer recovery and all three completed games tested |
| Club browser | Search selects Atlas and Paderborn and completes their starters; full-row hit area repaired and verified |
| Device run instructions | README explains simulator use, physical-device development signing and later TestFlight requirements |

The large-text lesson remains scrollable at the largest tested accessibility size. Standard SwiftUI controls expose accessibility labels; decorative club marks are hidden and the leopard has a descriptive label. Reduce Motion disables mascot rotation/scale and explicit lesson/matching animations in the view code.

A regression found that short club names left untappable empty space in their row. The whole-row hit area and explicit sheet closure are fixed. The focused Atlas/Paderborn test passes after that repair; unchanged scenarios passed in the full regression and navigation/game reruns. Expanded club courses are introductory lessons, rather than full multi-chapter player histories.

## Inspectable results

- [Club selection repair summary](output/qa/v2/club-fix-summary.json)
- [Expanded core tests](output/qa/v2/core-tests.log)
- [Full regression log](output/qa/v2/regression.log)
- [Club repair log](output/qa/v2/club-fix.log)
- [Navigation and game rerun log](output/qa/v2/navigation-games.log)
- [Updated release build](output/qa/v2/release-build.log)

Earlier MVP evidence:

- [Simulator test summary](output/qa/test-summary.json)
- [Core test log](output/qa/core-tests.log)
- [UI test log](output/qa/ui-tests.log)
- [Release build log](output/qa/release-build.log)
- [Roadmap screenshot](output/qa/roadmap.png)
- [Album screenshot](output/qa/album.png)
- [Largest tested text size](output/qa/large-text.png)

QA exports are local generated artifacts under the ignored `output/` directory. Regenerate them from an Xcode test result bundle if sharing a fresh checkout.

## Delivery boundary

This is a locally runnable native MVP, not an App Store or TestFlight publication. Physical-device installation needs the user's Apple development signing configuration. Live data, automated AI publishing, Firebase, live fixture briefings, and wider graph coverage remain the later work described in the vision.

## Visual clues and memory polish

- 37 core tests pass, including reversed memory pairs, concealed mismatch turns, saved pairs, malformed board rejection, and semantic visual typing (cities cannot become club badges).
- Real simulator flows pass for memory resume and all three football games. Large text welcome/lesson also passes after the semantic answer fix.
- All 9 club categories have cached badges. All 4 country categories use cached flag images; 22 flag images are bundled for country answers. Visual clues retain spoken country/club names. Player picker shows both grid clues.
- Choice answers only use artwork when all four options have supported visuals of the same semantic type. Historical, numeric, city, and nickname facts retain their meaning as text.
- VoiceOver holds unmatched cards until explicit dismissal; ordinary play turns them over after 1.8 seconds. This behavior is implemented and reviewed; a live VoiceOver session has not been exercised.
- Replayed lessons report their actual next recall date, preserving existing schedules. Press animations respect Reduce Motion.

## Daily study plan

44 core tests pass, including a 34-item backlog split into a five-question batch, cross-club resume, completed roadmaps, corrected-content history, bounded recent mistakes, rotating rehearsal, and old-save compatibility. The real simulator daily-plan flow passes: interrupted lesson resumes, six due objectives become a five-question session, the remaining queue updates, and the five-question preference persists into the next day's backlog. Independent recall, sources, and settings regression also passes. Picker persistence is verified through the resulting deck, rather than relying on its accessibility value.

## Offline coverage study packs

50 core tests pass. Coverage cases verify distinct canonical clubs, shared-objective deduplication, readable scope/source references, current-revision eligibility, rotating balanced sessions, and due-versus-early scheduling. Three real simulator coverage flows pass after the final fixes: a new learner reads sources and opens a lesson; club selection excludes the other chosen club and preserves Learn's selection; mixed due/early practice reports only three scheduled changes; correctly typed previewed answers earn zero independent successes and leave all three due objectives ready. The updated large-text welcome/lesson flow also passes. Coverage headers and lesson actions have separate accessibility controls, avoiding DisclosureGroup's inherited identifiers.

The study pack deliberately covers available historical course content. It does not supply current squads, live statistics, fixture scheduling, or a complete head-to-head briefing. Preview assistance persists for this preparation visit and its copied recall deck; it is not a global record of every answer seen anywhere in the app.

## Album collections and achievements

58 core tests pass, including collection membership through lessons, shared-card deduplication and search through either club, fixed totals while filtering, partial knowledge coverage, revised-fact refresh, additive knowledge sets, and older-save migration. Earned tiers survive revised or expanded sets. When an old save cannot prove the version of an achievement, that version remains unknown until demonstrated at the active version.

Simulator checks pass for collection filters, search, partial Xolos coverage, and assisted card practice. Opening all three identity contexts, then typing all three answers correctly, produces zero independent successes and leaves the three scheduled reviews due. These checks use separate Debug test saves and preserve ordinary learner progress.

The largest accessibility text size keeps album cards in one column and card details scrollable. The compact comparison screen also passes its lesson/recall/club-selection regression. Exported screenshots were inspected for the standard card detail, comparison screen, and large-text card. The optimized Release build passes with these changes.

## Connection explorer

68 core tests pass. Ten graph tests cover identity paths, unknown/disconnected subjects, backward traversal without reversed claims, self-reference exclusion, literal-statistic boundaries, relationship filters, canonical country targets, distinct match/goal/tie occurrences, parallel scoped claims, stable paths after record reordering, duplicate names, malformed relationship rejection, and older packs without authored relationships.

The library contains 100 canonical subjects and 57 supported graph edges: 46 entity-valued facts and 11 curated relationships backed by existing sourced facts. Source references and required provenance are structurally validated; this does not automatically establish the truth of future authored claims.

Four focused simulator scenarios pass across the final runs: sourced path/filter/evidence navigation, large-text exploration entered from a card, card-context recall protection, and card-explorer recall protection. The explorer regression finds the three-edge Ramos → equalizer → 2014 final → Ronaldo event path, handles unsupported paths and zero-hop identity, and exposes sources. Opening the explorer from a learned card then answering all three due questions correctly earns zero independent successes and leaves all three reviews due. One initial UI regression had an incorrect text-field identifier; the corrected test passes.

Normal map/path screenshots and the largest-text list were inspected. Long map labels wrap within their nodes; Di Stéfano's seed portrait is cached. At accessibility sizes, the heading and labeled search control occupy separate rows. The final optimized Release build passes. This graph is a sourced library explorer, not comprehensive football history or proof of teammate relationships.

## Player starters and shared roadmap progress

76 core tests pass. Eight roadmap tests cover six canonical player starters, required versus optional progress, shared objective deduplication, completion across both club/player paths, unchanged recall dates on replay, shared resumed sessions, persisted selection, older saves/packs, retired roadmap fallback, unchanged club-only coverage/album membership, and invalid subject/context references.

Five focused simulator scenarios pass across the feature runs: player selection/restart/shared progress, album entry and explicit selection, large-text player roadmap and lesson, historical club comparison regression, and large-text club welcome/lesson regression. Completing Ramos's player lesson gives one of one required lessons complete while optional context remains zero of one. Switching to Madrid shows the same completed lesson in its six-lesson course. Completing the optional final leaves required player progress complete and produces exactly five due memories the next day. Player selection survives relaunch; opening a roadmap from the album requires an explicit action to select it for Learn.

Standard player progress and the largest-text player header/lesson screenshots were inspected. At accessibility sizes, names use the full width and the roadmap switch has its own labeled row. The optimized Release build passes. The six starters reuse existing sourced lessons and clearly separate optional team history; full player careers, additional player lessons, national-team timelines, and wider dated statistics remain later content work.

## Visual clues and answers

Content version 5 resolves all authored club/player answer choices, including distractors, to canonical artwork aliases. Juventus and Gareth Bale are supporting visual subjects with no new lessons, cards, or career claims. Ecuador completes the authored nationality flags. All 149 selected image assets are cached; other game search portraits can still use HTTPS or fall back to initials. Classic Madrid lineup boards now include the club badge.

77 core tests pass, including a coverage check that every semantically visual lesson answer and every game category has bundled artwork. The simulator tests for all three games and hidden-card matching/mismatch/resume pass. The Release build succeeds. Spoken answer names remain available; city, nickname, date, and score answers retain text instead of borrowing an unrelated badge.

## Versioned lesson delivery

94 core tests pass. Delivery cases cover HTTPS manifest metadata and raw-byte checksums, unknown response lengths, oversized manifest streams and declared curriculum lengths, unsuccessful/HTTP-final responses, cancelled and bounded Files reads, same-family compatibility, newer-pending precedence, source-only edits, objective revision gates, raw key/UUID and graph identity preservation, conflicting answer keys, compatible versus changed/unknown resumes, archived learner saves, permanent tiers through rollback, valid-JSON cache corruption, older bundled-cache migration, and unwritable cache fallback. Tests use URLProtocol fixtures, not a deployed publishing service; redirect rejection is implemented in the production session delegate but a real redirect server was not exercised.

The complete simulator update flow passes: a partly matched lesson remains on version 5 while version 6 waits; after termination/relaunch its changed story restarts, version 6 is installed, and a confirmed restore returns to version 5 on another launch. The installed version and earned-card preservation notice are asserted. The normal Files picker itself was not automated; its bounded background read helper is tested. Staged and installed screen captures were inspected.

Progress and curriculum storage are separate. The manifest helper was run against bundled bytes and creates a local manifest without uploading files. The app does not include a default published feed, provider credentials, a game-pack update feed, cloud progress synchronization, or automatic truth verification. Authoring and recovery rules are recorded in `docs/content-updates.md`.

Two further simulator scenarios pass: large-text welcome/lesson regression and onboarding a valid updated library without either favorite club roadmap. The latter selects a remaining club and opens its roadmap. The final optimized Release build succeeds; Debug fixture flags are excluded from Release.

## Progressive visual player clues

104 core tests pass. Ten mystery-specific cases cover the six sourced subjects and unique final initials, numeric units/scopes, plausible forward/goalkeeper guesses, evidence-backed role contradictions, unknown statistics, solved-round locking, unsafe/retired clue fallback, embedded scope spoilers, retirement of one valid player course leaving five other rounds playable, duplicate identities, and activity-only completion deduplication.

Three focused simulator scenarios pass across the final runs: the new mystery board’s plausible/wrong guesses, hidden identity, supporting sources, all six identifications and replay; its largest accessibility text clue/player picker; and all three classic games with exact-ID answer selection and new board animations. The final mystery flow explicitly asserts the spoken Club Tijuana context on Saucedo’s scoped statistic. Standard and largest-text screenshots were inspected. The optimized Release build passes. Reduce Motion is respected by animation guards; the simulator’s system Reduce Motion setting was not toggled in these runs.

The current mystery player pool is deliberately bounded to six favorite-course subjects. Names/portraits and evidence are concealed until resolution; the answer picker shows the whole available portrait roster. Normal boards shuffle player order; UI fixtures keep deterministic order. Completing a board records streak activity without changing review memories, acquired cards or mastery tiers. Mystery definitions are bundled JSON, while their referenced facts come from the active validated lesson pack. Unfinished boards now have local resumes, described below; distributing new game packs remains future work. See `docs/mystery-game.md`.

## Persistent visual game boards

113 core tests pass. Nine resume cases cover all three classic boards, bingo offers, assistance and Undo history, stable lineup IDs after reordering, visual-only edits, grid orientation changes, individually valid dead ends recoverable by Undo, malformed snapshots isolated from learner progress, older saves, mystery order/reveals/solved rounds, relevant versus unrelated fact changes, source wording edits, and once-only completion with the draft removed in the same save.

Saved boards use content fingerprints rather than the whole curriculum version. A relevant layout, membership or clue change retires only that game's incompatible draft with an explanation. Artwork and source wording edits preserve progress. Completion uses the original session ID and removes its draft alongside activity credit. Save failures remain visible through the app's progress alert.

Lineup player pickers now keep the cached Madrid badge, historical squad title and season scope visible before typing; the header exposes combined spoken context. Bingo and grid categories continue using cached flags and badges, with spoken names. A legal bingo dead end cannot accidentally open an unrelated lineup picker; Undo remains available.

Three focused simulator scenarios pass across the final runs: classic grid/lineup/bingo relaunches with restart cancellation and preservation of the other board; mystery revealed-clue restoration, cancellation, all six identifications and a solved final player restored before Finish; and the three classic games' wrong-name recovery, lineup context header and completion. Initial restart tests exposed a missing cancel control in the confirmation popover; explicit alerts fixed it and both resume scenarios passed again. Completed mystery drafts are absent on the following launch. Standard resumed-board and solved-player captures were exported for inspection. The final optimized Release build passes. Largest-text resume layouts and the system Reduce Motion setting were not separately exercised in this milestone.

## Standalone 4×4 memory game

The learning path now finishes after two story pages and four choice questions. Lessons saved at their former matching step expose Finish directly, retaining earlier attempts and progress. Legacy matching JSON remains readable for content-update and save compatibility, but the learning path no longer renders or scores a matching board.

116 core tests pass. Three new cases check eight unique pictured subjects and sixteen cards, four names/four sourced numeric facts, subject-to-stat ownership and provenance, ambiguity rejection, all eight match relationships, saved order/turns/found pairs, corrupt/completed-board rejection, once-only activity credit and no mastery changes. Existing mismatch/third-card guards remain covered by MemoryMatch tests.

Cards use an interpolated 3D flip and a spring lift on touch or pointer hover; Reduce Motion disables movement. Hidden content is excluded from the visual card's accessibility tree and replaced with a single named button representation. VoiceOver keeps mismatches revealed until explicit concealment. Matched pairs, order and turn counts persist; transient unmatched reveals close when returning. Stat scopes appear beneath the board and are included in spoken answers; completion exposes provenance links. New memory definitions are bundled JSON referencing active canonical facts.

Three focused simulator scenarios pass across the feature runs: lesson resume/acquisition/album/due-recall without matching; the standalone board's hidden accessible labels, mismatches, blocked third selection, all eight pairs, restart cancellation, saved pairs and replay; and the four-column board at the largest accessibility text size. Initial card tests exposed nested accessibility elements from the animated face; explicit button representations fixed the labels and concealed content. Standard/large-text captures were inspected, including an in-flight 3D flip. A long stat label was refined into a prominent number and a separate two-line label. Pointer hover and the simulator's system Reduce Motion setting were not manually exercised.

The final standalone board regression passes again after the stat-label refinement; its settled completed-board screenshot was inspected. The final optimized Release build succeeds.

## Bundled sound assets and event feedback

117 core tests pass, including byte-identical original/bundled copies for every sound catalog asset, bounded cue profiles and the requested event hierarchy: small wins/setbacks within mini games, success for correct lesson/recall questions, and level-up for completion/unlocks. All eight MP3s were inspected with the platform audio metadata tool (durations 1.2–4.8 seconds).

Two focused simulator scenarios pass across the feature runs. The preview/mute flow creates and starts an AVAudioPlayer for each of the eight bundled resources, disables previews and clears feedback when Sound is switched off, then confirms the mute preference after relaunch. Its first run needed a test scroll correction to reach the toggle; the corrected flow passes. The complete memory-board mismatch/match/resume/replay regression also passes with sounds enabled. These assertions establish successful local loading/playback startup, not subjective speaker loudness. The optimized Release build succeeds.

Settings now has Assets → Sounds with full-clip previews. Live feedback uses modest gains and bounded, faded interface/retry/level-up cues. The player replaces prior sounds, stops on leaving the foreground, and honors the persisted Sound setting independently of haptics. AVAudioSession uses the ambient category with other-audio mixing; physical Silent Mode, interruption behavior and perceived loudness were not manually checked on an iPhone. Original files are preserved and all eight are bundled offline; game-over/sad-trumpet remain available in the asset library for later game modes.

## Fox navy visual identity

The shared palette and AccentColor asset use exact sRGB `#002D56` (0,45,86). Main controls, game backs, roadmap progress, navigation tint and headings now share that brand color. Light surfaces use `#F4F7FB`; muted text uses `#56677A`. Computed contrast is 13.91:1 for white on navy, 12.95:1 for navy on the light surface and 5.40:1 for muted text on that surface. Club/flag artwork, gold tier accents and error colors retain their semantic roles.

Two existing simulator scenarios pass: large-text welcome/lesson navigation and the memory board's concealment, matches, relaunch, cancellation, completion and replay. Their navy/light screenshots were inspected. No new learning or grading logic was changed. The leopard's generated scarf edit retains a genuinely transparent alpha channel; its golden character and pose were inspected. The icon's prepared foreground was packaged on a native exact brand fill, with an opaque 1024×1024 RGB result and RGB (0,45,86) corner checks. Asset edit prompts and source/output paths are recorded in `Foxlingo/Resources/ARTWORK.md`.

The final optimized Release build passes with the regenerated mascot and packaged icon.

## Icon bottom-edge repair

The regenerated icon foreground extends the shoulders and cream belly through the bottom edge. The finished icon was visually inspected: no navy strip remains below the torso. Read-only pixel checks confirm an opaque 1024×1024 RGB PNG, exact (0,45,86) top corners, and uninterrupted mascot pixels along the lower center through the last row. The optimized iOS Simulator Release build passes. No application logic changed.

## Illustrated football timelines

Two JSON-authored boards rehearse existing sourced chronology: three Xolos milestones and four Real Madrid milestones. Canonical year/date facts provide ordering; the game does not infer dates from text captions. Club mismatch, absent player club context, non-year numbers, impossible calendar dates, duplicate events/facts and tied years are rejected. Retired facts leave unaffected rounds available. The starter shuffle never begins solved. Dates/source context remain concealed until correct completion or an explicitly assisted reveal.

124 core tests pass, including seven timeline tests covering chronology, safe move bounds, wrong-order save restoration, session identity, once-only activity credit, content compatibility, and preservation of learning state. A subsequent focused seven-test run also passes after normalizing authored event order in the fingerprint. Artwork/source-title changes and event-array reordering preserve a board; changed date values invalidate it. Timeline completion leaves recall stages, due dates and card acquisition untouched.

Two focused iPhone simulator scenarios pass: wrong checks, concealed dates, reorder/relaunch restoration, restart cancellation, independent completion, source context, club switching, assisted-reveal cancellation, replay and the largest accessibility text size. Exported standard and large-text screenshots were inspected. Decorative step numerals were given a fixed size after inspection to prevent overflow, while event text remains scalable. Move controls expose current positions and announce their new position after moving. Reorder springs and date-reveal transitions honor Reduce Motion; physical VoiceOver and system Reduce Motion were not manually exercised.

The final optimized Release build succeeds, including the decorative numeral and disabled-arrow refinements. Authored and bundled timeline JSON are byte-identical. The final simulator build is installed with ordinary learner progress preserved.

## Deeper favourite stories, coverage rehearsal and animated streak

Content version 6 adds four official-source lessons: Casillas’s honours, Ramos’s Madrid trophies, Xolos’s professional/second-tier/top-flight beginnings, and Madrid’s 2018/2022/2024 European Cup sequence. The pack now has 82 lessons and 245 unique objectives; Xolos has seven required lessons, Madrid nine, and Ramos/Casillas two each. All pre-existing entities, sources, facts, objectives, exercises and lessons compare unchanged against the previous committed pack. Expanded cards preserve old objective sets and increment knowledgeVersion to 2. Six official pages were rechecked on October 8, 2026; authoring and source limitations are recorded in `content/favorites-enrichment-notes.md`.

Six JSON-authored rehearsals require an original written explanation or explicit confirmation of an aloud explanation before revealing three sourced anchors. Completion needs three explicit reflections, with all missed permitted. Notes preserve the original and optional revision; history snapshots include prompts, labels and reflections. Aloud rehearsal records no audio and does not use model grading. Revealed drafts and saved history apply preview protection to recall in the originating study visit.

131 core tests pass. The seven rehearsal tests cover save restoration, required reflections, once-only streak activity without recall/card changes, semantic revision, retired stories, malformed optional drafts, and preventing an archived session from erasing a new draft. Updated roadmap/card tests cover expanded knowledge, shared progress and content version changes. Authored and bundled rehearsal prompts are byte-identical.

The streak uses a native Canvas flame with three layered paths and continuous tip movement at up to 24 redraws per second. Its loop pauses when hidden or inactive; Reduce Motion and Low Power Mode use a static flame, and zero active days uses a muted silhouette. These fallback conditions were inspected in code; physical-device power consumption and manual Low Power/Reduce Motion switching have not been measured. The optimized Release build succeeds.

Five focused simulator scenarios pass across the two runs: written-note restore and saved reflections; aloud rehearsal at the largest text size; reading saved history before due recall; freshly revealed anchors before due recall; and expanded Ramos player/club shared progress. Both preview scenarios yield zero independent successes and preserve all three due memories. A container accessibility identifier initially hid the individual reflection identifiers; removing it restored independent controls. Final written, history and largest-text checks pass, and their screenshots were visually inspected. The streak remains a compact flame beside the count, and saved notes display the original explanation and each reflection.

## Independent competition foundations

Content version 7 adds three independent courses: UEFA Champions League, Bundesliga and Liga MX. Nine lessons introduce 27 memories and three cards, taking the pack to 91 lessons, 272 unique objectives and 77 cards. Each course has three required chapters and one optional existing club story. All pre-existing entities, facts, objectives, lessons, exercises, roadmaps and cards compare equal to the prior committed records; their relative ordering is preserved. The compiler reproduces identical bytes, and the optimized release embeds those final bytes.

Competition roadmaps have a canonical competition subject and no false contextual club. Selecting one preserves the preferred club. Club comparison remains club-only. Optional club stories reuse existing lesson/objective IDs and do not count toward competition foundations or its card. Album collections expose the new cards through All subjects, Competitions and the relevant named league; named club collections show their explicit membership season.

137 core tests pass, including six competition regressions for independent ownership, save restoration, optional context, once-only memories, strict club selection, album scope, malformed JSON and typed answer equivalents. Content update/download fixtures derive their versions from the bundled pack. Legacy club JSON still loads; older binaries require an updated app before accepting competition packs.

Seven focused simulator scenarios pass across the final runs: full Liga MX learning/relaunch/card progress; cross-type search and strict club-only comparison; largest-text competition header; largest-text player selection/learning; album filtering/search/scoped knowledge; next-launch curriculum activation and rollback; and onboarding without favorite club paths. Old album expectations were corrected for the already-expanded Xolos card. The final album run checks the membership season label explicitly. Competition, Bundesliga emblem and large-text screenshots were exported and inspected. Only decorative subject-header eyebrows cap their visual scaling; titles, body text, progress and controls retain full accessibility scaling.

Read-only adversarial product/design reviews caught alias gaps and the oversized header eyebrow; both were repaired and verified. The source audit removed unverifiable FMF archive claims, separated competition origins from later branding, and scoped format/record facts to their historical editions. Source classifications, retained model limitations and logo attribution are recorded in `content/competition-notes.md` and `content/competition-artwork.json`.

The final optimized Release build succeeds. Physical-device accessibility and power behavior were not manually exercised in this iteration. The release is installed in the simulator without resetting ordinary learner data.

## My roadmaps

Clubs, players and competitions can be bookmarked independently of the selected Learn path. The chooser shows saved subjects, their badges/portraits and required lesson progress above the catalog. Saving uses press feedback, a short icon fade and optional selection haptics; Reduce Motion disables the fade. Removing a bookmark preserves active selection, unfinished lessons, learned facts, cards and global review. This preference is local, with no account synchronization.

Legacy saves initialize Xolos and Madrid once, using stable canonical IDs even if a favorite is absent from the active pack. Explicit empty lists remain empty. IDs are deduplicated in insertion order and unavailable paths remain saved for rollback. The daily plan prioritizes a selected-path resume, then selected required lessons, then required learning from saved paths in saved order. Optional work resumes automatically only in the selected path. Recommendations carry their originating roadmap ID, so shared lessons name the actual path. Unrelated unsaved interruptions remain accessible manually.

142 core tests pass. Five saved-roadmap regressions cover legacy/empty migration, missing favorites on first migration, ordered deduplication and retirement/rollback, selection versus saving, preserved progress/global due recall, saved recommendation order and shared lesson ownership. Existing completion tests explicitly isolate paths without saved alternatives; the cross-club resume test now verifies selected-path priority before saved fallback.

Three focused simulator scenarios pass: save/select/remove/relaunch and explicit empty persistence; largest-text bookmark controls; and expanded player/club shared progress with a named saved-path suggestion. Screenshot inspection found crowded large-text names; stacking badges above full-width text and keeping decorative bookmark/check icons compact repaired the layout. The final largest-text rerun passes, and standard/final large-text screenshots were inspected. The optimized Release build succeeds and is installed without resetting ordinary learner data. Physical-device VoiceOver and Reduce Motion were not manually exercised.

Adversarial product and design reviews found the missing-favorite migration issue, which was repaired and tested. Deeper Cristiano, Arce and Riascos authoring remains in separate draft files for a later curriculum update; those drafts are not included in the version 7 bundled pack.

## Player career foundations

Content version 8 adds three lessons and nine memories for Cristiano Ronaldo, Fernando Arce and Duvier Riascos. The pack now has 94 lessons, 281 unique objectives and 77 cards. Xolos has nine required lessons and Madrid ten. Five player paths have two required lessons/six memories each; Saucedo remains at one lesson/three memories. All old entities, sources, facts, objectives, exercises and lessons compare unchanged to version 7, preserving their relative order. The rebuild is deterministic.

New player lessons use identical canonical IDs in their player and club roadmaps. Three player-card knowledge sets move from version 1 to 2. Club cards retain their club-specific sets unchanged; required club-course completion gains the new player lessons. Earned tiers remain while current coverage shows the new missing knowledge. No new review is created by reconciliation alone. Optional club context stays separate.

147 core tests pass on the final content. Five enrichment regressions cover shared required progress, once-only reviews, player-owned card sets, prior achievements/new missing knowledge, previously completed favorite paths gaining only the new required stories, source-scoped numbers, full-name aliases, distinct América identities and readable career graph edges. Existing artwork coverage checks verify every visual club choice is cached. Version-specific test fixtures now use each card's actual knowledge version and full knowledge set, preventing stale three-memory assumptions.

Primary-source checks and adversarial review removed an ambiguously scoped Chinese goal tally and redundant final trivia, changed Arce's required debut-day memory to its year, and broadened accepted number and club-name equivalents. Cristiano's 451-goal answer explicitly names the official Madrid profile; Riascos's 23-goal figure names the March 2019 retrospective. Four factual source links and four badge-credit links are added. Source limits, illustrative badge periods and image provenance are recorded in `content/player-enrichment-notes.md` and `content/player-career-artwork.json`.

Three focused simulator scenarios pass: Cristiano's two lessons, relaunch and six-memory card; Riascos's career-club badge questions, relaunch and shared Xolos progress; and Arce's career lesson at the largest text size. An initial test expected nonexistent album wording; it now checks the actual Active set version label. The final portrait/club-badge run passes all three. Screenshots were exported and inspected. Large-text inspection found the next prompt could retain the previous scroll offset; each step and completion now returns to the top. The final large-text rerun passes with the player header reachable immediately after advancing, and its screenshot was inspected.

The optimized Release build succeeds and embeds the final bundled JSON. The player header uses the canonical first fact's subject; the image is decorative and its adjacent name remains readable. Existing motion settings and feedback apply. Physical-device VoiceOver was not manually exercised. The release is installed without resetting ordinary learner data. Saucedo's next lesson remains separately authored draft content, outside this shipped pack.

## Visual answer grids, score wheels and Saucedo’s second lesson

Content version 10 contains 95 lessons, 284 unique review memories and 77 cards. All six player paths now contain two required lessons and six memories. Xolos and Madrid each have ten lessons. Saucedo’s new shared lesson uses two directly checked official Xolos archives for U23 bronze, his senior Mexico debut year and his arrival from Tigres. The proposed upcoming appearance milestone was rejected. Only Saucedo’s card expands; old earned tiers remain intact.

All pre-existing entity, source, fact, objective and lesson records remain byte-equivalent as decoded records. Six existing exercises gain only optional score metadata; stable IDs and revisions are unchanged. The compiler reproduces the same bytes. The artwork cache keeps career-badge provenance and adds the visually inspected UEFA AC Milan crest.

Core verification: 152 tests pass in `/private/tmp/foxlingo-score-core-guard-final.log`. Checks include concealed identity artwork, mixed-subject neutral recall, shared progress, preserved old achievements, strict score direction, malformed score metadata, legacy JSON without wheels, repeated-question orientation consistency, and changed score mappings requiring revised factual context.

Default-size iPhone simulator verification: three scenarios pass in `/private/tmp/foxlingo-score-ui.log` (grid/wheels, Saucedo learning/recall, concealed identity recall). Two additional scenarios pass in `/private/tmp/foxlingo-score-context-ui.log`: separate half-time/full-time/shoot-out orientations, and previewed score recall retaining its due schedule. Captured screenshots were inspected for the grid, team badges, two native wheels and scheduled feedback.

The final width adjustment is checked separately in `/private/tmp/foxlingo-score-layout-ui.log`; the question’s bounds must remain within the screen while the wheels still support wrong/reversed and corrected answers. Final release build evidence is `/private/tmp/foxlingo-score-release-final-v2.log`. Broader feature work and the Madrid appearance-comparison draft remain outside this increment.

Final confirmation: the width-adjusted grid/wheel scenario passes, its prompt stays inside screen bounds, and the final screenshot was visually inspected. The optimized release build succeeds and its bundled content hash matches the authored version-10 pack.
