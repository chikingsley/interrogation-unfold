# Retrieval Slice Contract

This slice tests a narrow question: can a learned spoken line survive long
enough to change a game state?

## Target exchange

The source file says the handoff is at 20:00. The actual call contains this
correction:

- Courier: `À huit heures ?`
- Contact: `Non. Pas à huit heures. À neuf heures.`
- Courier: `Quel quai ?`
- Contact: `Le quai numéro deux.`

The player is trained for the contact's role. The final operation has no
transcript and asks the player to change the field team from 20:00/platform 1
to 21:00/platform 2.

## Retrieval chain

1. **Semantic anchor:** hear the exchange while a non-language evidence board
   crosses out 20:00 and records 21:00.
2. **Component production:** produce `Non. Pas à huit heures`, then `À neuf
   heures`, with the contact modeling each answer after the response window.
3. **Turn completion:** hear the courier ask `À huit heures ?`, take the empty
   contact position, and produce the complete correction before Diana returns.
4. **Interleaving:** learn and retrieve `Le quai numéro deux` so the correction
   is no longer the immediately preceding item.
5. **Delayed scene retrieval:** complete both contact turns in order after the
   courier supplies the conversational cues.
6. **Operational retrieval:** listen to an uninterrupted two-speaker call, then
   manipulate the team's clock and platform. The package is secured only when
   the heard correction changes both pieces of world state.

The production windows are intentionally unscored. They test recall and model
comparison without pretending that browser speech recognition is a reliable
pronunciation judge. The field action is scored, but it scores comprehension
and retained meaning rather than a translation choice.

## Runtime invariants

- The runtime renders no lesson script and stores no translation field.
- English exists only in handler audio, where it establishes the communicative
  problem in the same role as an audio-course prompt.
- Alex is always the courier and Diana is always the contact; neither character
  becomes a translucent stand-in for the other.
- A response beat leaves Diana's position empty and shows only a timed recording
  signal. The following model beat brings Diana back.
- Audio is pre-generated. Browser `speechSynthesis` is not a fallback.
- Repeated lines reuse the same WAV and therefore the same voice performance.
- The live call and the dispatch are separate phases: first listen, then act.

## Content/state boundary

`src/operation.json` is the authored beat graph. Each audio beat owns an
`audioId`, speaker, hidden bake script, shot, and evidence state. Response beats
own only a role and response duration. The offline Python baker reads the hidden
scripts; the React UI never reads or displays them.

This is a technical slice, not yet the requested 20–25 minute episode. A longer
episode should add new communicative problems and delayed recurrences around
this same state contract rather than multiplying isolated translation prompts.
