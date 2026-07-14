# Operation Platform Two

A private browser slice testing one exact language-to-action loop. The user
learns a spoken time correction, retrieves it by taking a missing character's
turn, completes the exchange after a delay, then hears the line inside a live
call and changes the field team's clock and platform.

## Run

From the repository root, prepare the ignored recovered-asset pack:

```sh
uv run interrogation-unfold prepare-operation-prototype --clean
```

Bake the ignored three-speaker OmniVoice payload. The script loads the model
once, creates a persistent handler and courier reference, reuses the existing
OmniVoice contact reference, and voice-clones every operation line:

```sh
uv run --script tools/bake_operation_audio.py
```

Then run the Vite app:

```sh
cd prototypes/operation-platform-two
bun install
bun run validate:lesson
bun run dev
```

The dev server binds to `0.0.0.0` so it can be opened from another Tailscale
device using this machine's Tailscale address and the port Vite prints.

## Current boundaries

- Recovered *Interrogation* images are private visual stand-ins and are ignored
  by Git. Do not publish them.
- All spoken audio is baked with OmniVoice. The English handler, French courier,
  and French contact each have a separate persistent reference voice.
- Neither French transcripts nor English translations are rendered. The scripts
  in `src/operation.json` exist only as the offline TTS source and authoring record.
- There is no microphone or pronunciation score. Prompts ask for complete words
  and phrases aloud, then play a model.
- The operation is deterministic. The final input changes the team's clock and
  platform; it is not a translation multiple-choice question.
- Playback restarts the current beat after pause. Every beat transition invalidates
  the preceding run token, preventing stale audio/timers from advancing state.

The methodology audit is in
[`analysis/pimsleur_2002_prototype_audit.md`](../../analysis/pimsleur_2002_prototype_audit.md).
The implemented retrieval contract is in
[`analysis/retrieval_slice_contract.md`](../../analysis/retrieval_slice_contract.md).
