local InteractionPrompt = {}

function InteractionPrompt.mount(services)
    local gui = services.Gui
    local COLORS = services.Colors
    local round = services.Round
    local outline = services.Outline
    local makeLabel = services.MakeLabel
    local makeButton = services.MakeButton
    local ProximityPromptService = game:GetService("ProximityPromptService")
    local UserInputService = game:GetService("UserInputService")

    local promptCard = Instance.new("Frame")
    promptCard.Name = "CompactInteractionPrompt"
    promptCard.AnchorPoint = Vector2.new(0.5, 0)
    promptCard.Position = UDim2.new(0.5, 0, 0, 300)
    promptCard.Size = UDim2.new(0.68, 0, 0, 48)
    promptCard.BackgroundColor3 = COLORS.Panel
    promptCard.BackgroundTransparency = 0.08
    promptCard.BorderSizePixel = 0
    promptCard.Visible = false
    promptCard.ZIndex = 45
    promptCard.Parent = gui
    round(promptCard, 12)
    outline(promptCard, COLORS.Mint, 1, 0.25)
    local promptConstraint = Instance.new("UISizeConstraint")
    promptConstraint.MaxSize = Vector2.new(280, 48)
    promptConstraint.MinSize = Vector2.new(220, 48)
    promptConstraint.Parent = promptCard
    
    local promptObjectLabel = makeLabel(promptCard, "Object", "INTERAÇÃO", UDim2.new(1, -92, 0, 13), UDim2.new(0, 12, 0, 4), 9, COLORS.Muted, Enum.Font.GothamBold)
    promptObjectLabel.ZIndex = 46
    promptObjectLabel.TextTruncate = Enum.TextTruncate.AtEnd
    local promptActionLabel = makeLabel(promptCard, "Action", "", UDim2.new(1, -92, 0, 22), UDim2.new(0, 12, 0, 19), 13, COLORS.Cream, Enum.Font.GothamBlack)
    promptActionLabel.ZIndex = 46
    promptActionLabel.TextTruncate = Enum.TextTruncate.AtEnd
    local promptButton = makeButton(promptCard, "Interact", "TOQUE", COLORS.Mint, COLORS.Background)
    promptButton.AnchorPoint = Vector2.new(1, 0.5)
    promptButton.Position = UDim2.new(1, -7, 0.5, 0)
    promptButton.Size = UDim2.fromOffset(72, 34)
    promptButton.TextSize = 10
    promptButton.ZIndex = 46
    round(promptButton, 9)
    
    local activePrompt = nil
    local promptHolding = false
    local holdInput = nil
    local function endPromptHold()
        if promptHolding and activePrompt and activePrompt.Parent then
            activePrompt:InputHoldEnd()
        end
        promptHolding = false
        holdInput = nil
    end
    
    promptButton.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end
        if not activePrompt or not activePrompt.Parent then
            return
        end
        promptHolding = true
        holdInput = input
        activePrompt:InputHoldBegin()
    end)

    UserInputService.InputEnded:Connect(function(input)
        if holdInput and input == holdInput then
            endPromptHold()
        end
    end)
    
    ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
        activePrompt = prompt
        promptHolding = false
        promptObjectLabel.Text = prompt.ObjectText ~= "" and prompt.ObjectText or "INTERAÇÃO"
        promptActionLabel.Text = string.upper(prompt.ActionText)
        if inputType == Enum.ProximityPromptInputType.Touch then
            promptButton.Text = prompt.HoldDuration > 0 and "SEGURE" or "TOQUE"
        else
            promptButton.Text = "[" .. prompt.KeyboardKeyCode.Name .. "]"
        end
        promptCard.Visible = true
    end)
    
    ProximityPromptService.PromptHidden:Connect(function(prompt)
        if activePrompt ~= prompt then
            return
        end
        endPromptHold()
        activePrompt = nil
        promptCard.Visible = false
    end)

    return {
        Card = promptCard,
        GetActivePrompt = function()
            return activePrompt
        end,
        Hide = function()
            endPromptHold()
            activePrompt = nil
            promptCard.Visible = false
        end,
    }
end

return InteractionPrompt
