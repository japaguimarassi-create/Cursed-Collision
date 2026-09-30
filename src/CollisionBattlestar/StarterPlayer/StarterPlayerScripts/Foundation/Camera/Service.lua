--!strict

local Players = game:GetService("Players")

local Service = {}

function Service.Init()
    local player = Players.LocalPlayer
    player.CameraMinZoomDistance = 8
    player.CameraMaxZoomDistance = 18

    local function configure(character: Model)
        character:WaitForChild("Humanoid", 10)
        local camera = workspace.CurrentCamera
        if camera then
            camera.CameraType = Enum.CameraType.Custom
            camera.FieldOfView = 72
        end
    end

    if player.Character then
        configure(player.Character)
    end
    player.CharacterAdded:Connect(configure)
end

return Service