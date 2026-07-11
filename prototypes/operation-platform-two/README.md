# Operation Platform Two

A private browser prototype combining a Pimsleur-informed full-phrase retrieval
lesson with an authored eavesdropping operation. The user first hears the target
call, explicitly trains the required French, rehearses it, then hears the call
without English and configures a field intercept from the evidence.

## Run

From the repository root, prepare the ignored recovered-asset pack:

```sh
uv run interrogation-unfold prepare-operation-prototype --clean
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
- Browser `speechSynthesis` supplies English and French timing voices. It is not
  a voice-quality approval. French text and final baked audio need native review.
- There is no microphone or pronunciation score. Prompts ask for complete words
  and phrases aloud, then play a model.
- The operation is deterministic. The final input is a field decision derived
  from French evidence, not a translation multiple-choice question.
- Playback restarts the current cue after pause. Every cue transition invalidates
  the preceding run token, preventing stale audio/timers from advancing state.

The methodology audit is in
[`analysis/pimsleur_2002_prototype_audit.md`](../../analysis/pimsleur_2002_prototype_audit.md).
