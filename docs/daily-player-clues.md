# Daily player-clue games

The native Statdle, Legacy and Link games consume `DailyChallengePack.revealRounds` from the verified Futbol11 package. They preserve the daily record and source identities, not an inferred substitute from the learning graph.

## Source rules

- Statdle starts with the league and season. Each miss or skip consumes one of five chances and reveals up to two randomly chosen remaining clues. Normal includes appearances, goals, assists, position, country, age, value and club. Hard removes country and club. All statistics refer to the named historical season. The source's semicolon-separated record is parsed without substituting lifetime statistics. The first field's player label/shirt number is not used as an early clue.
- Legacy starts with one of four club shirts. A miss or skip reveals the next, with one final chance when all four are visible. Source order is the whole inline club catalog shuffled with the numeric day seed, then filtered by the authored club IDs. It is not chronological. An editorial "DELETE THIS SHIRT IN FOLDER" placeholder is displayed as an initial badge rather than treated as an image URL.
- Link starts with one of five teammate portraits. Each miss or skip reveals another, with a final chance after all five. Source order is the whole general player catalog shuffled with MM/DD/YYYY, then filtered by explicit authored teammate IDs. These are the source's senior shared-pitch claims, including club or national team connections, never inferred from sharing a roster or nationality.

All three import the general player namespace (`daily-general-ID`). Clubs XI and Nations XI raw numeric IDs refer to other people and are never used for these answer joins. The compiler validates imported bindings and the inline club catalog wrapper. Every selected record must match its source dataset row and the package's actual rounded local-day index.

## Interaction and persistence

The screen keeps a compact instruction, a clue grid, an attempt history and bottom search/skip actions. Shirts, nationality flags and large teammate portraits replace text-only entity clues. Numerical stats remain readable numbers. Player search stays above the keyboard. Reveal and answer transitions are short, with reduced-motion support and correct/mismatch/reveal sounds.

Clue order, difficulty, attempts and session ID are saved after each turn. Duplicate wrong guesses, foreign namespace IDs, attempts after a result and invalid mixed rounds are rejected. Statdle's random order is saved; relaunch does not reshuffle revealed clues. Hard mode can be selected before any attempt. Winning or losing rounds reopen as their completed result, without restarting the same daily challenge.

Only wins receive idempotent streak credit. Practice-gap recommendations wait until the hidden player is identified or revealed at the end, so lesson titles cannot spoil the answer. Both missed guesses and skipped rounds retain the original answer/reference names without generating unsupported lesson facts.

## Verification

Core tests validate actual source answers and artwork, historical values, each game's reveal rate, final-chance wins, losses, duplicate guesses, foreign IDs, hard mode, random order persistence, invalid saves, cache retention, older package compatibility and date consistency. Simulator tests exercise Legacy's wrong guess and resume, Legacy and Link wins with source portraits/shirts, Statdle hard-mode resume and final-chance loss, and a normal-mode win. A live nineteen-mode refresh with the support table succeeded on 2026-10-09.

Five modes remain to be implemented natively, and the existing other native games still need source-authored daily adapters. No public feed is deployed by this batch; the configured HTTPS pointer or JSON import delivers the published package.
