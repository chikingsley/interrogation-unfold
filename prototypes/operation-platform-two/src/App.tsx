import { useEffect, useMemo, useRef, useState, type CSSProperties } from "react";

import {
  lesson,
  phaseLabel,
  plannedDurationSeconds,
  type Cue,
  type Phase,
} from "./lesson.ts";

interface AnimationAsset {
  frames: string[];
  fps: number;
  width: number;
  height: number;
}

interface AssetManifest {
  notice: string;
  animations: Record<string, AnimationAsset>;
  scene: Record<string, string>;
  caseFile: string[];
}

interface Intercept {
  place: string;
  time: string;
  platform: string;
  target: string;
}

const emptyIntercept: Intercept = { place: "", time: "", platform: "", target: "" };
const solution: Intercept = {
  place: "Gare du Nord",
  time: "21:00",
  platform: "2",
  target: "Red coat",
};

const phaseOrder: Phase[] = [
  "briefing",
  "training",
  "rehearsal",
  "deployment",
  "wiretap",
  "decision",
  "debrief",
];

function formatTime(seconds: number): string {
  const rounded = Math.round(seconds);
  return `${Math.floor(rounded / 60)}:${String(rounded % 60).padStart(2, "0")}`;
}

function wait(milliseconds: number): Promise<void> {
  return new Promise((resolve) => window.setTimeout(resolve, milliseconds));
}

function speak(cue: Cue, speed: number): Promise<void> {
  if (!("speechSynthesis" in window) || !("SpeechSynthesisUtterance" in window)) {
    return wait((cue.plannedSeconds - cue.waitSeconds) * 1000 / speed);
  }

  return new Promise((resolve) => {
    const utterance = new SpeechSynthesisUtterance(cue.text);
    const voices = window.speechSynthesis.getVoices();
    const exactVoice = voices.find((voice) => voice.lang === cue.locale);
    const languageVoice = voices.find((voice) => voice.lang.startsWith(cue.locale.slice(0, 2)));
    utterance.voice = exactVoice ?? languageVoice ?? null;
    utterance.lang = cue.locale;
    utterance.rate = Math.min(1.45, speed * (cue.locale === "fr-FR" ? 0.88 : 0.96));
    utterance.pitch = cue.speaker === "courier" ? 0.82 : 1;
    utterance.onend = () => resolve();
    utterance.onerror = () => resolve();
    window.speechSynthesis.speak(utterance);
  });
}

function AnimatedSprite({
  animation,
  manifest,
  className,
}: {
  animation: string;
  manifest: AssetManifest;
  className: string;
}) {
  const asset = manifest.animations[animation];
  const [frame, setFrame] = useState(0);

  useEffect(() => {
    setFrame(0);
    if (!asset || asset.frames.length < 2) return;
    const timer = window.setInterval(
      () => setFrame((value) => (value + 1) % asset.frames.length),
      1000 / asset.fps,
    );
    return () => window.clearInterval(timer);
  }, [animation, asset]);

  if (!asset) return null;
  return <img className={className} src={asset.frames[frame]} alt="" draggable={false} />;
}

function CaseFile({ manifest, open }: { manifest: AssetManifest; open: boolean }) {
  const [frame, setFrame] = useState(0);

  useEffect(() => {
    if (!open) {
      setFrame(0);
      return;
    }
    let nextFrame = 0;
    const timer = window.setInterval(() => {
      nextFrame += 1;
      setFrame(Math.min(nextFrame, manifest.caseFile.length - 1));
      if (nextFrame >= manifest.caseFile.length - 1) window.clearInterval(timer);
    }, 67);
    return () => window.clearInterval(timer);
  }, [manifest, open]);

  const rawProgress = open ? frame / Math.max(1, manifest.caseFile.length - 1) : 0;
  const easedProgress = 1 - (rawProgress - 1) ** 4;
  const caseFileStyle = {
    width: `${18 + 74 * easedProgress}%`,
    left: `${23 + 27 * easedProgress}%`,
    bottom: `${7 + 43 * easedProgress}%`,
    transform: `translate(-${50 * easedProgress}%, ${50 * easedProgress}%)`,
  } as CSSProperties;

  return (
    <img
      className={`case-file ${open ? "is-open" : ""}`}
      src={manifest.caseFile[frame]}
      alt="Operation dossier"
      draggable={false}
      style={caseFileStyle}
    />
  );
}

function DecisionPanel({
  manifest,
  onSubmit,
}: {
  manifest: AssetManifest;
  onSubmit: (intercept: Intercept) => void;
}) {
  const [intercept, setIntercept] = useState(emptyIntercept);
  const ready = Object.values(intercept).every(Boolean);

  function select(field: keyof Intercept, value: string) {
    setIntercept((current) => ({ ...current, [field]: value }));
  }

  return (
    <div className="decision-layer">
      <CaseFile manifest={manifest} open />
      <div className="decision-sheet">
        <div className="dossier-heading">
          <span>FIELD AUTHORIZATION / 02</span>
          <strong>CONFIGURE INTERCEPT</strong>
        </div>
        <div className="decision-grid">
          <Choice label="Place" value={intercept.place} options={["Gare du Nord", "Hotel bar", "Airport"]} onChange={(value) => select("place", value)} />
          <Choice label="Time" value={intercept.time} options={["20:00", "21:00", "22:00"]} onChange={(value) => select("time", value)} />
          <Choice label="Platform" value={intercept.platform} options={["1", "2", "3"]} onChange={(value) => select("platform", value)} />
          <Choice label="Courier" value={intercept.target} options={["Black hat", "Red coat", "Blue scarf"]} onChange={(value) => select("target", value)} />
        </div>
        <button className="authorize" disabled={!ready} onClick={() => onSubmit(intercept)}>
          Authorize team
        </button>
      </div>
    </div>
  );
}

function Choice({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string;
  options: string[];
  onChange: (value: string) => void;
}) {
  return (
    <label className="choice">
      <span>{label}</span>
      <select value={value} onChange={(event) => onChange(event.target.value)}>
        <option value="">Select</option>
        {options.map((option) => (
          <option key={option}>{option}</option>
        ))}
      </select>
    </label>
  );
}

function MissingAssets({ error }: { error: string }) {
  return (
    <main className="missing-assets">
      <p className="eyebrow">Private asset pack missing</p>
      <h1>Prepare the recovered scene payload.</h1>
      <code>uv run interrogation-unfold prepare-operation-prototype --clean</code>
      <p>{error}</p>
    </main>
  );
}

export default function App() {
  const [manifest, setManifest] = useState<AssetManifest | null>(null);
  const [assetError, setAssetError] = useState("");
  const [cueIndex, setCueIndex] = useState(0);
  const [playing, setPlaying] = useState(false);
  const [speed, setSpeed] = useState(1);
  const [interceptResult, setInterceptResult] = useState<Intercept | null>(null);
  const runToken = useRef(0);

  const currentCue = lesson[cueIndex];
  const elapsed = useMemo(
    () => lesson.slice(0, cueIndex).reduce((total, cue) => total + cue.plannedSeconds, 0),
    [cueIndex],
  );
  const progress = elapsed / plannedDurationSeconds;

  useEffect(() => {
    fetch("./private-assets/manifest.json")
      .then((response) => {
        if (!response.ok) throw new Error(`Asset manifest returned ${response.status}`);
        return response.json() as Promise<AssetManifest>;
      })
      .then(setManifest)
      .catch((error: unknown) => setAssetError(error instanceof Error ? error.message : String(error)));
  }, []);

  useEffect(() => {
    if (!playing || !currentCue || currentCue.kind === "decision") {
      if (currentCue?.kind === "decision") setPlaying(false);
      return;
    }

    const token = runToken.current + 1;
    runToken.current = token;
    let cancelled = false;

    async function runCue() {
      await speak(currentCue, speed);
      await wait(currentCue.waitSeconds * 1000 / speed);
      if (cancelled || runToken.current !== token) return;
      if (cueIndex < lesson.length - 1) setCueIndex((index) => index + 1);
      else setPlaying(false);
    }

    void runCue();
    return () => {
      cancelled = true;
      runToken.current += 1;
      window.speechSynthesis?.cancel();
    };
  }, [cueIndex, currentCue, playing, speed]);

  function jumpTo(index: number, shouldPlay = false) {
    window.speechSynthesis?.cancel();
    setCueIndex(Math.max(0, Math.min(index, lesson.length - 1)));
    setPlaying(shouldPlay);
  }

  function jumpToPhase(phase: Phase) {
    const index = lesson.findIndex((cue) => cue.phase === phase);
    if (index >= 0) jumpTo(index);
  }

  function submitIntercept(intercept: Intercept) {
    setInterceptResult(intercept);
    jumpTo(cueIndex + 1, true);
  }

  if (assetError) return <MissingAssets error={assetError} />;
  if (!manifest || !currentCue) return <div className="loading">Opening secure channel…</div>;

  const isWiretap = currentCue.phase === "wiretap";
  const isDecision = currentCue.phase === "decision";
  const handlerVisible = !isWiretap && !isDecision;
  const contactVisible = isWiretap || currentCue.speaker === "contact" || currentCue.speaker === "courier";
  const animation = currentCue.animation ?? "tutor_idle";
  const resultCorrect = interceptResult
    ? Object.entries(solution).every(([key, value]) => interceptResult[key as keyof Intercept] === value)
    : null;
  const responseStyle = { "--response-seconds": `${currentCue.waitSeconds / speed}s` } as CSSProperties;

  return (
    <main className={`app phase-${currentCue.phase}`}>
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark">DM</span>
          <div><strong>DARK MALLARD</strong><small>Field language division</small></div>
        </div>
        <div className="operation-title"><span>OP–01</span> PLATFORM TWO</div>
        <div className={`channel ${isWiretap ? "live" : ""}`}><i /> {isWiretap ? "LIVE CHANNEL" : "SECURE"}</div>
      </header>

      <section className="workspace">
        <nav className="phase-rail" aria-label="Operation phases">
          {phaseOrder.map((phase) => (
            <button key={phase} className={phase === currentCue.phase ? "active" : ""} onClick={() => jumpToPhase(phase)}>
              <span>{phaseLabel(phase).split(" / ")[0]}</span>
              {phaseLabel(phase).split(" / ")[1]}
            </button>
          ))}
        </nav>

        <div className="stage-shell">
          <div className="stage" style={{ backgroundImage: `url(${manifest.scene.background})` }}>
            <div className="scanlines" />
            <img className="chair" src={manifest.scene.chair} alt="" />
            {handlerVisible && (
              <AnimatedSprite
                animation={animation.startsWith("tutor") ? animation : "tutor_idle_blink"}
                manifest={manifest}
                className="handler-sprite"
              />
            )}
            {contactVisible && (
              <AnimatedSprite
                animation={animation.startsWith("diana") ? animation : isWiretap ? "diana_idle_blink" : "diana_interested"}
                manifest={manifest}
                className={`contact-sprite ${isWiretap ? "wiretap-contact" : ""}`}
              />
            )}
            <img className="table" src={manifest.scene.table} alt="" />
            <img className={`recorder ${playing ? "is-playing" : ""}`} src={playing ? manifest.scene.recorderPlaying : manifest.scene.recorderPaused} alt="" />

            {!isDecision && (
              <div className={`speech-card ${isWiretap ? "wiretap-card" : ""} kind-${currentCue.kind}`}>
                <div className="speaker-label">
                  <span>{currentCue.speaker === "handler" ? "SHELDON / HANDLER" : currentCue.speaker.toUpperCase()}</span>
                  <b>{phaseLabel(currentCue.phase)}</b>
                </div>
                <p lang={currentCue.locale.slice(0, 2)}>{currentCue.text}</p>
                {currentCue.translation && !isWiretap && <small>{currentCue.translation}</small>}
                {currentCue.kind === "prompt" && playing && (
                  <div className="response-window" style={responseStyle}><i /></div>
                )}
              </div>
            )}

            {isWiretap && (
              <div className="signal-strip">
                {Array.from({ length: 31 }, (_, index) => <i key={index} style={{ "--bar": `${20 + (index * 37) % 78}%` } as CSSProperties} />)}
              </div>
            )}

            {isDecision && <DecisionPanel manifest={manifest} onSubmit={submitIntercept} />}

            {currentCue.phase === "debrief" && interceptResult && (
              <div className={`result-stamp ${resultCorrect ? "correct" : "wrong"}`}>
                {resultCorrect ? "INTERCEPT SUCCESS" : "TEAM MISDIRECTED"}
              </div>
            )}
          </div>

          <div className="transport">
            <button className="round" onClick={() => jumpTo(cueIndex - 1)} aria-label="Previous cue">‹</button>
            <button className="play" onClick={() => setPlaying((value) => !value)}>{playing ? "PAUSE" : cueIndex === 0 ? "BEGIN OPERATION" : "CONTINUE"}</button>
            <button className="round" onClick={() => jumpTo(cueIndex + 1)} aria-label="Next cue">›</button>
            <div className="timeline">
              <button className="timeline-track" onClick={(event) => jumpTo(Math.round((event.nativeEvent.offsetX / event.currentTarget.clientWidth) * (lesson.length - 1)))} aria-label="Operation timeline">
                <i style={{ width: `${progress * 100}%` }} />
              </button>
              <div><span>{formatTime(elapsed)} / {formatTime(plannedDurationSeconds)}</span><span>CUE {cueIndex + 1} / {lesson.length}</span></div>
            </div>
            <label className="speed">PACE<select value={speed} onChange={(event) => setSpeed(Number(event.target.value))}><option value={1}>1×</option><option value={1.35}>1.35×</option><option value={1.75}>1.75×</option></select></label>
          </div>
        </div>

        <aside className="intel-panel">
          <p className="eyebrow">Mission memory</p>
          <h2>Hold four facts.</h2>
          <div className="fact-grid">
            <div><span>01</span><strong>PLACE</strong><small>Where?</small></div>
            <div><span>02</span><strong>TIME</strong><small>Correction?</small></div>
            <div><span>03</span><strong>PLATFORM</strong><small>Which one?</small></div>
            <div><span>04</span><strong>COURIER</strong><small>Who?</small></div>
          </div>
          <div className="protocol"><span>TRAINING PROTOCOL</span><p>Listen. Retrieve aloud. Hear the model. Recur in a new context. Then act without English.</p></div>
          <div className="tts-note">LOCAL VOICE<br /><span>Browser TTS is a timing stand-in. French requires native review.</span></div>
        </aside>
      </section>
    </main>
  );
}
