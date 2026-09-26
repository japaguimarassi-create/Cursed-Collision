--!strict
local Service={}
local function loadTrack(animator:Animator,name:string,id:number,priority:Enum.AnimationPriority,looped:boolean)
    local animation=Instance.new("Animation"); animation.Name="CBS_"..name; animation.AnimationId="rbxassetid://"..tostring(id)
    local ok,track=pcall(function() return animator:LoadAnimation(animation) end); animation:Destroy()
    if not ok or not track then return nil end
    track.Priority=priority; track.Looped=looped; return track
end
function Service.Setup(humanoid:Humanoid,config)
    local animator=humanoid:FindFirstChildOfClass("Animator")
    if not animator then animator=Instance.new("Animator"); animator.Parent=humanoid end
    local ids=config.NPCAssets.Animations
    local tracks={
        Idle=loadTrack(animator,"Idle",ids.Idle,Enum.AnimationPriority.Idle,true),
        Walk=loadTrack(animator,"Walk",ids.Walk,Enum.AnimationPriority.Movement,true),
        Run=loadTrack(animator,"Run",ids.Run,Enum.AnimationPriority.Movement,true),
        Jump=loadTrack(animator,"Jump",ids.Jump,Enum.AnimationPriority.Movement,false),
        Fall=loadTrack(animator,"Fall",ids.Fall,Enum.AnimationPriority.Movement,true),
        Attack=loadTrack(animator,"Attack",ids.Attack,Enum.AnimationPriority.Action,false),
    }
    local state={Tracks=tracks,Locomotion="Idle"}
    local function stopLocomotion(except)
        for _,name in ipairs({"Idle","Walk","Run","Jump","Fall"}) do
            local track=tracks[name]
            if track and track~=except and track.IsPlaying then track:Stop(0.12) end
        end
    end
    function state:Play(name:string,fade:number?,speed:number?)
        local track=self.Tracks[name]; if not track then return end
        if name=="Attack" then track:Play(fade or 0.06,1,speed or 1); return end
        stopLocomotion(track)
        if not track.IsPlaying then track:Play(fade or 0.14,1,speed or 1) else track:AdjustSpeed(speed or 1) end
        self.Locomotion=name
    end
    function state:SetLocomotion(moveSpeed:number,stateType:Enum.HumanoidStateType?)
        local current=stateType or humanoid:GetState()
        if current==Enum.HumanoidStateType.Jumping then self:Play("Jump",0.08,1); return end
        if current==Enum.HumanoidStateType.Freefall then self:Play("Fall",0.1,1); return end
        if moveSpeed<=0.4 then self:Play("Idle",0.18,1)
        elseif moveSpeed>=15 then self:Play("Run",0.12,math.clamp(moveSpeed/15,0.85,1.35))
        else self:Play("Walk",0.12,math.clamp(moveSpeed/11,0.8,1.3)) end
    end
    state:Play("Idle",0,1)
    return state
end
return Service