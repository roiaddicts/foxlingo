# Bundesliga batch 2 research notes

Verified 2026-10-10. The pack contains three club courses and four player-specific lessons for each selected player. Every lesson has two story screens and three facts. Each fact carries its source key, scope, and evidence text in the JSON.

## Identity and portrait decisions

Player keys and seed identities were checked against `Foxlingo/Resources/games-en.json`; the numeric seed IDs are retained only as reviewed catalog IDs, not used to join unrelated datasets. The six selected players are Timo Werner (`player-461`), Emil Forsberg (`player-13`), Luka Jović (`player-153`), Filip Kostić (`player-1172`), Mario Gomez (`player-310`), and Jürgen Klinsmann (`player-1544`, catalog spelling `Jurgen Klinsmann`). Their display aliases preserve the proper accents while `seedName` retains the exact catalog spelling. Card visuals use initials; no independent portraits were added.

Frankfurt’s Alexander Meier and Bernd Hölzenbein were considered, but the Jović and Kostić courses had stronger four-lesson source coverage and reviewed seed matches.

## Leipzig claim corrections and source checks

- Leipzig club history now uses the directly opened Bundesliga historical guide (`rbl-club`). It supports that the team began playing in 2009, reached the Bundesliga in 2016 after seven seasons, and had four promotions in that span. The lesson uses the first three points and avoids treating “founded” and “began playing” as interchangeable.
- Leipzig’s first Bundesliga home win over Dortmund is sourced to the directly opened Bundesliga rivalry retrospective (`rbl-first-home`), which identifies 10 September 2016, Naby Keïta’s late goal, and the 1–0 score.
- The Atlético match lesson now cites UEFA’s directly opened match report (`rbl-olmo`): Leipzig beat Atlético 2–1 on 13 August 2020 and reached its first Champions League semi-final. The earlier RB Leipzig article URL was a client-side shell and was removed from this lesson.
- Werner’s DFB-Pokal quarter-final against Dortmund uses the directly opened DFB report (`rbl-dortmund`), which confirms the 5 April 2023 date, 22nd-minute opener, 2–0 score, and semi-final qualification.
- The prior Werner record course used an 8 January 2024 RB Leipzig client-shell page. It has been replaced by Chelsea’s directly opened 2021/22 report (`rbl-werner-records`): 37 all-competition appearances, 11 all-competition goals, and the club’s then-fastest Champions League goal at 1:23 against Zenit. This is explicitly scoped to that season/article.
- The prior Werner honours lesson incorrectly credited him with Leipzig’s 2022 DFB-Pokal title, although he was at Chelsea then. It now covers his Leipzig title in 2022/23 only. The DFB player profile (`rbl-werner-profile`) lists him as a 2022/23 cup winner; the directly opened DFB final report (`rbl-werner-final`) confirms Leipzig beat Eintracht Frankfurt 2–0 on 3 June 2023.
- Werner’s career facts now trace the route from VfB Stuttgart to Leipzig in 2016 (`rbl-werner-career`), then a 2020 Chelsea transfer and a January 2024 loan to Tottenham (`rbl-werner-spurs`). Both pages were directly opened.
- Forsberg’s career and departure snapshot use the directly opened New York Red Bulls transfer announcement (`rbl-fors`). It dates his Leipzig arrival to 2015, says the club was in the 2. Bundesliga, and reports nine seasons, 324 appearances, 71 goals, and 68 assists as of 16 December 2023.
- Forsberg’s defining moment now uses UEFA’s directly opened 13 September 2017 matchday report (`rbl-fors-ucl`): he scored Leipzig’s first Champions League goal against Monaco in a 1–1 draw.
- Forsberg’s honours lesson uses the directly opened DFB player profile (`rbl-forsberg-dfb`), which lists 2021/22 and 2022/23 as his DFB-Pokal-winning seasons.

Official Forsberg accounts disagree on his assist total: RB Leipzig’s shell-rendered farewell page says 69, while New York’s directly opened transfer announcement says 68. This pack uses the latter article’s 68, labels it as that dated report’s figure, and makes no “club record” claim from the conflicting totals. New York’s February 2024 captain announcement also says 325 appearances, while the December 2023 transfer report says 324; the pack keeps the December report’s dated total and does not call it a final/current number.

## Other clubs and player courses

Eintracht history and 1959, 1980, and 2022 title lessons cite the club’s official history and trophies page (`ef-history`), opened and checked for final score, match dates, away-goal resolution, and shootout result. Jović’s 2017/18 entry, 2018/19 league/Europa totals and 2018 five-goal match cite the club’s purchase and loan-return accounts (`ef-jovic`, `ef-jret`). Kostić’s 2018 arrival, 2019 permanent transfer, 2022 Juventus departure totals, Barcelona second-leg contribution, and 2021/22 Europa League awards use the club’s departure and season-review articles (`ef-kostic`, `ef-numbers`). Prompts scope stats to their league, competition, season, or dated departure source.

VfB history and the 1984 and 1992 championships cite the club’s official history and chronicle (`vfb-history`, `vfb-1984`, `vfb-1992`). Gomez’s career figures and 2007 title use his 2020 retirement retrospective (`vfb-gomez`); the 2009 four-goal match uses the club’s home-game record page (`vfb-four`). Klinsmann’s breakthrough, overhead kick, and five-goal match use VfB’s retrospective (`vfb-klinsi`); the 1987/88 scoring crown and 1988 German Footballer of the Year award use the club’s 60th-birthday account (`vfb-klinsi60`). These VfB sources were directly opened and checked.

## QA

The 33 lessons contain 99 facts; each has exactly three distinct distractors, a resolvable source key, and two story screens. Club match scores and European progress claims are assigned to the correct single match or competition round. Forsberg’s club stats are dated to his transfer announcement. Werner’s 2022/23 title is separated from Leipzig’s 2021/22 win while he played for Chelsea. Frankfurt and Stuttgart facts were checked against their cited opened official sources. No current-season statistics are used.

## Integration check

The two club-moment lessons initially reused fact keys. Before release, their keys were namespaced by lesson so the compiler can preserve each event as a distinct memory. Source-backed claims are unchanged.

## Integration topic review

Gomez’s Career journey now teaches the Fiorentina/Wolfsburg route and the official profile’s 1 January 2018 second-spell start. His 168 VfB/328 whole-Bundesliga appearance totals are filed as records, and the 78 VfB league-goal total cites the profile’s career table. The honours lesson now covers his 2007 individual award and 2015/16 Turkish scoring crown (26 goals), instead of repeating retirement/club-route details. Both the VfB portrait and 29 June 2020 retirement article were directly opened. December 2017 announcement wording is kept distinct from the profile’s January 2018 start date. Unsupported `honours` chapter values were normalized to `records` before release.

## Score interaction review

Explicit score answers with already verified club badges now carry score-input metadata for the native two-column number wheels. Prompts identify both teams and the event/date or season; aggregate results are labelled as aggregate. Other opponents remain text choices until their badge identities are verified.

## Standalone review prompts

Ambiguous pronouns and unscoped questions now identify the player/club, event and season. Departure statistics use their published snapshot, especially Forsberg’s December 2023 New York announcement and Kostić’s August 2022 Frankfurt departure. These prompts remain understandable when spaced review mixes different courses.
