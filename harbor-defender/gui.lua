return function(S, C, KillAura, Loopkill, Stockpile, RpgBlock)
    local Gui = {}
    
    -- State
    local screenGui = nil
    local mainFrame = nil
    local killAuraEnabled = true
    local loopkillEnabled = true
    local rpgBlockEnabled = true
    local ffRefreshEnabled = true
    
    -- Create the GUI
    local function createGUI()
        -- Clean up old GUI if exists
        if screenGui then screenGui:Destroy() end
        
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "HarborDefender"
        screenGui.Parent = S.LocalPlayer:WaitForChild("PlayerGui")
        
        -- Main frame
        mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(0, 220, 0, 200)
        mainFrame.Position = UDim2.new(1, -230, 0, 10)
        mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        mainFrame.BackgroundTransparency = 0.1
        mainFrame.BorderSizePixel = 0
        mainFrame.Active = true
        mainFrame.Draggable = true
        mainFrame.Parent = screenGui
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0, 30)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Text = "Harbor Defender"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 16
        title.Parent = mainFrame
        
        -- Close button
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "Close"
        closeBtn.Size = UDim2.new(0, 30, 0, 30)
        closeBtn.Position = UDim2.new(1, -30, 0, 0)
        closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.Text = "X"
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 14
        closeBtn.Parent = mainFrame
        closeBtn.MouseButton1Click:Connect(function()
            mainFrame.Visible = not mainFrame.Visible
        end)
        
        local yOffset = 35
        
        -- Helper to create toggle buttons
        local function createToggle(name, default, callback)
            local btn = Instance.new("TextButton")
            btn.Name = name .. "Toggle"
            btn.Size = UDim2.new(1, -10, 0, 32)
            btn.Position = UDim2.new(0, 5, 0, yOffset)
            btn.BackgroundColor3 = default and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = name .. ": " .. (default and "ON" or "OFF")
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.Parent = mainFrame
            
            local state = default
            btn.MouseButton1Click:Connect(function()
                state = not state
                btn.BackgroundColor3 = state and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
                btn.Text = name .. ": " .. (state and "ON" or "OFF")
                callback(state)
            end)
            
            yOffset = yOffset + 35
            return btn, function() return state end
        end
        
        -- Kill Aura toggle
        createToggle("Kill Aura", killAuraEnabled, function(v)
            killAuraEnabled = v
        end)
        
        -- Loopkill toggle
        createToggle("Loopkill", loopkillEnabled, function(v)
            loopkillEnabled = v
        end)
        
        -- RPG Block toggle
        createToggle("RPG Block", rpgBlockEnabled, function(v)
            rpgBlockEnabled = v
        end)
        
        -- FF Refresh toggle
        createToggle("FF Refresh", ffRefreshEnabled, function(v)
            ffRefreshEnabled = v
        end)
        
        -- Stats section
        local statsLabel = Instance.new("TextLabel")
        statsLabel.Name = "Stats"
        statsLabel.Size = UDim2.new(1, -10, 0, 20)
        statsLabel.Position = UDim2.new(0, 5, 0, yOffset + 5)
        statsLabel.BackgroundTransparency = 1
        statsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        statsLabel.Text = "Stockpile: 0 | Targets: 0"
        statsLabel.Font = Enum.Font.Gotham
        statsLabel.TextSize = 12
        statsLabel.Parent = mainFrame
        
        -- Update stats periodically
        task.spawn(function()
            while screenGui and screenGui.Parent do
                local stockCount = Stockpile and Stockpile.count() or 0
                local targetCount = KillAura and KillAura.getLoopkillTargets() and table.count(KillAura.getLoopkillTargets()) or 0
                statsLabel.Text = string.format("Missiles: %d | Loopkilled: %d", stockCount, targetCount)
                task.wait(1)
            end
        end)
    end
    
    -- State getters for main.lua to read
    function Gui.isKillAuraEnabled() return killAuraEnabled end
    function Gui.isLoopkillEnabled() return loopkillEnabled end
    function Gui.isRpgBlockEnabled() return rpgBlockEnabled end
    function Gui.isFFRefreshEnabled() return ffRefreshEnabled end
    
    -- Initialize
    function Gui.init()
        createGUI()
        print("🖥️ GUI loaded")
    end
    
    -- Cleanup
    function Gui.destroy()
        if screenGui then
            screenGui:Destroy()
            screenGui = nil
        end
    end
    
    return Gui
end
