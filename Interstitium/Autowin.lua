-- LocalScript (StarterPlayerScripts)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Constants
local MIN_DAMAGE = 300
local MAX_DAMAGE = 450
local AVG_DAMAGE = (MIN_DAMAGE + MAX_DAMAGE) / 2
local MAX_HP = 25000
local STOP_HP = 500
local SAFE_STOP_HP = 800
local ROUND_DURATION = 6000
local STOP_TIME = 180

local fireCooldown = 0.1
local renderConn = nil
local currentGen = 0
local isFiring = false
local floatData = {}
local dockConnection = nil
local timerConnection = nil

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function equipTool(toolName)
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return false end
    local tool = backpack:FindFirstChild(toolName)
    if tool then
        humanoid:EquipTool(tool)
        return true
    end
    return false
end

local function getDock()
    if not player.Team then return nil end
    if player.Team.Name == "Japan" then
        local dock = Workspace:FindFirstChild("USDock")
        return dock and dock:FindFirstChild("MainBody")
    elseif player.Team.Name == "USA" then
        local dock = Workspace:FindFirstChild("JapanDock")
        return dock and dock:FindFirstChild("MainBody")
    end
    return nil
end

-- Get HP with automatic reconnection
local function getDockHP()
    local dock = getDock()
    if dock then
        local hpInt = dock:FindFirstChild("HP")
        if hpInt and hpInt:IsA("IntValue") then
            return hpInt.Value
        end
    end
    return nil
end

-- Get Timer with automatic reconnection
local function getTimer()
    local timerFolder = Workspace:FindFirstChild("VariableFolder")
    if timerFolder then
        local timerVal = timerFolder:FindFirstChild("TimerVal")
        if timerVal and timerVal:IsA("IntValue") then
            return timerVal.Value
        end
    end
    return nil
end

-- Watch for HP instance changes
local function watchHP()
    if dockConnection then
        dockConnection:Disconnect()
        dockConnection = nil
    end
    
    local dock = getDock()
    if dock then
        -- Watch for HP being added/removed
        dockConnection = dock.ChildAdded:Connect(function(child)
            if child.Name == "HP" and child:IsA("IntValue") then
                print("[HP] HP instance added")
            end
        end)
        
        -- Also watch for HP value changes
        local hpInt = dock:FindFirstChild("HP")
        if hpInt and hpInt:IsA("IntValue") then
            hpInt:GetPropertyChangedSignal("Value"):Connect(function()
                -- HP changed, no action needed but we can log
            end)
        end
    end
end

-- Watch for Timer instance changes
local function watchTimer()
    if timerConnection then
        timerConnection:Disconnect()
        timerConnection = nil
    end
    
    local timerFolder = Workspace:FindFirstChild("VariableFolder")
    if timerFolder then
        -- Watch for TimerVal being added/removed
        timerConnection = timerFolder.ChildAdded:Connect(function(child)
            if child.Name == "TimerVal" and child:IsA("IntValue") then
                print("[Timer] TimerVal instance added")
            end
        end)
        
        -- Also watch for TimerVal value changes
        local timerVal = timerFolder:FindFirstChild("TimerVal")
        if timerVal and timerVal:IsA("IntValue") then
            timerVal:GetPropertyChangedSignal("Value"):Connect(function()
                -- Timer changed, no action needed but we can log
            end)
        end
    end
end

-- ============================================
-- RESPAWN HANDLING
-- ============================================

local function respawnCharacter()
    print("[Respawn] Character died, waiting for respawn...")
    
    -- Stop firing
    isFiring = false
    
    -- Clean up float
    cleanupFloat()
    
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
    
    -- Wait for character to respawn
    local character = player.CharacterAdded:Wait()
    print("[Respawn] Character respawned")
    
    -- Restart the setup
    task.wait(1)
    setup()
end

-- ============================================
-- FLOAT SYSTEM
-- ============================================

local function cleanupFloat()
    if floatData.attachment then
        floatData.attachment:Destroy()
    end
    if floatData.antiGravity then
        floatData.antiGravity:Destroy()
    end
    if floatData.alignPosition then
        floatData.alignPosition:Destroy()
    end
    floatData = {}
end

local function lockAboveDock()
    cleanupFloat()
    
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
    
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end
    
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    humanoid.AutoRotate = false
    
    local dock = getDock()
    if not dock then return end
    
    local OFFSET = Vector3.new(0, 100, -150)
    local targetPos = dock.Position + OFFSET
    
    hrp.CFrame = CFrame.new(targetPos)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    
    local attachment = Instance.new("Attachment")
    attachment.Name = "FloatAttachment"
    attachment.Parent = hrp
    
    local antiGravity = Instance.new("VectorForce")
    antiGravity.Name = "AntiGravity"
    antiGravity.Attachment0 = attachment
    antiGravity.RelativeTo = Enum.ActuatorRelativeTo.World
    antiGravity.Force = Vector3.new(0, Workspace.Gravity * hrp.AssemblyMass, 0)
    antiGravity.Parent = hrp
    
    local alignPosition = Instance.new("AlignPosition")
    alignPosition.Name = "FloatAlign"
    alignPosition.Attachment0 = attachment
    alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPosition.Position = targetPos
    alignPosition.MaxForce = hrp.AssemblyMass * 1000
    alignPosition.MaxVelocity = 50
    alignPosition.Responsiveness = 200
    alignPosition.Enabled = true
    alignPosition.Parent = hrp
    
    floatData = {
        attachment = attachment,
        antiGravity = antiGravity,
        alignPosition = alignPosition
    }
    
    local myGen = currentGen
    renderConn = RunService.Heartbeat:Connect(function()
        if currentGen ~= myGen then
            renderConn:Disconnect()
            renderConn = nil
            return
        end
        
        -- Re-get dock in case it moved
        local dock = getDock()
        if dock and alignPosition and hrp then
            local newPos = dock.Position + OFFSET
            alignPosition.Position = newPos
            
            if hrp and hrp.AssemblyMass then
                antiGravity.Force = Vector3.new(0, Workspace.Gravity * hrp.AssemblyMass, 0)
            end
        end
    end)
end

-- ============================================
-- FIRING LOGIC
-- ============================================

local function canFire()
    local hp = getDockHP()
    local timer = getTimer()
    
    if hp == nil or timer == nil then
        return false
    end
    
    local timeElapsed = ROUND_DURATION - timer
    local isEarlyGame = timeElapsed < STOP_TIME
    
    if isEarlyGame then
        return hp > SAFE_STOP_HP
    end
    
    return hp > 0
end

local function fireRPG()
    local event = ReplicatedStorage:FindFirstChild("Event")
    if not event then
        -- Wait for event to exist
        event = ReplicatedStorage:WaitForChild("Event", 5)
        if not event then return end
    end
    
    local dock = getDock()
    if dock then
        local pos = dock.Position
        if equipTool("RPG") then
            event:FireServer("fireRPG", { Vector3.new(pos.X, pos.Y, pos.Z) })
        end
    end
end

local function getFireDelay()
    local hp = getDockHP()
    local timer = getTimer()
    
    if not hp or not timer then
        return 0.5
    end
    
    local timeElapsed = ROUND_DURATION - timer
    
    -- Late game: fast spam
    if timeElapsed >= STOP_TIME then
        return 0.05
    end
    
    -- Early game: based on HP
    if hp > 20000 then
        return 0.5
    elseif hp > 10000 then
        return 0.8
    elseif hp > 5000 then
        return 1.2
    elseif hp > SAFE_STOP_HP then
        return 1.8
    else
        return 2.0
    end
end

local function fireLoop(myGen)
    isFiring = true
    
    while currentGen == myGen and isFiring do
        -- Check if we should fire
        if canFire() then
            fireRPG()
        end
        
        -- Get adaptive delay
        local delay = getFireDelay()
        task.wait(delay)
        
        -- If we're in late game, check more frequently
        local timer = getTimer()
        if timer then
            local timeElapsed = ROUND_DURATION - timer
            if timeElapsed >= STOP_TIME then
                task.wait(0.05) -- Fast spam to finish
            end
        end
        
        -- Check if we died
        if not player.Character then
            print("[FireLoop] Character died, stopping")
            isFiring = false
            break
        end
    end
end

-- ============================================
-- SETUP
-- ============================================

function setup()
    print("[Setup] Starting...")
    
    -- Increment generation to stop old loops
    currentGen = currentGen + 1 
    local myGen = currentGen
    
    -- Stop firing
    isFiring = false
    task.wait(0.1)
    
    -- Watch for changes
    watchHP()
    watchTimer()
    
    -- Lock above dock
    lockAboveDock()
    
    -- Start firing
    isFiring = true
    task.spawn(fireLoop, myGen)
    
    print("[Setup] Complete")
end

-- ============================================
-- EVENT HANDLING
-- ============================================

-- Handle respawn
player.CharacterAdded:Connect(function(character)
    print("[Event] Character added, waiting for setup...")
    -- Wait for character to fully load
    task.wait(1)
    setup()
end)

-- Handle character removal (death)
player.CharacterRemoving:Connect(function()
    print("[Event] Character removed, cleaning up...")
    isFiring = false
    cleanupFloat()
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
end)

-- Handle team changes
player:GetPropertyChangedSignal("Team"):Connect(function()
    print("[Event] Team changed, restarting...")
    isFiring = false
    cleanupFloat()
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
    task.wait(0.5)
    if player.Character then
        setup()
    end
end)

-- Handle workspace changes (dock recreated)
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "USDock" or child.Name == "JapanDock" then
        print("[Event] Dock added, restarting...")
        task.wait(0.5)
        if player.Character then
            setup()
        end
    end
end)

-- Handle VariableFolder changes (timer recreated)
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "VariableFolder" then
        print("[Event] VariableFolder added, updating timer watch...")
        watchTimer()
    end
end)

-- ============================================
-- DEBUG STATUS
-- ============================================

task.spawn(function()
    while true do
        task.wait(10)
        local hp = getDockHP()
        local timer = getTimer()
        local timeElapsed = timer and (ROUND_DURATION - timer) or 0
        local canFireStatus = canFire()
        local isDead = not player.Character
        
        print(string.format(
            "[Status] HP: %s | Timer: %s | Time: %d/%ds | CanFire: %s | Dead: %s",
            tostring(hp or "N/A"),
            tostring(timer or "N/A"),
            timeElapsed,
            ROUND_DURATION,
            tostring(canFireStatus),
            tostring(isDead)
        ))
    end
end)

-- ============================================
-- HP PATH DEBUGGER
-- ============================================

local function debugHPPath()
    print("=====================================")
    print("🔍 HP PATH DEBUGGER")
    print("=====================================")
    
    -- 1. Check team
    if not player.Team then
        print("❌ No team assigned yet")
        return
    end
    print("✓ Team: " .. player.Team.Name)
    
    -- 2. Find the dock
    local dockName = player.Team.Name == "Japan" and "USDock" or "JapanDock"
    print("Looking for: " .. dockName)
    
    local dock = Workspace:FindFirstChild(dockName)
    if not dock then
        print("❌ Dock not found in Workspace")
        print("   Available docks:")
        for _, child in ipairs(Workspace:GetChildren()) do
            if child.Name:match("Dock") then
                print("   - " .. child.Name)
            end
        end
        return
    end
    print("✓ Dock found: " .. dock.Name)
    
    -- 3. Find MainBody
    local mainBody = dock:FindFirstChild("MainBody")
    if not mainBody then
        print("❌ MainBody not found in dock")
        print("   Children in dock:")
        for _, child in ipairs(dock:GetChildren()) do
            print("   - " .. child.Name .. " (" .. child.ClassName .. ")")
        end
        return
    end
    print("✓ MainBody found: " .. mainBody.Name)
    
    -- 4. Find HP
    local hp = mainBody:FindFirstChild("HP")
    if not hp then
        print("❌ HP not found in MainBody")
        print("   Children in MainBody:")
        for _, child in ipairs(mainBody:GetChildren()) do
            print("   - " .. child.Name .. " (" .. child.ClassName .. ")")
        end
        
        -- Search deeper (maybe HP is nested)
        print("   Searching deeper for 'HP'...")
        local foundHP = mainBody:FindFirstChild("HP", true)
        if foundHP then
            print("   ✓ Found HP at: " .. foundHP:GetFullName())
            print("   - Class: " .. foundHP.ClassName)
            if foundHP:IsA("IntValue") then
                print("   - Value: " .. tostring(foundHP.Value))
            end
        else
            print("   ❌ No HP found anywhere in MainBody")
        end
        return
    end
    
    print("✓ HP found!")
    print("   - Full path: " .. hp:GetFullName())
    print("   - Class: " .. hp.ClassName)
    
    if hp:IsA("IntValue") then
        print("   - Value: " .. tostring(hp.Value))
        print("   - Can be read with: hp.Value")
    elseif hp:IsA("NumberValue") then
        print("   - Value: " .. tostring(hp.Value))
        print("   - Can be read with: hp.Value")
    elseif hp:IsA("Attribute") then
        print("   - Value: " .. tostring(hp.Value))
        print("   - Can be read with: mainBody:GetAttribute('HP')")
    else
        print("   ⚠️ Unknown HP type: " .. hp.ClassName)
        print("   Available properties:")
        for _, prop in ipairs(hp:GetProperties()) do
            print("   - " .. prop)
        end
    end
    
    print("=====================================")
    
    -- Return the HP object for further inspection
    return hp
end

-- ============================================
-- DETAILED PATH FINDER (Recursive)
-- ============================================

local function findHPPath()
    print("=====================================")
    print("🔍 DETAILED HP SEARCH")
    print("=====================================")
    
    -- Search entire workspace for anything with "HP" in name
    local matches = {}
    local function search(container, path)
        for _, child in ipairs(container:GetChildren()) do
            local currentPath = path .. "." .. child.Name
            if child.Name:match("HP") or child.Name:match("Health") or child.Name:match("health") then
                table.insert(matches, {
                    name = child.Name,
                    path = currentPath,
                    class = child.ClassName,
                    value = child:IsA("IntValue") and child.Value or 
                            child:IsA("NumberValue") and child.Value or 
                            "N/A"
                })
            end
            if #child:GetChildren() > 0 then
                search(child, currentPath)
            end
        end
    end
    
    search(Workspace, "Workspace")
    
    if #matches == 0 then
        print("❌ No 'HP' or 'Health' found in workspace")
        print("   Try checking: ReplicatedStorage, Players, or other services")
        return
    end
    
    print("Found " .. #matches .. " potential HP/Health objects:")
    for i, match in ipairs(matches) do
        print(string.format("%d. %s", i, match.path))
        print("   - Name: " .. match.name)
        print("   - Class: " .. match.class)
        print("   - Value: " .. tostring(match.value))
        print("")
    end
    
    print("=====================================")
    return matches
end

-- ============================================
-- RUN THE DEBUGGER
-- ============================================

-- Run this to find the HP path
task.spawn(function()
    task.wait(2) -- Wait for everything to load
    debugHPPath()
    findHPPath()
end)

-- Also print HP every 5 seconds to monitor
task.spawn(function()
    while true do
        task.wait(5)
        local hp = getDockHP()
        if hp ~= nil then
            print("[HP Monitor] HP = " .. hp)
        else
            print("[HP Monitor] ❌ HP is nil - path might be wrong")
        end
    end
end)

-- ============================================
-- INITIAL START
-- ============================================

print("[Init] Script loaded, waiting for character...")

if player.Character then
    task.wait(1)
    setup()
else
    player.CharacterAdded:Wait()
    task.wait(1)
    setup()
end
