# Daily visual boards

Pyramid and SquadSlice consume the same verified nineteen-mode daily package as Top 10 and the player clue games. Source dates, player namespaces, selected records and artwork remain intact. Historical totals and rosters are labelled as source snapshots.

## Pyramid

Ten offered players must be ranked exactly from highest to lowest in four rows of one, two, three and four. The compiler follows the source's independent floor-day index and common shuffle. For tied values it keeps the first listed player before selecting ten unique values; it never invents a tie-breaker.

Place the offered portrait in an empty rank. Drag occupied ranks to swap, or tap two ranks. Easy mode highlights the top three, middle three or bottom four band. One check locks correct positions after all ten players are placed. Submit grades the exact order and reveals totals; a partial placement or unsuccessful ranking cannot earn streak credit.

## SquadSlice

A season-specific club squad is grouped by general-player nationality, with descending counts and ascending country IDs for equal counts. Source players missing from the catalog are explicitly retained as omitted IDs, matching the source's filter rather than fabricating nationality counts. The compiler independently reproduces its UTF-16 FNV-1a/Mulberry32 shuffle using `clubID-season`.

Random or Clockwise order can be chosen before the first attempt. Each stage reveals the whole-country prefix closest to 30%, 60% and the full squad; a large country can make these fractions uneven. Hidden sectors share a fill and no separating inset. Flags identify revealed countries. Tap a sector or flag to inspect its size. Club search uses source shirt artwork and stays above the keyboard. Three chances include misses and skips; a final-chance correct answer still wins.

After the round, the club and shirt are revealed and selecting a nationality shows the associated player portraits. Player identities stay hidden while guessing.

## Persistence and review

Every move or guess is saved under a content signature with a stable session ID. Invalid duplicate placements, foreign IDs, duplicate club guesses and attempts after completion are rejected. Relaunch retains difficulty, reveal order, placements, checks and results. Wins grant credit once. Practice gaps are recorded only after the result, so recommendations cannot disclose a live answer.

Core checks cover source selections, rankings, reveal stages, final-chance outcomes, cached rounds and malformed data. Simulator checks cover native dragging, swaps, relaunch, grading, flag inspection, club search and final squad portraits.
