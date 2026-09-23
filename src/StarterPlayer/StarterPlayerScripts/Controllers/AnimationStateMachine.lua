--!strict

local AnimationStateMachine = {}
AnimationStateMachine.__index = AnimationStateMachine

local allowed = {
    Idle = {Running=true, Jumping=true, Falling=true, Attacking=true, Blocking=true, Dashing=true, UsingAbility=true, Ultimate=true, Awakening=true, Stunned=true, Ragdolled=true, Dead=true},
    Running = {Idle=true, Jumping=true, Falling=true, Attacking=true, Blocking=true, Dashing=true, UsingAbility=true, Ultimate=true, Awakening=true, Stunned=true, Ragdolled=true, Dead=true},
    Jumping = {Jumping=true, Falling=true, Attacking=true, Dashing=true, UsingAbility=true, Stunned=true, Ragdolled=true, Dead=true},
    Falling = {Falling=true, Idle=true, Jumping=true, Attacking=true, Dashing=true, UsingAbility=true, Stunned=true, Ragdolled=true, Dead=true},
    Attacking = {Attacking=true, Idle=true, Blocking=true, Dashing=true, UsingAbility=true, Stunned=true, Ragdolled=true, Ultimate=true, Awakening=true, Dead=true},
    Blocking = {Blocking=true, Idle=true, Attacking=true, Stunned=true, Ragdolled=true, Dead=true},
    Stunned = {Stunned=true, Idle=true, Falling=true, Ragdolled=true, Dead=true},
    Ragdolled = {Ragdolled=true, Idle=true, Falling=true, Dead=true},
    Dashing = {Dashing=true, Idle=true, Attacking=true, UsingAbility=true, Stunned=true, Ragdolled=true, Dead=true},
    UsingAbility = {UsingAbility=true, Idle=true, Attacking=true, Blocking=true, Stunned=true, Ragdolled=true, Ultimate=true, Awakening=true, Dead=true},
    Ultimate = {Ultimate=true, UsingAbility=true, Attacking=true, Idle=true, Stunned=true, Dead=true},
    Awakening = {Awakening=true, UsingAbility=true, Attacking=true, Idle=true, Stunned=true, Dead=true},
    Dead = {Dead=true}
}

function AnimationStateMachine.new()
    return setmetatable({State="Idle"}, AnimationStateMachine)
end

function AnimationStateMachine:CanEnter(nextState: string): boolean
    local current = self.State
    local transitions = allowed[current]
    return transitions ~= nil and transitions[nextState] == true
end

function AnimationStateMachine:Set(nextState: string): boolean
    if not self:CanEnter(nextState) then
        return false
    end
    self.State = nextState
    return true
end

function AnimationStateMachine:Force(nextState: string)
    self.State = nextState
end

function AnimationStateMachine:Is(nextState: string): boolean
    return self.State == nextState
end

return AnimationStateMachine
