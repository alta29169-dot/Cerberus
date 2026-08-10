local M = _G._GolgothaModules
local S, C = M.services, M.config
local U = M.utils(S, C)
local Core = M.core(S, C, U)
local GuiCore = M.guicore(S, C)
local GuiToggles = M.guitoggles(GuiCore)

local initialized = false
local lastSetup = 0

-- Master toggle watcher
task.spawn(function()
    local wasEnabled = false
    while true do
        local isEnabled = GuiCore.isMasterEnabled()
        if isEnabled and not wasEnabled then
            Core.setup()
            print("[main] Golgotha activated")
        elseif not isEnabled and wasEnabled then
            Core.stopHarbourLoop()
            Core.disableNoclip()
            print("[main] Golgotha deactivated")
        end
        wasEnabled = isEnabled
        task.wait(0.5)
    end
end)

-- Respawn handler
S.LocalPlayer.CharacterAdded:Connect(function()
    if GuiCore.isMasterEnabled() then
        task.wait(0.5)
        Core.setup()
    end
end)

-- Init
GuiCore.init()
GuiToggles.init()

print("[main] Golgotha loaded (dormant — use MASTER toggle)")
