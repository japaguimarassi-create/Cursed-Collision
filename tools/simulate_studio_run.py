#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REPORT = ROOT / "artifacts" / "studio-run-simulation.json"
DEFAULT_MARKDOWN = ROOT / "artifacts" / "studio-run-simulation.md"


def read_text(relative):
    return (ROOT / relative).read_text(encoding="utf-8")


def sha256_file(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def walk_tree(node, output):
    if not isinstance(node, dict):
        return
    class_name = node.get("ClassName")
    name = node.get("Name")
    if class_name or name:
        output.append({"className": class_name, "name": name, "path": node.get("Path")})
    for child in node.get("Children", []):
        walk_tree(child, output)


def number_from(pattern, text, cast=int, default=None):
    match = re.search(pattern, text)
    return cast(match.group(1)) if match else default


def clamp(value, minimum, maximum):
    return min(max(value, minimum), maximum)


class Audit:
    def __init__(self):
        self.results = []
        self.layouts = []
        self.warnings = []

    def check(self, name, condition, detail, evidence=None):
        item = {"name": name, "status": "PASS" if bool(condition) else "FAIL", "detail": str(detail)}
        if evidence:
            item["evidence"] = evidence
        self.results.append(item)
        print(f"[SIMULATED_STUDIO_RUN][{item['status']}] {name} — {detail}")
        return bool(condition)

    def warning(self, name, detail):
        item = {"name": name, "status": "WARN", "detail": str(detail)}
        self.results.append(item)
        self.warnings.append(item)
        print(f"[SIMULATED_STUDIO_RUN][WARN] {name} — {detail}")


def simulate_hud(audit, client, screen_profiles):
    top_y = number_from(r'top\.Position\s*=\s*UDim2\.new\(0\.5,\s*0,\s*0,\s*(\d+)\)', client)
    top_h = number_from(r'top\.Size\s*=\s*UDim2\.new\(0\.66,\s*0,\s*0,\s*(\d+)\)', client)
    top_min_w = number_from(r'topConstraint\.MinSize\s*=\s*Vector2\.new\((\d+),\s*68\)', client)
    top_max_w = number_from(r'topConstraint\.MaxSize\s*=\s*Vector2\.new\((\d+),\s*68\)', client)
    objective_y = number_from(r'objective\.Position\s*=\s*UDim2\.new\(0\.5,\s*0,\s*0,\s*(\d+)\)', client)
    objective_h = number_from(r'objective\.Size\s*=\s*UDim2\.new\(0\.68,\s*0,\s*0,\s*(\d+)\)', client)
    objective_min_w = number_from(r'objectiveConstraint\.MinSize\s*=\s*Vector2\.new\((\d+),\s*24\)', client)
    objective_max_w = number_from(r'objectiveConstraint\.MaxSize\s*=\s*Vector2\.new\((\d+),\s*24\)', client)
    dock_w = number_from(r'dock\.Size\s*=\s*UDim2\.new\(0,\s*(\d+),\s*0,\s*140\)', client)
    dock_h = number_from(r'dock\.Size\s*=\s*UDim2\.new\(0,\s*52,\s*0,\s*(\d+)\)', client)
    dock_x = number_from(r'dock\.Position\s*=\s*UDim2\.new\(0,\s*(\d+),\s*0,\s*y\)', client)
    touch_y = number_from(r'local y\s*=\s*touchDevice and\s*(\d+)\s+or\s*(\d+)', client)
    target = re.search(r'button\.Size\s*=\s*UDim2\.new\(0,\s*(\d+),\s*0,\s*(\d+)\)', client)
    target_w = int(target.group(1)) if target else None
    target_h = int(target.group(2)) if target else None

    parsed = all(value is not None for value in (
        top_y, top_h, top_min_w, top_max_w, objective_y, objective_h,
        objective_min_w, objective_max_w, dock_w, dock_h, dock_x,
        touch_y, target_w, target_h,
    ))
    audit.check(
        "HUD geometry constants can be read from source",
        parsed,
        "All layout constants required by the source-level model were parsed" if parsed else "A required HUD layout expression changed; update the simulator instead of silently guessing",
        "src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua",
    )
    if not parsed:
        return

    audit.check("HUD uses Roblox safe insets",
        "Enum.ScreenInsets.CoreUISafeInsets" in client,
        "ScreenGui uses CoreUISafeInsets", "GameClient.client.lua")
    audit.check("HUD removes the old permanent bottom bar",
        "ActionDock" not in client,
        "No obsolete ActionDock name remains", "GameClient.client.lua")
    audit.check("Quick actions have mobile-sized hit targets",
        target_w >= 44 and target_h >= 44,
        f"Source-defined quick action target is {target_w}x{target_h}px; modeled minimum is 44x44px",
        "GameClient.client.lua")
    audit.check("Shop, Index, and More each have active click connections",
        all(token in client for token in (
            'upgradeButton.Activated:Connect(function() openPanel("Shop") end)',
            'indexButton.Activated:Connect(function() openPanel("AnimalIndex") end)',
            'moreButton.Activated:Connect(function() openPanel("More") end)',
        )),
        "Each visible quick action has a handler", "GameClient.client.lua")
    audit.check("Rebirth badge opens the requirements panel",
        'rebirthBadge.Activated:Connect(function() openPanel("Rebirth") end)' in client,
        "Rebirth badge is wired to the panel without executing rebirth", "GameClient.client.lua")
    audit.check("Escape state has an explicit contextual objective",
        '"FUGA • LEVE O ANIMAL AO PAD VERDE DA SUA FAZENDA"' in client
        and "objectiveMarker.BackgroundColor3 = COLORS.Orange" in client,
        "Carrying an animal selects the escape message and orange marker", "GameClient.client.lua")

    for profile in screen_profiles:
        width, height, touch = profile["width"], profile["height"], profile["touch"]
        scale = 1.0 if touch else clamp(width / 1100.0, 0.82, 1.12)
        rendered_top_w = clamp(width * 0.66, top_min_w, top_max_w) * scale
        rendered_top_h = top_h * scale
        rendered_top_x = (width - rendered_top_w) / 2
        rendered_top_y = top_y * scale
        rendered_obj_w = clamp(width * 0.68, objective_min_w, objective_max_w) * scale
        rendered_obj_h = objective_h * scale
        rendered_obj_x = (width - rendered_obj_w) / 2
        rendered_obj_y = objective_y * scale
        non_touch_y = number_from(r'local y\s*=\s*touchDevice and\s*\d+\s+or\s*(\d+)', client, default=56)
        rendered_dock_w = dock_w * scale
        rendered_dock_h = dock_h * scale
        rendered_dock_x = dock_x * scale
        rendered_dock_y = (touch_y if touch else non_touch_y) * scale
        top_right = rendered_top_x + rendered_top_w
        top_bottom = rendered_top_y + rendered_top_h
        obj_right = rendered_obj_x + rendered_obj_w
        obj_bottom = rendered_obj_y + rendered_obj_h
        dock_right = rendered_dock_x + rendered_dock_w
        dock_bottom = rendered_dock_y + rendered_dock_h
        checks = {
            "headerInsideViewport": rendered_top_x >= -0.5 and top_right <= width + 0.5,
            "objectiveInsideViewport": rendered_obj_x >= -0.5 and obj_right <= width + 0.5,
            "quickActionsInsideViewport": rendered_dock_x >= 0 and dock_right <= width,
            "headerDoesNotOverlapObjectiveVertically": rendered_obj_y >= top_bottom,
            "objectiveDoesNotOverlapQuickActionsVertically": rendered_dock_y >= obj_bottom,
            "quickActionsClearBottomTouchZone": dock_bottom < height * 0.78,
            "touchTargetAtLeast44x44": target_w * scale >= 44 and target_h * scale >= 44,
        }
        passed = all(checks.values())
        item = {
            "profile": profile["name"],
            "width": width,
            "height": height,
            "touchEnabledInModel": touch,
            "modeledScale": round(scale, 3),
            "status": "PASS" if passed else "FAIL",
            "geometry": {
                "header": {"x": round(rendered_top_x, 2), "y": round(rendered_top_y, 2),
                           "width": round(rendered_top_w, 2), "height": round(rendered_top_h, 2)},
                "objective": {"x": round(rendered_obj_x, 2), "y": round(rendered_obj_y, 2),
                              "width": round(rendered_obj_w, 2), "height": round(rendered_obj_h, 2)},
                "quickActions": {"x": round(rendered_dock_x, 2), "y": round(rendered_dock_y, 2),
                                 "width": round(rendered_dock_w, 2), "height": round(rendered_dock_h, 2),
                                 "bottomClearanceLimit": round(height * 0.78, 2),
                                 "actualBottom": round(dock_bottom, 2)},
                "touchTarget": {"width": round(target_w * scale, 2), "height": round(target_h * scale, 2)},
            },
            "checks": checks,
        }
        audit.layouts.append(item)
        audit.check("HUD layout model: " + profile["name"], passed,
                    f"{width}x{height} touch={touch}: " + ", ".join(
                        f"{name}={'PASS' if ok else 'FAIL'}" for name, ok in checks.items()),
                    "GameClient.client.lua (deterministic source-level geometry model)")


def main():
    parser = argparse.ArgumentParser(description="Simulate a Studio-like source and HUD audit in CI.")
    parser.add_argument("--report", default=str(DEFAULT_REPORT))
    parser.add_argument("--markdown", default=str(DEFAULT_MARKDOWN))
    parser.add_argument("--place", default=str(ROOT / "build" / "StealAnAnimal.rbxl"))
    args = parser.parse_args()
    report_path, markdown_path, place_path = Path(args.report), Path(args.markdown), Path(args.place)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    markdown_path.parent.mkdir(parents=True, exist_ok=True)

    audit = Audit()
    tracked = [
        "default.project.json",
        "src/StealAnAnimal/ReplicatedStorage/Shared/Config.lua",
        "src/StealAnAnimal/ReplicatedStorage/Shared/AnimalCatalog.lua",
        "src/StealAnAnimal/ReplicatedStorage/Shared/GameplayRules.lua",
        "src/StealAnAnimal/ServerScriptService/Main.server.lua",
        "src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua",
        "src/StealAnAnimal/ServerScriptService/StudioAudit.server.lua",
        "src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/StudioAudit.client.lua",
        "tools/studio-tests/StealAnAnimalAudit.plugin.lua",
    ]
    sources = {}
    for relative in tracked:
        path = ROOT / relative
        exists = path.is_file()
        audit.check("Required source exists: " + relative, exists, "present" if exists else "missing", relative)
        if exists:
            sources[relative] = sha256_file(path)

    try:
        project = json.loads(read_text("default.project.json"))
        config = read_text("src/StealAnAnimal/ReplicatedStorage/Shared/Config.lua")
        catalog = read_text("src/StealAnAnimal/ReplicatedStorage/Shared/AnimalCatalog.lua")
        rules = read_text("src/StealAnAnimal/ReplicatedStorage/Shared/GameplayRules.lua")
        server = read_text("src/StealAnAnimal/ServerScriptService/Main.server.lua")
        client = read_text("src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua")
        studio_server = read_text("src/StealAnAnimal/ServerScriptService/StudioAudit.server.lua")
        studio_client = read_text("src/StealAnAnimal/StarterPlayer/StarterPlayerScripts/StudioAudit.client.lua")
        plugin = read_text("tools/studio-tests/StealAnAnimalAudit.plugin.lua")
        studio_docs = read_text("docs/STUDIO_AUTOMATED_AUDIT.md")
    except OSError as error:
        audit.check("All audited sources are readable", False, error)
        project = {}
        config = catalog = rules = server = client = studio_server = studio_client = plugin = studio_docs = ""

    ids = sorted(set(re.findall(r'Id\s*=\s*"([A-Za-z0-9]+)"', catalog)))
    biomes = re.findall(r'Id\s*=\s*"([A-Za-z]+)"\s*,\s*Name\s*=', config)
    phases = [int(value) for value in re.findall(r'Phase\s*=\s*(\d+)\s*,\s*CenterX\s*=', config)]
    audit.check("Animal catalog retains at least 28 unique species", len(ids) >= 28, f"Found {len(ids)} species")
    audit.check("Config defines eight sequential biomes", len(biomes) == 8 and phases == list(range(1, 9)),
                f"Biomes={biomes}; phases={phases}")
    audit.check("Every configured biome has catalog coverage",
                "ForBiome" in catalog and all(biome in catalog for biome in biomes),
                "Catalog provides ForBiome and contains all eight configured biome IDs")
    audit.check("Gameplay rules include capped movement and rebirth",
                all(token in rules for token in ("function Rules.MoveSpeed", "function Rules.RebirthCost", "function Rules.RebirthSpeedRequirement")),
                "MoveSpeed, RebirthCost, and RebirthSpeedRequirement found")
    audit.check("World construction retains eight-farm map and interaction landmarks",
                all(token in server for token in ("basePositions = {", "function createBase(index)", '"DepositPad"', '"CollectPad"',
                                                   '"TrainingZone"', "function makeGuardian(spec, biome)", "StealAnimalRemotes")),
                "Farm factory, deposit/collect pads, treadmill zone, guardian factory, and remotes found")
    audit.check("Studio QA remains disabled outside Studio and requires opt-in",
                all(token in studio_server for token in ('if not RunService:IsStudio() then return end',
                                                          'Workspace:GetAttribute("EnableStealAnimalAudit") ~= true then return end'))
                and all(token in studio_client for token in ('if not RunService:IsStudio() then return end',
                                                              'Workspace:GetAttribute("EnableStealAnimalAudit") ~= true then return end')),
                "Both runtime audit scripts are Studio-gated")
    audit.check("Studio tests use an isolated DataStore",
                'RunService:IsStudio() and "StealAnAnimal_StudioSandbox_v1" or "StealAnAnimal_FreshProfile_v1"' in config,
                "Studio and published profile stores have separate names")
    audit.check("Studio launcher creates two simulated clients",
                'StudioTestService:ExecuteMultiplayerTestAsync(2, "StealAnAnimalAudit-v1")' in plugin,
                "Plugin creates two Studio test clients")
    audit.check("Audit report collects client tests and exports JSON",
                all(token in studio_server for token in ("clientReports", "HttpService:JSONEncode(summary)",
                                                         "[STEAL_ANIMAL_AUDIT_REPORT]", "StudioTestService:EndTest(encoded)"))
                and 'reportRemote:FireServer(report)' in studio_client,
                "Client details are sent to server and returned as structured JSON")
    audit.check("Test bots avoid economy-changing client actions",
                all(token not in studio_client for token in ("collectRemote:FireServer()", "rebirthRemote:FireServer()", "upgradeRemote:FireServer()")),
                "No test click collects currency, purchases upgrades, or confirms rebirth")
    audit.check("Studio run instructions document report retrieval",
                all(token in studio_docs for token in ("Run Studio Audit", "[STEAL_ANIMAL_AUDIT_REPORT]", "StudioSandbox", "Device Simulator")),
                "Documentation includes execution, report, and mobile emulation steps")

    parts = []
    names = []
    try:
        model = json.loads(read_text("src/StealAnAnimal/Workspace/StealAnAnimalWorld.model.json"))
        nodes = []
        walk_tree(model, nodes)
        parts = [node for node in nodes if node["className"] == "Part"]
        names = [node["name"] for node in nodes if isinstance(node["name"], str)]
        farms = sorted({name for name in names if re.fullmatch(r"Farm_[1-8]", name)})
        audit.check("Static map preview parses as JSON", True, f"Root={model.get('Name', model.get('ClassName'))}")
        audit.check("Static map preview includes at least 300 Parts", len(parts) >= 300, f"Part count={len(parts)}")
        audit.check("Static preview includes all eight farms", farms == [f"Farm_{i}" for i in range(1, 9)], f"Farm markers={farms}")
        required_landmarks = ("CorridorFloor", "MainPath", "Farm_8", "TreadmillBelt", "GuardianParent_Ocean")
        absent = [name for name in required_landmarks if name not in names]
        audit.check("Static map landmarks exist", not absent,
                    "All required landmarks found" if not absent else "Missing: " + ", ".join(absent))
    except (OSError, json.JSONDecodeError) as error:
        audit.check("Static map preview parses as JSON", False, error)

    place_result = None
    if place_path.is_file() and place_path.stat().st_size > 0:
        try:
            place_name = str(place_path.relative_to(ROOT))
        except ValueError:
            place_name = str(place_path)
        place_result = {"path": place_name, "bytes": place_path.stat().st_size, "sha256": sha256_file(place_path)}
        audit.check("Compiled RBXL exists and is non-empty", True,
                    f"{place_result['bytes']} bytes; sha256={place_result['sha256']}", place_name)
    else:
        audit.check("Compiled RBXL exists and is non-empty", False, f"Missing build artifact: {place_path}")

    screen_profiles = [
        {"name": "Phone small portrait", "width": 320, "height": 568, "touch": True},
        {"name": "Android portrait", "width": 360, "height": 800, "touch": True},
        {"name": "Large phone portrait", "width": 430, "height": 932, "touch": True},
        {"name": "Phone landscape", "width": 844, "height": 390, "touch": True},
        {"name": "Tablet landscape", "width": 1024, "height": 768, "touch": True},
        {"name": "Desktop window", "width": 1366, "height": 768, "touch": False},
    ]
    simulate_hud(audit, client, screen_profiles)

    passed = [item for item in audit.results if item["status"] == "PASS"]
    failed = [item for item in audit.results if item["status"] == "FAIL"]
    warnings = [item for item in audit.results if item["status"] == "WARN"]
    farm_markers = sorted({name for name in names if re.fullmatch(r"Farm_[1-8]", name)})
    report = {
        "schemaVersion": 1,
        "suite": "StealAnAnimalSimulatedStudioRun",
        "mode": "source_and_layout_simulation",
        "status": "FAIL" if failed else "PASS_SIMULATION_WITH_LIMITS",
        "executedAt": datetime.now(timezone.utc).isoformat(),
        "commit": os.environ.get("GITHUB_SHA", "local"),
        "counts": {"passed": len(passed), "failed": len(failed), "warnings": len(warnings), "layoutProfiles": len(audit.layouts)},
        "studioRuntimeExecuted": False,
        "simulatedStudioClients": [
            {"name": "QA-Bot-Phone-Portrait", "role": "modeled_client_profile", "width": 360, "height": 800, "touch": True},
            {"name": "QA-Bot-Phone-Landscape", "role": "modeled_client_profile", "width": 844, "height": 390, "touch": True},
        ],
        "checks": audit.results,
        "layoutProfiles": audit.layouts,
        "sourceSha256": sources,
        "compiledPlace": place_result,
        "map": {"partCount": len(parts), "namedFarmMarkers": farm_markers},
        "limits": [
            "This is a deterministic source-level simulation, not an executed Roblox Studio session.",
            "It models HUD geometry from source constants; it does not render Roblox UI or measure Roblox AbsolutePosition.",
            "It does not execute physics, ProximityPrompt triggering, DataStore calls, client/server replication, or live RemoteEvents.",
            "The StudioTestService plugin and runtime bots must still be run inside Roblox Studio for engine-level evidence.",
            "TouchEnabled is modeled for device profiles; actual Device Simulator state is not changed by this script.",
        ],
        "nextStep": "Download studio-run-simulation.json from the GitHub Actions artifact. For actual runtime evidence, run the Studio plugin and provide [STEAL_ANIMAL_AUDIT_REPORT] JSON.",
    }
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = [
        "# Steal An Animal — simulated Studio run",
        "",
        f"- **Status:** {report['status']}",
        f"- **Commit:** {report['commit']}",
        f"- **Checks:** {len(passed)} passed, {len(failed)} failed, {len(warnings)} warnings",
        f"- **HUD profiles:** {len(audit.layouts)}",
        f"- **Map preview Parts:** {len(parts)}",
        "- **Studio runtime executed:** no — this report is a source/layout simulation",
        "",
        "## Results",
        "",
        "| Status | Check | Detail |",
        "|---|---|---|",
        *[f"| {item['status']} | {item['name'].replace('|', '/')} | {item['detail'].replace('|', '/')} |" for item in audit.results],
        "",
        "## Simulated screen profiles",
        "",
        "| Profile | Viewport | Status | Checks |",
        "|---|---:|---|---|",
    ]
    for layout in audit.layouts:
        bad = [name for name, ok in layout["checks"].items() if not ok]
        lines.append(f"| {layout['profile']} | {layout['width']}×{layout['height']} | {layout['status']} | "
                     + ("All geometry checks passed" if not bad else ", ".join(bad)) + " |")
    lines.extend(["", "## Limits", ""])
    lines.extend(f"- {item}" for item in report["limits"])
    lines.extend(["", "## How to obtain the real Studio report", "", report["nextStep"], ""])
    markdown_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"[SIMULATED_STUDIO_RUN] report={report_path}")
    print(f"[SIMULATED_STUDIO_RUN] markdown={markdown_path}")
    print(f"[SIMULATED_STUDIO_RUN] status={report['status']} passed={len(passed)} failed={len(failed)} warnings={len(warnings)}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
