# Collision Battlestar animation pipeline

## Runtime architecture

The client obtains the character Humanoid and its Animator. The animation controller creates Animation objects from a small profile catalog, preloads them when possible, calls Animator:LoadAnimation, assigns AnimationPriority, and stores AnimationTracks for reuse.

Action playback is separated by groups:
- Attack
- Special
- Movement
- Reaction

When a new track in a group starts, only the previous track in that group is stopped. Movement and action tracks can therefore coexist without forcing the whole character animation stack to stop.

## Blending rules

M1 clips use Action2 and Special uses Action3. Roblox evaluates higher animation priorities over lower ones; tracks at the same priority can be blended through weights. Collision Battlestar starts clips with a short fade and then adjusts weight and speed so attacks can replace one another without an abrupt pop.

## Runtime safety

Each external animation is loaded inside protected calls. PreloadAsync failures and LoadAnimation failures mark the candidate unavailable for the current character. Missing candidates never break combat because the controller executes the procedural Motor6D fallback.

## Candidate IDs currently included

18576726303 — public battleground combo clip referenced by Roblox Developer Forum discussion.

18576729183 — public battleground combo clip referenced by Roblox Developer Forum discussion.

18576731629 — public battleground combo clip referenced by Roblox Developer Forum discussion.

17866759652 — public punch animation ID shown in a Roblox tutorial.

2515090838 — official Roblox documentation kick example.

The first four are external creator assets and should be treated as candidate IDs rather than guaranteed rights. Roblox documentation states that a published animation receives a unique asset ID and that an animation used by a group-owned experience should be published with the appropriate group as creator. The project therefore keeps the procedural fallback until the experience can validate the candidate asset at runtime.

## Next animation targets

Future profiles should be added incrementally for:
- guard
- hit reaction
- directional dash
- uppercut
- knockdown/recovery

The project should not replace the full locomotion stack until the player rig type and live device behavior are confirmed.
