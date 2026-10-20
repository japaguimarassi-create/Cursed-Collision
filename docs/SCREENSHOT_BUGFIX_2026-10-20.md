# Screenshot bugfix log — 2026-10-20

Changes prepared on `fix/screenshot-overlap-20261020` for the in-game issues shown in the uploaded captures.

- World billboards are smaller, use fixed readable text sizes, are occluded by world geometry, and have explicit maximum viewing distances.
- Removed billboard labels from empty farm slots; stored animals keep a compact close-range label.
- The Swan guardian uses a white chest and its dedicated neck/head without the duplicate oversized orange muzzle or mammal ears/legs.
- The top objective bar is narrower.
- Proximity prompts use a compact client-side card so treadmill/deposit/collect/steal interactions do not cover the middle of the screen. Hold prompts are routed through `InputHoldBegin` / `InputHoldEnd`.
- BotX nameplates are smaller and occluded; one observer remains beside the nearest player while the other two patrol biomes and collect session observations.
- Added source-level regression checks for label collisions, prompt wiring, and visible BotX behavior.

## Validation boundary

The changes are in the Git branch named above. Source-level tests and the Rojo build must pass in GitHub Actions. The Roblox Studio client/engine has not been run from this environment, so the appearance, touch-hold behavior, and NPC movement still need the generated Studio audit report or an in-game capture. The production publishing workflow remains manual and confirmation-gated.
