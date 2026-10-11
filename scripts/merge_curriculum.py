"""Compile sourced history and player chapters without replacing learned IDs."""
import json
from pathlib import Path
from merge_favorites import uid
ROOT=Path(__file__).resolve().parents[1]
CHAPTERS={'history':'History & identity','moments':'Defining moments','players':'Players & legacies','career':'Career journey','records':'Records & honours','legacy':'Legacy'}

def merge(pack):
    registry=ROOT/'content/curriculum-packs.json'
    settings=json.loads(registry.read_text()) if registry.exists() else {}
    names=settings.get('packs',[])
    if len(names)!=len(set(names)) or any(Path(name).name!=name or not name.startswith('curriculum-') or not name.endswith('.json') for name in names):raise ValueError('Invalid curriculum pack registry')
    paths=[ROOT/'content'/name for name in names]
    documents=[json.loads(path.read_text()) for path in paths]
    seeds={p['id']:p for p in json.loads((ROOT/'Foxlingo/Resources/games-en.json').read_text())['players']}
    entities={e['key']:e for e in pack['entities']}
    sources={s['key']:s for s in pack['sources']}
    existing_lessons={l['key'] for l in pack['lessons']}
    facts={f['key'] for f in pack['facts']}
    # Validate the complete authoring set before mutating the compiled pack.
    for data in documents:
        for source in data['sources']:
            if source['key'] in sources and sources[source['key']]!=source:raise ValueError('Conflicting source: '+source['key'])
            if not source['url'].startswith('https://') or not source.get('verifiedAt'):raise ValueError('Missing source provenance')
            sources[source['key']]=source
        for player in data.get('players',[]):
            if player['key'] in entities:raise ValueError('Existing player must use enrichment: '+player['key'])
            if player['clubKey'] not in entities:raise ValueError('Unknown player club')
            if player.get('seedID'):
                seed=seeds.get(player['seedID'])
                if not seed or seed['name']!=player.get('seedName'):raise ValueError('Player portrait identity changed: '+player['key'])
            entities[player['key']]={'id':uid(player['key']),'key':player['key'],'type':'player','name':player['name']}
        for lesson in data['lessons']:
            if lesson['key'] in existing_lessons:raise ValueError('Duplicate lesson: '+lesson['key'])
            existing_lessons.add(lesson['key'])
            if lesson['subjectKey'] not in entities or lesson['clubKey'] not in entities or lesson['chapter'] not in CHAPTERS:raise ValueError('Missing lesson context')
            if len(lesson['facts'])!=3 or len(lesson['story'])!=2 or any(not s.get('title') or not s.get('body') for s in lesson['story']):raise ValueError('A lesson requires three distinct facts and two story screens')
            for row in lesson['facts']:
                key='fact-enrichment-'+row['key']
                if key in facts:raise ValueError('Duplicate fact: '+key)
                facts.add(key)
                choices=[row['answers'][0],*row['distractors']]
                normalize=lambda x:' '.join(x.casefold().split())
                if len(choices)!=4 or len(set(map(normalize,choices)))!=4 or set(map(normalize,row['answers'])) & set(map(normalize,row['distractors'])):raise ValueError('Ambiguous choice set: '+key)
                if row['sourceKey'] not in sources or not row['evidence'] or not row['scope']:raise ValueError('Missing fact evidence: '+key)
                value=row['value']
                if not isinstance(value.get('display'),str) or not value['display'].strip():raise ValueError('Fact display must be nonempty text: '+key)
                if value['kind']=='entity' and value['entityKey'] not in entities:raise ValueError('Unknown fact entity')
                if value['kind']=='number' and (not isinstance(value['number'],(int,float)) or not value['unit']):raise ValueError('Unscoped numeric fact')
                if value['kind'] not in ['text','number','entity']:raise ValueError('Unsupported fact value')
                if score:=row.get('scoreInput'):
                    for side in ['left','right']:
                        team=entities.get(score[side+'ClubKey'])
                        if not team or team['type']!='club' or not team.get('imageAsset'):raise ValueError('Score team needs a canonical club badge: '+key)
                        goals=score[side+'Goals']
                        if type(goals)!=int or not 0<=goals<=20:raise ValueError('Invalid score: '+key)
                    if f"{score['leftGoals']}–{score['rightGoals']}" not in row['answers']:raise ValueError('Score orientation disagrees with accepted answer: '+key)
    pack['sources']=list(sources.values())
    old_cards={c['entityID']:c['knowledgeVersion'] for c in pack['cards']};changed_cards=set()
    # The original intro compiler shares these lists with chapter definitions.
    # Detach before extending a card so its first chapter cannot silently grow.
    for card in pack['cards']:
        card['lessonIDs']=list(card['lessonIDs']);card['objectiveIDs']=list(card['objectiveIDs'])
    for data in documents:
        for draft in data['lessons']:
            club=entities[draft['clubKey']]
            if any(r.get('clubID')==club['id'] and not r.get('subjectID') for r in pack['roadmaps']):continue
            if not any(l['subjectKey']==club['key'] and l['chapter']=='history' for l in data['lessons']):raise ValueError('New club path needs authored history')
            rk='roadmap-'+club['key'].removeprefix('entity-')
            pack['roadmaps'].append(dict(id=uid(rk),key=rk,clubID=club['id'],summary='Club history, defining moments and player legacies.',chapters=[]))
            if not any(c['entityID']==club['id'] for c in pack['cards']):
                ck='card-'+club['key'].removeprefix('entity-')
                pack['cards'].append(dict(id=uid(ck),key=ck,entityID=club['id'],objectiveIDs=[],lessonIDs=[],knowledgeVersion=1,caption='History, defining moments and player legacies'))
        for player in data.get('players',[]):
            key=player['key'];seed=seeds.get(player.get('seedID'))
            entity=dict(id=uid(key),key=key,type='player',name=player['name'],aliases=player['aliases'],visual=player['visual'],externalRefs={})
            image=player.get('imageURL') or (seed or {}).get('imageURL')
            if image:entity.update(imageAsset=key,imageURL=image)
            if seed:entity['externalRefs']['futbol11.gamePlayers']=player['seedID'].removeprefix('player-')
            pack['entities'].append(entity);entities[key]=entity
            ck='card-'+key.removeprefix('entity-')
            pack['cards'].append(dict(id=uid(ck),key=ck,entityID=entity['id'],objectiveIDs=[],lessonIDs=[],knowledgeVersion=1,caption='Career, defining moments and records'))
            club_path=next(r for r in pack['roadmaps'] if r.get('clubID')==entities[player['clubKey']]['id'] and not r.get('subjectID'))
            rk='roadmap-player-'+key.removeprefix('entity-')
            context=club_path['chapters'][0]['lessonIDs'][0] if club_path['chapters'] else uid(next(l['key'] for l in data['lessons'] if l['subjectKey']==player['clubKey'] and l['chapter']=='history'))
            pack['roadmaps'].append(dict(id=uid(rk),key=rk,subjectID=entity['id'],clubID=entities[player['clubKey']]['id'],summary='Sourced career stories, defining moments and dated records.',chapters=[dict(key=rk+'-club-context',title='Club context',isOptional=True,note='Optional shared club history; it does not count toward player-specific learning.',lessonIDs=[context])]))
        for draft in data['lessons']:
            subject=entities[draft['subjectKey']];club=entities[draft['clubKey']];oids=[];xids=[]
            for row in draft['facts']:
                fk='fact-enrichment-'+row['key'];ok='objective-enrichment-'+row['key'];oids.append(uid(ok));value=dict(row['value'])
                if value['kind']=='entity':value['entityID']=entities[value.pop('entityKey')]['id']
                pack['facts'].append(dict(id=uid(fk),key=fk,subjectID=subject['id'],predicate=row['key'],value=value,scope=row['scope'],sourceKeys=[row['sourceKey']],evidence=row['evidence']))
                pack['objectives'].append(dict(id=uid(ok),key=ok,factIDs=[uid(fk)],prompt=row['prompt'],answers=row['answers'],feedback=f"{row['label']}: {value['display']}. Context: {row['scope']}.",revision=1))
            for n,i in enumerate([0,1,2,0]):
                row=draft['facts'][i];key=draft['key'].replace('lesson-','exercise-',1)+'-choice-'+str(n);xids.append(uid(key))
                pack['exercises'].append(dict(id=uid(key),key=key,kind='choice',objectiveIDs=[oids[i]],prompt=row['prompt'],feedback=f"{row['label']}: {row['value']['display']}. Context: {row['scope']}.",choices=[dict(id='choice-'+str(j),text=a) for j,a in enumerate([row['answers'][0]]+row['distractors'])],answerIDs=['choice-0'],left=[],right=[],pairs=[]))
                if score:=row.get('scoreInput'):
                    pack['exercises'][-1]['scoreInput']=dict(leftEntityID=entities[score['leftClubKey']]['id'],rightEntityID=entities[score['rightClubKey']]['id'],leftGoals=score['leftGoals'],rightGoals=score['rightGoals'],maximum=20)
            lesson=dict(id=uid(draft['key']),key=draft['key'],title=draft['title'],subtitle=draft['subtitle'],story=draft['story'],objectiveIDs=oids,exerciseIDs=xids)
            pack['lessons'].append(lesson)
            player_path=next((r for r in pack['roadmaps'] if r.get('subjectID')==subject['id']),None)
            club_path=next(r for r in pack['roadmaps'] if r.get('clubID')==club['id'] and not r.get('subjectID'))
            routes=[(club_path,'players' if subject['type']=='player' else draft['chapter'])]
            if player_path:routes.append((player_path,draft['chapter']))
            for path,kind in routes:
                key=path['key']+'-curriculum-'+kind
                chapter=next((c for c in path['chapters'] if c['key']==key),None)
                if chapter is None:
                    chapter=dict(key=key,title=CHAPTERS[kind],lessonIDs=[])
                    if path.get('subjectID') and path['chapters'][-1].get('isOptional'):path['chapters'].insert(len(path['chapters'])-1,chapter)
                    else:path['chapters'].append(chapter)
                chapter['lessonIDs'].append(lesson['id'])
            for entity_id in set([subject['id'],club['id']]):
                card=next(c for c in pack['cards'] if c['entityID']==entity_id)
                card['lessonIDs'].append(lesson['id']);card['objectiveIDs'].extend(oids);changed_cards.add(entity_id)
    for card in pack['cards']:
        if card['entityID'] in changed_cards:card['knowledgeVersion']=old_cards.get(card['entityID'],0)+1
    # Rebuilding all packs starts from the original card versions. Persist later
    # expansions explicitly so an existing earned card can accept new knowledge.
    cards_by_key={card['key']:card for card in pack['cards']}
    for key,version in settings.get('cardKnowledgeVersions',{}).items():
        card=cards_by_key.get(key)
        if card is None or type(version)!=int or version<card['knowledgeVersion']:
            raise ValueError('Invalid card knowledge version: '+key)
        card['knowledgeVersion']=version
    for path in pack['roadmaps']:
        if path.get('subjectID'):
            count=sum(len(c['lessonIDs']) for c in path['chapters'] if not c.get('isOptional'))
            path['summary']=f'Career stories, defining moments and dated records across {count} player-specific lessons, plus an optional club story.'
    return sum(len(d['lessons']) for d in documents)
