import { useEffect, useMemo, useRef, useState, type CSSProperties } from "react";

import {
  beatMode,
  lesson,
  phaseLabel,
  phaseOrder,
  type Beat,
  type Evidence,
  type Phase,
} from "./lesson.ts";

interface AnimationAsset {
  frames: string[];
  fps: number;
}

interface AssetManifest {
  animations: Record<string, AnimationAsset>;
  scene: Record<string, string>;
}

interface AudioAsset {
  path: string;
  speaker: string;
  seconds: number;
}

type AudioManifest = Record<string, AudioAsset>;

interface Dispatch {
  hour: number;
  platform: number;
}

function wait(milliseconds: number): Promise<void> {
  return new Promise((resolve) => window.setTimeout(resolve, milliseconds));
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

function EvidenceBoard({ evidence, hidden }: { evidence: Evidence; hidden: boolean }) {
  if (hidden || evidence === "live" || evidence === "decision") return null;
  return (
    <div className={`evidence-board evidence-${evidence}`}>
      <div className="evidence-tab">OP–01 / SOURCE FILE</div>
      {evidence === "file-eight" && (
        <div className="clock-reading"><small>RECORDED HANDOFF</small><strong>20:00</strong></div>
      )}
      {evidence === "correction" && (
        <div className="correction-reading">
          <span><small>OLD</small><s>20:00</s></span>
          <i>→</i>
          <span><small>REVISED</small><strong>21:00</strong></span>
        </div>
      )}
      {evidence === "platform" && (
        <div className="platform-reading"><small>HANDOFF PLATFORM</small><strong>02</strong></div>
      )}
    </div>
  );
}

function ResponseSignal({ beat, active }: { beat: Beat; active: boolean }) {
  const style = { "--response-ms": `${beat.responseMs ?? 4000}ms` } as CSSProperties;
  return (
    <div className={`response-signal ${active ? "active" : ""}`} style={style}>
      <div className="record-core"><i /></div>
      <strong>YOUR LINE</strong>
      <span>Speak before Diana returns</span>
      <div className="response-track"><i key={`${beat.id}-${active}`} /></div>
    </div>
  );
}

function DispatchPanel({ onSubmit }: { onSubmit: (dispatch: Dispatch) => void }) {
  const [hour, setHour] = useState(20);
  const [platform, setPlatform] = useState(1);

  return (
    <div className="dispatch-layer">
      <div className="dispatch-sheet">
        <div className="dispatch-heading"><span>FIELD TEAM / HOLDING</span><strong>SET INTERCEPT</strong></div>
        <div className="dispatch-controls">
          <label>
            <span>TEAM CLOCK</span>
            <output>{String(hour).padStart(2, "0")}:00</output>
            <input type="range" min="20" max="22" step="1" value={hour} onChange={(event) => setHour(Number(event.target.value))} />
            <i className="range-labels"><b>20</b><b>21</b><b>22</b></i>
          </label>
          <label>
            <span>RAIL PLATFORM</span>
            <output>0{platform}</output>
            <input type="range" min="1" max="3" step="1" value={platform} onChange={(event) => setPlatform(Number(event.target.value))} />
            <i className="range-labels"><b>01</b><b>02</b><b>03</b></i>
          </label>
        </div>
        <button className="dispatch-button" onClick={() => onSubmit({ hour, platform })}>DISPATCH TEAM</button>
      </div>
    </div>
  );
}

function Outcome({ dispatch, onReplay, onRetry }: { dispatch: Dispatch; onReplay: () => void; onRetry: () => void }) {
  const correct = dispatch.hour === 21 && dispatch.platform === 2;
  return (
    <div className={`outcome-layer ${correct ? "success" : "failure"}`}>
      <div className="outcome-card">
        <span>{correct ? "INTERCEPT CONFIRMED" : "HANDOFF MISSED"}</span>
        <strong>{correct ? "PACKAGE SECURED" : `${String(dispatch.hour).padStart(2, "0")}:00 / PLATFORM 0${dispatch.platform}`}</strong>
        <p>{correct ? "The spoken correction changed the field plan." : "The team moved on the wrong intelligence."}</p>
        <div><button onClick={onReplay}>REPLAY LIVE CALL</button><button onClick={onRetry}>RESET DISPATCH</button></div>
      </div>
    </div>
  );
}

function MissingPayload({ kind, detail }: { kind: "assets" | "audio"; detail: string }) {
  const command = kind === "assets"
    ? "~/.local/bin/uv run interrogation-unfold prepare-operation-prototype --clean"
    : "~/.local/bin/uv run --script tools/bake_operation_audio.py";
  return (
    <main className="missing-payload">
      <p>PRIVATE {kind.toUpperCase()} PAYLOAD MISSING</p>
      <h1>Prepare the local operation.</h1>
      <code>{command}</code>
      <small>{detail}</small>
    </main>
  );
}

export default function App() {
  const [manifest, setManifest] = useState<AssetManifest | null>(null);
  const [audioManifest, setAudioManifest] = useState<AudioManifest | null>(null);
  const [payloadError, setPayloadError] = useState<{ kind: "assets" | "audio"; detail: string } | null>(null);
  const [beatIndex, setBeatIndex] = useState(() => {
    const requestedBeat = new URLSearchParams(window.location.search).get("beat");
    const requestedIndex = lesson.findIndex((item) => item.id === requestedBeat);
    return requestedIndex >= 0 ? requestedIndex : 0;
  });
  const [playing, setPlaying] = useState(false);
  const [speed, setSpeed] = useState(1);
  const [dispatch, setDispatch] = useState<Dispatch | null>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const runToken = useRef(0);

  const beat = lesson[beatIndex];
  const progress = (beatIndex + 1) / lesson.length;
  const liveStart = useMemo(() => lesson.findIndex((item) => item.phase === "wiretap" && item.speaker === "courier"), []);

  useEffect(() => {
    Promise.all([
      fetch("./private-assets/manifest.json").then((response) => {
        if (!response.ok) throw new Error(`assets:${response.status}`);
        return response.json() as Promise<AssetManifest>;
      }),
      fetch("./private-audio/manifest.json").then((response) => {
        if (!response.ok) throw new Error(`audio:${response.status}`);
        return response.json() as Promise<AudioManifest>;
      }),
    ])
      .then(([assets, audio]) => {
        setManifest(assets);
        setAudioManifest(audio);
      })
      .catch((error: unknown) => {
        const detail = error instanceof Error ? error.message : String(error);
        setPayloadError({ kind: detail.startsWith("assets:") ? "assets" : "audio", detail });
      });
  }, []);

  useEffect(() => {
    if (!playing || !beat || beat.kind === "decision" || dispatch) {
      if (beat?.kind === "decision") setPlaying(false);
      return;
    }

    const token = runToken.current + 1;
    runToken.current = token;
    let cancelled = false;

    async function runBeat() {
      if (beat.kind === "response") {
        await wait((beat.responseMs ?? 4000) / speed);
      } else if (beat.audioId) {
        const source = audioManifest?.[beat.audioId]?.path ?? `./private-audio/${beat.audioId}.wav`;
        const audio = new Audio(source);
        audioRef.current = audio;
        audio.playbackRate = speed;
        await new Promise<void>((resolve) => {
          audio.onended = () => resolve();
          audio.onerror = () => {
            setPayloadError({ kind: "audio", detail: `Could not play ${source}` });
            resolve();
          };
          void audio.play().catch(() => resolve());
        });
        await wait((beat.postMs ?? 0) / speed);
      }
      if (cancelled || runToken.current !== token) return;
      if (beatIndex < lesson.length - 1) setBeatIndex((index) => index + 1);
      else setPlaying(false);
    }

    void runBeat();
    return () => {
      cancelled = true;
      runToken.current += 1;
      if (audioRef.current) {
        audioRef.current.pause();
        audioRef.current.currentTime = 0;
      }
    };
  }, [audioManifest, beat, beatIndex, dispatch, playing, speed]);

  function jumpTo(index: number, shouldPlay = false) {
    setDispatch(null);
    setBeatIndex(Math.max(0, Math.min(index, lesson.length - 1)));
    setPlaying(shouldPlay);
  }

  function jumpToPhase(phase: Phase) {
    const index = lesson.findIndex((item) => item.phase === phase);
    if (index >= 0) jumpTo(index);
  }

  if (payloadError) return <MissingPayload kind={payloadError.kind} detail={payloadError.detail} />;
  if (!manifest || !audioManifest || !beat) return <div className="loading">Opening secure channel…</div>;

  const isResponse = beat.kind === "response";
  const handlerVisible = beat.shot === "handler";
  const courierVisible = beat.shot === "courier" || beat.shot === "player-contact" || beat.shot === "two-shot";
  const contactVisible = beat.shot === "contact" || beat.shot === "two-shot";
  const courierAnimation = beat.speaker === "courier" ? "alex_idle" : "alex_smile";
  const contactAnimation = beat.speaker === "contact" ? "diana_interested" : "diana_idle_blink";

  return (
    <main className={`app phase-${beat.phase} shot-${beat.shot}`}>
      <header className="topbar">
        <div className="brand"><span>DM</span><strong>DARK MALLARD <small>FIELD LANGUAGE DIVISION</small></strong></div>
        <div className="operation-title">OP–01 / PLATFORM TWO</div>
        <div className={`channel ${beat.phase === "wiretap" ? "live" : ""}`}><i />{beat.phase === "wiretap" ? "LIVE CHANNEL" : "SECURE"}</div>
      </header>

      <section className="workspace">
        <nav className="phase-rail" aria-label="Operation phases">
          {phaseOrder.map((phase) => (
            <button key={phase} className={phase === beat.phase ? "active" : ""} onClick={() => jumpToPhase(phase)}>
              <span>{phaseLabel(phase).split(" / ")[0]}</span>{phaseLabel(phase).split(" / ")[1]}
            </button>
          ))}
        </nav>

        <div className="stage-shell">
          <div className="stage" style={{ backgroundImage: `url(${manifest.scene.background})` }}>
            <div className="scanlines" />
            <div className={`mode-tag ${isResponse ? "response" : ""}`}><i />{beatMode(beat)}</div>
            <img className="chair" src={manifest.scene.chair} alt="" />

            {handlerVisible && <AnimatedSprite animation={beat.speaker === "handler" ? "tutor_explain" : "tutor_idle_blink"} manifest={manifest} className="handler-sprite" />}
            {courierVisible && <AnimatedSprite animation={courierAnimation} manifest={manifest} className="courier-sprite" />}
            {contactVisible && <AnimatedSprite animation={contactAnimation} manifest={manifest} className="contact-sprite" />}
            {isResponse && <ResponseSignal beat={beat} active={playing} />}

            {courierVisible && <div className="nameplate courier-name"><b>ALEX</b><span>COURIER</span></div>}
            {contactVisible && <div className="nameplate contact-name"><b>DIANA</b><span>CONTACT</span></div>}

            <EvidenceBoard evidence={beat.evidence} hidden={isResponse} />
            {beat.phase === "wiretap" && <div className="wire-signal">{Array.from({ length: 43 }, (_, index) => <i key={index} style={{ "--bar": `${18 + (index * 41) % 76}%` } as CSSProperties} />)}</div>}

            <img className="table" src={manifest.scene.table} alt="" />
            <img className={`recorder ${playing ? "is-playing" : ""}`} src={playing ? manifest.scene.recorderPlaying : manifest.scene.recorderPaused} alt="" />

            {beat.kind === "decision" && !dispatch && <DispatchPanel onSubmit={setDispatch} />}
            {dispatch && <Outcome dispatch={dispatch} onReplay={() => jumpTo(liveStart, true)} onRetry={() => setDispatch(null)} />}
          </div>

          <div className="transport">
            <button className="round" onClick={() => jumpTo(beatIndex - 1)} aria-label="Previous beat">‹</button>
            <button className="play" onClick={() => setPlaying((value) => !value)}>{playing ? "PAUSE" : beatIndex === 0 ? "BEGIN OPERATION" : "CONTINUE"}</button>
            <button className="round" onClick={() => jumpTo(beatIndex + 1)} aria-label="Next beat">›</button>
            <div className="timeline">
              <i><b style={{ width: `${progress * 100}%` }} /></i>
              <span>BEAT {String(beatIndex + 1).padStart(2, "0")} / {lesson.length}</span>
            </div>
            <label>PACE <select value={speed} onChange={(event) => setSpeed(Number(event.target.value))}><option value="1">1×</option><option value="1.2">1.2×</option><option value="1.4">1.4×</option></select></label>
          </div>
        </div>

        <aside className="intel-panel">
          <p>RETRIEVAL CHAIN</p>
          <h2>One line. Three jobs.</h2>
          <ol>
            <li className={["acquisition", "briefing"].includes(beat.phase) ? "active" : ""}><span>01</span><div><b>BUILD</b><small>Meaning is anchored to the changing clock.</small></div></li>
            <li className={["retrieval", "rehearsal"].includes(beat.phase) ? "active" : ""}><span>02</span><div><b>PRODUCE</b><small>You take the missing character's turn.</small></div></li>
            <li className={["wiretap", "decision"].includes(beat.phase) ? "active" : ""}><span>03</span><div><b>ACT</b><small>The same line changes the field plan.</small></div></li>
          </ol>
          <div className="rule"><i />NO TRANSCRIPT<br /><i />NO TRANSLATION CHOICES<br /><i />DISTINCT SPEAKERS</div>
        </aside>
      </section>
    </main>
  );
}
