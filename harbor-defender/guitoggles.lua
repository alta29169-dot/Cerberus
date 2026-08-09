return function(GuiCore)
    local GuiToggles = {}
    
    function GuiToggles.init()
        local frame = GuiCore.getTabFrame("Toggles")
        if not frame then return end
        
        local yOff = 0
        
        -- ==================== MASTER TOGGLE ====================
        local masterBtn = Instance.new("TextButton")
        masterBtn.Size = UDim2.new(1, 0, 0, 40)
        masterBtn.Position = UDim2.new(0, 0, 0, yOff)
        masterBtn.BackgroundColor3 = GuiCore.isMasterEnabled() and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
        masterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        masterBtn.Text = "MASTER: " .. (GuiCore.isMasterEnabled() and "ON" or "OFF")
        masterBtn.Font = Enum.Font.GothamBold
        masterBtn.TextSize = 16
        masterBtn.Parent = frame
        
        masterBtn.MouseButton1Click:Connect(function()
            local newState = not GuiCore.isMasterEnabled()
            GuiCore.setMasterEnabled(newState)
            masterBtn.BackgroundColor3 = newState and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
            masterBtn.Text = "MASTER: " .. (newState and "ON" or "OFF")
        end)
        
        -- Touch support for mobile
        masterBtn.TouchTap:Connect(function()
            local newState = not GuiCore.isMasterEnabled()
            GuiCore.setMasterEnabled(newState)
            masterBtn.BackgroundColor3 = newState and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
            masterBtn.Text = "MASTER: " .. (newState and "ON" or "OFF")
        end)
        
        yOff = yOff + 45
        
        -- ==================== TOGGLE HELPER ====================
        local function createToggle(name, getter, setter, parent)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 32)
            btn.Position = UDim2.new(0, 0, 0, yOff)
            btn.BackgroundColor3 = getter() and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = name .. ": " .. (getter() and "ON" or "OFF")
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            btn.Parent = parent
            
            local function flip()
                local newState = not getter()
                setter(newState)
                btn.BackgroundColor3 = newState and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
                btn.Text = name .. ": " .. (newState and "ON" or "OFF")
            end
            
            btn.MouseButton1Click:Connect(flip)
            btn.TouchTap:Connect(flip)  -- Mobile support
            
            yOff = yOff + 35
        end
        
        -- ==================== TOGGLES ====================
        createToggle("Kill Aura", GuiCore.isKillAuraEnabled, GuiCore.setKillAuraEnabled, frame)
        createToggle("Kill Aura TP", GuiCore.isKillAuraTpEnabled, GuiCore.setKillAuraTpEnabled, frame)
        createToggle("Loopkill", GuiCore.isLoopkillEnabled, GuiCore.setLoopkillEnabled, frame)
        createToggle("RPG Block", GuiCore.isRpgBlockEnabled, GuiCore.setRpgBlockEnabled, frame)
        createToggle("FF Refresh", GuiCore.isFFRefreshEnabled, GuiCore.setFFRefreshEnabled, frame)
        
        -- ==================== STATS / OWNERSHIP ====================
        local statsLabel = Instance.new("TextLabel")
        statsLabel.Name = "StatsLabel"
        statsLabel.Size = UDim2.new(1, 0, 0, 20)
        statsLabel.Position = UDim2.new(0, 0, 0, yOff + 5)
        statsLabel.BackgroundTransparency = 1
        statsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        statsLabel.Text = '"It is simply a matter of skill" - swiftlyrandom'
        statsLabel.Font = Enum.Font.Gotham
        statsLabel.TextSize = 10
        statsLabel.Parent = frame
    end
    
    return GuiToggles
end
