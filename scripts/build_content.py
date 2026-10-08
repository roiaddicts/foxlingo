"""Build the curated starter pack. Stable IDs survive repeated runs."""
from pathlib import Path
import json, uuid, re, unicodedata
ROOT=Path(__file__).resolve().parents[1]
NAMESPACE=uuid.UUID('37ac373c-bf94-43fa-bf40-bfa0283391a3')
def uid(key): return str(uuid.uuid5(NAMESPACE,key))
source_data=[
('x-history','Xolos club history','https://www.xolos.com.mx/historia-del-club'),
('x-venue','Estadio Caliente anniversary','https://xolos.com.mx/noticias/primer-equipo/11738'),
('x-title','Xolos historical recap','https://xolos.com.mx/noticias/primer-equipo/7815'),
('x-final','Apertura 2012 final recap','https://xolos.com.mx/noticias/primer-equipo/3342'),
('x-riascos','Riascos signing announcement','https://xolos.com.mx/noticias/xoloitzcuintles/2515/%E2%80%9C'),
('x-arce','Fernando Arce interview, Apertura 2012','https://xolos.com.mx/noticias/primer-equipo/7521'),
('x-saucedo','Clausura 2012 award nominations','https://xolos.com.mx/noticias/xoloitzcuintles/2189/www.codersmx.com'),
('r-history','Real Madrid: 124 years of history','https://www.realmadrid.com/en-US/news/club/latest-news/124-anos-de-leyenda-06-03-2026'),
('r-final','La Décima anniversary','https://www.realmadrid.com/es-ES/noticias/club/actualidad/octavo-aniversario-de-la-decima'),
('r-cristiano','Cristiano Ronaldo: club legend','https://www.realmadrid.com/en-US/the-club/history/football-legends/cristiano-ronaldo-dos-santos-aveiro/'),
('r-ramos','Sergio Ramos: club legend','https://www.realmadrid.com/en-US/the-club/history/football-legends/sergio-ramos-garcia?pid=1384791177940'),
('r-casillas','Iker Casillas: club legend','https://www.realmadrid.com/en-US/the-club/history/football-legends/iker-casillas-fernandez')]
entities=[]
for key,name,kind,visual,aliases in [
('xolos','Club Tijuana','club','XT',['Xolos','Club Tijuana Xoloitzcuintles de Caliente']),('madrid','Real Madrid','club','RM',[]),
('riascos','Duvier Riascos','player','DR',[]),('arce','Fernando Arce','player','FA',[]),('saucedo','Cirilo Saucedo','player','CS',[]),
('cristiano','Cristiano Ronaldo','player','CR',['Ronaldo']),('ramos','Sergio Ramos','player','SR',[]),('casillas','Iker Casillas','player','IC',[])]:
 refs={}
 if key=='madrid': refs={'futbol11.dataset12':'14','futbol11.dataset19':'9','futbol11.dataset35':'14'}
 if key=='cristiano': refs={'futbol11.dataset2':'1'}
 if key=='casillas': refs={'futbol11.dataset2':'53'}
 entities.append(dict(id=uid('entity-'+key),key='entity-'+key,type=kind,name=name,aliases=aliases,visual=visual,externalRefs=refs))
# Supporting subjects provide reusable relationship targets without extra collectible cards.
for key,name,kind,visual in [('toluca','Toluca','club','TO'),('atletico','Atlético de Madrid','club','AM'),('puebla','Puebla','club','PU'),('di-stefano','Alfredo Di Stéfano','player','AD'),('city-tijuana','Tijuana','city','TJ'),('city-madrid','Madrid','city','MD'),('colombia','Colombia','country','CO'),('caliente','Estadio Caliente','venue','EC')]:
 entities.append(dict(id=uid('entity-'+key),key='entity-'+key,type=kind,name=name,aliases=[],visual=visual,externalRefs={}))
# Facts: key, prompt, answer aliases, distractors, compact board label, source key.
lessons_data=[
('xolos','identity','Meet Xolos','A club from the border','xolos',
('A name to remember','Club Tijuana is also known as Xolos. Its longer name, Xoloitzcuintles, gives the club a distinctive identity. Start by connecting the short name to the club rather than memorizing every letter at once. The club represents Tijuana, a city in Baja California. That geographical connection is the first anchor for this roadmap.'),
('The home ground','Estadio Caliente is the home ground to associate with Xolos. Keep three pieces together: Club Tijuana, the city of Tijuana, and Estadio Caliente. They answer different questions—who, where, and which venue. In the activities that follow, practice those connections in both directions. You do not need a current squad list to recognize the club and begin understanding its story.'),
[('nickname','Which nickname belongs to Club Tijuana?',['Xolos'],['Merengues','Diablos Rojos','Rayados'],'Club nickname','x-history'),('city','Which city does Club Tijuana represent?',['Tijuana'],['Monterrey','Toluca','Guadalajara'],'Home city','x-history'),('stadium','What is Xolos’s home stadium?',['Estadio Caliente','Caliente Stadium'],['Estadio Azteca','Estadio Nemesio Diez','Santiago Bernabéu'],'Home stadium','x-venue')]),
('xolos','climb','The climb','From a new club to champions','xolos',
('Three years to anchor','The Xolos story starts in 2007. The next major anchor is promotion to Mexico’s top division in 2011. Those dates describe different milestones: beginning a club and earning a place in a higher division. Keeping the events separate is more useful than learning an isolated list of numbers.'),
('A rapid rise','The third anchor is Apertura 2012, when Xolos won their first top-flight league championship. Follow the sequence: founded in 2007, promoted in 2011, champions in 2012. When recalling the years, say the event alongside the number. The next lesson explores the final behind that title. This is a historical sequence, not a statement about the club’s current standings.'),
[('founded','In which year was Club Tijuana founded?',['2007'],['1902','2011','2012'],'Foundation year','x-history'),('promoted','In which year did Xolos earn promotion to the top division?',['2011'],['2007','2010','2013'],'Promotion year','x-history'),('champion','Which tournament brought Xolos their first top-flight league title?',['Apertura 2012','2012 Apertura'],['Clausura 2011','Apertura 2010','Clausura 2013'],'First league title','x-title')]),
('xolos','final','The 2012 final','The night a title became history','xolos',
('The opponent','Xolos faced Toluca in the Apertura 2012 final. A final is easier to remember as a story with two sides than as a title in a trophy list. The opponent matters because it lets you connect the achievement to an actual contest. For this lesson, the relevant championship is the 2012 Apertura, not an undated league title.'),
('The result','Xolos won the two-leg final 4–1 on aggregate and secured the championship on December 2, 2012. Aggregate means the goals across both legs are combined; it is not the score of a single match. Practice the opponent, the aggregate result, and the title date as separate facts. Together they provide a compact account of a defining moment in the club’s history.'),
[('opponent','Who faced Xolos in the Apertura 2012 final?',['Toluca','CD Toluca','Deportivo Toluca'],['León','Monterrey','Pumas'],'Final opponent','x-title'),('aggregate','What was the aggregate score in Xolos’s favor in the 2012 final?',['4–1','4-1','4 to 1'],['2–1','3–0','2–0'],'Aggregate score','x-final'),('date','On what date did Xolos secure the Apertura 2012 title?',['December 2, 2012','2 December 2012','2012-12-02','December 2 2012'],['November 29, 2012','May 24, 2014','January 14, 2007'],'Title date','x-title')]),
('xolos','riascos','Duvier Riascos','A forward’s route to Tijuana','riascos',
('Meet the player','Duvier Riascos is a Colombian forward. Learn the country and position as separate connections: where the player comes from and the role he plays. This lesson focuses on the period around his move to Xolos, rather than presenting an up-to-date career profile. Historical scope helps you avoid confusing a former club with a current one.'),
('The previous stop','Before joining Xolos for Clausura 2012, Riascos played for Puebla in Apertura 2011. That sequence gives you a small piece of his career path: Puebla, then Club Tijuana. Recall the club name with the period attached. The questions here are about that move, his Colombian origin, and his forward role. They do not ask which team he represents today.'),
[('country','Which country is Duvier Riascos from?',['Colombia'],['Mexico','Ecuador','Argentina'],'Country of origin','x-riascos'),('position','What position did Riascos play?',['Forward','Striker','Delantero'],['Goalkeeper','Defender','Midfielder'],'Playing role','x-riascos'),('previous','Which club did Riascos represent in Apertura 2011 before joining Xolos?',['Puebla','Puebla FC'],['Toluca','Real Madrid','Monterrey'],'Previous club','x-riascos')]),
('xolos','arce','Fernando Arce','A midfielder with a local connection','arce',
('A local connection','Fernando Arce is described by the club as a midfielder from Tijuana. Those two details make useful anchors: the role he played and his local connection. A player’s birthplace or hometown is different from his club affiliation. Separating those relationships helps you understand a profile instead of remembering a single label.'),
('Place him in the story','During Apertura 2012, Arce represented Xolos. The club’s interview from that tournament connects his name to the team and its preparations. For now, learn three concise relationships: Arce to midfield, Arce to Tijuana, and Arce to Xolos during Apertura 2012. Later content can expand his career without replacing these historically scoped foundations. This lesson does not describe his current role or employer.'),
[('position','What playing role did Fernando Arce have?',['Midfielder','Midfield','Centrocampista'],['Goalkeeper','Forward','Defender'],'Playing role','x-arce'),('city','Which city is connected to Arce’s local origins?',['Tijuana'],['Madrid','Toluca','Monterrey'],'Local connection','x-arce'),('club','Which team did Arce represent during Apertura 2012?',['Xolos','Club Tijuana','Tijuana'],['Toluca','Real Madrid','León'],'Apertura 2012 club','x-arce')]),
('xolos','saucedo','Cirilo Saucedo','Reading a goalkeeper’s numbers','saucedo',
('Between the posts','Cirilo Saucedo played as a goalkeeper for Xolos. Goalkeeper statistics need precise context: goals conceded in a regular phase are different from goals conceded across a whole tournament with playoffs. This lesson uses the Clausura 2012 regular phase, as reported in the club’s announcement about award nominations.'),
('Keep the scope attached','Saucedo conceded 11 goals in 17 regular-phase matches during Clausura 2012. Learn the pair together—11 goals, 17 matches—then attach the tournament and phase. These are historical numbers, not a live performance total. When comparing players later, check that their numbers cover the same type of period. The exercises here ask about Saucedo’s role and these two specifically scoped figures.'),
[('position','What position did Cirilo Saucedo play?',['Goalkeeper','Keeper','Portero'],['Forward','Defender','Midfielder'],'Playing role','x-saucedo'),('conceded','How many goals did Saucedo concede in the Clausura 2012 regular phase?',['11','eleven'],['8','17','19'],'Goals conceded','x-saucedo'),('matches','How many regular-phase matches did Saucedo play in Clausura 2012?',['17','seventeen'],['11','19','8'],'Matches played','x-saucedo')]),
('madrid','identity','Meet Madrid','A name, a city, a beginning','madrid',
('The club and the city','Real Madrid is the club at the center of this roadmap. Connect its name to Madrid before adding players, titles, and matches. A club’s identity is a useful starting point because many later facts will refer back to it. Keep club and city as distinct ideas, even when the city is part of the name.'),
('The starting year','The club traces its beginning to 1902, when the first board of Madrid Foot Ball Club was elected on March 6. For this introductory lesson, remember the founding year rather than trying to learn every administrative detail. Your three anchors are the club name, Madrid, and 1902. The next lesson follows the story into the early European Cup era.'),
[('name','Which club is this roadmap about?',['Real Madrid','Real Madrid CF'],['Atlético de Madrid','Barcelona','Club Tijuana'],'Club name','r-history'),('city','Which city is Real Madrid associated with?',['Madrid'],['Barcelona','Lisbon','Tijuana'],'Home city','r-history'),('founded','In which year does Real Madrid’s history begin?',['1902'],['2007','1956','2014'],'Founding year','r-history')]),
('madrid','roots','European roots','The first five European Cups','madrid',
('A European beginning','Real Madrid won the first European Cup in 1956. The competition name matters: this is the historical European Cup era, before the modern Champions League name. Use 1956 as the starting anchor, then connect it to the run that followed rather than treating each trophy as an unrelated fact.'),
('The early run','Madrid won the first five European Cups consecutively, from 1956 through 1960. Alfredo Di Stéfano is one of the players the club associates with that era. These three anchors—1956, five consecutive titles, and Di Stéfano—help you recognize the period. They describe an early chapter of the club’s history, not its current total of European trophies or a ranking of every player.'),
[('first','In which year did Madrid win the first European Cup?',['1956'],['1960','1902','2014'],'First European Cup','r-history'),('count','How many European Cups did Madrid win consecutively from 1956 to 1960?',['5','five'],['3','4','6'],'Consecutive titles','r-history'),('player','Which player belongs to Madrid’s early European Cup era?',['Alfredo Di Stéfano','Di Stéfano','Alfredo Di Stefano','Di Stefano'],['Sergio Ramos','Iker Casillas','Cristiano Ronaldo'],'Era-defining player','r-history')]),
('madrid','decima','La Décima','An equalizer that changed a final','madrid',
('The setting','In 2014, Real Madrid faced Atlético in the Champions League final. The match became the night of La Décima, Madrid’s tenth European Cup. Learn the year and opponent before the decisive event. That context lets you connect the story to the correct final rather than mixing it with another Madrid title.'),
('The turning point','Sergio Ramos scored the equalizer in added time, sending the final into extra time. Madrid then won the match. For this lesson, focus on the turning point: Ramos’s goal changed what could have been a defeat into another period of play. Recall the opponent, the year, and the equalizer’s scorer. The player lessons connect those facts to individual careers.'),
[('opponent','Who faced Real Madrid in the 2014 Champions League final?',['Atlético de Madrid','Atlético','Atletico Madrid','Atletico de Madrid','Atlético Madrid'],['Barcelona','Juventus','Bayern Munich'],'Final opponent','r-final'),('year','In which year did Madrid win La Décima?',['2014'],['2012','2016','1956'],'La Décima year','r-final'),('equalizer','Who scored Madrid’s equalizer to force extra time in the 2014 final?',['Sergio Ramos','Ramos'],['Cristiano Ronaldo','Iker Casillas','Gareth Bale'],'Equalizer scorer','r-final')]),
('madrid','cristiano','Cristiano Ronaldo','A forward in the 2014 story','cristiano',
('Meet the forward','Cristiano Ronaldo is a forward associated with Real Madrid’s history. This card focuses on that part of his career, not his current club. Learn his name and role before adding a long list of statistics. Club associations need a time frame, especially for players whose careers include several teams.'),
('A final connection','Ronaldo scored a penalty for Real Madrid in the 2014 Champions League final. That connects his player card to the La Décima lesson. The three facts here are his forward role, his Real Madrid career association, and the penalty in that final. You can use the same event to understand a player and a club without counting it as two independent memories.'),
[('position','What playing role is Cristiano Ronaldo known for?',['Forward','Striker'],['Goalkeeper','Defender','Midfielder'],'Playing role','r-cristiano'),('club','Which club did Ronaldo represent in the 2014 Champions League final?',['Real Madrid','Real Madrid CF'],['Manchester United','Juventus','Sporting CP'],'Club in that final','r-final'),('goal','How did Ronaldo score in the 2014 Champions League final?',['Penalty','A penalty','Penalty kick'],['Header','Free kick','Own goal'],'Type of goal','r-final')]),
('madrid','ramos','Sergio Ramos','A defender with a scoring story','ramos',
('The defender','Sergio Ramos played as a defender for Real Madrid. His equalizer in the 2014 Champions League final is a key event to connect to that role. A position tells you a player’s usual responsibilities; it does not limit the kinds of decisive contributions he can make in a match.'),
('A scoped total','Real Madrid’s historical player profile records 101 goals for Ramos during his club career. Keep the club scope attached: this is not a total for every team he represented. Your three anchors are defender, scorer of the 2014 equalizer, and 101 Real Madrid goals. The equalizer also appears in the club lesson, so review should recognize it as shared knowledge rather than demand duplicate work.'),
[('position','What position did Sergio Ramos play?',['Defender','Centre-back','Center-back'],['Goalkeeper','Forward','Midfielder'],'Playing role','r-ramos'),('equalizer','Who scored Madrid’s equalizer to force extra time in the 2014 final?',['Sergio Ramos','Ramos'],['Cristiano Ronaldo','Iker Casillas','Gareth Bale'],'Equalizer scorer','r-final'),('goals','How many Real Madrid career goals does the club record for Ramos?',['101','one hundred one','one hundred and one'],['100','111','91'],'Real Madrid goals','r-ramos')]),
('madrid','casillas','Iker Casillas','The goalkeeper’s long chapter','casillas',
('Meet the goalkeeper','Iker Casillas is a goalkeeper in Real Madrid’s historical player collection. His first-team debut came in 1999. Connect the player to his position and then to the beginning of his senior Madrid career. This is a historical profile, so the lesson does not ask which club he plays for today.'),
('An appearance total','The club records 725 official Real Madrid appearances for Casillas. “Official” and “Real Madrid” both belong with that number: it is not a total of every appearance for club and country. Practice goalkeeper, 1999, and 725 as three distinct facts. Together they provide a compact introduction to his long first-team chapter and a foundation for later lessons about his matches and achievements.'),
[('position','What position did Iker Casillas play?',['Goalkeeper','Keeper','Portero'],['Defender','Forward','Midfielder'],'Playing role','r-casillas'),('debut','In which year did Casillas make his Real Madrid first-team debut?',['1999'],['1990','2002','2015'],'First-team debut','r-casillas'),('appearances','How many official Real Madrid appearances does the club record for Casillas?',['725','seven hundred twenty-five','seven hundred and twenty-five'],['671','741','438'],'Official appearances','r-casillas')])]
pack=dict(schemaVersion=1,key='foxlingo-favorites-en',contentVersion=1,language='en',entities=entities,sources=[dict(key=k,title=t,url=u,verifiedAt='2026-10-08') for k,t,u in source_data],facts=[],objectives=[],roadmaps=[],lessons=[],exercises=[],cards=[])
by_subject={}
for team,key,title,subtitle,subject,story1,story2,rows in lessons_data:
 lk='lesson-'+team+'-'+key
 objs=[]
 for fkey,prompt,answers,wrong,label,source in rows:
  # A shared historical event has one objective across two roadmaps/lessons.
  ok='objective-madrid-equalizer' if team=='madrid' and fkey=='equalizer' else 'objective-'+team+'-'+key+'-'+fkey
  oid=uid(ok); objs.append(oid)
  if not any(o['id']==oid for o in pack['objectives']):
   fk=ok.replace('objective-','fact-')
   scope={'x-saucedo':'Clausura 2012 regular phase','x-arce':'Apertura 2012','x-riascos':'Apertura 2011 to Clausura 2012','r-final':'2014 Champions League final'}.get(source,'Historical club record; checked 2026-10-08')
   targets={'Xolos':'xolos','Real Madrid':'madrid','Toluca':'toluca','Atlético de Madrid':'atletico','Puebla':'puebla','Alfredo Di Stéfano':'di-stefano','Sergio Ramos':'ramos','Tijuana':'city-tijuana','Madrid':'city-madrid','Colombia':'colombia','Estadio Caliente':'caliente'}
   value=dict(kind='text',display=answers[0],text=answers[0])
   if answers[0] in targets: value=dict(kind='entity',display=answers[0],entityID=uid('entity-'+targets[answers[0]]))
   elif answers[0].isdigit(): value=dict(kind='number',display=answers[0],number=int(answers[0]),unit='year' if fkey in ['founded','promoted','first','year','debut'] else 'matches' if fkey in ['matches','appearances'] else 'goals' if fkey in ['goals','conceded'] else 'titles')
   elif fkey=='date': value=dict(kind='date',display=answers[0],text='2012-12-02')
   pack['facts'].append(dict(id=uid(fk),key=fk,subjectID=uid('entity-'+('ramos' if ok=='objective-madrid-equalizer' else subject)),predicate=fkey,value=value,scope=scope,sourceKeys=[source],evidence=prompt+' Answer supported by source: '+answers[0]+'.'))
   pack['objectives'].append(dict(id=oid,key=ok,factIDs=[uid(fk)],prompt=prompt,answers=answers,feedback=f'{label}: {answers[0]}. Context: {scope}.',revision=1))
 exercises=[]
 for n,index in enumerate([0,1,2,0]):
  fkey,prompt,answers,wrong,label,source=rows[index]
  ek=f'exercise-{team}-{key}-choice-{n}'
  choices=[dict(id=f'choice-{i}',text=v) for i,v in enumerate([answers[0]]+wrong)]
  # Rephrasing remains semantic and explicitly scoped.
  if n==3: prompt='Recall the connection: '+prompt
  pack['exercises'].append(dict(id=uid(ek),key=ek,kind='choice',objectiveIDs=[objs[index]],prompt=prompt,feedback=next(o['feedback'] for o in pack['objectives'] if o['id']==objs[index]),choices=choices,answerIDs=['choice-0'],left=[],right=[],pairs=[])); exercises.append(uid(ek))
 ek=f'exercise-{team}-{key}-match'
 pack['exercises'].append(dict(id=uid(ek),key=ek,kind='match',objectiveIDs=objs,prompt='Connect the three facts',feedback='Match each label to the fact from this lesson.',choices=[],answerIDs=[],left=[dict(id=f'l-{i}',text=r[4]) for i,r in enumerate(rows)],right=[dict(id=f'r-{i}',text=r[2][0]) for i,r in enumerate(rows)],pairs=[dict(left=f'l-{i}',right=f'r-{i}') for i in range(3)])); exercises.append(uid(ek))
 pack['lessons'].append(dict(id=uid(lk),key=lk,title=title,subtitle=subtitle,story=[dict(title=story1[0],body=story1[1]),dict(title=story2[0],body=story2[1])],objectiveIDs=objs,exerciseIDs=exercises))
 by_subject.setdefault(subject,[]).append(uid(lk))
for team in ['xolos','madrid']:
 ls=[l for l in pack['lessons'] if l['key'].startswith('lesson-'+team+'-')]
 pack['roadmaps'].append(dict(id=uid('roadmap-'+team),key='roadmap-'+team,clubID=uid('entity-'+team),chapters=[dict(key=team+'-chapter-'+str(i),title=t,lessonIDs=[l['id'] for l in ls[a:b]]) for i,(t,a,b) in enumerate([('Meet the club',0,2),('A defining night',2,3),('Meet the players',3,6)])]))
for subject,lids in by_subject.items():
 oids=list(dict.fromkeys(o for l in pack['lessons'] if l['id'] in lids for o in l['objectiveIDs']))
 pack['cards'].append(dict(id=uid('card-'+subject),key='card-'+subject,entityID=uid('entity-'+subject),objectiveIDs=oids,lessonIDs=lids,knowledgeVersion=1,caption={'xolos':'From the border to the title','madrid':'A European story','riascos':'The forward','arce':'The local connection','saucedo':'Between the posts','cristiano':'The finisher','ramos':'The turning point','casillas':'The goalkeeper'}[subject]))
from merge_expansion import merge
merge(pack)
graph=json.loads((ROOT/'content/graph-connections.json').read_text())
pack['entities'] += graph['entities']
pack['relationships'] = graph['relationships']
pack['roadmaps'] += json.loads((ROOT/'content/player-roadmaps.json').read_text())
# Artwork-only subjects and aliases resolve every authored club/player answer.
# Seed namespaces are kept explicit; these subjects add no career claims or cards.
pack['entities'] += [
 dict(id=uid('entity-juventus'),key='entity-juventus',type='club',name='Juventus',aliases=['Juventus FC'],visual='JU',externalRefs={'futbol11.dataset12':'28'},imageAsset='entity-juventus',imageURL='https://img.uefa.com/imgml/TP/teams/logos/100x100/50139.png'),
 dict(id=uid('entity-bale'),key='entity-bale',type='player',name='Gareth Bale',aliases=['Bale'],visual='GB',externalRefs={'futbol11.dataset2':'9'},imageAsset='entity-bale')]
for key,aliases in {'entity-leon':['León','Leon'], 'entity-pumas':['Pumas'], 'entity-bayern-munich':['Bayern Munich'], 'entity-manchester-united':['Manchester United']}.items():
 entity=next(e for e in pack['entities'] if e['key']==key)
 entity['aliases']=list(dict.fromkeys(entity['aliases']+aliases))
pack['contentVersion']=5
# Promote explicitly authored country values into canonical targets. Preserve
# fact/objective IDs, wording, scope and revision: the taught claim is unchanged.
flags=json.loads((ROOT/'content/country-artwork.json').read_text())
for fact in pack['facts']:
 if fact['predicate'].endswith('-country') and fact['value']['kind']=='text':
  name=fact['value']['display'];plain=''.join(c for c in unicodedata.normalize('NFD',name.lower()) if not unicodedata.combining(c));slug=re.sub(r'[^a-z0-9]+','-',plain).strip('-')
  target=next((e for e in pack['entities'] if e['type']=='country' and e['name']==name),None)
  if target is None:
   key='entity-country-'+slug
   target=dict(id=uid(key),key=key,type='country',name=name,aliases=[],visual=name[:2].upper(),externalRefs={})
   if slug in flags:target.update(flags[slug])
   pack['entities'].append(target)
  fact['value']=dict(kind='entity',display=name,entityID=target['id'])
for entity in pack['entities']:
 if entity['key'] in ['entity-xolos','entity-madrid','entity-cristiano','entity-ramos','entity-casillas','entity-arce','entity-saucedo','entity-riascos','entity-di-stefano']: entity['imageAsset']=entity['key']
out=ROOT/'Foxlingo/Resources/starter-en.json';out.write_text(json.dumps(pack,ensure_ascii=False,indent=2)+'\n')
print(f'{len(pack["lessons"])} lessons, {len(pack["objectives"])} unique objectives, {len(pack["cards"])} cards')

# Mystery boards reference this curriculum by canonical fact/subject IDs.
(ROOT/'Foxlingo/Resources/mystery-en.json').write_text((ROOT/'content/mystery-rounds.json').read_text())

(ROOT/"Foxlingo/Resources/memory-en.json").write_text((ROOT/"content/memory-pairs.json").read_text())
