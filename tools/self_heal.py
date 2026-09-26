#!/usr/bin/env python3
from __future__ import annotations

import base64
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path
from typing import Any

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/"src"/"CollisionBattlestar"
RUN_ID=os.environ.get("QA_RUN_ID") or time.strftime("%Y%m%d-%H%M%S")
WORK=ROOT/".ci"/"self-heal"/RUN_ID
ORIGINALS=WORK/"originals"
REPO_BACKUP=ROOT/"qa"/"autofix"/"backups"/f"{RUN_ID}.json"
RESULT=WORK/"result.json"
MAX_ATTEMPTS=3
GEMINI_MODEL=os.environ.get("GEMINI_MODEL","gemini-3.8-flash")
ALLOWED_SUFFIXES={".lua"}
ALLOWED_PATHS={"default.project.json"}

DETECTOR_MAP={
    "HUD":["src/CollisionBattlestar/ReplicatedStorage/Shared/UI/HUDLayout.lua","src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua"],
    "Mobile":["src/CollisionBattlestar/ReplicatedStorage/Shared/UI/HUDLayout.lua","src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua"],
    "M1":["src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua","src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua"],
    "Dash":["src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua","src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua"],
    "Block":["src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua","src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua"],
    "Special":["src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua","src/CollisionBattlestar/ReplicatedStorage/Shared/Config.lua"],
    "Shop":["src/CollisionBattlestar/ReplicatedStorage/Shared/StoreCatalog.lua","src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua","src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua"],
    "Map":["src/CollisionBattlestar/ReplicatedStorage/Shared/MapDefinitions.lua","src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua","src/CollisionBattlestar/ReplicatedStorage/Shared/UI/HUDLayout.lua"],
    "QA":["src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/QARunner.client.lua","src/CollisionBattlestar/ServerScriptService/QAService.server.lua"],
}

def fail(message: str, exit_code: int=1):
    print(message, file=sys.stderr)
    raise SystemExit(exit_code)

def run(cmd: list[str], timeout: int=180) -> tuple[int,str]:
    p=subprocess.run(cmd,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=timeout)
    return p.returncode,p.stdout

def safe_path(raw: str) -> Path:
    path=Path(raw)
    if path.is_absolute() or ".." in path.parts:
        fail("AI returned an unsafe path: "+raw)
    if raw not in ALLOWED_PATHS and (path.suffix not in ALLOWED_SUFFIXES or not raw.startswith("src/CollisionBattlestar/")):
        fail("AI returned a disallowed path: "+raw)
    return ROOT/path

def load_report() -> dict[str,Any]:
    raw=os.environ.get("QA_REPORT","")
    if not raw:
        fail("QA_REPORT is missing")
    try:
        return json.loads(raw)
    except json.JSONDecodeError as e:
        fail("QA_REPORT is invalid JSON: "+str(e))

def detector_context(report: dict[str,Any]) -> list[str]:
    selected=[]
    for item in report.get("results",[]):
        if item.get("pass"):
            continue
        name=str(item.get("name",""))
        for key,paths in DETECTOR_MAP.items():
            if key.lower() in name.lower():
                selected.extend(paths)
    if not selected:
        selected=[
            "src/CollisionBattlestar/ReplicatedStorage/Shared/UI/HUDLayout.lua",
            "src/CollisionBattlestar/StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua",
            "src/CollisionBattlestar/ServerScriptService/Bootstrap.server.lua",
        ]
    out=[]
    for path in dict.fromkeys(selected):
        p=ROOT/path
        if p.is_file():
            out.append(path)
    return out

def snapshot(paths: list[str]) -> dict[str,str]:
    ORIGINALS.mkdir(parents=True,exist_ok=True)
    data={}
    for path in paths:
        p=ROOT/path
        value=p.read_text(encoding="utf-8")
        data[path]=value
        target=ORIGINALS/path
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_text(value,encoding="utf-8")
    return data

def restore(data: dict[str,str]):
    for path,value in data.items():
        p=ROOT/path
        p.parent.mkdir(parents=True,exist_ok=True)
        p.write_text(value,encoding="utf-8")

def save_internal_backup(data: dict[str,str],report: dict[str,Any]):
    REPO_BACKUP.parent.mkdir(parents=True,exist_ok=True)
    payload={
        "run_id":RUN_ID,
        "timestamp":int(time.time()),
        "report":report,
        "files":{path:base64.b64encode(value.encode("utf-8")).decode("ascii") for path,value in data.items()},
    }
    REPO_BACKUP.write_text(json.dumps(payload,ensure_ascii=False,indent=2),encoding="utf-8")

def ensure_luau() -> Path:
    root=WORK/"luau"
    binary=root/"luau-compile"
    if binary.exists():
        return binary
    root.mkdir(parents=True,exist_ok=True)
    archive=root/"luau.zip"
    url="https://github.com/luau-lang/luau/releases/download/0.740/luau-ubuntu.zip"
    urllib.request.urlretrieve(url,archive)
    with zipfile.ZipFile(archive) as z:
        z.extractall(root)
    candidates=list(root.rglob("luau-compile"))
    if not candidates:
        fail("Could not obtain luau-compile")
    candidates[0].chmod(0o755)
    return candidates[0]

def validate() -> tuple[bool,str]:
    code,out=run([sys.executable,"tools/validate_project.py"])
    if code:
        return False,"PROJECT VALIDATION FAILED\n"+out
    try:
        binary=ensure_luau()
        outputs=[]
        for path in SRC.rglob("*.lua"):
            code,textout=run([str(binary),"--only-parse",str(path)])
            if code:
                return False,"LUA PARSE FAILED\n"+str(path)+"\n"+textout
            outputs.append(str(path))
        code,out=run(["git","diff","--check"])
        if code:
            return False,"GIT DIFF CHECK FAILED\n"+out
        return True,"PASS\n"+out+"\nParsed "+str(len(outputs))+" Luau files."
    except Exception as e:
        return False,"VALIDATION TOOL ERROR\n"+repr(e)

def ai_request(prompt: str) -> dict[str,Any]:
    key=os.environ.get("GEMINI_API_KEY")
    if not key:
        fail("GEMINI_API_KEY is missing")
    body=json.dumps({
        "contents":[{"parts":[{"text":prompt}]}],
        "generationConfig":{"temperature":0.15,"maxOutputTokens":18000},
    }).encode()
    req=urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent",
        data=body,
        headers={"Content-Type":"application/json","x-goog-api-key":key},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req,timeout=180) as response:
            payload=json.load(response)
    except urllib.error.HTTPError as e:
        fail("Gemini HTTP error: "+str(e)+"\n"+e.read().decode("utf-8","replace"))
    text=payload["candidates"][0]["content"]["parts"][0]["text"]
    match=re.search(r"\{[\s\S]*\}",text)
    if not match:
        fail("Gemini did not return JSON")
    try:
        result=json.loads(match.group(0))
    except json.JSONDecodeError as e:
        fail("Gemini JSON parse failed: "+str(e))
    return result

def build_prompt(report: dict[str,Any],paths: list[str],previous_error: str,attempt: int) -> str:
    files=[]
    for path in paths:
        value=(ROOT/path).read_text(encoding="utf-8")
        files.append("\n===== "+path+" =====\n"+value)
    validator=(ROOT/"tools/validate_project.py").read_text(encoding="utf-8")
    return f"""You are the self-healing engineering agent for the Roblox game Collision Battlestar.
You are repairing a live production codebase after an owner-only runtime QA bot detected a failure.

Rules:
1. Diagnose from evidence. Do not invent missing runtime facts.
2. Only edit files under src/CollisionBattlestar/ or default.project.json.
3. Return complete replacement contents for every edited file.
4. Do not edit GitHub workflows, secrets, QA automation, permissions, or documentation.
5. Preserve server authority, the four core combat actions M1, Dash, Block, Special, and mobile support.
6. Prefer the smallest robust fix.
7. The replacement must be valid Luau and compatible with the existing architecture.
8. Never remove a feature merely to make a detector pass.
9. Do not add network calls from the Roblox client.
10. Attempt {attempt} of {MAX_ATTEMPTS}. A previous attempt may already have failed; use its error output.

Return ONLY JSON:
{{"diagnosis":"...","edits":[{{"path":"...","content":"...","reason":"..."}}],"tests":["..."]}}

QA REPORT:
{json.dumps(report,ensure_ascii=False,indent=2)}

PREVIOUS VALIDATION ERROR:
{previous_error or "none"}

VALIDATOR CONTRACT:
{validator}

RELEVANT SOURCE:
{''.join(files)}
"""

def apply_edits(edits: Any):
    if not isinstance(edits,list) or not edits:
        fail("AI returned no edits")
    if len(edits)>4:
        fail("AI returned too many edits")
    touched=[]
    for edit in edits:
        if not isinstance(edit,dict):
            fail("Malformed edit")
        path=str(edit.get("path",""))
        content=edit.get("content")
        if not path or not isinstance(content,str):
            fail("Malformed AI edit for "+path)
        p=safe_path(path)
        p.parent.mkdir(parents=True,exist_ok=True)
        p.write_text(content,encoding="utf-8")
        touched.append(path)
    return touched

def git_state() -> dict[str,Any]:
    code,out=run(["git","status","--short"])
    return {"code":code,"status":out}

def write_result(result:dict[str,Any]):
    RESULT.parent.mkdir(parents=True,exist_ok=True)
    RESULT.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps(result,ensure_ascii=False,indent=2))

def main()->int:
    report=load_report()
    WORK.mkdir(parents=True,exist_ok=True)
    paths=detector_context(report)
    original=snapshot(paths)
    save_internal_backup(original,report)
    previous_error=""
    attempts=[]
    success=False
    final_edits=[]

    for attempt in range(1,MAX_ATTEMPTS+1):
        restore(original)
        prompt=build_prompt(report,paths,previous_error,attempt)
        try:
            patch=ai_request(prompt)
            diagnosis=str(patch.get("diagnosis",""))
            touched=apply_edits(patch.get("edits"))
        except SystemExit:
            raise
        except Exception as e:
            previous_error="PATCH GENERATION ERROR\n"+repr(e)
            attempts.append({"attempt":attempt,"status":"generation_failed","error":previous_error})
            continue

        valid,output=validate()
        diff_code,diff=run(["git","diff","--",*touched])
        attempt_data={"attempt":attempt,"status":"pass" if valid else "fail","diagnosis":diagnosis,"files":touched,"validation":output,"diff":diff}
        attempts.append(attempt_data)

        if valid:
            success=True
            final_edits=touched
            break

        previous_error=output
        restore(original)

    result={
        "run_id":RUN_ID,
        "status":"SUCCESS" if success else "ROLLED_BACK",
        "attempts":attempts,
        "touched_files":final_edits,
        "backup_file":str(REPO_BACKUP.relative_to(ROOT)),
        "git_state":git_state(),
    }
    write_result(result)
    return 0 if success else 2

if __name__=="__main__":
    raise SystemExit(main())
