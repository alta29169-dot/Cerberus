local _persistentMaster = false

return function(S, C)
    local GuiCore = {}
    local screenGui, mainFrame, minimizedIcon = nil, nil, nil
    local masterEnabled = _persistentMaster

    function GuiCore.isMasterEnabled() return masterEnabled end
    function GuiCore.setMasterEnabled(v) masterEnabled = v; _persistentMaster = v end

    function GuiCore.init()
        if screenGui then screenGui:Destroy() end
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "GolgothaGUI"
        screenGui.Parent = S.LocalPlayer:WaitForChild("PlayerGui")

        minimizedIcon = Instance.new("TextButton")
        minimizedIcon.Size = UDim2.new(0, 40, 0, 40)
        minimizedIcon.Position = UDim2.new(1, -50, 0, 10)
        minimizedIcon.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        minimizedIcon.BackgroundTransparency = 0.1
        minimizedIcon.BorderSizePixel = 0
        minimizedIcon.Text = "💀"
        minimizedIcon.Font = Enum.Font.GothamBold
        minimizedIcon.TextSize = 20
        minimizedIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
        minimizedIcon.Draggable = true
        minimizedIcon.Visible = false
        minimizedIcon.Parent = screenGui

        mainFrame = Instance.new("Frame")
        mainFrame.Size = UDim2.new(0, 200, 0, 100)
        mainFrame.Position = UDim2.new(1, -210, 0, 10)
        mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        mainFrame.BackgroundTransparency = 0.1
        mainFrame.BorderSizePixel = 0
        mainFrame.Draggable = true
        mainFrame.Parent = screenGui

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -30, 0, 25)
        title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Text = "Golgotha"
        title.Font = Enum.Font.GothamBold
        title.TextSize = 14
        title.Parent = mainFrame

        local minBtn = Instance.new("TextButton")
        minBtn.Size = UDim2.new(0, 25, 0, 25)
        minBtn.Position = UDim2.new(1, -25, 0, 0)
        minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        minBtn.Text = "_"
        minBtn.Font = Enum.Font.GothamBold
        minBtn.TextSize = 14
        minBtn.Parent = mainFrame

        minimizedIcon.MouseButton1Click:Connect(function()
            minimizedIcon.Visible = false; mainFrame.Visible = true
        end)
        minBtn.MouseButton1Click:Connect(function()
            mainFrame.Visible = false; minimizedIcon.Visible = true
        end)
    end

    function GuiCore.getMainFrame() return mainFrame end
    function GuiCore.destroy()
        if screenGui then screenGui:Destroy(); screenGui = nil end
    end

    return GuiCore
end
