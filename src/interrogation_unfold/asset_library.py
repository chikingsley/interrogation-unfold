# ruff: noqa: E501
"""Build a browsable library from the extracted Defold texture payload."""

from __future__ import annotations

import json
import os
import re
import shutil
from collections import defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, cast

from interrogation_unfold.defold_texture import parse_texture_set, recover_animations
from interrogation_unfold.paths import CORPUS, EXTRACTED_OUTPUT_DIR, GENERATED_DIR

DEFAULT_OUTPUT_DIR = GENERATED_DIR / "asset-library"
ASSET_LIBRARY_SCHEMA_VERSION = 1
HASH_RE = re.compile(r'local\s+(h_[A-Za-z0-9_]+)\s*=\s*hash\("([^"]+)"\)')
SEQUENCE_RE = re.compile(
    r"\[(h_[A-Za-z0-9_]+)\]\s*=\s*\{\s*"
    r"fps\s*=\s*([0-9.]+)\s*,\s*frames\s*=\s*\{(.*?)\}\s*\}",
    re.DOTALL,
)
OFFSET_RE = re.compile(
    r"\[(h_[A-Za-z0-9_]+)\]\s*=\s*\{\s*offset\s*=\s*"
    r"vmath\.vector3\(([-0-9.]+),\s*([-0-9.]+),\s*([-0-9.]+)\)\s*\}",
    re.DOTALL,
)
SYMBOL_RE = re.compile(r"\bh_[A-Za-z0-9_]+\b")
FUIOR_ANIMATE_RE = re.compile(r"^\s*animate\s+(\S+)\s+(\S+)")
FUIOR_SHOW_RE = re.compile(r"^\s*show_character\s+(\S+)\s+\S+\s+(\S+)")
FUIOR_DIALOGUE_RE = re.compile(r"^\s*([A-Za-z0-9_]+):\s*\[([^\]]+)\]")
MIN_CHARACTER_PATH_PARTS = 4
PLAY_ANIMATION_EFFECT = 14


@dataclass(frozen=True)
class AtlasDescriptor:
    """One compiled texture set and its artist-facing library location."""

    identifier: str
    texturesetc: Path
    texturec: Path | None
    output: Path
    category: str
    context: str
    character: str | None
    sheet: str


@dataclass(frozen=True)
class Usage:
    """One source-level reference to a named visual state."""

    kind: str
    source: str
    line: int | None = None
    detail: str = ""


def _texture_path(texturesetc: Path, extracted_dir: Path) -> Path | None:
    texture_set = parse_texture_set(texturesetc)
    candidates = [texturesetc.with_suffix(".texturec")]
    if texture_set.texture:
        candidates.append(extracted_dir / texture_set.texture.lstrip("/"))
    return next((candidate for candidate in candidates if candidate.is_file()), None)


def _descriptor(texturesetc: Path, extracted_dir: Path, output_dir: Path) -> AtlasDescriptor:
    relative = texturesetc.relative_to(extracted_dir)
    stem = texturesetc.stem
    parts = relative.parts
    character: str | None = None
    context = parts[0]
    category = "asset"

    if len(parts) >= MIN_CHARACTER_PATH_PARTS and parts[:2] == ("episodes", "characters"):
        category = "character"
        context = "interrogation"
        character = parts[2]
    elif len(parts) >= MIN_CHARACTER_PATH_PARTS and parts[:2] == ("interludes", "characters"):
        category = "character"
        context = "interlude"
        character = parts[2]

    if character is None:
        output = output_dir / "assets" / relative.with_suffix("")
    else:
        output = output_dir / "characters" / character / context
        if stem != character:
            output /= stem

    return AtlasDescriptor(
        identifier=relative.with_suffix("").as_posix(),
        texturesetc=texturesetc,
        texturec=_texture_path(texturesetc, extracted_dir),
        output=output,
        category=category,
        context=context,
        character=character,
        sheet=stem,
    )


def discover_atlases(
    extracted_dir: Path = EXTRACTED_OUTPUT_DIR,
    output_dir: Path = DEFAULT_OUTPUT_DIR,
    *,
    scope: str = "all",
) -> list[AtlasDescriptor]:
    """Discover recoverable atlas resources and map them into stable folders."""
    descriptors = [
        _descriptor(path, extracted_dir, output_dir)
        for path in sorted(extracted_dir.rglob("*.texturesetc"))
    ]
    if scope == "characters":
        return [descriptor for descriptor in descriptors if descriptor.category == "character"]
    if scope != "all":
        raise ValueError(f"Unknown asset-library scope: {scope}")
    return descriptors


def parse_lua_sequences(path: Path, corpus_dir: Path = CORPUS) -> list[dict[str, Any]]:
    """Recover logical frame sequences assembled by the shipped Lua runtime."""
    text = path.read_text(encoding="utf-8")
    symbols = dict(HASH_RE.findall(text))
    offsets = {
        symbols[symbol]: [float(x), float(y), float(z)]
        for symbol, x, y, z in OFFSET_RE.findall(text)
        if symbol in symbols
    }
    sequences: list[dict[str, Any]] = []
    relative = path.relative_to(corpus_dir)
    parts = relative.parts
    context = "interrogation" if parts[0] == "episodes" else "interlude"
    character = parts[2]

    for symbol, raw_fps, frame_block in SEQUENCE_RE.findall(text):
        name = symbols.get(symbol)
        if name is None:
            continue
        frames = [symbols[item] for item in SYMBOL_RE.findall(frame_block) if item in symbols]
        if not frames:
            continue
        sequences.append(
            {
                "name": name,
                "fps": float(raw_fps),
                "frames": frames,
                "offsets": [offsets.get(frame, [0.0, 0.0, 0.0]) for frame in frames],
                "character": character,
                "context": context,
                "source": relative.as_posix(),
            }
        )
    return sequences


def discover_lua_sequences(corpus_dir: Path = CORPUS) -> list[dict[str, Any]]:
    """Find runtime-composed character sequences in readable Lua sources."""
    roots = [corpus_dir / "episodes" / "characters", corpus_dir / "interludes" / "characters"]
    sequences: list[dict[str, Any]] = []
    for root in roots:
        for path in sorted(root.rglob("*.lua")):
            sequences.extend(parse_lua_sequences(path, corpus_dir))
    return sequences


def _usage_dict(usages: dict[str, list[Usage]]) -> dict[str, list[dict[str, Any]]]:
    return {name: [asdict(usage) for usage in values] for name, values in usages.items()}


def _find_play_animation_effects(
    value: Any,
    source: str,
    usages: dict[str, list[Usage]],
    location: str = "root",
) -> None:
    if isinstance(value, dict):
        effect_value = value.get("value")
        if value.get("type") == PLAY_ANIMATION_EFFECT and isinstance(effect_value, dict):
            animation = effect_value.get("animation")
            if animation:
                companion = bool(effect_value.get("companion"))
                detail = f"{location}; companion={companion}"
                usages[str(animation)].append(Usage("play-animation-effect", source, detail=detail))
        for key, child in value.items():
            _find_play_animation_effects(child, source, usages, f"{location}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            _find_play_animation_effects(child, source, usages, f"{location}[{index}]")


def episode_usages(corpus_dir: Path = CORPUS) -> dict[str, list[Usage]]:
    """Index animation selections embedded in episode subjects, answers, and effects."""
    usages: dict[str, list[Usage]] = defaultdict(list)
    for path in sorted((corpus_dir / "episodes").glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        source = path.relative_to(corpus_dir).as_posix()
        subjects = data.get("subjects", [])
        animation_owners: dict[str, list[str]] = defaultdict(list)
        for subject in subjects:
            owner = str(subject.get("avatar") or subject.get("name") or "unknown")
            subject_animations = subject.get("animations", {})
            if not isinstance(subject_animations, dict):
                subject_animations = {}
            for logical_name, asset_name in subject_animations.items():
                animation_owners[str(asset_name)].append(owner)
                usages[str(asset_name)].append(
                    Usage("subject-map", source, detail=f"{owner}: {logical_name}")
                )
            for index, reaction in enumerate(subject.get("torture_reactions", [])):
                name = reaction.get("animation")
                if name:
                    usages[str(name)].append(
                        Usage(
                            "torture-reaction",
                            source,
                            detail=f"{owner} reaction {index + 1}: {reaction.get('reaction', '')}",
                        )
                    )

        for answer in data.get("answers", []):
            name = answer.get("animation")
            if name:
                owners = ", ".join(animation_owners.get(str(name), [])) or "active subject"
                detail = (
                    f"answer {answer.get('id')} for {owners}; "
                    f"text={answer.get('text', '')}; reaction={answer.get('reaction', '')}"
                )
                usages[str(name)].append(Usage("answer", source, detail=detail))

        _find_play_animation_effects(data, source, usages)
    return usages


def fuior_usages(corpus_dir: Path = CORPUS) -> dict[str, list[Usage]]:
    """Index named poses used by FUIOR story scenes."""
    usages: dict[str, list[Usage]] = defaultdict(list)
    for path in sorted((corpus_dir / "fuior").rglob("*.fui")):
        source = path.relative_to(corpus_dir).as_posix()
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            stripped = line.split("#", 1)[0].rstrip()
            match = FUIOR_ANIMATE_RE.match(stripped)
            kind = "fuior-animate"
            if match is None:
                match = FUIOR_SHOW_RE.match(stripped)
                kind = "fuior-show"
            if match is None:
                match = FUIOR_DIALOGUE_RE.match(stripped)
                kind = "fuior-dialogue"
            if match is None:
                continue
            character, pose = match.groups()
            name = pose if pose.startswith(f"{character}_") else f"{character}_{pose}"
            usages[name].append(Usage(kind, source, line_number, stripped.strip()))
    return usages


def build_usage_index(corpus_dir: Path = CORPUS) -> dict[str, list[dict[str, Any]]]:
    """Merge interrogation-graph and story-scene animation references."""
    merged: dict[str, list[Usage]] = defaultdict(list)
    for index in (episode_usages(corpus_dir), fuior_usages(corpus_dir)):
        for name, values in index.items():
            merged[name].extend(values)
    return _usage_dict(merged)


def _safe_link(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.unlink(missing_ok=True)
    try:
        os.link(source, destination)
    except OSError:
        shutil.copy2(source, destination)


def _materialize_logical_sequences(
    sequences: list[dict[str, Any]],
    clip_paths: dict[str, list[str]],
    output_dir: Path,
) -> list[dict[str, Any]]:
    materialized: list[dict[str, Any]] = []
    identities = [
        (sequence["context"], sequence["character"], sequence["name"]) for sequence in sequences
    ]
    for sequence in sequences:
        frame_sources: list[str] = []
        unresolved: list[str] = []
        identity = (sequence["context"], sequence["character"], sequence["name"])
        destination_dir = (
            output_dir
            / "characters"
            / sequence["character"]
            / sequence["context"]
            / "logical"
            / sequence["name"]
        )
        if identities.count(identity) > 1:
            destination_dir /= Path(sequence["source"]).stem
        for index, frame_name in enumerate(sequence["frames"]):
            candidates = clip_paths.get(frame_name, [])
            if not candidates:
                unresolved.append(frame_name)
                continue
            source_relative = candidates[0]
            source = output_dir / source_relative
            destination = destination_dir / f"{index:03d}.png"
            _safe_link(source, destination)
            frame_sources.append(destination.relative_to(output_dir).as_posix())
        payload = {
            **sequence,
            "materialized_frames": frame_sources,
            "unresolved_frames": sorted(set(unresolved)),
        }
        destination_dir.mkdir(parents=True, exist_ok=True)
        (destination_dir / "sequence.json").write_text(
            json.dumps(payload, indent=2) + "\n",
            encoding="utf-8",
        )
        materialized.append(payload)
    return materialized


def _gallery_html(catalog: dict[str, Any]) -> str:
    encoded = json.dumps(catalog, ensure_ascii=False).replace("</", "<\\/")
    return f"""<!doctype html>
<html lang=\"en\">
<meta charset=\"utf-8\">
<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">
<title>Interrogation local asset library</title>
<style>
:root {{ color-scheme: dark; font: 14px/1.45 system-ui,sans-serif; background:#090909; color:#ddd }}
* {{ box-sizing:border-box }} body {{ margin:0 }} button,input,select {{ font:inherit }}
header {{ position:sticky; top:0; z-index:2; display:flex; gap:1rem; align-items:center; padding:1rem 1.25rem; background:#111; border-bottom:1px solid #333 }}
h1 {{ margin:0; font-size:1rem; letter-spacing:.08em; text-transform:uppercase }}
header input {{ flex:1; min-width:8rem; padding:.55rem .7rem; color:#eee; background:#080808; border:1px solid #444 }}
header select {{ padding:.55rem; color:#eee; background:#080808; border:1px solid #444 }}
.layout {{ display:grid; grid-template-columns:minmax(250px,32vw) 1fr; min-height:calc(100vh - 66px) }}
.list {{ max-height:calc(100vh - 66px); overflow:auto; border-right:1px solid #333 }}
.item {{ width:100%; padding:.7rem 1rem; color:#bbb; border:0; border-bottom:1px solid #222; background:#0b0b0b; text-align:left; cursor:pointer }}
.item:hover,.item.active {{ color:#fff; background:#242424 }} .item small {{ display:block; color:#777 }}
.viewer {{ display:grid; grid-template-rows:minmax(320px,62vh) auto; min-width:0 }}
.stage {{ position:relative; display:grid; place-items:center; overflow:hidden; background:radial-gradient(circle,#303030,#050505 70%) }}
.stage img {{ max-width:92%; max-height:92%; object-fit:contain; image-rendering:auto; filter:drop-shadow(0 18px 24px #000) }}
.badge {{ position:absolute; left:1rem; top:1rem; padding:.35rem .55rem; background:#000b; color:#aaa }}
.info {{ padding:1rem 1.25rem 3rem; overflow-wrap:anywhere }} .info h2 {{ margin:.1rem 0 .3rem }}
.meta {{ color:#999 }} .usage {{ margin:.45rem 0; padding:.55rem .7rem; background:#121212; border-left:2px solid #555 }}
.usage code {{ color:#c9b377 }} .empty {{ padding:2rem; color:#777 }}
@media(max-width:720px) {{ .layout {{ grid-template-columns:1fr }} .list {{ max-height:30vh; border-right:0; border-bottom:1px solid #333 }} .viewer {{ grid-template-rows:45vh auto }} }}
</style>
<header><h1>Local asset library</h1><input id=\"search\" placeholder=\"Search character, clip, or source\"><select id=\"kind\"><option value=\"all\">All assets</option><option value=\"character\">Characters</option><option value=\"asset\">Environment / UI</option><option value=\"logical\">Runtime-composed</option></select><span id=\"count\"></span></header>
<div class=\"layout\"><nav class=\"list\" id=\"list\"></nav><main class=\"viewer\"><div class=\"stage\"><img id=\"image\" alt=\"Selected frame\"><span class=\"badge\" id=\"badge\"></span></div><section class=\"info\" id=\"info\"><div class=\"empty\">Choose an animation.</div></section></main></div>
<script id=\"catalog\" type=\"application/json\">{encoded}</script>
<script>
const data=JSON.parse(document.querySelector('#catalog').textContent);
const clips=[];
for(const atlas of data.atlases) for(const clip of atlas.animations) clips.push({{...clip,atlas,kind:atlas.category,frames:clip.frames}});
for(const sequence of data.logical_sequences) clips.push({{...sequence,kind:'logical',atlas:{{identifier:sequence.source,context:sequence.context,character:sequence.character}},frames:sequence.materialized_frames||[],playback:'Lua',width:'varies',height:'varies',usages:data.usages[sequence.name]||[]}});
let selected=null,timer=null,frame=0,filtered=[];
const list=document.querySelector('#list'),image=document.querySelector('#image'),info=document.querySelector('#info'),badge=document.querySelector('#badge'),count=document.querySelector('#count');
const esc=value=>String(value??'').replace(/[&<>\"]/g,char=>({{'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}}[char]));
function drawFrame(){{if(!selected||!selected.frames.length){{image.removeAttribute('src');return}} image.src=selected.frames[frame%selected.frames.length];badge.textContent=`${{frame+1}} / ${{selected.frames.length}}`;}}
function choose(index){{selected=filtered[index];frame=0;clearInterval(timer);document.querySelectorAll('.item').forEach((node,i)=>node.classList.toggle('active',i===index));drawFrame();const usages=selected.usages||data.usages[selected.name]||[];info.innerHTML=`<h2>${{esc(selected.name)}}</h2><div class=meta>${{esc(selected.atlas.character||selected.atlas.context)}} · ${{esc(selected.kind)}} · ${{esc(selected.fps)}} fps · ${{selected.frames.length}} frames · ${{esc(selected.width)}}x${{esc(selected.height)}}<br><code>${{esc(selected.atlas.identifier)}}</code></div><h3>Source usage (${{usages.length}})</h3>${{usages.length?usages.map(use=>`<div class=usage><b>${{esc(use.kind)}}</b> · <code>${{esc(use.source)}}${{use.line?':'+use.line:''}}</code><br>${{esc(use.detail)}}</div>`).join(''):'<div class=empty>No direct episode/FUIOR reference found.</div>'}}`;if(selected.frames.length>1)timer=setInterval(()=>{{frame=(frame+1)%selected.frames.length;drawFrame()}},Math.max(80,1000/(Number(selected.fps)||5)));}}
function render(){{const query=document.querySelector('#search').value.toLowerCase(),kind=document.querySelector('#kind').value;filtered=clips.filter(clip=>(kind==='all'||clip.kind===kind)&&`${{clip.name}} ${{clip.atlas.identifier}} ${{clip.atlas.character||''}}`.toLowerCase().includes(query));list.innerHTML=filtered.map((clip,index)=>`<button class=item data-index=${{index}}>${{esc(clip.name)}}<small>${{esc(clip.atlas.character||clip.atlas.context)}} · ${{clip.frames.length}} frame${{clip.frames.length===1?'':'s'}}</small></button>`).join('');count.textContent=filtered.length;list.querySelectorAll('button').forEach(button=>button.onclick=()=>choose(Number(button.dataset.index)));if(filtered.length)choose(0);}}
document.querySelector('#search').addEventListener('input',render);document.querySelector('#kind').addEventListener('change',render);render();
</script>
</html>"""


def _write_character_manifests(
    atlases: list[dict[str, Any]],
    logical_sequences: list[dict[str, Any]],
    usages: dict[str, list[dict[str, Any]]],
    output_dir: Path,
) -> int:
    characters: dict[str, dict[str, Any]] = {}
    for atlas in atlases:
        character = atlas["character"]
        if character is None:
            continue
        payload = characters.setdefault(
            character,
            {
                "schema_version": ASSET_LIBRARY_SCHEMA_VERSION,
                "character": character,
                "contexts": {},
            },
        )
        context = payload["contexts"].setdefault(
            atlas["context"],
            {"atlas_clips": [], "logical_sequences": []},
        )
        character_root = output_dir / "characters" / character
        for animation in atlas["animations"]:
            context["atlas_clips"].append(
                {
                    "name": animation["name"],
                    "kind": animation["kind"],
                    "frames": [
                        (output_dir / frame).relative_to(character_root).as_posix()
                        for frame in animation["frames"]
                    ],
                    "fps": animation["fps"],
                    "width": animation["width"],
                    "height": animation["height"],
                    "source_playback": animation["playback"],
                    "source_atlas": atlas["identifier"],
                    "usages": animation["usages"],
                }
            )

    for sequence in logical_sequences:
        character = sequence["character"]
        payload = characters.get(character)
        if payload is None:
            continue
        context = payload["contexts"].setdefault(
            sequence["context"],
            {"atlas_clips": [], "logical_sequences": []},
        )
        character_root = output_dir / "characters" / character
        context["logical_sequences"].append(
            {
                "name": sequence["name"],
                "kind": "runtime-composed",
                "frames": [
                    (output_dir / frame).relative_to(character_root).as_posix()
                    for frame in sequence.get("materialized_frames", [])
                ],
                "fps": sequence["fps"],
                "offsets": sequence["offsets"],
                "source": sequence["source"],
                "usages": usages.get(sequence["name"], []),
            }
        )

    for character, payload in characters.items():
        path = output_dir / "characters" / character / "character.json"
        path.write_text(
            json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
    return len(characters)


def build_asset_library(
    extracted_dir: Path = EXTRACTED_OUTPUT_DIR,
    corpus_dir: Path = CORPUS,
    output_dir: Path = DEFAULT_OUTPUT_DIR,
    *,
    scope: str = "all",
    clean: bool = False,
    metadata_only: bool = False,
) -> dict[str, Any]:
    """Recover extracted atlases into folders and build a source-aware gallery."""
    if clean and output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    descriptors = discover_atlases(extracted_dir, output_dir, scope=scope)
    usages = build_usage_index(corpus_dir)
    atlas_entries: list[dict[str, Any]] = []
    clip_paths: dict[str, list[str]] = defaultdict(list)
    recovered_atlases = 0
    missing_atlases = 0

    for index, descriptor in enumerate(descriptors, 1):
        texture_set = parse_texture_set(descriptor.texturesetc)
        print(f"[{index}/{len(descriptors)}] {descriptor.identifier}")
        status = "metadata-only" if metadata_only else "recovered"
        manifest: dict[str, Any] | None = None
        if descriptor.texturec is None:
            status = "missing-texture"
            missing_atlases += 1
        elif not metadata_only:
            manifest = cast(
                "dict[str, Any]",
                recover_animations(
                    descriptor.texturec,
                    descriptor.texturesetc,
                    descriptor.output,
                    include_atlas=False,
                ),
            )
            recovered_atlases += 1

        animations: list[dict[str, Any]] = []
        for animation in texture_set.animations:
            if manifest is None:
                frames: list[str] = []
            else:
                raw_animation = manifest["animations"][animation.name]
                frames = [
                    (descriptor.output / frame).relative_to(output_dir).as_posix()
                    for frame in raw_animation["frames"]
                ]
                clip_paths[animation.name].extend(frames[:1])
            animations.append(
                {
                    **asdict(animation),
                    "kind": "static-pose"
                    if animation.end - animation.start == 1
                    else "atlas-sequence",
                    "frames": frames,
                    "usages": usages.get(animation.name, []),
                }
            )

        atlas_entries.append(
            {
                "identifier": descriptor.identifier,
                "category": descriptor.category,
                "context": descriptor.context,
                "character": descriptor.character,
                "sheet": descriptor.sheet,
                "status": status,
                "source": {
                    "texturesetc": descriptor.texturesetc.relative_to(extracted_dir).as_posix(),
                    "texturec": (
                        descriptor.texturec.relative_to(extracted_dir).as_posix()
                        if descriptor.texturec is not None
                        else None
                    ),
                },
                "output": descriptor.output.relative_to(output_dir).as_posix(),
                "animations": animations,
            }
        )

    lua_sequences = discover_lua_sequences(corpus_dir)
    logical_sequences = (
        []
        if metadata_only
        else _materialize_logical_sequences(lua_sequences, clip_paths, output_dir)
    )
    character_count = _write_character_manifests(
        atlas_entries,
        logical_sequences or lua_sequences,
        usages,
        output_dir,
    )
    all_animations = [animation for atlas in atlas_entries for animation in atlas["animations"]]
    recovered_animations = [
        animation
        for atlas in atlas_entries
        if atlas["status"] == "recovered"
        for animation in atlas["animations"]
    ]
    catalog = {
        "schema_version": ASSET_LIBRARY_SCHEMA_VERSION,
        "library": "interrogation-local-asset-library",
        "scope": scope,
        "source": {
            "extracted": str(extracted_dir),
            "corpus": str(corpus_dir),
            "copyright": "Local analysis only. Do not publish or redistribute recovered game assets.",
        },
        "summary": {
            "atlases": len(atlas_entries),
            "recovered_atlases": recovered_atlases,
            "missing_texture_atlases": missing_atlases,
            "characters": character_count,
            "atlas_clips": len(all_animations),
            "atlas_frames": sum(
                animation["end"] - animation["start"] for animation in all_animations
            ),
            "recovered_atlas_frames": sum(
                animation["end"] - animation["start"] for animation in recovered_animations
            ),
            "character_clips": sum(
                len(atlas["animations"])
                for atlas in atlas_entries
                if atlas["category"] == "character"
            ),
            "character_frames": sum(
                animation["end"] - animation["start"]
                for atlas in atlas_entries
                if atlas["category"] == "character"
                for animation in atlas["animations"]
            ),
            "logical_sequences": len(lua_sequences),
            "logical_sequence_frames": sum(len(sequence["frames"]) for sequence in lua_sequences),
            "usage_names": len(usages),
            "usage_references": sum(len(values) for values in usages.values()),
        },
        "atlases": atlas_entries,
        "logical_sequences": logical_sequences or lua_sequences,
        "usages": usages,
    }
    (output_dir / "catalog.json").write_text(
        json.dumps(catalog, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    (output_dir / "index.html").write_text(_gallery_html(catalog), encoding="utf-8")
    (output_dir / "README.txt").write_text(
        "Interrogation local asset library\n"
        "=================================\n\n"
        "Open index.html in a browser or browse characters/ and assets/.\n"
        "The PNG payload is recovered copyrighted material for local analysis only.\n"
        "Do not publish or redistribute this directory.\n",
        encoding="utf-8",
    )
    return catalog
