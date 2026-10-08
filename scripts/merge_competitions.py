"""Compile sourced competition courses as independent canonical subjects."""
from pathlib import Path
import json, uuid
ROOT=Path(__file__).resolve().parents[1]
NS=uuid.UUID('37ac373c-bf94-43fa-bf40-bfa0283391a3')
def uid(key): return str(uuid.uuid5(NS,key))
def merge(pack):
 metadata=json.loads((ROOT/'content/competition-roadmaps.json').read_text())
 content=json.loads((ROOT/'content/competition-lessons.json').read_text())
 pack['sources'].extend(content['sources'])
 for course in metadata:
  key='entity-competition-'+course['key']
  pack['entities'].append(dict(id=uid(key),key=key,type='competition',name=course['name'],aliases=course['aliases'],visual=course['visual'],externalRefs={},imageAsset=key,competitions=[course['membershipScope']]))
 for course in metadata:
  subject=next(e for e in pack['entities'] if e['key']=='entity-competition-'+course['key'])
  drafts=[l for l in content['lessons'] if l['subjectKey']==course['key']]
  if len(drafts)!=3: raise ValueError('Each competition needs three foundation lessons: '+course['key'])
  lesson_ids=[];objective_ids=[];chapters=[]
  for draft in drafts:
   if len(draft['facts'])!=3: raise ValueError('Three anchors required: '+draft['key'])
   lesson_objectives=[]
   for row in draft['facts']:
    fk='fact-competition-'+row['key'];ok='objective-competition-'+row['key'];value=dict(row['value'])
    if value['kind']=='entity':
     entity_key=value.pop('entityKey')
     value['entityID']=next(e['id'] for e in pack['entities'] if e['key']==entity_key)
    pack['facts'].append(dict(id=uid(fk),key=fk,subjectID=subject['id'],predicate=row['key'],value=value,scope=row['scope'],sourceKeys=[row['sourceKey']],evidence=row['evidence']))
    pack['objectives'].append(dict(id=uid(ok),key=ok,factIDs=[uid(fk)],prompt=row['prompt'],answers=row['answers'],feedback=f"{row['label']}: {value['display']}. Context: {row['scope']}.",revision=1))
    lesson_objectives.append(uid(ok))
   exercise_ids=[]
   for n,index in enumerate([0,1,2,0]):
    row=draft['facts'][index];key=draft['key'].replace('lesson-','exercise-')+'-choice-'+str(n)
    pack['exercises'].append(dict(id=uid(key),key=key,kind='choice',objectiveIDs=[lesson_objectives[index]],prompt=row['prompt'],feedback=pack['objectives'][-3+index]['feedback'],choices=[dict(id='choice-'+str(i),text=answer) for i,answer in enumerate([row['answers'][0]]+row['distractors'])],answerIDs=['choice-0'],left=[],right=[],pairs=[]));exercise_ids.append(uid(key))
   lesson=dict(id=uid(draft['key']),key=draft['key'],title=draft['title'],subtitle=draft['subtitle'],story=draft['story'],objectiveIDs=lesson_objectives,exerciseIDs=exercise_ids)
   pack['lessons'].append(lesson);lesson_ids.append(lesson['id']);objective_ids.extend(lesson_objectives)
   chapters.append(dict(key=draft['key']+'-chapter',title=draft['chapterTitle'],lessonIDs=[lesson['id']]))
  optional=next(l for l in pack['lessons'] if l['key']==course['optionalLessonKey'])
  chapters.append(dict(key='competition-'+course['key']+'-club-context',title='A connected club story',lessonIDs=[optional['id']],isOptional=True,note='Shared club context. These facts are optional and do not count toward competition foundations.'))
  rk='roadmap-competition-'+course['key'];ck='card-competition-'+course['key']
  pack['roadmaps'].append(dict(id=uid(rk),key=rk,subjectID=subject['id'],summary=course['summary'],chapters=chapters))
  pack['cards'].append(dict(id=uid(ck),key=ck,entityID=subject['id'],objectiveIDs=objective_ids,lessonIDs=lesson_ids,knowledgeVersion=1,caption=course['caption']))
