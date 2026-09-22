--!strict

local AbilityController = {}
AbilityController.__index = AbilityController

function AbilityController.new(remote: RemoteEvent)
    return setmetatable({
        _remote = remote,
    }, AbilityController)
end

function AbilityController:Fire(action: string, payload: any)
    self._remote:FireServer(action, payload)
end

return AbilityController
