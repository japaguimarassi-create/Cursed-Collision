from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "src/StealAnAnimal"
SOURCES = [
    BASE / "ServerScriptService/Main.server.lua",
    BASE / "StarterPlayer/StarterPlayerScripts/GameClient.client.lua",
    BASE / "ReplicatedStorage/Shared/Config.lua",
]
content = "\n".join(path.read_text(encoding="utf-8") for path in SOURCES)
for token in (
    "MarketplaceService", "PromptGamePassPurchase", "UserOwnsGamePassAsync",
    "RequestGamepass", "PromptGamepass", "VIPFarm", "DoubleIncome",
    "DoubleSpeed", "HasExtraBarnSlots", "Developer Product",
):
    assert token not in content, f"Fresh game runtime must not include monetization feature: {token}"
assert "StealAnimalRemotes" in content
print("PASS Monetization: the fresh game contains no gamepasses or purchase prompts.")
