# Cursed Collision

Cursed Collision is being rebuilt as a clean-room Roblox PvP battleground.

## Current build

The active rebuild foundation intentionally exposes only:

- M1 four-hit chain
- Directional Dash
- Block
- One character-specific Special

Heavy, Dodge, Grab, Counter, Slam, Domain, Awakening, Domain Clash and One-Time Attack are not part of this foundation.

## First character

The first playable character is **Potential Man**, the new in-game identity replacing the earlier Megumi slot.

His initial Special is an original move called **Shadow Potential**.

## Technical architecture

The project is written in Roblox Luau and uses a Rojo-compatible source tree.

Server authority:
- hitbox queries
- damage
- blocking
- stun
- combo state
- cooldowns
- dash invulnerability
- input validation
- anti-spam validation

Client responsibility:
- input
- HUD
- local animation presentation

The animation foundation currently uses procedural Motor6D transforms. Published Roblox Animation assets can be integrated later when actual authored keyframe assets are available.

## Rebuild policy

Jujutsu Shenanigans and The Strongest Battlegrounds are reference material for observing combat presentation, pacing, framing and visual language. Their source code is not used as implementation material.

The project will add characters one at a time so each move can be implemented, tested and corrected independently.

## Verification

Static repository validation can run in GitHub Actions. Actual Roblox runtime behavior, replication, animation fidelity, asset availability and mobile performance require play-testing in Roblox.