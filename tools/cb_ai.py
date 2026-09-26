#!/usr/bin/env python3
from __future__ import annotations
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
KNOWLEDGE = ROOT / "tools" / "CB_AI_LuauKnowledge.md"
CONFIG = ROOT / ".cb-ai.json"

MODEL = "gemini-3.8-flash"
ROUNDS = 5
MAX_SNAPSHOT = 900_000
MAX_FILE = 45_000
MAX_OPS = 8
EXCLUDED = {".git", ".cb-ai", "build", "node_modules", "__pycache__"}
ALLOWED_PREFIXES = ("src/", "tools/", "docs/")
ALLOWED_ROOTS = {"README.md", "default.project.json", "rokit.toml", ".gitignore"}

SYSTEM = r"""
You are the Collision Battlestar repository repair engineer.
Inspect only the local repository snapshot. Find concrete Roblox/Luau defects and return safe complete-file replacements.

You are an expert in:
Luau strict mode, ModuleScripts, Script/LocalScript lifecycle, Roblox services and Instances, ReplicatedStorage,
RemoteEvent/RemoteFunction security, client/server replication, Player/Character lifecycle, Humanoid, Animator,
CFrame, Vector3, Model:GetPivot/Model:PivotTo, raycasts, overlap queries, attributes, signals, task scheduling,
DataStoreService, MarketplaceService/ProcessReceipt, PlayerGui, ScreenGui, Activated, ZIndex, mobile UI,
Pathfinding, physics, anti-cheat movement grace, and Rojo default.project.json mapping.

Rules:
- server-authoritative combat, economy, persistence, purchases, admin and protected progression;
- never trust client damage, rewards, prices, ownership or admin state;
- never invent IDs, secrets, remotes, attributes, APIs or files unsupported by the snapshot;
- never write secrets or API keys;
- never delete files;
- prefer targeted fixes and preserve working interfaces;
- do not add packages;
- do not modify GitHub workflows unless directly required by a validation failure;
- output ONLY JSON with status, summary and operations;
- operations contain complete UTF-8 file contents, not patches.
"""

def read_config() -> dict[str, Any]:
    if not CONFIG.exists():
        return {}
    try:
        value = json.loads(CONFIG.read_text(encoding="utf-8"))
        return value if isinstance(value, dict) else {}
    except Exception:
        return {}

def run(args: list[str], timeout: int = 180) -> tuple[int, str]:
    try:
        p = subprocess.run(args, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           text=True, timeout=timeout, check=False)
        return p.returncode, p.stdout[-30_000:]
    except FileNotFoundError:
        return 127, f"command not found: {args[0]}"
    except subprocess.TimeoutExpired:
        return 124, f"timeout: {' '.join(args)}"

def validate() -> tuple[bool, str]:
    checks = [
        [sys.executable, "tools/validate_project.py"],
        ["git", "diff", "--check"],
    ]
    parts = []
    ok = True

    for args in checks:
        code, out = run(args)
        parts.append(f"$ {' '.join(args)}\nexit={code}\n{out}")
        if code != 0:
            ok = False
            break

    rojo, _ = run(["rojo", "--version"], timeout=20)
    if rojo == 0:
        code, out = run(["rojo", "build", "default.project.json", "--output", "build/CB_AI_validation.rbxl"])
        parts.append(f"$ rojo build default.project.json\nexit={code}\n{out}")
        if code != 0:
            ok = False
    else:
        parts.append("Rojo unavailable locally.")

    return ok, "\n\n".join(parts)

def include(path: Path) -> bool:
    rel = path.relative_to(ROOT)
    if any(part in EXCLUDED for part in rel.parts):
        return False
    return path.is_file() and path.suffix.lower() in {
        ".lua", ".luau", ".py", ".json", ".toml", ".yml", ".yaml", ".md"
    }

def snapshot() -> str:
    files = [p for p in ROOT.rglob("*") if include(p)]
    files.sort(key=lambda p: (0 if p.suffix.lower() in {".lua", ".luau"} else 1, str(p).lower()))
    parts, total = [], 0

    for path in files:
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if len(text) > MAX_FILE:
            text = text[:MAX_FILE] + "\n-- CB-AI snapshot truncation\n"
        block = f"\n===== FILE: {path.relative_to(ROOT).as_posix()} =====\n{text}\n"
        if total + len(block) > MAX_SNAPSHOT:
            continue
        parts.append(block)
        total += len(block)

    return "".join(parts)

def prompt(snap: str, validation: str, round_no: int) -> str:
    knowledge = KNOWLEDGE.read_text(encoding="utf-8")[:80_000] if KNOWLEDGE.exists() else ""
    roots = ", ".join(sorted(ALLOWED_ROOTS))
    return f"""
Repository: {ROOT}
Repair round: {round_no}

Project Luau knowledge:
{knowledge}

Validation:
{validation}

Local source snapshot:
{snap}

Trace the call graph where necessary. Check especially:
Rojo mapping, require paths, RemoteEvent names, service initialization order, client-to-server action wiring,
attributes/state events, HUD mounting, M1 hit detection, dash movement versus anti-cheat, DataStore/ProcessReceipt,
admin authorization, strict Luau nil/type errors, stale references, and obvious performance problems.

Return ONLY:
{{
  "status": "ok" or "fix",
  "summary": "one sentence",
  "operations": [
    {{
      "action": "update" or "create",
      "path": "relative/path.lua",
      "content": "complete file content",
      "reason": "concrete defect"
    }}
  ]
}}

Maximum {MAX_OPS} operations.
Allowed paths: src/, tools/, docs/, or root files {roots}.
Never delete. Never include secrets.
"""

def api(key: str, model: str, body_text: str) -> dict[str, Any]:
    url = "https://generativelanguage.googleapis.com/v1beta/models/" + urllib.parse.quote(model, safe="") \
        + ":generateContent?key=" + urllib.parse.quote(key, safe="")
    payload = {
        "contents": [{"role": "user", "parts": [{"text": SYSTEM + "\n\n" + body_text}]}],
        "generationConfig": {
            "temperature": 0.1,
            "maxOutputTokens": 65536,
            "responseMimeType": "application/json",
        },
    }
    req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"),
                                 headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=180) as response:
            data = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f"Gemini HTTP {exc.code}: {exc.read().decode('utf-8', 'replace')[:4000]}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Gemini network error: {exc}") from exc

    try:
        text = data["candidates"][0]["content"]["parts"][0]["text"].strip()
    except (KeyError, IndexError, TypeError) as exc:
        raise RuntimeError("Gemini returned no usable response.") from exc

    fence = chr(96) * 3
    if text.startswith(fence):
        first = text.find("\n")
        text = text[first + 1:] if first >= 0 else text
        if text.endswith(fence):
            text = text[:-3]
    result = json.loads(text)
    if not isinstance(result, dict):
        raise RuntimeError("AI response root is not an object.")
    return result

def allowed(path: str) -> bool:
    normalized = path.replace("\\", "/").lstrip("/")
    if ".." in Path(normalized).parts:
        return False
    return normalized in ALLOWED_ROOTS or normalized.startswith(ALLOWED_PREFIXES)

def apply(ops: list[Any], round_no: int) -> int:
    backup_root = ROOT / ".cb-ai" / "backups" / f"round-{round_no}"
    applied = 0

    for op in ops[:MAX_OPS]:
        if not isinstance(op, dict):
            continue
        action, path_text, content = op.get("action"), op.get("path"), op.get("content")
        if action not in {"update", "create"} or not isinstance(path_text, str) or not allowed(path_text):
            print(f"[CB-AI] rejected operation: {path_text!r}")
            continue
        if not isinstance(content, str) or len(content) > 300_000:
            print(f"[CB-AI] rejected content: {path_text}")
            continue

        target = (ROOT / path_text).resolve()
        if ROOT not in target.parents:
            print(f"[CB-AI] rejected path escape: {path_text}")
            continue

        if target.exists():
            backup = backup_root / target.relative_to(ROOT)
            backup.parent.mkdir(parents=True, exist_ok=True)
            backup.write_text(target.read_text(encoding="utf-8"), encoding="utf-8")

        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
        print(f"[CB-AI] {action}: {path_text}")
        applied += 1

    return applied

def main() -> int:
    if not (ROOT / ".git").is_dir():
        print("[CB-AI] Must run inside the repository.", file=sys.stderr)
        return 2

    cfg = read_config()
    key = os.environ.get("GEMINI_API_KEY") or os.environ.get("CB_AI_API_KEY")
    if not key:
        print("[CB-AI] Missing GEMINI_API_KEY.", file=sys.stderr)
        print('export GEMINI_API_KEY="YOUR_KEY"', file=sys.stderr)
        return 2

    model = os.environ.get("CB_AI_MODEL") or cfg.get("model") or MODEL
    try:
        rounds = max(1, min(8, int(os.environ.get("CB_AI_ROUNDS", cfg.get("rounds", ROUNDS)))))
    except (TypeError, ValueError):
        rounds = ROUNDS

    print(f"[CB-AI] repo={ROOT}")
    print(f"[CB-AI] model={model}")
    ok, validation = validate()
    print(f"[CB-AI] initial validation={'PASS' if ok else 'FAIL'}")

    for round_no in range(1, rounds + 1):
        result = api(key, model, prompt(snapshot(), validation, round_no))
        print(f"[CB-AI] status={result.get('status')}: {result.get('summary', '')}")
        ops = result.get("operations") or []

        if result.get("status") == "ok" or not ops:
            final_ok, report = validate()
            print(report)
            return 0 if final_ok else 1

        if apply(ops, round_no) == 0:
            return 1

        ok, validation = validate()
        print(validation)
        if ok:
            audit = api(key, model, prompt(snapshot(), validation, round_no + 1))
            if audit.get("status") == "ok" or not audit.get("operations"):
                print("[CB-AI] post-fix audit=PASS")
                return 0

    final_ok, report = validate()
    print(report)
    return 0 if final_ok else 1

if __name__ == "__main__":
    raise SystemExit(main())
