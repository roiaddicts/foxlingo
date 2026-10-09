# Daily Guess the Footballer

This is Futbol11's question-driven deduction game, separate from Foxlingo's authored Who am I? rounds. Up to ten questions and three player guesses are available independently; using all questions still leaves every remaining guess. A final-chance correct answer wins. Revealing or losing a round shows the answer without granting streak credit.

## Source identities

The source's 2,614 candidate players use their own namespace, `daily-guesswho-ID`. Daily records connect those IDs to the general portrait catalog through `secID`. For example, Nick Pope is candidate 91 but general portrait 548; general player 91 is Thomas Partey. Those integers are never joined directly.

The compiler preserves the 48-club and eight-league question catalogs. Their club IDs differ from the shirt catalog: question club 14 is Real Madrid, whose shirt is kit 9; question club 24 is AC Milan, whose shirt is kit 12. Artwork joins use reviewed name aliases and matching country. German clubs use existing bundled badges where the source shirt catalog has no corresponding entry.

Additional candidate portraits require a full name unique in both catalogs. Explicit source `secID` links take precedence. The native loader validates every join; no factual eligibility or career relationship crosses an artwork-only join. Ambiguous or missing portraits retain the usual fallback rather than inventing an identity.

## Questions and scope

The eight topics are snapshot club, snapshot league, nationality, position, age, height, listed career clubs and listed career leagues. Numeric questions support exactly, over and under with strict comparisons. Age follows the source's UTC year-of-elapsed-birthday calculation, fixed to the dated packet so a saved round remains stable.

Past-club questions include the supplied current club, and past-league questions include leagues inferred from explicitly listed clubs plus explicit previous-league entries, matching the source. “No” describes the provided catalog rather than a complete career claim. Missing current club or league metadata displays “Not listed” rather than an invented answer.

Question options use club shirts or badges and country flags. Position options form a 2×2 grid; numeric questions use a native wheel. Search sits above the keyboard with results above it. Completing the round scrolls to the revealed portrait and profile.

## Saved rounds and checks

Typed questions, guesses, reveal state and session ID are saved atomically under a content signature. Duplicate questions and guesses, foreign namespaces, out-of-range values and attempts after completion are rejected. Wins earn credit once; practice recommendations wait until the round ends so they cannot reveal a live mystery.

Core tests cover every topic, exact numeric boundaries, source identity and artwork joins, question limits, final-chance wins, losses, reveal, invalid saves, changed source data, missing metadata and older-packet compatibility. Simulator tests ask visual and numeric questions, restore history, make two wrong guesses, solve on the final chance and restore the completed result. The daily compiler is checked against its verified archive without executing downloaded JavaScript.
