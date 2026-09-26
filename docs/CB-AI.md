# Collision Battlestar AI Repair Agent

tools/cb_ai.py is the repository-local self-repair agent.

## One command

Set the API key once in the shell:

    export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"

Then, from the repository root:

    python3 tools/cb_ai.py

The agent uses only Python's standard library.

## Optional settings

    CB_AI_MODEL=gemini-3.8-flash
    CB_AI_ROUNDS=5

You may copy .cb-ai.json.example to .cb-ai.json for non-secret settings.
Never put an API key into a tracked repository file.

## Operation

The agent:
1. Confirms it is inside the Git repository.
2. Reads local source and project configuration.
3. Runs tools/validate_project.py and git diff --check.
4. Runs Rojo build when Rojo is available.
5. Sends the local source snapshot to the Gemini API.
6. Accepts only create/update operations under approved paths.
7. Saves local backups under .cb-ai/backups/.
8. Revalidates after edits.
9. Repeats until valid or the round limit is reached.

The model cannot request arbitrary shell commands through the agent.
The agent never writes outside the repository.
The repair loop itself does not access GitHub.
Its only network request is the Gemini API call used for analysis.

## Luau knowledge

tools/CB_AI_LuauKnowledge.md is included in every repair request and contains the project's Roblox/Luau repair rules.
