return function(S, KillAura, GuiCore)
    local GuiTargets = {}
    
    function GuiTargets.init()
        local frame = GuiCore.getTabFrame("Targets")
        if not frame then return end
        
        -- Input section
        local inputFrame = Instance.new("Frame")
        inputFrame.Size = UDim2.new(1, 0, 0, 35)
        inputFrame.BackgroundTransparency = 1
        inputFrame.Parent = frame
        
        local inputBox = Instance.new("TextBox")
        inputBox.Size = UDim2.new(0.6, -5, 0, 30)
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
            end
        end)
        
        -- Scrolling target list
        local listFrame = Instance.new("ScrollingFrame")
        listFrame.Size = UDim2.new(1, 0, 1, -40)
        listFrame.Position = UDim2.new(0, 0, 0, 40)
        listFrame.BackgroundTransparency = 1
        listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        listFrame.ScrollBarThickness = 6
        listFrame.Parent = frame
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 3)
        layout.Parent = listFrame
        
        -- Refresh logic
        task.spawn(function()
            while GuiCore.getScreenGui() and GuiCore.getScreenGui().Parent do
                -- Clear
                for _, child in ipairs(listFrame:GetChildren()) do
                    if child:IsA("Frame") then child:Destroy() end
                end
                
                local targets = KillAura.getLoopkillTargets()
                local ySize = 0
                
                -- Offline targets
                for name, _ in pairs(targets) do
                    local found = false
                    for _, pl in ipairs(S.Players:GetPlayers()) do
                        if pl.Name == name then found = true; break end
                    end
                    if not found then
                        local entry = Instance.new("Frame")
                        entry.Size = UDim2.new(1, 0, 0, 30)
                        entry.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
                        entry.BorderSizePixel = 0
                        entry.Parent = listFrame
                        
                        local lbl = Instance.new("TextLabel")
                        lbl.Size = UDim2.new(0.55, 0, 1, 0)
                        lbl.Position = UDim2.new(0, 5, 0, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
                        lbl.Text = name .. " (offline)"
                        lbl.Font = Enum.Font.Gotham
                        lbl.TextSize = 11
                        lbl.TextXAlignment = Enum.TextXAlignment.Left
                        lbl.Parent = entry
                        
                        local rmBtn = Instance.new("TextButton")
                        rmBtn.Size = UDim2.new(0.35, 0, 1, -4)
                        rmBtn.Position = UDim2.new(0.63, 0, 0, 2)
                        rmBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
                        rmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        rmBtn.Text = "Remove"
                        rmBtn.Font = Enum.Font.Gotham
                        rmBtn.TextSize = 11
                        rmBtn.Parent = entry
                        rmBtn.MouseButton1Click:Connect(function() targets[name] = nil end)
                        
                        ySize = ySize + 33
                    end
                end
                
                -- Active players
                for _, pl in ipairs(S.Players:GetPlayers()) do
                    if pl ~= S.LocalPlayer and pl.Team ~= S.LocalPlayer.Team and pl.Character then
                        local isLK = targets[pl.Name] == true
                        local hasFF = false
                        for _, c in ipairs(pl.Character:GetDescendants()) do
                            if c:IsA("ForceField") then hasFF = true; break end
                        end
                        
                        local entry = Instance.new("Frame")
                        entry.Size = UDim2.new(1, 0, 0, 30)
                        entry.BackgroundColor3 = isLK and Color3.fromRGB(50, 30, 30) or Color3.fromRGB(30, 30, 30)
                        entry.BorderSizePixel = 0
                        entry.Parent = listFrame
                        
                        local lbl = Instance.new("TextLabel")
                        lbl.Size = UDim2.new(0.55, 0, 1, 0)
                        lbl.Position = UDim2.new(0, 5, 0, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                        lbl.Text = pl.Name .. (hasFF and " ⚡" or "")
                        lbl.Font = Enum.Font.Gotham
                        lbl.TextSize = 12
                        lbl.TextXAlignment = Enum.TextXAlignment.Left
                        lbl.Parent = entry
                        
                        local btn = Instance.new("TextButton")
                        btn.Size = UDim2.new(0.35, 0, 1, -4)
                        btn.Position = UDim2.new(0.63, 0, 0, 2)
                        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        btn.Font = Enum.Font.Gotham
                        btn.TextSize = 11
                        btn.Parent = entry
                        
                        local tName = pl.Name
                        if isLK then
                            btn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
                            btn.Text = "Remove"
                            btn.MouseButton1Click:Connect(function() targets[tName] = nil end)
                        else
                            btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
                            btn.Text = "Add"
                            btn.MouseButton1Click:Connect(function() targets[tName] = true end)
                        end
                        
                        ySize = ySize + 33
                    end
                end
                
                listFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(ySize, 200))
                task.wait(2)
            end
        end)
    end
    
    return GuiTargets
end
