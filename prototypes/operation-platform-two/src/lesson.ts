import operation from "./operation.json";

export type Phase =
  | "briefing"
  | "acquisition"
  | "retrieval"
  | "rehearsal"
  | "wiretap"
  | "decision";

export type Speaker = "handler" | "courier" | "contact" | "player" | "system";
export type Shot = "handler" | "courier" | "contact" | "player-contact" | "two-shot" | "evidence";
export type Evidence = "file-eight" | "correction" | "platform" | "live" | "decision";

export interface Beat {
  id: string;
  phase: Phase;
  kind: "audio" | "response" | "decision";
  speaker: Speaker;
  shot: Shot;
  evidence: Evidence;
  audioId?: string;
  script?: string;
  postMs?: number;
  responseMs?: number;
}

export const lesson = operation.beats as Beat[];

export const phaseOrder: Phase[] = [
  "briefing",
  "acquisition",
  "retrieval",
  "rehearsal",
  "wiretap",
  "decision",
];

export function phaseLabel(phase: Phase): string {
  return {
    briefing: "01 / Hear the problem",
    acquisition: "02 / Build the line",
    retrieval: "03 / Take her turn",
    rehearsal: "04 / Complete the scene",
    wiretap: "05 / Live call",
    decision: "06 / Move the team",
  }[phase];
}

export function beatMode(beat: Beat): string {
  if (beat.kind === "response") return "YOUR LINE";
  if (beat.kind === "decision") return "FIELD ACTION";
  if (beat.speaker === "handler") return "HANDLER";
  if (beat.phase === "wiretap") return "LIVE CHANNEL";
  return beat.speaker === "contact" ? "MODEL" : "LISTEN";
}
