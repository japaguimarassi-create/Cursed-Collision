from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
IDS = (ROOT / "src/RoubeUmAnimal/ReplicatedStorage/Shared/MonetizationIds.lua").read_text(encoding="utf-8")
CLIENT = (ROOT / "src/RoubeUmAnimal/StarterPlayer/StarterPlayerScripts/GameClient.client.lua").read_text(encoding="utf-8")
SHELL = (ROOT / "src/RoubeUmAnimal/ServerScriptService/CoreShell.server.lua").read_text(encoding="utf-8")
KERNEL = (ROOT / "src/RoubeUmAnimal/ServerScriptService/Services/CoreKernel.lua").read_text(encoding="utf-8")
PRODUCT_SERVICE = (ROOT / "src/RoubeUmAnimal/ServerScriptService/Services/StackableProductService.lua").read_text(encoding="utf-8")
PASS_SERVICE = ROOT / "src/RoubeUmAnimal/ServerScriptService/Services/PassService.lua"

assert "Passes" not in IDS, "Gamepass registry must be removed"
assert not PASS_SERVICE.exists(), "Gamepass service must be deleted"
assert all(token not in CLIENT + SHELL + KERNEL for token in (
    "RequestGamepass", "PromptGamepass", "PromptGamePassPurchase", "UserOwnsGamePassAsync",
    "DoubleIncome", "DoubleSpeed", "VIPFarm", "HasExtraBarnSlots"
)), "Runtime must not contain gamepass behavior"

match = re.search(r"Products = table\.freeze\(\{(.*?)\}\)", IDS, re.S)
assert match, "Developer product registry missing"
products = dict((name, int(value)) for name, value in re.findall(r"(\w+)\s*=\s*(\d+)", match.group(1)))
assert set(products) == {"SpeedBoost", "CoinBundle"}
configured = [value for value in products.values() if value > 0]
assert len(configured) == len(set(configured)), "Nonzero developer product IDs must be unique"
assert all(value >= 0 for value in products.values()), "Developer product IDs cannot be negative"
assert all(key in PRODUCT_SERVICE for key in ("SpeedBoost", "CoinBundle", "ProcessReceipt", "PurchaseId", "PurchaseGranted", "NotProcessedYet"))
assert all(key in CLIENT for key in ("OPTIONAL DEVELOPER PRODUCTS", "+5,000 COINS", "renderShop"))
print("PASS monetization: no gamepasses; optional repeatable developer products remain server-validated.")
