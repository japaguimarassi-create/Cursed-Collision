local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local RebirthService = {}
local profiles
local animalService
local requestRemote
local notify
local cooldowns = {}
local started = false

function RebirthService.Start(profileService, animals, remote, notifyFunction)
    if started then
        return
    end

    started = true
    profiles = profileService
    animalService = animals
    requestRemote = remote
    notify = notifyFunction

    requestRemote.OnServerEvent:Connect(function(player)
        if player.Parent ~= Players or not profiles.IsLoaded(player) then
            return
        end

        local now = os.clock()
        if now - (cooldowns[player] or 0) < 2 then
            return
        end
        cooldowns[player] = now

        if player:GetAttribute("CarryingAnimal") then
            notify(player, "Venda ou perca o animal carregado antes de renascer.", "Warning")
            return
        end

        player:SetAttribute("RebirthInProgress", true)
        local callSucceeded, success, result = pcall(profiles.PerformRebirth, player)
        player:SetAttribute("RebirthInProgress", false)

        if not callSucceeded then
            warn("RoubeUmAnimal: falha no renascimento: " .. tostring(success))
            notify(player, "O renascimento falhou com segurança. Seus dados não foram reiniciados.", "Error")
            return
        end

        if not success then
            local messages = {
                ["requirements"] = "Para renascer, alcance Velocidade " .. Config.MaxSpeedLevel .. " e Força " .. Config.MaxStrength .. ".",
                ["carrying-animal"] = "Você não pode renascer enquanto carrega um animal.",
                ["max-rebirths"] = "Você já atingiu o limite de renascimentos.",
                ["profile-not-loaded"] = "Seus dados ainda não estão prontos.",
                ["profile-busy"] = "Seus dados estão sendo salvos. Tente novamente.",
                ["datastore-error"] = "Não foi possível salvar o renascimento. Nenhum progresso foi reiniciado.",
                ["session-lock"] = "A sessão perdeu o bloqueio dos dados. Entre novamente para evitar perda de progresso.",
            }
            notify(player, messages[result] or "Renascimento cancelado com segurança.", "Warning")
            return
        end

        animalService.ApplyMovement(player)
        notify(
            player,
            "Renascimento " .. tostring(result) .. " concluído! Você ganhou +" .. tostring(Config.RebirthCoinBonusPerRebirth * 100) .. "% de moedas permanentes por renascimento.",
            "Success"
        )
    end)
end

function RebirthService.RemovePlayer(player)
    cooldowns[player] = nil
    if player:GetAttribute("RebirthInProgress") then
        player:SetAttribute("RebirthInProgress", false)
    end
end

return RebirthService
