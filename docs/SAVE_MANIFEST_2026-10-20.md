# Save manifest — total rebuild (2026-10-20)

Before replacing the default branch, immutable-in-history backup refs were created:

- `saves/main-before-total-rebuild-20261020` → original main commit `7c0c567554ac0de5bc2d6cec582d7a71cb888092`
- `saves/r7-before-total-rebuild-20261020` → validated r7 source commit `63ff68f22c539c7687c7b56fe7cd6beabe8d9239`
- `rebuild/steal-an-egg-total-rebuild-20261020` → working reconstruction branch, derived from the validated r7 source.

Git stores each saved commit and its tree. The gamepass configuration is intentionally excluded from edits: `.github/gamepasses/provision.json`, `gamepasses/manifest.json`, and the existing pass service/ID files are retained byte-for-byte in the rebuilt repository tree.

Original main SHA: `7c0c567554ac0de5bc2d6cec582d7a71cb888092`
Original r7 SHA: `63ff68f22c539c7687c7b56fe7cd6beabe8d9239`
