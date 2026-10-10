# Daily Grid

The daily adapter offers Easy, Normal, Hard and Legend. It consumes the source's dated boards and 3,492-player general catalog, preserving `daily-general-` player identities. Each square accepts an explicitly listed player in both header categories; players can be placed only once. The separate Practice Grid remains replayable.

The compiler follows the source date-string shuffle and category pools: Easy uses club/country; Normal club; Hard club/country/country2; Legend adds club2. Rows must share a candidate with each column. The numeric-seed fallback is bounded to avoid infinite refresh loops. Bingo and grid membership CSVs form a positive union. A missing membership never becomes evidence that a footballer did not play for a club. Tests compare all four boards against an independently authored JavaScript data-only oracle.

Header flags and club shirts open named category details. Uniform squares show large portraits and small names. Search stays above the keyboard, with results above it. Searching from a square checks that connection; global search places a player automatically when exactly one open square fits, or highlights possible squares. Undo removes the last placement, allowing recovery from a valid choice that blocks another square.

No timer, 60 seconds and 90 seconds are available before starting. Difficulty and timer preferences persist; a started round locks them. Timers count active game time, pause when leaving or backgrounding, and resume with the saved remainder. Periodic saved snapshots preserve active-play time after interruption. Late guesses expire before being accepted.

Revealing finishes an assisted round and shows examples separately from actual placements. It grants no win or streak credit. This intentionally resolves the source help action's unfinished-state behavior. A complete nine-player board grants win credit once, including after relaunch. Incorrect source pairings become practice gaps with namespaced source references; recommendations never manufacture negative career claims or silently join unrelated numeric IDs.

The initial offline bundle is refreshed to the current publication. Core and UI regression tests use the immutable October 9 packet for reproducible answers; a separate test loads the current bundled packet and checks every available adapter. A DEBUG-only UI-testing argument selects that fixture without bundling it into the release app.
