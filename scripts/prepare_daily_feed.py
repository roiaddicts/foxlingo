"""Prepare a validated, dedicated Firebase Hosting release; never deploy it."""
import argparse,hashlib,json,re,shutil,subprocess,tempfile
from datetime import date,datetime
from pathlib import Path
from zoneinfo import ZoneInfo
ROOT=Path(__file__).resolve().parents[1]
NAME=re.compile(r'^(\d{4}-\d{2}-\d{2})-([a-f0-9]{12})\.json$')

def native_validate(packets):
    compiler=shutil.which('swiftc')
    if not compiler:raise ValueError('Swift is required for the native preflight; use a macOS build runner')
    with tempfile.TemporaryDirectory(prefix='foxlingo-native-') as directory:
        binary=Path(directory)/'validate-daily'
        subprocess.run([compiler,'-module-name','FoxlingoDailyValidation',*map(str,sorted((ROOT/'Foxlingo/Core').glob('*.swift'))),str(ROOT/'scripts/validate_daily.swift'),'-o',str(binary)],check=True)
        subprocess.run([str(binary),*map(str,packets)],check=True)

def prepare(feed,output,site,expected_date=None,validator=native_validate):
    feed=Path(feed).resolve();output=Path(output).absolute()
    if not re.fullmatch(r'[a-z0-9](?:[a-z0-9-]{0,28}[a-z0-9])?',site):raise ValueError('Provide a valid dedicated Firebase Hosting site ID')
    # Refuse to overwrite an existing release or follow an output symlink.
    if output.exists() or output.is_symlink():raise ValueError('Use a new staging directory; the previous release is preserved')
    pointer=json.loads((feed/'latest.json').read_text())
    current=pointer.get('file');match=NAME.fullmatch(current or '')
    digest=pointer.get('sha256','')
    if not match or not re.fullmatch(r'[a-f0-9]{64}',digest) or current != pointer.get('gameDate','')+'-'+digest[:12]+'.json' or pointer.get('modes')!=19:raise ValueError('Invalid daily feed pointer')
    def packet(name):
        m=NAME.fullmatch(name or '')
        if not m:raise ValueError('Invalid immutable packet filename')
        path=(feed/name).resolve()
        if path.parent != feed:raise ValueError('Packet is outside the feed directory')
        raw=path.read_bytes();sha=hashlib.sha256(raw).hexdigest();data=json.loads(raw)
        if sha[:12]!=m[2] or data.get('gameDate')!=m[1]:raise ValueError('Immutable packet checksum/date mismatch')
        return path,raw,data,sha
    path,raw,data,sha=packet(current)
    if sha!=digest or data.get('gameDate')!=pointer.get('gameDate') or data.get('timeZone')!=pointer.get('timeZone'):raise ValueError('Pointer and packet disagree')
    zone=ZoneInfo(data['timeZone']);today=expected_date or datetime.now(zone).date()
    if data['gameDate']!=today.isoformat():raise ValueError('The current packet is not today’s feed in its timezone')
    files={current:raw}
    previous=pointer.get('previous')
    if previous:
        if previous==current:raise ValueError('Rollback pointer cannot reference the current packet')
        old,oldraw,olddata,_=packet(previous)
        if olddata.get('timeZone')!=data['timeZone'] or olddata['gameDate']>data['gameDate']:raise ValueError('Invalid rollback date/timezone')
        files[previous]=oldraw
    config={'hosting':{'site':site,'public':'public','ignore':['**/.*'],
        'headers':[{'source':'/daily/latest.json','headers':[{'key':'Cache-Control','value':'no-store'},{'key':'Content-Type','value':'application/json; charset=utf-8'}]},
                   {'source':'/daily/????-??-??-????????????.json','headers':[{'key':'Cache-Control','value':'public, max-age=31536000, immutable'},{'key':'Content-Type','value':'application/json; charset=utf-8'}]}]}}
    output.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.daily-release-',dir=output.parent) as directory:
        stage=Path(directory)/'release';public=stage/'public/daily';public.mkdir(parents=True)
        for name,body in files.items():(public/name).write_bytes(body)
        # Validate the exact private byte snapshots that will be deployed,
        # rather than reopening potentially changing source files.
        validator([public/name for name in files])
        (public/'latest.json').write_text(json.dumps(pointer,indent=2)+'\n')
        (stage/'firebase.json').write_text(json.dumps(config,indent=2)+'\n')
        # The directory becomes visible only after every byte has been staged.
        stage.rename(output)
    return output

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--feed',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--site',required=True)
    args=p.parse_args()
    try:print(prepare(args.feed,args.output,args.site))
    except Exception as error:p.exit(1,'Daily release preparation rejected: '+str(error)+'\n')
