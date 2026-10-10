"""Cache selected source images in asset catalogs, preserving URL provenance."""
from pathlib import Path
import json,subprocess,re,html
ROOT=Path(__file__).resolve().parents[1]; ASSETS=ROOT/'Foxlingo/Resources/Assets.xcassets'
p=json.loads((ROOT/'Foxlingo/Resources/games-en.json').read_text())
urls={'entity-madrid':'https://img.uefa.com/imgml/TP/teams/logos/100x100/50051.png','entity-xolos':'https://www.xolos.com.mx/images/sitio/logo.png'}
for key in ['arce','riascos','saucedo']:
 file=Path('/private/tmp/'+key+'-page.html')
 if file.exists():
  images=re.findall(r'<img[^>]+src="([^"]+)"',file.read_text())
  v=next((i for i in images if 'commons/thumb/' in i and '.jpg' in i),None)
  if v:urls['entity-'+key]='https:'+html.unescape(v).split('?')[0]
for n in [1,9,53,57,12,56,76,79,83,103,210,28,18,54,58,74,86,128,129,145,165,173,176,187,198,212,223,230,242,251,258,261,278,285,291,303,310,326,352,358,365,402,434,461,498,512,1512]:
 player=next((x for x in p['players'] if x['id']==f'player-{n}'),None)
 if player and player.get('imageURL'):urls[f'seed-player-{n}']=player['imageURL']
for player in p['players']:
 if player['id'].startswith('current-player-') and player.get('imageURL'):
  urls[player['imageAsset']]=player['imageURL']
# Retain the exact source-to-entity linkage; no ID joins across namespaces.
for key,n in [('cristiano',1),('casillas',53),('ramos',57),('di-stefano',1512),('bale',9)]:urls['entity-'+key]=urls[f'seed-player-{n}']
# New authored players carry an explicit provider identity and reviewed portrait source.
catalog=json.loads((ROOT/'content/player-catalog.json').read_text())
for player in catalog['players']:
 seed=next(v for v in p['players'] if v['id']==player['seedID'])
 if seed['name'] != player['seedName']:raise ValueError('Portrait identity changed: '+player['key'])
 image=player.get('imageURL') or seed.get('imageURL')
 if not image:raise ValueError('Missing authored player portrait: '+player['key'])
 urls[player['key']]=image
 if seed.get('imageURL'):urls['seed-'+seed['id']]=seed['imageURL']
urls['entity-juventus']='https://img.uefa.com/imgml/TP/teams/logos/100x100/50139.png'
artworkPath=ROOT/'content/club-artwork.json'
if artworkPath.exists():
 for key,value in json.loads(artworkPath.read_text()).items():
  if value.get('url'):urls.setdefault('entity-'+key,value['url'])
for club in json.loads((ROOT/'content/club-search-artwork.json').read_text()):
 urls.setdefault(club['asset'],club['imageURL'])
for c in p["categories"]:
 if c.get("imageAsset") and c.get("imageURL"):urls.setdefault(c["imageAsset"],c["imageURL"])
for competition in json.loads((ROOT/'content/competition-artwork.json').read_text()):
 if competition['key'] == 'entity-competition-premier-league':urls[competition['key']]=competition['assetURL']
for squad in p['lineups']:
 if squad.get('imageAsset') and squad.get('imageURL'):urls[squad['imageAsset']]=squad['imageURL']
countries=json.loads((ROOT/'content/country-artwork.json').read_text())
for key in ['ecuador','spain','mexico','germany','brazil','portugal','argentina','france','england','colombia','austria','azerbaijan','belgium','czechia','greece','italy','netherlands','norway','slovakia','turkiye','ukraine','uruguay','chile']:
 c=countries[key];urls[c['imageAsset']]=c['imageURL']
draft_path=ROOT/'Foxlingo/Resources/drafts-en.json'
if draft_path.exists():
 for mode in json.loads(draft_path.read_text())['modes']:
  for group in mode['groups']:urls.setdefault(group['imageAsset'],group['imageURL'])
manifest_path=ROOT/'Foxlingo/Resources/artwork-manifest.json'
previous_artwork={item['asset']:item for item in json.loads(manifest_path.read_text())} if manifest_path.exists() else {}
def cache_image(item):
 name,url=item
 folder=ASSETS/(name+'.imageset');folder.mkdir(exist_ok=True)
 file=folder/'image.png'
 if file.exists() and (folder/'Contents.json').exists():
  cached=dict(previous_artwork.get(name,{}))
  cached.update(asset=name,url=cached.get('url',url),cached=True)
  if cached['url'] != url:cached['requestedURL']=url
  return cached
 r=subprocess.run(['curl','-fsSL','--retry','2','--retry-delay','1','--max-time','20',url,'-o',str(file)],capture_output=True)
 if r.returncode or not file.exists():
  return dict(asset=name,url=url,cached=False)
 # Verify and convert to PNG, bounding decoded memory costs without altering content.
 r=subprocess.run(['sips','-s','format','png','-Z','320',str(file),'--out',str(file)],capture_output=True)
 if r.returncode:
  file.unlink(missing_ok=True);return dict(asset=name,url=url,cached=False)
 (folder/'Contents.json').write_text(json.dumps({'images':[{'filename':'image.png','idiom':'universal'}],'info':{'author':'xcode','version':1}},indent=2)+'\n')
 return dict(asset=name,url=url,cached=True)
from concurrent.futures import ThreadPoolExecutor
with ThreadPoolExecutor(max_workers=8) as pool:
 manifest=list(pool.map(cache_image,urls.items()))
for player in catalog['players']:
 if player.get('portraitSourceURL'):
  item=next(m for m in manifest if m['asset']==player['key']);item['sourceURL']=player['portraitSourceURL']
# Keep curated career artwork (including a crest cropped from an AFC PDF).
# These cached artifacts have their own provenance and are not raw URL images.
for item in json.loads((ROOT/'content/player-career-artwork.json').read_text()):
 if not any(m['asset']==item['key'] for m in manifest):
  manifest.append(dict(asset=item['key'],url=item['imageURL'],sourceURL=item['sourceURL'],cached=(ROOT/item['assetPath']).exists()))
for name,item in previous_artwork.items():
 if not any(m['asset']==name for m in manifest):manifest.append(item)
(ROOT/'Foxlingo/Resources/artwork-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(sum(m['cached'] for m in manifest),'images cached;',len(manifest),'requested')
