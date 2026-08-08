return function(S, C, U)
    local Stockpile = {}
    local missiles = {}

    -- Get stockpile position 15 studs ahead
    local function getPosition()
        local char = S.LocalPlayer.Character
        if not char then return nil end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        return root.Position + (root.CFrame.LookVector * C.STOCKPILE_DISTANCE)
    end
    
    -- Freeze a missile with physics constraints
    local function freeze(missile, position)
        for _, child in ipairs(missile:GetChildren()) do
            if child.Name == "StockpileAttachment" or child.Name == "StockpileAlign" then
                child:Destroy()
            end
        end
        local att = Instance.new("Attachment")
        att.Name = "StockpileAttachment"
        att.Parent = missile
        local align = Instance.new("AlignPosition")
        align.Name = "StockpileAlign"
        align.Attachment0 = att
        align.Mode = Enum.PositionAlignmentMode.OneAttachment
        align.MaxForce = math.huge
        align.Responsiveness = 200
        align.Position = position
        align.Parent = missile
        missile.Velocity = Vector3.zero
        missile.RotVelocity = Vector3.zero
        missile.Transparency = 1
        missiles[missile] = { attachment = att, align = align }
    end

    -- Fire RPG and freeze the resulting missile
    function Stockpile.fireAndFreeze()
        local pos = getPosition()
        if not pos then return end
        local count = 0
        for _ in pairs(missiles) do count = count + 1 end
        if count >= C.STOCKPILE_MAX then return end
        
        pcall(function() S.Remote:FireServer("fireRPG", { pos }) end)
        task.wait(0.15)
        
        for _, child in ipairs(S.Workspace:GetChildren()) do
            if child.Name == "Missile" and child:IsA("BasePart") then
                if (child.Position - pos).Magnitude < 50 and not missiles[child] then
                    freeze(child, pos)
                    break
                end
            end
        end
    end

    -- Clean up destroyed missiles
    function Stockpile.cleanup()
        for missile, _ in pairs(missiles) do
            if not missile or not missile.Parent then
                missiles[missile] = nil
            end
        end
    end

    -- Teleport an enemy directly onto a stockpiled missile
    function Stockpile.teleportEnemy(enemy)
        if not enemy then return false end
        local char = enemy.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
    
        -- Find the first available stockpiled missile
        local missilePos = nil
        for missile, _ in pairs(missiles) do
            if missile and missile.Parent then
                missilePos = missile.Position
                break
            end
        end
        
        -- Fallback to stockpile spawn position if no missiles
        if not missilePos then
            missilePos = getPosition()
            if not missilePos then return false end
        end
        
        root.CFrame = CFrame.new(missilePos)
        root.Velocity = Vector3.zero
        root.RotVelocity = Vector3.zero
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum:MoveTo(missilePos) end
        return true
    end

    -- Get current stockpile count
    function Stockpile.count()
        local n = 0
        for _ in pairs(missiles) do n = n + 1 end
        return n
    end

    -- Check if a missile is in our stockpile
    function Stockpile.isStockpiled(missile)
        return missiles[missile] ~= nil
    end

    -- Full clear (on respawn)
    function Stockpile.clear()
        for missile, data in pairs(missiles) do
            if missile and missile.Parent then
                if data.attachment then data.attachment:Destroy() end
                if data.align then data.align:Destroy() end
            end
        end
        table.clear(missiles)
    end

    return Stockpile
end
