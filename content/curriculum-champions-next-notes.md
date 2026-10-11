# Champions next curriculum: evidence and review notes

Prepared 2026-10-10. The JSON contains 3 club lessons and 4 player-specific lessons per selected player, with 39 source records. Every lesson has two story screens and three fact prompts. All source keys below use the `curriculum-next-` namespace. The official pages were opened for direct review when accessible; the notes distinguish indexed search content where needed.

## Identity and portraits

- PSG uses existing `entity-psg`; its displayed starter name is “Paris.”
- Manchester City uses `entity-manchester-city`; its starter name is “Man City.”
- Atlético uses `entity-atletico`; its starter name is “Atlético de Madrid.”
- Player seed bindings match the exact names/IDs in `games-en.json`: Kylian Mbappe (`player-20`), Zlatan Ibrahimovic (`player-4`), Sergio Aguero (`player-62`), David Silva (`player-255`), Antoine Griezmann (`player-142`), Fernando Torres (`player-177`). Accents in authored names do not alter seed identity.
- Visual initials are generic initials, not portrait claims; each binding points to the exact named seed person.

## Fact-level evidence coverage

### A Paris club is born — `entity-psg`

- **How many people backed the project for a major Paris club?** `psg-support` — The article says 66,000 people supported the project. Source: `curriculum-next-psg-origin` (https://www.psg.fr/en/content/the-paris-derby-where-it-all-began-psg-history-ligue-1-2025-2026).
- **Which club merged with Paris Football Club to form PSG?** `psg-merger` — The article says PFC was forced to merge with Stade Sangermanois. Source: `curriculum-next-psg-origin` (https://www.psg.fr/en/content/the-paris-derby-where-it-all-began-psg-history-ligue-1-2025-2026).
- **What did PSG achieve in its first season?** `psg-first-season` — PSG records a National Championship title and promotion to the first division. Source: `curriculum-next-psg-origin` (https://www.psg.fr/en/content/the-paris-derby-where-it-all-began-psg-history-ligue-1-2025-2026).

### Brussels brings a European first — `entity-psg`

- **Which club did PSG defeat in the 1996 Cup Winners’ Cup final?** `psg-1996-opponent` — The UEFA final report lists Paris Saint-Germain 1–0 SK Rapid Wien. Source: `curriculum-next-psg-cup` (https://www.psg.fr/content/il-y-a-30-ans-paris-remportait-la-coupe-des-vainqueurs-de-coupe).
- **Who scored the only goal of the 1996 final?** `psg-1996-scorer` — UEFA identifies N’Gotty as the scorer after a Djorkaeff touch from a free kick. Source: `curriculum-next-psg-cup` (https://www.psg.fr/content/il-y-a-30-ans-paris-remportait-la-coupe-des-vainqueurs-de-coupe).
- **On what date did PSG win the Cup Winners’ Cup in Brussels?** `psg-1996-date` — PSG dates the Brussels final to Wednesday 8 May 1996. Source: `curriculum-next-psg-1996` (https://en.psg.fr/teams/club/content/25-years-agoeurope-belongs-to-paris-saint-germain-sk-rapid-vienne-1995-1996).

### Four past Barcelona — `entity-psg`

- **What was the score when PSG hosted Barcelona on 14 February 2017?** `psg-barca-score` — UEFA says PSG won 4–0. Source: `curriculum-next-psg-barca` (https://www.uefa.com/uefachampionsleague/news/0236-0e963887c498-42bc424b301f-1000--brilliant-paris-blow-barcelona-away/).
- **Which PSG player scored twice that night?** `psg-barca-brace` — UEFA names Di María as the two-goal scorer. Source: `curriculum-next-psg-barca` (https://www.uefa.com/uefachampionsleague/news/0236-0e963887c498-42bc424b301f-1000--brilliant-paris-blow-barcelona-away/).
- **Who scored PSG’s second goal?** `psg-barca-draxler` — UEFA describes Verratti setting up Draxler’s finish. Source: `curriculum-next-psg-barca` (https://www.uefa.com/uefachampionsleague/news/0236-0e963887c498-42bc424b301f-1000--brilliant-paris-blow-barcelona-away/).

### A prodigy rises at Monaco — `entity-mbappe`

- **In which month and year did Mbappé make his Ligue 1 debut?** `mbappe-born` — Ligue 1’s retrospective says he discovered the league in December 2015. Source: `curriculum-next-ligue1-mbappe-monaco` ([Rétro : Kylian Mbappé, une éclosion princière](https://ligue1.com/fr/articles/l1_article_336-retro-kylian-mbappe-une-eclosion-princiere)).
- **How many Ligue 1 goals did Mbappé score in his first half-season with Monaco?** `mbappe-psg-sign` — The league retrospective records 11 appearances, one goal and one assist in his first half-season. Source: `curriculum-next-ligue1-mbappe-monaco` ([Rétro : Kylian Mbappé, une éclosion princière](https://ligue1.com/fr/articles/l1_article_336-retro-kylian-mbappe-une-eclosion-princiere)).
- **On what date did Mbappé score the goal that clinched Monaco’s 2016/17 league title?** `mbappe-monaco-title` — Ligue 1 dates the title-clinching goal against ASSE to 17 May 2017. Source: `curriculum-next-ligue1-mbappe-monaco` ([Rétro : Kylian Mbappé, une éclosion princière](https://ligue1.com/fr/articles/l1_article_336-retro-kylian-mbappe-une-eclosion-princiere)).

### A hat-trick at Camp Nou — `entity-mbappe`

- **When did Mbappé score his Camp Nou hat-trick?** `mbappe-barca-date` — UEFA dates the match Tuesday, 16 February 2021. Source: `curriculum-next-psg-mbappe-barca` ([Barcelona 1-4 Paris: Mbappé hits stunning hat-trick](https://www.uefa.com/uefachampionsleague/news/0266-1197f34a1ce0-99c2ccf20bea-1000/)).
- **How many goals did Mbappé score against Barcelona in that match?** `mbappe-barca-treble` — UEFA reports Mbappé’s treble. Source: `curriculum-next-psg-mbappe-barca` ([Barcelona 1-4 Paris: Mbappé hits stunning hat-trick](https://www.uefa.com/uefachampionsleague/news/0266-1197f34a1ce0-99c2ccf20bea-1000/)).
- **What match award did UEFA give Mbappé after the Barcelona game?** `mbappe-barca-award` — The report lists Kylian Mbappé as Player of the Match. Source: `curriculum-next-psg-mbappe-barca` ([Barcelona 1-4 Paris: Mbappé hits stunning hat-trick](https://www.uefa.com/uefachampionsleague/news/0266-1197f34a1ce0-99c2ccf20bea-1000/)).

### Goal 201 makes history — `entity-mbappe`

- **When did Mbappé score his 201st PSG goal?** `mbappe-201-date` — PSG dates the goal Saturday 4 March 2023. Source: `curriculum-next-psg-mbappe201` ([Kylian Mbappé becomes Paris Saint-Germain’s all-time top scorer](https://en.psg.fr/teams/first-team/content/kylian-mbappe-becomes-paris-saint-germains-all-time-top-scorer-2022-2023)).
- **How many matches had Mbappé played for PSG when he reached 201 goals?** `mbappe-201-games` — The PSG report states 201 goals in 247 matches. Source: `curriculum-next-psg-mbappe201` ([Kylian Mbappé becomes Paris Saint-Germain’s all-time top scorer](https://en.psg.fr/teams/first-team/content/kylian-mbappe-becomes-paris-saint-germains-all-time-top-scorer-2022-2023)).
- **How old was Mbappé when he became PSG’s leading scorer?** `mbappe-201-age` — PSG states his age as 24 years, 2 months and 12 days. Source: `curriculum-next-psg-mbappe201` ([Kylian Mbappé becomes Paris Saint-Germain’s all-time top scorer](https://en.psg.fr/teams/first-team/content/kylian-mbappe-becomes-paris-saint-germains-all-time-top-scorer-2022-2023)).

### A record run of league honours — `entity-mbappe`

- **How many Ligue 1 Player of the Year awards does the league list for Mbappé?** `mbappe-player-awards` — The LFP honours list names Mbappé as winner in 2019, 2021, 2022, 2023 and 2024. Source: `curriculum-next-ligue1-awards` ([Trophées UNFP : Palmarès des meilleurs joueurs](https://ligue1.com/en/articles/l1_article_285-)).
- **How many consecutive Ligue 1 top-scorer titles did Mbappé win from 2019 to 2024?** `mbappe-top-scorer` — Ligue 1 calls him the first six-time top scorer and lists the six winning years 2019–2024. Source: `curriculum-next-ligue1-topscorers` ([History and Records of the Ligue 1 McDonald's Top Scorers](https://ligue1.com/en/articles/l1_article_2588-)).
- **In which year did Mbappé play the final PSG lost 1–0 to Bayern?** `mbappe-final-date` — UEFA dates the Paris–Bayern final to August 2020. Source: `curriculum-next-psg-mbappe-final` ([Paris 0-1 Bayern: Coman scores Champions League final winner](https://www.uefa.com/uefachampionsleague/news/0260-1033c96091a1-3d127374ef80-1000--paris-0-1-bayern-coman-scores-champions-league-final-winner/)).

### Ibrahimović joins PSG — `entity-ibrahimovic`

- **On what date did UEFA report Ibrahimović’s move from Milan to PSG?** `ibra-sign-date` — UEFA’s transfer report dates the agreement to 18 July 2012 and identifies AC Milan as his previous club. Source: `curriculum-next-uefa-ibra-sign` ([PSG prise Ibrahimović away from Milan](https://www.uefa.com/uefachampionsleague/news/01ff-0e7e6cc852e1-a3921304caa3-1000--psg-prise-ibrahimovic-away-from-milan/)).
- **How long was the contract in UEFA’s signing report?** `ibra-contract` — UEFA reports Ibrahimović agreed a three-year contract. Source: `curriculum-next-uefa-ibra-sign` ([PSG prise Ibrahimović away from Milan](https://www.uefa.com/uefachampionsleague/news/01ff-0e7e6cc852e1-a3921304caa3-1000--psg-prise-ibrahimovic-away-from-milan/)).
- **How many total appearances did Ibrahimović make for PSG?** `ibra-games` — Ligue 1’s retrospective says 180 appearances, his highest total at any club. Source: `curriculum-next-ligue1-ibra-180` ([Happy Birthday, Zlatan Ibrahimovic!](https://ligue1.com/en/articles/l1_article_3385-)).

### An immediate impact in Paris — `entity-ibrahimovic`

- **On what date did Ibrahimović make his first Ligue 1 appearance for PSG?** `ibra-lille-date` — Ligue 1 dates his first Paris appearance to 11 August 2012 against FC Lorient. Source: `curriculum-next-ligue1-ibra` ([Ibrahimovic, un passage marquant au PSG](https://ligue1.com/en/articles/l1_article_283-ibrahimovic-un-passage-marquant-au-psg)).
- **Which club did PSG face in Ibrahimović’s first league appearance?** `ibra-lille-time` — Ligue 1 identifies FC Lorient as the opponent in his first PSG league appearance. Source: `curriculum-next-ligue1-ibra` ([Ibrahimovic, un passage marquant au PSG](https://ligue1.com/en/articles/l1_article_283-ibrahimovic-un-passage-marquant-au-psg)).
- **How many goals did PSG trail by before Ibrahimović’s debut brace rescued a draw?** `ibra-30first` — Ligue 1 says his brace rescued PSG after the team fell two goals behind. Source: `curriculum-next-ligue1-ibra` ([Ibrahimovic, un passage marquant au PSG](https://ligue1.com/en/articles/l1_article_283-ibrahimovic-un-passage-marquant-au-psg)).

### A historic scoring season — `entity-ibrahimovic`

- **How many Ligue 1 goals did Ibrahimović score in the 2015/16 season?** `ibra-ligue-goals` — Ligue 1 records 38 goals in 31 matches for 2015/16. Source: `curriculum-next-ligue1-ibra` ([Ibrahimovic, un passage marquant au PSG](https://ligue1.com/en/articles/l1_article_283-ibrahimovic-un-passage-marquant-au-psg)).
- **What place did his 38-goal 2015/16 total hold in Ligue 1 single-season history?** `ibra-ligue-assists` — Ligue 1 describes 38 goals as the third-highest total in the championship’s history. Source: `curriculum-next-ligue1-ibra` ([Ibrahimovic, un passage marquant au PSG](https://ligue1.com/en/articles/l1_article_283-ibrahimovic-un-passage-marquant-au-psg)).
- **How many goals did Ibrahimović score in PSG’s 9–0 win at Troyes?** `ibra-troyes-goals` — Ligue 1’s season retrospective calls the four-goal performance a quadruple. Source: `curriculum-next-ligue1-ibra` ([Ibrahimovic, un passage marquant au PSG](https://ligue1.com/en/articles/l1_article_283-ibrahimovic-un-passage-marquant-au-psg)).

### A final match with a brace — `entity-ibrahimovic`

- **On what date did Ibrahimović score twice in PSG’s Coupe de France final against Marseille?** `ibra-last-match-date` — The FFF archive dates the final to 21 May 2016 and identifies it as PSG–Marseille. Source: `curriculum-next-fff-ibra-final` ([2016 - Olympique de Marseille - Paris-SG (2-4)](https://ffftv.fff.fr/video/6165212730001/2016-olympique-de-marseille-paris-sg-2-4)).
- **Which club did PSG beat in Ibrahimović’s final match?** `ibra-final-opponent` — The FFF archive identifies Olympique de Marseille as the opponent. Source: `curriculum-next-fff-ibra-final` ([2016 - Olympique de Marseille - Paris-SG (2-4)](https://ffftv.fff.fr/video/6165212730001/2016-olympique-de-marseille-paris-sg-2-4)).
- **How many goals did Ibrahimović score in the final?** `ibra-paris-goals` — The FFF final archive says Ibrahimović scored a brace in PSG’s 4–2 win. Source: `curriculum-next-fff-ibra-final` ([2016 - Olympique de Marseille - Paris-SG (2-4)](https://ffftv.fff.fr/video/6165212730001/2016-olympique-de-marseille-paris-sg-2-4)).
### From St Mark’s to Manchester City — `entity-manchester-city`

- **In what year did St Mark’s Church form the team that evolved into Manchester City?** `city-formation` — The club history dates the St Mark’s team to 1880. Source: `curriculum-next-city-history` (https://www.mancity.com/club/manchester-city-history).
- **In what year did St Mark’s evolve into Ardwick AFC?** `city-ardwick` — The history says the team became Ardwick AFC in 1887. Source: `curriculum-next-city-history` (https://www.mancity.com/club/manchester-city-history).
- **In what year did Ardwick reform as Manchester City Football Club?** `city-name` — Manchester City dates this change to 1894. Source: `curriculum-next-city-history` (https://www.mancity.com/club/manchester-city-history).

### A trophy after 35 years — `entity-manchester-city`

- **When did City beat Stoke in the 2011 FA Cup final?** `city-fa-date` — The official club retrospective lists 14 May 2011. Source: `curriculum-next-city-fa` (https://www.mancity.com/news/mens/on-this-day-14-may-man-city-win-fa-cup-2011-63724967).
- **What was the score against Stoke in the FA Cup final?** `city-fa-score` — Manchester City records a 1–0 win over Stoke. Source: `curriculum-next-city-fa` (https://www.mancity.com/news/mens/on-this-day-14-may-man-city-win-fa-cup-2011-63724967).
- **Who scored the only goal in the final?** `city-fa-scorer` — The club says Touré scored the winner 16 minutes from time. Source: `curriculum-next-city-fa` (https://www.mancity.com/news/mens/on-this-day-14-may-man-city-win-fa-cup-2011-63724967).

### City completes the Treble — `entity-manchester-city`

- **When did City beat Inter to win its first Champions League?** `city-inter-date` — UEFA dates the final Saturday 10 June 2023. Source: `curriculum-next-city-ucl` (https://www.uefa.com/uefachampionsleague/news/0282-1839b24603ef-36e94e63621d-1000--highlights-report-man-city-win-champions-league/).
- **Who scored the only goal against Inter?** `city-inter-scorer` — UEFA identifies Rodri as the second-half scorer. Source: `curriculum-next-city-ucl` (https://www.uefa.com/uefachampionsleague/news/0282-1839b24603ef-36e94e63621d-1000--highlights-report-man-city-win-champions-league/).
- **What major English football achievement did City complete with the win?** `city-treble` — UEFA describes the Champions League win as completing a treble. Source: `curriculum-next-city-ucl` (https://www.uefa.com/uefachampionsleague/news/0282-1839b24603ef-36e94e63621d-1000--highlights-report-man-city-win-champions-league/).

### Agüero joins City — `entity-aguero`

- **On what date did Agüero join Manchester City?** `aguero-join-date` — The City profile says he joined on 27 July 2011. Source: `curriculum-next-city-aguero` (https://www.mancity.com/mancitylegends/aguero-sergio).
- **Which team did Agüero face on his City debut?** `aguero-debut-opponent` — City identifies Swansea as his debut opponent. Source: `curriculum-next-city-aguero` (https://www.mancity.com/mancitylegends/aguero-sergio).
- **How many goals did Agüero score in his first City season?** `aguero-first-season` — The club biography says he scored 30 times. Source: `curriculum-next-city-aguero` (https://www.mancity.com/mancitylegends/aguero-sergio).

### The 93:20 winner — `entity-aguero`

- **On what date did Agüero score the 93:20 goal?** `aguero-qpr-day` — City identifies the QPR win as the last day of the 2011/12 campaign. Source: `curriculum-next-city-aguero-final` (https://www.mancity.com/news/mens/sergio-aguero-relives-the-qpr-goal-and-names-his-second-favourite-season-63791231).
- **What was the final score when City beat QPR with Agüero’s goal?** `aguero-qpr-score` — City’s retrospective describes the 3–2 win after City had trailed 2–1. Source: `curriculum-next-city-aguero-final` (https://www.mancity.com/news/mens/sergio-aguero-relives-the-qpr-goal-and-names-his-second-favourite-season-63791231).
- **At what time did Agüero score the title-winning goal?** `aguero-qpr-time` — City and the Premier League refer to the goal as 93:20. Source: `curriculum-next-city-aguero` (https://www.mancity.com/mancitylegends/aguero-sergio).

### A record City goalscorer — `entity-aguero`

- **How many goals did Agüero score for City?** `aguero-city-goals` — Manchester City records 260 goals. Source: `curriculum-next-city-aguero` (https://www.mancity.com/mancitylegends/aguero-sergio).
- **How many City appearances did Agüero make?** `aguero-city-apps` — The City profile lists 390 appearances. Source: `curriculum-next-city-aguero` (https://www.mancity.com/mancitylegends/aguero-sergio).
- **How many Premier League hat-tricks did Agüero score, a league record?** `aguero-pl-trebles` — The Premier League record list identifies Agüero with 12. Source: `curriculum-next-city-plrecords` (https://www.premierleague.com/en/stats/records).

### A medal-winning City era — `entity-aguero`

- **How many Premier League titles did Agüero win with City?** `aguero-pl-titles` — City lists five Premier League medals. Source: `curriculum-next-city-aguero` (https://www.mancity.com/mancitylegends/aguero-sergio).
- **How many League Cup medals does City list for Agüero?** `aguero-league-cups` — City lists five Carabao Cup medals. Source: `curriculum-next-city-aguero` (https://www.mancity.com/mancitylegends/aguero-sergio).
- **How many total medals does the City profile list for Agüero?** `aguero-total-medals` — City says he has 14 medals. Source: `curriculum-next-city-aguero` (https://www.mancity.com/mancitylegends/aguero-sergio).

### A World Cup winner arrives — `entity-david-silva`

- **Where was David Silva born?** `silva-born` — City says Silva was born in Arguineguín, Gran Canaria. Source: `curriculum-next-city-silva` (https://www.mancity.com/mancitylegends/silva-david).
- **In which year did Silva arrive at Manchester City?** `silva-city-arrival` — The club biography places his arrival in July 2010. Source: `curriculum-next-city-silva` (https://www.mancity.com/mancitylegends/silva-david).
- **Which club did Silva join City from?** `silva-from-club` — The official profile says he arrived from Valencia. Source: `curriculum-next-city-silva` (https://www.mancity.com/mancitylegends/silva-david).

### A derby remembered in passes — `entity-david-silva`

- **In what year did City win 6–1 at Old Trafford with Silva assisting Džeko?** `silva-derby-year` — City’s article describes the 6–1 defeat of United in 2011. Source: `curriculum-next-city-silva-derby` (https://www.mancity.com/news/first-team/first-team-news/2020/january/man-city-decade-david-silva-impact-stats).
- **What was the score of City’s Old Trafford win?** `silva-derby-score` — The club tribute calls it the 6–1 defeat of arch-rivals United. Source: `curriculum-next-city-silva-derby` (https://www.mancity.com/news/first-team/first-team-news/2020/january/man-city-decade-david-silva-impact-stats).
- **Who received Silva’s notable pass for a goal in that derby?** `silva-assist-recipient` — City’s retrospective names Silva’s assist to Edin Džeko. Source: `curriculum-next-city-silva-derby` (https://www.mancity.com/news/first-team/first-team-news/2020/january/man-city-decade-david-silva-impact-stats).

### A decade of City appearances — `entity-david-silva`

- **How many appearances did Silva make for Manchester City?** `silva-total-apps` — City lists 436 appearances. Source: `curriculum-next-city-silva-milestone` (https://www.mancity.com/news/mens/david-silva-appearance-milestone-63733121).
- **How many European appearances did Silva have after the Lyon match?** `silva-lyon-apps` — City says the Lyon fixture took him to 70 European appearances. Source: `curriculum-next-city-silva-milestone` (https://www.mancity.com/news/mens/david-silva-appearance-milestone-63733121).
- **How many goals did Silva score for City?** `silva-goals` — The official profile gives 77 goals. Source: `curriculum-next-city-silva` (https://www.mancity.com/mancitylegends/silva-david).

### Honours across a decade — `entity-david-silva`

- **How many Premier League titles did Silva win with City?** `silva-leagues` — City lists four Premier League titles. Source: `curriculum-next-city-silva-statue` (https://www.mancity.com/news/mens/david-silva-statue-khaldoon-al-mubarak-63733257).
- **How many FA Cups did Silva win with City?** `silva-fa-cups` — City lists two FA Cups. Source: `curriculum-next-city-silva-statue` (https://www.mancity.com/news/mens/david-silva-statue-khaldoon-al-mubarak-63733257).
- **How many League Cups did Silva win with City?** `silva-league-cups` — City lists five League Cups. Source: `curriculum-next-city-silva-statue` (https://www.mancity.com/news/mens/david-silva-statue-khaldoon-al-mubarak-63733257).

### Athletic Club de Madrid begins — `entity-atletico`

- **On what date was Athletic Club de Madrid founded?** `atleti-found-date` — The club’s anniversary article identifies 26 April 1903. Source: `curriculum-next-atleti-origin` (https://www.atleticodemadrid.com/noticias/123-anos-de-pasion).
- **Who founded Athletic Club de Madrid?** `atleti-founders` — Atlético describes the founders as young Basque students based in Madrid. Source: `curriculum-next-atleti-origin` (https://www.atleticodemadrid.com/noticias/123-anos-de-pasion).
- **When did members play the club’s first match?** `atleti-first-match` — The club’s official retrospective says the first match was on 2 May 1903 at Campo del Retiro, with 24 members split into two sides of 12. Source: `curriculum-next-atleti-history` (https://www.atleticodemadrid.com/noticias/se-cumplen-118-anos-de-nuestro-primer-partido).

### A title secured at Camp Nou — `entity-atletico`

- **When did Atlético secure the 2013/14 league title at Barcelona?** `atleti-title-date` — UEFA dates the match Saturday 17 May 2014. Source: `curriculum-next-atleti-title` (https://www.uefa.com/news-media/news/0215-0e8adc597e0f-6bf435e52eab-1000--godin-heads-atletico-to-liga-title/).
- **Who scored Atlético’s equaliser at Camp Nou?** `atleti-equalizer` — UEFA identifies Godín as the second-half scorer. Source: `curriculum-next-atleti-title` (https://www.uefa.com/news-media/news/0215-0e8adc597e0f-6bf435e52eab-1000--godin-heads-atletico-to-liga-title/).
- **How many Spanish league titles did this win give Atlético?** `atleti-league-count` — UEFA says the draw secured Atlético’s tenth Liga title. Source: `curriculum-next-atleti-title` (https://www.uefa.com/news-media/news/0215-0e8adc597e0f-6bf435e52eab-1000--godin-heads-atletico-to-liga-title/).

### An Intercontinental comeback — `entity-atletico`

- **When did Atlético win the decisive Intercontinental Cup match?** `atleti-ic-date` — Atlético dates its 2–0 win over Independiente to 10 April 1975. Source: `curriculum-next-atleti-intercontinental` (https://www.atleticodemadrid.com/noticias/campeon-de-la-intercontinental-en-el-calderon).
- **Which club did Atlético beat to win the Intercontinental Cup?** `atleti-ic-opponent` — The club identifies Independiente de Avellaneda as its opponent. Source: `curriculum-next-atleti-intercontinental` (https://www.atleticodemadrid.com/noticias/campeon-de-la-intercontinental-en-el-calderon).
- **What was Atlético’s score in the home leg that completed the comeback?** `atleti-ic-comeback` — The club says Atlético won the second match by two goals to nil. Source: `curriculum-next-atleti-intercontinental` (https://www.atleticodemadrid.com/noticias/campeon-de-la-intercontinental-en-el-calderon).

### Torres rises from the academy — `entity-fernando-torres`

- **How old was Torres when he joined Atlético’s academy?** `torres-academy-age` — Atlético says he joined the academy at 11. Source: `curriculum-next-atleti-torres` (https://en.atleticodemadrid.com/noticias/see-you-soon-fernando-torres).
- **When did Torres make his first-team debut?** `torres-debut-date` — Atlético dates the debut to 27 May 2001. Source: `curriculum-next-atleti-torres-debut` (https://www.atleticodemadrid.com/noticias/se-cumplen-21-anos-del-debut-de-fernando-torres).
- **Against whom did Torres score his first senior Atlético goal?** `torres-first-goal` — The club says his first goal came against Albacete. Source: `curriculum-next-atleti-torres` (https://en.atleticodemadrid.com/noticias/see-you-soon-fernando-torres).

### A farewell brace — `entity-fernando-torres`

- **Which team did Atlético face in Torres’s Calderón farewell match?** `torres-farewell-opponent` — Atlético says Torres scored twice against Athletic Club. Source: `curriculum-next-atleti-torres` (https://en.atleticodemadrid.com/noticias/see-you-soon-fernando-torres).
- **How many goals did Torres score in the Calderón farewell match?** `torres-farewell-goals` — The club records two of the three goals as Torres’s. Source: `curriculum-next-atleti-torres` (https://en.atleticodemadrid.com/noticias/see-you-soon-fernando-torres).
- **Which stadium hosted the farewell match where Torres scored a brace?** `torres-farewell-stadium` — Atlético calls it the Vicente Calderón farewell match. Source: `curriculum-next-atleti-torres` (https://en.atleticodemadrid.com/noticias/see-you-soon-fernando-torres).

### A century of Atlético goals — `entity-fernando-torres`

- **When did Torres score his 100th Atlético goal?** `torres-hundred-date` — Atlético dates the milestone 6 February 2016. Source: `curriculum-next-atleti-torres` (https://en.atleticodemadrid.com/noticias/see-you-soon-fernando-torres).
- **How many appearances did Torres make for Atlético?** `torres-final-apps` — The club farewell reports 404 matches. Source: `curriculum-next-atleti-torres` (https://en.atleticodemadrid.com/noticias/see-you-soon-fernando-torres).
- **How many goals did Torres score for Atlético?** `torres-final-goals` — Atlético records 129 goals. Source: `curriculum-next-atleti-torres` (https://en.atleticodemadrid.com/noticias/see-you-soon-fernando-torres).

### A childhood dream fulfilled — `entity-fernando-torres`

- **In what year did Torres win the Europa League with Atlético?** `torres-europa-year` — Atlético says he won the Europa League in Lyon in 2018. Source: `curriculum-next-atleti-torres` (https://en.atleticodemadrid.com/noticias/see-you-soon-fernando-torres).
- **Which team did Atlético beat in the final Torres won?** `torres-europa-opponent` — The club identifies Olympique de Marseille as the final opponent. Source: `curriculum-next-atleti-torres` (https://en.atleticodemadrid.com/noticias/see-you-soon-fernando-torres).
- **Which country did Torres score against in the Euro 2008 final?** `torres-euro-2008` — Atlético says he scored the winning goal against Germany in the 1–0 final. Source: `curriculum-next-atleti-torres-debut` (https://www.atleticodemadrid.com/noticias/se-cumplen-21-anos-del-debut-de-fernando-torres).

### Griezmann’s first Atleti spell — `entity-griezmann`

- **Before which season did Griezmann first join Atlético?** `griezmann-first-season` — Atlético says he joined ahead of 2014/15. Source: `curriculum-next-atleti-griezmann` (https://en.atleticodemadrid.com/noticias/welcome-back-griezmann).
- **When did Griezmann make his Atlético debut?** `griezmann-debut-date` — Atlético dates his debut to 10 August 2014. Source: `curriculum-next-atleti-griezmann` (https://en.atleticodemadrid.com/noticias/welcome-back-griezmann).
- **Against whom did Griezmann score his first Atlético goal?** `griezmann-first-goal-opponent` — The club identifies Olympiacos as the opponent. Source: `curriculum-next-atleti-griezmann` (https://en.atleticodemadrid.com/noticias/welcome-back-griezmann).

### A brace on home soil — `entity-griezmann`

- **When did Griezmann score twice in the Europa League final?** `griezmann-final-date` — UEFA dates the final Wednesday 16 May 2018. Source: `curriculum-next-atleti-griezmann-final` (https://www.uefa.com/uefaeuropaleague/news/0245-0e98ccf1bf02-d01429ca84a2-1000--griezmann-named-official-man-of-the-match/).
- **What was the score in Atlético’s win over Marseille?** `griezmann-final-score` — UEFA records a 3–0 Atlético victory. Source: `curriculum-next-atleti-final` (https://www.uefa.com/uefaeuropaleague/news/0245-0e98ccf1cec2-0418a5d239cc-1000--griezmann-inspires-atletico-to-europa-league-glory/).
- **What award did Griezmann receive for the final?** `griezmann-man-match` — UEFA named him official man of the match. Source: `curriculum-next-atleti-griezmann-final` (https://www.uefa.com/uefaeuropaleague/news/0245-0e98ccf1bf02-d01429ca84a2-1000--griezmann-named-official-man-of-the-match/).

### Level with Luis Aragonés — `entity-griezmann`

- **When did Griezmann equal the Atlético scoring record?** `griezmann-record-date` — The club report dates the record tie to 19 December. Source: `curriculum-next-atleti-griezmann-record` (https://www.atleticodemadrid.com/noticias/antoine-griezmann-iguala-a-luis-aragones-como-maximo-goleador-historico).
- **How many Atlético goals had Griezmann scored when he equalled Luis Aragonés?** `griezmann-record-goals` — Atlético says he equalled the record with 173 goals. Source: `curriculum-next-atleti-griezmann-record` (https://www.atleticodemadrid.com/noticias/antoine-griezmann-iguala-a-luis-aragones-como-maximo-goleador-historico).
- **How many matches had Griezmann played across his two Atlético spells at that milestone?** `griezmann-record-games` — The club says his 173 goals came in 364 matches. Source: `curriculum-next-atleti-griezmann-record` (https://www.atleticodemadrid.com/noticias/antoine-griezmann-iguala-a-luis-aragones-como-maximo-goleador-historico).

### Club and country honours — `entity-griezmann`

- **How many Europa League titles did Griezmann win with Atlético in his first spell?** `griezmann-atleti-titles` — Atlético lists one Europa League title. Source: `curriculum-next-atleti-griezmann` (https://en.atleticodemadrid.com/noticias/welcome-back-griezmann).
- **In which year did Griezmann win the World Cup with France?** `griezmann-world-cup` — The club says he won the World Cup in 2018. Source: `curriculum-next-atleti-griezmann` (https://en.atleticodemadrid.com/noticias/welcome-back-griezmann).
- **What was Griezmann’s placing in the 2018 Ballon d’Or?** `griezmann-ballon` — Atlético says he came third in the 2018 award. Source: `curriculum-next-atleti-griezmann` (https://en.atleticodemadrid.com/noticias/welcome-back-griezmann).

## Caveats

- Several old PSG English profile and retrospective paths redirect or return 404 when opened. Mbappé’s Monaco debut and title-clinching run are now supported by directly opened Ligue 1 editorial coverage; his award counts use directly opened LFP honours lists. Ibrahimović’s PSG transfer details use an opened UEFA transfer report, his season/career records use opened Ligue 1 articles, and his final match uses the FFF archive. No indexed-only PSG profile claims remain in these player lessons.
- The exact PSG 201. goal fact is a historical snapshot on 4 March 2023 (201 in 247), not a current career total. The PSG profile may now show later totals; the milestone lesson is explicitly date-scoped.
- The City Aguero legend/profile and City history pages were opened directly. Premier League’s official record page directly supports the 12-hat-trick record. The David Silva 6–1 derby contribution is supported by the City retrospective page, which specifically calls out the Džeko assist.
- Atlético’s 123-year official history article was directly opened for founder/date; the club history PDF supports the first-match chronology. The 1975 and 2014 moments use directly opened official club and UEFA pages. Torres and Griezmann official pages were directly opened.
- Player lessons reuse a major event as context only where that lesson asks a distinct player-specific detail. The facts do not ask identical questions across lessons. All totals are framed as historical completed-player totals or dated snapshots.

## Integration review

Replaced City’s repeated 1880 foundation-year question with the founding church, St Mark’s, using the same opened club-history timeline. The initial introduction already teaches the foundation year; the new history lesson now adds a distinct fact.

## Score interaction review

Explicit score answers with already verified club badges now carry score-input metadata for the native two-column number wheels. Prompts identify both teams and the event/date or season; aggregate results are labelled as aggregate. Other opponents remain text choices until their badge identities are verified.
