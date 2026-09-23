# Cursed Collision — Research Matrix

| System | Reference sources | Visual refs | Current implementation | Test status | Performance status | Security status |
|---|---|---|---|---|---|---|
| Combat | Roblox RemoteEvent + security docs; JJS controls | M1 / skill HUD samples | Server-authoritative M1/skills with validated timing requests | Static validation pending | Throttled remote + spatial query | Server validates state, cooldown, attack ID |
| Animation | AnimationTrack docs | combat/awakening frames | Cache + AnimationController + marker CombatHandler | Static validation pending | Cached tracks/animations | Client marker cannot apply damage directly |
| Input | UserInputService + ContextActionService docs | mobile HUD sample | InputManager + custom HUD | Static validation pending | Event-based | Inputs only request actions |
| HUD | ScreenGui/insets/constraints docs | HUD/mobile samples | HUDController | Static validation pending | Throttled cooldown refresh | UI is presentation only |
| Emotes | RemoteEvent/security model | emote/menu sample | Emote server validation + client presentation | Existing CI coverage + new static coverage | Client-side pose loop | Ownership checked server-side |
| Networking | RemoteEvent docs + security boundary | N/A | Organized Remotes folder | Static validation pending | No per-frame gameplay remote | Payloads validated |
| Performance | Roblox performance + streaming docs | city references | Cache/constrained UI foundation | Runtime profiling not available here | Architecture prepared | N/A |
| Map | Streaming docs | city references | Existing map foundation | Runtime QA pending | Streaming-compatible target | Gameplay-critical destruction remains server-side target |
| VFX | Client presentation pattern | VFX references | Existing VFX manager | Runtime QA pending | Cosmetic events client-side | No gameplay authority |
| Camera | client presentation pattern | impact/awakening refs | Existing CameraController | Runtime QA pending | Event-driven | No authority |
| Awakening | combat state architecture | awakening refs | Existing meter/state framework | Runtime QA pending | Event-driven | Server validates meter |
| Domain | state/replication architecture | domain category reserved | Framework work remains | Not complete | Not complete | Not complete |
| Domain Clash | universal state design | clash category reserved | Framework work remains | Not complete | Not complete | Not complete |
| Destruction | streaming/performance docs | destruction category reserved | Framework work remains | Not complete | Not complete | Not complete |
| Data | Roblox data architecture | menu/economy references | Existing DataService foundation | Runtime persistence QA pending | Server-side | Server authority |
| Missions | data/economy architecture | menu refs | Existing mission foundation | Runtime QA pending | Data-driven | Server authority |
| Skins | data/economy architecture | menu refs | Existing skin foundation | Runtime QA pending | Data-driven | Server authority |
| Admin | client-server security | N/A | Owner UI + server gate foundation | Runtime QA pending | Low-frequency | UserId/permission based |
