# How answers are checked

Scheduled recall compares the submitted answer with the objective’s authored `answers` aliases after removing case differences, accents, repeated whitespace, and outer whitespace. It does not currently tolerate arbitrary misspellings, compute embedding similarity, or call a model. Numeric values, dates, scores, and units require an explicit accepted form; the content author includes alternatives such as `4–1`, `4-1`, and `4 to 1`.

Games treat text as a name lookup. Search displays matching identities and known nicknames, then the learner selects the intended player. Scoring uses that concrete namespaced player ID. Bingo checks category membership; grid intersects row and column memberships; lineup checks the named historical season squad and eligible position. A used player cannot fill a second square. Classic squad IDs and general player IDs are separate; portraits are joined only when full names match.

Embedding similarity could help discovery or suggest an alias for editorial review. It should not by itself award correctness: two different players, nearby years, and similar scores can be semantically close. A conservative future typo layer can require one uniquely matching identity, with numbers and scores kept strict. Unknown or ambiguous names should prompt clarification.

A small model could eventually assess long explanations against the specific lesson facts, with an explicit uncertain result and reviewed grading examples. It is unnecessary for these short identity and statistic answers. Authored aliases and exact relationships give predictable feedback, offline operation, and no per-answer model cost.

Correctness in a game does not imply scheduled recall mastery. Games record a separate completed session and active streak day. Only independent answers to due objectives advance review stages and album tiers.
