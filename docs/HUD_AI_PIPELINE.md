# Collision Battlestar HUD AI

The generator in tools/hud_ai_generator.py performs the requested visual-selection pipeline.

It accepts up to four supplied HUD reference images, generates 100 diversified HUD candidates by default, evaluates them in batches of ten with a separate visual critic, ranks them, copies the ten highest-scoring candidates into finalists, then sends those ten finalist images back as references for one final synthesis.

Outputs:
- candidates/candidate_001.png through candidate_100.png
- finalists/finalist_01.png through finalist_10.png
- selection.json
- collision_battlestar_hud_final.png

Configuration:
- primary image model: gemini-3.1-flash-image
- critic model: gemini-3.8-flash
- default candidates: 100
- default finalists: 10
- default parallel workers: 3

The API key is never stored in the repository. Configure GEMINI_API_KEY in the environment before running.

Example command:

python3 tools/hud_ai_generator.py --references ./references/hud --output ./build/hud-ai

The generator uses the current Gemini Interactions API with multiple image inputs. The final synthesis uses the ten selected candidates as references and keeps the permanent combat language at M1, DASH, BLOCK and SPECIAL.

Google currently lists the image-generation models with no API Free Tier for image output. Therefore the repository does not claim that 100 image generations through the Gemini API are free. The script must only be run with an account/quota policy that you have confirmed is acceptable.