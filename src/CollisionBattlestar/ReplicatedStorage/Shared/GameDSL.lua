--!strict

local DSL = {}
DSL.__index = DSL

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

local function requireTable(root, key)
    if type(root[key]) ~= "table" then error(("Collision Script: missing %s"):format(key)) end
end

function DSL.game(name: string)
    return setmetatable({_data = {Name = name, DSLVersion = "CBSL-1.0"}}, DSL)
end
function DSL:identity(buildVersion: string, universeId: number, placeId: number, gameMode: string)
    self._data.BuildVersion = buildVersion
    self._data.UniverseId = universeId
    self._data.PlaceId = placeId
    self._data.GameMode = gameMode
    return self
end

function DSL:world(definition) self._data.World = copy(definition); return self end
function DSL:combat(definition) self._data.Combat = copy(definition); return self end
function DSL:waves(definition) self._data.Waves = copy(definition); return self end
function DSL:enemy(name: string, definition)
    self._data.Enemies = self._data.Enemies or {}
    self._data.Enemies[name] = copy(definition)
    return self
end

function DSL:enemies(definitions) self._data.Enemies = copy(definitions); return self end
function DSL:ai(kind: string, definition) self._data.AI = self._data.AI or {}; self._data.AI[kind] = copy(definition); return self end
function DSL:assets(definition) self._data.NPCAssets = copy(definition); return self end
function DSL:shop(definition) self._data.Shop = copy(definition); return self end
function DSL:passes(definition) self._data.GamePasses = copy(definition); return self end
function DSL:ui(definition) self._data.UI = copy(definition); return self end
function DSL:meta(definition) self._data.Meta = copy(definition); return self end
function DSL:compile()
    for _, key in ipairs({"World","Combat","Waves","Enemies","AI","NPCAssets","Shop","GamePasses","UI"}) do requireTable(self._data, key) end
    if type(self._data.Combat.M1) ~= "table" or type(self._data.Combat.Dash) ~= "table" then error("Collision Script: Combat requires M1 and Dash") end
    for _, key in ipairs({"Tier1","Tier2","Tier3","Elite"}) do if type(self._data.Enemies[key]) ~= "table" then error(("Collision Script: enemy preset %s is missing"):format(key)) end end
    if type(self._data.AI.Enemy) ~= "table" or type(self._data.AI.Companion) ~= "table" then error("Collision Script: AI requires Enemy and Companion") end
    local output = copy(self._data)
    if type(self._data.BuildVersion) ~= "string" or type(self._data.UniverseId) ~= "number" or type(self._data.PlaceId) ~= "number" or type(self._data.GameMode) ~= "string" then
        error("Collision Script: identity is incomplete")
    end

    output.BuildVersion = self._data.BuildVersion
    output.UniverseId = self._data.UniverseId
    output.PlaceId = self._data.PlaceId
    output.GameMode = self._data.GameMode
    return output
end

return DSL