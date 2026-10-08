"""Resolve missing club badge URLs from the actual Wikipedia infobox images."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json,re,subprocess,html,urllib.parse,time
ROOT=Path(__file__).resolve().parents[1]
wiki={'aek-athens':'AEK Athens F.C.','atlas':'Atlas F.C.','atletico-madrid':'Atlético Madrid','augsburg':'FC Augsburg','bayern-munich':'FC Bayern Munich','bodo-glimt':'FK Bodø/Glimt','borussia-dortmund':'Borussia Dortmund','borussia-monchengladbach':'Borussia Mönchengladbach','club-brugge':'Club Brugge KV','como':'Como 1907','eintracht-frankfurt':'Eintracht Frankfurt','elversberg':'SV Elversberg','fc-cologne':'1. FC Köln','feyenoord':'Feyenoord','freiburg':'SC Freiburg','hamburger-sv':'Hamburger SV','hoffenheim':'TSG 1899 Hoffenheim','lask':'LASK','leipzig':'RB Leipzig','lens':'RC Lens','lille':'Lille OSC','mainz-05':'1. FSV Mainz 05','paderborn-07':'SC Paderborn 07','sabah':'Sabah FC (Azerbaijan)','schalke-04':'FC Schalke 04','slavia-prague':'SK Slavia Prague','slovan-bratislava':'ŠK Slovan Bratislava','stuttgart':'VfB Stuttgart','union-berlin':'1. FC Union Berlin','viking':'Viking FK','werder-bremen':'SV Werder Bremen'}
clubs=json.loads((ROOT/'content/club-expansion.json').read_text())['clubs']
def find(club):
 if club.get('logoURL'):return club['key'],{'url':club['logoURL'],'source':'Supplied seed or official club site'}
 title=wiki.get(club['key'])
 if not title:return club['key'],{'url':None,'source':None}
 url='https://en.wikipedia.org/wiki/'+urllib.parse.quote(title.replace(' ','_'),safe='()')
 r=subprocess.run(['curl','-fsSL','--retry','2','--retry-delay','1','--max-time','20',url],capture_output=True)
 if r.returncode:return club['key'],{'url':None,'source':url}
 s=r.stdout.decode(errors='ignore');start=s.find('class="infobox');section=s[start:start+18000] if start>=0 else ''
 image=re.search(r'<img[^>]+src="([^"]+)"',section)
 v=html.unescape(image.group(1)).split('?')[0] if image else None
 if v and v.startswith('//'):v='https:'+v
 return club['key'],{'url':v,'source':url}
previous=json.loads((ROOT/'content/club-artwork.json').read_text()) if (ROOT/'content/club-artwork.json').exists() else {}
result=previous.copy()
for club in clubs:
 if result.get(club['key'],{}).get('url'):continue
 key,value=find(club);result[key]=value;time.sleep(0.5)
(ROOT/'content/club-artwork.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(sum(bool(c['url']) for c in result.values()),'badge sources;',len(result),'clubs')
