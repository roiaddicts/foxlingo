# Daily XI source contract

The compiler packages both Normal and Easy boards for Countries, Clubs, Retro, Legends and America. All five native daily adapters consume these boards. The existing practice XI screens keep their separate practice pack.

## Date and selection

Each board uses the rounded local day-of-year helper and the reviewed source shuffle. The formation always comes from the default mode seed; changing to Easy does not redraw it.

| Mode | Normal seed suffix | Formation index | Easy behavior |
| --- | --- | --- | --- |
| Countries | `/c1fdE` | 1 | Filter the source's 12 country IDs and shuffle with `/dE` |
| Clubs | `/CA` | 1 | Filter the source's 16 club IDs; keep the seed |
| Retro | `osaIS3` | 1 | Filter the source's 18 squad IDs, then keep the first season per club |
| Legends | `ofADI` | 0 | Keep the countries, include source records marked active |
| America | `/CA` | 3 | Filter the source's 16 club IDs; keep the seed |

Normal Retro keeps the first squad per distinct club before shuffling. Easy must filter **before** deduplicating; otherwise a selected later season could disappear. Normal Legends excludes `active == "yes"`; Easy includes those records. That marker is an archived source classification, not a current retirement check.

## Identity and eligibility

`selection.catalog` binds the player module, group module and formation module. The reviewed support contracts pin the imported formation component, Countries group component and three imported player wrappers. America contains its player data in its already pinned mode module. Changed executable code or import bindings rejects publication; static table changes remain permitted after schema and relationship validation.

Countries membership uses its own `countryID`; America uses its own `clubID`. The Classic player catalog's `clubID` is a **country key** in Legends. Retro uses explicit squad player IDs, while its squad `clubID` identifies a club. Clubs uses explicit group memberships, not a player's single club field. Bare numeric IDs never cross those catalogs.

Each board's `memberships` preserves explicit CSV order or source player-table order. Players with missing or unsupported position codes are listed in `excludedPositionPlayerIDs` and cannot become valid native picks. The full source player rows remain in the packet. All 11 offers and the formation are retained exactly; a bounded position matching check rejects an unplayable board instead of substituting a different draw.

Retro explicitly rejects repeated players in the source game. The other four source modes do not enforce that constraint; `uniquePlayers` records this difference for native adapters. Timers support no timer, 40, 60 or 90 seconds. Native timers should pause while inactive, preserve remaining time and award no win credit for an expired round.

Portrait crosswalks join only full names unique in both the XI catalog and general portrait catalog after case/accent normalization. Those mappings carry artwork only. Missing portraits should show the offered flag, club or season shirt rather than join a different player by ID. Historical roster membership and positional eligibility remain scoped to the imported source table.

## Verification

An independent Node program receives JSON data only and reconstructs every Normal/Easy group draw, membership list, exclusion list and formation. It never loads or executes downloaded JavaScript. Additional tests prove portrait identity, reject changed support programs and import exports, and exercise unsatisfiable positional pools and Retro uniqueness.

Run `python3 -m unittest discover -s scripts -p test_futbol11_daily.py`. The frozen 2026-10-09 archive remains unchanged; normal live refresh uses separate ignored archives.

## Native play and persistence

The source draw and formation are fixed for the day. Normal/Easy and no timer/40/60/90 seconds are selected before starting and survive relaunch. Search shows the offered flag or shirt above the player results, with the search field directly above the keyboard. Every pitch slot uses the same size; verified player portraits replace offer artwork when available. Search rejects unlisted memberships or positions without inventing a negative career fact.

Saved rounds retain exact offer order, placements, undo history, helped positions, remaining active-play time and won/lost/revealed outcomes. The loader revalidates catalog namespaces, explicit membership lists, position exclusions, unique-name portraits and board relationships. Saved signatures include date, timezone, source identities and portrait rows. A changed draw or catalog cannot restore an old round as today's game.

Only completing all eleven placements awards streak credit, once per saved session. Helped picks and uncompleted offers generate practice gaps. Reveal and timer expiry display an independently solved example XI without converting that example into user placements or awarding a win. A legal dead end stays resumable; undo is available, and help asks the learner to undo when the remaining offers cannot fit.

Core tests cover all ten mode/difficulty combinations, wrong IDs, offer order, positional rejection, timers, saved terminal states, single-win credit and forged catalog relationships. Simulator tests cover all five Normal completions, Easy resume/undo/reveal flows, keyboard-safe search and saved timer loss.
