--[[
    HARBOR DEFENDER – Main Entry Point
    Reads modules from _G._HarborModules (set by bootloader)
]]

local M = _G._HarborModules

local S = M.services
local C = M.config

-- Initialize modules that need dependencies
local Utils = M.utils(S, C)
local Teleport = M.teleport(S, C, Utils)
local Stockpile = M.stockpile(S, C, Utils)
local KillAura = M.killaura(S, C, Utils, Teleport, Stockpile)
local Loopkill = M.loopkill(S, C, Utils, Teleport, Stockpile, KillAura)
local RpgBlock = M.rpgblock(S, C, Utils, Stockpile)

local initialized = false

-- Stockpile maintenance loop (with initial delay)
local function stockpileLoop()
    -- Wait for setup to complete
    task.wait(3)  -- Give time for teleport + anti-gravity to settle
    
    while true do
        if initialized then
            Stockpile.cleanup()
            if Stockpile.count() < C.STOCKPILE_MAX then
                Utils.equipTool("RPG")
                task.wait(0.1)
                Stockpile.fireAndFreeze()
            end
        end
        task.wait(C.STOCKPILE_CHECK_INTERVAL)
    end
end

-- Float position maintenance + FF refresh loop
task.spawn(function()
    while true do
        if initialized then
            Teleport.maintainFloat()
            
            -- Refresh FF every 5 seconds
            if tick() - lastFFRefresh >= C.FF_REFRESH_INTERVAL then
                pcall(function() S.Remote:FireServer("Teleport", { "Harbour", "" }) end)
                lastFFRefresh = tick()
            end
        end
        task.wait(0.05)
    end
end)

-- RPG Block loop (every frame via Heartbeat)
S.RunService.Heartbeat:Connect(function()
    if initialized then
        RpgBlock.cleanup()
        RpgBlock.run()
    end
end)

-- Respawn handler
S.LocalPlayer.CharacterAdded:Connect(function()
    print("🔄 Character respawned — re-initializing...")
    initialized = false
    Teleport.cleanup()
    Stockpile.clear()
    RpgBlock.clear()
    task.wait(0.5)
    Teleport.toHarbor()
    Teleport.setupAntiGravity()
    lastFFRefresh = tick()
    initialized = true
end)

-- Init
Teleport.toHarbor()
Teleport.setupAntiGravity()
lastFFRefresh = tick()
initialized = true

task.spawn(function() KillAura.run(function() return initialized end) end)
task.spawn(stockpileLoop)
task.spawn(function() Loopkill.run(function() return initialized end) end)

print("✅ Harbor Defender loaded")
print("   Float height:", C.FLOAT_HEIGHT, "studs above harbor")
print("   Kill range:", C.KILL_RANGE, "studs")
print("   FF users: Kill Aura (M1 Garand)")
print("   Non-FF users: Stockpile blast")
print("   Loopkill: teleported into stockpile until they leave")
print("   RPG Block: all enemy missiles absorbed")
print("   FF Refresh: every 5 seconds")
