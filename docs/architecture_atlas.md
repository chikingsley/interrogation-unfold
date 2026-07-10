# Interrogation Architecture Atlas

This repo is best understood as a readable corpus extracted from a shipped Defold game. It is not the original authoring project. The checked-in `corpus/` directory mixes several kinds of readable artifacts: decompiled Lua runtime code, extracted narrative DSL files, interrogation JSON graphs, and localization tables.

## How It Was Produced

The earlier work recovered the local app archive, extracted the Defold archive, decrypted encrypted scripts with Defold's static XTEA key, and decompiled readable Lua where possible.

The useful current corpus is:

- `corpus/**/*.lua`: readable Lua runtime and game logic.
- `corpus/fuior/**/*.fui`: authored narrative/interlude scripts.
- `corpus/episodes/*.json`: interrogation conversation graphs.
- `corpus/intl/*.en.lua`: English string tables used by episodes, FUIOR, campaign UI, outcomes, and menus.

The local app bundle under `raw/app/` is raw source material, not curated corpus. It should stay ignored unless a deliberate provenance/archive workflow is added.

## Main Runtime Flow

The shipped game is message-driven and scene-based.

1. `corpus/main/boot.lua` loads resources and creates the main collection.
2. `corpus/main/main.lua` initializes platform behavior, localization, cursor handling, hot reload, Discord presence, and achievements.
3. `corpus/crit/progression.lua` runs coroutine-style progression functions and resumes them from dispatched messages.
4. `corpus/main/progression/main.lua` chooses the active progression: splash, menu, campaign, single-level debug, tests, FUIOR preview, or loss/demo flows.
5. `corpus/main/progression/scenes.lua` dispatches scene loads and waits for `show_<scene>` messages.
6. `corpus/main/scene_loader/scene_loader.lua` handles collection proxy load/init/enable/unload and transition timing.

The pattern worth copying is not Defold-specific: keep a small progression spine that loads scenes and waits for scene-complete messages, instead of scattering navigation across UI components.

## Story Spine

Campaign flow is organized as nested segments.

- `corpus/main/progression/campaign.lua` owns profile load/rewind/debug save behavior.
- `corpus/campaign/snapshot.lua` saves and restores campaign state modules.
- `corpus/main/progression/campaign_main.lua` enters difficulty selection and the chapter sequence.
- `corpus/main/progression/chapter1/index.lua`, `chapter2/index.lua`, and `chapter3/index.lua` are the playable table of contents.

Chapter indexes chain tutorial, episodes, outcomes, interludes, press releases, campaign phases, interviews, triggered consequence scenes, minigames, and cutscenes. For a new game, these files are the clearest model for a high-level story roadmap.

## Interrogation Episodes

`corpus/episodes/*.json` contains the interrogation graph data. A typical episode has:

- `level_id`: episode identifier.
- `intl_namespace`: string table namespace, such as `level_episode1`.
- `subjects`: suspects/witnesses with avatars, meters, question pages, fake answers, triggered questions, and animation maps.
- `questions`: prompt nodes with visible answers, conditions, effects, and repeated-use effects.
- `answers`: player choices with NPC reactions, animations, conditions, and effects.
- `hints`: conditional hints.
- `common_texts`: shared text references used inside the graph.

`corpus/level/store.lua` is the interpreter for this data. It resolves table references, evaluates visibility conditions, executes answer effects, tracks subject state, switches pages, applies torture effects, records history, and translates text keys.

Important decoded numeric types:

- Conditions: `32` at least, `33` at most, `34` equal, `36` more than, `37` less than, `6` flag set, `7` flag not set, `8` OR, `11` AND, `31` as subject, `35` ternary.
- Effects: `17` increment stat, `3` set flag, `8` unset flag, `4` win, `7` lose, `12` navigate, `16` replace page, `13` fire event, `14` play animation, `15` set idle, `11` conditional effect.
- Stats: `0` empathy, `1` fear, `2` health, `3` insanity, `4` cruelty, `6` times asked, `7` times answered, `8` torture damage, `9` popularity, `10` press, `11` authorities.

For a language-learning game, this maps cleanly to conversation nodes, learner-visible prompts, possible spoken responses, NPC reactions, mastery gates, review flags, and remediation branches.

## FUIOR Interludes

`corpus/fuior/**/*.fui` is the easiest authoring layer to read. It is a small narrative DSL for scene setup, character placement, dialogue, choices, conditions, variables, stat changes, waits, and animations.

Example files:

- `corpus/fuior/example.fui`: tutorial for the DSL.
- `corpus/fuior/chapter1/interlude_c.fui`: nested choices with relationship effects.
- `corpus/fuior/triggered_torture_e1.fui`: conditional consequence scene.
- `corpus/fuior/chapter2/hannigan1.fui`: multi-step choice exclusion.

The runtime bridge is `corpus/main/fuior/runtime.lua`, and the compiled Lua form of an FUIOR script can be seen in files like `corpus/main/progression/chapter1/interlude_c.lua`.

For a language-learning game, this is the right model for authored lesson scenes: setup, scripted dialogue, learner choices, variables, rapport changes, and transitions.

## Campaign Shell

The campaign layer wraps episodes with management pressure.

- `corpus/campaign/stats.lua`: campaign approval/stat meters.
- `corpus/campaign/agents.lua`: team members and approval.
- `corpus/campaign/missions.lua`: assigned missions and completion state.
- `corpus/campaign/perks.lua`: player-selected modifiers.
- `corpus/campaign/variables.lua`: story flags.
- `corpus/campaign/budget.lua`: campaign resource budget.
- `corpus/campaign/office/**`: office hub UI and inspectable objects.
- `corpus/campaign/briefing_room/**`: mission selection/briefing UI.

This is the reusable idea: put the conversation game inside a larger loop that creates pressure, consequences, and reasons to replay or revisit earlier decisions.

## Current Layout

The repo now separates raw source material, generated intermediates, checked-in readable corpus, analysis, docs, and packaged tooling:

```text
raw/                    source app/archive material; most of it is ignored
corpus/                 checked-in readable corpus
generated/              ignored full extraction/decryption/decompilation outputs
analysis/               generated indexes and human notes
docs/                   curated architecture/provenance docs
src/interrogation_unfold/
                        reusable extraction and corpus-inspection tooling
```

The normal entry point for the Python tooling is:

```sh
uv run interrogation-unfold inspect
```
