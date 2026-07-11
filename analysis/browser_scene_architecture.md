# Browser Scene Architecture

The private academy benchmark currently uses React, ordinary DOM layers, CSS
transitions/keyframes, and a small PNG frame player. The characters are not 3D.
They are transparent full-body image frames with stable canvas anchors, swapped
at the FPS declared by the Defold atlas or Lua runtime sequence.

## What the Original Runtime Separates

The recovered game is useful because it separates five concerns that should
remain separate in a new browser implementation:

1. **Content graph:** episode JSON and FUIOR decide dialogue, conditions,
   effects, and requested animation names.
2. **Scene state:** the runtime decides which mode is active, which character is
   focused, whether the recorder is running, and which interaction is legal.
3. **Presentation mapping:** a character manifest maps a semantic or source
   state name to frame paths, FPS, playback, anchor, and optional offsets.
4. **Cue sequencing:** fades, object movement, audio, frame changes, and input
   gates run as cancellable cues attached to a scene transition.
5. **Rendering:** DOM/CSS, Canvas/Pixi, or a native renderer draws the same state
   and manifests.

This is the portable concept. React Native would need a different renderer and
animation adapter, but it can share the content graph, reducer, cue definitions,
asset manifests, and audio IDs.

## The Case File Can Be Reproduced More Exactly

The current browser benchmark approximates the folder opening with one open
folder image and a CSS 3D transform. The readable source exposes the original
mechanism:

- `corpus/level/casefile/casefile.lua` declares eleven visual states:
  `casefile1`, `2`, `3`, `5`, `7`, `9`, `10`, `11`, `12`, `14`, and `16`.
- `corpus/lib/full_screen_panel.lua` advances that sequence at 15 FPS.
- Frame one is the closed table object; frame two is the hover state; the
  remaining frames open toward the full-screen dossier.
- Position and scale interpolate from the table anchor to the screen center.
- The case-file-specific easing is `1 - (t - 1)^4`, an ease-out quart.
- The background opacity rises with opening progress, and the active hitbox
  changes after the hover frames.

That can be implemented directly with the recovered eleven PNG states and one
small cue runner. Motion or GSAP is not required for parity. An animation
library can make cancellation and sequencing more convenient, but it does not
provide missing source behavior.

## Recommended Browser Stack

Keep React and DOM/CSS for this product while scenes remain text-heavy,
responsive, and composed of a modest number of layered images. CSS is sufficient
for persistent effects such as highlight pulses, blinking prompts, opacity,
simple transforms, and hover feedback.

If the browser pilot needs a library for interrupted enter/exit sequences,
adopt Motion narrowly around scene transitions and the case-file panel. Its
scoped animation controls and automatic cleanup match React component lifetimes.
Do not migrate the sprite-frame player or persistent CSS effects merely to use a
library.

GSAP becomes worthwhile only if authored scenes grow into long, scrubbable
cutscene timelines with labels, overlapping tracks, reverse playback, and
playhead control. The current academy and language-operation scenes do not need
that power.

PixiJS is the later renderer option if scenes become graphics-heavy: many
sprites, particles, masks, blend modes, camera movement, or continuous 60 FPS
updates. Moving to Canvas now would make text layout, accessibility, responsive
controls, and ordinary interface work more complicated without solving the
current problems.

## Fix State Before Adding Animation Dependencies

The academy benchmark currently schedules several transitions with independent
`setTimeout` calls. A stale timeout can fire after the player has already moved
to another answer or tutorial gate. That is the likely source of click/answer
state glitches; an animation package does not make stale game state safe.

The next browser-runtime pass should use:

```text
SceneDefinition (data)
        |
SceneReducer (single authoritative state transition)
        |
CueRunner (cancellable animation/audio/input sequence)
        |
StageRenderer + AudioBus + AnimatedSprite
```

Every player action should dispatch one event. The reducer should produce the
new canonical state and a cue list. The cue runner should own cancellation via
an `AbortController` or transition token so cues from an old scene cannot alter
the current scene. Input gates should derive from canonical state rather than
from timers.

This gives the project a small reusable scene runtime without pretending to
create a general-purpose React game engine.
