# Liga MX curriculum: Tigres, Monterrey and Pachuca

Authored 2026-10-10. This pack adds 33 lessons: three club stories for each club, plus four player-specific lessons for each of six players. Each lesson has three supported questions. Existing club introductory lessons were checked to avoid repeating founding date, stadium, mascot or other intro metadata.

## Club lesson evidence

- **Tigres — early titles** (`next-tigres-titles`, `next-tigres-1982`): the official championship chronology supports the 1977–78 first league title; the club’s 1981–82 final account supports Atlante as opponent and Estadio Azteca as the shootout venue.
- **Tigres — golden era** (`next-tigres-golden-era`): official Tigres retrospective says the era began after the 2010 leadership change and lists the five Liga MX title seasons 2011, 2015, 2016, 2017 and 2019.
- **Tigres — Palmeiras** (`next-tigres-fifa`): FIFA’s match recap supports the 1–0 result, Gignac’s penalty, date, and first Mexican/Concacaf finalist milestone.
- **Monterrey — first title** (`next-rayados-1986`): official Rayados history supports March 1, 1986, Tampico Madero, the 2–0 return win and 3–2 aggregate.
- **Monterrey — continental run** (`next-rayados-history`): official club history supports the 2011–13 Concacaf threepeat and the 2019 fourth title against Tigres.
- **Monterrey — 2019 final** (`next-rayados-2019`): Rayados’ own final account, also indexed in search, supports the 2–1 aggregate, 1–1 return-leg score and Nicolás Sánchez’s goal. Direct page opening intermittently returned an internal retrieval error; the page is the club’s primary account and its indexed text states those facts. The club’s history page independently confirms the 2019 1–1 return leg and final.
- **Pachuca — promotion and first title** (`next-pachuca-history`, `next-pachuca-1999`): official history gives promotion in 1998 and first professional-era title in 1999; the Invierno 1999 final recap names Cruz Azul.
- **Pachuca — Sudamericana** (`next-pachuca-sudamericana`): Pachuca’s official retrospective supports the 2006 title, Colo-Colo opponent and 3–2 aggregate. One matching official page failed direct retrieval; the same article appeared in the official Tuzos search index with its full headline and outcome, and a separately opened official club history also identifies the 2006 Sudamericana as Pachuca’s trophy.
- **Pachuca — 2017 Concacaf final** (`next-pachuca-concacaf`): Concacaf’s match recap supports Tigres as opponent, Franco Jara as scorer, minute 83 and the final result context.

## Player lesson coverage and evidence

### Tigres

- **André-Pierre Gignac**: career route, dated 2006–07 first-division debut at Lorient, Toulouse/Marseille before Tigres and Apertura 2015 arrival; 200th official Tigres goal against León on January 17, 2024 (minute 76); player-specific dated-career snapshot from the 2020 club retrospective (477 first-division games and no red cards through publication); two-goal performance in the February 26, 2020 Alianza match. Sources: `next-tigres-gignac-career`, `next-tigres-gignac200`, `next-tigres-always`.
- **Nahuel Guzmán**: Newell’s development, Independiente Rivadavia loan, Apertura 2014 arrival; 93rd-minute header against Alianza assisted by Eduardo Vargas; 500th official match against Necaxa on May 11, 2025 and club appearance record; dated competition breakdown at that 500-match milestone. Sources: `next-tigres-nahuel`, `next-tigres-always`, `next-tigres-500`.

### Monterrey

- **Humberto Suazo**: Chilean career from Audax Italiano and Colo-Colo to Rayados in 2007; 13-goal Clausura 2008 scoring title and four-goal Veracruz match; 2010 Zaragoza spell and December 2014 exit to Colo-Colo; 121-goal club record and the 2011–13 Concacaf run. Sources: `next-rayados-suazo`, `next-rayados-suazo-4`, `next-rayados-suazo-farewell`, `next-rayados-funes-record`, `next-rayados-history`.
- **Rogelio Funes Mori**: Mendoza, River Plate/Benfica/Eskişehirspor and 2015 arrival; Rayados debut vs Pumas and first official/league goals; April 3, 2021 tie of Suazo’s 121-goal mark against Atlético de San Luis; 160 goals in 328 appearances at departure and his final 160th goal. Sources: `next-rayados-funes-bio`, `next-rayados-funes-goodbye`, `next-rayados-funes-record`.

### Pachuca

- **Hirving Lozano**: Pachuca spell totals of 149 appearances, 43 goals and 28 assists; July 2017 departure to PSV and subsequent move to Napoli; eight-goal Golden Boot and Best Young Player award in the 2016–17 Concacaf competition; Clausura 2016 league title. Sources: `next-pachuca-lozano`, `next-pachuca-lozano-concacaf`. Seed identity verified against `games-en.json`: `player-774`, exact name `Hirving Lozano`.
- **Miguel Calero**: Ginebra, Colombia birthplace; Invierno 2000 arrival and July 30 debut; four Pachuca league titles and five international honours; 2007 SuperLiga shootout save against Landon Donovan in the final against LA Galaxy. Sources: `next-pachuca-calero`.

## Identity, portraits and scope

Hirving Lozano uses the exact matching seed `player-774`. The available `player-2426` seed is **David Suazo**, so it was not attached to Humberto Suazo; Humberto is authored as a separate canonical person. Gignac, Nahuel Guzmán, Humberto Suazo, Rogelio Funes Mori and Miguel Calero have no verified matching seed in the local game catalog and are represented as independent canonical players. Initials are visual fallbacks only; no portrait URL was guessed. Dates and counts are scoped to their cited article’s explicit snapshot rather than presented as live values.

## Editorial limits

The 2020 Gignac appearance/red-card lesson is explicitly historical and date-bounded. Nahuel’s tally is labeled at the May 11, 2025 milestone. Funes Mori’s 160 goals and 328 appearances are tied to his January 2024 farewell. No current-season statistics are asserted. All question choices have one intended answer and three distinct distractors.

## Independent QA review (2026-10-10)

The pack now has the compiler-required **two story screens in every lesson**. Chapter tags make the minimum club and player coverage explicit: each club has one history lesson and two distinct defining moments; each of the six players has career, moment, and records/honours coverage across four lessons. All three facts remain present per lesson, all value displays are strings, and all referenced source keys resolve. The existing starter facts for Monterrey, Pachuca, and Tigres cover founding/origin, debut/venue, or nickname identity; none of the new fact prompts repeats those intro anchors.

Corrections made during this audit:

- **Monterrey 1986 final:** replaced a stray Pachuca–Colo-Colo aggregate question (whose answer was unrelated to the cited Rayados page) with the Rayados return-leg score, 2–0. The directly opened official account records the 2–0 win over Tampico Madero, the 2–1 first-leg loss, and the 3–2 aggregate.
- **André-Pierre Gignac discipline:** replaced a duplicate French-club-path question with the documented 2020 VAR incident. Tigres’ June 10, 2020 article says the referee showed a red card for the challenge on Joaquín Esquivel, then reversed it to a yellow after VAR review. The 477 first-division matches and zero red cards are explicitly a June 2020 snapshot, not a current count.
- **Miguel Calero biography:** replaced a redundant country-of-birth question (the birthplace question already said Ginebra, Colombia) with his source-supported birth date, April 14, 1971.
- **Chapter taxonomy:** the 1981–82 Tigres final, Monterrey’s 1986 first title, and Pachuca’s 2006 Sudamericana lesson are tagged as club moments, giving each club two separate defining-moment lessons. Suazo’s Clausura 2008 scoring achievement is a player moment; his 121-goal mark is tagged records. Funes Mori’s debut/first-goal lesson and Lozano’s 2016 league-title milestone are tagged moments.

### Source access and evidence limits

Directly opened primary pages in this review included Tigres’ 1981–82 final retrospective, its golden-era article, FIFA’s Palmeiras semifinal report, Gignac’s 200th-goal report, the June 2020 discipline article, Nahuel Guzmán’s 500-match article, Rayados’ 1986 first-title article, Funes Mori’s 2015 biography and January 2024 farewell, and Concacaf’s 2017 Pachuca–Tigres final recap. These pages’ body text supports the associated claims at the cited scope. The current official pages do not provide a single uniform snapshot across all of these historic records; every dated total remains tied to its own article date or milestone.

Two relevant official pages returned an access error when opened directly in this review: Concacaf’s Hirving Lozano awards page (`next-pachuca-lozano-concacaf`) and Pachuca’s Miguel Calero retrospective (`next-pachuca-calero`). Their official-site search-index extracts did expose the used facts. The Lozano extract explicitly names the 2016/17 title, eight-goal Golden Boot, and Best Young Player award; the Calero extract explicitly gives his birth date/place, Pachuca arrival/debut, honours, and Donovan penalty save. Treat those specific claims as **official indexed evidence, not a fresh direct-page verification**. The official Pachuca 2006 Sudamericana retrospective also intermittently failed direct opening in the earlier research; its index extract and a separate official club-history reference support the title/opponent/aggregate, and the note above retains that limitation. The 2019 Rayados final source’s direct retrieval was intermittent in prior research; the official history independently confirms the return result/final, while the primary final recap’s indexed text supplies the goal detail.

Identity check: Lozano is bound to the exact `player-774` / `Hirving Lozano` seed. Humberto Suazo remains seedless because the similarly named local seed is **David** Suazo. Gignac, Nahuel Guzmán, Humberto Suazo, Rogelio Funes Mori, and Miguel Calero are independent canonical entries; no portrait URL or false seed match was introduced.

## Integration topic review

Lozano’s aggregate Pachuca totals are now correctly in Records & honours. His Europe route remains Career journey; the final lesson now teaches his Liga MX debut date, América opponent and age, using the directly opened Pachuca debut article (which explicitly distinguishes earlier Copa MX appearances). Calero’s repeated arrival-tournament/captaincy lesson was replaced by his farewell date, Hidalgo stadium and clean sheet, all directly supported by the opened 22 October 2023 official retirement retrospective. The replacement avoids claiming a combined trophy total: that retrospective’s broad ten-title phrase differs from the older detailed honours breakdown.

## Score interaction review

Explicit score answers with already verified club badges now carry score-input metadata for the native two-column number wheels. Prompts identify both teams and the event/date or season; aggregate results are labelled as aggregate. Other opponents remain text choices until their badge identities are verified.

## Final primary-source recheck

Directly reopening the Tigres 500-game article revealed that 11 May 2025 is its publication date, not the date of the Necaxa away leg. Removed that unsupported event-date question and replaced it with the article’s explicit 411 league-and-liguilla appearances from Nahuel’s first 500 official matches. His story identifies the Clausura 2025 quarterfinal rather than assigning a guessed date. Gignac’s repetitive 200-total question is replaced with 175 league-and-liguilla goals out of his first 200 official club goals, directly supported by the club’s 30 January 2024 breakdown. These are dated historical milestones, not current totals.
