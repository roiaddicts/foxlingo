"""Add authored player paths using canonical club context and explicit seed identities."""
from pathlib import Path
import json
from merge_favorites import merge, uid

ROOT=Path(__file__).resolve().parents[1]

def compile_catalog(pack):
    data=json.loads((ROOT/'content/player-catalog.json').read_text())
    games=json.loads((ROOT/'Foxlingo/Resources/games-en.json').read_text())
    seeds={p['id']:p for p in games['players']}
    # Country answers can precede the later text-to-country promotion pass.
    # Resolve them from the explicit artwork registry, preserving stable IDs.
    flags=json.loads((ROOT/'content/country-artwork.json').read_text())
    for lesson in data['lessons']:
        for fact in lesson['facts']:
            value=fact['value']; key=value.get('entityKey','')
            if not key.startswith('entity-country-') or any(e['key']==key for e in pack['entities']):
                continue
            name=value['display']; artwork=flags[name.lower()]
            pack['entities'].append(dict(id=uid(key),key=key,type='country',name=name,aliases=[],visual=name[:2].upper(),externalRefs={},**artwork))
    for player in data['players']:
        key=player['key']; seed=seeds[player['seedID']]
        if seed['name'] != player['seedName']:
            raise ValueError('Player portrait identity changed: '+key)
        entity=next((e for e in pack['entities'] if e['key']==key),None)
        if entity is None:
            entity=dict(id=uid(key),key=key,type='player',name=player['name'],aliases=player['aliases'],visual=player['visual'],externalRefs={})
            pack['entities'].append(entity)
        elif entity['type'] != 'player' or entity['name'] not in [player['name']]+player['aliases']:
            raise ValueError('Canonical player identity changed: '+key)
        entity['imageAsset']=key
        entity['imageURL']=player.get('imageURL') or seed.get('imageURL')
        entity['externalRefs']['futbol11.gamePlayers']=player['seedID'].removeprefix('player-')
        if any(c['entityID']==entity['id'] for c in pack['cards']):
            raise ValueError('Existing player card requires explicit enrichment: '+key)
        pack['cards'].append(dict(id=uid('card-'+key.removeprefix('entity-')),key='card-'+key.removeprefix('entity-'),entityID=entity['id'],objectiveIDs=[],lessonIDs=[],knowledgeVersion=1,caption='Career connections and club records'))
    merge(pack,'content/player-catalog.json',include_club_context=False)
    for player in data['players']:
        subject=next(e for e in pack['entities'] if e['key']==player['key'])
        club=next(e for e in pack['entities'] if e['key']==player['clubKey'])
        drafts=[l for l in data['lessons'] if l['subjectKey']==player['key']]
        if len(drafts)!=2:raise ValueError('Each initial player path needs two lessons')
        key='roadmap-player-'+player['key'].removeprefix('entity-')
        club_path=next(r for r in pack['roadmaps'] if r.get('clubID')==club['id'] and not r.get('subjectID'))
        pack['roadmaps'].append(dict(id=uid(key),key=key,subjectID=subject['id'],clubID=club['id'],summary='Six sourced career and club-record memories, plus optional club history.',chapters=[
            dict(key=key+'-career',title='Career connections',lessonIDs=[uid(drafts[0]['key'])]),
            dict(key=key+'-record',title='Club record',lessonIDs=[uid(drafts[1]['key'])]),
            dict(key=key+'-club-context',title='Club context',isOptional=True,note='Optional club history; these lessons do not add player-specific career claims.',lessonIDs=[club_path['chapters'][0]['lessonIDs'][0]])]))
        record=next(f for f in drafts[1]['facts'] if f['value']['kind']=='number' and any(w in f['value']['unit'] for w in ['appearances','games']))
        edge_key='relationship-catalog-'+player['key'].removeprefix('entity-')+'-club-record'
        pack['relationships'].append(dict(id=uid(edge_key),key=edge_key,subjectID=subject['id'],objectID=club['id'],group='history',label='Played for',claim=f"{subject['name']} recorded {record['value']['number']} appearances for {club['name']}.",scope=record['scope'],factIDs=[uid('fact-enrichment-'+record['key'])]))
        card=next(c for c in pack['cards'] if c['entityID']==subject['id']);card['knowledgeVersion']=1
