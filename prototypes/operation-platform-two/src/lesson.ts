export type Phase =
  | "briefing"
  | "training"
  | "rehearsal"
  | "deployment"
  | "wiretap"
  | "decision"
  | "debrief";

export type Speaker = "handler" | "courier" | "contact" | "system";
export type CueKind = "narration" | "model" | "prompt" | "wiretap" | "decision";

export interface Cue {
  id: string;
  phase: Phase;
  kind: CueKind;
  speaker: Speaker;
  locale: "en-US" | "fr-FR";
  text: string;
  translation?: string;
  waitSeconds: number;
  plannedSeconds: number;
  animation?: string;
}

interface Phrase {
  french: string;
  english: string;
  prompt: string;
}

const phrases: Phrase[] = [
  { french: "ce soir", english: "tonight", prompt: "Say: tonight." },
  { french: "à la gare", english: "at the station", prompt: "Say: at the station." },
  { french: "à huit heures", english: "at eight o'clock", prompt: "Say: at eight o'clock." },
  { french: "à neuf heures", english: "at nine o'clock", prompt: "Say: at nine o'clock." },
  {
    french: "pas à huit heures",
    english: "not at eight o'clock",
    prompt: "Correct the time. Say: not at eight o'clock.",
  },
  { french: "le quai numéro deux", english: "platform number two", prompt: "Say: platform number two." },
  { french: "le paquet", english: "the package", prompt: "Say: the package." },
  {
    french: "la femme au manteau rouge",
    english: "the woman in the red coat",
    prompt: "Say: the woman in the red coat.",
  },
  { french: "elle a le paquet", english: "she has the package", prompt: "Say: she has the package." },
  {
    french: "le rendez-vous est ce soir",
    english: "the meeting is tonight",
    prompt: "Say: the meeting is tonight.",
  },
];

let cueSequence = 0;

function estimateSpeechSeconds(text: string, locale: Cue["locale"]): number {
  const words = text.trim().split(/\s+/).length;
  const wordsPerSecond = locale === "fr-FR" ? 1.75 : 2.25;
  return Math.max(1.6, words / wordsPerSecond + 0.8);
}

function cue(input: Omit<Cue, "id" | "plannedSeconds">): Cue {
  cueSequence += 1;
  return {
    ...input,
    id: `cue-${String(cueSequence).padStart(3, "0")}`,
    plannedSeconds: estimateSpeechSeconds(input.text, input.locale) + input.waitSeconds,
  };
}

function handler(text: string, phase: Phase = "training", waitSeconds = 0.8): Cue {
  return cue({
    phase,
    kind: "narration",
    speaker: "handler",
    locale: "en-US",
    text,
    waitSeconds,
    animation: "tutor_explain",
  });
}

function model(
  french: string,
  english: string,
  phase: Phase = "training",
  speaker: Speaker = "contact",
): Cue {
  return cue({
    phase,
    kind: phase === "wiretap" ? "wiretap" : "model",
    speaker,
    locale: "fr-FR",
    text: french,
    translation: english,
    waitSeconds: phase === "wiretap" ? 1.2 : 1.1,
    animation: speaker === "contact" ? "diana_interested" : "tutor_secret",
  });
}

function prompt(text: string, phase: Phase = "training", waitSeconds = 5.5): Cue {
  return cue({
    phase,
    kind: "prompt",
    speaker: "handler",
    locale: "en-US",
    text,
    waitSeconds,
    animation: "tutor_idle",
  });
}

function teachPhrase(item: Phrase, index: number): Cue[] {
  const context = index < 5 ? "time and place" : "the handoff";
  return [
    handler(`Now a piece of ${context}. Listen to the French.`),
    model(item.french, item.english),
    handler(`It means “${item.english}.” Listen again.`),
    model(item.french, item.english),
    prompt(item.prompt),
    model(item.french, item.english),
    prompt(`Once more. ${item.prompt}`),
    model(item.french, item.english),
  ];
}

interface Retrieval {
  prompt: string;
  answer: string;
  translation: string;
}

const retrievalRounds: Retrieval[][] = [
  [
    { prompt: "Say: the meeting is tonight.", answer: "le rendez-vous est ce soir", translation: "the meeting is tonight" },
    { prompt: "Where is it? Say: at the station.", answer: "à la gare", translation: "at the station" },
    { prompt: "Give the first time: at eight o'clock.", answer: "à huit heures", translation: "at eight o'clock" },
    { prompt: "Reject it: not at eight o'clock.", answer: "pas à huit heures", translation: "not at eight o'clock" },
    { prompt: "Give the corrected time: at nine o'clock.", answer: "à neuf heures", translation: "at nine o'clock" },
    { prompt: "Name the platform.", answer: "le quai numéro deux", translation: "platform number two" },
    { prompt: "Name the object: the package.", answer: "le paquet", translation: "the package" },
  ],
  [
    { prompt: "Say: tonight.", answer: "ce soir", translation: "tonight" },
    { prompt: "Say: the woman in the red coat.", answer: "la femme au manteau rouge", translation: "the woman in the red coat" },
    { prompt: "Say: she has the package.", answer: "elle a le paquet", translation: "she has the package" },
    { prompt: "Say: at the station, at nine o'clock.", answer: "à la gare, à neuf heures", translation: "at the station, at nine o'clock" },
    { prompt: "Correct me: à huit heures?", answer: "non, pas à huit heures", translation: "no, not at eight o'clock" },
    { prompt: "Then give the right time.", answer: "à neuf heures", translation: "at nine o'clock" },
    { prompt: "Say: platform number two.", answer: "le quai numéro deux", translation: "platform number two" },
  ],
  [
    { prompt: "Where is the meeting?", answer: "à la gare", translation: "at the station" },
    { prompt: "When is it? Say the full sentence.", answer: "le rendez-vous est ce soir", translation: "the meeting is tonight" },
    { prompt: "At eight? Correct the bad intelligence.", answer: "pas à huit heures, à neuf heures", translation: "not at eight, at nine" },
    { prompt: "Which platform?", answer: "le quai numéro deux", translation: "platform number two" },
    { prompt: "Who are we looking for?", answer: "la femme au manteau rouge", translation: "the woman in the red coat" },
    { prompt: "What does she have?", answer: "elle a le paquet", translation: "she has the package" },
    { prompt: "Put the location and time together.", answer: "à la gare, à neuf heures", translation: "at the station, at nine o'clock" },
  ],
  [
    { prompt: "Say the full correction: not at eight, at nine.", answer: "pas à huit heures, à neuf heures", translation: "not at eight, at nine" },
    { prompt: "Say: the meeting is tonight.", answer: "le rendez-vous est ce soir", translation: "the meeting is tonight" },
    { prompt: "Say: the package is at the station.", answer: "le paquet est à la gare", translation: "the package is at the station" },
    { prompt: "Identify the courier.", answer: "la femme au manteau rouge", translation: "the woman in the red coat" },
    { prompt: "Say what she has.", answer: "elle a le paquet", translation: "she has the package" },
    { prompt: "Give the complete intercept: station, nine, platform two.", answer: "à la gare, à neuf heures, le quai numéro deux", translation: "at the station, at nine, platform two" },
    { prompt: "Again, without the English prompt: station, nine, platform two.", answer: "à la gare, à neuf heures, le quai numéro deux", translation: "at the station, at nine, platform two" },
  ],
];

function makeRetrievalRound(round: Retrieval[], roundNumber: number): Cue[] {
  return [
    handler(`Retrieval round ${roundNumber}. Answer before the contact does.`),
    ...round.flatMap((item) => [prompt(item.prompt), model(item.answer, item.translation)]),
    handler("Good. The operation will not give you these English prompts."),
  ];
}

const targetCall: Array<[Speaker, string, string]> = [
  ["courier", "Le rendez-vous est ce soir ?", "The meeting is tonight?"],
  ["contact", "Oui. À la gare.", "Yes. At the station."],
  ["courier", "À huit heures ?", "At eight o'clock?"],
  ["contact", "Non. Pas à huit heures. À neuf heures.", "No. Not at eight. At nine."],
  ["courier", "Quel quai ?", "Which platform?"],
  ["contact", "Le quai numéro deux.", "Platform number two."],
  ["courier", "Et le paquet ?", "And the package?"],
  ["contact", "La femme au manteau rouge a le paquet.", "The woman in the red coat has the package."],
];

const preview = targetCall.map(([speaker, french, english]) =>
  model(french, english, "briefing", speaker),
);

const rehearsal = targetCall.flatMap(([speaker, french, english]) => [
  prompt(`Respond with the next line. ${speaker === "courier" ? "The courier speaks." : "The contact speaks."}`, "rehearsal", 4.5),
  model(french, english, "rehearsal", speaker),
]);

const finalRecall: Retrieval[] = [
  {
    prompt: "Last check. Correct eight o'clock with the actual time.",
    answer: "pas à huit heures, à neuf heures",
    translation: "not at eight, at nine",
  },
  {
    prompt: "Give the location and platform together.",
    answer: "à la gare, le quai numéro deux",
    translation: "at the station, platform number two",
  },
  {
    prompt: "Identify the courier and object together.",
    answer: "la femme au manteau rouge a le paquet",
    translation: "the woman in the red coat has the package",
  },
  {
    prompt: "One complete field report: station, nine, platform two.",
    answer: "à la gare, à neuf heures, le quai numéro deux",
    translation: "at the station, at nine, platform two",
  },
];

const wiretap = targetCall.map(([speaker, french, english]) =>
  model(french, english, "wiretap", speaker),
);

export const lesson: Cue[] = [
  handler("Operation Platform Two. A courier will call a contact before a package handoff.", "briefing"),
  handler("Your job is to identify the place, corrected time, platform, and courier. First, hear the entire call.", "briefing"),
  ...preview,
  handler("You are not expected to understand that yet. We will train exactly the language the operation requires.", "briefing"),
  ...phrases.flatMap(teachPhrase),
  ...retrievalRounds.flatMap((round, index) => makeRetrievalRound(round, index + 1)),
  handler("Controlled rehearsal. You will hear each line once more, with a short retrieval window.", "rehearsal"),
  ...rehearsal,
  handler("Final recall. Build the intelligence in larger chunks.", "rehearsal"),
  ...finalRecall.flatMap((item) => [
    prompt(item.prompt, "rehearsal", 5.5),
    model(item.answer, item.translation, "rehearsal"),
  ]),
  handler("Training complete. English support is going dark.", "deployment"),
  handler("Do not translate every word. Hold four facts: place, corrected time, platform, courier.", "deployment"),
  handler("Live channel open.", "wiretap", 1.5),
  ...wiretap,
  cue({
    phase: "decision",
    kind: "decision",
    speaker: "system",
    locale: "en-US",
    text: "Configure the intercept from the call.",
    waitSeconds: 0,
    animation: "diana_idle_scared",
  }),
  handler("Channel closed. Your field decision has been logged.", "debrief"),
  handler("The correction was the trap: not eight o'clock, but nine o'clock.", "debrief"),
  model("Pas à huit heures. À neuf heures.", "Not at eight. At nine.", "debrief"),
  handler("The full intercept is Gare du Nord, nine o'clock, platform two, the woman in the red coat.", "debrief"),
  handler("Operation complete. Replay any section from the timeline if you want another retrieval pass.", "debrief"),
];

export const plannedDurationSeconds = lesson.reduce(
  (total, item) => total + item.plannedSeconds,
  0,
);

export const plannedSilenceSeconds = lesson.reduce(
  (total, item) => total + item.waitSeconds,
  0,
);

export function phaseLabel(phase: Phase): string {
  return {
    briefing: "01 / Target call",
    training: "02 / Acquisition",
    rehearsal: "03 / Rehearsal",
    deployment: "04 / Deployment",
    wiretap: "05 / Live wiretap",
    decision: "06 / Field decision",
    debrief: "07 / Debrief",
  }[phase];
}
