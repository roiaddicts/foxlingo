"""Compile five XI drafting pools from archived first-party data, without JS execution."""
from pathlib import Path
import argparse, hashlib, json, unicodedata
from collections import defaultdict
from futbol11_source import extract
from futbol11_static import one_table
from futbol11_archive import Archive
ROOT=Path(__file__).resolve().parents[1]
SCOPE='Futbol11 historical seed pool; roster, position and activity cutoff dates are not published. Fetch time is not data freshness.'
POSITIONS={'GK','LB','CB','RB','LWB','RWB','CDM','CM','CAM','LM','RM','LW','RW','ST','CF'}


def normalize(text):
    return ''.join(c for c in unicodedata.normalize('NFD',text.casefold()) if not unicodedata.combining(c)).strip()


def fullname(row): return ' '.join(filter(None,[row.get('firstName'),row.get('lastName')]))
def display(row): return row.get('nickname') or fullname(row)
def positions(row):
    result=list(dict.fromkeys(v.strip() for v in row['positions'].split(',') if v.strip()))
    if not result or not set(result) <= POSITIONS: raise ValueError('Unsupported position codes: '+str(result))
    return result


def compile_pack(path):
    archive=Archive(path);meta=archive.meta;root=path.parent;roles=archive.roles
    countries_module=archive.mode('countries');clubs_module=archive.mode('clubs')
    modules={'CnV5DmAQ.js':archive.imported(countries_module,'z'),'Ca2vDWde.js':clubs_module,'B2tFiaen.js':archive.mode('america'),'8BCraab8.js':archive.mode('legends'),'CaAfWsTq.js':archive.imported(countries_module,'ue'),'U8uOf8nf.js':archive.imported(countries_module,'O'),'ChS2TaaV.js':archive.imported(clubs_module,'G')}
    source_url=meta['sourceURL'].rstrip('/')
    def module(filename):
        matches=[a for a in meta['assets'] if a['url']==modules[filename]]
        if len(matches)!=1: raise ValueError('Missing source module: '+filename)
        item=matches[0]; raw=(root/item['file']).read_bytes()
        if hashlib.sha256(raw).hexdigest()!=item['sha256']: raise ValueError('Source asset digest changed: '+filename)
        return item,raw.decode()
    def json_rows(filename):
        item,text=module(filename); rows=extract(text.encode(),item['url'])
        if len(rows)!=1 or rows[0]['duplicateIDs']: raise ValueError('Ambiguous player table: '+filename)
        return rows[0]['data']
    country_item,country_text=module('CnV5DmAQ.js')
    nation_groups=one_table(country_text,{'id','name','logo'})
    club_item,club_text=module('Ca2vDWde.js')
    club_groups=one_table(club_text,{'id','name','logo','players'})
    america_item,america_text=module('B2tFiaen.js')
    america_groups=one_table(america_text,{'id','name','logo'})
    legend_item,legend_text=module('8BCraab8.js')
    legend_groups=one_table(legend_text,{'id','name','logo'})
    formation_item,formation_text=module('CaAfWsTq.js')
    source_formations=one_table(formation_text,{'name','players'})
    rows={'442':[[9,10],[5,6,7,8],[1,2,3,4],[0]],'433':[[8,9,10],[5,6,7],[1,2,3,4],[0]],'532':[[9,10],[7,8],[6],[1,2,3,4,5],[0]],'352':[[9,10],[8],[6,4,5,7],[1,2,3],[0]],'343':[[8,10,9],[6,4,5,7],[1,2,3],[0]]}
    formations=[dict(id=f['name'],positions=[p['position'] for p in f['players']],rows=rows[f['name']]) for f in source_formations]
    for f in formations:
        if len(f['positions'])!=11 or not set(f['positions'])<=POSITIONS: raise ValueError('Invalid formation')
    game=json.loads((ROOT/'Foxlingo/Resources/games-en.json').read_text())
    game_by_id={p['id']:p for p in game['players']}; active=set(game['activeConnectionPlayerIDs'])
    source_people=defaultdict(list)
    for person in roles['gamePlayers']:
        if fullname(person): source_people[normalize(fullname(person))].append(person)
    # Match portraits only by unambiguous full names, then resolve the reviewed game namespace.
    runtime_names=defaultdict(list)
    for person in game['players']:
        if person['id'] in active:
            for alias in set(person['aliases']): runtime_names[normalize(alias)].append(person)
    crosswalk=[]; profiles=[]; exclusions=[]
    def make_profiles(rows,namespace):
        out={}
        for row in rows:
            identifier=f'draft-{namespace}-player-{row["id"]}'
            codes=[v.strip() for v in row.get('positions','').split(',') if v.strip()]
            if not codes or not set(codes)<=POSITIONS:
                exclusions.append(dict(id=identifier,name=display(row),positions=row.get('positions'),reason='missing or unsupported position codes'))
                continue
            person=dict(id=identifier,name=display(row),aliases=list(dict.fromkeys(filter(None,[display(row),fullname(row)]))),imageURL=None,imageAsset=None)
            candidates=source_people[normalize(fullname(row))] if row.get('firstName') else []
            if len(candidates)==1:
                original=candidates[0]; matches=runtime_names[normalize(fullname(original))]
                if len(matches)==1 and matches[0].get('imageURL'):
                    photo=matches[0]; person.update(imageURL=photo.get('imageURL'),imageAsset=photo.get('imageAsset'))
                    crosswalk.append(dict(id=identifier,fullName=fullname(row),portraitID=photo['id'],portraitName=photo['name'],method='unique exact normalized full name'))
            if namespace=='classic':
                photo=game_by_id.get(f'classic-player-{row["id"]}')
                if photo and normalize(photo['name'])==normalize(display(row)) and photo.get('imageURL'):
                    person.update(imageURL=photo.get('imageURL'),imageAsset=photo.get('imageAsset'))
                    crosswalk.append(dict(id=identifier,fullName=fullname(row),portraitID=photo['id'],portraitName=photo['name'],method='preserved classic identity and curated portrait'))
            profile=dict(person=person,positions=positions(row));profiles.append(profile);out[row['id']]=profile
        return out
    nations=json_rows('U8uOf8nf.js');clubs=json_rows('ChS2TaaV.js');america=json_rows('B2tFiaen.js');classic=roles['classicPlayers']
    pools={key:make_profiles(rows,key) for key,rows in [('nations',nations),('clubs',clubs),('america',america),('classic',classic)]}
    artwork={m['url']:m['asset'] for m in json.loads((ROOT/'Foxlingo/Resources/artwork-manifest.json').read_text()) if m.get('cached')}
    countries=json.loads((ROOT/'content/country-artwork.json').read_text())
    urls=lambda url:source_url+url if url.startswith('/') else url
    def group(mode,row,members,distinct=None,asset=None):
        url=urls(row['logo']);key=f'draft-{mode}-group-{row["id"]}'
        if mode in ['nations','legends']:
            country=countries.get(normalize(row['name']))
            asset=country.get('imageAsset') if country else None
        return dict(id=key,name=row['name'],distinctKey=str(distinct if distinct is not None else row['id']),imageAsset=asset or artwork.get(url) or key,imageURL=url,playerIDs=members)
    def ids(mode,rows): return [pools[mode][p['id']]['person']['id'] for p in rows if p['id'] in pools[mode]]
    members={}
    members['nations']=[group('nations',c,ids('nations',[p for p in nations if p.get('countryID')==c['id']])) for c in nation_groups]
    members['clubs']=[]
    for c in club_groups:
        raw_ids=[int(i) for i in c['players'].split(',') if i.strip()]
        if len(raw_ids)!=len(set(raw_ids)) or any(i not in {p['id'] for p in clubs} for i in raw_ids): raise ValueError('Broken club membership: '+c['name'])
        members['clubs'].append(group('clubs',c,[pools['clubs'][i]['person']['id'] for i in raw_ids if i in pools['clubs']]))
    members['america']=[group('america',c,ids('america',[p for p in america if p.get('clubID')==c['id']])) for c in america_groups]
    # clubID in the classic PLAYER table is a country key in the Legends module.
    # clubID in the classic SQUAD table is a club key; the two roles are not joined.
    members['legends']=[group('legends',c,ids('classic',[p for p in classic if p.get('clubID')==c['id'] and p.get('active')!='yes'])) for c in legend_groups]
    members['retro']=[]
    for c in roles['classicSquads']:
        raw_ids=[int(i) for i in c['players'].split(',') if i.strip()]
        if any(i not in {p['id'] for p in classic} for i in raw_ids): raise ValueError('Broken classic membership')
        # Reuse the exact verified season shirt already compiled for this squad.
        old=next(x for x in game['lineups'] if x['id']==f'lineup-{c["id"]}')
        if old['title']!=c['name'].replace('Real M','Real Madrid'): raise ValueError('Classic shirt identity changed')
        members['retro'].append(group('retro',dict(c,name=old['title']),[pools['classic'][i]['person']['id'] for i in raw_ids if i in pools['classic']],distinct=c['clubID'],asset=old['imageAsset']))
    descriptions={
        'nations':('Nations XI','Eleven countries. One formation.','futbol11'),
        'clubs':('Clubs XI','Eleven clubs. One formation.','futbol11-clubs'),
        'retro':('Retro XI','Eleven historical clubs and season squads.','futbol11-retro'),
        'legends':('Legends XI','Eleven countries from the historical legend pool.','futbol11-legends'),
        'america':('America XI','Eleven South American clubs. One formation.','futbol11-america')}
    modes=[]
    for key,(title,subtitle,route) in descriptions.items():
        groups=[g for g in members[key] if g['playerIDs']]
        if len(set(g['distinctKey'] for g in groups))<11: raise ValueError('Not enough groups: '+key)
        modes.append(dict(id=key,title=title,subtitle=subtitle,scope=SCOPE+(' Legends excludes records marked active by the source; unmarked records are not a live retirement check.' if key=='legends' else ''),sourceURL=source_url+'/'+route,groups=groups))
    pack=dict(schemaVersion=1,fetchedAt=meta['fetchedAt'],sourceURL=source_url+'/',players=profiles,formations=formations,modes=modes)
    return pack,list({row["id"]:row for row in crosswalk}.values()),exclusions


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--snapshot',type=Path,required=True);args=parser.parse_args()
    pack,crosswalk,exclusions=compile_pack(args.snapshot)
    target=ROOT/'Foxlingo/Resources/drafts-en.json'
    if target.exists():
        old=json.loads(target.read_text());new={p['person']['id']:p for p in pack['players']}
        changed=[p['person']['id'] for p in old['players'] if p['person']['id'] in new and normalize(p['person']['name'])!=normalize(new[p['person']['id']]['person']['name'])]
        if changed: raise ValueError('Draft player IDs changed identity: '+str(changed[:20]))
    target.write_text(json.dumps(pack,ensure_ascii=False,indent=2)+'\n')
    (ROOT/'content/draft-portrait-crosswalk.json').write_text(json.dumps(crosswalk,ensure_ascii=False,indent=2)+'\n')
    (ROOT/'content/draft-source-exclusions.json').write_text(json.dumps(exclusions,ensure_ascii=False,indent=2)+'\n')
    print(len(pack['players']),'namespaced draft profiles;',[(m['id'],len(m['groups'])) for m in pack['modes']],';',len(crosswalk),'portrait mappings')

if __name__=='__main__':main()
