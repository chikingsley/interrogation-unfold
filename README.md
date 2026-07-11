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

For the conceptual reading path, start with
[`docs/learning_map.md`](docs/learning_map.md).

For the first concrete language-mystery direction, read
[`docs/first_case_blueprint.md`](docs/first_case_blueprint.md).
