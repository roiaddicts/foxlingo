"""Extract namespaced historical relationships, never execute the reference bundle."""
from pathlib import Path
import json,re,unicodedata
ROOT=Path(__file__).resolve().parents[1]
import argparse
from futbol11_source import extract, bind_roles, role_data
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--snapshot',type=Path,help='Validated snapshot.json from refresh_futbol11.py')
args=parser.parse_args()
if args.snapshot:
 roles=role_data(args.snapshot);snapshot=json.loads(args.snapshot.read_text())
 fetched_at=snapshot['fetchedAt']
 source_url=snapshot['sourceURL'].rstrip('/')
 source=str(args.snapshot.relative_to(ROOT)) if args.snapshot.is_relative_to(ROOT) else str(args.snapshot)
else:
 datasets=extract((ROOT/'ref/futbol11.js').read_bytes(),'https://futbol-11.com/')
 bindings=bind_roles(datasets);lookup={d['id']:d['data'] for d in datasets};roles={role:lookup[id] for role,id in bindings.items()}
 scope='Historical relationships imported from the supplied Futbol11 bundle; snapshot date unknown. These games do not claim current squads or exhaustive career coverage.'
 source='ref/futbol11.js'
 fetched_at=None
 source_url='https://futbol-11.com'
scope='Historical relationships imported from the supplied Futbol11 bundle; snapshot date unknown. These games do not claim current squads or exhaustive career coverage.'
# Role indexes below are internal compiler aliases, independent of source encounter order.
D={1:roles['countries'],2:roles['gamePlayers'],27:roles['categories'],30:roles['classicPlayers'],31:roles['classicSquads']}
def name(p):return p.get('nickname') or ' '.join(filter(None,[p.get('firstName'),p.get('lastName')]))
def norm(v):return ''.join(c for c in unicodedata.normalize('NFD',v.lower()) if not unicodedata.combining(c))
def ints(v):return list(dict.fromkeys(int(x.strip()) for x in v.split(',') if x.strip()))
def imageurl(v):return source_url+v if v.startswith('/') else v
categories=[dict(id=f'category-{p["id"]}',title=p['title'],playerIDs=[f'player-{i}' for i in ints(p['players'])]) for p in D[27]]
# Visual clues are content, so new boards can ship with their own badges and flags.
club_visuals={1:('arsenal',52280),3:('manchester-united',52682),4:('liverpool',7889),5:('chelsea',52914),6:('tottenham',1652),8:('barcelona',50080),9:('madrid',50051),14:('bayern-munich',50037),15:('borussia-dortmund',52758)}
flags={23:'Germany',24:'Brazil',28:'Portugal',30:'Spain'}
country_visuals={norm(p['name']):dict(imageAsset='flag-'+norm(p['name']).replace(' ','-'),imageURL=imageurl(p['flag'])) for p in D[1]}
country_visuals['czechia']=country_visuals['czech republic'];country_visuals['turkiye']=country_visuals['turkey']
country_visuals['azerbaijan']=dict(imageAsset='flag-azerbaijan',imageURL='https://flagcdn.com/w160/az.png')
for c in categories:
 i=int(c['id'].split('-')[-1])
 if i in flags:c.update(country_visuals[norm(flags[i])])
 elif i in club_visuals:
  key,uefa=club_visuals[i];c['imageAsset']='entity-'+key;c['imageURL']=f'https://img.uefa.com/imgml/TP/teams/logos/100x100/{uefa}.png'
players=[dict(id=f'player-{p["id"]}',name=name(p),aliases=list(dict.fromkeys(filter(None,[name(p),' '.join(filter(None,[p.get('firstName'),p.get('lastName')]))]))),imageURL=imageurl(p['image']) if p.get('image') else None,imageAsset=f'seed-player-{p["id"]}') for p in D[2]]
# Classic squads use a separate ID namespace. Portrait joins require the explicit preserved crosswalk.
portraits={f'player-{p["id"]}':p for p in D[2]}
crosswalk={r['classicID']:r for r in json.loads((ROOT/'content/classic-portrait-crosswalk.json').read_text())}
classic={p['id']:p for p in D[30]};lineups=[]
ordered=sorted(D[31],key=lambda s:([35,36,37,38].index(s['id']) if s['id'] in [35,36,37,38] else 4+s['id']))
for squad in ordered:
 members=[]
 for i in ints(squad['players']):
  p=classic[i];pid=f'classic-player-{i}';link=crosswalk.get(pid);photo=portraits.get(link['portraitID']) if link else None
  if link and (norm(name(p)) != norm(link['classicName']) or photo is None or norm(name(photo)) != norm(link['portraitName'])):raise ValueError('Curated portrait identity changed: '+pid)
  if not any(v['id']==pid for v in players):players.append(dict(id=pid,name=name(p),aliases=[name(p)],imageURL=imageurl(photo['image']) if photo and photo.get('image') else None,imageAsset=f'seed-player-{photo["id"]}' if photo else None))
  members.append(dict(playerID=pid,positions=[v.strip() for v in p['positions'].split(',') if v.strip()]))
 lineups.append(dict(id=f'lineup-{squad["id"]}',title=squad['name'].replace('Real M','Real Madrid'),imageAsset=f'classic-shirt-{squad["id"]}',clubName=squad['name'].rsplit(' ',1)[0].replace('Real M','Real Madrid'),imageURL=imageurl(squad['logo']),scope='Build a valid 4–3–3 using this historical season squad; this is not a particular match’s starting XI.',source=source,members=members,positions=['LW','ST','RW','CM','CM','CDM','LB','CB','CB','RB','GK']))
def solvable(squad):
 match={}
 def assign(slot,seen):
  for member in squad['members']:
   player=member['playerID']
   if squad['positions'][slot] not in member['positions'] or player in seen:continue
   seen.add(player)
   if player not in match or assign(match[player],seen):match[player]=slot;return True
  return False
 return all(assign(i,set()) for i in range(11))
for squad in lineups:
 if not solvable(squad):
  squad['positions']=['ST','ST','CAM','CM','CM','CDM','LB','CB','CB','RB','GK']
  squad['rows']=[[0,1],[2],[3,4,5],[6,7,8,9],[10]]
  squad['scope']='Build a valid 4–3–1–2 from this historical season squad; this is a playable formation, not a claimed match starting XI.'
 if not solvable(squad):raise ValueError('No supported formation for '+squad['title'])
pack=dict(schemaVersion=1,fetchedAt=fetched_at,scope=scope,sourceURL=source_url+'/',players=players,categories=categories,bingoCategoryIDs=[f'category-{i}' for i in [1,3,4,5,6,8,9,14,15,23,24,28]],gridRowIDs=[f'category-{i}' for i in [9,8,14]],gridColumnIDs=[f'category-{i}' for i in [30,24,23]],lineups=lineups)
known={p['id'] for p in players}
for c in categories:
 if not set(c['playerIDs']).issubset(known):raise ValueError('Unresolved category members: '+c['id'])
# Source IDs stay in their own proven role. A reused ID cannot overwrite progress.
previous_path=ROOT/'Foxlingo/Resources/games-en.json'
if previous_path.exists():
 previous=json.loads(previous_path.read_text());new_ids={p['id']:p for p in players}
 changed=[p['id'] for p in previous['players'] if p['id'] in new_ids and norm(p['name']) != norm(new_ids[p['id']]['name'])]
 for key in ['categories','lineups']:
  updated={v['id']:v for v in pack[key]}
  reused=[v['id'] for v in previous[key] if v['id'] in updated and norm(v['title']) != norm(updated[v['id']]['title'])]
  if reused:raise ValueError('Reused '+key+' identifiers: '+str(reused))
 if changed:raise ValueError('Player IDs changed identity; explicit crosswalk required: '+str(changed[:20]))
 group_rows=roles['gameGroups']
 for category in categories:
  if category.get('imageURL'):continue
  if category['title'].startswith('Played for '):
   target=norm(category['title'][11:]);matches=[g for g in group_rows if g['type'].startswith('club') and norm(g['name']) == target]
   if len(matches)==1:category['imageURL']=imageurl(matches[0]['logo'])
  elif category['title'].startswith('From '):
   target=norm(category['title'][5:]);matches=[c for c in D[1] if norm(c['name']) == target]
   if len(matches)==1:category['imageURL']=imageurl(matches[0]['flag'])
(ROOT/'content/country-artwork.json').write_text(json.dumps(country_visuals,indent=2)+'\n')
(ROOT/'Foxlingo/Resources/games-en.json').write_text(json.dumps(pack,ensure_ascii=False,indent=2)+'\n')
print(len(players),'players;',len(categories),'categories;',len(lineups),'classic squads')
