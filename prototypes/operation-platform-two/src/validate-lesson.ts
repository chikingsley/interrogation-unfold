import { lesson } from "./lesson.ts";

const errors: string[] = [];
const duplicateIds = lesson.map((beat) => beat.id).filter((id, index, ids) => ids.indexOf(id) !== index);
const responseCount = lesson.filter((beat) => beat.kind === "response").length;
const liveSpeakers = new Set(lesson.filter((beat) => beat.phase === "wiretap").map((beat) => beat.speaker));

if (duplicateIds.length > 0) errors.push(`duplicate beat ids: ${duplicateIds.join(", ")}`);
if (responseCount < 6) errors.push(`expected at least six production windows, found ${responseCount}`);
if (!liveSpeakers.has("courier") || !liveSpeakers.has("contact")) errors.push("live call must contain two distinct speakers");
if (lesson.some((beat) => beat.kind === "audio" && (!beat.audioId || !beat.script))) errors.push("every audio beat needs a baked audio id and private bake script");
if (lesson.filter((beat) => beat.kind === "decision").length !== 1) errors.push("operation needs exactly one field decision");
if (lesson.some((beat) => "translation" in beat)) errors.push("runtime content must not contain translations");

if (errors.length > 0) throw new Error(errors.join("\n"));

console.log(`${lesson.length} beats, ${responseCount} spoken retrieval windows, two-speaker live call`);
