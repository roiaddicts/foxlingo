"""Player coverage must measure authored learning, not optional context."""
import copy
import json
import unittest
from pathlib import Path

from audit_curriculum import audit
from catalog_identity import player_reference


class PlayerCoverageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = Path(__file__).resolve().parents[1]
        cls.pack = json.loads((root / 'Foxlingo/Resources/starter-en.json').read_text())

    def test_four_lessons_without_defining_moments_remain_unfinished(self):
        pack = copy.deepcopy(self.pack)
        path = next(p for p in pack['roadmaps'] if p['key'] == 'roadmap-player-gerrard')
        for chapter in path['chapters']:
            if chapter['title'] == 'Defining moments':
                chapter['title'] = 'More records'
        player = next(p for p in audit(pack)['players'] if p['key'] == path['key'])
        self.assertEqual(player['playerLessons'], 4)
        self.assertIn('moments', player['missingAreas'])
        self.assertFalse(player['complete'])

    def test_optional_lesson_does_not_fill_a_required_topic(self):
        pack = copy.deepcopy(self.pack)
        path = next(p for p in pack['roadmaps'] if p['key'] == 'roadmap-player-gerrard')
        for chapter in path['chapters']:
            if chapter['title'] == 'Defining moments':
                chapter['isOptional'] = True
        player = next(p for p in audit(pack)['players'] if p['key'] == path['key'])
        self.assertEqual(player['playerLessons'], 3)
        self.assertIn('moments', player['missingAreas'])
        self.assertFalse(player['complete'])

    def test_catalog_coverage_uses_reviewed_ids_and_counts_uncovered_players(self):
        pack=copy.deepcopy(self.pack)
        player_id=next(p['subjectID'] for p in pack['roadmaps'] if p['key']=='roadmap-player-gerrard')
        entity=next(e for e in pack['entities'] if e['id']==player_id)
        entity['externalRefs']={'futbol11.gamePlayers':'reviewed'}
        # A same-name seed is deliberately not a verified identity match.
        catalog={'players':[{'id':'player-reviewed','name':'Different display name'},
                            {'id':'player-unbound','name':entity['name']},
                            {'id':'player-unbound','name':entity['name']}]}
        coverage=audit(pack,catalog)['gameCatalogPlayerCoverage']
        self.assertEqual(coverage['totalCatalogPlayers'],2)
        self.assertEqual(coverage['playersWithAuthoredPaths'],1)
        self.assertEqual(coverage['playersMeetingDepthRequirements'],1)
        self.assertEqual(coverage['playersWithoutAuthoredPaths'],1)
        self.assertNotIn('roadmap-player-gerrard',coverage['independentPlayerPaths'])

    def test_classic_identity_does_not_bind_same_number_in_game_catalog(self):
        pack=copy.deepcopy(self.pack)
        player_id=next(p['subjectID'] for p in pack['roadmaps'] if p['key']=='roadmap-player-gerrard')
        entity=next(e for e in pack['entities'] if e['id']==player_id)
        namespace,provider_id=player_reference('classic-player-2497')
        entity['externalRefs']={namespace:provider_id}
        self.assertEqual(namespace,'futbol11.classicPlayers')
        game_only={'players':[{'id':'player-2497','name':entity['name']}]}
        self.assertEqual(audit(pack,game_only)['gameCatalogPlayerCoverage']['playersWithAuthoredPaths'],0)
        mixed={'players':game_only['players']+[{'id':'classic-player-2497','name':'Reviewed classic identity'}]}
        coverage=audit(pack,mixed)['gameCatalogPlayerCoverage']
        self.assertEqual(coverage['playersWithAuthoredPaths'],1)
        self.assertEqual(coverage['playersMeetingDepthRequirements'],1)
        self.assertEqual(coverage['playersWithoutAuthoredPaths'],1)

    def test_unrecognized_authored_provider_is_rejected(self):
        with self.assertRaises(ValueError):player_reference('unknown-player-2497')
        with self.assertRaises(ValueError):player_reference('classic-player-')


if __name__ == '__main__':
    unittest.main()
