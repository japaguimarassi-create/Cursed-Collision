--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry: any=require(ReplicatedStorage.Animation.AnimationRegistry)
local Blender: any=require(script.Parent.AnimationBlender)
local Priority: any=require(script.Parent.AnimationPriorityManager)
local StateMachine: any=require(script.Parent.AnimationStateMachine)
local Procedural: any=require(ReplicatedStorage.Combat.CombatAnimationService)

local AnimationController={}
AnimationController.__index=AnimationController

type CharacterData={
    animator: Animator,
    machine: any,
    tracks: {[string]: AnimationTrack}
}

local bound:{[Model]: CharacterData}={}

local function animatorOf(character: Model): Animator?
    local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end

    local animator=humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator=Instance.new("Animator")
        animator.Parent=humanoid
    end

    return animator
end

local function fallback(character: Model,key: string,payload: any): boolean
    local move=tostring(payload and (payload.move or payload.Name) or key)

    if key=="HitLight" or key=="HitHeavy" or key=="HitLaunch" or key=="HitSlam" or key=="HitFinisher" then
        local reaction=key=="HitHeavy" and "Heavy"
            or key=="HitLaunch" and "Launcher"
            or key=="HitSlam" and "Slam"
            or key=="HitFinisher" and "Death"
            or "Light"

        Procedural:HitReact(character,tonumber(payload and payload.damage) or 1,reaction)
        return true
    end

    if key=="M1_1" or key=="M1_2" or key=="M1_3" or key=="M1_4" then
        local combo=tonumber(string.sub(key,4)) or 1
        return Procedural:PlayAttack(character,"M1",{combo=combo,move=move})
    end

    if key=="Skill1" or key=="Skill2" or key=="Skill3" or key=="Skill4" then
        return Procedural:PlaySkill(character,move,payload or {})
    end

    if key=="Block" then
        return Procedural:PlayAttack(character,"Block",payload or {})
    end

    if key=="Parry" then
        return Procedural:HitReact(character,1.5,"Parry")
    end

    if key=="Dash" or key=="AirDash" then
        return Procedural:PlayAttack(character,"Dash",payload or {})
    end

    if key=="Special" or key=="Ultimate" or key=="Awakening" then
        return Procedural:PlaySkill(character,move,payload or {})
    end

    if key=="Execute" then
        return Procedural:HitReact(character,2,"Death")
    end

    return Procedural:PlayAttack(character,move,payload or {})
end

function AnimationController:Bind(character: Model): CharacterData?
    if bound[character] then return bound[character] end

    local animator: Animator? = animatorOf(character)
    if not animator then return nil end

    local data: CharacterData={
        animator=animator,
        machine=StateMachine.new(),
        tracks={}
    }

    bound[character]=data
    return data
end

function AnimationController:Unbind(character: Model)
    local data=bound[character]
    if not data then return end
    Priority:StopAll(data.animator,0.04)
    bound[character]=nil
end

function AnimationController:Play(character: Model,key: string,payload: any,markerCallback: ((string,any)->())?): boolean
    local data=self:Bind(character)
    if not data then return false end

    local definition=Registry:Get(key)

    if not definition or definition.Id<=0 then
        return fallback(character,key,payload)
    end

    local track=Blender:Load(data.animator,definition.Id)
    if not track then
        return fallback(character,key,payload)
    end

    data.tracks[key]=track
    Priority:Play(data.animator,key,track,definition.Priority,definition.Fade)

    if markerCallback then
        for _,marker in ipairs(definition.Markers) do
            track:GetMarkerReachedSignal(marker):Connect(function(value)
                markerCallback(marker,value)
            end)
        end
    end

    track.Ended:Connect(function()
        if data.tracks[key]==track then
            data.tracks[key]=nil
        end
    end)

    return true
end

function AnimationController:SetState(character: Model,state: string)
    local data=self:Bind(character)
    if not data then return false end
    return data.machine:Set(state)
end

function AnimationController:ForceState(character: Model,state: string)
    local data=self:Bind(character)
    if data then data.machine:Force(state) end
end

function AnimationController:Stop(character: Model,key: string)
    local data=bound[character]
    if not data then return end
    Priority:Stop(data.animator,key,0.04)
    data.tracks[key]=nil
end

function AnimationController:PlayAttack(character: Model,move: string,comboOrOptions:any,power:any)
    local options=type(comboOrOptions)=="table" and comboOrOptions or {combo=comboOrOptions,power=power}
    return fallback(character,options and options.combo and "M1_"..tostring(options.combo) or "M1_1",options)
end

function AnimationController:PlaySkill(character: Model,skill: string,options:any)
    return fallback(character,"Skill1",{move=skill,options=options})
end

function AnimationController:PlayDomain(character: Model,options:any)
    return Procedural:PlayDomain(character,options or {})
end

function AnimationController:HitReact(character: Model,intensity:number,reaction:string)
    return Procedural:HitReact(character,intensity,reaction)
end

function AnimationController:ResetJoints(character: Model,duration:number?)
    return Procedural:ResetJoints(character,duration or 0.12)
end

function AnimationController:Cancel(character: Model)
    return Procedural:Cancel(character)
end

function AnimationController:StartIdleCombat(character: Model,intensity:number?)
    return Procedural:StartIdleCombat(character,intensity or 1)
end

function AnimationController:StopIdleCombat(character: Model)
    return Procedural:StopIdleCombat(character)
end

return AnimationController
