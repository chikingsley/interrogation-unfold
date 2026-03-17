# Interrogation: You Will Be Deceived — Extracted

Extracted and decompiled source from the Defold game
[Interrogation: You Will Be Deceived](https://interrogation-game.com/)
(Critique Gaming / Mixtvision, Defold 1.2.171).

## Structure

```text
decompiled/         all extracted game content
  episodes/         dialogue tree JSONs (46 files)
  fuior/            narrative scripts — branching story DSL (63 files)
  intl/             localization strings (60 Lua files)
  level/            interrogation gameplay logic
  campaign/         campaign progression, office, missions
  main/             boot, animations, fuior runtime, progression
  interludes/       interlude scene controllers
  ...               479 decompiled Lua source files total

game/               source game files (manifest, config)
tools/              extraction pipeline
  extract.py        archive extractor (arci/arcd → output/)
  decrypt.py        XTEA decryptor + LuaJIT decompiler
```

## Getting the game archives

`game.arcd` and `game.arci` are too large for GitHub.
Copy from the installed app:

```sh
cp /Applications/Interrogation.app/Wrapper/Interrogation.app/game.arcd game/
cp /Applications/Interrogation.app/Wrapper/Interrogation.app/game.arci game/
```

Then re-extract if needed:

```sh
uv run tools/extract.py
uv run tools/decrypt.py
```
