--!strict

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local Input = {}

local ATTACK_ACTION = "CollisionBattlestar_M1"
local DASH_ACTION = "CollisionBattlestar_Dash"

function Input.Bind(player: Player, hud, combatRemote: RemoteEvent)
    local function canInput(): boolean
        return UserInputService:GetFocusedTextBox() == nil
    end

    local function attack()
        if canInput() then
            combatRemote:FireServer("M1")
        end
    end

    local function dash()
        if not canInput() then
            return
        end

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local move = humanoid and humanoid.MoveDirection
        local direction = nil

        if move and move.Magnitude > 0.1 then
            direction = Vector3.new(move.X, 0, move.Z).Unit
        end

        combatRemote:FireServer("Dash", direction)
    end

    hud:SetActionCallbacks(attack, dash)

    ContextActionService:BindAction(
        ATTACK_ACTION,
        function(_, state)
            if state == Enum.UserInputState.Begin then
                attack()
            end
            return Enum.ContextActionResult.Sink
        end,
        false,
        Enum.UserInputType.MouseButton1,
        Enum.KeyCode.ButtonR2
    )

    ContextActionService:BindAction(
        DASH_ACTION,
        function(_, state)
            if state == Enum.UserInputState.Begin then
                dash()
            end
            return Enum.ContextActionResult.Sink
        end,
        false,
        Enum.KeyCode.Q,
        Enum.KeyCode.ButtonB
    )

    return {
        Attack = attack,
        Dash = dash,
        Unbind = function()
            ContextActionService:UnbindAction(ATTACK_ACTION)
            ContextActionService:UnbindAction(DASH_ACTION)
        end,
    }
end

return Input
