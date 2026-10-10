# Daily Football Bingo

The source's dated board has four club, one club2, two country, one combined country2/continent, one extra, two award and one league category. Each pool is shuffled with MM/DD/YYYY before slicing; the combined board is shuffled again. The compiler verifies the full selector contract, imported general-player/category bindings and positive candidates for every square. The app verifies the recipe, category definitions and source date before accepting a package.

Only general-catalog players with a nonempty `bingo` CSV are offered. Whitespace is accepted in numeric CSV values as in the source's `Number` conversion. Grid memberships never count toward Bingo acceptance. Identities retain the `daily-general-` namespace; they never join Retro legends by numeric ID.

Players are offered randomly and may appear or be placed multiple times. A correct placement fills one category, resets the skip counter and draws again. Wrong and filled-square taps retain the current offer. A random threshold of 2–5 skips produces a player fitting at least one remaining category, resets the counter and resamples the threshold. Native uniform sampling replaces the source's random-string shuffle for this assisted offer, preserving its positive eligibility and pacing; it is not a shared daily offer sequence.

The 3-column phone board shows category artwork before placement and large portraits afterward, with a small category overlay. Hold a category to inspect its name. Completed rounds expose source-listed example players. These are historical catalog memberships, not live current squads; an unlisted pairing never creates a negative career fact.

Untimed, 60-second and 90-second rounds share the existing verified Bingo Retro engine, with separate catalogs, help ranges, cache filenames and completion kinds. Timer deadlines continue while away, as explicitly described before starting. Expiry is checked before a move and on return. Round, offer, skip count, threshold, timer and mistakes survive relaunch. Wins award streak credit once; timed losses expose the board without credit. Failed pairings retain namespaced source references for future lesson recommendations.

The bundled current-day packet supports twelve daily adapters. Bingo tests use the immutable October 10 packet for repeatable data assertions and UI staging. Simulator tests also play real random offers, verify wrong-pair recovery, skip and saved-offer recovery, and check continuous timer expiry. The previous Retro flows remain regression coverage for the shared screen and engine.
