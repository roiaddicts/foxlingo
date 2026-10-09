"""Offline checks for provider identity and atomic refresh safety."""
import copy
import json
from pathlib import Path
import tempfile
import unittest
from futbol11_source import extract, bind_roles, js_string
from refresh_futbol11 import refresh, source_url

RAW = (Path(__file__).resolve().parents[1]/'ref/futbol11.js').read_bytes()

class SourceTests(unittest.TestCase):
    def setUp(self):
        self.datasets = extract(RAW, 'https://futbol-11.com/js/app.js')
        self.roles = bind_roles(self.datasets)

    def role(self, name):
        return next(d for d in self.datasets if d['id'] == self.roles[name])

    def test_reordering_and_unrelated_insertions_preserve_roles(self):
        inserted = extract(b'JSON.parse(\'[1,2,3]\')', 'https://futbol-11.com/extra.js')
        self.assertEqual(bind_roles(inserted + list(reversed(self.datasets))), self.roles)

    def test_ambiguous_schema_rejected(self):
        duplicate = copy.deepcopy(self.role('gamePlayers')); duplicate['id'] += '-other'
        with self.assertRaises(ValueError): bind_roles(self.datasets + [duplicate])

    def test_current_profile_binds_only_required_game_roles(self):
        roles={'gamePlayers','countries','categories','classicPlayers','classicSquads','gameGroups'}
        current=[copy.deepcopy(self.role(name)) for name in roles]
        countries=next(d for d in current if d['id']==self.roles['countries'])
        countries['fields'].append('bgColor')
        for row in countries['data']:row['bgColor']='#ffffff'
        unrelated=copy.deepcopy(self.role('catalogPlayers'))
        duplicate=copy.deepcopy(unrelated);duplicate['id']+='-copy'
        self.assertEqual(bind_roles(current+[unrelated,duplicate],'current'),{k:v for k,v in self.roles.items() if k in roles})
        with self.assertRaises(ValueError):bind_roles(current,'legacy')

    def test_duplicate_entity_ids_rejected(self):
        self.role('classicPlayers')['duplicateIDs'] = 1
        with self.assertRaises(ValueError): bind_roles(self.datasets)

    def test_reused_anchor_rejected(self):
        self.role('gamePlayers')['data'][0]['firstName'] = 'Another'
        with self.assertRaises(ValueError): bind_roles(self.datasets)

    def test_missing_category_reference_rejected(self):
        self.role('categories')['data'][0]['players'] += ',99999999'
        with self.assertRaises(ValueError): bind_roles(self.datasets)

    def test_strings_are_decoded_without_execution(self):
        self.assertEqual(js_string(r"'Cup\'s \\ \u00e9 \x41'"), "Cup's \\ é A")
        with self.assertRaises(ValueError): js_string(r"'bad\q'")
        self.assertEqual(extract(b'JSON.parse(\'["safe"]\'); throw Error("never executed");', 'https://futbol-11.com/app.js')[0]['data'], ['safe'])
        self.assertEqual(extract(b'JSON.parse(`[{"id":1,"name":"Player"}]`)', 'https://futbol11.com/data.js')[0]['data'], [{'id':1,'name':'Player'}])
        with self.assertRaises(ValueError): js_string('`[${danger()}]`')

    def test_current_modules_are_archived_once_with_separate_pointer(self):
        payloads = {
            'https://futbol11.com/': b'<script src="/_nuxt/main.js"></script><script src="https://ads.example/ad.js"></script>',
            'https://futbol11.com/_nuxt/main.js': b'import "./data.js";import "./data.js";import "https://ads.example/ad.js";',
            'https://futbol11.com/_nuxt/data.js': b'import "./main.js";const a=JSON.parse(`[{"id":7,"name":"Player"}]`);',
        }
        requests=[]
        def fetch(url,limit): requests.append(url);return payloads[url]
        with tempfile.TemporaryDirectory() as folder:
            legacy=Path(folder)/'latest.json';legacy.write_text('{"snapshot":"keep-legacy"}')
            snapshot,inventory=refresh(folder,fetch=fetch,site='current')
            self.assertEqual(len(requests),3)
            self.assertEqual(len(inventory['assets']),2)
            self.assertEqual(inventory['totalRecords'],1)
            self.assertEqual(json.loads(legacy.read_text())['snapshot'],'keep-legacy')
            self.assertEqual(json.loads((Path(folder)/'latest-current.json').read_text())['snapshot'],snapshot.name)
            value=json.loads((snapshot/'snapshot.json').read_text())
            self.assertEqual(value['schemaVersion'],2);self.assertEqual(value['roles'],{})
            pointer=(Path(folder)/'latest-current.json').read_bytes()
            payloads['https://futbol11.com/_nuxt/data.js']=b'const a=JSON.parse(`[${unsafe()}]`);'
            with self.assertRaises(ValueError):refresh(folder,fetch=fetch,site='current')
            self.assertEqual((Path(folder)/'latest-current.json').read_bytes(),pointer)
            self.assertFalse(list(Path(folder).glob('.staging-*')))

    def test_external_or_non_https_assets_rejected(self):
        for url in ['http://futbol-11.com/a.js', 'https://evil.example/a.js', 'https://user@futbol-11.com/a.js']:
            with self.assertRaises(ValueError): source_url(url)

    def test_failed_refresh_keeps_previous_pointer_and_cleans_staging(self):
        page = b'<script src="/app.js"></script>'
        def good(url, limit): return page if url.endswith('/') else RAW
        with tempfile.TemporaryDirectory() as folder:
            first, _ = refresh(folder, fetch=good)
            pointer = (Path(folder)/'latest.json').read_bytes()
            def failed(url, limit):
                if url.endswith('/'): return page
                raise OSError('Interrupted download')
            with self.assertRaises(OSError): refresh(folder, fetch=failed)
            self.assertEqual((Path(folder)/'latest.json').read_bytes(), pointer)
            self.assertTrue((first/'snapshot.json').exists())
            self.assertFalse(list(Path(folder).glob('.staging-*')))
            second, _ = refresh(folder, fetch=good)
            self.assertEqual(json.loads((Path(folder)/'latest.json').read_text())['previous'], first.name)
            self.assertNotEqual(first, second)

if __name__ == '__main__': unittest.main()
