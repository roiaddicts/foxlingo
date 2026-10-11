# Manchester United and Villarreal curriculum notes

Reviewed: 2026-10-11. This pack contains 22 lessons: 3 club lessons per club, plus 4 player lessons each for Wayne Rooney, Paul Scholes, Diego Forlán, and Marcos Senna. Every lesson has two story screens and exactly three facts. Every display is a string, with typed text or number values; every fact has three distinct distractors.

## Identity and seed choices

- Club subjects: `entity-manchester-united` and `entity-villarreal`. Villarreal is present in the player catalog; Manchester United is confirmed in the club draft.
- Player seeds were checked against the supplied `Foxlingo/Resources/games-en.json` records: Wayne Rooney → `player-63` / `Wayne Rooney`; Paul Scholes → `player-349` / `Paul Scholes`; Diego Forlán → `player-31` / exact seed name `Diego Forlan`; Marcos Senna → `player-627` / `Marcos Senna`. The canonical Forlán display keeps the accent and includes the exact seed spelling as an alias.
- Each seed’s full name exactly matches the named player in the opened primary club biography or official player page, and each biography supports the player’s association with the club path. The `visual` initials are based on the verified names, not a guessed portrait. The pack does not bind the separate classic-namespace duplicate IDs.

## Source register

- `curriculum-uv-united-origin` — [Manchester United history by decade: 1878–1909](https://www.manutd.com/en/club/history/history-by-decade/1878-1909) (verified 2026-10-11).
- `curriculum-uv-united-1950s` — [Manchester United history by decade: 1950–1959](https://www.manutd.com/en/club/history/history-by-decade/1950-1959) (verified 2026-10-11).
- `curriculum-uv-united-2013` — [United 3 Aston Villa 0: 22 April 2013 highlights](https://www.manutd.com/en/mutv/videos/detail/man-utd-3-aston-villa-0-extended-highlights-premier-league-2012-13) (verified 2026-10-11).
- `curriculum-uv-rooney-career` — [Why Wayne Rooney decided to sign for United](https://www.manutd.com/en/news/utd-podcast-why-wayne-rooney-decided-to-sign-for-man-utd?t=y) (verified 2026-10-11).
- `curriculum-uv-rooney-city` — [How to watch United 2–1 Man City in full](https://www.manutd.com/en/news/web-watch-live-stream-man-utd-2-man-city-1-from-12-february-2011) (verified 2026-10-11).
- `curriculum-uv-scholes-debut` — [Manchester United youth team debutants](https://www.manutd.com/en/academy/youth-team-debutants) (verified 2026-10-11).
- `curriculum-uv-scholes-port-vale` — [Goal of the Day: Scholes v Port Vale](https://www.manutd.com/en/mutv/videos/detail/goal-of-the-day-21-september-2021-paul-scholes-v-port-vale) (verified 2026-10-11).
- `curriculum-uv-scholes-barcelona` — [Highlights: Man United 1 Barcelona 0, 29 April 2008](https://www.manutd.com/en/mutv/videos/detail/highlights-of-man-united-1-barcelona-0-at-old-trafford-on-29-april-2008) (verified 2026-10-11).
- `curriculum-uv-scholes-bradford` — [Scholesy’s take on the Valley Parade volley](https://www.manutd.com/en/news/paul-scholes-says-bradford-volley-was-unrehearsed) (verified 2026-10-11).
- `curriculum-uv-villarreal-history` — [Villarreal CF Foundation and history](https://villarrealcf.es/en/fundacion/) (verified 2026-10-11).
- `curriculum-uv-villarreal-arsenal` — [Arsenal joy as Villarreal pay price](https://www.uefa.com/uefachampionsleague/news/01b4-0ea859ad425c-8a4fa7bab58c-1000--arsenal-joy-as-villarreal-pay-price/) (verified 2026-10-11).
- `curriculum-uv-villarreal-final` — [Villarreal 1–1 Manchester United: 2021 Europa League final](https://www.uefa.com/uefaeuropaleague/news/0269-125f1aaaeb0d-c59e8a06ac14-1000--highlights-2021-final/) (verified 2026-10-11).
- `curriculum-uv-forlan` — [Forlán, a golden goalscorer](https://villarrealcf.es/en/forlan-a-golden-goalscorer/) (verified 2026-10-11).
- `curriculum-uv-senna-career` — [Eternal captain Marcos Senna](https://villarrealcf.es/en/eternal-captain-marcos-senna/) (verified 2026-10-11).
- `curriculum-uv-senna-records` — [Marcos Senna returns to Villarreal CF](https://villarrealcf.es/en/marcos-senna-returns-to-villarreal-cf/) (verified 2026-10-11).
- `curriculum-uv-rooney-unveiled` — [Wayne Rooney unveiled as a Manchester United player in 2004](https://www.manutd.com/en/mutv/videos/detail/mutv-archive-wayne-rooney-unveiled-as-a-man-utd-player-in-2004) (verified 2026-10-11).
- `curriculum-uv-pl-rooney-total` — [PFA: Wayne Rooney retires](https://www.thepfa.com/news/2021/1/15/wayne-rooney-retires) (verified 2026-10-11).
- `curriculum-uv-pl-rooney-record` — [Premier League: Rooney breaks two records with goal at Stoke](https://www.premierleague.com/en/news/314752) (verified 2026-10-11).
- `curriculum-uv-pl-scholes-profile` — [Premier League Hall of Fame: Paul Scholes](https://www.premierleague.com/en/events/hall-of-fame/inductees/paul-scholes) (verified 2026-10-11).
- `curriculum-uv-rooney-fener-uefa` — [UEFA: Rampant Rooney starts in style](https://www.uefa.com/uefachampionsleague/news/01a1-0e6b1d358b17-67dccbc7e97c-1000--rampant-rooney-starts-in-style/) (verified 2026-10-11).
- `curriculum-uv-scholes-comeback` — [Manchester United history by decade: 2010 onwards](https://www.manutd.com/en/club/history/history-by-decade/2010-onwards) (verified 2026-10-11).
- `curriculum-uv-forlan-es` — [Forlán, a golden goalscorer (Spanish profile)](https://villarrealcf.es/es/forlan-un-goleador-de-oro/) (verified 2026-10-11).
- `curriculum-uv-senna-spain` — [Red and yellow](https://villarrealcf.es/en/red-and-yellow/) (verified 2026-10-11).

## Fact-by-fact evidence

Each bullet lists the fact prompt, canonical answer, source key, and the evidence statement stored with that fact.

### A railway works side becomes United (`history`)

- **At which division level did Newton Heath enter the Football League in 1892?** Answer: **Division One**. Source `curriculum-uv-united-origin`. The club history says Newton Heath entered the Football League in 1892 at Division One level.
- **In what year was the Manchester United name adopted after the club was saved from extinction?** Answer: **1902**. Source `curriculum-uv-united-origin`. Manchester United’s official chronology says John Henry Davies invested in the financially troubled Newton Heath and the club became Manchester United in April/May 1902.
- **Which season brought Manchester United its first league championship?** Answer: **1907/08**. Source `curriculum-uv-united-origin`. The club’s 1878–1909 history records its first league title in 1907/08.

### The Babes’ last match on English soil (`moments`)

- **Which London club did United beat at Highbury in the Babes’ final match on English soil?** Answer: **Arsenal**. Source `curriculum-uv-united-1950s`. The club’s history names Arsenal as the opponent at Highbury on 1 February 1958.
- **How many spectators watched the 1 February 1958 Highbury match?** Answer: **63,578**. Source `curriculum-uv-united-1950s`. The club history gives the crowd as 63,578.
- **How many goals were scored in the Highbury match that United won before travelling to Belgrade?** Answer: **Nine**. Source `curriculum-uv-united-1950s`. The official club account describes the 5–4 game as a nine-goal thriller.

### Van Persie seals the twentieth (`moments`)

- **On what date did United clinch the 2012/13 title by beating Aston Villa?** Answer: **22 April 2013**. Source `curriculum-uv-united-2013`. Manchester United’s match page dates the 3–0 Villa win to 22 April 2013.
- **What was the score when Manchester United clinched the title against Villa?** Answer: **3–0**. Source `curriculum-uv-united-2013`. The official match title and highlights give the result as United 3, Aston Villa 0.
- **Which United player scored the hat-trick that night?** Answer: **Robin van Persie**. Source `curriculum-uv-united-2013`. The club states that Robin van Persie scored the hat-trick on the night United were crowned champions for a 20th time.

### A teenage signing makes an instant impact (`career`)

- **In what year did Wayne Rooney sign for Manchester United from Everton?** Answer: **2004**. Source `curriculum-uv-rooney-career`. Rooney’s United podcast says he signed in 2004 and discusses his decision to choose the club.
- **How old was Rooney when he joined United in 2004?** Answer: **18**. Source `curriculum-uv-rooney-unveiled`. United’s 2004 unveiling video identifies Rooney as 18 when he signed; its signing feature confirms the 2004 transfer.
- **How many goals did Rooney score in all competitions for United in 2004/05?** Answer: **17**. Source `curriculum-uv-rooney-career`. The United podcast says he added 14 after his debut treble to finish as the team’s prime marksman with 17.

### Three goals on debut (`moments`)

- **When did Rooney make his Manchester United debut against Fenerbahçe?** Answer: **28 September 2004**. Source `curriculum-uv-rooney-fener-uefa`. The official United match feature identifies 28 September 2004 as Rooney’s debut and hat-trick match.
- **What was the final score in Rooney’s Champions League debut against Fenerbahçe?** Answer: **6–2**. Source `curriculum-uv-rooney-fener-uefa`. UEFA identifies the match as Manchester United 6–2 Fenerbahçe.
- **How many goals did Rooney score in that first United appearance?** Answer: **Three**. Source `curriculum-uv-rooney-fener-uefa`. UEFA says Rooney scored a debut hat-trick and describes the free-kick that completed it.

### The derby overhead kick (`moments`)

- **Which local rival did United beat when Rooney scored his famous overhead kick in 2011?** Answer: **Manchester City**. Source `curriculum-uv-rooney-city`. The official United match retrospective identifies the goal as Rooney’s effort against Manchester City.
- **What was the score in the 2011 Manchester derby decided by Rooney’s overhead kick?** Answer: **2–1**. Source `curriculum-uv-rooney-city`. The club’s account calls it a 2–1 United win.
- **What kind of strike did Rooney use for his winning goal against City?** Answer: **Overhead kick**. Source `curriculum-uv-rooney-city`. United’s goal retrospective explicitly describes the effort as an overhead kick.

### United’s all-time leading scorer (`records`)

- **When did Rooney score his record-breaking 250th goal for United?** Answer: **21 January 2017**. Source `curriculum-uv-pl-rooney-record`. The Premier League dates the event to 21 January 2017 and reports that his 250th United goal made him the club’s record scorer.
- **How many goals did Rooney score in his 559 Manchester United appearances?** Answer: **253**. Source `curriculum-uv-pl-rooney-total`. The PFA records Rooney’s 2017 departure with 253 goals in 559 appearances for United.
- **Whose club scoring record did Rooney pass to become United’s leading scorer?** Answer: **Sir Bobby Charlton**. Source `curriculum-uv-pl-rooney-record`. The Premier League states the 250th goal took Rooney above Sir Bobby Charlton for Manchester United.

### Scholes across eras (`career`)

- **On what date did Paul Scholes make his Manchester United debut at Port Vale?** Answer: **21 September 1994**. Source `curriculum-uv-scholes-debut`. United’s academy debutants list gives 21 September 1994, Port Vale, age 19.
- **During which season did Scholes return to Manchester United after retirement?** Answer: **2011/12**. Source `curriculum-uv-scholes-comeback`. The club’s decade history places his return in its 2011/12 season account.
- **In what year did Scholes end his playing career for good after returning to United?** Answer: **2013**. Source `curriculum-uv-pl-scholes-profile`. The Premier League Hall of Fame profile dates his United playing career through 2013.

### A strike sends United to Moscow (`moments`)

- **On what date did Scholes score the goal that eliminated Barcelona in 2008?** Answer: **29 April 2008**. Source `curriculum-uv-scholes-barcelona`. The official United match highlight labels the Barcelona 1–0 match as 29 April 2008.
- **What was the score when United beat Barcelona at Old Trafford in the 2008 semi-final?** Answer: **1–0**. Source `curriculum-uv-scholes-barcelona`. The official highlights are titled Man United 1 Barcelona 0.
- **What did Scholes’s goal earn Manchester United against Barcelona?** Answer: **A place in the Champions League final**. Source `curriculum-uv-scholes-barcelona`. United’s account says Scholes’s strike sent United through to the Champions League final.

### The Valley Parade volley (`moments`)

- **Who delivered the corner that Scholes volleyed in the 2000 match at Bradford?** Answer: **David Beckham**. Source `curriculum-uv-scholes-bradford`. The official club feature says Beckham delivered the corner before Scholes struck.
- **What was the score when Scholes scored his volley at Bradford?** Answer: **United led 2–0**. Source `curriculum-uv-scholes-bradford`. The club retrospective says two Dwight Yorke goals had put United 2–0 ahead before the volley.
- **What was the final score of United’s away match at Bradford in March 2000?** Answer: **4–0**. Source `curriculum-uv-scholes-bradford`. United’s official feature records the final score as 4–0.

### Service, scoring and silverware (`records`)

- **How many Premier League appearances did Scholes make for Manchester United?** Answer: **499**. Source `curriculum-uv-pl-scholes-profile`. The Premier League Hall of Fame profile gives Scholes 499 league appearances.
- **How many Premier League titles did Scholes win with Manchester United over his career?** Answer: **11**. Source `curriculum-uv-pl-scholes-profile`. The Premier League Hall of Fame profile says Scholes helped United to 11 Premier League titles.
- **How many goals did Scholes score for Manchester United in all competitions?** Answer: **155**. Source `curriculum-uv-scholes-port-vale`. Manchester United’s official goal clip calls the Port Vale debut strike the first of Scholes’s 155 United goals.

### A club born in Vila-real (`history`)

- **On what date was Club Deportivo Villarreal founded?** Answer: **10 March 1923**. Source `curriculum-uv-villarreal-history`. The club’s foundation history dates CD Villarreal’s formation to 10 March 1923.
- **Which local pharmacist was among the driving forces behind the founding of CD Villarreal?** Answer: **José Calduch**. Source `curriculum-uv-villarreal-history`. Villarreal’s official history identifies pharmacist José Calduch as a leading founder and first president.
- **In what year did Villarreal’s shirts change from white to yellow?** Answer: **1946**. Source `curriculum-uv-villarreal-history`. The club history says the original white shirts remained until 1946, when they changed to yellow.

### Riquelme’s last-minute penalty (`moments`)

- **On what date did Villarreal host Arsenal in the second leg of the 2006 Champions League semi-final?** Answer: **25 April 2006**. Source `curriculum-uv-villarreal-arsenal`. UEFA dates the match report to Tuesday, 25 April 2006.
- **Which Villarreal player took the 89th-minute penalty against Arsenal?** Answer: **Juan Román Riquelme**. Source `curriculum-uv-villarreal-arsenal`. UEFA states Riquelme stepped up in the 89th minute and had his spot-kick saved.
- **What was Villarreal’s aggregate score against Arsenal when the 2006 semi-final ended?** Answer: **Villarreal lost 0–1 on aggregate**. Source `curriculum-uv-villarreal-arsenal`. UEFA reports a 1–0 Arsenal first-leg win and a goalless second leg, so Villarreal lost the tie 0–1 on aggregate.

### Twenty-two kicks to a first European crown (`moments`)

- **When did Villarreal beat Manchester United in the Europa League final?** Answer: **26 May 2021**. Source `curriculum-uv-villarreal-final`. UEFA dates the final to Wednesday, 26 May 2021.
- **What was the score after extra time in the 2021 Europa League final?** Answer: **1–1**. Source `curriculum-uv-villarreal-final`. UEFA’s final report gives the match as 1–1 after extra time.
- **Which goalkeeper saved the decisive Manchester United penalty in the shoot-out?** Answer: **Gerónimo Rulli**. Source `curriculum-uv-villarreal-final`. UEFA says Rulli saved the 22nd kick from De Gea to give Villarreal the trophy.

### Three seasons in yellow (`career`)

- **Which club did Forlán leave to join Villarreal in summer 2004?** Answer: **Manchester United**. Source `curriculum-uv-forlan`. Villarreal’s player retrospective says he signed from Manchester United in summer 2004.
- **How many seasons did Forlán play for Villarreal before leaving in 2007?** Answer: **Three**. Source `curriculum-uv-forlan`. The club describes his transfer as occurring three years after his 2004 arrival, in summer 2007; this means three seasons with Villarreal.
- **Which club signed Forlán from Villarreal in summer 2007?** Answer: **Atlético Madrid**. Source `curriculum-uv-forlan`. Villarreal reports it sold Forlán to Atlético Madrid in summer 2007.

### Forlán strikes in Milan (`moments`)

- **Which Italian club did Villarreal face when Forlán scored at the Giuseppe Meazza in 2006?** Answer: **Inter Milan**. Source `curriculum-uv-forlan`. The club’s Forlán feature identifies the quarter-final opponent as Inter Milan.
- **At which stadium did Forlán score his rapid quarter-final goal against Inter?** Answer: **Giuseppe Meazza**. Source `curriculum-uv-forlan`. The official account places the goal at the Giuseppe Meazza. Distractors are distinct stadiums; San Siro is treated as a synonym and therefore excluded below.
- **How soon did Forlán score at Inter’s stadium in that Champions League tie?** Answer: **45 seconds**. Source `curriculum-uv-forlan`. Villarreal’s official retrospective says the goal came after just 45 seconds.

### A hat-trick at Camp Nou (`moments`)

- **Which team was Villarreal playing when Forlán scored his first LaLiga hat-trick for the club?** Answer: **Barcelona**. Source `curriculum-uv-forlan-es`. Villarreal’s Spanish profile says the first of Forlán’s two LaLiga hat-tricks came at Camp Nou.
- **What was the score in Forlán’s Camp Nou hat-trick match?** Answer: **3–3**. Source `curriculum-uv-forlan-es`. The Spanish official profile gives the Camp Nou match as 3–3.
- **In which season did Forlán score that first Villarreal LaLiga hat-trick?** Answer: **2004/05**. Source `curriculum-uv-forlan-es`. Villarreal’s Spanish profile dates Forlán’s first Villarreal LaLiga hat-trick to 2004/05.

### Europe’s leading scorer (`records`)

- **How many domestic goals did Forlán score for Villarreal in the 2004/05 season?** Answer: **25**. Source `curriculum-uv-forlan`. The club says his 25 domestic strikes made him the top scorer across the continent.
- **How many LaLiga hat-tricks did Forlán score for Villarreal, according to the club’s Spanish profile?** Answer: **Two**. Source `curriculum-uv-forlan-es`. The Spanish official profile says Forlán was the only player in club history to score two Primera División hat-tricks, naming Camp Nou in 2004/05 and Osasuna in 2006/07. The English translation incorrectly says three.
- **How many goals did Forlán score in his three seasons at Villarreal?** Answer: **59**. Source `curriculum-uv-forlan`. The club’s profile records 59 goals in his three seasons as a Yellow.

### A long-serving captain in yellow (`career`)

- **In what year did Senna join Villarreal from São Caetano?** Answer: **2002**. Source `curriculum-uv-senna-career`. Villarreal’s biography says Senna arrived in summer 2002 from São Caetano.
- **How many seasons did Senna represent Villarreal?** Answer: **11**. Source `curriculum-uv-senna-career`. The club says he wore the yellow shirt for 11 seasons.
- **How many goals did Senna score for Villarreal?** Answer: **33**. Source `curriculum-uv-senna-career`. The official profile records 33 goals for the Yellows.

### He stayed to help Villarreal rise again (`moments`)

- **After which season did Villarreal suffer the relegation that Senna stayed to respond to?** Answer: **2011/12**. Source `curriculum-uv-senna-career`. The club’s historical table shows Villarreal 18th in Primera in 2011/12; Senna’s profile says he stayed after relegation.
- **What did Senna decide to do after Villarreal were relegated?** Answer: **Extend his contract and stay another season**. Source `curriculum-uv-senna-career`. The club says he extended his contract and stayed one more season to help return Villarreal to the top flight.
- **After Villarreal returned to the top flight, which club did Senna join to finish his playing career?** Answer: **New York Cosmos**. Source `curriculum-uv-senna-career`. Villarreal says Senna left after the promotion season to end his career in the United States with New York Cosmos.

### A long Villarreal career (`records`)

- **How many official matches did Senna play for Villarreal across competitions?** Answer: **363**. Source `curriculum-uv-senna-records`. The club lists 363 total official appearances and identifies him as the record holder at that time.
- **How many of Senna’s Villarreal matches were in LaLiga?** Answer: **292**. Source `curriculum-uv-senna-records`. The club breaks his appearances down and lists 292 in the Spanish first division.
- **How many Champions League matches did Senna play for Villarreal?** Answer: **27**. Source `curriculum-uv-senna-records`. The club’s competition breakdown gives Senna 27 Champions League appearances.

### From São Paulo to European champion (`legacy`)

- **How many Spain appearances did Senna make while playing for Villarreal, according to the club’s 2019 count?** Answer: **28**. Source `curriculum-uv-senna-spain`. Villarreal’s 2019 official article lists Senna with 28 Spain matches among players who represented the national team while at the club.
- **In what year did Senna make his debut for Spain?** Answer: **2006**. Source `curriculum-uv-senna-career`. Villarreal’s official biography reports his Spain debut in 2006. The club’s newer profile dates naturalisation to 2006, while the older English biography says 2005, so the contested naturalisation year is not tested.
- **Which major international tournament did Senna win with Spain in 2008?** Answer: **UEFA European Championship / UEFA EURO**. Source `curriculum-uv-senna-records`. Villarreal’s official retrospective says Senna won the UEFA European Championship with Spain in 2008.

## Scope and retrieval notes

- United’s 1958 history, Villarreal’s 2006 Champions League semi-final, Villarreal’s 2021 Europa League final, Villarreal’s foundation history, and the Forlán/Senna biographies were checked against primary club or UEFA pages.
- Scholes’s Premier League record is scoped to the competition: the Premier League profile gives 499 appearances, 107 league goals, and 11 Premier League titles. A Manchester United history article says “500 top-flight appearances”; because that differs from the competition record, the pack uses the Premier League’s exact 499 figure. His 155-goal total is explicitly all competitions and comes from the club’s official goal clip.
- Rooney’s completed club total is 253 goals across all competitions. The 250th-goal date and the record he passed are supported by the Premier League match report.
- Forlán’s Villarreal English retrospective calls his 2004/05 recognition “Golden Ball” while other summaries use “Golden Boot”; the pack tests the body-supported domestic-goal total and hat-trick record rather than an inconsistent award-name translation.
- Senna’s 363 total is historical. Villarreal later reported Bruno Soriano surpassed the appearance record. The lesson frames Senna as a 363-match career, not as the current holder. Villarreal sources conflict on naturalisation year (2005 in the 2020 English biography; 2006 in a later official profile); the exact-year question was replaced with the club’s 2019 count of 28 Spain appearances while he played for Villarreal.
- Scholes’s career lesson pairs his 1994 debut date with his 2011/12 return from retirement and 2013 final retirement, avoiding three questions about one debut event. The 2011/12 season and 2013 endpoint are supported by opened official United history and the Premier League Hall of Fame profile.
- Some Manchester United article/video pages returned only their visible shell in browser extraction. Where possible, corresponding claims use official indexed article text or other directly readable primary pages, listed above. Firecrawl CLI was unavailable; discovery and inspection used the enabled web search/open interface. No unsupported claim is retained.

## Integration review — 11 October 2026

Manchester United, Manchester City, Inter, Atlético de Madrid and other club answers now reference canonical badge entities. Existing curated Ajax, Leicester, Everton, West Ham, Sevilla, Valencia, Monaco and Lyon badges have supporting entities; no new course is implied. Unknown distractor clubs have been replaced with distinct, available badge choices. Score questions state which team’s score is requested, including Villarreal’s 0–1 aggregate loss and United’s 2–0 score immediately after Scholes’s Bradford volley. Division Two and Second Division were synonymous distractors; the second was replaced with Division Four. Bradford’s supporting badge is UEFA club 72533, not the women’s team ID.
