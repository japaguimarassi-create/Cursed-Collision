# Cursed Collision Runtime Upgrade

## Runtime changes

- Added an AnimationConstraint-capable procedural animation backend for upgraded R15 rigs.
- Kept the existing Motor6D animation backend intact for legacy-compatible rigs.
- Added client-side PreSimulation pose application for AnimationConstraint characters.
- Added movement state coverage for idle, walking, running, sprinting, jumping, and falling.
- Added attack coverage for the four-hit M1 chain, character skill patterns, dash, reactions, awakening, and transformed poses.
- Enabled workspace instance streaming and selected an aggressive target radius for the large urban map.

## Design rules

Gameplay authority remains on the server. Client animation and VFX only present the server-confirmed combat state. Server hit validation continues to use spatial queries and marker windows.

Roblox recommends server-side spatial queries when the result must reflect the complete world, and recommends instance streaming for large worlds and resource-constrained devices. AnimationConstraint is now the default joint type on upgraded R15 avatars, so the project no longer assumes Motor6D is the only procedural joint backend.

