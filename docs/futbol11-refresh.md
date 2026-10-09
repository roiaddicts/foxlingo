# Public Futbol11 seed refresh

Download current public first-party JavaScript assets without executing them:

```sh
python3 scripts/refresh_futbol11.py --site current
# Archive the current modular site; latest-current.json points to it.

python3 scripts/refresh_futbol11.py --site legacy
python3 scripts/build_games.py --snapshot ref/futbol11-snapshots/<printed-legacy-folder>/snapshot.json
python3 -m unittest discover -s scripts -p 'test_futbol11_source.py'
swift test
```

The downloader archives the homepage, every discovered first-party script, all embedded JSON arrays, UTC fetch time, URLs and SHA-256 checksums. The default CLI source is the current `futbol11.com` site. Its static module dependencies are followed without running JavaScript, including JSON stored in non-interpolated template literals. Archives are limited to 128 modules, 32 MiB per asset and 64 MiB total. The legacy source remains available with `--site legacy`. Third-party scripts are skipped. Role bindings use schemas, identity anchors and validated game references rather than literal positions. Ambiguous roles, duplicate entity IDs, changed anchors, missing references or failed downloads fail before the latest snapshot pointer changes. The previous snapshot stays available. Raw archives are ignored by Git; the committed refresh inventory records the reviewed source evidence.

The compiler keeps game and classic-player ID namespaces separate. Existing player, category and squad IDs cannot silently change identities. Only explicitly preserved portrait crosswalks join those namespaces. New classic players without a verified portrait retain initials. Club badges come from the relevant squad source. Every squad must have a solution with eleven distinct eligible players. Three squads use an alternative playable formation; the app describes these as historical season squad exercises, not actual match starting lineups.

The current game pack includes 5,274 provider player records, 158 categories and 98 season squads. Bingo and grid retain their existing visual boards; the larger category catalog is available for future boards. The curriculum remains separately authored and sourced: importing game relationships does not automatically create verified history lessons. Unresolved catalog club/country IDs stay in the raw snapshot rather than being joined by coincidental integer IDs. Provider game ratings are not authoritative player-performance rankings.

A download date does not establish roster or statistic freshness. No independent daily-game endpoint or coverage of today's games has been verified. Refresh downloads the current scripts and embedded datasets; it does not promise current squads, every player, or every major league. Fetch provenance is separate from saved-board identity so unchanged data can refresh without resetting games.

The compiler also trims whitespace in upstream position lists. This corrects previously omitted secondary positions on the four original Madrid squads, so their candidate sets change. In-progress lineup boards may restart under the existing content compatibility rule; completed activity and learning progress stay intact.

## Current-site review (October 9, 2026)

The latest current-site archive contains **64 scripts, 20 datasets and 20,161 raw records**. Six game roles pass schema, identity-anchor and category/squad reference validation. Other datasets—including two copies of the player-rating catalog, Statdle, transfer chains and SquadSlice season squads—remain separately archived rather than joined by integer ID. The reviewed inventory is `content/futbol11-current-inventory.json`.

The current snapshot uses schema version 2 and its own `latest-current.json` pointer; a successful current archive does not replace the last validated legacy snapshot. Its 3,492 game-player records include name changes and reused IDs relative to the bundled game pack. Twelve names changed, including actual identity conflicts: provider ID 2229 changed from Hannibal Mejbri to Dwight Gayle, and 2230 from Mattia Perin to Gerd Müller. `content/futbol11-current-player-namespaces.json` now assigns eleven current records separate `current-player-*` IDs and checks their exact prior/incoming names before each build. Older records are retained. These overrides preserve both records without asserting that spelling changes are the same person. Unreviewed later changes still fail before output is written. `content/futbol11-current-identity-review.json` records the comparison and namespace resolution.

The current snapshot now compiles directly into the app with the same build command (use the current snapshot folder). It adds 1,286 namespaced records to the earlier 3,988: 1,268 previously unseen game-player IDs, eleven separately preserved names and seven classic squad records. This is not a count of unique people or authored player lesson paths. All older app player IDs and display names remain available.

The current Grid module explicitly combines each player’s `bingo` and `grid` fields against the `gameGroups` dataset. Named club/country categories gain those memberships after matching both group type and normalized name. Integer IDs are not category joins: Liverpool is category 4 but group 6. Categories without a matching current named group retain their supplied historical members. Source eligibility is game data; it does not prove senior-team appearances, a current signed contract or official history claims. The resulting pack exposes 2,127 distinct records through category memberships.

The Bingo module constructs a date key from the browser’s local calendar and uses it for daily category selection. This is evidence of client-side daily selection, not an independent daily endpoint, an externally verified challenge for every game, or proof that the underlying football statistics are current. The full game modules are archived for further rule and selection review.

This is an editorial command-line pipeline. The app does not download or execute upstream JavaScript, and no recurring refresh or remote content service is configured.

The game pack’s optional `activeConnectionPlayerIDs` field separates the current search/Wordle choices from retained archived records, so a name variant is not displayed twice just to preserve an old save. Older game packs without that field still load. Candidate references must all belong to the active catalog.

Provider record 518 is quarantined from new choices: its renamed Mousa/Moussa label, country identifier and club/country membership fields conflict. Its raw data remains in the source archive, and the older app record is retained for save compatibility. This is an unresolved data-quality issue, not an inferred merger of two similarly named players.

Cached artwork retains its original download URL when already present. A changed requested source URL is recorded separately in `requestedURL`; refreshing script metadata does not claim that the cached image was downloaded again.
