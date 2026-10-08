# Who am I?

A six-player starter board connects Riascos, Arce, Saucedo, Ronaldo, Ramos and Casillas to the sourced facts already taught in their lessons. It is explicitly bounded to these featured players, rather than claiming that a role or statistic identifies a person uniquely across football.

`content/mystery-rounds.json` is the authoring source. The content builder copies it to the bundled `mystery-en.json`. Each stable round UUID/key references a canonical subject and three ordered clues: historical role, a scoped connection/record, then canonical-name initials. Clues reference existing fact UUIDs and expected predicates. Comparison fact UUIDs establish what is known about other players. Optional club context UUIDs attach badges and spoken labels to scoped records. No cross-provider ID or name-based join grades answers.

A correct canonical subject resolves the round. A different subject is rejected only when a revealed comparison fact contradicts it. Missing evidence or a plausible alternative reveals another clue neutrally; missing facts are never proof of a negative claim. Final initials are unique within the available pool. An identified round locks further guesses/reveals.

The target portrait/name and source evidence appear only after identification. Choosing a player shows the whole available portrait roster, without marking the hidden target. Names embedded in early clue values, labels or scopes retire an unsafe round. If delivered lessons remove target facts, only affected rounds disappear; missing comparison facts become unknown. The currently installed curriculum stays fixed during a game.

Normal entry and replay shuffle the round order. Replay clears revealed clues, identity, feedback and counts. Each finished board records one activity session and can count toward the daily streak. It grants no review stage, mastery tier or album card. The completion summary reports clues used instead of describing assisted play as independent recall.

Animations reveal clues, resolve portraits and fill classic board cells/progress; Reduce Motion removes those animated changes. Large accessibility text uses a single-column player picker. Numeric records retain units, club context and historical scope.

This release bundles mystery definitions with app code. Lesson delivery can change the facts they reference, but does not yet distribute new mystery definitions or game packs. Unfinished boards save locally, including player order, revealed clues, guesses and a solved player awaiting Next or Finish. Returning preserves that session; completing it removes the draft and records activity once. A changed clue meaning retires only the incompatible saved board. Artwork and source wording edits preserve it.
