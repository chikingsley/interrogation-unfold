# Raw Source Material

`raw/metadata/` is tracked and contains small source metadata from the app:

- `game.dmanifest`
- `game.projectc`

`raw/archives/` is ignored. Put `game.arci` and `game.arcd` there when rerunning
the extraction commands:

```sh
uv run interrogation-unfold extract
uv run interrogation-unfold decrypt
```

`raw/app/` is ignored. It can hold a local copy of `Interrogation.app` for
reference or re-copying archives, but it should not be committed.
