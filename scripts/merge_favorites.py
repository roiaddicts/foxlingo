"""Compile separately sourced deeper favorite stories without replacing old IDs."""
from pathlib import Path
import json,uuid
ROOT=Path(__file__).resolve().parents[1]
NS=uuid.UUID('37ac373c-bf94-43fa-bf40-bfa0283391a3')
def uid(key):return str(uuid.uuid5(NS,key))
def merge(pack,content_path='content/favorites-enrichment.json',include_club_context=True):
 data=json.loads((ROOT/content_path).read_text())
 pack['entities'].extend(data.get('entities',[]))
 pack['sources'].extend(data['sources'])
 for draft in data['lessons']:
  subject=next(e for e in pack['entities'] if e['key']==draft['subjectKey'])
  club=next(e for e in pack['entities'] if e['key']==draft['clubKey'])
  objective_ids=[]
  for row in draft['facts']:
   fk='fact-enrichment-'+row['key'];ok='objective-enrichment-'+row['key']
   value=dict(row['value'])
   if value['kind']=='entity':
    entity_key=value.pop('entityKey')
    value['entityID']=next(e['id'] for e in pack['entities'] if e['key']==entity_key)
   pack['facts'].append(dict(id=uid(fk),key=fk,subjectID=subject['id'],predicate=row['key'],value=value,scope=row['scope'],sourceKeys=[row['sourceKey']],evidence=row['evidence']))
   pack['objectives'].append(dict(id=uid(ok),key=ok,factIDs=[uid(fk)],prompt=row['prompt'],answers=row['answers'],feedback=f"{row['label']}: {value['display']}. Context: {row['scope']}.",revision=1))
   objective_ids.append(uid(ok))
  exercises=[]
  for n,index in enumerate([0,1,2,0]):
   row=draft['facts'][index];key=draft['key'].replace('lesson-','exercise-')+'-choice-'+str(n)
   pack['exercises'].append(dict(id=uid(key),key=key,kind='choice',objectiveIDs=[objective_ids[index]],prompt=row['prompt'],feedback=pack['objectives'][-3+index]['feedback'],choices=[dict(id='choice-'+str(i),text=answer) for i,answer in enumerate([row['answers'][0]]+row['distractors'])],answerIDs=['choice-0'],left=[],right=[],pairs=[]));exercises.append(uid(key))
  lesson=dict(id=uid(draft['key']),key=draft['key'],title=draft['title'],subtitle=draft['subtitle'],story=draft['story'],objectiveIDs=objective_ids,exerciseIDs=exercises)
  pack['lessons'].append(lesson)
  for roadmap in pack['roadmaps']:
   if (roadmap.get('subjectID') or roadmap.get('clubID')) in ({subject['id'],club['id']} if include_club_context else {subject['id']}):
    # Favorite club paths include all their deeper stories; player paths include
    # only their own new knowledge, leaving optional club context untouched.
    chapter=next((c for c in roadmap['chapters'] if c['key'].endswith('-deeper-stories')),None)
    if chapter is None:
     chapter=dict(key=roadmap['key']+'-deeper-stories',title='Deeper stories',lessonIDs=[]);roadmap['chapters'].append(chapter)
    chapter['lessonIDs'].append(lesson['id'])
  card=next(c for c in pack['cards'] if c['entityID']==subject['id'])
  card['lessonIDs'].append(lesson['id']);card['objectiveIDs'].extend(objective_ids);card['knowledgeVersion']=card['knowledgeVersion']+1
