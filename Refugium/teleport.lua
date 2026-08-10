return function(S, C, U)
    local Teleport = {}
    local initialized = false
    local isFloating = false
    local floatAttachment, antiGravityForce, alignPosition = nil, nil, nil

    function Teleport.isInitialized() return initialized end
    function Teleport.isFloating() return isFloating end

    function Teleport.toHarbor()
        print("[teleport] Teleporting to harbor...")
        pcall(function() S.Remote:FireServer("Teleport", { "Harbour", "" }) end)
        task.wait(2)
        initialized = true
        print("[teleport] Harbor teleport complete")
    end

    function Teleport.setupAntiGravity()
        local char = S.LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local myHarbor = U.getMyHarbor()
        if not myHarbor then return end
        local targetY = myHarbor.Position.Y + C.FLOAT_HEIGHT
        
        if antiGravityForce then antiGravityForce:Destroy() end
        if floatAttachment then floatAttachment:Destroy() end
        if alignPosition then alignPosition:Destroy() end
        
        floatAttachment = Instance.new("Attachment")
        floatAttachment.Name = "FloatAttachment"
        floatAttachment.Parent = root
        antiGravityForce = Instance.new("VectorForce")
        antiGravityForce.Name = "AntiGravity"
        antiGravityForce.Attachment0 = floatAttachment
        antiGravityForce.RelativeTo = Enum.ActuatorRelativeTo.World
        antiGravityForce.Parent = root
        antiGravityForce.Force = Vector3.new(0, S.Workspace.Gravity * root.AssemblyMass, 0)
        alignPosition = Instance.new("AlignPosition")
        alignPosition.Name = "FloatAlign"
        alignPosition.Attachment0 = floatAttachment
        alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
        alignPosition.MaxForce = math.huge
        alignPosition.Parent = root
        local targetPos = Vector3.new(root.Position.X, targetY, root.Position.Z)
        alignPosition.Position = targetPos
        alignPosition.Enabled = true
        isFloating = true
        root.CFrame = CFrame.new(targetPos)
        root.Velocity = Vector3.zero
        root.RotVelocity = Vector3.zero
    end

    function Teleport.toEnemy(enemy)
        if not initialized then return false end
        local enemyChar = enemy.Character
        if not enemyChar then return false end
        local enemyRoot = enemyChar:FindFirstChild("HumanoidRootPart")
        if not enemyRoot then return false end
        local myChar = S.LocalPlayer.Character
        if not myChar then return false end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return false end
        local direction = (enemyRoot.Position - myRoot.Position).Unit
        local targetPos = enemyRoot.Position - (direction * C.KILL_RANGE)
        local myHarbor = U.getMyHarbor()
        local targetY = myHarbor and (myHarbor.Position.Y + C.FLOAT_HEIGHT) or enemyRoot.Position.Y + C.FLOAT_HEIGHT
        targetPos = Vector3.new(targetPos.X, targetY, targetPos.Z)
        myRoot.CFrame = CFrame.new(targetPos)
        myRoot.Velocity = Vector3.zero
        myRoot.RotVelocity = Vector3.zero
        return true
    end

    function Teleport.maintainFloat()
        if isFloating then
            local char = S.LocalPlayer.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root and alignPosition then
                    local myHarbor = U.getMyHarbor()
                    if myHarbor then
                        local targetY = myHarbor.Position.Y + C.FLOAT_HEIGHT
                        local targetPos = Vector3.new(root.Position.X, targetY, root.Position.Z)
                        alignPosition.Position = targetPos
                    end
                end
            end
        end
    end

    local noClipRunning = false
    
    function Teleport.startNoClip()
        if noClipRunning then return end
        noClipRunning = true
        task.spawn(function()
            while noClipRunning do
                local char = S.LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
                task.wait(0.1)  -- Re-apply every 0.1s
            end
        end)
    end
    
    function Teleport.stopNoClip()
        noClipRunning = false
        local char = S.LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end

    function Teleport.cleanup()
        initialized = false
        isFloating = false
        if antiGravityForce then antiGravityForce:Destroy() end
        if floatAttachment then floatAttachment:Destroy() end
        if alignPosition then alignPosition:Destroy() end
        antiGravityForce, floatAttachment, alignPosition = nil, nil, nil
    end

    return Teleport
end
