# Collision Battlestar Runtime Architecture

Updated: 2026-09-26

## Runtime model

- Rojo compiles only `src/CollisionBattlestar/*`.
- Gameplay authority stays server-side.
- Client animation, audio and VFX present server-confirmed actions.
- The default world is procedural and remains playable when optional asset loading fails.

## Animation

AnimationClient caches configured AnimationTracks, cross-fades between action tracks and records the live Humanoid.RigType as a player attribute.

The active source does not explicitly pin R6 or R15. The procedural fallback therefore uses compatible Motor6D name lookup and remains available until direct public Roblox AnimationIds are verified.

## VFX

VFXController uses a shared effect budget from VFXDefinitions. Impact bursts, expanding waves, blade-style beams and Reality Break environment response are all client-side presentation.

## Map

Battle Line contains seven districts along one continuous route. Streaming is enabled and MapTravelService requests the destination region before Character:PivotTo.

## Asset fallback

MapDecorationService creates procedural details first. Approved public Creator Store props are then loaded asynchronously into a separate folder. Failed loads do not remove or delay the procedural map.

## Performance

The code avoids per-frame gameplay remotes. Persistent presentation loops are small, and short-lived VFX are capped by MaxEffects.


HUD recovery v2 includes direct reconstruction when the runtime HUD controller does not materialize.
