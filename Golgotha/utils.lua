return function(S, C)
    local Utils = {}

    function Utils.getEnemyDock()
        if not S.LocalPlayer.Team then return nil end
        if S.LocalPlayer.Team.Name == "Japan" then
            local dock = S.Workspace:FindFirstChild("USDock")
            return dock and dock:FindFirstChild("MainBody")
        elseif S.LocalPlayer.Team.Name == "USA" then
            local dock = S.Workspace:FindFirstChild("JapanDock")
            return dock and dock:FindFirstChild("MainBody")
        end
        return nil
    end

    function Utils.equipTool(toolName)
        local char = S.LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local backpack = S.LocalPlayer:FindFirstChild("Backpack")
        if not backpack then return end
        local tool = backpack:FindFirstChild(toolName)
        if tool then humanoid:EquipTool(tool) end
    end

    function Utils.getRandomOrbitPosition(dockPosition)
        local angle = math.random() * math.pi * 2
        local radius = math.random(C.ORBIT_RADIUS * 0.7, C.ORBIT_RADIUS * 1.3)
        local x = dockPosition.X + math.cos(angle) * radius
        local z = dockPosition.Z + math.sin(angle) * radius
        local y = dockPosition.Y + C.Y_OFFSET
        return Vector3.new(x, y, z)
    end

    return Utils
end
