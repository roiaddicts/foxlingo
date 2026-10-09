# Adding player curriculum

`content/player-catalog.json` is authored content, separate from the raw seed catalogs. It contains `players`, `sources`, and `lessons` arrays. It is compiled by `scripts/build_content.py` through `merge_player_catalog.py`.

A player entry declares a stable canonical entity key, name, aliases, visual initials, canonical club key, and explicit provider `seedID` plus expected `seedName`. An optional reviewed portrait URL and source page can replace a missing seed image. Do not join arbitrary datasets by equal integer IDs or names. Existing canonical entities can gain a first path; existing cards require the enrichment workflow instead of this initializer.

Every initial path has exactly two authored lessons with three facts each. Use a career lesson and a club-record lesson. Facts carry a stable key, label, prompt, accepted answer aliases, three distinct distractors, typed value, explicit historical scope, official source key and evidence. Numbers require a number and unit. Entity values reference canonical entity keys; every club/country/player answer and distractor needs supported artwork. Story pages should explain the facts in original language without introducing unsupported claims.

The compiler preserves old content, creates player cards and separate required lessons, and attaches one optional existing club-history lesson. A club-appearance fact supports the historical player-to-club graph edge. Player paths do not lengthen the club’s required lessons. Album collections use canonical player-roadmap club context as well as shared lessons.

Run the content builder, cache artwork, run the core checks, and verify one new path and its album entry on the normal iPhone layout. Check the compiled old facts/objectives/lessons/cards/roadmaps against the previous pack before publishing. Increase contentVersion; later changes to existing objective meaning need revisions under the update rules.

These paths are initial history/stat lessons, not full profiles or current squad feeds. Additional career chapters, seasons, match events, awards, and dated live stats remain separate sourced authoring work.
