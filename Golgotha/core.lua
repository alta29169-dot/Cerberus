return function(S, C, U)
    local Core = {}
    
    local renderConn = nil
    local harbourActive = false
    local currentGen = 0
    local noclipActive = false

    -- Noclip
    function Core.enableNoclip()
        local char = S.LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
        noclipActive = true
    end

    function Core.disableNoclip()
        local char = S.LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
        noclipActive = false
    end

    function Core.isNoclipActive() return noclipActive end

    -- Harbour teleport
    function Core.triggerHarbourTeleport()
        pcall(function() S.Remote:FireServer("Teleport", { "Harbour", "" }) end)
    end

    function Core.startHarbourLoop(myGen)
        harbourActive = true
        task.spawn(function()
            while harbourActive and currentGen == myGen do
                Core.triggerHarbourTeleport()
                task.wait(C.HARBOUR_INTERVAL)
            end
        end)
    end

    function Core.stopHarbourLoop()
        harbourActive = false
    end

    -- RPG spam
    function Core.fireToDock(myGen)
        while currentGen == myGen do
            local dock = U.getEnemyDock()
            if dock then
                U.equipTool("RPG")
                S.Remote:FireServer("fireRPG", { dock.Position })
            end
            task.wait(C.FIRE_COOLDOWN)
        end
    end

    -- Orbit
    function Core.orbitAroundDock()
        if renderConn then renderConn:Disconnect(); renderConn = nil end
        local char = S.LocalPlayer.Character or S.LocalPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local humanoid = char:WaitForChild("Humanoid")
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        humanoid.AutoRotate = false

        local myGen = currentGen
        local orbitTimer = 0
        local currentOrbitPosition = nil

        renderConn = S.RunService.Heartbeat:Connect(function(dt)
            if currentGen ~= myGen then renderConn:Disconnect(); renderConn = nil; return end
            orbitTimer = orbitTimer + dt
            if orbitTimer >= C.ORBIT_INTERVAL or not currentOrbitPosition then
                orbitTimer = 0
                local dock = U.getEnemyDock()
                if dock and hrp then currentOrbitPosition = U.getRandomOrbitPosition(dock.Position) end
            end
            if currentOrbitPosition and hrp then hrp.CFrame = CFrame.new(currentOrbitPosition) end
        end)
    end

    -- Setup
    function Core.setup()
        currentGen = currentGen + 1
        local myGen = currentGen
        Core.stopHarbourLoop()
        Core.triggerHarbourTeleport()
        task.wait(0.2)
        Core.orbitAroundDock()
        task.spawn(function() Core.fireToDock(myGen) end)
        Core.startHarbourLoop(myGen)
        if noclipActive then task.wait(0.1); Core.enableNoclip() end
    end

    -- Noclip persistence on respawn
    S.LocalPlayer.CharacterAdded:Connect(function()
        if noclipActive then task.wait(0.1); Core.enableNoclip() end
    end)

    return Core
end
