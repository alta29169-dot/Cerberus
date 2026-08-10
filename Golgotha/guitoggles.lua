return function(GuiCore)
    return {
        init = function()
            local frame = GuiCore.getMainFrame()
            if not frame then return end

            local masterBtn = Instance.new("TextButton")
            masterBtn.Size = UDim2.new(1, -10, 0, 35)
            masterBtn.Position = UDim2.new(0, 5, 0, 30)
            masterBtn.BackgroundColor3 = GuiCore.isMasterEnabled() and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
            masterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            masterBtn.Text = "MASTER: " .. (GuiCore.isMasterEnabled() and "ON" or "OFF")
            masterBtn.Font = Enum.Font.GothamBold
            masterBtn.TextSize = 13
            masterBtn.Parent = frame

            masterBtn.MouseButton1Click:Connect(function()
                local new = not GuiCore.isMasterEnabled()
                GuiCore.setMasterEnabled(new)
                masterBtn.BackgroundColor3 = new and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
                masterBtn.Text = "MASTER: " .. (new and "ON" or "OFF")
            end)
        end
    }
end
