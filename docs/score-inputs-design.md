# Visual answers and score wheels

Visual thesis: the Fox navy learning journal uses centered club badges, portraits and flags in a compact two-by-two answer grid. Text-only questions retain their familiar rows. Picture buttons have a subtle press response and show the correct-answer border after submission.

Score questions use two native iOS wheel pickers, each beneath its club badge and readable name. The selected result reads left to right. An explicit Check score button submits it; spinning a wheel never grades an answer. Wrong scores retain the chosen values for retry. Moving to another question resets both values to zero. The same control works in due recall, early rehearsal and coverage recall.

The JSON file `content/score-inputs.json` opts in six existing exercises: Xolos’s aggregate final score, Necaxa’s final result, and four Istanbul checks. It declares club UUIDs, score orientation, expected numbers and a broad 0–20 range. Penalty shoot-out and aggregate wording remain in their original prompts and feedback. Liverpool goes on the left for its winning shoot-out; Milan goes on the left for half-time and full-time. There is no inference from dates or hyphenated seasons.

The loader validates club identities and artwork, numeric bounds, canonical answers and repeated-objective orientation. Older packs without metadata keep their choice questions. Older apps can continue displaying the original choices. Score inputs keep existing objective IDs, revisions and scheduling. Native numeric input is exact; no embedding or model grading is used.

Verification emphasizes the default iPhone layout, two-column grid geometry, wrong reversed scores, corrected scores, safe identity recall and due-review scoring. AC Milan’s UEFA badge is cached offline and carries source provenance. The badge is illustrative, without asserting it is the precise 2005 edition.

Content transitions also protect established team-to-goals mappings. Changing that meaning requires a higher objective revision and updated factual value or scope; repeating the same question twice cannot bypass the guard. Expanding the wheel range is presentation-only.
