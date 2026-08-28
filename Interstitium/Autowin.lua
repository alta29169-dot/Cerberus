-- LocalScript (StarterPlayerScripts) which is heall yeah
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
local isNoRender = false

-- ============================================
-- ANTI-AFK SYSTEM (Delta Optimized)
-- ============================================

local function antiAFK()
    print("[Anti-AFK] Initialized (keypress + jump + camera)")
    
    task.spawn(function()
        while true do
            local waitTime = math.random(250, 750) / 10
            task.wait(waitTime)
            
            local action = math.random(1, 3)
            
            if action == 1 then
                if keypress then
                    local keys = {"w", "a", "s", "d"}
                    local key = keys[math.random(#keys)]
                    keypress(key)
                    task.wait(0.05)
                    keypress(key)
                    
                    if math.random(1, 3) == 1 then
                        task.wait(0.1)
                        keypress(key)
                        task.wait(0.05)
                        keypress(key)
                    end
                end
                
            elseif action == 2 then
                local character = player.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:Jump()
                        if math.random(1, 3) == 1 then
                            task.wait(0.2)
                            humanoid:Jump()
                        end
                    end
                end
                
            elseif action == 3 then
                local character = player.Character
                if character then
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    if hrp and workspace.CurrentCamera then
                        local currentCF = workspace.CurrentCamera.CFrame
                        local angle = math.rad(math.random(-20, 20))
                        local newCF = currentCF * CFrame.Angles(0, angle, 0)
                        workspace.CurrentCamera.CFrame = newCF
                        
                        if math.random(1, 2) == 1 then
                            local vertAngle = math.rad(math.random(-10, 10))
                            workspace.CurrentCamera.CFrame = newCF * CFrame.Angles(vertAngle, 0, 0)
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================
-- NORENDER SYSTEM
-- ============================================

local function toggleNoRender(enable)
    if isNoRender == enable then return end
    
    local success, err = pcall(function()
        RunService:Set3dRenderingEnabled(not enable)
    end)
    
    if success then
        isNoRender = enable
        if enable then
            print("[NoRender] ✅ 3D rendering disabled (white screen)")
        else
            print("[NoRender] ✅ 3D rendering re-enabled")
        end
    else
        print("[NoRender] ❌ Failed: " .. tostring(err))
    end
end

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

local function watchHP()
    if dockConnection then
        dockConnection:Disconnect()
        dockConnection = nil
    end
    
    local dock = getDock()
    if dock then
        dockConnection = dock.Parent.ChildAdded:Connect(function(child)
            if child.Name == "HP" and child:IsA("IntValue") then
                print("[HP] HP instance added")
            end
        end)
        
        local hpInt = dock.Parent:FindFirstChild("HP")
        if hpInt and hpInt:IsA("IntValue") then
            hpInt:GetPropertyChangedSignal("Value"):Connect(function()
                -- HP changed, no action needed
            end)
        end
    end
end

local function watchTimer()
    if timerConnection then
        timerConnection:Disconnect()
        timerConnection = nil
    end
    
    local timerFolder = Workspace:FindFirstChild("VariableFolder")
    if timerFolder then
        timerConnection = timerFolder.ChildAdded:Connect(function(child)
            if child.Name == "TimerVal" and child:IsA("IntValue") then
                print("[Timer] TimerVal instance added")
            end
        end)
        
        local timerVal = timerFolder:FindFirstChild("TimerVal")
        if timerVal and timerVal:IsA("IntValue") then
            timerVal:GetPropertyChangedSignal("Value"):Connect(function()
                -- Timer changed, no action needed
            end)
        end
    end
end

-- ============================================
-- RESPAWN HANDLING
-- ============================================

local function respawnCharacter()
    print("[Respawn] Character died, waiting for respawn...")
    isFiring = false
    cleanupFloat()
    
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
    
    local character = player.CharacterAdded:Wait()
    print("[Respawn] Character respawned")
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
    if not event then return false end
    
    local dock = getDock()
    if not dock then return false end
    
    local pos = dock.Position
    equipTool("RPG")
    event:FireServer("fireRPG", { Vector3.new(pos.X, pos.Y, pos.Z) })
    return true
end

local function getFireDelay()
    local hp = getDockHP()
    local timer = getTimer()
    
    if not hp or not timer then
        return 0.5
    end
    
    local timeElapsed = ROUND_DURATION - timer
    
    if timeElapsed >= STOP_TIME then
        return 0.05
    end
    
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
        if canFire() then
            fireRPG()
        end
        
        local delay = getFireDelay()
        task.wait(delay)
        
        local timer = getTimer()
        if timer then
            local timeElapsed = ROUND_DURATION - timer
            if timeElapsed >= STOP_TIME then
                task.wait(0.05)
            end
        end
        
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
    
    currentGen = currentGen + 1 
    local myGen = currentGen
    
    isFiring = false
    task.wait(0.1)
    
    watchHP()
    watchTimer()
    lockAboveDock()
    
    -- Enable NoRender AFTER everything is set up
    if not isNoRender then
        toggleNoRender(true)
    end
    
    isFiring = true
    task.spawn(fireLoop, myGen)
    
    print("[Setup] Complete")
end

-- ============================================
-- EVENT HANDLING
-- ============================================

player.CharacterAdded:Connect(function(character)
    print("[Event] Character added, waiting for setup...")
    task.wait(1)
    setup()
end)

player.CharacterRemoving:Connect(function()
    print("[Event] Character removed, cleaning up...")
    isFiring = false
    cleanupFloat()
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
end)

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

Workspace.ChildAdded:Connect(function(child)
    if child.Name == "USDock" or child.Name == "JapanDock" then
        print("[Event] Dock added, restarting...")
        task.wait(0.5)
        if player.Character then
            setup()
        end
    end
end)

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
            "[Status] HP: %s | Timer: %s | Time: %d/%ds | CanFire: %s | Dead: %s | NoRender: %s",
            tostring(hp or "N/A"),
            tostring(timer or "N/A"),
            timeElapsed,
            ROUND_DURATION,
            tostring(canFireStatus),
            tostring(isDead),
            tostring(isNoRender)
        ))
    end
end)

-- ============================================
-- INITIAL START
-- ============================================

print("[Init] Script loaded, waiting for character...")

-- Start Anti-AFK immediately
antiAFK()

if player.Character then
    task.wait(1)
    setup()
else
    player.CharacterAdded:Wait()
    task.wait(1)
    setup()
end
