# Daily Football Wordle

The dated daily name is selected by the source’s rounded local-day ordinal from an ordered 374-word array. The compiler verifies the dictionary import and the general-player import. It pins the imported dictionary wrapper after replacing only the reviewed literal word array, permitting name updates while rejecting changes to its program. Downloaded JavaScript is parsed as data, never executed.

Normal mode accepts a whole first name, surname or nickname uppercased exactly as stored in the general-player table, or a word from the daily array. It does not split names, fold accents or remove punctuation. The on-screen alphabet accepts ASCII letters. Easy mode accepts any letter sequence with the answer’s length. Six guesses are available. Repeated guesses are permitted and consume a chance, matching the source. Difficulty locks after the first submitted guess.

Letter feedback uses the existing two-pass count-consuming engine: mark exact positions first, then consume each remaining occurrence once for displaced letters. Keyboard colors preserve the strongest known mark. The UI uses Fox navy for exact positions, gold for displaced letters and muted gray for absent letters.

Partial input, mode, guesses, session and completed outcome are saved atomically against the dated source signature. Unknown names leave the input and attempt count intact. A correct sixth guess wins; six misses lose. Finished rounds remain visible on relaunch. Only wins earn streak credit once; a completed saved win recovers credit if recording was interrupted. The separate Practice Wordle remains replayable.

A Wordle answer is a name string rather than a selected player ID. Completed rounds show portraits of source players with a matching whole name field, labeled as examples. Multiple matching people remain distinct. A loss records the name and source example IDs without choosing a canonical lesson subject from an ambiguous surname.

Core tests cover dictionary semantics, repeated-letter marks, Normal/Easy rules, partial input, repeated guesses, final-chance wins, losses, saved outcomes, invalid progress and altered catalogs. Python verifies imported bindings and rejects executable wrapper changes while accepting a literal dictionary update. Simulator tests cover unknown-name recovery, switching to Easy, resuming partial typing, a saved win and a saved Normal-mode loss.

Run `swift test` and `python3 -m unittest discover -s scripts -p 'test_*.py'`. Xcode UI checks are `FlowTests/testDailyWordleDifficultyUnknownInputPartialResumeAndWin` and `FlowTests/testDailyWordleNormalRepeatedNamesAndSavedLoss`.

All nineteen modes have native screens. Ten now consume the verified daily packet; Grid, Bingo, Connections, Impostor and the five XI modes still need daily adapters. Public feed hosting remains unconfigured.
