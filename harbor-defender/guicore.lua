return function(S, C, KillAura, Stockpile)
    local GuiCore = {}
    
    local screenGui = nil
    local mainFrame = nil
    local minimizedIcon = nil
    local tabFrames = {}
    
    -- Global toggles
    local killAuraEnabled = false
    local killAuraTpEnabled = false
    local loopkillEnabled = false
    local rpgBlockEnabled = false
    local ffRefreshEnabled = false
    
    function GuiCore.getScreenGui() return screenGui end
    function GuiCore.getMainFrame() return mainFrame end
    function GuiCore.getTabFrame(name) return tabFrames[name] end
    
    -- Toggle getters
    function GuiCore.isKillAuraEnabled() return killAuraEnabled end
    function GuiCore.isKillAuraTpEnabled() return killAuraTpEnabled end
    function GuiCore.isLoopkillEnabled() return loopkillEnabled end
    function GuiCore.isRpgBlockEnabled() return rpgBlockEnabled end
    function GuiCore.isFFRefreshEnabled() return ffRefreshEnabled end
    
    -- Toggle setters
    function GuiCore.setKillAuraEnabled(v) killAuraEnabled = v end
    function GuiCore.setKillAuraTpEnabled(v) killAuraTpEnabled = v end
    function GuiCore.setLoopkillEnabled(v) loopkillEnabled = v end
    function GuiCore.setRpgBlockEnabled(v) rpgBlockEnabled = v end
    function GuiCore.setFFRefreshEnabled(v) ffRefreshEnabled = v end
    
    function GuiCore.init()
        if screenGui then screenGui:Destroy() end
        
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "HarborDefender"
        screenGui.Parent = S.LocalPlayer:WaitForChild("PlayerGui")
        
        -- Minimized icon
        minimizedIcon = Instance.new("Frame")
        minimizedIcon.Size = UDim2.new(0, 40, 0, 40)
        minimizedIcon.Position = UDim2.new(1, -50, 0, 10)
        minimizedIcon.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        minimizedIcon.BackgroundTransparency = 0.1
        minimizedIcon.BorderSizePixel = 0
        minimizedIcon.Active = true
        minimizedIcon.Draggable = true
        minimizedIcon.Visible = false
        minimizedIcon.Parent = screenGui
        
        local iconText = Instance.new("TextLabel")
        iconText.Size = UDim2.new(1, 0, 1, 0)
        iconText.BackgroundTransparency = 1
        iconText.TextColor3 = Color3.fromRGB(255, 255, 255)
        iconText.Text = "🥰"
        iconText.Font = Enum.Font.GothamBold
        iconText.TextSize = 20
        iconText.Parent = minimizedIcon
        
        -- Main frame
        mainFrame = Instance.new("Frame")
        mainFrame.Size = UDim2.new(0, 240, 0, 280)
        mainFrame.Position = UDim2.new(1, -250, 0, 10)
        mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        mainFrame.BackgroundTransparency = 0.1
        mainFrame.BorderSizePixel = 0
        mainFrame.Active = true
        mainFrame.Draggable = true
        mainFrame.Parent = screenGui
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -35, 0, 30)
        title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Text = "AntiCheat v3"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16
        title.Parent = mainFrame
        
        -- Minimize button
        local minBtn = Instance.new("TextButton")
        minBtn.Size = UDim2.new(0, 30, 0, 30)
        minBtn.Position = UDim2.new(1, -30, 0, 0)
        minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        minBtn.Text = "_"
        minBtn.Font = Enum.Font.GothamBold
        minBtn.TextSize = 18
        minBtn.Parent = mainFrame
        
        -- Minimize/maximize toggle
        minimizedIcon.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                minimizedIcon.Visible = false
                mainFrame.Visible = true
            end
        end)

        minBtn.MouseButton1Click:Connect(function()
            mainFrame.Visible = false
            minimizedIcon.Visible = true
        end)
        
        -- Tab system
        local tabButtons = {}
        local tabs = {"Toggles", "Targets"}
        
        for i, tabName in ipairs(tabs) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.5, -2, 0, 25)
            btn.Position = UDim2.new((i-1) * 0.5, 1, 0, 35)
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = tabName
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            btn.Parent = mainFrame
            tabButtons[tabName] = btn
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 1, -65)
            frame.Position = UDim2.new(0, 5, 0, 60)
            frame.BackgroundTransparency = 1
            frame.Visible = (i == 1)
            frame.Parent = mainFrame
            tabFrames[tabName] = frame
            
            local tName = tabName
            btn.MouseButton1Click:Connect(function()
                for _, f in pairs(tabFrames) do f.Visible = false end
                for _, b in pairs(tabButtons) do b.BackgroundColor3 = Color3.fromRGB(35, 35, 35) end
                tabFrames[tName].Visible = true
                btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            end)
        end
    end
    
    function GuiCore.destroy()
        if screenGui then screenGui:Destroy(); screenGui = nil end
    end
    
    return GuiCore
end
