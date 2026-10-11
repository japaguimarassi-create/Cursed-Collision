from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
IDS = (ROOT / "src/RoubeUmAnimal/ReplicatedStorage/Shared/MonetizationIds.lua").read_text(encoding="utf-8")

blocks = {}
for section in ("Passes", "Products"):
    match = re.search(rf"{section} = table\.freeze\(\{{(.*?)\}}\)", IDS, re.S)
    assert match, f"{section} registry missing"
    blocks[section] = dict((name, int(value)) for name, value in re.findall(r"(\w+)\s*=\s*(\d+)", match.group(1)))

assert set(blocks["Passes"]) == {"DoubleSpeed", "DoubleStrength", "DoubleCoins", "VIPSpeed"}
assert set(blocks["Products"]) == {"StackableSpeed", "StackableStrength"}
configured = [value for section in blocks.values() for value in section.values() if value > 0]
assert len(configured) == len(set(configured)), "Nonzero gamepass/product IDs must be unique"
assert all(value >= 0 for section in blocks.values() for value in section.values()), "Monetization IDs cannot be negative"

print("PASS monetization registry: unique IDs, distinct pass/product keys; zero only marks an unconfigured item")
