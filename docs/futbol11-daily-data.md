# Futbol11 daily data

## Verified behavior

The public homepage currently lists nineteen football games. In the reviewed 2026-10-09 source, daily challenges are selected from embedded data by local date indexes and seeded shuffles; fetching the module archive alone does not identify today's challenge. The compiler discovers actual daily-store implementations, traces their imports, verifies every archived module and embedded dataset, and checks the homepage inventory against the supported nineteen modes.

`content/futbol11-daily-contracts.json` pins reviewed selector programs. Module filenames and static data tables may change without changing those programs. Changed selector logic, bindings, schemas, inventory, missing records or out-of-range dates reject publication. Updating the contract requires reviewing the changed code and verifying its behavior; the refresh command never automatically approves a new selector.

The common source date helper rounds elapsed days since local December 31. Pyramid independently floors elapsed days; during daylight saving time it can select a different array row. Source numeric shuffle seeds skip the string-hashing loop, while string seeds use UTF-16 code units. The compiler preserves both behaviors, including the seeded Fisher–Yates order. Numeric seeds must not be converted to strings.

Countries, Clubs, Retro, Legends and America use their own salts and formation indexes. Retro keeps the first squad per distinct club before shuffling, matching the daily source. Grid combines explicit bingo and grid memberships and follows the bounded source fallback search. Connections reproduces category exclusion and selected-player exclusion. Bingo and Bingo Retro provide dated category boards, while player offers are intentionally random. Impostor's hard-mode extra positives are retained separately. The compiled defaults are the source defaults: Grid easy; Connections and Impostor normal. Other difficulty variants still need adapters in the app.

## Refresh and publication

Run:

```sh
python3 scripts/refresh_daily_futbol11.py --timezone America/Mexico_City
```

The date defaults to today in that timezone. `--date YYYY-MM-DD`, `--destination`, and `--archives` provide explicit overrides. The command fetches a new current-site archive, verifies all nineteen selectors, then writes a self-contained dated JSON package and atomically replaces `ref/futbol11-daily/latest.json`. The package includes the twenty source datasets, selector contracts digest, snapshot digest, per-mode module digests, game date, timezone, fetch time and scope. These are source identities; raw numeric IDs across datasets are not interchangeable or canonical learning IDs.

Transient network errors receive bounded retries, including short numeric Retry-After delays. A missing module during a deploy receives one fresh-page retry. Interrupted downloads or rejected compilation leave the last complete daily pointer intact. The command exits unsuccessfully and reports the last good date instead of labeling cached data as today's data. Archived modules and downloaded JavaScript are never executed. A backend may serve the resulting JSON with compression; it must preserve these dates and digests.

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

Daily extraction covers nineteen modes; native game coverage is eleven modes. Top 10 now consumes the packaged daily ranking in-app. Remaining native screens are SquadSlice, Statdle, Goltexto, Pyramid, Legacy, Bingo Retro, Link and Guess the Footballer. Existing native games still need source-authored daily adapters and broader Connections/Impostor variants.

## In-app delivery

The app bundles `Foxlingo/Resources/daily-en.json` as its initial offline set. In Games → Daily challenge updates, import a compiled package or connect an HTTPS URL to the published `latest.json`. The referenced package must be in the same feed directory with the exact dated digest filename. Foxlingo checks the checksum, date, timezone, nineteen-mode inventory and Top 10 source relationships before installation. Failed downloads or imports preserve the last good set. A configured feed is checked on launch and when the app becomes active if its saved set is not today's set.

No public feed is deployed or assumed. Host the output directory from the refresh command on your HTTPS static storage and supply that `latest.json` address. To refresh the next app build's bundled set, copy the verified dated output to `Foxlingo/Resources/daily-en.json` and run the core tests.

Top 10 uses the general-game player table, never Clubs/Nations numeric IDs. It preserves ranked order, nationality flag clues, source title/season and visible game date. Portraits replace flags on successful guesses. Source nicknames and HTTPS portrait URLs are supported. Saved progress is tied to the exact ranking, names, images, flags, date and timezone. Both unfinished and finished lists survive relaunch, and completion earns streak credit once per session. Wrong answers and assisted reveals record practice gaps without fabricating lesson facts.

The feed's other eighteen selections are retained in the package but do not yet drive their native screens. Full goal completion requires every game to be playable and every daily adapter to preserve source identity and freshness.
