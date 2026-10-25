--!strict
--[[
    TrapService.luau
    Authoritative server-side trap controller managing all 6 functional traps:
    1. CollapsingBridge
    2. SwingingHammer
    3. FallingCeiling
    4. MovingWall
    5. RotatingPlatform
    6. Pitfall

    Features:
    - Shared server-side cooldown enforcement across all trap controllers
    - Per-player input debounce to prevent rapid spamming
    - Real-time physics, tweens, and hazard zone damage
    - Clean state recovery and round reset
    - Remote notifications to sync client UI and audio
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enums = require(Shared:WaitForChild("Enums"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local TrapConfig = require(Shared:WaitForChild("TrapConfig"))

local TrapService = {}

type TrapState = {
    IsAvailable: boolean,
    IsActive: boolean,
    CooldownExpiry: number,
    ActiveExpiry: number,
    LastActivatedBy: Player?,
    ActiveThread: thread?,
}

local trapStates: { [string]: TrapState } = {}
local playerDebounce: { [Player]: number } = {}
local recentTrapController: Player? = nil
local recentTrapTime: number = 0

local NetworkService: any
local PlayerStateService: any
local RoundService: any

-- Default initial transforms and properties for clean resetting
local initialTransforms: { [string]: { [BasePart]: { CFrame: CFrame, CanCollide: boolean, Transparency: number, Color: Color3, Material: Enum.Material } } } = {}

function TrapService.Init(deps: { 
    NetworkService: any, 
    PlayerStateService: any, 
    RoundService: any 
})
    NetworkService = deps.NetworkService
    PlayerStateService = deps.PlayerStateService
    RoundService = deps.RoundService

    -- Initialize state for every trap definition
    for id, def in pairs(TrapConfig.Traps) do
        trapStates[id] = {
            IsAvailable = true,
            IsActive = false,
            CooldownExpiry = 0,
            ActiveExpiry = 0,
            LastActivatedBy = nil,
            ActiveThread = nil,
        }
        initialTransforms[id] = {}
    end

    -- Hook up remote client activation requests
    NetworkService.ConnectServerEvent("ActivateTrap", function(player: Player, trapId: string)
        TrapService.RequestTrapActivation(player, trapId)
    end)
end

function TrapService.RegisterTrapParts(trapId: string, model: Model)
    initialTransforms[trapId] = {}
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            initialTransforms[trapId][desc] = {
                CFrame = desc.CFrame,
                CanCollide = desc.CanCollide,
                Transparency = desc.Transparency,
                Color = desc.Color,
                Material = desc.Material,
            }
        end
    end
end

function TrapService.RequestTrapActivation(player: Player, trapId: string): (boolean, string?)
    local def = TrapConfig.Traps[trapId]
    if not def then
        return false, "InvalidTrapId"
    end

    -- 1. Check player debounce
    local now = os.clock()
    local lastInput = playerDebounce[player] or 0
    if now - lastInput < GameConfig.PlayerInputDebounce then
        return false, "Debounced"
    end
    playerDebounce[player] = now

    -- 2. Validate round state
    if not RoundService or not RoundService.IsRoundInProgress() then
        return false, "RoundNotInProgress"
    end

    -- 3. Validate player role
    local role = PlayerStateService.GetPlayerState(player)
    if role ~= Enums.PlayerState.TrapController then
        -- Allow DevMode override for testing if enabled
        if not GameConfig.DevMode then
            return false, "UnauthorizedRole"
        end
    end

    -- 4. Validate player character is alive
    local character = player.Character
    if not character or not character:FindFirstChild("Humanoid") then
        return false, "CharacterNotAlive"
    end

    -- 5. Validate trap cooldown & availability (Mutual exclusion lock)
    local state = trapStates[trapId]
    if not state.IsAvailable or state.IsActive or now < state.CooldownExpiry then
        return false, "OnCooldown"
    end

    -- Acquire trap activation lock immediately
    state.IsAvailable = false
    state.IsActive = true
    state.CooldownExpiry = now + def.Cooldown
    state.ActiveExpiry = now + def.ActiveDuration
    state.LastActivatedBy = player
    recentTrapController = player
    recentTrapTime = now

    -- Broadcast state update to all clients for real-time UI/sound response
    NetworkService.FireAllClients(
        "TrapStateChanged",
        trapId,
        false, -- isAvailable
        true,  -- isActive
        def.Cooldown,
        def.ActiveDuration,
        player.DisplayName
    )

    NetworkService.FireAllClients(
        "Announcement",
        string.format("TRAP TRIGGERED: %s", string.upper(def.DisplayName)),
        string.format("Activated by %s", player.DisplayName),
        def.AccentColor,
        "TrapAlarm"
    )

    -- Launch authoritative physical trap execution in dedicated thread
    state.ActiveThread = task.spawn(function()
        TrapService.ExecuteTrap(trapId, def, player)
    end)

    return true, nil
end

function TrapService.ExecuteTrap(trapId: string, def: any, player: Player)
    local state = trapStates[trapId]
    local trapsFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Traps")
    local trapModel = trapsFolder and trapsFolder:FindFirstChild(trapId)

    if trapModel then
        if trapId == "CollapsingBridge" then
            TrapService.RunCollapsingBridge(trapModel, def)
        elseif trapId == "SwingingHammer" then
            TrapService.RunSwingingHammer(trapModel, def, player)
        elseif trapId == "FallingCeiling" then
            TrapService.RunFallingCeiling(trapModel, def, player)
        elseif trapId == "MovingWall" then
            TrapService.RunMovingWall(trapModel, def, player)
        elseif trapId == "RotatingPlatform" then
            TrapService.RunRotatingPlatform(trapModel, def)
        elseif trapId == "Pitfall" then
            TrapService.RunPitfall(trapModel, def)
        end
    else
        -- If physical model is not yet in workspace, wait out the duration
        task.wait(def.ActiveDuration)
    end

    -- Trap physical active duration has finished
    state.IsActive = false

    local now = os.clock()
    local remainingCooldown = math.max(0, state.CooldownExpiry - now)

    -- Broadcast active ended, entering cooldown
    NetworkService.FireAllClients(
        "TrapStateChanged",
        trapId,
        false, -- isAvailable
        false, -- isActive
        remainingCooldown,
        0,
        nil
    )

    -- Wait out remaining cooldown
    if remainingCooldown > 0 then
        task.wait(remainingCooldown)
    end

    -- Cooldown complete! Reset to available
    state.IsAvailable = true
    state.ActiveThread = nil

    NetworkService.FireAllClients(
        "TrapStateChanged",
        trapId,
        true,  -- isAvailable
        false, -- isActive
        0,
        0,
        nil
    )
end

-- ==================== TRAP 1: COLLAPSING BRIDGE ====================
function TrapService.RunCollapsingBridge(model: Model, def: any)
    local warningPillars = model:FindFirstChild("WarningPillars")
    local planksFolder = model:FindFirstChild("Planks")

    -- Warning flash
    if warningPillars then
        for _, part in ipairs(warningPillars:GetChildren()) do
            if part:IsA("BasePart") then
                part.Color = Color3.fromRGB(255, 30, 30)
                part.Material = Enum.Material.Neon
            end
        end
    end
    task.wait(def.WarningDuration)

    -- Drop bridge planks
    if planksFolder then
        for _, plank in ipairs(planksFolder:GetChildren()) do
            if plank:IsA("BasePart") then
                plank.CanCollide = false
                plank.Transparency = 0.85
                plank.Color = Color3.fromRGB(255, 50, 50)
            end
        end
    end

    task.wait(def.ActiveDuration)

    -- Restore bridge planks
    if planksFolder then
        for _, plank in ipairs(planksFolder:GetChildren()) do
            if plank:IsA("BasePart") then
                plank.CanCollide = true
                plank.Transparency = 0
                plank.Color = Color3.fromRGB(80, 85, 95)
                plank.Material = Enum.Material.DiamondPlate
            end
        end
    end
    if warningPillars then
        for _, part in ipairs(warningPillars:GetChildren()) do
            if part:IsA("BasePart") then
                part.Color = Color3.fromRGB(60, 60, 60)
                part.Material = Enum.Material.SmoothPlastic
            end
        end
    end
end

-- ==================== TRAP 2: SWINGING HAMMER ====================
function TrapService.RunSwingingHammer(model: Model, def: any, player: Player)
    local arch = model:FindFirstChild("Arch")
    local hammer = model:FindFirstChild("Hammer") :: Model?
    local head = hammer and hammer:FindFirstChild("Head") :: BasePart?
    local pivot = model:FindFirstChild("Pivot") :: BasePart?

    -- Warning indication
    if arch then
        for _, p in ipairs(arch:GetChildren()) do
            if p:IsA("BasePart") and p.Name:find("Beacon") then
                p.Color = Color3.fromRGB(255, 170, 0)
                p.Material = Enum.Material.Neon
            end
        end
    end
    task.wait(def.WarningDuration)

    -- Connect lethal touch during swing
    local touchConn: RBXScriptConnection? = nil
    if head then
        touchConn = head.Touched:Connect(function(hit)
            local char = hit.Parent
            local hum = char and char:FindFirstChild("Humanoid") :: Humanoid?
            if hum and hum.Health > 0 then
                local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
                if root then
                    -- Fling runner off platform with lateral knockback
                    root.AssemblyLinearVelocity = Vector3.new(0, 40, -60)
                end
                hum:TakeDamage(100)
            end
        end)
    end

    -- Swing hammer back and forth across walkway
    local startTime = os.clock()
    local duration = def.ActiveDuration
    local swingAngleMax = math.rad(65)

    local initialCFrame = hammer and hammer:GetPivot() or CFrame.new()

    while os.clock() - startTime < duration do
        local elapsed = os.clock() - startTime
        local progress = elapsed / duration
        -- Sinusoidal swing: 2 full swings
        local currentAngle = math.sin(progress * math.pi * 4) * swingAngleMax

        if hammer and pivot then
            hammer:PivotTo(pivot.CFrame * CFrame.Angles(0, 0, currentAngle))
        end
        task.wait(0.03)
    end

    if touchConn then
        touchConn:Disconnect()
    end

    -- Return hammer to rest position
    if hammer and initialCFrame then
        hammer:PivotTo(initialCFrame)
    end
end

-- ==================== TRAP 3: FALLING CEILING ====================
function TrapService.RunFallingCeiling(model: Model, def: any, player: Player)
    local crusher = model:FindFirstChild("Crusher") :: BasePart?
    local warningLights = model:FindFirstChild("WarningLights")

    if warningLights then
        for _, light in ipairs(warningLights:GetChildren()) do
            if light:IsA("BasePart") then
                light.Color = Color3.fromRGB(255, 20, 20)
                light.Material = Enum.Material.Neon
            end
        end
    end
    task.wait(def.WarningDuration)

    if crusher then
        local originalCFrame = crusher.CFrame
        local downCFrame = originalCFrame - Vector3.new(0, 16, 0)

        -- Lethal touch connection while crushing
        local touchConn = crusher.Touched:Connect(function(hit)
            local char = hit.Parent
            local hum = char and char:FindFirstChild("Humanoid") :: Humanoid?
            if hum and hum.Health > 0 then
                hum:TakeDamage(100)
            end
        end)

        -- Slam down rapidly in 0.25s
        local slamTween = TweenService:Create(crusher, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            CFrame = downCFrame
        })
        slamTween:Play()
        slamTween.Completed:Wait()

        -- Hold crushed position
        task.wait(1.5)

        if touchConn then
            touchConn:Disconnect()
        end

        -- Retract back up to ceiling
        local retractTween = TweenService:Create(crusher, TweenInfo.new(1.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = originalCFrame
        })
        retractTween:Play()
        retractTween.Completed:Wait()
    else
        task.wait(def.ActiveDuration)
    end

    if warningLights then
        for _, light in ipairs(warningLights:GetChildren()) do
            if light:IsA("BasePart") then
                light.Color = Color3.fromRGB(50, 50, 50)
                light.Material = Enum.Material.SmoothPlastic
            end
        end
    end
end

-- ==================== TRAP 4: MOVING WALL ====================
function TrapService.RunMovingWall(model: Model, def: any, player: Player)
    local wall = model:FindFirstChild("Pusher") :: BasePart?
    local warningSign = model:FindFirstChild("WarningSign") :: BasePart?

    if warningSign then
        warningSign.Color = Color3.fromRGB(0, 200, 255)
        warningSign.Material = Enum.Material.Neon
    end
    task.wait(def.WarningDuration)

    if wall then
        local originalCFrame = wall.CFrame
        local extendedCFrame = originalCFrame + Vector3.new(24, 0, 0)

        -- Wall fling touch
        local touchConn = wall.Touched:Connect(function(hit)
            local char = hit.Parent
            local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
            if root then
                root.AssemblyLinearVelocity = Vector3.new(80, 25, 0)
            end
        end)

        -- Push across catwalk in 0.4s
        local pushTween = TweenService:Create(wall, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = extendedCFrame
        })
        pushTween:Play()
        pushTween.Completed:Wait()

        -- Hold extended
        task.wait(1.8)

        if touchConn then
            touchConn:Disconnect()
        end

        -- Retract back into wall
        local retractTween = TweenService:Create(wall, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            CFrame = originalCFrame
        })
        retractTween:Play()
        retractTween.Completed:Wait()
    else
        task.wait(def.ActiveDuration)
    end

    if warningSign then
        warningSign.Color = Color3.fromRGB(50, 50, 50)
        warningSign.Material = Enum.Material.SmoothPlastic
    end
end

-- ==================== TRAP 5: ROTATING PLATFORM ====================
function TrapService.RunRotatingPlatform(model: Model, def: any)
    local platform = model:FindFirstChild("SpinPlatform") :: BasePart?
    local beacons = model:FindFirstChild("Beacons")

    if beacons then
        for _, b in ipairs(beacons:GetChildren()) do
            if b:IsA("BasePart") then
                b.Color = Color3.fromRGB(200, 50, 255)
                b.Material = Enum.Material.Neon
            end
        end
    end
    task.wait(def.WarningDuration)

    if platform then
        local originalCFrame = platform.CFrame
        local startTime = os.clock()
        local duration = def.ActiveDuration

        while os.clock() - startTime < duration do
            local elapsed = os.clock() - startTime
            -- Spin around Y-axis rapidly, and tilt along Z-axis
            local spinAngle = elapsed * math.pi * 3
            local tiltAngle = math.sin(elapsed * math.pi * 2) * math.rad(45)

            platform.CFrame = originalCFrame * CFrame.Angles(tiltAngle, spinAngle, 0)
            task.wait(0.03)
        end

        -- Restore flat orientation
        local restoreTween = TweenService:Create(platform, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = originalCFrame
        })
        restoreTween:Play()
        restoreTween.Completed:Wait()
    else
        task.wait(def.ActiveDuration)
    end

    if beacons then
        for _, b in ipairs(beacons:GetChildren()) do
            if b:IsA("BasePart") then
                b.Color = Color3.fromRGB(50, 50, 50)
                b.Material = Enum.Material.SmoothPlastic
            end
        end
    end
end

-- ==================== TRAP 6: PITFALL ====================
function TrapService.RunPitfall(model: Model, def: any)
    local doorLeft = model:FindFirstChild("HatchLeft") :: BasePart?
    local doorRight = model:FindFirstChild("HatchRight") :: BasePart?
    local warningFrame = model:FindFirstChild("WarningFrame")

    if warningFrame then
        for _, part in ipairs(warningFrame:GetChildren()) do
            if part:IsA("BasePart") then
                part.Color = Color3.fromRGB(255, 30, 130)
                part.Material = Enum.Material.Neon
            end
        end
    end
    task.wait(def.WarningDuration)

    -- Drop trapdoors open
    if doorLeft and doorRight then
        doorLeft.CanCollide = false
        doorLeft.Transparency = 0.85
        doorLeft.Color = Color3.fromRGB(255, 50, 50)

        doorRight.CanCollide = false
        doorRight.Transparency = 0.85
        doorRight.Color = Color3.fromRGB(255, 50, 50)
    end

    task.wait(def.ActiveDuration)

    -- Close trapdoors
    if doorLeft and doorRight then
        doorLeft.CanCollide = true
        doorLeft.Transparency = 0
        doorLeft.Color = Color3.fromRGB(70, 75, 85)
        doorLeft.Material = Enum.Material.DiamondPlate

        doorRight.CanCollide = true
        doorRight.Transparency = 0
        doorRight.Color = Color3.fromRGB(70, 75, 85)
        doorRight.Material = Enum.Material.DiamondPlate
    end

    if warningFrame then
        for _, part in ipairs(warningFrame:GetChildren()) do
            if part:IsA("BasePart") then
                part.Color = Color3.fromRGB(50, 50, 50)
                part.Material = Enum.Material.SmoothPlastic
            end
        end
    end
end

function TrapService.ResetAllTraps()
    -- Cancel active trap threads
    for _, state in pairs(trapStates) do
        if state.ActiveThread then
            task.cancel(state.ActiveThread)
            state.ActiveThread = nil
        end
        state.IsAvailable = true
        state.IsActive = false
        state.CooldownExpiry = 0
        state.ActiveExpiry = 0
        state.LastActivatedBy = nil
    end

    -- Restore saved initial transforms & appearances
    for trapId, partsMap in pairs(initialTransforms) do
        for part, props in pairs(partsMap) do
            if part and part.Parent then
                part.CFrame = props.CFrame
                part.CanCollide = props.CanCollide
                part.Transparency = props.Transparency
                part.Color = props.Color
                part.Material = props.Material
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end

    -- Broadcast reset to all clients
    for id, _ in pairs(TrapConfig.Traps) do
        NetworkService.FireAllClients("TrapStateChanged", id, true, false, 0, 0, nil)
    end
end

function TrapService.GetRecentTrapController(): Player?
    if os.clock() - recentTrapTime < 5.0 then
        return recentTrapController
    end
    return nil
end

return TrapService
