import { lesson, plannedDurationSeconds, plannedSilenceSeconds } from "./lesson.ts";

const errors: string[] = [];
const minutes = plannedDurationSeconds / 60;
const silenceShare = plannedSilenceSeconds / plannedDurationSeconds;

if (minutes < 20 || minutes > 25) {
  errors.push(`planned duration ${minutes.toFixed(1)} minutes is outside 20–25 minutes`);
}

if (silenceShare < 0.33 || silenceShare > 0.42) {
  errors.push(`planned silence share ${(silenceShare * 100).toFixed(1)}% is outside 33–42%`);
}

if (lesson.filter((cue) => cue.phase === "wiretap").some((cue) => !cue.text)) {
  errors.push("wiretap contains an empty line");
}

const duplicateIds = lesson
  .map((cue) => cue.id)
  .filter((id, index, ids) => ids.indexOf(id) !== index);
if (duplicateIds.length > 0) {
  errors.push(`duplicate cue ids: ${duplicateIds.join(", ")}`);
}

if (errors.length > 0) {
  throw new Error(errors.join("\n"));
}

console.log(
  `${lesson.length} cues, ${minutes.toFixed(1)} planned minutes, ` +
    `${(silenceShare * 100).toFixed(1)}% planned silence`,
);
