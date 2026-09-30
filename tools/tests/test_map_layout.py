from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
SOURCE = (ROOT / "src/CollisionBattlestar/ServerScriptService/Foundation/World/ArenaBuilder.lua").read_text(encoding="utf-8")

def count_calls(name: str) -> int:
    return len(re.findall(r"^\s{4}" + re.escape(name) + r"\s*\(", SOURCE, re.MULTILINE))

assert "CollisionCore" in SOURCE
assert "UpgradeStation" in SOURCE
assert "EnemySpawns" in SOURCE
assert count_calls("addStreetLight") >= 6
assert count_calls("addBarricade") >= 8
assert count_calls("addRaisedPlatform") >= 4
print("PASS MapLayoutSpec")
