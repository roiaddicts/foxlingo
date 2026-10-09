"""Resolve provider records without replacing a previously named person."""
import unicodedata


def normalized(name):
    return ''.join(c for c in unicodedata.normalize('NFD', name.lower()) if not unicodedata.combining(c))


def player_name(row):
    return row.get('nickname') or ' '.join(filter(None, [row.get('firstName'), row.get('lastName')]))


def player_ids(rows, previous, overrides):
    previous = {p['id']: p for p in previous}
    configured = {r['providerID']: r for r in overrides}
    if len(configured) != len(overrides):
        raise ValueError('Duplicate player namespace override')
    resolved = {}
    for row in rows:
        provider = row['id']; legacy = f'player-{provider}'; incoming = player_name(row)
        override = configured.get(provider)
        if override:
            if override['targetID'] != f'current-player-{provider}' or override['incomingName'] != incoming:
                raise ValueError('Player namespace override no longer matches source: '+str(provider))
            old = previous.get(legacy)
            if old is None or old['name'] != override['previousName']:
                raise ValueError('Player namespace override no longer matches retained identity: '+str(provider))
            target = override['targetID']
        else:
            target = legacy
        old = previous.get(target)
        if old and normalized(old['name']) != normalized(incoming):
            raise ValueError('Player identity changed; explicit namespace required: '+target)
        resolved[provider] = None if override and override.get('quarantined') else target
    if set(configured) - set(resolved):
        raise ValueError('Player namespace override refers to missing source record')
    active = [target for target in resolved.values() if target is not None]
    if len(set(active)) != len(active):
        raise ValueError('Multiple provider players resolve to one app identity')
    return resolved
