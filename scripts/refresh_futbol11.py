"""Fetch an atomic, dated archive of the current public Futbol11 JS data."""
import argparse
from datetime import datetime, timezone
import hashlib
from html.parser import HTMLParser
import json
import os
import re
from pathlib import Path
import shutil
import tempfile
from urllib.parse import urljoin, urlsplit
from urllib.request import Request, build_opener, HTTPRedirectHandler

from futbol11_source import extract, bind_roles

ROOT = Path(__file__).resolve().parents[1]
ALLOWED = {'futbol-11.com', 'www.futbol-11.com', 'futbol11.com', 'www.futbol11.com'}
SITES = {'current': 'https://futbol11.com/', 'legacy': 'https://futbol-11.com/'}
MODULE = re.compile(r'''["']((?:\./|\.\./|/|https://)[^"'\s]+\.js(?:\?[^"'\s]*)?)["']''')
MAX_ASSET = 32 * 1024 * 1024


def source_url(url):
    p = urlsplit(url)
    if p.scheme != 'https' or p.hostname not in ALLOWED or p.username or p.password or p.port not in (None, 443):
        raise ValueError('Only public HTTPS assets on Futbol11 are accepted')
    return url


class Redirects(HTTPRedirectHandler):
    max_redirections = 4
    def redirect_request(self, request, response, code, message, headers, url):
        source_url(url)
        return super().redirect_request(request, response, code, message, headers, url)


def download(url, limit=MAX_ASSET):
    request = Request(source_url(url), headers={'User-Agent': 'Foxlingo-content-refresh/1.0', 'Accept-Encoding': 'identity'})
    with build_opener(Redirects).open(request, timeout=30) as response:
        source_url(response.url)
        data = response.read(limit + 1)
        if len(data) > limit:
            raise ValueError('Source exceeds download limit')
        return data


class Scripts(HTMLParser):
    def __init__(self): super().__init__(); self.urls = []
    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if tag == 'script' and attrs.get('src'):
            self.urls.append(attrs['src'])


def refresh(destination, fetch=download, site='legacy'):
    destination = Path(destination); destination.mkdir(parents=True, exist_ok=True)
    page_url = SITES[site]
    page = fetch(page_url, 1024 * 1024)
    parser = Scripts(); parser.feed(page.decode('utf-8'))
    urls = []
    for src in parser.urls:
        url = urljoin(page_url, src)
        if urlsplit(url).hostname not in ALLOWED: continue
        source_url(url)
        if urlsplit(url).path.endswith('.js') and url not in urls: urls.append(url)
    if not urls or len(urls) > 12:
        raise ValueError('Unexpected script inventory; previous snapshot retained')
    stage = Path(tempfile.mkdtemp(prefix='.staging-', dir=destination))
    try:
        (stage/'page.html').write_bytes(page)
        datasets = []; assets = []; total = 0
        index = 0
        while index < len(urls):
            url = urls[index]
            raw = fetch(url, MAX_ASSET); total += len(raw)
            if total > 64 * 1024 * 1024: raise ValueError('Total source assets exceed limit')
            filename = f'asset-{index}.js'; (stage/filename).write_bytes(raw)
            assets.append(dict(url=url, file=filename, bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
            datasets.extend(extract(raw, url))
            if site == 'current':
                for dependency in MODULE.findall(raw.decode('utf-8')):
                    candidate = urljoin(url, dependency)
                    if urlsplit(candidate).hostname not in ALLOWED: continue
                    source_url(candidate)
                    if candidate not in urls: urls.append(candidate)
                if len(urls) > 128: raise ValueError('Too many module dependencies')
            index += 1
        if site == 'legacy':
            roles = bind_roles(datasets)
        else:
            if not datasets: raise ValueError('No embedded current-site datasets found')
            try:
                roles = bind_roles(datasets, 'current')
            except ValueError:
                roles = {} # Retain inspectable archives; the compiler still rejects unbound roles.
        timestamp = datetime.now(timezone.utc).isoformat()
        snapshot = dict(schemaVersion=1 if site == 'legacy' else 2, fetchedAt=timestamp, sourceURL=page_url,
                        pageSHA256=hashlib.sha256(page).hexdigest(), assets=assets, roles=roles, datasets=datasets,
                        scope='Provider seed snapshot. Fetch time is not roster/stat freshness; raw IDs are snapshot-scoped. JavaScript was not executed.',
                        roleStatus=f'Validated {site} game roles' if roles else 'Current modules archived; compiler roles not yet reviewed')
        (stage/'snapshot.json').write_text(json.dumps(snapshot, ensure_ascii=True, indent=2)+'\n')
        inventory = dict(fetchedAt=timestamp, assets=assets, roles=roles,
                         datasets=[{k:v for k,v in d.items() if k!='data'} for d in datasets],
                         totalRecords=sum(d['records'] for d in datasets),
                         dailyDataStatus='Embedded datasets retained; no independent daily-game endpoint or game-date coverage verified.')
        (stage/'inventory.json').write_text(json.dumps(inventory, indent=2)+'\n')
        name = timestamp.replace(':','-') + '-' + hashlib.sha256((stage/'snapshot.json').read_bytes()).hexdigest()[:12]
        folder = destination/name; stage.rename(folder)
        pointer_name = 'latest.json' if site == 'legacy' else 'latest-current.json'
        previous = json.loads((destination/pointer_name).read_text()).get('snapshot') if (destination/pointer_name).exists() else None
        pointer = dict(snapshot=name, previous=previous, fetchedAt=timestamp)
        temporary = destination/('.'+pointer_name+'-next'); temporary.write_text(json.dumps(pointer, indent=2)+'\n')
        os.replace(temporary, destination/pointer_name)
        return folder, inventory
    finally:
        if stage.exists(): shutil.rmtree(stage)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', type=Path, default=ROOT/'ref/futbol11-snapshots')
    parser.add_argument('--site', choices=SITES, default='current', help='Current modular site or validated legacy seed source')
    args = parser.parse_args()
    folder, inventory = refresh(args.destination, site=args.site)
    print(f'{len(inventory["datasets"])} datasets; {inventory["totalRecords"]} source records; snapshot: {folder}')
    print(inventory['dailyDataStatus'])
