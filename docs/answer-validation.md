# How answers are checked

Scheduled recall compares the submitted answer with the objective’s authored `answers` aliases after removing case differences, accents, repeated whitespace, and outer whitespace. It does not currently tolerate arbitrary misspellings, compute embedding similarity, or call a model. Numeric values, dates, scores, and units require an explicit accepted form; the content author includes alternatives such as `4–1`, `4-1`, and `4 to 1`.

Games treat text as a name lookup. Search displays matching identities and known nicknames, then the learner selects the intended player. Scoring uses that concrete namespaced player ID. Bingo checks category membership; grid intersects row and column memberships; lineup checks the named historical season squad and eligible position. A used player cannot fill a second square. Classic squad IDs and general player IDs are separate; portraits are joined only when full names match.

Embedding similarity could help discovery or suggest an alias for editorial review. It should not by itself award correctness: two different players, nearby years, and similar scores can be semantically close. A conservative future typo layer can require one uniquely matching identity, with numbers and scores kept strict. Unknown or ambiguous names should prompt clarification.

A small model could eventually assess long explanations against the specific lesson facts, with an explicit uncertain result and reviewed grading examples. It is unnecessary for these short identity and statistic answers. Authored aliases and exact relationships give predictable feedback, offline operation, and no per-answer model cost.

Correctness in a game does not imply scheduled recall mastery. Games record a separate completed session and active streak day. Only independent answers to due objectives advance review stages and album tiers.

## Memory matching and learning evidence

Memory is a standalone 4×4 mini game in Games, with eight image-to-name or image-to-stat pairs. Matching has been removed from lessons. Pair definitions reference canonical subjects and optional numeric facts; the stat must belong to the pictured subject and answers must distinguish all eight pairs. Normal boards shuffle all sixteen tiles. The learner reveals two; valid associations remain visible, and mismatches close after 1.8 seconds. The game permits either reveal order and same-side mistakes, preserves the board layout and found pairs across an app relaunch, and conceals face-down text from accessibility labels. Incorrect feedback does not reveal an unseen correct partner.

This is a design choice for variety and memory challenge. It can reward remembering tile locations, so it is not treated as proof of independent football knowledge. Scheduled typed recall remains the mastery check. [Roediger and Karpicke (2006)](https://pubmed.ncbi.nlm.nih.gov/16507066/) provide evidence for the retention benefits of retrieval practice; their study did not test this app’s face-down game.

## Visual context in recall

Recall can show a portrait or badge of the factual subject when the answer is a statistic or another entity. When accepted aliases identify that subject, or a fact tests its name or nickname, both the artwork and its accessible name remain absent until the answer has been submitted. Multi-subject objectives stay neutral. This prevents a Ramos portrait from answering the equalizer question and avoids counting recognition of a logo as independent club-name recall.

Score questions with authored wheel metadata compare the two selected integers in the authored team order. The metadata must agree with the canonical choice and a recall answer alias. This applies to recall as well as introductory questions; swapping a non-drawn score is incorrect. A score-shaped season never activates this control automatically.
