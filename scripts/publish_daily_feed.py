"""Refresh, validate and publish Foxlingo's dedicated daily feed on this Mac."""
import fcntl,hashlib,json,shutil,subprocess,tempfile,urllib.request
from pathlib import Path
from prepare_daily_feed import prepare
from refresh_daily_futbol11 import refresh_daily
from datetime import datetime
from zoneinfo import ZoneInfo

ROOT=Path(__file__).resolve().parents[1]
PROJECT='foxlingo-daily'
SITE='foxlingo-daily'
ADDRESS=f'https://{SITE}.web.app/daily/latest.json'

def verify_release(address,expected):
    def read(url,limit):
        request=urllib.request.Request(url,headers={'Cache-Control':'no-cache'})
        with urllib.request.urlopen(request,timeout=60) as response:
            if response.status!=200 or not response.url.startswith('https://'):raise ValueError('Invalid HTTPS response')
            raw=response.read(limit+1)
            if len(raw)>limit:raise ValueError('Hosted file is too large')
            return raw,response.headers
    raw,headers=read(address,64*1024)
    pointer=json.loads(raw)
    if pointer!=expected:raise ValueError('Hosted pointer differs from the validated release')
    if 'no-store' not in headers.get('Cache-Control',''):raise ValueError('Hosted pointer cache policy is incorrect')
    raw,headers=read(address.rsplit('/',1)[0]+'/'+expected['file'],16*1024*1024)
    if hashlib.sha256(raw).hexdigest()!=expected['sha256']:raise ValueError('Hosted packet checksum mismatch')
    if 'immutable' not in headers.get('Cache-Control',''):raise ValueError('Hosted packet cache policy is incorrect')

def publish():
    firebase=shutil.which('firebase')
    if not firebase:raise ValueError('The authenticated Firebase CLI is required on this Mac')
    work=ROOT/'output/daily-feed';work.mkdir(parents=True,exist_ok=True)
    with (work/'publish.lock').open('a') as lock:
        try:fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:raise ValueError('Another daily publication is running')
        zone=ZoneInfo('America/Mexico_City')
        _,pack=refresh_daily(work/'feed',work/'archives',datetime.now(zone).date(),str(zone))
        with tempfile.TemporaryDirectory(prefix='release-',dir=work) as directory:
            release=prepare(work/'feed',Path(directory)/'validated',SITE)
            expected=json.loads((release/'public/daily/latest.json').read_text())
            subprocess.run([firebase,'deploy','--only','hosting','--project',PROJECT,'--config',str(release/'firebase.json'),'--non-interactive'],cwd=release,check=True)
            verify_release(ADDRESS,expected)
        print('Published and verified',pack['gameDate'],'· 19 native modes ·',ADDRESS)

if __name__=='__main__':
    try:publish()
    except Exception as error:raise SystemExit('Daily publication failed: '+str(error))
