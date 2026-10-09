import unittest, json
from unittest.mock import patch
from pathlib import Path
from futbol11_static import array_at, one_table
from build_drafts import compile_pack, normalize
ROOT=Path(__file__).resolve().parents[1]

class StaticTests(unittest.TestCase):
    def test_literals_and_escapes(self):
        self.assertEqual(array_at('[{id:1,name:"A\\\"B",nested:[true,null,-2]}]',0),[dict(id=1,name='A"B',nested=[True,None,-2])])
    def test_expressions_duplicate_keys_and_ambiguity_rejected(self):
        for code in ['[{id:run()}]','[{id:1,id:2}]','[{id:globalThis.secret}]','[{id:(()=>1)()}]']:
            with self.assertRaises(ValueError):array_at(code,0)
        with self.assertRaises(ValueError):one_table('let x=[{id:1,name:"a"}];let y=[{id:2,name:"b"}]',{'id','name'})
    def test_changed_archived_module_digest_rejected(self):
        snapshot=ROOT/'ref/futbol11-snapshots/2026-10-09T07-24-09.051921+00-00-647159b7c135/snapshot.json'
        meta=json.loads(snapshot.read_text())
        target=snapshot.parent/next(a['file'] for a in meta['assets'] if a['url'].endswith('/CaAfWsTq.js'))
        original=Path.read_bytes
        def changed(path):return b'[{name:"injected"}]' if path==target else original(path)
        with patch.object(Path,'read_bytes',changed):
            with self.assertRaisesRegex(ValueError,'digest'):compile_pack(snapshot)
    def test_source_roles_and_generated_pack(self):
        # Resolve the exact checked-in artifact, not a live download.
        snapshot=ROOT/'ref/futbol11-snapshots/2026-10-09T07-24-09.051921+00-00-647159b7c135/snapshot.json'
        pack,crosswalk,excluded=compile_pack(snapshot)
        self.assertEqual(pack,json.loads((ROOT/'Foxlingo/Resources/drafts-en.json').read_text()))
        self.assertEqual(len(pack['players']),8958)
        self.assertEqual(len({p['person']['id'] for p in pack['players']}),8958)
        self.assertEqual(len(crosswalk),len({p['id'] for p in crosswalk}))
        self.assertEqual(len(excluded),4)
        modes={m['id']:m for m in pack['modes']}
        self.assertEqual(modes['america']['groups'][0]['name'],'Palmeiras')
        self.assertEqual(modes['legends']['groups'][0]['name'],'England')
        self.assertEqual(modes['nations']['groups'][0]['name'],'England')
        self.assertNotIn('draft-classic-player-76',{p for g in modes['legends']['groups'] for p in g['playerIDs']})
        for f in pack['formations']:self.assertEqual(sorted(i for row in f['rows'] for i in row),list(range(11)))

if __name__=='__main__':unittest.main()
