return function(S, C, U)
    local Stockpile = {}
    local missiles = {}
    local stockpileIndex = 0
    local teleportIndex = 0

    -- Get stockpile position spread in a ring
    local function getPosition()
        local char = S.LocalPlayer.Character
        if not char then return nil end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        
        local angle = (stockpileIndex / math.max(C.STOCKPILE_MAX, 1)) * math.pi * 2
        local offset = Vector3.new(math.cos(angle) * C.STOCKPILE_DISTANCE, 0, math.sin(angle) * C.STOCKPILE_DISTANCE)
        stockpileIndex = stockpileIndex + 1
        
        return root.Position + offset
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

        -- Debug: show where this missile is frozen
        local debugPart = Instance.new("Part")
        debugPart.Name = "StockpileDebug"
        debugPart.Size = Vector3.new(2, 2, 2)
        debugPart.Position = position
        debugPart.Anchored = true
        debugPart.CanCollide = false
        debugPart.Color = Color3.fromRGB(255, 0, 0)
        debugPart.Material = Enum.Material.Neon
        debugPart.Parent = S.Workspace
        task.delay(10, function() debugPart:Destroy() end)
        
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

    -- Teleport an enemy onto a stockpiled missile (cycles through them)
    function Stockpile.teleportEnemy(enemy)
        if not enemy then return false end
        local char = enemy.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        
        -- Build list of available missiles
        local missileList = {}
        for missile, _ in pairs(missiles) do
            if missile and missile.Parent then
                table.insert(missileList, missile)
            end
        end
        
        local missilePos = nil
        if #missileList > 0 then
            teleportIndex = (teleportIndex % #missileList) + 1
            missilePos = missileList[teleportIndex].Position
        else
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
            -- Remove debug parts
        for _, part in ipairs(S.Workspace:GetChildren()) do
            if part.Name == "StockpileDebug" then
                part:Destroy()
            end
        end
        for missile, data in pairs(missiles) do
            if missile and missile.Parent then
                if data.attachment then data.attachment:Destroy() end
                if data.align then data.align:Destroy() end
            end
        end
        table.clear(missiles)
        stockpileIndex = 0
        teleportIndex = 0
    end

    return Stockpile
end
