from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
IDS = (ROOT / "src/RoubeUmAnimal/ReplicatedStorage/Shared/MonetizationIds.lua").read_text(encoding="utf-8")
CLIENT = (ROOT / "src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua").read_text(encoding="utf-8")
PASS_SERVICE = (ROOT / "src/RoubeUmAnimal/ServerScriptService/Services/PassService.lua").read_text(encoding="utf-8")
PRODUCT_SERVICE = (ROOT / "src/RoubeUmAnimal/ServerScriptService/Services/StackableProductService.lua").read_text(encoding="utf-8")

blocks = {}
for section in ("Passes", "Products"):
    match = re.search(rf"{section} = table\.freeze\(\{{(.*?)\}}\)", IDS, re.S)
    assert match, f"{section} registry missing"
    blocks[section] = dict((name, int(value)) for name, value in re.findall(r"(\w+)\s*=\s*(\d+)", match.group(1)))

assert set(blocks["Passes"]) == {"DoubleIncome", "DoubleSpeed", "VIPFarm", "ExtraBarnSlots"}
assert set(blocks["Products"]) == {"SpeedBoost", "CoinBundle"}
configured = [value for section in blocks.values() for value in section.values() if value > 0]
assert len(configured) == len(set(configured)), "Nonzero gamepass/product IDs must be unique"
assert all(value >= 0 for section in blocks.values() for value in section.values()), "Monetization IDs cannot be negative"
assert all(key in PASS_SERVICE for key in ("DoubleIncome", "DoubleSpeed", "VIPFarm", "ExtraBarnSlots"))
assert all(key in PRODUCT_SERVICE for key in ("SpeedBoost", "CoinBundle", "ProcessReceipt", "PurchaseId", "PurchaseGranted", "NotProcessedYet"))
assert all(key in CLIENT for key in ("PROFIT FARM", "QUICK ESCAPE", "VIP FARM", "EXPANDED BARN", "+5,000 COINS"))
print("PASS monetization registry: distinct permanent benefits, repeatable products and unique nonzero IDs.")
