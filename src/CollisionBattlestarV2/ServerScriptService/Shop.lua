--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Definitions = require(ReplicatedStorage.Shared.ShopDefinitions)

local Shop = {}
Shop.__index = Shop

function Shop.new(players, remotes, runtimeState)
    return setmetatable({
        players = players,
        remotes = remotes,
        state = runtimeState,
        connections = {},
    }, Shop)
end

local function upgradePrice(id: string, level: number)
    return math.floor((100 + level * 65) * (id == "Dash" and 1.2 or 1))
end

function Shop:Catalog(player: Player)
    local state = self.players:State(player)
    local result = {}

    for id, item in pairs(Definitions.Items) do
        local entry = {
            id = id,
            name = item.Name,
            kind = item.Kind,
            owned = false,
            price = item.Price,
        }

        if item.Kind == "Upgrade" then
            local level = state and state.profile.Upgrades[id] or 0
            entry.level = level
            entry.max = 25
            entry.price = upgradePrice(id, level)
        elseif state then
            entry.owned = state.profile.Inventory.Owned[id] == true
        end

        table.insert(result, entry)
    end

    return result
end

function Shop:Handle(player: Player, request: any)
    if type(request) ~= "table" then
        return
    end

    if self.state.phase ~= "Intermission" then
        return
    end

    if request.action == "Catalog" then
        self.remotes.Shop:FireClient(player, "Catalog", self:Catalog(player))
        return
    end

    if request.action == "Buy" and type(request.id) == "string" then
        local item = Definitions.Items[request.id]
        if not item then
            return
        end

        if item.Kind == "Upgrade" then
            local ok = self.players:Upgrade(
                player,
                request.id,
                tonumber(request.price) or -1
            )
            self.remotes.Shop:FireClient(player, "Result", {
                success = ok == true,
                catalog = self:Catalog(player),
            })
            return
        end

        local state = self.players:State(player)
        if not state or state.profile.Inventory.Owned[request.id] then
            return
        end

        if state.profile.Credits < item.Price then
            return
        end

        state.profile.Credits -= item.Price
        state.profile.Inventory.Owned[request.id] = true
        self.players.persistence:MarkDirty(player)
        player:SetAttribute("CBS_Credits", state.profile.Credits)

        self.remotes.Shop:FireClient(player, "Result", {
            success = true,
            catalog = self:Catalog(player),
        })
        return
    end

    if request.action == "Equip" and type(request.id) == "string" then
        local state = self.players:State(player)
        if state and state.profile.Inventory.Owned[request.id] then
            state.profile.Inventory.Equipped.PlayerSkin = request.id
            self.players.persistence:MarkDirty(player)
            player:SetAttribute("CBS_PlayerSkin", request.id)
            self.remotes.Shop:FireClient(player, "Result", {
                success = true,
                catalog = self:Catalog(player),
            })
        end
    end
end

function Shop:Start()
    table.insert(self.connections, self.remotes.Shop.OnServerEvent:Connect(function(player, request)
        self:Handle(player, request)
    end))
end

function Shop:Stop()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    table.clear(self.connections)
end

function Shop:Reload()
    self:Stop()
    self:Start()
end

return Shop
