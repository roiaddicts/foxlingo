import json,subprocess,tempfile,unittest
from datetime import date
from pathlib import Path
from unittest.mock import patch
from futbol11_daily import compile_daily,day_indexes,shuffle,publish,selector_digest,squad_shuffle
from futbol11_archive import Archive
ROOT=Path(__file__).resolve().parents[1]
SNAPSHOT=ROOT/'ref/futbol11-fixtures/current-2026-10-09/snapshot.json'

class DailyTests(unittest.TestCase):
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
