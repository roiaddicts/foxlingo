# Favorites enrichment notes

This addition contains four sourced lesson drafts: deeper Casillas honours, Ramos’s Madrid trophy record, Xolos’s climb from its first professional match to the top flight, and Madrid’s European Cup sequence from 2018 through 2024. Each lesson has two story paragraphs and three quiz facts. The story paragraphs state every correct answer.

## Provenance

I inspected `vision.md`, `scripts/build_content.py`, and the existing favorite lessons in `Foxlingo/Resources/starter-en.json`. The existing anchors include Casillas’s goalkeeper role, 1999 debut year, and 725 Madrid appearances; Ramos’s defender role, 2014 equalizer, and 101 Madrid goals; Xolos’s founding year, promotion year, and 2012 top-flight title; and Madrid’s first five European Cups and 2014 La Décima. The new facts add career honours and more precise historical milestones without testing those same facts again.

The Firecrawl skill instructions were consulted, but its CLI is unavailable in this environment. I used the built-in web search and page-opening tools to find and verify official club pages. Every page listed in the JSON was reachable on 2026-10-08; all substantive claims below come from the relevant club’s own page:

- Real Madrid’s 2024 Casillas anniversary page gives his 19 Madrid titles, three Champions League titles, 2010 World Cup, and Euros in 2008 and 2012.
- Real Madrid’s historical Ramos profile gives his 22 total titles, four European Cups, and five LaLiga titles.
- Xolos’s historical chronology records its professional debut, first Liga de Ascenso title, promotion path, and first-division start.
- Real Madrid’s pages for La Decimotercera, La Decimocuarta, and La Decimoquinta confirm the 2018, 2022, and 2024 European Cup milestones.

Evidence fields contain short verbatim excerpts. Excerpts from each source remain within the 25-word quotation limit. Since the quiz choices use numbers, dates, seasons, and competition names, they do not introduce club, player, or country choices that would depend on unverified artwork.

## Scope and limitations

All statistics are historical totals attached to a completed career or a specified final/year. Nothing describes current form, squad membership, or live standings. Xolos’s historical chronology is an older club-published retrospective; its historical dates remain useful, though it should not be treated as a current source for present-day club information. No unsupported claims were added where official sources were available.

## Integration review

The main agent rechecked all six official pages. Xolos’s first championship is explicitly labelled Liga de Ascenso to distinguish it from the 2012 Liga MX title; precise dates use canonical date values. The Casillas World Cup answer retains its 2010 scope and accepts the authored competition aliases. The compiler adds four lessons and twelve objectives without changing any pre-existing fact, objective, exercise, lesson, entity or source record. The four expanded cards increment their knowledge-set version to 2, preserving previously earned tiers while exposing the new connections. New lessons finish after four questions, with memory matching remaining in Games.
