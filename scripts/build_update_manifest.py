"""Create a manifest for an already reviewed lesson JSON file; never publish or upload."""
import argparse
import hashlib
import json
from pathlib import Path
from urllib.parse import urlparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--content', type=Path, required=True)
parser.add_argument('--content-url', required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
url = urlparse(args.content_url)
if url.scheme != 'https' or not url.hostname or url.username or url.password:
    parser.error('content-url must be HTTPS without embedded credentials')
data = args.content.read_bytes()
if len(data) > 16 * 1024 * 1024:
    parser.error('content exceeds the app limit of 16 MiB')
pack = json.loads(data)
manifest = {
    'packKey': pack['key'],
    'contentVersion': pack['contentVersion'],
    'schemaVersion': pack['schemaVersion'],
    'language': pack['language'],
    'contentURL': args.content_url,
    'sha256': hashlib.sha256(data).hexdigest(),
}
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(manifest, indent=2) + '\n')
print(f"Manifest created for lesson version {manifest['contentVersion']}. No files uploaded.")
