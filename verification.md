# Foxlingo verification

Verified October 8, 2026, using Xcode 26.3 and an iPhone 17 Pro simulator running iOS 26.3.1.

## Result

**76 core tests pass.** The initial six end-to-end scenarios and subsequent focused simulator checks are recorded below. The original full regression and later feature checks are separate runs, rather than a fresh run of every UI test after every change. Debug and optimized Release builds have passed; the Release executable excludes the Debug-only test launch flags.

## Requirements and evidence

| Requirement | Evidence |
| --- | --- |
| 68 club roadmaps, 78 lessons | Content checks confirm 36 Champions League, 18 Bundesliga, 18 Liga MX memberships; full simulator walkthrough completes the 12 favorite-club lessons and sample Atlas/Paderborn starters |
| JSON-authored content and 74 album cards | Pack validation covers 233 objectives; favorite-club walkthrough unlocks its original eight cards |
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

The current mystery player pool is deliberately bounded to six favorite-course subjects. Names/portraits and evidence are concealed until resolution; the answer picker shows the whole available portrait roster. Normal boards shuffle player order; UI fixtures keep deterministic order. Completing a board records streak activity without changing review memories, acquired cards or mastery tiers. Mystery definitions are bundled JSON, while their referenced facts come from the active validated lesson pack. Unfinished game boards are transient; saving game resumes and distributing new game packs remain future work. See `docs/mystery-game.md`.
