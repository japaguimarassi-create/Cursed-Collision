--!strict

local CombatController = {}
CombatController.__index = CombatController

export type Handler = (player: Player, payload: any) -> boolean?

function CombatController.new()
    return setmetatable({
        _handlers = {} :: {[string]: Handler},
    }, CombatController)
end

function CombatController:Register(action: string, handler: Handler)
    self._handlers[action] = handler
end

function CombatController:Dispatch(player: Player, action: string, payload: any): boolean
    local handler = self._handlers[action]
    if not handler then
        return false
    end
    return handler(player, payload) ~= false
end

return CombatController
