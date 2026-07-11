# Interrogation: You Will Be Deceived - Extracted Corpus

Readable extracted corpus and analysis tooling for the Defold game
[Interrogation: You Will Be Deceived](https://interrogation-game.com/)
(Critique Gaming / Mixtvision, Defold 1.2.171).

## Structure

```text
corpus/             readable corpus kept for analysis
  episodes/         dialogue tree JSONs (46 files)
  fuior/            narrative scripts — branching story DSL (63 files)
  intl/             localization strings (59 Lua files)
  level/            interrogation gameplay logic
  campaign/         campaign progression, office, missions
  main/             boot, animations, fuior runtime, progression
  interludes/       interlude scene controllers
  ...               538 Lua files total

raw/
  metadata/         tracked source metadata (manifest, config)
  archives/         ignored local archive files (game.arci, game.arcd)
  app/              ignored local app bundle, if kept here
generated/          ignored extraction/decryption/decompilation outputs
analysis/           notes, indexes, and reports
src/
  interrogation_unfold/
                    Python package and CLI for extraction/analysis

docs/
  architecture_atlas.md  map of the game architecture and content systems
  learning_map.md        reading guide and glossary for the recovered corpus
  first_case_blueprint.md
                    first language-mystery level concept
```

## Getting the game archives

`game.arcd` and `game.arci` are too large for GitHub. Copy them from the
installed app into ignored `raw/archives/`:

```sh
mkdir -p raw/archives
cp /Applications/Interrogation.app/Wrapper/Interrogation.app/game.arcd raw/archives/
cp /Applications/Interrogation.app/Wrapper/Interrogation.app/game.arci raw/archives/
```

Then re-extract if needed:

```sh
uv run interrogation-unfold extract
uv run interrogation-unfold decrypt
```

`interrogation-unfold decrypt` writes LuaJIT bytecode intermediates to ignored
`generated/decrypted-bytecode/`. Readable Lua in `corpus/` came from a separate
LuaJIT decompiler step.

To inspect the currently checked-in readable corpus:

```sh
uv run interrogation-unfold inspect
```

To export the shipped Episode 0 academy tutorial as resolved JSON for the
private browser benchmark in the sibling `episodic` repository:

```sh
uv run interrogation-unfold export-tutorial \
  ../episodic/planning/planning-v4/prototypes/benchmarks/interrogation-tutorial/public/interrogation-local/tutorial.json
```

The export combines the original 15-question/30-answer episode graph with all
27 instructor lines and an explicit ten-gate trace of
`main/progression/chapter1/tutorial.lua`. The generated JSON contains original
dialogue and must remain in the benchmark's ignored local-payload directory.

## Recovering Visual Frames

The iOS payload stores sprite sheets as Defold 1.2.171 protobuf resources. The
tooling can decode the raw RGBA or luminance-alpha texture, correct the OpenGL
vertical orientation, read atlas UVs, and crop named animation frames:

```sh
uv run interrogation-unfold recover-texture \
  generated/extracted/episodes/characters/diana/diana.texturec \
  generated/extracted/episodes/characters/diana/diana.texturesetc \
  generated/recovered/diana \
  --animation diana_idle \
  --animation diana_disgust
```

`ffmpeg` is required. Recovered PNGs remain under ignored `generated/`; do not
commit or publish the game's copyrighted visual payload.

## Building the Local Asset Library

The single-atlas recovery command is also available as a batch Python workflow:

```sh
uv run interrogation-unfold build-asset-library --scope all --clean
```

It writes an ignored, artist-friendly library to `generated/asset-library/`:

```text
generated/asset-library/
  index.html                 self-contained searchable animation gallery
  catalog.json               atlas metadata plus episode/FUIOR source usage
  characters/
    alex/interrogation/
      alex_idle/000.png ...
      alex_angry/000.png ...
    alex/character.json       portable per-character runtime manifest
    jen/interlude/
      jen_normal/000.png
      jen_normal_angry/000.png
    helene/interrogation/logical/
      helene_idle/000.png ...
  assets/                    room, UI, case files, outcomes, and cutscenes
```

The current local payload resolves 173 of 175 atlas descriptions into 2,008
named clips and 6,077 PNG frames. The character portion contains 727 atlas
clips and 4,734 frames. Another 64 logical character sequences are reconstructed
from the readable Lua animation tables into 731 ordered, hard-linked PNG paths.
Two one-frame final-cutscene support atlases reference texture payloads that are
not present in the shipped extraction; the catalog marks them explicitly rather
than silently dropping them.

Every catalog animation retains its Defold width, height, FPS, playback mode,
and source paths. Usage records connect animation names to episode answer IDs,
torture reactions, animation effects, and FUIOR scene commands. Open
`generated/asset-library/index.html` directly in a browser to search and play
the recovered sequences. Each character's smaller `character.json` is the
renderer-neutral contract for future React, Pixi, or native experiments; those
consumers do not need to parse Defold resources.

The benchmark's `build-private-payload.sh` remains a thin orchestration layer:
it calls this repository's Python CLI for data and texture recovery, then uses
`vgmstream`/`ffmpeg` for the app-specific FMOD audio extraction. Reusable
archive, atlas, catalog, and usage-index logic belongs in the Python package.

## Operation Platform Two

[`prototypes/operation-platform-two/`](prototypes/operation-platform-two/) is a
complete first pass at the combined learning-and-application loop. Its authored
20-minute operation contains 198 autoplay cues with a 38% planned-silence
envelope:

1. hear a target French call with support;
2. explicitly train and retrieve ten complete phrases;
3. rehearse the call in mixed order;
4. hear the live call without English; and
5. configure a station intercept from the evidence.

Prepare its small ignored visual payload from the generated library, then run
the Vite app:

```sh
uv run interrogation-unfold prepare-operation-prototype --clean
cd prototypes/operation-platform-two
bun install
bun run validate:lesson
bun run dev
```

The prepared payload is 19 MB locally, selects nine tutor/contact animations
and all eleven case-file opening states, and hard-links recovered frames when
the filesystem permits it. It must remain private and uncommitted. The app uses
browser speech synthesis as a timing stand-in; a native French reviewer must
approve the script and any final baked voice.

The evidence and constraints behind the lesson are recorded in
[`analysis/pimsleur_2002_prototype_audit.md`](analysis/pimsleur_2002_prototype_audit.md).
The browser scene/runtime split is documented in
[`analysis/browser_scene_architecture.md`](analysis/browser_scene_architecture.md).

For the conceptual reading path, start with
[`docs/learning_map.md`](docs/learning_map.md).

For the first concrete language-mystery direction, read
[`docs/first_case_blueprint.md`](docs/first_case_blueprint.md).
