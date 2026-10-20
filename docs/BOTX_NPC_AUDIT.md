# BotX — humanoid observer NPCs

## What they are

BotX adds three autonomous non-player characters: `bot1`, `bot2`, and `bot3`. Each is a server-created R6 Humanoid with custom Bacon Hair, a visible face, a cyan chest badge, a nameplate, and a restrained Highlight outline. Their initial positions are spread around the real player rather than stacked on one point. They are Workspace models, not accounts or `Player` objects, so they do not count toward the server player limit.

## Runtime contract

- No real players: no BotX NPCs are spawned.
- At least one real player: start a session and spawn all three NPCs.
- Active session: NPCs patrol the configured biomes using server-side pathfinding and capture structured gameplay observations.
- Last real player leaves: emit the final session report and destroy all BotX models. A future player starts a new session.
- Bot actions never collect coins, purchase items, execute rebirths, claim rewards, redeem codes, own a farm, or fire gameplay remotes.

## Event records

Every event is printed to server Output as `[BOTX_EVENT]` followed by JSON. The stream covers real-player joins/leaves, character lifecycle/deaths, prompt interactions, selected gameplay RemoteEvents (names, argument count and argument types only), changes to profile/economy/progression attributes (coins, barn bank, speed, treadmill level, rebirths, captures, deposits, carrying state), and 10-second snapshots of player health/position/profile-loaded state and NPC positions/modes. The NPCs' two leg parts collide with the floor so Humanoid movement is physically grounded. A periodic summary and a final summary are printed as `[BOTX_SESSION_REPORT]`. The client has a `BOTX` status chip and a Diagnostics view. The chip requests a fresh summary over the `BotXStatus` RemoteEvent; the server also pushes the latest state when bots spawn and on 10-second snapshots. The view shows live NPC count, names, patrol modes, positions, elapsed session time and event counts.

The session retains the newest 400 events in memory and keeps event counters, including how many old entries were dropped. Periodic reports summarize current state without re-embedding the entire event history; the final report includes the retained events. Remote observation is capped at 30 events per player per RemoteEvent per second to avoid log flooding. These are server session diagnostics, not durable cloud storage; download/copy the Output report if you need an external archive.

## GitHub validation

The GitHub Actions workflow parses `BotX.server.lua`, runs `tools/tests/test_botx_npc.py`, checks project wiring, and builds `StealAnAnimal.rbxl`. GitHub Actions does not run the Roblox game engine, so it cannot verify real humanoid physics or live pathfinding. GitHub validation checks the status RemoteEvent wiring and the client-side display but does not execute Roblox physics. Runtime NPC movement still needs an actual published-game session with a real client connected; the in-game chip now exposes whether the NPCs have appeared, rather than leaving the user to infer this from inaccessible server Output.
