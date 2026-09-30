--!strict

local Players=game:GetService("Players")
local SharedState=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("PlayerState"))
local Constants=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Constants"))

local Service={}
Service.__index=Service

function Service.new()
    return setmetatable({states={},persistence=nil,saveInProgress={},saveAllowed={}},Service)
end

function Service:Init(registry)
    self.persistence=registry:Get("Persistence")
end

local function configureCharacter(player:Player,character:Model)
    local humanoid=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",10)
    if humanoid then
        humanoid.MaxHealth=Constants.Combat.PlayerMaxHealth
        humanoid.Health=humanoid.MaxHealth
        player:SetAttribute("CombatHealth",humanoid.Health)
    end
end

function Service:BindPlayer(player:Player)
    local profile,loaded=self.persistence:Load(player)
    if not player.Parent then return end
    local state=SharedState.new()
    state.Credits=profile.Credits
    state.DamageLevel=profile.DamageLevel
    state.XP=profile.XP
    state.TotalKills=profile.TotalKills
    state.HighestWave=profile.HighestWave
    state.OwnedItems=profile.OwnedItems
    state.EquippedSkin=profile.EquippedSkin
    state.EquippedEcho=profile.EquippedEcho
    SharedState.setReady(state,true)
    self.states[player]=state
    self.saveAllowed[player]=loaded

    player:SetAttribute("DataReady",true)
    player:SetAttribute("PersistenceLoaded",loaded)
    player:SetAttribute("PersistenceDegraded",not loaded)
    player:SetAttribute("Credits",state.Credits)
    player:SetAttribute("DamageLevel",state.DamageLevel)
    player:SetAttribute("XP",state.XP)
    player:SetAttribute("TotalKills",state.TotalKills)
    player:SetAttribute("HighestWave",state.HighestWave)
    player:SetAttribute("EquippedSkin",state.EquippedSkin)
    player:SetAttribute("EquippedEcho",state.EquippedEcho)
    player:SetAttribute("Zone","PvE")
    player:SetAttribute("CombatHealth",Constants.Combat.PlayerMaxHealth)

    player.CharacterAdded:Connect(function(character) configureCharacter(player,character) end)
    if player.Character then configureCharacter(player,player.Character) end
end

function Service:Get(player:Player) return self.states[player] end

function Service:Profile(player:Player)
    local state=self.states[player]
    if not state then return nil end
    return {
        Version=2,Credits=state.Credits,DamageLevel=state.DamageLevel,XP=state.XP,
        TotalKills=state.TotalKills,HighestWave=state.HighestWave,
        OwnedItems=table.clone(state.OwnedItems or {}),
        EquippedSkin=state.EquippedSkin or "Default",
        EquippedEcho=state.EquippedEcho or "None",
    }
end

function Service:Dirty(player:Player)
    if self.persistence then self.persistence:MarkDirty(player) end
end

function Service:AddCredits(player:Player,amount:number)
    local state=self.states[player]
    if not state then return end
    SharedState.addCredits(state,amount)
    player:SetAttribute("Credits",state.Credits)
    self:Dirty(player)
end

function Service:SpendCredits(player:Player,amount:number):boolean
    local state=self.states[player]
    if not state or amount<=0 or state.Credits<amount then return false end
    state.Credits-=amount
    player:SetAttribute("Credits",state.Credits)
    self:Dirty(player)
    return true
end

function Service:AddDamageLevel(player:Player)
    local state=self.states[player]
    if not state then return end
    SharedState.addDamageLevel(state)
    player:SetAttribute("DamageLevel",state.DamageLevel)
    self:Dirty(player)
end

function Service:AddXP(player:Player,amount:number)
    local state=self.states[player]
    if not state then return end
    state.XP=math.max(0,state.XP+math.max(0,amount))
    player:SetAttribute("XP",state.XP)
    self:Dirty(player)
end

function Service:AddKill(player:Player)
    local state=self.states[player]
    if not state then return end
    state.TotalKills+=1
    player:SetAttribute("TotalKills",state.TotalKills)
    self:Dirty(player)
end

function Service:SetHighestWave(player:Player,wave:number)
    local state=self.states[player]
    if not state then return end
    state.HighestWave=math.max(state.HighestWave,wave)
    player:SetAttribute("HighestWave",state.HighestWave)
    self:Dirty(player)
end

function Service:Owns(player:Player,itemId:string):boolean
    local state=self.states[player]
    return state~=nil and state.OwnedItems[itemId]==true
end

function Service:GrantItem(player:Player,itemId:string):boolean
    local state=self.states[player]
    if not state or type(itemId)~="string" or itemId=="" or state.OwnedItems[itemId] then return false end
    state.OwnedItems[itemId]=true
    player:SetAttribute("InventoryUpdated",os.clock())
    self:Dirty(player)
    return true
end

function Service:EquipSkin(player:Player,itemId:string):boolean
    local state=self.states[player]
    if not state or not state.OwnedItems[itemId] then return false end
    state.EquippedSkin=itemId
    player:SetAttribute("EquippedSkin",itemId)
    self:Dirty(player)
    return true
end

function Service:SetEquippedEcho(player:Player,itemId:string):boolean
    local state=self.states[player]
    if not state or not state.OwnedItems[itemId] then return false end
    state.EquippedEcho=itemId
    player:SetAttribute("EquippedEcho",itemId)
    self:Dirty(player)
    return true
end

function Service:GetDamage(player:Player):number
    local state=self.states[player]
    return state and state.DamageLevel*Constants.Economy.UpgradeDamagePerLevel or 0
end

function Service:SetWave(player:Player,wave:number)
    local state=self.states[player]
    if state then
        state.Wave=wave
        player:SetAttribute("Wave",wave)
        self:SetHighestWave(player,wave)
    end
end

function Service:Save(player:Player):boolean
    if self.saveInProgress[player] or not self.saveAllowed[player] then return false end
    local profile=self:Profile(player)
    if not profile then return false end
    self.saveInProgress[player]=true
    local ok=self.persistence:Save(player,profile)
    self.saveInProgress[player]=nil
    return ok
end

function Service:Start()
    Players.PlayerAdded:Connect(function(player) task.spawn(function() self:BindPlayer(player) end) end)
    Players.PlayerRemoving:Connect(function(player)
        self:Save(player)
        self.states[player]=nil
        self.saveAllowed[player]=nil
        self.persistence:Release(player)
    end)
    game:BindToClose(function()
        for _,player in ipairs(Players:GetPlayers()) do self:Save(player) end
    end)
    for _,player in ipairs(Players:GetPlayers()) do task.spawn(function() self:BindPlayer(player) end) end
end

return Service
