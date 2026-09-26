# Collision Battlestar - Luau Repair Knowledge

## Runtime boundaries
Collision Battlestar is a Rojo Roblox project. default.project.json controls DataModel mapping.

Server is authoritative for combat, enemy AI, economy, persistence, purchases, admin and protected progression.
Client handles input, HUD and visual feedback. Client requests are untrusted intent.

## Luau
Use --!strict when the surrounding module does.
Understand typed locals, table aliases, optional values, unions, generics, closures, multiple returns, pcall/xpcall, task.spawn/defer/delay/wait, tonumber, typeof, math.clamp and string functions.

Colon syntax passes self:
service:Init(config)
is equivalent to:
service.Init(service, config)

Check optional values before indexing or calling. Do not assume dictionary iteration order.

## Roblox lifecycle
Use game:GetService for services.
Use WaitForChild for required replicated startup dependencies.
Player.CharacterAdded can fire before all descendants exist. Use Character:WaitForChild("Humanoid") and Character:WaitForChild("HumanoidRootPart") where required.

Avoid duplicate connections during repeated UI refreshes or service calls.

## Remotes and security
RemoteEvent and RemoteFunction are not trust boundaries in the client's favor.
Client may request M1, Dash, shop actions and travel/action intents.
Server must calculate damage, target, cooldown, movement destination, price, reward, ownership and admin authorization.
Never accept client authority for protected values.

## Combat
For box hits:
workspace:GetPartBoundsInBox(center, size, overlapParams)
Then resolve:
part:FindFirstAncestorOfClass("Model")
Then verify the model is a valid enemy/player and has a living Humanoid.

Do not rely on PrimaryPart unless the project guarantees it. Model:GetPivot() is robust for generic models.

For dash:
derive direction from the server-known root CFrame;
raycast to avoid solid obstacles;
mutate character/root on the server;
account for legitimate server movement in anti-cheat;
check whether another system immediately moves the character back.

Use server-side cooldown tables keyed by Player.

## Physics
Relevant APIs:
BasePart.CFrame
BasePart.AssemblyLinearVelocity
Model:GetPivot()
Model:PivotTo(cf)
workspace:Raycast(...)
workspace:GetPartBoundsInBox(...)
RaycastParams
OverlapParams
Vector3
CFrame

## UI
Runtime-created ScreenGui instances must end up in PlayerGui to render.
Use Activated for multi-input buttons.
ZIndex, AnchorPoint and UIScale matter.
UIListLayout/UIGridLayout AbsoluteContentSize is useful for scroll sizing.
Mobile layouts need narrow-width handling.

Trace every UI entry point:
StarterPlayer mapping -> client script -> require -> mount -> parent -> Visible -> ZIndex.

## DataStore and monetization
DataStore is server-only.
Developer products must use MarketplaceService.ProcessReceipt.
Receipt processing must be idempotent and should persist the processed purchase before reporting success.
Do not use client purchase-finished signals as grant authority.

## Admin
Client visibility is not authorization.
Admin permission is decided on the server from trusted identity.
Owner/admin remotes must validate target and values.

## Performance and safety
Prefer signals over polling.
Avoid unbounded per-frame scans, leaked connections, loadstring, arbitrary dynamic code loading and uncontrolled task.spawn loops.
Keep combat overlap queries bounded.
Do not introduce external packages merely to repair existing code.

## Rojo
A script outside the mapped tree is not present in the Roblox DataModel.
A valid source tree must pass the repository validator and, when available, produce a non-empty Rojo .rbxl.

## Repair method
Before changing a file:
1. Find callers.
2. Find callees.
3. Verify remote/event/attribute names.
4. Verify startup order.
5. Verify client/server boundary.
6. Verify validator/build evidence.

After changing:
1. Run tools/validate_project.py.
2. Run git diff --check.
3. Run Rojo build when available.
4. Re-audit touched files and their references.
5. Stop when no concrete defect remains.
