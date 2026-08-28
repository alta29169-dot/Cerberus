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

local function equipTool(toolName)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end
    local tool = backpack:FindFirstChild(toolName)
    if tool then
        humanoid:EquipTool(tool)
    end
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
        local hpInt = dock:FindFirstChild("HP")
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

local function canFire()
    local hp = getDockHP()
    local timer = getTimer()
    
    if hp == nil or timer == nil then
        return false
    end
    
    local timeElapsed = ROUND_DURATION - timer
    local isEarlyGame = timeElapsed < STOP_TIME
    
    -- Early game: Stop at safe HP threshold
    if isEarlyGame then
        return hp > SAFE_STOP_HP
    end
    
    -- Late game: Finish the dock
    return hp > 0
end

local function fireRPG()
    local event = ReplicatedStorage:WaitForChild("Event")
    local dock = getDock()
    if dock then
        local pos = dock.Position
        equipTool("RPG")
        event:FireServer("fireRPG", { Vector3.new(pos.X, pos.Y, pos.Z) })
    end
end

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
    
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    
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
        if dock and alignPosition then
            local newPos = dock.Position + OFFSET
            alignPosition.Position = newPos
            
            if hrp and hrp.AssemblyMass then
                antiGravity.Force = Vector3.new(0, Workspace.Gravity * hrp.AssemblyMass, 0)
            end
        end
    end)
end

local function fireLoop(myGen)
    isFiring = true
    
    while currentGen == myGen and isFiring do
        if canFire() then
            fireRPG()
        end
        
        -- Check HP and timer more frequently near thresholds
        local hp = getDockHP()
        local timer = getTimer()
        local timeElapsed = ROUND_DURATION - (timer or 0)
        
        -- Speed up firing when HP is high, slow down near threshold
        if hp and hp > 5000 then
            task.wait(0.05) -- Fast spam
        elseif hp and hp > 2000 then
            task.wait(0.1) -- Medium pace
        elseif hp and hp > SAFE_STOP_HP then
            task.wait(0.15) -- Slow down near threshold
        else
            task.wait(0.5) -- Idle check
        end
        
        -- If we're in late game, check more frequently
        if timeElapsed >= STOP_TIME then
            task.wait(0.05) -- Fast spam to finish
        end
    end
end

local function setup()
    currentGen = currentGen + 1 
    local myGen = currentGen
    
    task.wait(0.2)
    lockAboveDock()
    
    -- Stop any existing fire loop
    isFiring = false
    task.wait(0.1)
    
    -- Start new fire loop
    isFiring = true
    task.spawn(fireLoop, myGen)
end

-- Clean up on character death
player.CharacterRemoving:Connect(function()
    isFiring = false
    cleanupFloat()
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
end)

player.CharacterAdded:Connect(setup)
if player.Character then
    setup()
end

-- Print status messages for debugging
task.spawn(function()
    while true do
        task.wait(10)
        local hp = getDockHP()
        local timer = getTimer()
        local timeElapsed = ROUND_DURATION - (timer or 0)
        local canFireStatus = canFire()
        
        print(string.format(
            "[Status] HP: %d | Timer: %ds | Time: %d/%ds | CanFire: %s",
            hp or 0,
            timer or 0,
            timeElapsed,
            ROUND_DURATION,
            tostring(canFireStatus)
        ))
    end
end)
