"""Extract namespaced historical relationships, never execute the reference bundle."""
from pathlib import Path
import json,re,unicodedata
ROOT=Path(__file__).resolve().parents[1]
s=(ROOT/'ref/futbol11.js').read_text();D=[]
for m in re.finditer(r'JSON\.parse\(\s*("(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\')\s*\)',s):
 r=m.group(1);D.append(json.loads(json.loads(r) if r[0]=='"' else r[1:-1].replace("\\'","'")))
def name(p):return p.get('nickname') or ' '.join(filter(None,[p.get('firstName'),p.get('lastName')]))
def norm(v):return ''.join(c for c in unicodedata.normalize('NFD',v.lower()) if not unicodedata.combining(c))
def ints(v):return list(dict.fromkeys(int(x.strip()) for x in v.split(',') if x.strip()))
def imageurl(v):return 'https://futbol-11.com'+v if v.startswith('/') else v
categories=[dict(id=f'category-{p["id"]}',title=p['title'],playerIDs=[f'player-{i}' for i in ints(p['players'])]) for p in D[27] if p['id'] in [1,3,4,5,6,8,9,14,15,23,24,28,30]]
# Visual clues are content, so new boards can ship with their own badges and flags.
club_visuals={1:('arsenal',52280),3:('manchester-united',52682),4:('liverpool',7889),5:('chelsea',52914),6:('tottenham',1652),8:('barcelona',50080),9:('madrid',50051),14:('bayern-munich',50037),15:('borussia-dortmund',52758)}
flags={23:'Germany',24:'Brazil',28:'Portugal',30:'Spain'}
country_visuals={norm(p['name']):dict(imageAsset='flag-'+norm(p['name']).replace(' ','-'),imageURL=imageurl(p['flag'])) for p in D[1]}
country_visuals['czechia']=country_visuals['czech republic'];country_visuals['turkiye']=country_visuals['turkey']
country_visuals['azerbaijan']=dict(imageAsset='flag-azerbaijan',imageURL='https://flagcdn.com/w160/az.png')
for c in categories:
 i=int(c['id'].split('-')[-1])
 if i in flags:c.update(country_visuals[norm(flags[i])])
 else:
  key,uefa=club_visuals[i];c['imageAsset']='entity-'+key;c['imageURL']=f'https://img.uefa.com/imgml/TP/teams/logos/100x100/{uefa}.png'
players=[dict(id=f'player-{p["id"]}',name=name(p),aliases=list(dict.fromkeys(filter(None,[name(p),' '.join(filter(None,[p.get('firstName'),p.get('lastName')]))]))),imageURL=imageurl(p['image']) if p.get('image') else None,imageAsset=f'seed-player-{p["id"]}') for p in D[2]]
# Classic squads reference dataset30, not dataset2. Link portraits only by full-name identity.
portraits={norm(name(p)):p for p in D[2]}
classic={p['id']:p for p in D[30]};lineups=[]
for squad in D[31]:
 if squad['id'] not in [35,36,37,38]:continue
 members=[]
 for i in ints(squad['players']):
  p=classic[i];pid=f'classic-player-{i}';photo=portraits.get(norm(name(p)))
  if not any(v['id']==pid for v in players):players.append(dict(id=pid,name=name(p),aliases=[name(p)],imageURL=imageurl(photo['image']) if photo and photo.get('image') else None,imageAsset=f'seed-player-{photo["id"]}' if photo else None))
  members.append(dict(playerID=pid,positions=p['positions'].split(',')))
 lineups.append(dict(id=f'lineup-{squad["id"]}',title=squad['name'].replace('Real M','Real Madrid'),scope='Build a valid 4–3–3 using this historical season squad; this is not a particular match’s starting XI.',source='ref/futbol11.js · datasets30+31',members=members,positions=['LW','ST','RW','CM','CM','CDM','LB','CB','CB','RB','GK']))
pack=dict(schemaVersion=1,scope='Historical relationships imported from the supplied Futbol11 bundle; snapshot date unknown. These games do not claim current squads or exhaustive career coverage.',sourceURL='https://futbol-11.com/',players=players,categories=categories,bingoCategoryIDs=[f'category-{i}' for i in [1,3,4,5,6,8,9,14,15,23,24,28]],gridRowIDs=[f'category-{i}' for i in [9,8,14]],gridColumnIDs=[f'category-{i}' for i in [30,24,23]],lineups=lineups)
known={p['id'] for p in players}
for c in categories:c['playerIDs']=[i for i in c['playerIDs'] if i in known]
(ROOT/'content/country-artwork.json').write_text(json.dumps(country_visuals,indent=2)+'\n')
(ROOT/'Foxlingo/Resources/games-en.json').write_text(json.dumps(pack,ensure_ascii=False,indent=2)+'\n')
print(len(players),'players;',len(categories),'categories;',len(lineups),'classic squads')
