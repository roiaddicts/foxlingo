"""Fetch current modules, verify nineteen daily selectors, then publish atomically."""
import argparse,json
from datetime import datetime,date
from pathlib import Path
from zoneinfo import ZoneInfo
from refresh_futbol11 import refresh,ROOT
from futbol11_daily import compile_daily,publish

def refresh_daily(destination,archives,day,zone,fetch_snapshot=refresh):
    # A mid-deploy missing module gets one fresh-page retry; changed selectors are
    # rejected instead of retrying or silently reusing the wrong challenge.
    for attempt in range(2):
        try:
            snapshot,_=fetch_snapshot(archives,site='current');break
        except Exception as error:
            if attempt==1 or getattr(error,'code',None)!=404:raise
    pack=compile_daily(snapshot/'snapshot.json',day,zone)
    return publish(pack,destination),pack

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--timezone',default='America/Mexico_City')
    parser.add_argument('--date',type=date.fromisoformat)
    parser.add_argument('--destination',type=Path,default=ROOT/'ref/futbol11-daily')
    parser.add_argument('--archives',type=Path,default=ROOT/'ref/futbol11-snapshots')
    args=parser.parse_args()
    try:
        zone=ZoneInfo(args.timezone);day=args.date or datetime.now(zone).date()
        target,pack=refresh_daily(args.destination,args.archives,day,args.timezone)
        print(str(target));print('Verified',len(pack['games']),'daily modes for',pack['gameDate'],pack['timeZone'])
    except Exception as error:
        pointer=args.destination/'latest.json'
        cached=json.loads(pointer.read_text()) if pointer.exists() else None
        message='Daily refresh failed; previous package retained: '+str(error)
        if cached:message+='\nLast good date: '+cached['gameDate']+' '+cached['timeZone']+' ('+cached['file']+')'
        parser.exit(1,message+'\n')
