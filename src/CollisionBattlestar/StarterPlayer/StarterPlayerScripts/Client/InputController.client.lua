--!strict

local ContextActionService = game:GetService("ContextActionService")

local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local Action = remotes:WaitForChild("Action") :: RemoteEvent

local function bind(name: string, title: string, position: UDim2, inputs: {Enum.KeyCode | Enum.UserInputType}, callback)
    local function handler(_, state)
        if state == Enum.UserInputState.Begin then
            callback()
        end
        return Enum.ContextActionResult.Sink
    end

    ContextActionService:BindAction(name, handler, true, table.unpack(inputs))
    ContextActionService:SetTitle(name, title)

    local button = ContextActionService:GetButton(name)
    if button then
        button.Position = position
        button.Size = UDim2.fromOffset(72, 72)
        button.BackgroundTransparency = 0.12
        button.Font = Enum.Font.GothamBold
        button.TextScaled = true
    end
end

local Controller = {}

function Controller:Init()
    bind(
        "CBS_Attack",
        "ATK",
        UDim2.fromScale(0.83, 0.72),
        {Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2},
        function()
            Action:FireServer("M1")
        end
    )

    bind(
        "CBS_Dash",
        "DASH",
        UDim2.fromScale(0.73, 0.62),
        {Enum.KeyCode.Q, Enum.KeyCode.ButtonB},
        function()
            Action:FireServer("Dash")
        end
    )
end

return Controller
