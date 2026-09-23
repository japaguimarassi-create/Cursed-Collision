--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local StateManager = require(script.Parent.StateManager)

local ComboService = {}

local ATTACKS = {
    [1] = {Startup=0.075, Active=0.045, Recovery=0.10, Damage=5, Hitbox=Vector3.new(5.2,5.8,6.2), Offset=3.1},
    [2] = {Startup=0.070, Active=0.045, Recovery=0.105, Damage=5, Hitbox=Vector3.new(5.3,5.8,6.4), Offset=3.2},
    [3] = {Startup=0.075, Active=0.050, Recovery=0.12, Damage=7, Hitbox=Vector3.new(5.4,5.9,6.6), Offset=3.3},
    [4] = {Startup=0.11, Active=0.06, Recovery=0.28, Damage=10, Hitbox=Vector3.new(5.8,6.4,7.1), Offset=3.6}
}

local function airborne(player: Player): boolean
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    local state = humanoid:GetState()
    return state == Enum.HumanoidStateType.Jumping
        or state == Enum.HumanoidStateType.Freefall
end

function ComboService:Next(player: Player, now: number)
    local state = StateManager:Get(player)
    if not state then return nil end

    if now - state.LastM1 > Config.Combat.M1.ComboReset then
        state.Combo = 0
    end

    state.Combo = math.clamp(state.Combo + 1, 1, 4)
    state.LastM1 = now

    local base = ATTACKS[state.Combo]
    local data = {}
    for key, value in pairs(base) do data[key] = value end

    data.Combo = state.Combo
    data.Final = state.Combo == 4
    data.Variant = airborne(player) and "Air" or "Ground"

    if data.Variant == "Air" then
        data.Launch = data.Final and 0 or 5
        data.Knockback = data.Final and 42 or 10
        data.Stun = data.Final and 0.36 or 0.24
    else
        data.Launch = data.Final and 8 or 1.5
        data.Knockback = data.Final and 48 or 8 + state.Combo
        data.Stun = ({0.20,0.22,0.25,0.42})[state.Combo]
    end

    if state.Combo == 1 and state.LastAction == "Dash" then
        data.Variant = "DashCancel"
        data.Startup = 0.055
        data.Knockback += 4
    end

    return data
end

function ComboService:Reset(player: Player)
    local state = StateManager:Get(player)
    if state then state.Combo = 0 end
end

return ComboService
