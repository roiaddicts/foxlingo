# Futbol11 daily data

## Verified behavior

The public homepage currently lists nineteen football games. In the reviewed 2026-10-09 source, daily challenges are selected from embedded data by local date indexes and seeded shuffles; fetching the module archive alone does not identify today's challenge. The compiler discovers actual daily-store implementations, traces their imports, verifies every archived module and embedded dataset, and checks the homepage inventory against the supported nineteen modes.

`content/futbol11-daily-contracts.json` pins reviewed selector programs. Module filenames and static data tables may change without changing those programs. Changed selector logic, bindings, schemas, inventory, missing records or out-of-range dates reject publication. Updating the contract requires reviewing the changed code and verifying its behavior; the refresh command never automatically approves a new selector.

The contracts also pin all seven imported dataset programs actually bound to the current daily games, including the general portraits/memberships, countries/flags, category table, XI profiles and Impostor records. This catches post-parse mutations and changed exports that a JSON-only extractor could miss. Two archived legacy screen programs are not consumed by current daily adapters; changing their implementation alone does not block a refresh. Their bytes and extracted data still undergo archive integrity checks.

The common source date helper rounds elapsed days since local December 31. Pyramid independently floors elapsed days; during daylight saving time it can select a different array row. Source numeric shuffle seeds skip the string-hashing loop, while string seeds use UTF-16 code units. The compiler preserves both behaviors, including the seeded Fisher–Yates order. Numeric seeds must not be converted to strings.

Countries, Clubs, Retro, Legends and America use their own salts and formation indexes. Retro keeps the first squad per distinct club before shuffling, matching the daily source. Grid combines explicit bingo and grid memberships and follows the bounded source fallback search. Connections reproduces category exclusion and selected-player exclusion. Bingo and Bingo Retro provide dated category boards, while player offers are intentionally random. Impostor's hard-mode extra positives are retained separately. Grid includes Easy, Normal, Hard and Legend boards with the source category pools. Connections includes Easy and Normal boards; Hard uses the Normal board with five mistakes. Impostor includes Normal and One by One using its explicit positive, extra-positive and impostor lists.

All five XI selections now package Normal/Easy boards, bound player and formation catalogs, exact positional memberships, unique-name portrait crosswalks, excluded unsupported position records and timer choices. Support program changes and unplayable exact draws reject publication. All five native XI daily adapters consume these boards. See [Daily XI source contract](daily-xi.md).

## Refresh and publication

Run:

```sh
python3 scripts/refresh_daily_futbol11.py --timezone America/Mexico_City
```

The date defaults to today in that timezone. `--date YYYY-MM-DD`, `--destination`, and `--archives` provide explicit overrides. The command fetches a new current-site archive, verifies all nineteen selectors, then writes a self-contained dated JSON package and atomically replaces `ref/futbol11-daily/latest.json`. The package includes the twenty source datasets, selector contracts digest, snapshot digest, per-mode module digests, game date, timezone, fetch time and scope. These are source identities; raw numeric IDs across datasets are not interchangeable or canonical learning IDs.

Transient network errors receive bounded retries, including short numeric Retry-After delays. A missing module during a deploy receives one fresh-page retry. Interrupted downloads or rejected compilation leave the last complete daily pointer intact. The command exits unsuccessfully and reports the last good date instead of labeling cached data as today's data. Archived modules and downloaded JavaScript are never executed. A backend may serve the resulting JSON with compression; it must preserve these dates and digests.

Before reusing an existing immutable packet filename, publication verifies its bytes exactly. Corruption rejects publication without advancing the last good pointer or overwriting the conflicting file. Publishing the identical packet again preserves the previous distinct rollback filename instead of replacing it with a self-reference.

For an already archived source:

```sh
python3 scripts/futbol11_daily.py --snapshot PATH/snapshot.json --date 2026-10-09 --timezone America/Mexico_City
```

Player and statistic freshness is independent of the daily game date. Source historical scopes, season labels and ranking titles must remain visible in native game adapters. Missing data must not be filled with invented statistics or fallback questions labeled as the provider's daily game.

## Evidence

Two live public-source downloads succeeded on 2026-10-09 despite changed module filenames relative to the previous archive. A complete fetch, compilation and atomic publication produced all nineteen selections and 20,227 records across twenty datasets. The frozen reproducible fixture is `ref/futbol11-fixtures/current-2026-10-09/`; normal refresh archives remain ignored runtime output.

Browser checks on the same day confirmed:

- [Top 10](https://futbol11.com/futbol11-top10): Chelsea 2023/24 — Most matches, matching source row 282.
- [Countries XI](https://futbol11.com/futbol11): Uruguay first, with the 3–5–2 formation.
- [Connections](https://futbol11.com/futbol11-connections): all sixteen displayed player surnames in exactly the compiled order, including the first Alonso and last Zaha.

Offline tests verify all nineteen mode selections, JavaScript arithmetic compatibility, UTF-16 seeds, numeric-seed behavior, year boundaries, leap dates, DST, malformed or changed programs, transient and permanent HTTP failures, fresh-page retries, interrupted publication and retention of the last good pointer. Run `python3 -m unittest discover -s scripts -p 'test_*.py'` with Python 3.9+ and Node available for the independent arithmetic test.

## Remaining app work

Daily extraction covers nineteen modes; native game coverage is nineteen modes. Top 10, Statdle, Legacy, Link, Pyramid, SquadSlice, Guess the Footballer, Goltexto, Bingo Retro, Wordle, Grid, Bingo, Connections and Impostor consume packaged daily selections in-app. The five XI modes also consume their exact dated source boards. All nineteen mode screens now have native daily consumers.

## In-app delivery

The app bundles `Foxlingo/Resources/daily-en.json` as its initial offline set. In Games → Daily challenge updates, import a compiled package or connect an HTTPS URL to the published `latest.json`. The referenced package must be in the same feed directory with the exact dated digest filename. Foxlingo checks the checksum, date, timezone, nineteen-mode inventory and supported native source relationships before installation. Failed downloads or imports preserve the last good set. A configured feed is checked on launch and when the app becomes active if its saved set is not today's set.

No public feed is deployed or assumed. Host the output directory from the refresh command on your HTTPS static storage and supply that `latest.json` address. To refresh the next app build's bundled set, copy the verified dated output to `Foxlingo/Resources/daily-en.json` and run the core tests.

For Firebase Hosting, [daily feed deployment](daily-feed-deployment.md) describes the dedicated-site release preparer, native validation, cache headers and remaining project/scheduler setup. The preparer stages only verified JSON and does not deploy by itself.

Top 10 uses the general-game player table, never Clubs/Nations numeric IDs. It preserves ranked order, nationality flag clues, source title/season and visible game date. Portraits replace flags on successful guesses. Source nicknames and HTTPS portrait URLs are supported. Saved progress is tied to the exact ranking, names, images, flags, date and timezone. Both unfinished and finished lists survive relaunch, and completion earns streak credit once per session. Wrong answers and assisted reveals record practice gaps without fabricating lesson facts.

All nineteen feed selections drive native daily screens. Full goal completion still requires verification of runtime coverage, source identity and fresh delivery; a hosted feed is not configured by default.

The additive `support.clubs` table preserves the source's inline club names, country IDs and kit URLs, with its module URL/digest. Its executable wrapper has a reviewed selector contract. Legacy's club clue order and Link's teammate order are compiled with the source shuffle and correct seeds. Statdle, Legacy and Link are explicitly bound to the general-game player table during compilation. Apps reject selected native record indexes that do not match the game date's local index: floor for Pyramid and rounded for the other supported modes. Older Top 10-only packages remain readable without inventing clues for the new modes. A newer bundled date, or a same-date bundle with more supported modes, takes precedence over an older cached package after an app update.

SquadSlice has its own UTF-16 FNV-1a/Mulberry32 shuffle, seeded with `clubID-season`; it does not use the common daily shuffle. Its compiled `slices` preserve the source general-player join, omitted player IDs, descending nationality counts and numeric-country tie order. `revealOrder` is verified against an independent authored JavaScript math oracle. Pyramid uses `elapsedDayFloor`, validates its source record and ten unique selected values, and keeps the first source player per tied value. Native Pyramid validates the floor index; the other selected native records validate the rounded index.

Guess the Footballer packages its own 48-club and eight-league question catalogs and player-module binding. Daily records retain their explicit `secID` portrait identities. Additional search portraits join only on a full name unique in both player catalogs; they carry no club, nationality or career facts across that join. Club shirt artwork joins by reviewed names and matching country, never by the question catalog’s integer club ID. The native loader verifies these relationships.

Goltexto binds its separate ratings module, 71-country catalog, shared shirt table, source league/region mappings and 366-player daily shuffle order. Its 969 searchable profiles include missing ages. Portraits are artwork-only crosswalks on full names unique in both catalogs, validated again in-app; nationality and club IDs never cross namespaces. See `docs/daily-goltexto.md` for scoring and independent validation.

Bingo Retro packages its separate legend-module binding, full category table and board date. The app verifies every selected category against that table, the exact type recipe and source-listed player memberships. Retired category IDs in the player table remain uninterpreted and cannot create playable facts. Its namespace never joins general-player IDs.

Daily Wordle packages the source’s ordered 374-word array, imported module binding and general-player binding. A reviewed dictionary-wrapper contract permits literal word updates and rejects changed executable code. Native Normal mode accepts an exact uppercased whole first name, surname, nickname or dictionary word; Easy permits any ASCII letter sequence of the answer length. Partial input, difficulty, guesses and completed outcomes persist. See `docs/daily-wordle.md`.

Grid consumes all four dated source boards, with unique player placements, visual category headers, undo, global player search, saved outcomes and optional active-play timers. See [Daily Grid](daily-grid.md). Regression tests use a fixed dated packet while the app bundles the newly refreshed day.

Bingo now binds its general-player and category tables explicitly, verifies all twelve categories have positive matches, and consumes the dated recipe natively. Grid membership is never substituted for Bingo membership. See [Daily Bingo](daily-bingo.md).

Connections compiles two source boards, preserving category and selected-player exclusion, portrait availability and the source seeded order. An independent JavaScript data-only oracle verifies Easy and Normal; Hard shares Normal’s identities. See [Daily Connections](daily-connections.md).

Impostor binds the dated record table and general catalog, retaining raw extra-player IDs separately from any reviewed JSON corrections. Record membership, full source player names and evidence are required before a correction can change the playable extra list. The current correction registry is empty. See [Daily Impostor](daily-impostor.md).
