local S = require(script.Parent.services)
local C = require(script.Parent.config)
local U = require(script.Parent.utils)
local Teleport = require(script.Parent.teleport)
local Stockpile = require(script.Parent.stockpile)

local KillAura = {}
local killCounts = {}
local loopkillTargets = {}

-- Expose loopkill targets so other modules can read them
function KillAura.getLoopkillTargets() return loopkillTargets end

-- Fire kill burst at a target
function KillAura.fireBurst(target)
    local char = target.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local targetPart = U.getValidTargetPart(char)
    if not targetPart then return end
    
    for i = 1, C.SHOTS_PER_BURST do
        pcall(function() S.Remote:FireServer("shootRifle", "", { targetPart }) end)
        task.wait(0.03)
        pcall(function() S.Remote:FireServer("shootRifle", "hit", { hum }) end)
        if i < C.SHOTS_PER_BURST then task.wait(C.SHOT_INTERVAL) end
    end
    
    killCounts[target.Name] = (killCounts[target.Name] or 0) + 1
    if killCounts[target.Name] >= 1 then
        loopkillTargets[target.Name] = true
        print("🔥 Loopkill activated for:", target.Name)
    end
end

-- Main kill aura loop
function KillAura.run(initialized)
    while true do
        if initialized() then
            local enemies = U.getEnemiesInRange(initialized())
            if #enemies > 0 then
                for _, enemy in ipairs(enemies) do
                    if U.isEnemyAlive(enemy) then
                        if U.hasForceField(enemy) then
                            U.equipTool("M1 Garand")
                            task.wait(0.1)
                            Teleport.toEnemy(enemy)
                            task.wait(0.2)
                            KillAura.fireBurst(enemy)
                        else
                            Stockpile.teleportEnemy(enemy)
                        end
                    end
                end
                task.wait(C.BURST_COOLDOWN)
            else
                task.wait(0.5)
            end
        else
            task.wait(0.5)
        end
    end
end

return KillAura
