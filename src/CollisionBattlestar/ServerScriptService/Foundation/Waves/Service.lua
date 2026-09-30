--!strict

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Rules = require(Shared:WaitForChild("WaveRules"))
local SkinDefinitions = require(Shared:WaitForChild("EnemySkinDefinitions"))

local Service = {}
Service.__index = Service

function Service.new()
    return setmetatable({
        world=nil,enemies=nil,economy=nil,playerState=nil,state=nil,stateRemote=nil,
        wave=0,phase="Waiting",active=0,elitePresent=false,running=false,
        themeId="Urban",spawnToken=0,
    },Service)
end

function Service:Init(registry,remotes)
    self.world=registry:Get("World")
    self.enemies=registry:Get("Enemies")
    self.economy=registry:Get("Economy")
    self.playerState=registry:Get("PlayerState")
    self.state=registry:Get("RuntimeState")
    self.stateRemote=remotes.State
    self.analytics=registry:Get("Analytics")
    self.enemies:SetDefeatHandler(function(model,tier,attackerId)
        self:OnEnemyDefeated(model,tier,attackerId)
    end)
end

function Service:Broadcast()
    self.state:Set(self.wave,self.phase,self.active,self.elitePresent)
    workspace:SetAttribute("CollisionWave",self.wave)
    workspace:SetAttribute("CollisionEnemies",self.active)
    workspace:SetAttribute("CollisionPhase",self.phase)
    workspace:SetAttribute("CollisionElite",self.elitePresent)
    workspace:SetAttribute("CollisionTheme",self.themeId)
    self.stateRemote:FireAllClients("Wave",self.wave,self.active,self.phase,self.elitePresent,self.themeId)
    for _,player in ipairs(Players:GetPlayers()) do self.playerState:SetWave(player,self.wave) end
end

function Service:spawnWave(wave:number)
    self.spawnToken += 1
    local token=self.spawnToken
    local count=Rules.enemyCount(wave)
    self.active=0
    self.elitePresent=false
    self.phase="Spawning"
    local themes=SkinDefinitions.themeIds()
    self.themeId=themes[((wave-1)%#themes)+1]
    self:Broadcast()
    for _,player in ipairs(Players:GetPlayers()) do self.analytics:Log(player,"Wave",wave,{"Start",self.themeId,tostring(count)}) end

    task.spawn(function()
        for index=1,count-1 do
            if token~=self.spawnToken or #Players:GetPlayers()==0 then return end
            if self.phase~="Spawning" then return end
            local tier=Rules.normalTier(wave,index)
            self.enemies:Spawn(tier,index,self.themeId,wave*1000+index)
            self.active=self.enemies:GetActiveCount()
            self:Broadcast()
            task.wait(Constants.Waves.SpawnDelay)
        end
        if token~=self.spawnToken or #Players:GetPlayers()==0 then return end
        self.elitePresent=true
        self.enemies:Spawn("Elite",count,self.themeId,wave*1000+count)
        self.active=self.enemies:GetActiveCount()
        self.phase="Active"
        self:Broadcast()
    end)
end

function Service:beginNextWave()
    if #Players:GetPlayers()==0 then
        self.enemies:ClearAll()
        self.active=0
        self.elitePresent=false
        self.phase="Waiting"
        self:Broadcast()
        return
    end
    self.wave+=1
    self:spawnWave(self.wave)
end

function Service:ForceNextWave()
    if #Players:GetPlayers()==0 then return end
    self.spawnToken+=1
    self.enemies:ClearAll()
    self.active=0
    self.elitePresent=false
    self.phase="Cleared"
    self:Broadcast()
    self:beginNextWave()
end

function Service:OnEnemyDefeated(_,tier:string,attackerId)
    self.active=self.enemies:GetActiveCount()
    if tier=="Elite" then self.elitePresent=false end

    if typeof(attackerId)=="number" then
        local player=Players:GetPlayerByUserId(attackerId)
        if player then
            self.economy:GrantEnemyReward(player,tier)
            self.playerState:AddKill(player)
            self.playerState:AddXP(player,math.max(1,(Constants.Enemies[tier] and Constants.Enemies[tier].Credits or 1)*2))
        end
    end

    self:Broadcast()
    if self.phase=="Active" and self.active==0 then
        local clearedWave=self.wave
        self.phase="Cleared"
        self:Broadcast()
        for _,player in ipairs(Players:GetPlayers()) do self.analytics:Log(player,"Wave",clearedWave,{"Cleared",self.themeId,tostring(self.wave)}) end
        self.economy:GrantWaveReward(clearedWave)
        task.delay(Constants.Waves.Intermission,function()
            if #Players:GetPlayers()>0 and self.phase=="Cleared" and self.wave==clearedWave then
                self:beginNextWave()
            end
        end)
    end
end

function Service:Start()
    Players.PlayerAdded:Connect(function()
        if not self.running then
            self.running=true
            task.delay(1.5,function()
                if self.wave==0 and #Players:GetPlayers()>0 then self:beginNextWave() end
            end)
        end
    end)
    Players.PlayerRemoving:Connect(function()
        if #Players:GetPlayers()<=1 then
            self.spawnToken+=1
            self.enemies:ClearAll()
            self.active=0
            self.elitePresent=false
            self.phase="Waiting"
            self:Broadcast()
        end
    end)
    if #Players:GetPlayers()>0 then
        self.running=true
        task.delay(1.5,function()
            if self.wave==0 and #Players:GetPlayers()>0 then self:beginNextWave() end
        end)
    end
    self:Broadcast()
end

return Service
