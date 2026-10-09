# Public Futbol11 seed refresh

Download current public first-party JavaScript assets without executing them:

```sh
python3 scripts/refresh_futbol11.py
python3 scripts/build_games.py --snapshot ref/futbol11-snapshots/<printed-folder>/snapshot.json
python3 -m unittest discover -s scripts -p 'test_futbol11_source.py'
swift test
```

The downloader archives the homepage, every discovered first-party script, all embedded JSON arrays, UTC fetch time, URLs and SHA-256 checksums. Third-party scripts are skipped. Role bindings use schemas, identity anchors and validated game references rather than literal positions. Ambiguous roles, duplicate entity IDs, changed anchors, missing references or failed downloads fail before the latest snapshot pointer changes. The previous snapshot stays available. Raw archives are ignored by Git; the committed refresh inventory records the reviewed source evidence.

The compiler keeps game and classic-player ID namespaces separate. Existing player, category and squad IDs cannot silently change identities. Only explicitly preserved portrait crosswalks join those namespaces. New classic players without a verified portrait retain initials. Club badges come from the relevant squad source. Every squad must have a solution with eleven distinct eligible players. Three squads use an alternative playable formation; the app describes these as historical season squad exercises, not actual match starting lineups.

The current game pack includes 3,988 provider player records, 158 categories and 98 season squads. Bingo and grid retain their existing visual boards; the larger category catalog is available for future boards. The curriculum remains separately authored and sourced: importing game relationships does not automatically create verified history lessons. Unresolved catalog club/country IDs stay in the raw snapshot rather than being joined by coincidental integer IDs. Provider game ratings are not authoritative player-performance rankings.

A download date does not establish roster or statistic freshness. No independent daily-game endpoint or coverage of today's games has been verified. Refresh downloads the current scripts and embedded datasets; it does not promise current squads, every player, or every major league. Fetch provenance is separate from saved-board identity so unchanged data can refresh without resetting games.

The compiler also trims whitespace in upstream position lists. This corrects previously omitted secondary positions on the four original Madrid squads, so their candidate sets change. In-progress lineup boards may restart under the existing content compatibility rule; completed activity and learning progress stay intact.

This is an editorial command-line pipeline. The app does not download or execute upstream JavaScript, and no recurring refresh or remote content service is configured.
