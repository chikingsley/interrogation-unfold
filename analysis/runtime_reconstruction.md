# Runtime Reconstruction Notes

This note records the concrete source and payload evidence used by the local
Concierge Call reconstruction. It is not a claim that the original game has
been rebuilt or relicensed.

## Exact Runtime

- The shipped executable identifies Defold `1.2.171`.
- `game.projectc` identifies game version `1.1.9.dc9529f2`.
- The extracted payload contains 3,236 files and occupies about 3.5 GB.
- The useful visual families are compiled `.texturec` images paired with
  `.texturesetc` atlas metadata, plus `.spritec`, `.collectionc`, and GUI
  resources.

## What the Game Actually Does

The interrogation loop is a deterministic data interpreter, not a freeform
conversation system:

1. an episode JSON declares subjects, question pages, answers, conditions,
   effects, stats, flags, animation names, and navigation
2. `corpus/level/store.lua` evaluates conditions and applies effects
3. `corpus/level/questions.lua` exposes the currently valid questions
4. `corpus/level/level.lua` and `controller.lua` coordinate the room, subject,
   meters, dialogue, input, and scene transitions
5. character animation names in episode data select atlas frame ranges
6. FUIOR scripts use the same pattern for cinematic dialogue, choices, flags,
   approval changes, character slots, and interlude transitions

Episode 0 contains one subject, 15 questions, and 30 answers. The tutorial actor
atlas contains 12 named sequences; the broader character library contains
idle, blink, fear, empathy, disgust, smile, nod, headshake, shrug, defense, and
other reactions.

## Visual Recovery

The original iOS texture payload is neither missing nor a set of ordinary image
files. For example:

- `actor.texturec` is a 4096 x 2048 luminance-alpha sheet with 159 frame entries
- `diana.texturec` is a 4096 x 2048 luminance-alpha sheet
- `level.texturec` is a 2048 x 2048 RGBA sheet containing the 1920 x 1200 room,
  table, chair, lamp, meters, recorder, question bubble, prompts, and overlays

The paired texture-set protobuf stores animation start/end indices, playback,
FPS, dimensions, and eight UV floats per frame. Defold UVs use a bottom-left
origin, so recovered PNGs require a vertical flip before atlas crops are
calculated.

The `recover-texture` CLI now performs this process and writes a manifest plus
numbered frames. The local React scene uses five real Diana sequences and room
layers. Copyrighted outputs stay ignored.

## Audio Recovery

The app uses FMOD banks containing embedded FSB5 archives. Episode 0's bank has
one 151.5-second music stream named `tutorial_p`; it does not contain dialogue.
The shared `All Levels` bank has 58 streams including:

- `roomnoise`
- `cue_ask_question`
- `bring_them_in`
- `tape_start` and `tape_stop`
- `casefile_open_full` and `casefile_close_full`
- chair, door, recorder, hover, button, timer, breath, and physical-reaction
  cues

The local scene uses the Episode 0 score, room noise, and five interaction cues.
The original game does not provide a voice-performance pipeline to reuse.

## Voice Boundary

Original scene reconstruction needs no TTS because there is no original speech
to reproduce. New French content does need speech authoring. The current local
pipeline is script freeze, native review, offline TTS bake, independent ASR
check, human performance review, normalization, stable node-ID filenames, and
preloaded playback. Runtime TTS is intentionally out of scope.
