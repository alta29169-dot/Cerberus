local M = _G._HarborModules

local S = M.services    -- plain table, no init needed
local C = M.config       -- plain table, no init needed

-- Initialize modules that need dependencies
local Utils = M.utils(S, C)
local Teleport = M.teleport(S, C, Utils)
local Stockpile = M.stockpile(S, C, Utils)
local KillAura = M.killaura(S, C, Utils, Teleport, Stockpile)
local Loopkill = M.loopkill(S, C, Utils, Teleport, Stockpile, KillAura)

local initialized = false

-- Rest of main.lua stays the same...
local function stockpileLoop()
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

local lastFFRefresh = 0
task.spawn(function()
    while true do
        Teleport.maintainFloat()
        if tick() - lastFFRefresh >= 5 then
            pcall(function() S.Remote:FireServer("Teleport", { "Harbour", "" }) end)
            lastFFRefresh = tick()
        end
        task.wait(0.05)
    end
end)

S.LocalPlayer.CharacterAdded:Connect(function()
    print("🔄 Character respawned — re-initializing...")
    initialized = false
    Teleport.cleanup()
    Stockpile.clear()
    task.wait(0.5)
    Teleport.toHarbor()
    Teleport.setupAntiGravity()
    initialized = true
end)

Teleport.toHarbor()
Teleport.setupAntiGravity()
initialized = true

task.spawn(function() KillAura.run(function() return initialized end) end)
task.spawn(stockpileLoop)
task.spawn(function() Loopkill.run(function() return initialized end) end)

print("✅ Harbor Defender loaded")
