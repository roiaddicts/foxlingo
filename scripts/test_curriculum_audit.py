"""Player coverage must measure authored learning, not optional context."""
import copy
import json
import unittest
from pathlib import Path

from audit_curriculum import audit


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


if __name__ == '__main__':
    unittest.main()
