--!strict

local PlayableRoster = {}

PlayableRoster.Order = {
    "Yuji",
    "Gojo",
    "Sukuna",
    "Megumi"
}

PlayableRoster.Default = "Yuji"

PlayableRoster.IsPlayable = {
    Yuji = true,
    Gojo = true,
    Sukuna = true,
    Megumi = true
}

function PlayableRoster:Contains(id: string): boolean
    return self.IsPlayable[id] == true
end

return PlayableRoster
