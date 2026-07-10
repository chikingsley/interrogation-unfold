# Learning Map

This repo has two different kinds of organization:

- `corpus/` preserves the readable files recovered from the shipped game.
- `docs/` and `analysis/` explain those files in a way a human can study.

Do not treat `corpus/` as the ideal structure for a new game. Treat it as
evidence. The useful design structure is the one we infer from it.

## Is `corpus/` Everything?

No. `corpus/` is the readable corpus: decompiled Lua, episode JSON graphs,
FUIOR story scripts, and localization Lua files.

The shipped app contains more than that. The ignored local app bundle under
`raw/app/Interrogation.app/` still has the Defold archive files, the app
executable, icons, signing metadata, iOS wrapper files, and FMOD `.bank` audio
assets. The original extraction history found thousands of archive entries;
`corpus/` keeps the parts that are useful for understanding runtime logic,
narrative structure, and data-driven dialogue.

That is why the right split is:

- `raw/`: source material and provenance, mostly ignored.
- `generated/`: regenerated extraction/decryption/decompilation outputs, ignored.
- `corpus/`: checked-in readable evidence.
- `analysis/`: derived inventories and notes.
- `docs/`: curated explanations.
- `src/interrogation_unfold/`: reusable Python tooling.

## The Main Concepts

### Chapters

Chapters are the high-level story sequence. They are the table of contents for
the campaign.

Start here:

- `corpus/main/progression/chapter1/index.lua`
- `corpus/main/progression/chapter2/index.lua`
- `corpus/main/progression/chapter3/index.lua`

These files chain tutorials, interrogation episodes, campaign phases, press
releases, interludes, interviews, minigames, triggered scenes, and cutscenes.

For a new language-learning game, chapters are closest to units or acts.

### Episodes

Episodes are interrogation levels. The data lives in `corpus/episodes/*.json`.
Each episode is a graph of subjects, questions, answers, conditions, effects,
hints, and localization references.

The interpreter for those graphs is mainly:

- `corpus/level/store.lua`
- `corpus/main/progression/episode.lua`

For a language-learning game, episodes are closest to lessons, scenario drills,
or conversations with branching learner responses.

### FUIOR

FUIOR files are authored narrative scripts in `corpus/fuior/**/*.fui`. They are
not the same thing as episode JSON. They describe story scenes: setup, dialogue,
choices, conditions, variables, waits, animation cues, and transitions.

Good entry files:

- `corpus/fuior/example.fui`
- `corpus/fuior/example_advanced.fui`
- `corpus/fuior/chapter1/interlude_c.fui`
- `corpus/fuior/triggered_torture_e1.fui`

The runtime bridge is:

- `corpus/main/fuior/runtime.lua`

For a language-learning game, FUIOR is the model for authored scenes around
lessons: setup, scripted dialogue, character reactions, learner choices, and
state changes.

### Interludes

Interludes are story scenes between episodes. The authored text usually lives
as FUIOR, while runtime scene controllers live under `corpus/interludes/`.
Compiled progression wrappers also appear under `corpus/main/progression/`.

Examples:

- Authoring layer: `corpus/fuior/chapter1/interlude_c.fui`
- Progression wrapper: `corpus/main/progression/chapter1/interlude_c.lua`
- Scene/runtime layer: `corpus/interludes/interludes.lua`

This is why the repo can appear to have the same scene in multiple places. They
are different layers of the same feature.

### Cutscenes

Cutscenes are more animation-driven scenes, separate from plain FUIOR dialogue.
Their controllers live under `corpus/spine_cutscene/`, with progression entries
such as:

- `corpus/main/progression/chapter1/cutscene1.lua`
- `corpus/main/progression/chapter3/final_cutscene.lua`
- `corpus/main/progression/cutscene_intro.lua`

### Sound

`corpus/sound/` and subsystem `sound.lua` files are Lua hooks and control code.
The actual shipped audio banks are not in `corpus/`; they are FMOD `.bank`
files in the ignored raw app bundle.

## Suggested Reading Order

1. Run `uv run interrogation-unfold inspect`.
2. Read `docs/architecture_atlas.md`.
3. Read `docs/first_case_blueprint.md` for the first language-mystery version
   of the structure.
4. Read the chapter indexes:
   `corpus/main/progression/chapter1/index.lua`,
   `corpus/main/progression/chapter2/index.lua`,
   `corpus/main/progression/chapter3/index.lua`.
5. Read one episode graph, such as `corpus/episodes/episode1.json`.
6. Read the episode interpreter in `corpus/level/store.lua`.
7. Read `corpus/fuior/example.fui`, then one real interlude FUIOR file.
8. Compare that FUIOR file with its progression wrapper under
   `corpus/main/progression/`.
9. Read one cutscene progression file and its controller under
   `corpus/spine_cutscene/`.

## Design Shape To Reuse

For a new game, the reusable shape is not Defold or Lua. It is the layering:

- A progression spine decides what happens next.
- A lesson/episode graph stores interactive content as data.
- A scene scripting format handles authored story scenes.
- Runtime interpreters execute those data formats.
- A campaign shell stores long-term state, pressure, rewards, and consequences.
- Analysis tools index content so the project stays understandable as it grows.
