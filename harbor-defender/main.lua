local S = require(script.services)
local C = require(script.config)
local Teleport = require(script.teleport)
local Stockpile = require(script.stockpile)
local KillAura = require(script.killaura)
local Loopkill = require(script.loopkill)

local initialized = false

-- Stockpile maintenance loop
local function stockpileLoop()
    while true do
        if initialized then
            Stockpile.cleanup()
            if Stockpile.count() < C.STOCKPILE_MAX then
                require(script.utils).equipTool("RPG")
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
