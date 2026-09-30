--!strict

local DataStoreService=game:GetService("DataStoreService")
local HttpService=game:GetService("HttpService")
local Rules=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ProgressionRules"))

local Service={}
Service.__index=Service
local DATASTORE_NAME="CollisionBattlestar_PlayerProfiles_v2"
local MAX_RETRIES=4

local function retry(label:string,callback)
    local lastError="unknown"
    for attempt=1,MAX_RETRIES do
        local ok,result=pcall(callback)
        if ok then return true,result end
        lastError=tostring(result)
        task.wait(math.min(8,2^(attempt-1)))
    end
    warn(("[Persistence] %s failed after %d retries: %s"):format(label,MAX_RETRIES,lastError))
    return false,nil
end

local function key(userId:number):string return "u:"..tostring(userId) end

function Service.new()
    return setmetatable({store=DataStoreService:GetDataStore(DATASTORE_NAME),dirty={}},Service)
end

function Service:Init() end

function Service:Load(player:Player)
    local ok,raw=retry("load/"..player.UserId,function()
        return self.store:GetAsync(key(player.UserId))
    end)
    if not ok then return Rules.defaultProfile(),false end
    return Rules.migrate(raw),true
end

function Service:MarkDirty(player:Player)
    self.dirty[player]=true
end

function Service:Save(player:Player,profile):boolean
    if not profile or not Rules.validate(profile) then return false end
    local payload=HttpService:JSONDecode(HttpService:JSONEncode(profile))
    local ok=retry("save/"..player.UserId,function()
        return self.store:UpdateAsync(key(player.UserId),function() return payload end)
    end)
    if ok then
        self.dirty[player]=nil
        return true
    end
    return false
end

function Service:Release(player:Player)
    self.dirty[player]=nil
end

return Service
