# Bundesliga curriculum source notes

Verified against the official club pages listed in `content/curriculum-bundesliga.json` on 2026-10-10. Every fact row carries a `sourceKey` and a short evidence statement naming the relevant claim. Stories are original summaries, not copied passages. Competition and career scopes are kept explicit in each fact's `scope`.

## Identity decisions

- Bayern uses existing catalog subjects `entity-lahm` and `entity-schweinsteiger`; this pack adds two new moments lessons for each, beyond their existing career and record lessons. Their added moments focus on captaincy/youth and the 2012/2013 finals/departure, avoiding repeat questions from the existing lessons.
- Dortmund adds `entity-marco-reus` from seed identity `player-187` / `Marco Reus`, and `entity-robert-lewandowski` from `player-18` / `Robert Lewandowski`. Their names match the English game seed identities exactly.
- Leverkusen adds `entity-stefan-kiessling` from `player-386` / `Stefan Kiessling` and `entity-patrik-schick` from `player-11` / `Patrick Schick`. The seed omits the accent in Kiessling and uses Patrick rather than Patrik for Schick; canonical display follows club usage, while `seedName` and aliases preserve the exact seed names.
- The Leverkusen player choices span a retired club-leading scorer and a defining modern scorer. No current-season totals are used. Schick's record facts are bounded to the 2021/22 season; Kiessling's career facts refer to his completed Bayer 04 career.

## Fact-to-source map

`curriculum-bundesliga.json` has the exact statement-level evidence strings. Source groupings are:

- `bayern-history`, `bayern-treble`, `bayern-2013`: Bayern history timeline, the 2012/13 treble chapter, and its 2013–19 milestones. These support the 1974–76 European Cup run, 2012/13 treble and early title clinch, plus the 2015 Wolfsburg match details.
- `bayern-lahm`, `bayern-schwein`, `bayern-cwc`: official Bayern Hall of Fame biographies. Lahm facts cover 517 competitive appearances, eight league titles, 2013 Champions League final, 2011 captaincy, youth move from FT Gern at eleven, and the 2013 Club World Cup final opponent. The Club World Cup claim uses Bayern’s standalone final report; the Hall of Fame page has inconsistent cup-year details. Schweinsteiger facts cover the 2012 Chelsea final, 2013 Wembley win, 17-year Bayern tenure, plus the documented biography details.
- `bvb-history`, `bvb-1997`, `bvb-2009`, `bvb-double`: Dortmund’s official history and match retrospectives. These support the 1995/96 league titles and 1997 European Cup, 2011/12 81-point season and 5–2 cup final, and the 2013 Champions League final.
- `bvb-reus`, `bvb-reus2`: official Dortmund career retrospectives and extension report. The 169 appearances/goals snapshot is explicitly “before the Darmstadt game”; 101 contributions are explicitly the figure in the 2018 extension article. The facts keep those dated snapshots from being presented as career totals.
- `bvb-lewy`, `bvb-lewy103`: Dortmund transfer announcement and its archive of all 103 goals. Team titles and the cup final are supported by `bvb-double`.
- `bayer-history`, `bayer-1988`, `bayer-2024`: Leverkusen anniversary history, UEFA Cup retrospective and 2023/24 season page. These support the 1988 comeback, first league championship, cup count and unbeaten campaign.
- `bayer-kies`: Bayer’s 2026 official legends retrospective. It reports Kießling’s completed career at 443 Werkself appearances and 162 goals in all competitions, including 344 Bundesliga games and 131 league goals. It also dates his end of playing career to May 2018. The earlier age-32 player profile is excluded as a stale snapshot. The current retrospective supports birthplace, Nürnberg transfer, 2006 arrival, 2013 scoring award, final playing year and club representative role.
- `bayer-schick`, `bayer-schick4`, `bayer-schickseason`: official Schick contract announcement, the 4 December 2021 match report, and Bayer’s 17 June 2022 season-award announcement. Career record facts are tied to the completed 2021/22 season; the four-goal match facts point to the 4 December 2021 report.

## Limits

The Reus 2018 goal contribution figure and his 2024 pre-farewell competitive totals are intentionally dated historical snapshots. Bayern's five-goal match source uses the club's reported nine-minute span; the listed goal minutes are 51, 52, 54, 57 and 60. Leverkusen's phrase “first team” for the 1988 unbeaten league season is not used to infer facts about other competitions. The catalog identity for Schick is the seed’s `Patrick Schick`; no numeric identifiers from other datasets are used.

## Independent review corrections

The Bayern 1969/1974–76 claims cite the Golden Years chapter directly rather than the milestone index. Lewandowski’s 2012 team facts cite the Double retrospective, not his 2010 signing. His legacy lesson now distinguishes his 20-cap Poland snapshot at signing and 2009 Polish Cup honour instead of repeating his nationality and contract length. Schick’s career lesson uses his transfer from Roma rather than repeating his 24-goal season; his second-place seasonal rank and 87-minute scoring rate cite the season award article. Kießling’s move is taught at the documented year grain (2006), and his last-matchday goal identifies René Adler rather than attaching an unsupported exact match date. All display fields use strings required by the iOS decoder.

## Integration review, 10 October 2026

Directly opened the 2024 DFB-Pokal final report: it supports Xhaka as scorer, minute 16 and the second cup title. Replaced anniversary trivia and a repeated championship-year question with those final-specific facts. The official season table does not substantiate the old 43-game streak claim; replaced it with the 5–0 title-clinching score. The directly opened season review explicitly confirms 14 April 2024 as the title-clinching date. Reus’s 2018 extension article supports the 2017 final, Frankfurt opponent, injury and 101 dated Bundesliga contributions; his directly opened 2019 award article supports his first award in 2012 and second award in 2019. Removed incorrectly attributed first-goal questions from the final lesson. All changes precede release of version 13.
