"""Read public source assets as data; never evaluate their JavaScript."""
import hashlib
import json
import re
from pathlib import Path

LITERAL = re.compile(r'''JSON\.parse\(\s*("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)\s*\)''')


def js_string(literal):
    if literal.startswith('`') and '${' in literal:
        raise ValueError('Interpolated template strings are not static data')
    body = literal[1:-1]
    result = []
    i = 0
    escapes = {'n': '\n', 'r': '\r', 't': '\t', 'b': '\b', 'f': '\f', 'v': '\v', '0': '\0', '"': '"', "'": "'", '\\': '\\', '/': '/'}
    while i < len(body):
        if body[i] != '\\':
            result.append(body[i]); i += 1; continue
        i += 1
        if i == len(body):
            raise ValueError('Truncated JavaScript string escape')
        char = body[i]; i += 1
        if char in escapes:
            result.append(escapes[char])
        elif char in ('u', 'x'):
            size = 4 if char == 'u' else 2
            digits = body[i:i + size]
            if len(digits) != size or not re.fullmatch(r'[0-9a-fA-F]+', digits):
                raise ValueError('Invalid Unicode/hex string escape')
            result.append(chr(int(digits, 16))); i += size
        elif char == '\n':
            continue
        elif char == '\r':
            if i < len(body) and body[i] == '\n': i += 1
        else:
            raise ValueError('Unsupported JavaScript string escape')
    return ''.join(result)


def extract(raw, url):
    digest = hashlib.sha256(raw).hexdigest()
    source = raw.decode('utf-8')
    datasets = []
    for index, match in enumerate(LITERAL.finditer(source)):
        value = json.loads(js_string(match.group(1)))
        if not isinstance(value, list):
            continue
        fields = sorted({key for row in value if isinstance(row, dict) for key in row})
        ids = [json.dumps(row['id'], sort_keys=True) for row in value if isinstance(row, dict) and 'id' in row]
        datasets.append(dict(id=f'futbol11.{digest}.literal{index}', sourceURL=url, assetSHA256=digest,
                             literalIndex=index, offset=match.start(), records=len(value), fields=fields,
                             duplicateIDs=len(ids)-len(set(ids)), data=value))
    return datasets


def bind_roles(datasets, profile='legacy'):
    """Positional indexes are diagnostics, not identities or join instructions."""
    checks = {
        'gamePlayers': lambda d: {'bingo', 'grid', 'countryID', 'image', 'firstName', 'id'} <= set(d['fields']),
        'countries': lambda d: set(d['fields']) == {'id', 'name', 'flag'},
        'categories': lambda d: set(d['fields']) == {'id', 'level', 'players', 'title'},
        'classicPlayers': lambda d: {'active', 'clubID', 'positions', 'firstName', 'id'} <= set(d['fields']) and all(isinstance(r.get('positions'), str) for r in d['data']),
        'classicSquads': lambda d: set(d['fields']) == {'clubID', 'id', 'logo', 'name', 'players'},
        'catalogPlayers': lambda d: {'birthday', 'ovr', 'countryID', 'clubID', 'firstName', 'id'} <= set(d['fields']),
        'gameGroups': lambda d: set(d['fields']) == {'id', 'name', 'logo', 'type'} and any(r.get('type') == 'league' for r in d['data']),
        'leagues': lambda d: set(d['fields']) == {'id', 'name'} and all('League' in r.get('name', '') for r in d['data']),
        'leagueClubs': lambda d: set(d['fields']) == {'id', 'name', 'countryID'},
    }
    if profile == 'current':
        checks = {k:v for k,v in checks.items() if k in {'gamePlayers','countries','categories','classicPlayers','classicSquads','gameGroups'}}
        checks['countries'] = lambda d: {'id','name','flag'} <= set(d['fields']) <= {'id','name','flag','bgColor'}
        checks['gameGroups'] = lambda d: set(d['fields']) == {'id','name','logo','type'}
    elif profile != 'legacy':
        raise ValueError('Unknown source role profile')
    roles = {}
    for role, check in checks.items():
        matches = [d for d in datasets if d['records'] > 0 and check(d)]
        if len(matches) != 1:
            raise ValueError(f'{role}: expected one unambiguous schema, found {len(matches)}; previous snapshot retained')
        item = matches[0]
        if item['duplicateIDs']:
            raise ValueError(f'{role}: duplicate entity identifiers')
        roles[role] = item['id']
    by_id = {d['id']: d for d in datasets}
    def rows(role): return by_id[roles[role]]['data']
    def ids(role): return {r['id'] for r in rows(role)}
    anchors = [('gamePlayers', 1, 'Cristiano', 'Ronaldo'), ('classicPlayers', 1, 'Peter', 'Shilton')]
    for role, identifier, first, last in anchors:
        row = next((r for r in rows(role) if r['id'] == identifier), {})
        if row.get('firstName') != first or row.get('lastName') != last:
            raise ValueError(f'{role}: provider identity anchor changed')
    missing_categories = {int(i.strip()) for r in rows('categories') for i in r['players'].split(',') if i.strip()} - ids('gamePlayers')
    missing_squads = {int(i.strip()) for r in rows('classicSquads') for i in r['players'].split(',') if i.strip()} - ids('classicPlayers')
    if missing_categories or missing_squads:
        raise ValueError(f'Broken game references: categories={sorted(missing_categories)}, squads={sorted(missing_squads)}')
    return roles


def role_data(snapshot):
    value = json.loads(Path(snapshot).read_text())
    by_id = {d['id']: d for d in value['datasets']}
    expected = bind_roles(value['datasets'], 'current' if value['schemaVersion'] == 2 else 'legacy')
    if value['roles'] != expected:
        raise ValueError('Snapshot role manifest disagrees with validated datasets')
    return {role: by_id[identifier]['data'] for role, identifier in expected.items()}
