"""Compile authored club lessons into the same validated JSON contract as the favorites."""
import json,uuid
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
NAMESPACE=uuid.UUID('37ac373c-bf94-43fa-bf40-bfa0283391a3')
def uid(key):return str(uuid.uuid5(NAMESPACE,key))
def merge(pack):
 path=ROOT/'content/club-expansion.json'
 if not path.exists():return
 expansion=json.loads(path.read_text());pack['competitionScopes']=expansion['seasonScopes'];pack['contentVersion']=2
 pack['sources']+=expansion['sources']
 for club in expansion['clubs']:
  ek='entity-'+({'atletico-madrid':'atletico'}.get(club['key'],club['key']));existing=next((e for e in pack['entities'] if e['key']==ek),None)
  if existing is None:
   existing=dict(id=uid(ek),key=ek,type='club',name=club['name'],aliases=club['aliases'],visual=club['visual'],externalRefs={});pack['entities'].append(existing)
  existing['competitions']=club['competitions']
  artworkPath=ROOT/'content/club-artwork.json'
  artwork=json.loads(artworkPath.read_text()) if artworkPath.exists() else {}
  logo=artwork.get(club['key'],{}).get('url') or club['logoURL']
  if logo:existing['imageURL']=logo
  existing['imageAsset']='entity-'+club['key']
  lessons=[];objectives=[]
  for lesson in club['lessons']:
   lk='lesson-'+lesson['key'];oids=[];xids=[]
   for f in lesson['facts']:
    fk='fact-expansion-'+f['key'];ok='objective-expansion-'+f['key'];oid=uid(ok);oids.append(oid);objectives.append(oid)
    pack['facts'].append(dict(id=uid(fk),key=fk,subjectID=existing['id'],predicate=f['key'],value=dict(kind='text',display=f['answers'][0],text=f['answers'][0]),scope=f['scope'],sourceKeys=[f['sourceKey']],evidence=f['evidence']))
    pack['objectives'].append(dict(id=oid,key=ok,factIDs=[uid(fk)],prompt=f['prompt'],answers=f['answers'],feedback=f"{f['label']}: {f['answers'][0]}. Context: {f['scope']}.",revision=1))
   for n,i in enumerate([0,1,2,0]):
    f=lesson['facts'][i];xk=f'exercise-{lesson["key"]}-choice-{n}';xids.append(uid(xk))
    pack['exercises'].append(dict(id=uid(xk),key=xk,kind='choice',objectiveIDs=[oids[i]],prompt=('Recall the connection: ' if n==3 else '')+f['prompt'],feedback=f"{f['label']}: {f['answers'][0]}. Context: {f['scope']}.",choices=[dict(id=f'choice-{j}',text=a) for j,a in enumerate([f['answers'][0]]+f['distractors'])],answerIDs=['choice-0'],left=[],right=[],pairs=[]))
   xk=f'exercise-{lesson["key"]}-match';xids.append(uid(xk))
   pack['exercises'].append(dict(id=uid(xk),key=xk,kind='match',objectiveIDs=oids,prompt='Connect the three facts',feedback='Match the three connections from this club story.',choices=[],answerIDs=[],left=[dict(id=f'l-{i}',text=f['label']) for i,f in enumerate(lesson['facts'])],right=[dict(id=f'r-{i}',text=f['answers'][0]) for i,f in enumerate(lesson['facts'])],pairs=[dict(left=f'l-{i}',right=f'r-{i}') for i in range(3)]))
   pack['lessons'].append(dict(id=uid(lk),key=lk,title=lesson['title'],subtitle=lesson['subtitle'],story=lesson['story'],objectiveIDs=oids,exerciseIDs=xids));lessons.append(uid(lk))
  if lessons:
   rk='roadmap-'+club['key'];pack['roadmaps'].append(dict(id=uid(rk),key=rk,clubID=existing['id'],chapters=[dict(key='chapter-'+club['key'],title='Meet the club',lessonIDs=lessons)]))
   ck='card-'+club['key'];pack['cards'].append(dict(id=uid(ck),key=ck,entityID=existing['id'],objectiveIDs=objectives,lessonIDs=lessons,knowledgeVersion=1,caption='The first chapter'))
