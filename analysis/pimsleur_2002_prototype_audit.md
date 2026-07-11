# Pimsleur 2002 Prototype Audit

This audit uses the human-corrected 2002 French I Markdown and TXT transcripts
under `pimsleur-hub/course-creation-research/references/pimsleur-human-labeled/`.
It is a design audit, not a claim that the prototype reproduces Pimsleur's
copyrighted course or proprietary scheduling method.

## What the first lessons actually do

Unit 1 begins with a short target conversation, explicitly promises that the
learner will understand and participate in it, then spends almost the entire
lesson teaching and retrieving the language required for that exchange. The
conversation returns around minute 21. Two role-play passes follow, the second
with less scaffolding, before the lesson ends near minute 28. A simple transcript
count finds roughly 79 direct learner-response prompts.

Units 2 and 3 do not reset. They begin with immediate retrieval and reuse of
Unit 1 material, mix earlier items into new prompts, add a small amount of new
language, and end with another participation sequence. The body is therefore a
review and retrieval engine aimed at a scene, not a phrase list and not merely a
line-by-line explanation of the opening dialogue.

The 2002 evidence also qualifies one claim in the existing
`HOW_PIMSLEUR_WORKS.md`: explicit part-by-part work is structurally concentrated
in Unit 1, but it is not literally absent afterward. Unit 2 says “Repeat after
him, part by part” for *Mademoiselle*, and Unit 3 includes sound distinctions.
For this prototype the distinction is moot by product choice: it uses only full
words and phrases and does no pronunciation scoring.

## Reproducibility issue in the current research tree

On 2026-07-11, running `uv run --locked scripts/verify_claims.py` from the
`pimsleur-gen` directory reported a corpus fingerprint of zero files and then
failed on the old path
`course-creation-research/french-course-transcripts/Pimsleur/...`. The current
human-corrected corpus lives under
`course-creation-research/references/pimsleur-human-labeled/...`. Until those
paths are repaired, the document's measured claims should not be described as
currently reproducible from its verifier.

## Constraints used by Operation Platform Two

- The target scene is the reason for the lesson, but explicit training performs
  the learning.
- The first call is a preview. The final call removes English and becomes source
  evidence for a game action.
- New recurring material stays near ten items or chunks.
- A trained item returns in mixed contexts rather than appearing once in a
  dedicated block.
- Learner-response windows are explicit and usually several seconds long.
- The planned timing envelope reserves roughly one third of the experience for
  response silence.
- The player retrieves complete words and phrases aloud. No microphone,
  pronunciation score, or sub-word accent judgment is required.
- The authored field scene is deterministic and reconvergent. French changes
  what evidence the player can act on; choosing an English translation is not
  the game.

## Quality boundary

Browser speech synthesis is sufficient to exercise timing, voice separation,
and autoplay. It is not a French voice-quality approval process. Before a public
or instructional release, every French line and every baked TTS render needs a
native reviewer. ASR can catch missing or substituted words, but cannot approve
accent, prosody, or naturalness.
