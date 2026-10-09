import copy
import unittest
from futbol11_identity import player_ids


class IdentityTests(unittest.TestCase):
    def setUp(self):
        self.previous=[dict(id='player-5',name='Neymar'),dict(id='player-2229',name='Hannibal Mejbri')]
        self.rows=[dict(id=5,nickname='Neymar Jr'),dict(id=2229,firstName='Dwight',lastName='Gayle')]
        self.overrides=[dict(providerID=5,previousName='Neymar',incomingName='Neymar Jr',targetID='current-player-5'),
                        dict(providerID=2229,previousName='Hannibal Mejbri',incomingName='Dwight Gayle',targetID='current-player-2229')]

    def test_same_names_elsewhere_do_not_join_and_changed_ids_need_review(self):
        self.assertEqual(player_ids([dict(id=99,nickname='Neymar')],self.previous,[]),{99:'player-99'})
        with self.assertRaises(ValueError):player_ids(self.rows,self.previous,[])

    def test_reviewed_records_get_separate_ids_and_input_is_preserved(self):
        before=copy.deepcopy(self.previous)
        self.assertEqual(player_ids(self.rows,self.previous,self.overrides),{5:'current-player-5',2229:'current-player-2229'})
        self.assertEqual(before,self.previous)

    def test_override_cannot_follow_a_later_reused_id(self):
        for field in ['incomingName','previousName','targetID']:
            changed=copy.deepcopy(self.overrides);changed[0][field]='Another'
            with self.assertRaises(ValueError):player_ids(self.rows,self.previous,changed)
        occupied=self.previous+[dict(id='current-player-5',name='Another Player')]
        with self.assertRaises(ValueError):player_ids(self.rows,occupied,self.overrides)

    def test_duplicate_or_missing_override_is_rejected(self):
        with self.assertRaises(ValueError):player_ids(self.rows,self.previous,self.overrides+self.overrides[:1])
        with self.assertRaises(ValueError):player_ids(self.rows[:1],self.previous,self.overrides)

    def test_quarantined_record_keeps_review_checks_but_has_no_active_identity(self):
        self.overrides[0]['quarantined']=True
        self.assertEqual(player_ids(self.rows,self.previous,self.overrides),{5:None,2229:'current-player-2229'})
        changed=copy.deepcopy(self.rows);changed[0]['nickname']='Different Person'
        with self.assertRaises(ValueError):player_ids(changed,self.previous,self.overrides)


if __name__=='__main__':unittest.main()
