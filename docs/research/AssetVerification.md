# Collision Battlestar — Asset Verification Ledger

Research checkpoint: 2026-09-26

## Runtime-approved map assets

| Asset | ID | License / permission evidence | Budget | Slot |
|---|---:|---|---:|---|
| Bench | 400850371 | Creator Store description says it is a free bench model | 228 tris | Park seating |
| Dumpster Free | 42942436 | Creator Store item is explicitly named Dumpster Free | 82 tris | Alley clutter |
| Small Blocky Car | 282662596 | Creator Store title explicitly marks it [FREE!] | 792 tris | Street parking |

Sources:
- https://create.roblox.com/store/asset/400850371/Bench
- https://create.roblox.com/store/asset/42942436/Dumpster-Free
- https://create.roblox.com/store/asset/282662596/FREE-Small-Blocky-Car

The runtime loader sanitizes loaded models and the procedural Battle Line remains the default map. Roblox documents
that AssetService:LoadAssetAsync can load public free third-party assets only when Allow Loading Third Party Assets
is enabled; otherwise calls may fail, so the fallback geometry is intentionally preserved.
Source: https://create.roblox.com/docs/reference/engine/classes/AssetService

## Runtime-approved audio

| Asset | ID | Permission evidence | Duration shown | Slot |
|---|---:|---|---:|---|
| Punch Sound Effect Sfx 2 | 9075325599 | Creator Store title explicitly says free to use | short | Light/Hit |
| Thud | 1198923651 | Creator Store description says feel free to use | 0:00 | Heavy/Parry |
| bounce sound effect | 1885641628 | Creator Store description says feel free to use | 0:01 | Dash |
| User Interface / Glass Style Button Click | 82845990304289 | Creator Store description says Free to use | 0:02 | UI/Map |

Sources:
- https://create.roblox.com/store/asset/9075325599/Punch-Sound-Effect-Sfx-2-free-to-use
- https://create.roblox.com/store/asset/1198923651
- https://create.roblox.com/store/asset/1885641628/bounce-sound-effect
- https://create.roblox.com/store/asset/82845990304289/User-Interface-Glass-Style-Button-Click

Roblox's official audio documentation states that the Creator Store contains free-to-use audio and that imported audio
should only be used when the creator has permission.
Source: https://create.roblox.com/docs/audio/assets

## Animation verification

The following public/free Creator Store pages were verified as animation packs/models:
- https://create.roblox.com/store/asset/75164220659481/Fists-Combat-Animation-Pack-R6-Punch-Fighting
- https://create.roblox.com/store/asset/13081191834/R6-Punch-Animation

They do not expose a child Animation asset ID in the public page data used by this audit, and the active repository
does not declare whether the player avatar is R6 or R15. Roblox's animation documentation says the rig is an
important design decision because the body structure directly affects the animation. For safety, no unverified
AnimationId was inserted. All twelve slots use the existing procedural fallback.
Source: https://create.roblox.com/docs/tutorials/use-case-tutorials/animation/create-an-animation

## Mobile budget rule

Runtime-approved models are kept under 1,000 triangles each in this pass. The larger catalog entries remain research
references only, including the 66k-triangle street pack and the 796k-triangle modular building kit.