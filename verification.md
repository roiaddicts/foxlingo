# Foxlingo verification

Verified October 8, 2026, using Xcode 26.3 and an iPhone 17 Pro simulator running iOS 26.3.1.

## Result

**32 core tests and all six end-to-end scenarios passed across the full regression and focused reruns.** The Debug app used in UI tests and the optimized Release app both built successfully. The Release executable contains none of the Debug-only test launch flags.

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

This is a locally runnable native MVP, not an App Store or TestFlight publication. Physical-device installation needs the user's Apple development signing configuration. Live data, automated AI publishing, Firebase, match preparation, and the connection explorer remain the later work described in the vision.

## Visual clues and memory polish

- 37 core tests pass, including reversed memory pairs, concealed mismatch turns, saved pairs, malformed board rejection, and semantic visual typing (cities cannot become club badges).
- Real simulator flows pass for memory resume and all three football games. Large text welcome/lesson also passes after the semantic answer fix.
- All 9 club categories have cached badges. All 4 country categories use cached flag images; 22 flag images are bundled for country answers. Visual clues retain spoken country/club names. Player picker shows both grid clues.
- Choice answers only use artwork when all four options have supported visuals of the same semantic type. Historical, numeric, city, and nickname facts retain their meaning as text.
- VoiceOver holds unmatched cards until explicit dismissal; ordinary play turns them over after 1.8 seconds. This behavior is implemented and reviewed; a live VoiceOver session has not been exercised.
- Replayed lessons report their actual next recall date, preserving existing schedules. Press animations respect Reduce Motion.

## Daily study plan

44 core tests pass, including a 34-item backlog split into a five-question batch, cross-club resume, completed roadmaps, corrected-content history, bounded recent mistakes, rotating rehearsal, and old-save compatibility. The real simulator daily-plan flow passes: interrupted lesson resumes, six due objectives become a five-question session, the remaining queue updates, and the five-question preference persists into the next day's backlog. Independent recall, sources, and settings regression also passes. Picker persistence is verified through the resulting deck, rather than relying on its accessibility value.
