return function(S, C, U, Stockpile)
    local RpgBlock = {}
    local blockedMissiles = {}  -- tracked separately from stockpile

    -- Teleport all enemy missiles into your hitbox
    function RpgBlock.run()
        local char = S.LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local myPos = root.Position

        -- Also check other body parts for larger hitbox coverage
        local hitboxPositions = { myPos }
        local head = char:FindFirstChild("Head")
        if head then table.insert(hitboxPositions, head.Position) end
        local torso = char:FindFirstChild("Torso")
        if torso then table.insert(hitboxPositions, torso.Position) end

        for _, child in ipairs(S.Workspace:GetChildren()) do
            if child.Name == "Missile" and child:IsA("BasePart") then
                child.Transparency = 1
                -- SKIP if this missile is in our stockpile
                if Stockpile.isStockpiled(child) then continue end

                -- SKIP if we already blocked this one (avoid re-teleporting)
                -- Teleport into a random hitbox position for spread
                local targetPos = hitboxPositions[math.random(#hitboxPositions)]
                child.CFrame = CFrame.new(targetPos)
                child.Velocity = Vector3.zero
                child.RotVelocity = Vector3.zero

                -- Mark as blocked
                blockedMissiles[child] = tick()
            end
        end
    end

    -- Clean up tracked missiles that are gone
    function RpgBlock.cleanup()
        for missile, _ in pairs(blockedMissiles) do
            if not missile or not missile.Parent then
                blockedMissiles[missile] = nil
            end
        end
    end

    -- Clear all tracked missiles
    function RpgBlock.clear()
        table.clear(blockedMissiles)
    end

    return RpgBlock
end
