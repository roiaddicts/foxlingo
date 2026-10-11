"""Report real club/player course depth without treating catalog records as lessons."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def audit(pack):
    entities={e['id']:e for e in pack['entities']};lessons={l['id']:l for l in pack['lessons']};facts={f['id']:f for f in pack['facts']};objectives={o['id']:o for o in pack['objectives']}
    def required(path):return set(i for c in path['chapters'] if not c.get('isOptional') for i in c['lessonIDs'])
    def subjects(lesson_ids):return set(facts[f]['subjectID'] for i in lesson_ids for o in lessons[i]['objectiveIDs'] for f in objectives[o]['factIDs'])
    players=[]
    for path in pack['roadmaps']:
        if not path.get('subjectID') or entities[path['subjectID']]['type']!='player':continue
        own=set(i for i in required(path) if path['subjectID'] in subjects([i]));chapters=[c['title'] for c in path['chapters'] if not c.get('isOptional')]
        areas={
            'career': any(any(word in title.lower() for word in ['career','foundations']) for title in chapters),
            'moments': any('moment' in title.lower() for title in chapters),
            'records': any(any(word in title.lower() for word in ['record','honour']) for title in chapters),
        }
        players.append(dict(key=path['key'],name=entities[path['subjectID']]['name'],entityID=path['subjectID'],playerLessons=len(own),chapters=chapters,missingAreas=[area for area,covered in areas.items() if not covered],complete=len(own)>=4 and all(areas.values())))
    by_player={p['entityID']:p for p in players};clubs=[]
    for path in pack['roadmaps']:
        if not path.get('clubID') or path.get('subjectID'):continue
        ids=required(path);related=sorted(subjects(ids)&by_player.keys());moment_ids=set(i for c in path['chapters'] if 'moment' in c['title'].lower() or 'defining' in c['title'].lower() for i in c['lessonIDs'])
        complete_players=[by_player[i]['key'] for i in related if by_player[i]['complete']]
        clubs.append(dict(key=path['key'],name=entities[path['clubID']]['name'],requiredLessons=len(ids),definingMomentLessons=len(moment_ids),playerPaths=[by_player[i]['key'] for i in related],completePlayerPaths=complete_players,complete=len(ids)>1 and len(moment_ids)>=2 and len(complete_players)>=2))
    return dict(contentVersion=pack['contentVersion'],scope='Existing club courses and authored player courses; game catalogs are excluded.',clubs=clubs,players=players,completedClubs=sum(c['complete'] for c in clubs),totalClubs=len(clubs),completedPlayers=sum(p['complete'] for p in players),totalPlayers=len(players))

if __name__=='__main__':
    pack=json.loads((ROOT/'Foxlingo/Resources/starter-en.json').read_text());report=audit(pack)
    (ROOT/'content/curriculum-progress.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(f"{report['completedClubs']}/{report['totalClubs']} club courses, {report['completedPlayers']}/{report['totalPlayers']} player courses meet depth requirements")
