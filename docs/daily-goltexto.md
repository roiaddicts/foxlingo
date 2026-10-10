# Daily Goltexto

Goltexto is a source-catalog similarity puzzle with 10, 20 or 100 guesses. Portraits, flags and shirts accompany signed scores. A breakdown explains each contribution. Search stays above the keyboard; positions, ages and ratings distinguish repeated names. Only the exact source ID wins. Completed wins grant credit once; losses and reveals grant none. Saved budgets, guesses and results survive relaunch. Practice gaps wait until the round ends and carry identities rather than unverified catalog facts.

The compiler binds the ratings module imported by the Goltexto source. It takes the first 366 profiles with club and birthday, shuffles with `today`, and selects the local rounded day ordinal. All 969 club-bearing profiles remain searchable, including 75 without birthdays. Ages are fixed to the package date. The 71-country namespace differs from general-game country IDs. Club shirts come from the source's 109-club support table. A placeholder shirt becomes initials. Portrait crosswalks use full names unique in both catalogs and transfer artwork only.

Scoring preserves source arithmetic: club +40; rating +5 through +1 within four points; age +7 through +4 within three years or a rounded penalty at ten or more years; overlapping positions +10 plus +5 for the same primary position; broad role +10; shared wing/fullback group +10; role mismatch −5. Source league groups yield +20/−5, regional groups +6/−2, nationality +20/−5. Combined mismatches add −15 at four or −6 per mismatch from five onward. Missing ages contribute zero. Unclassified clubs share a nil league group; unclassified countries share region zero, matching the source. Wrong identities cap at 99, the exact identity at 100. Signed scores remain visible even below zero.

These attributes describe the source game catalog, not verified current club affiliations, live ratings or geographic classifications. The app states this scope and explains the group behavior. It does not use similarity scoring for factual free-text recall.

`scripts/goltexto_reference.js` is an independently authored math reference accepting JSON data; it never executes downloaded JavaScript. The committed October 9 oracle checks all 969 scores. Python verifies compilation and the reference fixture; Swift compares every native score and breakdown total with it, and checks malformed selections, crosswalks, caps, budgets, saves and one-time credit. The simulator flow covers distinct same-name search profiles, negative and closer scores, rules, relaunch and exact completion.

Run `python3 -m unittest discover -s scripts -p 'test_*.py'` and `swift test`. For simulator verification, run `FlowTests/testDailyGoltextoScoresBreakdownBudgetResumeAndWin` in the Xcode UI test target.

Coverage is now 18 native modes and eight packaged daily consumers. Bingo Retro and eleven daily adapters remain. Public hosting is still unconfigured; refresh publication, HTTPS pointer import and an offline bundle are available.
