"""Keep reviewed player IDs in their original provider namespace."""

PLAYER_NAMESPACES = {
    'futbol11.gamePlayers': 'player-',
    'futbol11.classicPlayers': 'classic-player-',
}


def player_reference(seed_id):
    for namespace, prefix in PLAYER_NAMESPACES.items():
        if seed_id.startswith(prefix) and seed_id[len(prefix):]:
            return namespace, seed_id[len(prefix):]
    raise ValueError('Unsupported authored player identity: ' + seed_id)


def referenced_player_ids(external_refs):
    return {prefix + str(external_refs[namespace])
            for namespace, prefix in PLAYER_NAMESPACES.items()
            if namespace in external_refs}
