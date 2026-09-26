#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import json
import os
import random
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any

from google import genai

DEFAULT_IMAGE_MODEL = "gemini-3.1-flash-image"
DEFAULT_CRITIC_MODEL = "gemini-3.8-flash"
DEFAULT_COUNT = 100
DEFAULT_TOP = 10
DEFAULT_WORKERS = 3

VARIANTS = [
    "minimal competitive battleground HUD with maximum combat readability",
    "premium neon tactical HUD with restrained sci-fi accents",
    "clean mobile-first HUD with large thumb targets",
    "dark glass HUD with compact utility information",
    "high-contrast arcade battleground HUD with sharp hierarchy",
    "urban-tech HUD with modular panels and strong silhouettes",
    "minimalist action HUD with layered cooldown states",
    "cinematic combat HUD with restrained environmental framing",
    "modern esport HUD with compact resource meters",
    "stylized Roblox battleground HUD with original visual language",
]

BASE_PROMPT = """
Design an original Collision Battlestar Roblox combat HUD reference image.

Use the supplied reference images only to learn useful interaction patterns:
mobile action placement, compact combat HUD hierarchy, health/resource meters,
shop and progression card language, circular defensive controls, cooldown states,
and readable city-battleground presentation.

Do not copy logos, text, characters, branded UI, exact layouts, copyrighted art,
or franchise-specific visual identities from the references.

The target game is a continuous urban multiplayer battleground.
The permanent combat layer must expose exactly four core actions:
M1, DASH, BLOCK, SPECIAL.
Parry is a timing result of defensive play rather than a fifth permanent button.
Overdrive/Awakening is a state meter rather than another core action.

The HUD must support mobile, tablet, PC and gamepad.
Keep combat information sparse and readable.
Reserve the center of the screen for the character and combat.
Use safe-area-aware placement.
Use original icons, original panel shapes and a coherent typography system.
Show realistic examples of READY, cooldown, blocking, hit feedback and awakening states.
The final visual should look like a professional Roblox game UI concept sheet,
not a screenshot of an existing game.
"""

CRITIC_PROMPT = """
You are the visual QA director for Collision Battlestar.

Evaluate each candidate image against the supplied four reference images and the
design brief. The references are for interaction patterns, not for copying.

For every candidate, return:
id, total, legibility, hierarchy, mobile, combat, consistency, originality,
spacing, restraint, platform_support, and one concise reason.

Use integer scores from 0 to 10.
Total must be the arithmetic sum of the ten category scores.
Reject layouts that are cluttered, hard to read, too close to a known game's layout,
or that create a fifth permanent combat button.

Return JSON only:
{"candidates":[{"id":"Candidate 001","total":93,"legibility":10,"hierarchy":9,"mobile":10,"combat":10,"consistency":9,"originality":9,"spacing":9,"restraint":9,"platform_support":9,"reason":"..."}]}
"""

FINAL_PROMPT = """
Create the final Collision Battlestar HUD direction by studying the ten finalist
reference images supplied after this text.

Synthesize the strongest qualities across the finalists rather than averaging their
visual clutter. Preserve the four-action combat language:
M1, DASH, BLOCK, SPECIAL.

Create one polished original HUD concept sheet showing:
1. standard combat HUD,
2. mobile combat HUD,
3. cooldown and blocking states,
4. awakening/overdrive state,
5. compact secondary menu language.

Keep the main combat screen sparse.
Use original icons, original shapes, original typography treatment and an urban-tech
visual identity. Do not reproduce any logo, franchise character, copyrighted UI,
exact panel geometry or exact text treatment from the reference games.

The result should be suitable as the visual specification for a real Roblox UI
implementation.
"""

def load_image(path: Path) -> tuple[str, str]:
    suffix = path.suffix.lower()
    mime = {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".webp": "image/webp",
    }.get(suffix)
    if not mime:
        raise ValueError(f"Unsupported image type: {path}")
    return base64.b64encode(path.read_bytes()).decode("utf-8"), mime

def image_parts(paths: list[Path]) -> list[dict[str, str]]:
    parts = []
    for path in paths:
        data, mime = load_image(path)
        parts.append({"type": "image", "data": data, "mime_type": mime})
    return parts

def parse_json(text: str) -> Any:
    text = text.strip()
    fenced = re.search(r"\`\`\`(?:json)?\s*(.*?)\s*\`\`\`", text, re.S | re.I)
    if fenced:
        text = fenced.group(1)
    start = text.find("{")
    end = text.rfind("}")
    if start < 0 or end < start:
        raise ValueError("Critic did not return JSON")
    return json.loads(text[start:end + 1])

def generate_one(client: genai.Client, image_model: str, references: list[Path], output_path: Path, candidate_id: int) -> Path:
    seed = random.randint(0, 2_000_000_000)
    variant = VARIANTS[(candidate_id - 1) % len(VARIANTS)]
    prompt = (
        BASE_PROMPT
        + f"\nVariation direction: {variant}.\nCandidate number: {candidate_id:03d}.\n"
        + f"Use this hidden design seed only to diversify the composition: {seed}."
    )
    input_parts: list[dict[str, Any]] = [{"type": "text", "text": prompt}]
    input_parts.extend(image_parts(references))
    interaction = client.interactions.create(
        model=image_model,
        input=input_parts,
        response_format={
            "type": "image",
            "mime_type": "image/png",
            "aspect_ratio": "16:9",
            "image_size": "1K",
        },
    )
    image = interaction.output_image
    if not image or not image.data:
        raise RuntimeError(f"No image output for candidate {candidate_id:03d}")
    output_path.write_bytes(base64.b64decode(image.data))
    return output_path

def critic_batch(client: genai.Client, critic_model: str, paths: list[Path], start_index: int) -> list[dict[str, Any]]:
    parts: list[dict[str, Any]] = [{"type": "text", "text": CRITIC_PROMPT}]
    for offset, path in enumerate(paths):
        candidate_id = f"Candidate {start_index + offset:03d}"
        data, mime = load_image(path)
        parts.append({"type": "text", "text": candidate_id})
        parts.append({"type": "image", "data": data, "mime_type": mime})
    interaction = client.interactions.create(model=critic_model, input=parts)
    return parse_json(interaction.output_text or "").get("candidates", [])

def build_final(client: genai.Client, image_model: str, finalists: list[Path], output_path: Path) -> Path:
    parts: list[dict[str, Any]] = [{"type": "text", "text": FINAL_PROMPT}]
    for index, path in enumerate(finalists, 1):
        data, mime = load_image(path)
        parts.append({"type": "text", "text": f"Finalist reference {index:02d}"})
        parts.append({"type": "image", "data": data, "mime_type": mime})
    interaction = client.interactions.create(
        model=image_model,
        input=parts,
        response_format={
            "type": "image",
            "mime_type": "image/png",
            "aspect_ratio": "16:9",
            "image_size": "1K",
        },
    )
    image = interaction.output_image
    if not image or not image.data:
        raise RuntimeError("No final image output")
    output_path.write_bytes(base64.b64decode(image.data))
    return output_path

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--references", required=True)
    parser.add_argument("--output", default="hud_ai_output")
    parser.add_argument("--count", type=int, default=DEFAULT_COUNT)
    parser.add_argument("--top", type=int, default=DEFAULT_TOP)
    parser.add_argument("--workers", type=int, default=DEFAULT_WORKERS)
    parser.add_argument("--image-model", default=DEFAULT_IMAGE_MODEL)
    parser.add_argument("--critic-model", default=DEFAULT_CRITIC_MODEL)
    args = parser.parse_args()

    key = os.getenv("GEMINI_API_KEY")
    if not key:
        raise SystemExit("GEMINI_API_KEY is required in the environment")
    if args.count < args.top or args.top < 1:
        raise SystemExit("--count must be >= --top >= 1")
    if args.count > 1000:
        raise SystemExit("--count is capped at 1000")
    if args.workers < 1 or args.workers > 8:
        raise SystemExit("--workers must be between 1 and 8")

    reference_dir = Path(args.references)
    references = [p for p in sorted(reference_dir.iterdir()) if p.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}]
    if not references:
        raise SystemExit("No reference images found")
    if len(references) > 4:
        raise SystemExit("Use at most four primary reference images in the generation pass")

    output_dir = Path(args.output)
    candidates_dir = output_dir / "candidates"
    finalists_dir = output_dir / "finalists"
    candidates_dir.mkdir(parents=True, exist_ok=True)
    finalists_dir.mkdir(parents=True, exist_ok=True)

    client = genai.Client(api_key=key)

    tasks = {}
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        for candidate_id in range(1, args.count + 1):
            path = candidates_dir / f"candidate_{candidate_id:03d}.png"
            tasks[pool.submit(generate_one, client, args.image_model, references, path, candidate_id)] = candidate_id
        for future in as_completed(tasks):
            candidate_id = tasks[future]
            try:
                future.result()
                print(f"generated {candidate_id:03d}/{args.count}")
            except Exception as exc:
                print(f"generation_failed {candidate_id:03d}: {exc}")

    candidates = sorted(candidates_dir.glob("candidate_*.png"))
    if len(candidates) < args.top:
        raise SystemExit(f"Only {len(candidates)} candidates generated")

    batches = [candidates[i:i + 10] for i in range(0, len(candidates), 10)]
    scores: dict[str, dict[str, Any]] = {}
    for batch_index, batch in enumerate(batches):
        start_index = batch_index * 10 + 1
        for attempt in range(3):
            try:
                results = critic_batch(client, args.critic_model, batch, start_index)
                for item in results:
                    if isinstance(item, dict) and item.get("id"):
                        scores[str(item["id"])] = item
                break
            except Exception as exc:
                if attempt == 2:
                    print(f"critic_failed batch {batch_index + 1}: {exc}")
                else:
                    time.sleep(2 ** attempt)

    ranked = []
    for path in candidates:
        candidate_id = f"Candidate {int(path.stem.split('_')[-1]):03d}"
        item = scores.get(candidate_id)
        if item:
            ranked.append((int(item.get("total", 0)), candidate_id, path, item))
    ranked.sort(key=lambda x: (-x[0], x[1]))

    selected = ranked[:args.top]
    manifest = {
        "image_model": args.image_model,
        "critic_model": args.critic_model,
        "generated": len(candidates),
        "scored": len(ranked),
        "top": [
            {"rank": i + 1, "id": item[1], "path": str(item[2]), "score": item[0], "critique": item[3]}
            for i, item in enumerate(selected)
        ],
    }
    (output_dir / "selection.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")

    finalists = []
    for rank, (_, _, path, _) in enumerate(selected, 1):
        target = finalists_dir / f"finalist_{rank:02d}.png"
        target.write_bytes(path.read_bytes())
        finalists.append(target)

    if len(finalists) < args.top:
        raise SystemExit("Not enough finalists for the final synthesis")

    build_final(client, args.image_model, finalists, output_dir / "collision_battlestar_hud_final.png")
    print(f"final={output_dir / 'collision_battlestar_hud_final.png'}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
