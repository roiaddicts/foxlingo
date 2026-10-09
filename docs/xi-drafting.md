# XI drafting

Five native games draw eleven distinct countries or clubs, then ask the learner to place one eligible player per offer into a formation. Nations XI, Clubs XI, Retro XI, Legends XI and America XI use separate archived player namespaces. America uses South American clubs. Retro draws one season squad per distinct club, preventing multiple seasons of a single club from filling the board.

`Foxlingo/Resources/drafts-en.json` supplies the player pools, explicit memberships, five source formations and their pitch rows. It contains 8,958 usable source profiles (not 8,958 distinct people), across 35 Nations groups, 35 Clubs groups, 98 Retro squads, 22 Legends countries and 33 America clubs. Four profiles with missing or malformed position codes are excluded and listed in `content/draft-source-exclusions.json`; their positions are not guessed.

`build_drafts.py` reads the verified local snapshot, parses static literals without executing JavaScript, and verifies source asset digests. Each mode retains its source membership semantics: club CSV membership, Nations country IDs, America club IDs, classic squad club keys, and Legends country keys are different relations. Legends excludes records marked active by its source. Unmarked players are not asserted to be retired today. Snapshot fetch time is never treated as a roster or statistic cutoff.

Portraits are reused only through unique exact normalized full-name matches or an existing reviewed classic identity. The 2,094 mappings are recorded in `content/draft-portrait-crosswalk.json`. A missing portrait displays the offered flag or shirt alongside the player's name; no headshot is inferred from shared numeric IDs. Group images are cached with URL provenance in the artwork manifest.

The indexed native engine validates identity, membership, open position and one use per person. A bounded search guarantees a completable starting XI and provides hints. It accepts valid picks even when those picks leave a dead end; Undo recovers the earlier offer. Saves retain offer order, placement history, assisted slots and a signature covering source membership, player profiles, formations and scope. Stale, mixed-mode, malformed and completed-session saves cannot resume. A legal dead end can resume.

Completed boards count once toward the streak. Hints do not grade recall or upgrade album mastery. Wrong country/club and position choices retain their namespaced references for lesson recommendations. The existing recommendation engine only suggests verified available lessons; live AI lesson generation still requires a configured service and evidence workflow.

Verification covers all 25 mode/formation combinations, solver recovery, namespaces, assisted Undo, resume validation, completion credit and static-parser safety. Simulator checks cover manual selection, rejection, positioning, persistence, Undo, replay and completion of all five modes.
