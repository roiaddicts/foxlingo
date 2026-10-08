# Coverage rehearsal authoring

`content/rehearsal-prompts.json` compiles unchanged into `Foxlingo/Resources/rehearsal-en.json`. Each entry names a canonical lesson UUID, its pictured club/player UUID, a prompt, and three anchor labels in the lesson's objective order. The subject must have artwork and a card associated with that lesson. Duplicate lessons, missing context, or empty labels are rejected; retired lessons are skipped.

Answers, scope, evidence and source links come from the validated curriculum, rather than a second answer database. Choose prompts that invite an explanation supported by those three facts. This is historical rehearsal, not a live fixture briefing or an automatically graded essay.

A typed response must contain text before anchors can be revealed. Aloud rehearsal requires explicitly confirming the explanation is finished; audio is neither recorded nor assessed. Every anchor requires an explicit Included, Missed or Unsure reflection before completion. All three may be missed. Revised notes are optional and preserve the original response.

Drafts save locally with a 400 ms text debounce and flush on navigation/backgrounding. A draft stores its session ID, content signature, original and revised text, reveal state, mode and reflections. Completion records activity once without writing recall attempts, advancing due dates or changing card tiers. Previewed facts are assisted for recall in the originating Practice or comparison visit; reopening a revealed draft and reading saved history apply the same protection.

Content signatures include the prompt, labels, objective revisions and claim meaning. Updated or retired topics archive existing drafts instead of discarding notes. History retains the original title, prompt, anchor labels and reflections. Malformed optional rehearsal data is isolated from the main learning save. An archived session cannot complete later or erase a newer draft.

Run `python3 scripts/build_content.py` after changing authored prompts or favourite story drafts. Structural tests establish consistency; editorial review still needs to check that each prompt is answerable from its sourced anchors.
