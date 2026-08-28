-- LocalScript (StarterPlayerScripts)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local OFFSET = Vector3.new(0, 100, -150)
local fireCooldown = 2.13

local renderConn = nil
local currentGen = 0
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
        local dock = workspace:FindFirstChild("USDock")
        return dock and dock:FindFirstChild("MainBody")
    elseif player.Team.Name == "USA" then
        local dock = workspace:FindFirstChild("JapanDock")
        return dock and dock:FindFirstChild("MainBody")
    end
    return nil
end

local function fireToDock(myGen)
    local event = ReplicatedStorage:WaitForChild("Event")
    while currentGen == myGen do  
        local dock = getDock()
        if dock then
            local pos = dock.Position
            equipTool("RPG")
            event:FireServer("fireRPG", { Vector3.new(pos.X, pos.Y, pos.Z) })
        end
        task.wait(fireCooldown)
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

local function setup()
    currentGen = currentGen + 1 
    local myGen = currentGen
    task.wait(0.2)
    lockAboveDock()
    task.spawn(fireToDock, myGen)
end

player.CharacterRemoving:Connect(function()
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
