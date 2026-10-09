"""Verified module graph and static dataset discovery; downloaded code is never run."""
import hashlib,json,re
from pathlib import Path
from urllib.parse import urljoin,urlsplit
from html.parser import HTMLParser
from futbol11_source import extract,role_data

class Archive:
    def __init__(self,path):
        self.path=Path(path);self.meta=json.loads(self.path.read_text());self.modules={}
        if self.meta['schemaVersion']!=2:raise ValueError('Current-site snapshot required')
        page=(self.path.parent/'page.html').read_bytes()
        if hashlib.sha256(page).hexdigest()!=self.meta['pageSHA256']:raise ValueError('Page digest mismatch')
        for asset in self.meta['assets']:
            target=(self.path.parent/asset['file']).resolve()
            if target.parent!=self.path.parent.resolve():raise ValueError('Asset outside snapshot')
            raw=target.read_bytes()
            if hashlib.sha256(raw).hexdigest()!=asset['sha256']:raise ValueError('Module digest mismatch')
            self.modules[asset['url']]=(asset,raw.decode())
        actual=[d for url,(_,text) in self.modules.items() for d in extract(text.encode(),url)]
        if actual!=self.meta['datasets']:raise ValueError('Embedded datasets disagree with modules')
        self.roles=role_data(self.path)
    def catalog_routes(self):
        class Links(HTMLParser):
            def __init__(self):super().__init__();self.routes=set()
            def handle_starttag(self,tag,attrs):
                href=dict(attrs).get('href','')
                if tag=='a' and re.fullmatch(r'/(?:futbol11(?:-[a-z0-9-]+)?|guess-the-footballer)',href):self.routes.add(href)
        parser=Links();parser.feed((self.path.parent/'page.html').read_text())
        if not parser.routes:raise ValueError('Homepage game catalog missing')
        return parser.routes
    def mode(self,name):
        # Public implementation calls a daily store; homepage labels do not qualify.
        pattern=r'"f11-'+re.escape(name)+r'-daily",\{'
        found=[url for url,(_,text) in self.modules.items() if re.search(pattern,text)]
        if name=='impostor':found=[u for u in found if re.search(pattern+r'[^}]*gameStatus:',self.modules[u][1])]
        if len(found)!=1:raise ValueError('Ambiguous daily module: '+name)
        return found[0]
    def text(self,url):return self.modules[url][1]
    def datasets(self,url):return [d for d in self.meta['datasets'] if d['sourceURL']==url]
    def rows(self,fields,url=None):
        rows=[d['data'] for d in self.meta['datasets'] if set(d['fields'])==set(fields) and (url is None or d['sourceURL']==url)]
        unique={json.dumps(data,sort_keys=True):data for data in rows}
        if len(unique)!=1:raise ValueError('Ambiguous data schema: '+','.join(sorted(fields)))
        return next(iter(unique.values()))
    def dependencies(self,url):
        return [urljoin(url,m.group(1)) for m in re.finditer(r'from"([^" ]+\.js)"',self.text(url))]
    def import_symbol(self,url,local):
        found=[]
        for match in re.finditer(r'import\{([^}]+)\}from"([^" ]+\.js)"',self.text(url)):
            for spec in match.group(1).split(','):
                if spec.strip().split(' as ')[-1]==local:found.append((spec.strip().split(' as ')[0],urljoin(url,match.group(2))))
        if len(found)!=1:raise ValueError('Ambiguous import binding: '+local)
        return found[0]
    def imported(self,url,local):return self.import_symbol(url,local)[1]
    def main(self):
        found=[u for u in self.modules if 'function Fy(){const e=new Date;' in self.text(u)]
        if len(found)!=1:raise ValueError('Date helper changed; review needed')
        return found[0]
