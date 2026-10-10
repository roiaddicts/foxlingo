import hashlib,json,unittest
from unittest.mock import patch
from publish_daily_feed import verify_release

class Response:
    status=200
    def __init__(self,url,raw,cache):self.url=url;self.raw=raw;self.headers={'Cache-Control':cache}
    def __enter__(self):return self
    def __exit__(self,*args):return False
    def read(self,limit):return self.raw[:limit]

class PublicationVerificationTests(unittest.TestCase):
    address='https://foxlingo-daily.web.app/daily/latest.json'
    def check(self,pointer_change=None,packet_change=None,pointer_cache='no-store',packet_cache='public, immutable'):
        raw=b'{"verified":"staged packet"}'
        expected={'file':'2026-10-10-'+hashlib.sha256(raw).hexdigest()[:12]+'.json','sha256':hashlib.sha256(raw).hexdigest()}
        served=dict(expected)
        if pointer_change:served.update(pointer_change)
        responses=[Response(self.address,json.dumps(served).encode(),pointer_cache),Response(self.address.rsplit('/',1)[0]+'/'+expected['file'],packet_change or raw,packet_cache)]
        with patch('publish_daily_feed.urllib.request.urlopen',side_effect=responses) as fetch:
            verify_release(self.address,expected)
            self.assertEqual(fetch.call_count,2)
    def test_exact_deployed_bytes_and_cache_policies(self):self.check()
    def test_stale_pointer_rejected(self):
        with self.assertRaisesRegex(ValueError,'pointer differs'):self.check(pointer_change={'file':'old.json'})
    def test_corrupt_packet_rejected(self):
        with self.assertRaisesRegex(ValueError,'checksum'):self.check(packet_change=b'corrupted')
    def test_cache_policy_mismatch_rejected(self):
        with self.assertRaisesRegex(ValueError,'pointer cache'):self.check(pointer_cache='max-age=3600')
        with self.assertRaisesRegex(ValueError,'packet cache'):self.check(packet_cache='no-store')

if __name__=='__main__':unittest.main()
