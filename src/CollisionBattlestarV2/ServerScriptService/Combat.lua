--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Shared.Constants)

local Combat = {}
Combat.__index = Combat

function Combat.new(players, enemies, pvp, remotes, heart)
    return setmetatable({
        players = players,
        enemies = enemies,
        pvp = pvp,
        remotes = remotes,
        heart = heart,
        running = false,
        connection = nil,
    }, Combat)
end

function Combat:DamageTarget(attacker: Player, target: Model, baseDamage: number, isPlayerTarget: boolean)
    if isPlayerTarget then
        local targetPlayer = Players:GetPlayerFromCharacter(target)
        if not targetPlayer or not self.pvp:CanAttack(attacker, targetPlayer) then
            return false
        end

        local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
        if not targetHumanoid or targetHumanoid.Health <= 0 then
            return false
        end

        targetHumanoid:TakeDamage(baseDamage)
        targetPlayer:SetAttribute("CBS2_LastKiller", attacker.UserId)
        self.remotes.FX:FireAllClients("Hit", {
            position = target:GetPivot().Position,
            pvp = true,
        })
        return true
    end

    return self.enemies:TakeDamage(attacker, target, baseDamage, false)
end

function Combat:Attack(player: Player)
    local state = self.players:State(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not state or not root or not root:IsA("BasePart") then
        return
    end

    local now = os.clock()
    if now - state.attackAt < Constants.AttackCooldown then
        return
    end

    state.attackAt = now
    state.combo = now - state.comboAt <= Constants.ComboReset and state.combo + 1 or 1
    if state.combo > 3 then
        state.combo = 1
    end
    state.comboAt = now

    local damage = 15 + state.profile.Upgrades.Damage * 6
    damage *= ({1, 1.1, 1.25})[state.combo] or 1

    local boxCFrame = root.CFrame * CFrame.new(0, 0, -5)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.MaxParts = 32

    local parts = Workspace:GetPartBoundsInBox(boxCFrame, Constants.AttackBox, params)
    local seen = {}

    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and not seen[model] then
            seen[model] = true

            if model:GetAttribute("CBS2_NPC") == true then
                local targetRoot = model.PrimaryPart
                if targetRoot then
                    local distance = (targetRoot.Position - root.Position).Magnitude
                    if distance <= Constants.AttackRange then
                        local delta = targetRoot.Position - root.Position
                        local flatDelta = Vector3.new(delta.X, 0, delta.Z)
                        local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
                        local facing = if flatDelta.Magnitude > 0.1 and forward.Magnitude > 0.1
                            then forward.Unit:Dot(flatDelta.Unit)
                            else -1

                        if facing < 0.15 then
                            continue
                        end

                        local critical = math.random() < math.min(0.25, state.profile.Upgrades.Damage * 0.01)
                        local finalDamage = math.floor(damage * (critical and 1.8 or 1))
                        self.enemies:TakeDamage(player, model, finalDamage, critical)
                    end
                end
            elseif self.pvp:IsParticipant(player) then
                local targetPlayer = Players:GetPlayerFromCharacter(model)
                if targetPlayer and targetPlayer ~= player then
                    self:DamageTarget(player, model, damage, true)
                end
            end
        end
    end

    self.remotes.FX:FireAllClients("Swing", {
        position = root.Position,
        combo = state.combo,
    })
end

function Combat:Dash(player: Player, direction: any)
    local state = self.players:State(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not state or not root or not root:IsA("BasePart") then
        return
    end

    local now = os.clock()
    local cooldown = math.max(0.45, Constants.DashCooldown - state.profile.Upgrades.Dash * 0.03)

    if now - state.dashAt < cooldown then
        return
    end

    if typeof(direction) ~= "Vector3" then
        return
    end

    local flat = Vector3.new(direction.X, 0, direction.Z)
    if flat.Magnitude < 0.1 then
        return
    end

    flat = flat.Unit
    state.dashAt = now

    local distance = Constants.DashDistance + state.profile.Upgrades.Dash * 1.2
    local target = root.Position + flat * distance

    if self.pvp:IsParticipant(player) then
        target = Vector3.new(
            math.clamp(target.X, -Constants.PVPArenaHalfWidth + 3, Constants.PVPArenaHalfWidth - 3),
            root.Position.Y,
            math.clamp(
                target.Z,
                Constants.PVPArenaCenterZ - Constants.PVPArenaHalfDepth + 3,
                Constants.PVPArenaCenterZ + Constants.PVPArenaHalfDepth - 3
            )
        )
    else
        target = Vector3.new(
            math.clamp(target.X, -Constants.ArenaRadius + 4, Constants.ArenaRadius - 4),
            root.Position.Y,
            math.clamp(target.Z, -Constants.ArenaRadius + 4, Constants.ArenaRadius - 4)
        )
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {character}

    local hit = Workspace:Raycast(
        root.Position,
        target - root.Position,
        rayParams
    )

    if hit and hit.Instance and hit.Instance.CanCollide then
        target = hit.Position - flat * 2
    end

    root.CFrame = CFrame.lookAt(target, target + flat)
    root.AssemblyLinearVelocity = Vector3.zero

    self.remotes.FX:FireAllClients("Dash", {
        position = target,
    })
end

function Combat:Start()
    if self.running then
        return
    end

    self.running = true
    self.connection = self.remotes.Combat.OnServerEvent:Connect(function(player, request)
        local ok, err = pcall(function()
            if type(request) ~= "table" then
                return
            end

            if request.action == "Attack" then
                self:Attack(player)
            elseif request.action == "Dash" then
                self:Dash(player, request.direction)
            end
        end)

        if not ok and self.heart then
            self.heart:Report("combat", err)
        end
    end)
end

function Combat:Stop()
    self.running = false
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
end

function Combat:Reload()
    self:Stop()
    self:Start()
end

return Combat
