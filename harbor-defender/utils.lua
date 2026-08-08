-- Utils is passed its dependencies when initialized
return function(S, C)
    local Utils = {}

    function Utils.getMyHarbor()
        if not S.LocalPlayer.Team then return nil end
        if S.LocalPlayer.Team.Name == "Japan" then
            local dock = S.Workspace:FindFirstChild("JapanDock")
            return dock and dock:FindFirstChild("MainBody")
        elseif S.LocalPlayer.Team.Name == "USA" then
            local dock = S.Workspace:FindFirstChild("USDock")
            return dock and dock:FindFirstChild("MainBody")
        end
        return nil
    end

    function Utils.getValidTargetPart(char)
        if not char then return nil end
        for _, partName in ipairs(C.R6_PARTS) do
            local part = char:FindFirstChild(partName)
            if part and part:IsA("BasePart") then return part end
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then return root end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then return part end
        end
        return nil
    end

    function Utils.hasForceField(enemy)
        if not enemy then return false end
        local char = enemy.Character
        if not char then return false end
        for _, child in ipairs(char:GetDescendants()) do
            if child:IsA("ForceField") then return true end
        end
        return false
    end

    function Utils.isEnemyAlive(enemy)
        if not enemy then return false end
        local char = enemy.Character
        if not char then return false end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return false end
        return hum.Health > 0
    end

    function Utils.equipTool(toolName)
        local char = S.LocalPlayer.Character
        if not char then return false end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        local equipped = char:FindFirstChild(toolName)
        if equipped then return true end
        local backpack = S.LocalPlayer:FindFirstChild("Backpack")
        if not backpack then return false end
        local tool = backpack:FindFirstChild(toolName)
        if not tool then return false end
        humanoid:EquipTool(tool)
        return true
    end

    function Utils.getEnemiesInRange(initialized)
        if not initialized then return {} end
        local enemies = {}
        local myHarbor = Utils.getMyHarbor()
        if not myHarbor then return {} end
        local harborPos = myHarbor.Position
        for _, pl in ipairs(S.Players:GetPlayers()) do
            if pl ~= S.LocalPlayer and pl.Team ~= S.LocalPlayer.Team then
                local char = pl.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if root then
                            local dist = (root.Position - harborPos).Magnitude
                            if dist < C.HARBOR_RANGE then
                                table.insert(enemies, pl)
                            end
                        end
                    end
                end
            end
        end
        return enemies
    end

    return Utils
end
