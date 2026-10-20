local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Workspace = game:GetService("Workspace")
if Workspace:GetAttribute("EnableStealAnimalAudit") ~= true then return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local tests = {}
local passed = 0
local failed = 0
local warnings = 0

local function record(name, condition, detail, warningOnly)
    local status = warningOnly and "WARN" or condition and "PASS" or "FAIL"
    table.insert(tests, {
        name = tostring(name),
        status = status,
        detail = tostring(detail or ""),
    })
    if status == "PASS" then
        passed += 1
    elseif status == "FAIL" then
        failed += 1
    else
        warnings += 1
    end
    print("[STEAL_ANIMAL_AUDIT_CLIENT][" .. status .. "] " .. tostring(name) .. " — " .. tostring(detail or ""))
end

local function waitUntil(predicate, timeout)
    local deadline = os.clock() + timeout
    repeat
        local ok, value = pcall(predicate)
        if ok and value then return true end
        task.wait(0.1)
    until os.clock() >= deadline
    local ok, value = pcall(predicate)
    return ok and value == true
end

local function isVisibleOnScreen(object, viewport)
    if not object or not object:IsA("GuiObject") or not object.Visible then
        return false
    end
    local position = object.AbsolutePosition
    local size = object.AbsoluteSize
    return size.X > 0 and size.Y > 0
        and position.X >= -1 and position.Y >= -1
        and position.X + size.X <= viewport.X + 1
        and position.Y + size.Y <= viewport.Y + 1
end

local function overlaps(a, b)
    if not a or not b then return false end
    local ap, as = a.AbsolutePosition, a.AbsoluteSize
    local bp, bs = b.AbsolutePosition, b.AbsoluteSize
    return ap.X < bp.X + bs.X and ap.X + as.X > bp.X
        and ap.Y < bp.Y + bs.Y and ap.Y + as.Y > bp.Y
end

local function clickButton(virtualInput, button)
    if not button or not button:IsA("GuiButton") or not button.Visible then
        return false, "Botão indisponível"
    end
    local position = button.AbsolutePosition + button.AbsoluteSize / 2
    local ok, err = pcall(function()
        virtualInput:SendMouseButton(position, Enum.UserInputType.MouseButton1, true, 0)
        task.wait(0.06)
        virtualInput:SendMouseButton(position, Enum.UserInputType.MouseButton1, false, 0)
    end)
    if not ok then return false, tostring(err) end
    return true, ""
end

local loaded = waitUntil(function()
    return playerGui:FindFirstChild("StealAnAnimalHUD") ~= nil
end, 35)
local gui = playerGui:FindFirstChild("StealAnAnimalHUD")
record("HUD do jogo inicializa", loaded and gui ~= nil, "StealAnAnimalHUD")

local camera = Workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(0, 0)
record("Câmera e viewport acessíveis", viewport.X > 0 and viewport.Y > 0,
    tostring(math.floor(viewport.X)) .. "x" .. tostring(math.floor(viewport.Y)))

if gui then
    record("HUD respeita Core UI safe insets",
        gui:IsA("ScreenGui") and gui.ScreenInsets == Enum.ScreenInsets.CoreUISafeInsets,
        tostring(gui.ScreenInsets))

    local top = gui:FindFirstChild("TopDashboard")
    local resources = top and top:FindFirstChild("ResourceCards")
    local objective = gui:FindFirstChild("ContextObjective")
    local dock = gui:FindFirstChild("QuickActions")
    local modalShade = gui:FindFirstChild("ModalShade")
    local modal = modalShade and modalShade:FindFirstChild("Modal")

    record("Painel de recursos existe", top ~= nil and resources ~= nil,
        "TopDashboard / ResourceCards")
    record("Objetivo contextual existe", objective ~= nil and objective:FindFirstChild("Text") ~= nil,
        "ContextObjective")
    record("Atalhos rápidos existem", dock ~= nil,
        "QuickActions")
    record("Menu modal e lista existem", modal ~= nil and modal:FindFirstChild("MenuList") ~= nil,
        "Modal / MenuList")

    if top and objective and dock and viewport.X > 0 and viewport.Y > 0 then
        task.wait(0.4)
        record("Cabeçalho inteiro permanece na tela", isVisibleOnScreen(top, viewport),
            tostring(top.AbsoluteSize.X) .. "x" .. tostring(top.AbsoluteSize.Y))
        record("Objetivo permanece na tela", isVisibleOnScreen(objective, viewport),
            tostring(objective.AbsolutePosition))
        record("Atalhos não invadem a região inferior de toque",
            dock.AbsolutePosition.Y + dock.AbsoluteSize.Y < viewport.Y * 0.78,
            "Fim do menu Y=" .. tostring(math.floor(dock.AbsolutePosition.Y + dock.AbsoluteSize.Y))
                .. " de " .. tostring(math.floor(viewport.Y)))
        record("Cabeçalho não se sobrepõe ao objetivo", not overlaps(top, objective),
            "Verificação geométrica de retângulos")
        record("Atalhos não se sobrepõem ao cabeçalho nem ao objetivo",
            not overlaps(dock, top) and not overlaps(dock, objective),
            "Verificação geométrica de retângulos")

        local mobileTargetsOkay = true
        local mobileTargetDetails = {}
        for _, name in ipairs({ "OpenShop", "OpenIndex", "OpenMore" }) do
            local button = dock:FindFirstChild(name)
            local visible = button ~= nil and isVisibleOnScreen(button, viewport)
            record("Atalho " .. name .. " está visível e dentro da tela", visible,
                button and (tostring(math.floor(button.AbsoluteSize.X)) .. "x" .. tostring(math.floor(button.AbsoluteSize.Y))) or "ausente")
            if button then
                local size = button.AbsoluteSize
                table.insert(mobileTargetDetails, name .. "=" .. tostring(math.floor(size.X)) .. "x" .. tostring(math.floor(size.Y)))
                if UserInputService.TouchEnabled and (size.X < 44 or size.Y < 44) then
                    mobileTargetsOkay = false
                end
            else
                mobileTargetsOkay = false
            end
        end
        if UserInputService.TouchEnabled then
            record("Atalhos respeitam alvo tátil mínimo de 44px", mobileTargetsOkay,
                table.concat(mobileTargetDetails, ", "))
        else
            record("Entrada tátil está emulada", false,
                "TouchEnabled=false nesta sessão. Para validar alvos táteis reais, ative um perfil Phone no Device Simulator.", true)
        end

        local rebirth = top:FindFirstChild("RebirthBadge")
        record("Acesso ao renascimento existe", rebirth ~= nil and rebirth:IsA("GuiButton") and rebirth.Visible,
            "RebirthBadge")

        local statNames = { "CoinsCard", "IncomeCard", "SpeedCard" }
        local statsOkay = resources ~= nil
        local statDetails = {}
        for _, name in ipairs(statNames) do
            local card = resources and resources:FindFirstChild(name)
            local value = card and card:FindFirstChild("Value")
            if not value or not value:IsA("TextLabel") or value.Text == "" then
                statsOkay = false
            end
            table.insert(statDetails, name .. "=" .. tostring(value and value.Text or "ausente"))
        end
        record("Contadores de economia e movimento são renderizados", statsOkay,
            table.concat(statDetails, ", "))

        local virtualOk, virtualInput = pcall(function()
            return UserInputService:CreateVirtualInput()
        end)
        if virtualOk and virtualInput then
            local more = dock:FindFirstChild("OpenMore")
            local sentMore, moreError = clickButton(virtualInput, more)
            local moreOpened = sentMore and waitUntil(function()
                return modalShade and modalShade.Visible and modal
                    and modal:FindFirstChild("ModalTitle")
                    and modal.ModalTitle.Text == "PROGRESSO E SISTEMA"
            end, 3)
            record("Toque simulado abre o menu Mais", moreOpened,
                moreOpened and "Painel aberto" or tostring(moreError))

            local close = modal and modal:FindFirstChild("Close")
            local sentClose, closeError = clickButton(virtualInput, close)
            local closed = sentClose and waitUntil(function()
                return modalShade and not modalShade.Visible
            end, 3)
            record("Toque simulado fecha o menu", closed,
                closed and "Painel fechado" or tostring(closeError))

            local index = dock:FindFirstChild("OpenIndex")
            local sentIndex, indexError = clickButton(virtualInput, index)
            local indexOpened = sentIndex and waitUntil(function()
                return modalShade and modalShade.Visible and modal
                    and modal:FindFirstChild("ModalTitle")
                    and modal.ModalTitle.Text == "ÍNDICE ANIMAL"
            end, 3)
            record("Toque simulado abre o índice animal", indexOpened,
                indexOpened and "Índice aberto" or tostring(indexError))

            sentClose, closeError = clickButton(virtualInput, close)
            closed = sentClose and waitUntil(function()
                return modalShade and not modalShade.Visible
            end, 3)
            record("Índice animal fecha sem travar a partida", closed,
                closed and "Retorno à partida" or tostring(closeError))

            local shop = dock:FindFirstChild("OpenShop")
            local sentShop, shopError = clickButton(virtualInput, shop)
            local shopOpened = sentShop and waitUntil(function()
                return modalShade and modalShade.Visible and modal
                    and modal:FindFirstChild("ModalTitle")
                    and modal.ModalTitle.Text == "LOJA DE MELHORIAS"
            end, 3)
            record("Toque simulado abre a loja", shopOpened,
                shopOpened and "Loja aberta; nenhuma compra executada" or tostring(shopError))

            sentClose, closeError = clickButton(virtualInput, close)
            closed = sentClose and waitUntil(function()
                return modalShade and not modalShade.Visible
            end, 3)
            record("Loja fecha sem travar a partida", closed,
                closed and "Retorno à partida" or tostring(closeError))

            local rebirthButton = top:FindFirstChild("RebirthBadge")
            local sentRebirth, rebirthError = clickButton(virtualInput, rebirthButton)
            local rebirthOpened = sentRebirth and waitUntil(function()
                return modalShade and modalShade.Visible and modal
                    and modal:FindFirstChild("ModalTitle")
                    and modal.ModalTitle.Text == "RENASCIMENTO"
            end, 3)
            record("Toque simulado abre requisitos de renascimento", rebirthOpened,
                rebirthOpened and "Somente tela de requisitos aberta" or tostring(rebirthError))

            sentClose, closeError = clickButton(virtualInput, close)
            closed = sentClose and waitUntil(function()
                return modalShade and not modalShade.Visible
            end, 3)
            record("Renascimento fecha sem executar a ação", closed,
                closed and "Nenhum renascimento executado" or tostring(closeError))
        else
            record("Testes de toque virtual", false,
                "VirtualInput indisponível: " .. tostring(virtualInput), true)
        end
    end
end

local profileLoaded = player:GetAttribute("ProfileLoaded") == true
if profileLoaded then
    record("Perfil chegou ao cliente", true, "Atributos de gameplay podem ser lidos")
else
    record("Perfil chegou ao cliente", false,
        "Perfil ainda não está disponível; verificar configuração de API Services no Studio", true)
end

local report = {
    client = player.Name,
    passed = passed,
    failed = failed,
    warnings = warnings,
    touchEnabled = UserInputService.TouchEnabled,
    viewport = {
        width = math.floor(viewport.X),
        height = math.floor(viewport.Y),
    },
    uiScale = gui and gui:FindFirstChild("ResponsiveScale") and gui.ResponsiveScale.Scale or nil,
    tests = tests,
}
local encoded = HttpService:JSONEncode(report)
print("[STEAL_ANIMAL_AUDIT_CLIENT_REPORT]" .. encoded)

local reportRemote = ReplicatedStorage:WaitForChild("StealAnimalAuditReport", 20)
if reportRemote and reportRemote:IsA("RemoteEvent") then
    reportRemote:FireServer(report)
else
    warn("[STEAL_ANIMAL_AUDIT_CLIENT] O servidor não criou StealAnimalAuditReport; o resultado só está no Output deste cliente.")
end
