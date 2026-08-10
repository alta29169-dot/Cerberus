--[[
    GUI PICKER
    Simple menu to select which script suite to run
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GITHUB_USER = "alta29169-dot"
local GITHUB_REPO = "Cerberus"
local GITHUB_BRANCH = "main"

-- Available suites
local SUITES = {
    {
        name = "Refugium",
        description = "Harbor Defense System",
        path = "Refugium/bootloader.lua"
    },
    -- Future suites go here:
    -- {
    --     name = "OrbitKiller",
    --     description = "Orbital Dock Attacker",
    --     path = "OrbitKiller/bootloader.lua"
    -- },
}

-- Create the picker GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RefugiumPicker"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 40 + #SUITES * 55)
frame.Position = UDim2.new(0.5, -130, 0.5, -(40 + #SUITES * 55) / 2)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "Refugium"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

local yOff = 35

-- Suite buttons
for _, suite in ipairs(SUITES) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 45)
    btn.Position = UDim2.new(0, 5, 0, yOff)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = suite.name .. "\n" .. suite.description
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.Parent = frame
    
    btn.MouseButton1Click:Connect(function()
        -- Load the suite's bootloader
        local url = string.format(
            "https://raw.githubusercontent.com/%s/%s/refs/heads/%s/%s",
            GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH, suite.path
        )
        local result = request({ Url = url, Method = "GET" })
        if result.StatusCode == 200 then
            local fn, err = loadstring(result.Body, suite.path)
            if fn then
                screenGui:Destroy()  -- Close picker
                fn()
            else
                warn("[Picker] Compile error:", err)
            end
        end
    end)
    
    yOff = yOff + 50
end

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = frame
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)
