# Bundesliga fifth curriculum: source and content notes

This draft adds Borussia Mönchengladbach and FC Augsburg. It contains 22 lessons: three club lessons and four personal lessons for each of two players per club. Every lesson has two short story screens and three separate facts. The claim dates below describe the events or statistical cutoff, while each source’s `verifiedAt` records the 2026-10-10 research date.

## Identity and entity choices

- Club subjects are `entity-borussia-monchengladbach` and `entity-augsburg`, matching the compiled-club slug convention (`borussia-monchengladbach` and `augsburg`).
- `entity-lothar-matthaus` is bound to the exact game seed `player-38`, whose seed name is `Lothar Matthaus`. The curriculum display uses the proper German spelling; the seed spelling is preserved verbatim.
- Günter Netzer, Helmut Haller, and Daniel Baier have no exact player seed in `Foxlingo/Resources/games-en.json`. They are declared as independent canonical player identities with no seed IDs or images. No portrait identity is inferred.

## Borussia Mönchengladbach

**Club history — `gladbach-history`:** The opened Bundesliga historical guide gives the club’s Bundesliga seasons as beginning in 1965; it reports 57 seasons in the league in its 10 July 2023 snapshot; and it identifies Berti Vogts as the appearance leader with 419. These are dated league history and records, not a repeat of the existing starter’s title-count introduction.

**1977/78 record win — `gladbach-titles` and `gladbach-history`:** The opened Bundesliga season review supports 29 April 1978, the five Jupp Heynckes goals, and Cologne’s three-goal final goal-difference edge after its concurrent 5–0 win. The club guide independently identifies the result as 12–0 and the largest Bundesliga win. Fact keys: `bmg-12-0-date`, `bmg-12-0-scorer`, `bmg-12-0-margin`.

**1977 European Cup final — `gladbach-europe`, `gladbach-history`:** The opened UEFA match account supplies the 25 May 1977 date, 3–1 result, Rome venue, and scoring sequence; the league guide independently verifies Gladbach’s final appearance. Fact keys: `bmg-europe-final-date`, `bmg-europe-final-score`, `bmg-europe-venue`.

**Günter Netzer career — `netzer-dfb`, `netzer-dfb-bio`, `netzer-euro`:** DFB’s opened Datencenter profile lists Borussia dates 1 July 1963–30 June 1973, 269 club matches, and 37 senior caps. UEFA’s opened Netzer article says he negotiated a move to Real Madrid in early 1973. Fact keys: `netzer-career-years`, `netzer-career-appearances`, `netzer-career-next`.

**Netzer’s 1973 cup final — `netzer-dfb`, `netzer-euro`:** The DFB match log records the 23 June 1973 final, Cologne as opponent, and Gladbach’s 2–1 extra-time win. UEFA’s article describes Netzer entering after Christian Kulik’s injury and scoring the winner. Fact keys: `netzer-cup-date`, `netzer-cup-opponent`, `netzer-cup-score`.

**Netzer at Wembley and EURO 1972 — `netzer-dfb-bio`, `netzer-euro`:** DFB directly identifies 29 April 1972, England, the 3–1 score, and Netzer’s central role. UEFA says he later played a part in Germany’s wins over Belgium and the Soviet Union that secured the European title. Fact keys: `netzer-wembley-date`, `netzer-wembley-opponent`, `netzer-euro-title`. The Netzer DFB biography is opened at https://www.dfb.de/news/detail/der-spielmacher-der-wembley-elf-guenter-netzer-wird-80-264352 and supports the 21-minute 1974 World Cup appearance claim.

**Netzer honors and 1974 World Cup role — `netzer-dfb`, `netzer-dfb-bio`:** DFB’s profile lists Germany Footballer of the Year in 1971/72 and 1972/73, plus 37 senior caps. The opened DFB birthday profile says his only appearance at the 1974 World Cup was a 21-minute group-stage appearance against East Germany. The lesson now covers the second award season only once and uses the 21-minute personal milestone as its distinct third fact. Fact keys: `netzer-award-first`, `netzer-world-cup-minutes`, `netzer-caps`.

**Lothar Matthäus career — `matthaus-dfb`, `matthaus-dfb-bio`:** DFB’s opened Datencenter table records 185 Gladbach appearances from 1 July 1979 to 30 June 1984 (162 in the Bundesliga) and Bayern from 1 July 1984. DFB’s biography says his professional career began in Mönchengladbach in 1979. Fact keys: `matthaus-first-pro`, `matthaus-gladbach-appearances`, `matthaus-next-club`.

**Matthäus in the 1990 opener — `matthaus-match`, `matthaus-dfb-bio`:** DFB’s opened match record lists Germany 4–1 Yugoslavia on 10 June 1990. The DFB profile says Matthäus scored the 3–1 after a long run and that the match was his 75th cap. Fact keys: `matthaus-yugo-score`, `matthaus-yugo-goal`, `matthaus-yugo-cap`.

**Matthäus and the 1990 final — `matthaus-dfb-bio`:** DFB dates Germany’s 1–0 win over Argentina and Matthäus’s trophy lift as captain to 8 July 1990. Fact keys: `matthaus-final-date`, `matthaus-final-opponent`, `matthaus-final-score`.

**Matthäus’s personal records and awards — `matthaus-dfb-bio`:** DFB reports 150 caps, 75 captaincies, the 1990 German/European/world player awards, and that he defended the world award in 1991. Fact keys: `matthaus-caps`, `matthaus-captaincy`, `matthaus-world-award-defense`.

## FC Augsburg

**Club history — `augsburg-history`:** The opened English club timeline dates the FC Allemania foundation to 8 August 1907, lists first competitive matches in the Donaugau B-Class in 1910, and says the BCA adopted the FC Augsburg name after the 1969 football merger with TSV 1847 Schwaben Augsburg. Fact keys: `fca-history-founded`, `fca-history-first-games`, `fca-history-merger-name`.

**First Bundesliga promotion — `augsburg-promo`:** The opened official match retrospective confirms 8 May 2011, the 2–1 home win over FSV Frankfurt, and Stephan Hain’s 85th-minute winner. Fact keys: `fca-promotion-date`, `fca-promotion-score`, `fca-promotion-winner`.

**European exit at Liverpool — `augsburg-europa`:** UEFA’s opened report records the 25 February 2016 second leg, James Milner’s fifth-minute penalty, Liverpool’s 1–0 result, and 1–0 aggregate elimination after a 0–0 first leg. Fact keys: `fca-liverpool-date`, `fca-liverpool-penalty`, `fca-liverpool-aggregate`.

**Helmut Haller career — `haller-bio`:** FCA’s opened biography says Haller was born in Augsburg on 21 July 1939, joined BC Augsburg at age nine, scored his first senior goal at Offenbacher Kickers in 1957, moved to Bologna in 1962, moved to Juventus in 1968, and returned in 1973. Fact keys: `haller-career-born`, `haller-career-youth`, `haller-career-italy`.

**Haller’s 1966 final — `haller-bio`:** The opened FCA account gives the 30 July date, his 12th-minute opening goal, and England’s 4–2 extra-time victory. It also says Haller scored six times at the tournament, second behind Eusébio. Fact keys: `haller-wembley-date`, `haller-wembley-minute`, `haller-wembley-score`.

**Haller’s Bologna season — `haller-seriea`:** The opened FCA account says he played every minute of all 34 matches, scored seven goals, and became the first foreign Serie A player named Italy’s Footballer of the Year in 1964. Fact keys: `haller-bologna-games`, `haller-bologna-goals`, `haller-bologna-award`. A separate club article gives a conflicting Bologna career-goal total (57 vs 58), so no career-total goal claim is used here.

**Haller’s return — `haller-homecoming`, `augsburg-history`:** FCA’s opened retrospective dates the return from Juventus to summer 1973, gives Haller ten goals in the 1973/74 Regionalliga Süd title season, and says the promotion-round finish was behind Tennis Borussia Berlin. It does not establish the margin, so the story does not say Augsburg missed promotion by one point. Fact keys: `haller-return-year`, `haller-return-goals`, `haller-return-runnerup`.

**Daniel Baier career — `baier-career`, `baier-record`:** FCA dates the loan from Wolfsburg to the 2008/09 season and permanent signing to January 2010. The DFB profile lists his earlier TSV 1860 spell from July 2003 to June 2007. Fact keys: `baier-career-first`, `baier-career-loan`, `baier-career-permanent`.

**Baier debut — `baier-milestone`:** The opened FCA milestone feature specifies 14 September 2008, SC Freiburg, a 3–1 second-division defeat, and Baier’s FCA debut. Fact keys: `baier-debut-date`, `baier-debut-opponent`, `baier-debut-score`.

**Baier’s 300th Augsburg appearance — `baier-bremen`:** The opened FCA match report says Augsburg came back from 2–0 down to level Werder before losing 3–2, and identifies the match as Baier’s 300th club appearance and 250th Bundesliga appearance. Fact keys: `baier-bremen-opponent`, `baier-bremen-score`, `baier-bremen-double-milestone`.

**Baier’s Augsburg records — `baier-record`, `baier-career`:** DFB lists 355 Augsburg matches in all competitions and 274 Augsburg Bundesliga appearances through 17 June 2020; FCA identifies him as its record Bundesliga appearance maker at departure. A contemporaneous FCA item before the final two league rounds gives 272 Augsburg Bundesliga appearances, so the curriculum uses the later DFB total with its end date rather than mixing those snapshots. Fact keys: `baier-record-total`, `baier-record-league`, `baier-record-rank`.

## Retrieval and factual limitations

- The source pages listed in the JSON were opened and their substantive body text reviewed. The DFB Datencenter match pages can be unreliable for direct retrieval; where a match record was used, the DFB page displayed its result in the retrieved record, and corroborating DFB or UEFA narrative material was also opened where available.
- The Netzer cup-final goal detail is supported by UEFA’s opened 1972 EURO profile; the DFB Datencenter separately verifies date, opponent, and score. This draft does not assert that Netzer literally self-substituted himself; UEFA’s wording instead describes his return to the pitch after the coach’s plan and a teammate’s injury.
- Player portraits remain unassigned for Netzer, Haller, and Baier because no verified exact seed is present. Matthäus uses only the exact `player-38` seed match.
- The Augsburg league appearance total is explicitly bounded to the DFB profile’s final date. It is not presented as a timeless live count. Netzer’s 1974 World Cup minute count uses the DFB’s 14 September 2024 birthday profile, which directly states his sole appearance lasted 21 minutes.
- Numeric counts and elapsed-minute facts use numeric `value.number` with a meaningful unit; dates, scores, seasons, and named outcomes remain text. Prompts identify their player, match, competition, or season so they can be reviewed out of lesson order.

## Final integration visual review

Five match-score facts use native score wheels and canonical club badges, including the Liverpool aggregate result explicitly identified as aggregate in the question. Correct club choices and distractors use canonical clubs with cached badges. The existing Bologna badge is linked to a supporting club entity, without inventing a Bologna roadmap. England and Argentina choice questions use flag answers. Matthäus uses only his exact reviewed `player-38` portrait; the other three independent identities retain no guessed images.
