import json,subprocess,tempfile,unittest
from datetime import date
from pathlib import Path
from unittest.mock import patch
from futbol11_daily import compile_daily,day_indexes,shuffle,publish,selector_digest,squad_shuffle,xi_solution
from futbol11_archive import Archive
ROOT=Path(__file__).resolve().parents[1]
SNAPSHOT=ROOT/'ref/futbol11-fixtures/current-2026-10-09/snapshot.json'

class DailyTests(unittest.TestCase):
    def test_xi_both_levels_match_independent_data_only_reference(self):
        packet=compile_daily(SNAPSHOT,date(2026,10,10),'America/Mexico_City')
        xi=[g for g in packet['games'] if g['id'] in ['countries','clubs','retro','legends','america']]
        js="""const input=JSON.parse(require('fs').readFileSync(0,'utf8'));
        function mix(a,seed){let v=2166136261;for(let i=0;i<seed.length;i++){v^=seed.charCodeAt(i);v+=(v<<1)+(v<<4)+(v<<7)+(v<<8)+(v<<24);}let out=[...a];for(let i=out.length-1;i>0;i--){v+=v<<13;v^=v>>>7;v+=v<<3;v^=v>>>17;v+=v<<5;let j=Math.floor((v>>>0)/4294967296*(i+1));[out[i],out[j]]=[out[j],out[i]];}return out;}
        const codes=new Set(['GK','LB','CB','RB','LWB','RWB','CDM','CM','CAM','LM','RM','LW','RW','ST','CF']);
        const config={countries:['/c1fdE',1,[0,2,3,4,6,7,8,9,10,11,12,14]],clubs:['/CA',1,[1,2,3,5,6,7,13,14,16,22,23,24,28,29,31,36]],retro:['osaIS3',1,[12,13,16,19,63,23,70,17,24,5,27,78,34,38,43,48,81,1]],legends:['ofADI',0,[]],america:['/CA',3,[1,2,3,5,6,7,13,14,16,22,23,24,28,29,31,36]]};
        const result=input.games.map(g=>{let c=g.selection.catalog,[salt,index,easy]=config[g.id],players=input.datasets.find(t=>t.sourceURL===c.playerSourceURL).data;
          let valid=players.filter(p=>(p.positions||'').split(',').map(x=>x.trim()).filter(Boolean).length&&(p.positions||'').split(',').map(x=>x.trim()).filter(Boolean).every(x=>codes.has(x)));
          let boards=['normal','easy'].map(level=>{let pool=c.groups,seed='283'+salt;if(level==='easy'&&g.id!=='legends'){pool=pool.filter(x=>easy.includes(x.id));if(g.id==='countries')seed='283/dE';}if(g.id==='retro')pool=pool.filter((x,i,a)=>i===a.findIndex(y=>x.clubID===y.clubID));let groups=mix(pool,seed).slice(0,11);
            let memberships=groups.map(x=>({id:x.id,playerIDs:['clubs','retro'].includes(g.id)?x.players.split(',').map(Number).filter(id=>valid.some(p=>p.id===id)):valid.filter(p=>p[g.id==='countries'?'countryID':'clubID']===x.id&&(g.id!=='legends'||level==='easy'||p.active!=='yes')).map(p=>p.id)}));return {level,groups,memberships};});
          return {id:g.id,formation:mix(c.formations,'283'+salt)[index],boards,excluded:players.filter(p=>!valid.includes(p)).map(p=>p.id)};});console.log(JSON.stringify(result));"""
        oracle=json.loads(subprocess.check_output(['node','-e',js],input=json.dumps(dict(games=xi,datasets=packet['datasets'])),text=True))
        for g,reference in zip(xi,oracle):
            s=g['selection'];c=s['catalog']
            self.assertEqual(s['boards'],reference['boards']);self.assertEqual(s['formation'],reference['formation'])
            self.assertEqual(s['groups'],s['boards'][0]['groups']);self.assertEqual(c['excludedPositionPlayerIDs'],reference['excluded'])
            self.assertEqual(c['uniquePlayers'],g['id']=='retro');self.assertEqual(c['timerSeconds'],[0,40,60,90])
        legends=next(g for g in xi if g['id']=='legends')['selection']['boards']
        self.assertEqual(legends[0]['groups'],legends[1]['groups'])
        self.assertTrue(any(len(a['playerIDs'])<len(b['playerIDs']) for a,b in zip(legends[0]['memberships'],legends[1]['memberships'])))

    def test_xi_portraits_use_unique_full_names_never_numeric_id_joins(self):
        import unicodedata
        from collections import Counter
        def name(p):return ''.join(c for c in unicodedata.normalize('NFD',' '.join(filter(None,[p.get('firstName'),p.get('lastName')])).strip().casefold()) if not unicodedata.combining(c))
        packet=compile_daily(SNAPSHOT,date(2026,10,10),'America/Mexico_City')
        general=next(t['data'] for t in packet['datasets'] if set(t['fields'])=={'bingo','countryID','firstName','grid','id','image','lastName','nickname'})
        general_counts=Counter(map(name,general));general_ids={p['id']:p for p in general}
        for g in packet['games']:
            if g['id'] not in ['countries','clubs','retro','legends','america']:continue
            c=g['selection']['catalog'];players=next(t['data'] for t in packet['datasets'] if t['sourceURL']==c['playerSourceURL'])
            own_counts=Counter(map(name,players));own_ids={p['id']:p for p in players}
            for identifier,portrait in c['portraitPlayerIDs'].items():
                player=own_ids[int(identifier)];photo=general_ids[portrait]
                self.assertTrue(name(player));self.assertEqual(name(player),name(photo));self.assertTrue(photo['image'])
                self.assertEqual(own_counts[name(player)],1);self.assertEqual(general_counts[name(player)],1)
        countries=next(g for g in packet['games'] if g['id']=='countries')['selection']['catalog']
        self.assertNotEqual(countries['portraitPlayerIDs'].get('1'),1)

    def test_xi_bound_support_program_drift_is_rejected(self):
        archive=Archive(SNAPSHOT);original=Archive.text
        targets=[archive.imported(archive.mode('countries'),a) for a in ['ue','z','O']]+[archive.imported(archive.mode('clubs'),'G'),archive.imported(archive.mode('retro'),'v1')]
        for target in targets:
            with self.subTest(target=target),patch.object(Archive,'text',lambda a,u:original(a,u)+(';fakeMutation();' if u==target else '')):
                with self.assertRaisesRegex(ValueError,'support contract changed'):compile_daily(SNAPSHOT,date(2026,10,10),'America/Mexico_City')
        target=archive.mode('clubs')
        binding=Archive.import_symbol;wrong_url=archive.imported(archive.mode('countries'),'O')
        with patch.object(Archive,'import_symbol',lambda a,u,l:('p',wrong_url) if u==target and l=='G' else binding(a,u,l)):
            with self.assertRaisesRegex(ValueError,'XI player export changed'):compile_daily(SNAPSHOT,date(2026,10,10),'America/Mexico_City')

    def test_xi_playability_checks_positions_and_retro_uniqueness(self):
        groups=[dict(id=i,playerIDs=[1]) for i in range(11)]
        formation=dict(players=[dict(position='CM') for _ in range(11)])
        players=[dict(id=1,positions='CM')]
        self.assertTrue(xi_solution(groups,players,formation))
        self.assertFalse(xi_solution(groups,players,formation,unique=True))
        self.assertFalse(xi_solution(groups,[dict(id=1,positions='GK')],formation))
    def test_contract_allows_static_data_and_filename_changes_but_rejects_code_drift(self):
        source='import{p as q}from"./a.js";const a=JSON.parse(`[{"id":1}]`);const b=[{id:1,name:"A"}];function choose(){return a[day()];}'
        updated=source.replace('./a.js','./new-hash.js').replace('"id":1','"id":2').replace('name:"A"','name:"B"')
        self.assertEqual(selector_digest(source),selector_digest(updated))
        self.assertNotEqual(selector_digest(source),selector_digest(source.replace('a[day()]','a[0]')))
        self.assertNotEqual(selector_digest(source),selector_digest(source+';a[0]=fakeAnswer;'))
    def test_shuffle_matches_independent_javascript_arithmetic_and_numeric_seed_quirk(self):
        code='''function rng(seed) {let v=2166136261;for(let i=0;i<seed.length;i++){v^=seed.charCodeAt(i);v+=(v<<1)+(v<<4)+(v<<7)+(v<<8)+(v<<24);}return()=>{v+=v<<13;v^=v>>>7;v+=v<<3;v^=v>>>17;v+=v<<5;return(v>>>0)/4294967296;};}
        function mix(seed){let a=Array.from({length:20},(_,i)=>i),r=rng(seed);for(let i=a.length-1;i>0;i--){let j=Math.floor(r()*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a;}
        console.log(JSON.stringify(['282/CA','10/09/2026/','today','😀',282,0].map(mix)));'''
        expected=json.loads(subprocess.check_output(['node','-e',code],text=True))
        actual=[shuffle(list(range(20)),seed) for seed in ['282/CA','10/09/2026/','today','😀',282,0]]
        self.assertEqual(actual,expected);self.assertEqual(actual[-1],actual[-2])
    def test_date_indexes_match_source_at_year_boundary_leap_day_and_dst(self):
        self.assertEqual(day_indexes(date(2026,1,1),'America/Mexico_City'),(1,1))
        self.assertEqual(day_indexes(date(2024,2,29),'UTC'),(60,60))
        self.assertEqual(day_indexes(date(2026,10,9),'America/Mexico_City'),(282,282))
        self.assertEqual(day_indexes(date(2026,10,9),'America/New_York'),(282,281))
        with self.assertRaises(Exception):day_indexes(date(2026,10,9),'invalid/zone')
    def test_all_nineteen_live_modes_have_scoped_reproducible_selections(self):
        first=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City')
        again=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City')
        self.assertEqual(len(first['datasets']),20)
        self.assertGreater(sum(d['records'] for d in first['datasets']),20_000)
        self.assertEqual(len(first['games']),19);self.assertEqual(first['games'],again['games'])
        modes={g['id']:g for g in first['games']}
        self.assertEqual(modes['top10']['selection']['record']['title'],'Chelsea 2023/24 - Most matches')
        self.assertEqual(modes['wordle']['selection']['answer'],'TERRY')
        for mode in ['countries','clubs','retro','legends','america']:
            self.assertEqual(len(modes[mode]['selection']['groups']),11)
            self.assertEqual(len(modes[mode]['selection']['formation']['players']),11)
        self.assertEqual(len(modes['connections']['selection']['groups']),4)
        self.assertEqual(len(set(modes['connections']['selection']['order'])),16)
        self.assertTrue(modes['bingo']['randomPlayOrder'])
        self.assertEqual(len(modes['bingo']['selection']['groups']),12)
        self.assertEqual(len(modes['bingo-retro']['selection']['groups']),12)
        ny=compile_daily(SNAPSHOT,date(2026,10,9),'America/New_York')
        self.assertNotEqual(modes['pyramid']['selection']['record'],next(g for g in ny['games'] if g['id']=='pyramid')['selection']['record'])
    def test_impostor_review_rejects_wrong_player_identity(self):
        correction=dict(id='a11e9d68-cb83-4b8b-b9ed-8313a6fa69d4',game='impostor',recordID=57,title='Played for Athletic Club',sourceCorrectPlayerIDs=[760,129,370,1029],sourceExtraCorrectPlayerIDs=[113],sourceImpostorPlayerIDs=[185,352,267,326,291,311],removeExtraPlayerIDs=[113],playerNames={'113':'Cesar Azpilicueta'},note='Incorrect player identity',reviewedAt='2026-10-10',sources=[dict(title='Career source',url='https://sevillafc.es/actualidad/noticias/cesar-azpilicueta-signs')])
        original=Path.read_text
        def read(path,*args,**kwargs):
            return json.dumps(dict(schemaVersion=1,corrections=[correction])) if path.name=='futbol11-data-corrections.json' else original(path,*args,**kwargs)
        with patch.object(Path,'read_text',read):
            with self.assertRaisesRegex(ValueError,'player identity changed'):compile_daily(SNAPSHOT,date(2026,10,10),'America/Mexico_City')
    def test_impostor_source_bindings_and_one_by_one_pool_transform(self):
        packet=compile_daily(SNAPSHOT,date(2026,10,10),'America/Mexico_City');s=next(g['selection'] for g in packet['games'] if g['id']=='impostor')
        rows=next(d['data'] for d in packet['datasets'] if d['sourceURL']==s['catalog']['recordSourceURL'])
        self.assertEqual(s['record'],rows[s['index']]);self.assertEqual(s['index'],283);self.assertEqual(s['catalog']['boardDate'],'2026-10-10')
        code="const r=JSON.parse(require('fs').readFileSync(0,'utf8'));let c=r.correctPl.split(',').map(Number),e=r.addcorr?r.addcorr.split(',').map(Number):[],n=r.impostors.split(',').map(Number),normal=[...n,...c];if(e.length){c.push(...e);n.splice(-e.length);}console.log(JSON.stringify({normal,hard:[...n,...c]}));"
        pools=json.loads(subprocess.check_output(['node','-e',code],input=json.dumps(s['record']),text=True))
        self.assertEqual(pools['normal'],s['impostorPlayerIDs']+s['correctPlayerIDs'])
        extra=s['extraCorrectPlayerIDs'];self.assertEqual(pools['hard'],(s['impostorPlayerIDs'][:-len(extra)] if extra else s['impostorPlayerIDs'])+s['correctPlayerIDs']+extra)
        self.assertEqual(len(set(pools['normal'])),10);self.assertEqual(len(set(pools['hard'])),10)
    def test_connections_easy_normal_match_independent_data_only_reference(self):
        packet=compile_daily(SNAPSHOT,date(2026,10,10),'America/Mexico_City');s=next(g['selection'] for g in packet['games'] if g['id']=='connections')
        groups=next(d['data'] for d in packet['datasets'] if d['sourceURL']==s['catalog']['categorySourceURL'])
        players=next(d['data'] for d in packet['datasets'] if d['sourceURL']==s['catalog']['playerSourceURL'])
        js="""const d=JSON.parse(require('fs').readFileSync(0,'utf8'));function mix(a,seed){let v=2166136261;for(let i=0;i<seed.length;i++){v^=seed.charCodeAt(i);v+=(v<<1)+(v<<4)+(v<<7)+(v<<8)+(v<<24);}let out=[...a];for(let i=out.length-1;i>0;i--){v+=v<<13;v^=v>>>7;v+=v<<3;v^=v>>>17;v+=v<<5;let j=Math.floor((v>>>0)/4294967296*(i+1));[out[i],out[j]]=[out[j],out[i]];}return out;}
        const seed='10/10/2026/',pool=d.groups.map(g=>({...g,players:g.players.split(',').map(Number).filter(id=>d.players.some(p=>p.id===id&&p.image))})).filter(g=>g.players.length>=4),boards=[];
        for(const mode of ['normal','easy']){const chosen=[],excluded=[],groups=[];for(const g of mix(pool,seed)){if(mode==='easy'&&g.level!=='easy')continue;if(g.players.some(id=>chosen.includes(id)))continue;const ids=mix(g.players.filter(id=>!chosen.includes(id)&&!excluded.includes(id)),seed).slice(0,4);if(ids.length!==4)continue;groups.push({id:g.id,title:g.title,playerIDs:ids});chosen.push(...ids);excluded.push(...g.players);if(groups.length===4)break;}boards.push({mode,groups,order:mix(groups.flatMap(g=>g.playerIDs),seed)});}console.log(JSON.stringify(boards));"""
        actual=json.loads(subprocess.check_output(['node','-e',js],input=json.dumps(dict(groups=groups,players=players)),text=True))
        self.assertEqual(s['boards'],actual)
    def test_bingo_catalog_bound_memberships_and_category_recipe(self):
        packet=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City');selection=next(g['selection'] for g in packet['games'] if g['id']=='bingo')
        self.assertEqual(selection['catalog']['boardDate'],'2026-10-09')
        players=next(d['data'] for d in packet['datasets'] if d['sourceURL']==selection['catalog']['playerSourceURL'])
        groups=next(d['data'] for d in packet['datasets'] if d['sourceURL']==selection['catalog']['categorySourceURL'])
        expected=[]
        for types,count in [('club',4),('club2',1),('country',2),('country2|continent',1),('extra',1),('award',2),('league',1)]:
            expected+=shuffle([g for g in groups if g['type'] in types.split('|')],'10/09/2026')[:count]
        self.assertEqual(selection['groups'],shuffle(expected,'10/09/2026'))
        for g in selection['groups']:
            self.assertTrue(any(g['id'] in [int(v) for v in p.get('bingo','').split(',') if v.strip()] for p in players))
    def test_grid_four_difficulties_match_independent_data_only_reference(self):
        packet=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City');selection=next(g['selection'] for g in packet['games'] if g['id']=='grid')
        groups=next(d['data'] for d in packet['datasets'] if d['sourceURL']==selection['catalog']['categorySourceURL'])
        players=next(d['data'] for d in packet['datasets'] if d['sourceURL']==selection['catalog']['playerSourceURL'])
        js="""const d=JSON.parse(require('fs').readFileSync(0,'utf8'));function mix(a,seed){let v=2166136261;for(let i=0;i<seed.length;i++){v^=seed.charCodeAt(i);v+=(v<<1)+(v<<4)+(v<<7)+(v<<8)+(v<<24);}let out=[...a];for(let i=out.length-1;i>0;i--){v+=v<<13;v^=v>>>7;v+=v<<3;v^=v>>>17;v+=v<<5;let j=Math.floor((v>>>0)/4294967296*(i+1));[out[i],out[j]]=[out[j],out[i]];}return out;}
        const groups=d.groups.map(g=>({...g,members:d.players.filter(p=>[p.bingo,p.grid].some(csv=>csv&&csv.split(',').map(Number).includes(g.id))).map(p=>p.id)}));let result=[];
        for(const [mode,types]of [['easy',['club','country']],['normal',['club']],['hard',['club','country','country2']],['legend',['club','country','country2','club2']]]){let pool=groups.filter(g=>types.includes(g.type)),cols=mix(pool,d.stamp).slice(0,3),rows=[],n=0;while(rows.length<3){rows=mix(pool.filter(g=>!cols.some(c=>c.id===g.id)&&cols.every(c=>g.members.some(id=>c.members.includes(id)))),d.stamp).slice(0,3);if(rows.length<3){if(n>1000)throw Error('no board');cols=mix(pool,n++).slice(0,3);}}result.push({mode,columns:cols.map(g=>g.id),rows:rows.map(g=>g.id)});}console.log(JSON.stringify(result));"""
        reference=json.loads(subprocess.check_output(['node','-e',js],input=json.dumps(dict(groups=groups,players=players,stamp='10/09/2026')),text=True))
        actual=[dict(mode=b['mode'],columns=[g['id'] for g in b['columns']],rows=[g['id'] for g in b['rows']]) for b in selection['boards']]
        self.assertEqual(reference,actual);self.assertEqual(selection['catalog']['boardDate'],'2026-10-09')
    def test_wordle_dictionary_binding_and_support_contract_are_verified(self):
        packet=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City')
        game=next(g for g in packet['games'] if g['id']=='wordle');selection=game['selection'];catalog=selection['catalog']
        self.assertEqual(selection['answer'],'TERRY');self.assertEqual(len(catalog['words']),374);self.assertEqual(catalog['words'][selection['index']],'TERRY')
        players=next(d for d in packet['datasets'] if d['sourceURL']==catalog['playerSourceURL']);self.assertIn('bingo',players['fields'])
        original=Archive.text
        def changed(archive,url):
            text=original(archive,url)
            return text+';ke[0]="FAKE";' if url==catalog['sourceURL'] else text
        with patch.object(Archive,'text',changed):
            with self.assertRaisesRegex(ValueError,'dictionary support contract changed'):compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City')
        def static_update(archive,url):
            text=original(archive,url)
            return text.replace('"SAUL"','"SANE"') if url==catalog['sourceURL'] else text
        with patch.object(Archive,'text',static_update):
            updated=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City')
            self.assertEqual(next(g for g in updated['games'] if g['id']=='wordle')['selection']['catalog']['words'][-1],'SANE')
    def test_bingo_retro_catalog_is_bound_and_all_selected_categories_have_source_matches(self):
        packet=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City')
        game=next(g for g in packet['games'] if g['id']=='bingo-retro');selection=game['selection'];catalog=selection['catalog']
        self.assertEqual(catalog['boardDate'],'2026-10-09');self.assertEqual(catalog['playerSourceURL'],game['sourceModule']);self.assertEqual(len(catalog['groups']),58)
        players=next(d['data'] for d in packet['datasets'] if d['sourceURL']==catalog['playerSourceURL'] and set(d['fields'])=={'id','name','image','groups'})
        self.assertEqual(len(players),251);self.assertEqual([g['id'] for g in selection['groups']],[2,32,18,6,11,30,23,36,65,72,3,53])
        for group in selection['groups']:
            self.assertIn(group,catalog['groups']);self.assertTrue(any(group['id'] in p['groups'] for p in players))
        ibra=next(p for p in players if p['id']==1);self.assertEqual(ibra['name'],'Ibrahimovic');self.assertNotIn(2,ibra['groups']);self.assertIn(3,ibra['groups'])
    def test_reveal_modes_use_general_identity_and_reviewed_visual_clue_order(self):
        first=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City')
        modes={g['id']:g for g in first['games']};players=Archive(SNAPSHOT).roles['gamePlayers']
        self.assertEqual(next(p for p in players if p['id']==820)['lastName'],'Savinho')
        self.assertEqual(next(p for p in players if p['id']==282)['lastName'],'Rodriguez')
        self.assertEqual(modes['legacy']['selection']['clueOrder'],[89,2,156,116])
        self.assertEqual(modes['link']['selection']['clueOrder'],[910,190,661,57,417])
        self.assertTrue(modes['statdle']['randomPlayOrder'])
        self.assertEqual(len(first['support']['clubs']['data']),109)
        self.assertEqual(next(c for c in first['support']['clubs']['data'] if c['id']==3)['lastName'],'Man Utd')
        # Static table changes are allowed; executable logic changes require review.
        original=Archive.text
        def changed(archive,url):
            text=original(archive,url)
            return text+';a[0].id=999;' if url==first['support']['clubs']['sourceURL'] else text
        with patch.object(Archive,'text',changed):
            with self.assertRaisesRegex(ValueError,'support contract changed'):compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City')
    def test_squad_rng_matches_independent_javascript_and_source_cohort(self):
        js="function shuffled(seed){let s=2166136261;for(let i=0;i<seed.length;i++)s=Math.imul(s^seed.charCodeAt(i),16777619);s>>>=0;let a=Array.from({length:20},(_,i)=>i);for(let i=a.length-1;i>0;i--){s=s+1831565813|0;let v=Math.imul(s^s>>>15,1|s);v=v+Math.imul(v^v>>>7,61|v)^v;let j=Math.floor(((v^v>>>14)>>>0)/4294967296*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a;}console.log(JSON.stringify(['12-2016/17','1-2025/26','😀'].map(shuffled)));"
        expected=json.loads(subprocess.check_output(['node','-e',js],text=True))
        self.assertEqual([squad_shuffle(list(range(20)),seed) for seed in ['12-2016/17','1-2025/26','😀']],expected)
        pack=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City')
        squad=next(g['selection'] for g in pack['games'] if g['id']=='squadslice')
        self.assertEqual(squad['revealOrder'],[65,1,13,51,10,6,17,34,37,7,19,66])
        self.assertEqual(sum(s['count'] for s in squad['slices']),28)
        self.assertEqual(squad['slices'][0]['countryID'],10);self.assertEqual(squad['slices'][0]['count'],13)
        self.assertEqual(squad['omittedPlayerIDs'],[])
    def test_guesswho_catalog_uses_explicit_portrait_crosswalk_and_named_kit_join(self):
        pack=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City')
        selected=next(g['selection'] for g in pack['games'] if g['id']=='guesswho')
        self.assertEqual(selected['record']['id'],91);self.assertEqual(selected['record']['secID'],548)
        catalog=selected['catalog'];self.assertEqual(catalog['portraitPlayerIDs']['91'],548)
        self.assertEqual(catalog['portraitPlayerIDs']['1056'],2);self.assertEqual(catalog['portraitPlayerIDs']['1622'],1)
        self.assertEqual(len(catalog['clubs']),48);self.assertEqual(len(catalog['leagues']),8)
        clubs={c['id']:c for c in catalog['clubs']}
        self.assertEqual(clubs[14]['name'],'Real Madrid');self.assertEqual(clubs[14]['image'],'/media/shirts/9.png')
        self.assertEqual(clubs[24]['name'],'AC Milan');self.assertEqual(clubs[24]['image'],'/media/shirts/12.png')
        self.assertEqual(clubs[3]['image'],'/media/shirts/3.png')
        self.assertNotIn('image',clubs[29]) # No invented German kit URLs.
        self.assertTrue(any(d['sourceURL']==catalog['playerSourceURL'] and d['records']==2614 for d in pack['datasets']))
    def test_goltexto_has_its_own_country_namespace_and_source_groups(self):
        pack=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City')
        selection=next(g['selection'] for g in pack['games'] if g['id']=='goltexto');catalog=selection['catalog']
        self.assertEqual(selection['player']['id'],465);self.assertEqual(selection['orderPlayerIDs'][282],465)
        self.assertEqual(len(selection['orderPlayerIDs']),366)
        countries={c['id']:c['name'] for c in catalog['countries']}
        self.assertEqual(len(countries),71);self.assertEqual(countries[6],'England');self.assertEqual(countries[10],'France')
        self.assertEqual(catalog['leagueGroups']['8'],[21,89]);self.assertIn(7,catalog['regionGroups']['4'])
        self.assertNotEqual(catalog['portraitPlayerIDs']['1'],1)
        rows=next(d['data'] for d in pack['datasets'] if d['sourceURL']==catalog['playerSourceURL'])
        players=[p for p in rows if p.get('clubID')]
        payload=dict(date=pack['gameDate'],answer=selection['player'],players=players,leagues=catalog['leagueGroups'],regions=catalog['regionGroups'])
        import os
        actual=json.loads(subprocess.check_output(['node',str(ROOT/'scripts/goltexto_reference.js')],input=json.dumps(payload),text=True,env={**os.environ,'TZ':pack['timeZone']}))
        expected=json.loads((ROOT/'FoxlingoTests/Fixtures/goltexto-2026-10-09-oracle.json').read_text())['scores']
        self.assertEqual(actual,expected)
    def test_new_homepage_mode_is_reported_instead_of_silently_omitted(self):
        routes=Archive(SNAPSHOT).catalog_routes()
        with patch.object(Archive,'catalog_routes',return_value=routes|{'/futbol11-new-mode'}):
            with self.assertRaisesRegex(ValueError,'inventory changed'):compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City')
    def test_unknown_selector_or_out_of_range_date_preserves_last_good_pointer(self):
        with tempfile.TemporaryDirectory() as directory:
            pack=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City');publish(pack,directory)
            original=(Path(directory)/'latest.json').read_bytes()
            text=Archive.text
            def changed(archive,url):return text(archive,url).replace('b.value=B[x()]','b.value=B[0]')
            with patch.object(Archive,'text',changed):
                with self.assertRaisesRegex(ValueError,'selector'):compile_daily(SNAPSHOT,date(2026,10,10),'America/Mexico_City')
            self.assertEqual((Path(directory)/'latest.json').read_bytes(),original)
            with self.assertRaisesRegex(ValueError,'index outside'):compile_daily(SNAPSHOT,date(2028,12,31),'UTC')
            self.assertEqual((Path(directory)/'latest.json').read_bytes(),original)
    def test_pointer_publish_failure_keeps_previous_complete_package(self):
        with tempfile.TemporaryDirectory() as directory:
            first=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City');publish(first,directory)
            original=(Path(directory)/'latest.json').read_bytes()
            second=compile_daily(SNAPSHOT,date(2026,10,10),'America/Mexico_City')
            import os
            replace=os.replace
            def fail(source,target):
                if Path(target).name=='latest.json':raise OSError('simulated interruption')
                return replace(source,target)
            with patch('futbol11_daily.os.replace',fail):
                with self.assertRaises(OSError):publish(second,directory)
            self.assertEqual((Path(directory)/'latest.json').read_bytes(),original)
            self.assertFalse(list(Path(directory).glob('.pointer-*')))


class DownloadTests(unittest.TestCase):
    def test_transient_failure_retries_but_permanent_error_does_not(self):
        from refresh_futbol11 import download
        from urllib.error import HTTPError
        class Response:
            url='https://futbol11.com/_nuxt/test.js'
            def __enter__(self):return self
            def __exit__(self,*args):pass
            def read(self,limit):return b'const data=[];'
        opener=unittest.mock.Mock();opener.open.side_effect=[HTTPError(Response.url,503,'Unavailable',{},None),Response()]
        sleeps=[]
        with patch('refresh_futbol11.build_opener',return_value=opener):self.assertEqual(download(Response.url,sleep=sleeps.append),b'const data=[];')
        self.assertEqual(sleeps,[1]);self.assertEqual(opener.open.call_count,2)
        opener.open.reset_mock();opener.open.side_effect=HTTPError(Response.url,403,'Forbidden',{},None)
        with patch('refresh_futbol11.build_opener',return_value=opener):
            with self.assertRaises(HTTPError):download(Response.url,sleep=sleeps.append)
        self.assertEqual(opener.open.call_count,1)
    def test_failed_fetch_keeps_daily_pointer_and_mid_deploy_404_retries_fresh_page(self):
        from refresh_daily_futbol11 import refresh_daily
        from urllib.error import HTTPError
        with tempfile.TemporaryDirectory() as directory:
            pack=compile_daily(SNAPSHOT,date(2026,10,9),'America/Mexico_City');publish(pack,directory)
            old=(Path(directory)/'latest.json').read_bytes()
            def broken(*args,**kwargs):raise TimeoutError('temporary network outage')
            with self.assertRaises(TimeoutError):refresh_daily(directory,directory,date(2026,10,10),'America/Mexico_City',broken)
            self.assertEqual((Path(directory)/'latest.json').read_bytes(),old)
            fetch=unittest.mock.Mock(side_effect=[HTTPError('https://futbol11.com/_nuxt/old.js',404,'Not found',{},None),(SNAPSHOT.parent,{})])
            target,updated=refresh_daily(directory,directory,date(2026,10,10),'America/Mexico_City',fetch)
            self.assertEqual(fetch.call_count,2);self.assertTrue(target.exists());self.assertEqual(updated['gameDate'],'2026-10-10')

if __name__=='__main__':unittest.main()
