# Bundesliga sixth pack — source and QA notes

Verified on 2026-10-11. This unregistered pack covers Hoffenheim and Union Berlin. It contains 22 lessons, with three club lessons per club and four lessons for each of Kramarić, Süle, Kruse and Awoniyi. Every lesson has two story screens and three facts.

## Hoffenheim

**Club history — `lesson-curriculum-hoffenheim-rise`:** The directly opened Bundesliga historical guide supports Hoffenheim’s 1899 origins as a gymnastics club, its promotion to the Bundesliga in 2008, and its position at the top of the table at the midpoint of its maiden Bundesliga season. Facts: `hoffenheim-history-founded`, `hoffenheim-history-promotion`, `hoffenheim-history-midseason`. The previous lower-tier detail depended on a TSG PDF URL that returned 404; those exact tier claims were removed.

**2017 first Bundesliga win over Bayern — `lesson-curriculum-hoffenheim-first-bayern-win`:** FC Bayern’s directly opened match report dates the 1–0 result to 4 April 2017, identifies Andrej Kramarić as the 21st-minute scorer, and calls it Hoffenheim’s first-ever Bundesliga victory over Bayern. Facts: `hoffenheim-bayern-date`, `hoffenheim-bayern-score`, `hoffenheim-bayern-goal`.

**2013 relegation play-off — `lesson-curriculum-hoffenheim-relegation-playoff`:** The Bundesliga’s directly opened results table records Hoffenheim’s 5–2 aggregate win over Kaiserslautern (3–1, 1–2) in 2012/13. Facts: `hoffenheim-playoff-opponent`, `hoffenheim-playoff-aggregate`, `hoffenheim-playoff-second-leg`.

**Andrej Kramarić’s arrival:** The Bundesliga profile supports his loan from Leicester on 20 January 2016 and five goals in his first 15 Hoffenheim appearances. The quantity is stored as five goals. Facts: `kramaric-loan-date`, `kramaric-first-loan-source`, `kramaric-first-15`.

**Kramarić’s Gladbach hat-trick:** Bundesliga Matchday 17 coverage gives Hoffenheim’s 5–1 win, the first-half treble, and goals at 22, 45+1 and 45+4 minutes. DFB’s directly opened 2025/26 schedule confirms the match date, 14 January 2026. Facts: `kramaric-gladbach-date`, `kramaric-gladbach-score`, `kramaric-gladbach-minutes`.

**Kramarić’s personal league records:** The dated 17 January 2026 Bundesliga profile records 13 league goals in 2017/18 and a best-season output of 20 in 2020/21. The third fact now uses the directly readable Bundesliga match report: on 27 June 2020, Kramarić scored all four goals in Hoffenheim’s 4–0 win at Borussia Dortmund. Facts: `kramaric-2017-18-goals`, `kramaric-best-season`, `kramaric-dortmund-four-goals`.

**Kramarić for Croatia:** The January 2026 Bundesliga profile is the dated source for 112 senior caps and 36 goals. UEFA’s European Qualifiers profile lists eight appearances and six goals in the 2026 qualifying campaign. UEFA’s Croatia report lists the eight Group L qualifying fixtures. The January 2026 Bundesliga profile’s ten-match qualifier figure conflicts with UEFA’s competition-specific count; this curriculum follows UEFA’s count of eight for the 2026 European qualifying campaign, rather than treating the broader Bundesliga figure as this cycle’s total. Facts: `kramaric-croatia-caps`, `kramaric-croatia-goals`, `kramaric-croatia-qualifiers`. The former “all ten qualifiers” count was incorrect and has been replaced with eight.

**Niklas Süle’s Hoffenheim-to-Bayern path:** The directly opened DFB player profile records his Hoffenheim Bundesliga spell beginning 11 May 2013, 108 Hoffenheim Bundesliga appearances, and Bayern beginning 1 July 2017. These are league appearances for Hoffenheim, not total club matches. Facts: `sule-hoffenheim-debut`, `sule-hoffenheim-league-apps`, `sule-next-club`.

**Süle’s Germany debut:** The DFB Datencenter international competition page records his first senior Germany appearance against Finland on 31 August 2016, a 2–0 win. This replaces youth-semifinal and injury details that depended on a TSG page returning 403. Facts: `sule-debut-date`, `sule-debut-opponent`, `sule-debut-score`.

**Süle’s international record and honours:** Through Süle’s last DFB-listed senior match on 18 October 2023, DFB lists 49 senior Germany caps and one senior goal; its competition breakdown lists four 2017 Confederations Cup appearances. The honours lesson uses only club titles: five German championships, two DFB Cups, and the 2019/20 Champions League. Olympic match counts/medals and a duplicated Confederations Cup-honour prompt were removed. Facts: `sule-confed-apps`, `sule-germany-goals`, `sule-germany-caps`, `sule-bundesliga-titles`, `sule-dfb-cups`, `sule-champions-league`.

## Union Berlin

The Union history, promotion, first-win, player-transfer, and match-report sources in the JSON remain the official club pages used for the existing lessons. The facts stay scoped to their reported events and departure snapshots.

**Awoniyi transfer date:** `awoniyi-permanent-date` now cites the permanent-signing announcement, dated 20 July 2021, rather than the prior loan-arrival story.

**Awoniyi at Mainz:** Union’s match report says the 69th-minute opener marked the club’s 100th Bundesliga goal; his second goal came at 73 minutes. The prompt and story now assign the milestone to the first goal. Facts: `awoniyi-mainz-date`, `awoniyi-mainz-minutes`, `awoniyi-mainz-milestone`.

## Source access and factual limits

The failed TSG sustainability-PDF, stadium-history article and interview claims have been removed. Hoffenheim history now comes from the readable Bundesliga historical guide; its two defining match courses use the directly opened FC Bayern match report and Bundesliga relegation-results table. Süle’s path uses the DFB player profile and club-statistics page; his debut, international figures and honours use the broadened DFB Datencenter senior Germany match and competition page. Its last listed senior appearance is the 2–2 match against Mexico on 18 October 2023; 49 caps and one goal are therefore reported as a completed historical total through that date, not as a current 2026 count. UEFA’s Kramarić qualifier statistics page and Croatia qualifying overview were directly opened. The remaining Union sources were retained from the earlier source review; the permanent signing and Mainz match reports were directly opened.

The UEFA profile is a competition-specific player stat page, so its eight matches and six goals refer to European qualifying, not all Croatia internationals. Kramarić’s 112 caps and 36 goals are explicitly bounded to the January 2026 Bundesliga profile snapshot. Süle’s 49 caps/one goal are bounded to DFB’s last listed senior match on 18 October 2023. Awoniyi’s 25 Union goals and 65 appearances are the club’s departure snapshot; his 15 goals are Bundesliga-only for 2021/22.

## Identity and structure

Player seed identities remain exact name-and-seed pairs from the game catalog: Andrej Kramaric → `player-1461`; Niklas Sule → `player-646`; Maximilian Kruse → `player-1462`; Taiwo Awoniyi → `player-1984`. Display spellings retain the existing pack’s diacritic convention; no substring-based IDs or new portrait URLs were added. Club subjects remain `entity-hoffenheim` and `entity-union-berlin`.

The revised pack retains 22 lessons and 66 facts. Fact and lesson keys are globally unique within the pack, every source key resolves, all lessons retain two story screens and three facts, and all count-valued facts use number values with explicit units. Scores, dates and season labels remain text values. Distractors are distinct per fact.

## Integration review — 11 October 2026

The 2013 play-off return result is Kaiserslautern 1–2 Hoffenheim: Hoffenheim won both legs and the aggregate was 5–2. The story and accepted score orientation have been corrected together. Bülter’s two-goal question now has numeric distractors. Kruse’s winner is identified as the second minute of stoppage time, not an unqualified minute 2. The Finland debut answer and all distractors use cached flags; score inputs and canonical club answers use badges. Supporting Kaiserslautern, Jena and Bochum entities illustrate the current badge, without claiming a historic-season image or adding a roadmap.
