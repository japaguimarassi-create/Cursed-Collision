--!strict

local names = {"Health", "Credits", "Wave", "Enemies", "Elite", "M1", "Dash", "Menu"}

local Contract = {}

function Contract.required(name: string): boolean
    for _, value in ipairs(names) do
        if value == name then
            return true
        end
    end
    return false
end

function Contract.count(): number
    return #names
end

return Contract