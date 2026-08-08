return function(S, C, KillAura, Loopkill, Stockpile, RpgBlock)
    local Gui = {}
    
    -- State
    local screenGui = nil
    local mainFrame = nil
    local minimizedIcon = nil
    local isMinimized = false
    
    -- Toggles
    local killAuraEnabled = true
    local killAuraTpEnabled = true
    local loopkillEnabled = true
    local rpgBlockEnabled = true
    local ffRefreshEnabled = true
    
    -- ==================== CREATE GUI ====================
    local function createGUI()
        if screenGui then screenGui:Destroy() end
        
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "HarborDefender"
        screenGui.Parent = S.LocalPlayer:WaitForChild("PlayerGui")
        
        -- MINIMIZED ICON
        minimizedIcon = Instance.new("Frame")
        minimizedIcon.Name = "MinimizedIcon"
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
        iconText.Text = "🛡️"
        iconText.Font = Enum.Font.GothamBold
        iconText.TextSize = 20
        iconText.Parent = minimizedIcon
        
        minimizedIcon.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isMinimized = false
                minimizedIcon.Visible = false
                mainFrame.Visible = true
            end
        end)
        
        -- MAIN FRAME
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
        title.Position = UDim2.new(0, 0, 0, 0)
        title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Text = "Harbor Defender"
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
        minBtn.MouseButton1Click:Connect(function()
            isMinimized = true
            mainFrame.Visible = false
            minimizedIcon.Visible = true
        end)
        
        -- ==================== TAB SYSTEM ====================
        local tabButtons = {}
        local tabFrames = {}
        
        local function switchTab(tabName)
            for name, frame in pairs(tabFrames) do
                frame.Visible = (name == tabName)
            end
            for name, btn in pairs(tabButtons) do
                btn.BackgroundColor3 = (name == tabName) and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(35, 35, 35)
            end
        end
        
        local tabY = 35
        local tabs = {"Toggles", "Targets"}
        for i, tabName in ipairs(tabs) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.5, -2, 0, 25)
            btn.Position = UDim2.new((i-1) * 0.5, 1, 0, tabY)
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = tabName
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            btn.Parent = mainFrame
            tabButtons[tabName] = btn
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -10, 1, -(tabY + 30))
            frame.Position = UDim2.new(0, 5, 0, tabY + 25)
            frame.BackgroundTransparency = 1
            frame.Visible = (i == 1)
            frame.Parent = mainFrame
            tabFrames[tabName] = frame
            
            btn.MouseButton1Click:Connect(function() switchTab(tabName) end)
        end
        
        -- ==================== TOGGLES TAB ====================
        local toggleFrame = tabFrames["Toggles"]
        local yOff = 5
        
        local function createToggle(name, default, parent, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 32)
            btn.Position = UDim2.new(0, 0, 0, yOff)
            btn.BackgroundColor3 = default and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = name .. ": " .. (default and "ON" or "OFF")
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            btn.Parent = parent
            
            local state = default
            btn.MouseButton1Click:Connect(function()
                state = not state
                btn.BackgroundColor3 = state and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
                btn.Text = name .. ": " .. (state and "ON" or "OFF")
                callback(state)
            end)
            
            yOff = yOff + 35
            return btn
        end
        
        -- Toggles tab (no Targeted Loopkill here)
        createToggle("Kill Aura", killAuraEnabled, toggleFrame, function(v) killAuraEnabled = v end)
        createToggle("Kill Aura TP", killAuraTpEnabled, toggleFrame, function(v) killAuraTpEnabled = v end)
        createToggle("Loopkill", loopkillEnabled, toggleFrame, function(v) loopkillEnabled = v end)
        createToggle("RPG Block", rpgBlockEnabled, toggleFrame, function(v) rpgBlockEnabled = v end)
        createToggle("FF Refresh", ffRefreshEnabled, toggleFrame, function(v) ffRefreshEnabled = v end)
        
        -- Stats
        local statsLabel = Instance.new("TextLabel")
        statsLabel.Size = UDim2.new(1, 0, 0, 20)
        statsLabel.Position = UDim2.new(0, 0, 0, yOff + 5)
        statsLabel.BackgroundTransparency = 1
        statsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        statsLabel.Text = "Missiles: 0 | Targets: 0"
        statsLabel.Font = Enum.Font.Gotham
        statsLabel.TextSize = 11
        statsLabel.Parent = toggleFrame
        
        -- ==================== TARGETS TAB ====================
        local targetsFrame = tabFrames["Targets"]
        
        -- Username input section
        local inputFrame = Instance.new("Frame")
        inputFrame.Size = UDim2.new(1, 0, 0, 35)
        inputFrame.Position = UDim2.new(0, 0, 0, 0)
        inputFrame.BackgroundTransparency = 1
        inputFrame.Parent = targetsFrame
        
        local inputBox = Instance.new("TextBox")
        inputBox.Size = UDim2.new(0.6, -5, 0, 30)
        inputBox.Position = UDim2.new(0, 0, 0, 0)
        inputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        inputBox.PlaceholderText = "Username..."
        inputBox.Font = Enum.Font.Gotham
        inputBox.TextSize = 12
        inputBox.Parent = inputFrame
        
        local addBtn = Instance.new("TextButton")
        addBtn.Size = UDim2.new(0.35, 0, 0, 30)
        addBtn.Position = UDim2.new(0.63, 0, 0, 0)
        addBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        addBtn.Text = "Add"
        addBtn.Font = Enum.Font.GothamBold
        addBtn.TextSize = 13
        addBtn.Parent = inputFrame
        addBtn.MouseButton1Click:Connect(function()
            local name = inputBox.Text
            if name and name ~= "" then
                KillAura.getLoopkillTargets()[name] = true
                inputBox.Text = ""
                print("➕ Added loopkill target:", name)
            end
        end)
        
        -- Scrolling target list
        local targetListFrame = Instance.new("ScrollingFrame")
        targetListFrame.Size = UDim2.new(1, 0, 1, -40)
        targetListFrame.Position = UDim2.new(0, 0, 0, 40)
        targetListFrame.BackgroundTransparency = 1
        targetListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        targetListFrame.ScrollBarThickness = 6
        targetListFrame.Parent = targetsFrame
        
        local targetListLayout = Instance.new("UIListLayout")
        targetListLayout.Padding = UDim.new(0, 3)
        targetListLayout.Parent = targetListFrame
        
        -- Refresh target list
        local function refreshTargetList()
            for _, child in ipairs(targetListFrame:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end
            
            local loopkillTargets = KillAura.getLoopkillTargets()
            local ySize = 0
            
            -- Show manually added targets first (even if not in game)
            for name, _ in pairs(loopkillTargets) do
                local found = false
                for _, pl in ipairs(S.Players:GetPlayers()) do
                    if pl.Name == name then found = true; break end
                end
                
                if not found then
                    local entryFrame = Instance.new("Frame")
                    entryFrame.Size = UDim2.new(1, 0, 0, 30)
                    entryFrame.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
                    entryFrame.BorderSizePixel = 0
                    entryFrame.Parent = targetListFrame
                    
                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
                    nameLabel.Position = UDim2.new(0, 5, 0, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                    nameLabel.Text = name .. " (offline)"
                    nameLabel.Font = Enum.Font.Gotham
                    nameLabel.TextSize = 11
                    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    nameLabel.Parent = entryFrame
                    
                    local removeBtn = Instance.new("TextButton")
                    removeBtn.Size = UDim2.new(0.35, 0, 1, -4)
                    removeBtn.Position = UDim2.new(0.63, 0, 0, 2)
                    removeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
                    removeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    removeBtn.Text = "Remove"
                    removeBtn.Font = Enum.Font.Gotham
                    removeBtn.TextSize = 11
                    removeBtn.Parent = entryFrame
                    
                    removeBtn.MouseButton1Click:Connect(function()
                        loopkillTargets[name] = nil
                        print("➖ Removed loopkill target:", name)
                    end)
                    
                    ySize = ySize + 33
                end
            end
            
            -- Show active players
            for _, pl in ipairs(S.Players:GetPlayers()) do
                if pl ~= S.LocalPlayer and pl.Team ~= S.LocalPlayer.Team and pl.Character then
                    local isLoopkilled = loopkillTargets[pl.Name] == true
                    local hasFF = false
                    for _, child in ipairs(pl.Character:GetDescendants()) do
                        if child:IsA("ForceField") then hasFF = true; break end
                    end
                    
                    local entryFrame = Instance.new("Frame")
                    entryFrame.Size = UDim2.new(1, 0, 0, 30)
                    entryFrame.BackgroundColor3 = isLoopkilled and Color3.fromRGB(50, 30, 30) or Color3.fromRGB(30, 30, 30)
                    entryFrame.BorderSizePixel = 0
                    entryFrame.Parent = targetListFrame
                    
                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
                    nameLabel.Position = UDim2.new(0, 5, 0, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    nameLabel.Text = pl.Name .. (hasFF and " ⚡" or "")
                    nameLabel.Font = Enum.Font.Gotham
                    nameLabel.TextSize = 12
                    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    nameLabel.Parent = entryFrame
                    
                    local actionBtn = Instance.new("TextButton")
                    actionBtn.Size = UDim2.new(0.35, 0, 1, -4)
                    actionBtn.Position = UDim2.new(0.63, 0, 0, 2)
                    
                    if isLoopkilled then
                        actionBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
                        actionBtn.Text = "Remove"
                        actionBtn.Font = Enum.Font.Gotham
                        actionBtn.TextSize = 11
                        actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        actionBtn.Parent = entryFrame
                        
                        local targetName = pl.Name
                        actionBtn.MouseButton1Click:Connect(function()
                            loopkillTargets[targetName] = nil
                            print("➖ Removed loopkill target:", targetName)
                        end)
                    else
                        actionBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
                        actionBtn.Text = "Add"
                        actionBtn.Font = Enum.Font.Gotham
                        actionBtn.TextSize = 11
                        actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        actionBtn.Parent = entryFrame
                        
                        local targetName = pl.Name
                        actionBtn.MouseButton1Click:Connect(function()
                            loopkillTargets[targetName] = true
                            print("➕ Added loopkill target:", targetName)
                        end)
                    end
                    
                    ySize = ySize + 33
                end
            end
            
            targetListFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(ySize, 200))
        end
        
        -- Periodic updates
        task.spawn(function()
            while screenGui and screenGui.Parent do
                local stockCount = Stockpile and Stockpile.count() or 0
                local targetCount = KillAura and KillAura.getLoopkillTargets() and table.count(KillAura.getLoopkillTargets()) or 0
                statsLabel.Text = string.format("Missiles: %d | Loopkilled: %d", stockCount, targetCount)
                pcall(refreshTargetList)
                task.wait(2)
            end
        end)
    end
    
    -- State getters
    function Gui.isKillAuraEnabled() return killAuraEnabled end
    function Gui.isKillAuraTpEnabled() return killAuraTpEnabled end
    function Gui.isLoopkillEnabled() return loopkillEnabled end
    function Gui.isRpgBlockEnabled() return rpgBlockEnabled end
    function Gui.isFFRefreshEnabled() return ffRefreshEnabled end
    
    function Gui.init() createGUI(); print("🖥️ GUI loaded") end
    function Gui.destroy()
        if screenGui then screenGui:Destroy(); screenGui = nil end
    end
    
    return Gui
end
