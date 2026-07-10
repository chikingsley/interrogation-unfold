# First Case Blueprint

This is the first concrete direction for an Interrogation-inspired language
mystery. It uses the recovered Interrogation structure as a production model,
but it keeps the first playable level small enough to build.

## What Interrogation Actually Needed

The shipped game is much larger than the readable `corpus/` folder suggests.
The extracted Defold archive contains 3,759 resources. The main production
categories are:

- GUI screens: `.guic`, `.gui_scriptc`, labels, buttons, dialogue boxes.
- Scene objects: `.collectionc`, `.goc`, factories, collection factories.
- Visual assets: `.texturec`, `.texturesetc`, `.spritec`.
- Character/cutscene animation: Spine models, skeletons, mesh sets, animation
  sets, particle effects.
- Scripts: encrypted and decompiled Lua.
- Narrative data: episode JSON and FUIOR interlude scripts.
- Audio: FMOD banks in the app bundle, grouped by menu, campaign, cutscene, and
  level.

The pattern worth copying is the layering, not the amount of production:

- A progression file decides the order of scenes.
- A data file describes interactive content.
- A runtime interpreter executes the data.
- GUI systems show dialogue, choices, hints, and evidence.
- Character systems swap/fade/focus sprites and animations.
- Audio systems load banks, play ambience/music/SFX, and react to game state.

## Interrogation Systems To Borrow

### Episode Room

The interrogation level combines:

- a room/background
- subject portraits/avatars
- question and answer UI
- timers/meters
- casefile/evidence panels
- audio ambience, music, UI sounds, and state-based reactions

For this project, the equivalent is a case room or evidence desk where the
player studies language evidence and makes deductions.

### Interlude Scene

Interludes use slots, character show/hide/focus messages, speech bubbles, and
choices. Characters can fade in, dim when unfocused, flip, and swap animation
states.

For this project, the first version only needs:

- show/hide a character portrait
- focus/dim the active speaker
- change expression
- show a speech bubble or subtitle panel
- show 2-4 choices

### Cutscene Layer

Interrogation uses Spine-driven cutscenes with event-triggered animations and
SFX. This is too much for the first version.

For this project, the equivalent should be light:

- still background
- evidence close-up
- short crossfade
- waveform or recorder animation
- optional character blink/expression swap

## Language Scope From Pimsleur French I

The early French material is useful because it gives a strict beginner ceiling.
The first case should only require functions like:

- greeting someone politely
- asking whether someone understands
- saying that someone understands or does not understand
- identifying French versus English
- saying "a little"
- identifying whether someone is American
- using basic forms of address
- asking/answering basic wellbeing

The point is not to copy the Pimsleur lesson. The point is to use its constraint:
the player has almost no French, so the case must be solvable through a tiny set
of repeated, meaningful phrases.

## First Level Concept

Working title: **Case 01: The Concierge Tape**

The player is reviewing a short lobby recording connected to a missing American
tenant in a French apartment building. The case is not solved by translating a
wall of text. It is solved by determining who understood whom.

Core mystery:

- The concierge claims she did not understand the American tenant.
- The recording suggests she understood enough to ask a follow-up question.
- The tenant understood a little French, but not enough to catch everything.
- The player must decide whether the concierge is confused, mistaken, or lying.

The language is the fog over the case.

## First Five Minutes

1. **Case Desk**
   The player sees a file, a cassette/recorder, a photo of the missing tenant,
   and a building-lobby still.

2. **First Playback**
   A short exchange plays. The player can replay individual lines. Unknown
   words are not fully translated at first; they are tagged as possible meanings.

3. **Meaning Tags**
   The player assigns simple tags:
   `understands French`, `does not understand English`, `American`, `a little`,
   `polite address`.

4. **Contradiction**
   The witness statement says the concierge did not understand the tenant.
   The audio contains a clue that complicates that claim.

5. **Choice**
   The player chooses the next interview angle:
   ask about language ability, ask about the tenant's nationality, or ask about
   why she used a specific form of address.

6. **Forward Motion**
   A correct deduction unlocks the second evidence item. A weak deduction does
   not hard-fail; it costs time and produces a less helpful response.

## Required First-Level Assets

Keep this intentionally small.

### Backgrounds

- case desk / evidence table
- apartment lobby still
- audio recorder close-up

### Characters

- concierge portrait: neutral, guarded, irritated
- missing tenant photo: one static image
- case handler portrait or voice-only presence

### Evidence UI

- audio tape / waveform player
- witness statement card
- case board with 4-6 slots
- word/phrase tag chips
- final deduction panel

### Audio

- lobby ambience
- tape hiss / recorder controls
- short voiced evidence lines
- UI sounds for tag placement, replay, contradiction found

Use generated or placeholder voices for the prototype. Treat human voice acting
as a later production upgrade.

### Animation

Do not build a full animation system first. The minimum useful animation set is:

- fade scene in/out
- dim unfocused character
- expression swap
- audio waveform pulse
- evidence card slide/zoom
- contradiction highlight

This matches the spirit of Interrogation's show/hide/focus/animate systems
without requiring Spine or a large art pipeline.

## First Content File Shape

A case file should be data-driven from the start:

```yaml
id: case_01_concierge_tape
language: fr
level: a1
scenes:
  - id: desk_intro
    background: case_desk
    evidence:
      - lobby_tape
      - concierge_statement
  - id: tape_review
    evidence_player: lobby_tape
    utterances:
      - id: line_001
        speaker: tenant
        audio: case_01/line_001.mp3
        tags: [polite_opening]
      - id: line_002
        speaker: concierge
        audio: case_01/line_002.mp3
        tags: [does_not_understand_english]
choices:
  - id: ask_language_ability
    requires: [does_not_understand_english]
    effect: unlock_followup_interview
  - id: accuse_immediately
    effect: lose_time
```

The content format should separate:

- what the player hears/sees
- what tags can be inferred
- which deductions require which tags
- what evidence unlocks next
- what language items should be reviewed later

## What To Build First

Build a vertical slice with one case and one loop:

1. Load a case YAML/JSON file.
2. Show a desk scene with evidence cards.
3. Play short audio lines.
4. Let the player tag meanings.
5. Let the player place tags on a case board.
6. Unlock a follow-up scene based on the tags.
7. Record which words/phrases were tapped or missed.

No live microphone. No runtime TTS. No full RPG map. No cutscenes. The first
prototype should prove that language comprehension can move an investigation
forward.

## Why This Feels Like A Thing

This is not a quiz in disguise. The player is not asked, "What does this word
mean?" The player is asked, "What happened here?" The answer depends on
understanding small pieces of French.

That gives the language a job:

- It reveals trust.
- It exposes contradictions.
- It changes which questions are available.
- It changes how much time is lost.
- It creates a reason to replay audio carefully.

That is the bridge between Interrogation and a language-learning game.
