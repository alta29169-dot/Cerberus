--[[
    AntiCheat v3, developed by swiftlyrandom
]]

local M = _G._HarborModules

local S = M.services
local C = M.config

-- Initialize in dependency order
local Utils = M.utils(S, C)
local Teleport = M.teleport(S, C, Utils)
local Stockpile = M.stockpile(S, C, Utils)
local GuiCore = M.guicore(S, C, Stockpile)
local KillAura = M.killaura(S, C, Utils, Teleport, Stockpile, GuiCore)
local Loopkill = M.loopkill(S, C, Utils, Teleport, Stockpile, KillAura, GuiCore)
local RpgBlock = M.rpgblock(S, C, Utils, Stockpile)
local GuiToggles = M.guitoggles(GuiCore)
local GuiTargets = M.guitargets(S, KillAura, GuiCore)

local initialized = false
local lastFFRefresh = 0

-- Stockpile maintenance loop
local function stockpileLoop()
    task.wait(3)
    while true do
        if initialized and GuiCore.isMasterEnabled() then
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

-- Float maintenance + FF refresh
task.spawn(function()
    while true do
        if initialized and GuiCore.isMasterEnabled() then
            Teleport.maintainFloat()
            if GuiCore.isFFRefreshEnabled() and tick() - lastFFRefresh >= C.FF_REFRESH_INTERVAL then
                pcall(function() S.Remote:FireServer("Teleport", { "Harbour", "" }) end)
                lastFFRefresh = tick()
            end
        end
        task.wait(0.05)
    end
end)

-- RPG Block loop
S.RunService.Heartbeat:Connect(function()
    if initialized and GuiCore.isMasterEnabled() and GuiCore.isRpgBlockEnabled() then
        RpgBlock.cleanup()
        RpgBlock.run()
    end
end)

-- Master toggle watcher (activates/deactivates float)
task.spawn(function()
    local wasEnabled = false
    while true do
        local isEnabled = GuiCore.isMasterEnabled()
        if isEnabled and not wasEnabled then
            if initialized then
                Teleport.toHarbor()
                task.wait(2)
                Teleport.setupAntiGravity()
            end
            print("🟢 Harbor Defender activated")
        elseif not isEnabled and wasEnabled then
            Teleport.cleanup()
            print("🔴 Harbor Defender deactivated")
        end
        wasEnabled = isEnabled
        task.wait(0.5)
    end
end)

-- Respawn handler
S.LocalPlayer.CharacterAdded:Connect(function()
    print("🔄 Character respawned — re-initializing...")
    initialized = false
    Teleport.cleanup()
    Stockpile.clear()
    RpgBlock.clear()
    GuiCore.destroy()
    task.wait(0.5)
    GuiCore.init()
    GuiToggles.init()
    GuiTargets.init()
    lastFFRefresh = tick()
    initialized = true
end)

-- Init (no teleport, no float)
GuiCore.init()
GuiToggles.init()
GuiTargets.init()
lastFFRefresh = tick()
initialized = true

task.spawn(function() KillAura.run(function() return initialized end) end)
task.spawn(stockpileLoop)
task.spawn(function() Loopkill.run(function() return initialized end) end)

print("✅ Harbor Defender loaded (dormant — use MASTER toggle in GUI)")
