#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"

EXPECTED = {
    "Yuji", "Gojo", "Sukuna", "Megumi", "Yuta", "Maki", "Toji", "Mahito",
    "Todo", "Hakari", "Choso", "Kashimo", "Naoya", "Kenjaku", "Jogo", "Dagon",
    "Hanami", "Higuruma", "Takaba", "Uraume", "Yorozu", "Ryu", "Uro", "Kusakabe",
}

DOMAIN_CHARACTERS = {
    "Gojo": "UnlimitedVoid",
    "Sukuna": "MalevolentShrine",
    "Megumi": "ChimeraShadowGarden",
    "Yuta": "AuthenticLove",
    "Mahito": "SelfEmbodiment",
    "Hakari": "IdleDeathGamble",
    "Kenjaku": "WombProfusion",
    "Jogo": "CoffinOfTheIronMountain",
    "Dagon": "HorizonOfCaptivatingSkandha",
    "Higuruma": "DeadlySentencing",
}

REQUIRED_FILES = [
    "ReplicatedStorage/Characters/CharacterDefinitions.lua",
    "ReplicatedStorage/Characters/CharacterFactory.lua",
    "ReplicatedStorage/Characters/CharacterService.lua",
    "ReplicatedStorage/Combat/HitboxService.lua",
    "ReplicatedStorage/Domains/DomainService.lua",
    "ReplicatedStorage/DomainClash/DomainClashService.lua",
    "ReplicatedStorage/PerfectCombos/PerfectComboService.lua",
    "ReplicatedStorage/OneTimeAttacks/OneTimeAttackService.lua",
    "ReplicatedStorage/Shared/Config.lua",
    "ReplicatedStorage/Shared/RemoteService.lua",
    "ServerScriptService/CombatServer.server.lua",
    "ServerScriptService/WorldBuilder.server.lua",
    "StarterPlayer/StarterPlayerScripts/CombatClient.client.lua",
]

FORBIDDEN = [
    re.compile(r"\bCE\b", re.I),
    re.compile(r"\bMaxCE\b", re.I),
    re.compile(r"\bCursedEnergy\b", re.I),
    re.compile(r"\bspendCE\b", re.I),
    re.compile(r"\bCECost\b", re.I),
    re.compile(r"\bCERegen\b", re.I),
]

CRITICAL_STUBS = re.compile(
    r"\b(?:TODO|FIXME|HACK|NOT IMPLEMENTED|IMPLEMENT ME|PLACEHOLDER)\b",
    re.I,
)


def fail(message: str) -> None:
    print(f"ERROR: {message}")
    raise SystemExit(1)


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as exc:
        fail(f"cannot read {path.relative_to(ROOT)}: {exc}")


def main() -> int:
    if not SRC.is_dir():
        fail("src directory is missing")

    for relative in REQUIRED_FILES:
        if not (SRC / relative).is_file():
            fail(f"required file missing: src/{relative}")

    definitions = read(SRC / "ReplicatedStorage/Characters/CharacterDefinitions.lua")
    factory = read(SRC / "ReplicatedStorage/Characters/CharacterFactory.lua")
    service = read(SRC / "ReplicatedStorage/Characters/CharacterService.lua")

    definition_ids = set(re.findall(r"\n\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*\{\n\s*Id\s*=\s*\"([A-Za-z][A-Za-z0-9_]*)\"",
                                     definitions))
    ids = {pair[0] for pair in definition_ids}
    if ids != EXPECTED:
        fail(f"character definition mismatch: missing={sorted(EXPECTED - ids)} extra={sorted(ids - EXPECTED)}")

    declared_id_values = [value for _, value in definition_ids]
    if len(declared_id_values) != len(set(declared_id_values)):
        fail("duplicate character Id values in CharacterDefinitions.lua")

    module_keys = set(re.findall(r"\n\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*require\(ReplicatedStorage\.Characters\.",
                           service))
    if module_keys != EXPECTED:
        fail(f"CharacterService coverage mismatch: missing={sorted(EXPECTED - module_keys)} extra={sorted(module_keys - EXPECTED)}")

    for character in sorted(EXPECTED):
        path = SRC / "ReplicatedStorage/Characters" / f"{character}.lua"
        if not path.is_file():
            fail(f"character module missing: {character}.lua")
        content = read(path)
        if not re.search(rf'Factory\.Build\("{re.escape(character)}"\)', content):
            fail(f"character module does not bind to Factory.Build: {character}.lua")

    for character, domain in DOMAIN_CHARACTERS.items():
        pattern = rf"{re.escape(character)}\s*=\s*\{{.*?Domain\s*=\s*\"{re.escape(domain)}\""
        if not re.search(pattern, definitions, re.S):
            fail(f"domain definition missing or mismatched for {character}")

    required_factory_methods = ["Init", "GetCooldown", "Special", "Skill", "Awaken", "Domain", "OneTime", "OnIncomingDamage"]
    for method in required_factory_methods:
        if not re.search(rf"function M\.{re.escape(method)}\b", factory):
            fail(f"CharacterFactory missing method: M.{method}")

    all_text_files = [p for p in ROOT.rglob("*") if p.is_file() and ".git" not in p.parts]
    for path in all_text_files:
        if path.suffix.lower() not in {".lua", ".luau", ".json", ".md", ".toml", ".yml", ".yaml", ".py"}:
            continue
        try:
            content = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for pattern in FORBIDDEN:
            if pattern.search(content):
                fail(f"forbidden universal energy reference found in {path.relative_to(ROOT)}: {pattern.pattern}")
        match = CRITICAL_STUBS.search(content)
        if match:
            fail(f"critical stub marker found in {path.relative_to(ROOT)}: {match.group(0)}")

    project = json.loads(read(ROOT / "default.project.json"))
    if project.get("name") != "CursedCollision":
        fail("default.project.json has an unexpected project name")
    if project.get("tree", {}).get("ReplicatedStorage", {}).get("$path") != "src/ReplicatedStorage":
        fail("default.project.json ReplicatedStorage mapping is broken")
    if project.get("tree", {}).get("ServerScriptService", {}).get("$path") != "src/ServerScriptService":
        fail("default.project.json ServerScriptService mapping is broken")

    required_runtime_terms = {
        "server_authoritative_damage": "context.damage(" in read(SRC / "ServerScriptService/CombatServer.server.lua"),
        "clash_service": "DomainClashService:TryStart" in read(SRC / "ServerScriptService/CombatServer.server.lua"),
        "perfect_combo": "PerfectComboService:Record" in read(SRC / "ServerScriptService/CombatServer.server.lua"),
        "one_time_service": "OneTimeAttackService:TryUse" in read(SRC / "ServerScriptService/CombatServer.server.lua"),
        "mobile_ui": "UserInputService" in read(SRC / "StarterPlayer/StarterPlayerScripts/CombatClient.client.lua"),
    }
    missing_runtime = [name for name, ok in required_runtime_terms.items() if not ok]
    if missing_runtime:
        fail(f"required runtime integration missing: {', '.join(missing_runtime)}")

    print("PASS: 24 characters present and unique")
    print("PASS: CharacterDefinitions and CharacterService cover all characters")
    print("PASS: domain declarations validated")
    print("PASS: CharacterFactory exposes the required action surface")
    print("PASS: universal energy meter references absent")
    print("PASS: critical stub markers absent")
    print("PASS: Rojo project mappings validated")
    print("PASS: server-authoritative runtime integrations detected")
    print("NOT VERIFIED: Roblox Studio gameplay, replication under live physics, animation/assets, exploit testing, and publishing")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
