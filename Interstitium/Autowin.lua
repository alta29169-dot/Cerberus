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
        local hpInt = dock.Parent:FindFirstChild("HP")
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
        dockConnection = dock.Parent.ChildAdded:Connect(function(child)
            if child.Name == "HP" and child:IsA("IntValue") then
                print("[HP] HP instance added")
            end
        end)
        
        -- Also watch for HP value changes
        local hpInt = dock.Parent:FindFirstChild("HP")
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
    print("[FIRE] Attempting to fire RPG...")  -- Add this
    
    local event = ReplicatedStorage:FindFirstChild("Event")
    if not event then 
        print("[FIRE] ❌ Event not found")
        return false 
    end
    
    local dock = getDock()
    if not dock then 
        print("[FIRE] ❌ No dock")
        return false 
    end
    
    local pos = dock.Position
    print("[FIRE] ✅ Firing at: " .. tostring(pos.X) .. ", " .. tostring(pos.Y) .. ", " .. tostring(pos.Z))
    
    equipTool("RPG")
    event:FireServer("fireRPG", { Vector3.new(pos.X, pos.Y, pos.Z) })
    print("[FIRE] ✅ Remote fired!")
    return true
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
