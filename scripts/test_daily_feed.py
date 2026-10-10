import hashlib,json,tempfile,unittest
from datetime import date
from pathlib import Path
from prepare_daily_feed import prepare
ROOT=Path(__file__).resolve().parents[1]

class FeedReleaseTests(unittest.TestCase):
    def feed(self,directory,previous=True):
        root=Path(directory)/'feed';root.mkdir()
        raw=(ROOT/'Foxlingo/Resources/daily-en.json').read_bytes();data=json.loads(raw);sha=hashlib.sha256(raw).hexdigest();name=data['gameDate']+'-'+sha[:12]+'.json';(root/name).write_bytes(raw)
        pointer=dict(file=name,sha256=sha,gameDate=data['gameDate'],timeZone=data['timeZone'],modes=19,previous=None)
        if previous:
            old=ROOT/'ref/futbol11-daily/2026-10-10-ce0e2fed5287.json';(root/old.name).write_bytes(old.read_bytes());pointer['previous']=old.name
        (root/'latest.json').write_text(json.dumps(pointer))
        return root,date.fromisoformat(data['gameDate']),pointer
    def test_release_contains_only_current_and_verified_rollback_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            feed,day,p=self.feed(directory);out=Path(directory)/'release';checked=[]
            def validate(paths):
                checked.extend(paths)
                self.assertTrue(all(x.parent!=feed for x in paths))
                self.assertEqual([x.read_bytes() for x in paths],[(feed/p['file']).read_bytes(),(feed/p['previous']).read_bytes()])
            prepare(feed,out,'foxlingo-daily',day,validate)
            self.assertEqual(set(x.name for x in (out/'public/daily').iterdir()),{p['file'],p['previous'],'latest.json'})
            self.assertEqual((out/'public/daily'/p['file']).read_bytes(),(feed/p['file']).read_bytes())
            self.assertEqual(len(checked),2)
            config=json.loads((out/'firebase.json').read_text())['hosting'];self.assertEqual(config['site'],'foxlingo-daily');self.assertEqual(config['public'],'public')
    def test_native_rejection_leaves_no_publishable_output(self):
        with tempfile.TemporaryDirectory() as directory:
            feed,day,_=self.feed(directory);out=Path(directory)/'release'
            def reject(paths):raise ValueError('native incompatibility')
            with self.assertRaisesRegex(ValueError,'native incompatibility'):prepare(feed,out,'foxlingo-daily',day,reject)
            self.assertFalse(out.exists());self.assertFalse(list(Path(directory).glob('.daily-release-*')))
    def test_invalid_checksum_and_stale_date_fail_before_native_preflight(self):
        with tempfile.TemporaryDirectory() as directory:
            feed,day,p=self.feed(directory);out=Path(directory)/'release'
            def no_validate(paths):self.fail('Invalid transport data reached native validation')
            with self.assertRaisesRegex(ValueError,'not today'):prepare(feed,out,'foxlingo-daily',date(2026,10,11),no_validate)
            (feed/p['file']).write_bytes(b'{}')
            with self.assertRaisesRegex(ValueError,'checksum'):prepare(feed,out,'foxlingo-daily',day,no_validate)
            self.assertFalse(out.exists())
    def test_existing_output_and_symlink_escape_are_preserved_and_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            feed,day,p=self.feed(directory,False);out=Path(directory)/'release';out.mkdir();marker=out/'keep';marker.write_text('last good')
            with self.assertRaisesRegex(ValueError,'new staging'):prepare(feed,out,'foxlingo-daily',day,lambda paths:None)
            self.assertEqual(marker.read_text(),'last good')
            out2=Path(directory)/'new';target=Path(directory)/'external.json';target.write_bytes((feed/p['file']).read_bytes());(feed/p['file']).unlink();(feed/p['file']).symlink_to(target)
            with self.assertRaisesRegex(ValueError,'outside'):prepare(feed,out2,'foxlingo-daily',day,lambda paths:None)
            self.assertFalse(out2.exists())
    def test_self_referencing_and_missing_rollback_cannot_publish(self):
        with tempfile.TemporaryDirectory() as directory:
            feed,day,p=self.feed(directory);out=Path(directory)/'release';p['previous']=p['file'];(feed/'latest.json').write_text(json.dumps(p))
            with self.assertRaisesRegex(ValueError,'current packet'):prepare(feed,out,'foxlingo-daily',day,lambda paths:None)
            p['previous']='2026-10-09-aaaaaaaaaaaa.json';(feed/'latest.json').write_text(json.dumps(p))
            with self.assertRaises(FileNotFoundError):prepare(feed,out,'foxlingo-daily',day,lambda paths:None)
            self.assertFalse(out.exists())

if __name__=='__main__':unittest.main()
