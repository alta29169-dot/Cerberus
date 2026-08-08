--[[
    HARBOR DEFENDER – Main Entry Point
    Load with: loadstring(game:HttpGet(".../main.lua"))()
]]

local scriptParent = script.Parent  -- The folder containing all modules

local S = require(scriptParent.services)
local C = require(scriptParent.config)
local Teleport = require(scriptParent.teleport)
local Stockpile = require(scriptParent.stockpile)
local KillAura = require(scriptParent.killaura)
local Loopkill = require(scriptParent.loopkill)
local Utils = require(scriptParent.utils)

local initialized = false

-- Stockpile maintenance loop
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

-- Float position maintenance loop
task.spawn(function()
    while true do
        Teleport.maintainFloat()
        task.wait(0.05)
    end
end)

-- Respawn handler
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

-- Init
Teleport.toHarbor()
Teleport.setupAntiGravity()
initialized = true

task.spawn(function() KillAura.run(function() return initialized end) end)
task.spawn(stockpileLoop)
task.spawn(function() Loopkill.run(function() return initialized end) end)

print("✅ Harbor Defender loaded")
print("   Float height:", C.FLOAT_HEIGHT, "studs above harbor")
print("   FF users: Kill Aura (M1 Garand)")
print("   Non-FF users: Stockpile blast")
print("   Loopkill: teleported into stockpile until they leave")
