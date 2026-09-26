from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]

for relative in (
    ".github/workflows/hud-ai.yml",
    ".github/workflows/qa-ai-review.yml",
    ".github/workflows/qa-self-heal.yml",
    "tools/hud_ai_generator.py",
    "tools/self_heal.py",
):
    if (ROOT/relative).exists():
        print("FAIL: AI-specific project file remains:", relative)
        sys.exit(1)

for base in (ROOT/".github/workflows", ROOT/"tools"):
    if not base.exists():
        continue
    for path in base.rglob("*"):
        if "__pycache__" in path.parts or not path.is_file():
            continue
        text=path.read_text(encoding="utf-8",errors="ignore").lower()
        blocked=("gemini_api_key","gemini-","openai_api_key","HUD_AI_PIPELINE","qa-ai-review")
        if path == ROOT/"tools"/"validate_no_ai.py":
            continue
        if any(token in text for token in blocked):
            print("FAIL: AI integration marker remains:", path.relative_to(ROOT))
            sys.exit(1)

print("PASS: no AI runtime/workflow integration")
