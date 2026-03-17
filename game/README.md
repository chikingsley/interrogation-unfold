# Game Archive Files

`game.arcd` and `game.arci` are not in the repo (too large for GitHub).

## How to get them

```sh
cp /Applications/Interrogation.app/Wrapper/Interrogation.app/game.arcd game/
cp /Applications/Interrogation.app/Wrapper/Interrogation.app/game.arci game/
```

Then run the extraction/decryption tools:

```sh
uv run tools/extract.py    # extracts all assets to output/
uv run tools/decrypt.py    # decrypts scripts to decompiled/
```
