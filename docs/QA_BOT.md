# Collision Battlestar QA Bot

The experience now contains an owner-only runtime QA bot. It checks the real PlayerGui, safe-area bounds, core HUD panels, mobile branch, combat requests, the server dummy, and screenshot capture. The result is displayed in an on-screen detector panel and sent to the server.

The server keeps the latest JSON report in ServerStorage.CollisionQALatest. When HTTP requests are enabled and the Roblox Secret Store contains GITHUB_QA_TOKEN, the server sends a GitHub repository_dispatch event. GitHub Actions records the report in qa/results/latest.json and qa/results/latest.md, then the AI review workflow can create qa/results/ai_review.md using GEMINI_API_KEY.

Roblox's current documentation recommends CoreUISafeInsets for important interactive ScreenGui content and recommends using MicroProfiler and event-driven updates when diagnosing performance. See:

- https://create.roblox.com/docs/reference/engine/enums/ScreenInsets
- https://create.roblox.com/docs/tutorials/use-case-tutorials/ui/create-hud-meters
- https://create.roblox.com/docs/performance-optimization/improve
- https://create.roblox.com/docs/performance-optimization/microprofiler
- https://create.roblox.com/docs/cloud-services/secrets
- https://create.roblox.com/docs/pt-br/cloud-services/http-service

Combat architecture references checked during the rebuild include ShapecastHitbox, AMS, and TopbarPlus:

- https://github.com/TeamSwordphin/ShapecastHitbox
- https://github.com/hatmatty/AMS
- https://github.com/1ForeverHD/TopbarPlus

These are used as implementation and interaction references, not copied branding or proprietary game code.
