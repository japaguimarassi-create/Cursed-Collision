--!strict

local UserInputService = game:GetService("UserInputService")

local Input = {}

function Input.Bind(player: Player, hud, combatRemote: RemoteEvent)
    local function attack()
        combatRemote:FireServer("M1")
    end

    local function dash()
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local direction = humanoid and humanoid.MoveDirection
        if direction and direction.Magnitude > 0.1 then
            direction = Vector3.new(direction.X, 0, direction.Z).Unit
        else
            direction = nil
        end
        combatRemote:FireServer("Dash", direction)
    end

    hud:SetActionCallbacks(attack, dash)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            attack()
        elseif input.KeyCode == Enum.KeyCode.Q then
            dash()
        elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
            attack()
        elseif input.KeyCode == Enum.KeyCode.ButtonB then
            dash()
        end
    end)

    return {Attack = attack, Dash = dash}
end

return Input