--!strict
--[[
    MapService.luau
    Builds and wires the complete Deathrun 3D map:
    - Lobby, Runner Course, Elevated Controller Catwalk, Checkpoints, Finish, KillZone
    - 6 Functional Traps: CollapsingBridge, SwingingHammer, FallingCeiling, MovingWall, RotatingPlatform, Pitfall
    - Physical 3D controller terminals with ClickDetectors
    - Finish detection & KillZone lethal triggers
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local TrapConfig = require(Shared:WaitForChild("TrapConfig"))

local MapService = {}

local RoundService: any
local CheckpointService: any
local TrapService: any

function MapService.Init(deps: {
    RoundService: any,
    CheckpointService: any,
    TrapService: any,
})
    RoundService = deps.RoundService
    CheckpointService = deps.CheckpointService
    TrapService = deps.TrapService

    local mapFolder = Workspace:FindFirstChild("Map")
    if not mapFolder then
        mapFolder = MapService.BuildMap()
    end

    MapService.WireMapTriggers(mapFolder)
end

function MapService.CreatePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, anchored: boolean, canCollide: boolean): Part
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material
    part.Anchored = anchored ~= nil and anchored or true
    part.CanCollide = canCollide ~= nil and canCollide or true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

function MapService.BuildMap(): Folder
    local map = Instance.new("Folder")
    map.Name = "Map"
    map.Parent = Workspace

    -- ==================== 1. LOBBY ====================
    local lobby = Instance.new("Folder")
    lobby.Name = "Lobby"
    lobby.Parent = map

    -- Lobby floor (high above, looking down on the course)
    MapService.CreatePart(lobby, "Floor", Vector3.new(50, 4, 50), CFrame.new(0, 50, -80), Color3.fromRGB(30, 32, 40), Enum.Material.Metal, true, true)
    -- Lobby walls (glass front looking over course)
    MapService.CreatePart(lobby, "WallBack", Vector3.new(50, 16, 2), CFrame.new(0, 60, -105), Color3.fromRGB(20, 22, 28), Enum.Material.SmoothPlastic, true, true)
    MapService.CreatePart(lobby, "WallLeft", Vector3.new(2, 16, 50), CFrame.new(-25, 60, -80), Color3.fromRGB(20, 22, 28), Enum.Material.SmoothPlastic, true, true)
    MapService.CreatePart(lobby, "WallRight", Vector3.new(2, 16, 50), CFrame.new(25, 60, -80), Color3.fromRGB(20, 22, 28), Enum.Material.SmoothPlastic, true, true)
    -- Glass front wall
    local glassWall = MapService.CreatePart(lobby, "WallFrontGlass", Vector3.new(50, 16, 1), CFrame.new(0, 60, -55), Color3.fromRGB(180, 220, 255), Enum.Material.Glass, true, true)
    glassWall.Transparency = 0.7

    -- Lobby Spawn
    local lobbySpawn = Instance.new("SpawnLocation")
    lobbySpawn.Name = "LobbySpawn"
    lobbySpawn.Size = Vector3.new(12, 1, 12)
    lobbySpawn.CFrame = CFrame.new(0, 52.5, -80)
    lobbySpawn.Color = Color3.fromRGB(0, 170, 255)
    lobbySpawn.Material = Enum.Material.Neon
    lobbySpawn.Anchored = true
    lobbySpawn.CanCollide = true
    lobbySpawn.Neutral = true
    lobbySpawn.Parent = lobby

    -- ==================== 2. RUNNER START ====================
    local runnerStart = Instance.new("Folder")
    runnerStart.Name = "RunnerStart"
    runnerStart.Parent = map

    MapService.CreatePart(runnerStart, "Floor", Vector3.new(30, 4, 30), CFrame.new(0, 10, 10), Color3.fromRGB(45, 50, 60), Enum.Material.DiamondPlate, true, true)

    local runnerSpawn = Instance.new("SpawnLocation")
    runnerSpawn.Name = "RunnerSpawn"
    runnerSpawn.Size = Vector3.new(10, 1, 10)
    runnerSpawn.CFrame = CFrame.new(0, 12.5, 10)
    runnerSpawn.Color = Color3.fromRGB(80, 255, 120)
    runnerSpawn.Material = Enum.Material.Neon
    runnerSpawn.Anchored = true
    runnerSpawn.CanCollide = true
    runnerSpawn.Enabled = false
    runnerSpawn.Parent = runnerStart

    -- Barrier gate that drops on round start
    local barrier = MapService.CreatePart(runnerStart, "Barrier", Vector3.new(30, 12, 2), CFrame.new(0, 18, 25), Color3.fromRGB(255, 50, 50), Enum.Material.ForceField, true, true)
    barrier.Transparency = 0.4

    -- ==================== 3. TRAP CONTROLLER WALKWAY ====================
    -- Elevated parallel catwalk running along the entire course with glass observation windows
    local controllerArea = Instance.new("Folder")
    controllerArea.Name = "TrapControllerArea"
    controllerArea.Parent = map

    -- Walkway floor (X = 38, Y = 25, Z = 20 to 480)
    MapService.CreatePart(controllerArea, "WalkwayFloor", Vector3.new(16, 2, 480), CFrame.new(38, 25, 250), Color3.fromRGB(35, 40, 50), Enum.Material.Metal, true, true)
    -- Glass railing facing runner course
    local railing = MapService.CreatePart(controllerArea, "GlassRailing", Vector3.new(1, 10, 480), CFrame.new(30, 31, 250), Color3.fromRGB(150, 220, 255), Enum.Material.Glass, true, true)
    railing.Transparency = 0.75
    -- Back wall
    MapService.CreatePart(controllerArea, "BackWall", Vector3.new(1, 14, 480), CFrame.new(46, 33, 250), Color3.fromRGB(20, 25, 30), Enum.Material.SmoothPlastic, true, true)

    -- Controller Spawn
    local controllerSpawn = Instance.new("SpawnLocation")
    controllerSpawn.Name = "ControllerSpawn"
    controllerSpawn.Size = Vector3.new(8, 1, 8)
    controllerSpawn.CFrame = CFrame.new(38, 26.5, 25)
    controllerSpawn.Color = Color3.fromRGB(255, 60, 60)
    controllerSpawn.Material = Enum.Material.Neon
    controllerSpawn.Anchored = true
    controllerSpawn.CanCollide = true
    controllerSpawn.Enabled = false
    controllerSpawn.Parent = controllerArea

    -- ==================== 4. TRAPS & COURSE SECTIONS ====================
    local trapsFolder = Instance.new("Folder")
    trapsFolder.Name = "Traps"
    trapsFolder.Parent = map

    local courseFolder = Instance.new("Folder")
    courseFolder.Name = "RunnerCourse"
    courseFolder.Parent = map

    -- Pre-Trap 1: Jumps
    MapService.CreatePart(courseFolder, "JumpPad1", Vector3.new(8, 2, 8), CFrame.new(-4, 10, 38), Color3.fromRGB(50, 55, 65), Enum.Material.DiamondPlate, true, true)
    MapService.CreatePart(courseFolder, "JumpPad2", Vector3.new(8, 2, 8), CFrame.new(4, 10, 50), Color3.fromRGB(50, 55, 65), Enum.Material.DiamondPlate, true, true)

    -- ---------- TRAP 1: COLLAPSING BRIDGE (Z = 65) ----------
    local bridgeModel = Instance.new("Model")
    bridgeModel.Name = "CollapsingBridge"
    bridgeModel.Parent = trapsFolder

    local pillars = Instance.new("Folder")
    pillars.Name = "WarningPillars"
    pillars.Parent = bridgeModel
    MapService.CreatePart(pillars, "PillarLeft", Vector3.new(3, 12, 3), CFrame.new(-10, 16, 65), Color3.fromRGB(60, 60, 60), Enum.Material.SmoothPlastic, true, true)
    MapService.CreatePart(pillars, "PillarRight", Vector3.new(3, 12, 3), CFrame.new(10, 16, 65), Color3.fromRGB(60, 60, 60), Enum.Material.SmoothPlastic, true, true)

    local planks = Instance.new("Folder")
    planks.Name = "Planks"
    planks.Parent = bridgeModel
    MapService.CreatePart(planks, "Plank1", Vector3.new(14, 2, 8), CFrame.new(0, 10, 60), Color3.fromRGB(80, 85, 95), Enum.Material.DiamondPlate, true, true)
    MapService.CreatePart(planks, "Plank2", Vector3.new(14, 2, 8), CFrame.new(0, 10, 70), Color3.fromRGB(80, 85, 95), Enum.Material.DiamondPlate, true, true)
    MapService.CreatePart(planks, "Plank3", Vector3.new(14, 2, 8), CFrame.new(0, 10, 80), Color3.fromRGB(80, 85, 95), Enum.Material.DiamondPlate, true, true)

    -- CHECKPOINT 1 ISLAND (Z = 100)
    local cp1 = Instance.new("Model")
    cp1.Name = "Checkpoint1"
    cp1.Parent = map
    MapService.CreatePart(cp1, "Island", Vector3.new(20, 4, 16), CFrame.new(0, 10, 100), Color3.fromRGB(40, 45, 55), Enum.Material.Metal, true, true)
    local pad1 = MapService.CreatePart(cp1, "Pad", Vector3.new(10, 1, 10), CFrame.new(0, 12.5, 100), Color3.fromRGB(0, 200, 100), Enum.Material.Neon, true, true)
    pad1:SetAttribute("CheckpointIndex", 1)

    -- Course Catwalk to Trap 2
    MapService.CreatePart(courseFolder, "NarrowBeam", Vector3.new(6, 2, 24), CFrame.new(0, 10, 120), Color3.fromRGB(50, 55, 65), Enum.Material.DiamondPlate, true, true)

    -- ---------- TRAP 2: SWINGING HAMMER (Z = 140) ----------
    local hammerModel = Instance.new("Model")
    hammerModel.Name = "SwingingHammer"
    hammerModel.Parent = trapsFolder

    local arch = Instance.new("Folder")
    arch.Name = "Arch"
    arch.Parent = hammerModel
    MapService.CreatePart(arch, "LegL", Vector3.new(3, 26, 3), CFrame.new(-12, 23, 140), Color3.fromRGB(50, 50, 55), Enum.Material.Metal, true, true)
    MapService.CreatePart(arch, "LegR", Vector3.new(3, 26, 3), CFrame.new(12, 23, 140), Color3.fromRGB(50, 50, 55), Enum.Material.Metal, true, true)
    MapService.CreatePart(arch, "TopCross", Vector3.new(27, 3, 3), CFrame.new(0, 36, 140), Color3.fromRGB(50, 50, 55), Enum.Material.Metal, true, true)
    local beaconH = MapService.CreatePart(arch, "BeaconHammer", Vector3.new(2, 2, 2), CFrame.new(0, 38, 140), Color3.fromRGB(255, 170, 0), Enum.Material.Neon, true, true)

    local pivot = MapService.CreatePart(hammerModel, "Pivot", Vector3.new(2, 2, 2), CFrame.new(0, 35, 140), Color3.fromRGB(80, 80, 80), Enum.Material.Metal, true, false)
    pivot.Transparency = 1

    local hammerObj = Instance.new("Model")
    hammerObj.Name = "Hammer"
    hammerObj.Parent = hammerModel
    local pole = MapService.CreatePart(hammerObj, "Pole", Vector3.new(2, 20, 2), CFrame.new(0, 24, 140), Color3.fromRGB(70, 70, 75), Enum.Material.Metal, true, false)
    local head = MapService.CreatePart(hammerObj, "Head", Vector3.new(10, 5, 5), CFrame.new(0, 14, 140), Color3.fromRGB(240, 60, 60), Enum.Material.DiamondPlate, true, true)
    hammerObj.PrimaryPart = pole

    MapService.CreatePart(courseFolder, "HammerWalkway", Vector3.new(8, 2, 30), CFrame.new(0, 10, 140), Color3.fromRGB(50, 55, 65), Enum.Material.DiamondPlate, true, true)

    -- CHECKPOINT 2 ISLAND (Z = 180)
    local cp2 = Instance.new("Model")
    cp2.Name = "Checkpoint2"
    cp2.Parent = map
    MapService.CreatePart(cp2, "Island", Vector3.new(20, 4, 16), CFrame.new(0, 10, 180), Color3.fromRGB(40, 45, 55), Enum.Material.Metal, true, true)
    local pad2 = MapService.CreatePart(cp2, "Pad", Vector3.new(10, 1, 10), CFrame.new(0, 12.5, 180), Color3.fromRGB(0, 200, 100), Enum.Material.Neon, true, true)
    pad2:SetAttribute("CheckpointIndex", 2)

    -- ---------- TRAP 3: FALLING CEILING (Z = 225) ----------
    local ceilingModel = Instance.new("Model")
    ceilingModel.Name = "FallingCeiling"
    ceilingModel.Parent = trapsFolder

    -- Tunnel enclosure
    MapService.CreatePart(ceilingModel, "TunnelFloor", Vector3.new(14, 2, 40), CFrame.new(0, 10, 225), Color3.fromRGB(40, 40, 45), Enum.Material.DiamondPlate, true, true)
    MapService.CreatePart(ceilingModel, "TunnelWallL", Vector3.new(2, 20, 40), CFrame.new(-8, 20, 225), Color3.fromRGB(30, 30, 35), Enum.Material.Metal, true, true)
    MapService.CreatePart(ceilingModel, "TunnelWallR", Vector3.new(2, 20, 40), CFrame.new(8, 20, 225), Color3.fromRGB(30, 30, 35), Enum.Material.Metal, true, true)
    MapService.CreatePart(ceilingModel, "TunnelRoof", Vector3.new(18, 2, 40), CFrame.new(0, 31, 225), Color3.fromRGB(30, 30, 35), Enum.Material.Metal, true, true)

    local warningLights = Instance.new("Folder")
    warningLights.Name = "WarningLights"
    warningLights.Parent = ceilingModel
    MapService.CreatePart(warningLights, "Light1", Vector3.new(14, 1, 1), CFrame.new(0, 30, 210), Color3.fromRGB(50, 50, 50), Enum.Material.SmoothPlastic, true, false)
    MapService.CreatePart(warningLights, "Light2", Vector3.new(14, 1, 1), CFrame.new(0, 30, 240), Color3.fromRGB(50, 50, 50), Enum.Material.SmoothPlastic, true, false)

    -- Crusher slab suspended at ceiling Y = 28
    MapService.CreatePart(ceilingModel, "Crusher", Vector3.new(12, 3, 34), CFrame.new(0, 28, 225), Color3.fromRGB(220, 40, 40), Enum.Material.DiamondPlate, true, true)

    -- Course Catwalk to Trap 4
    MapService.CreatePart(courseFolder, "CatwalkMid", Vector3.new(10, 2, 24), CFrame.new(0, 10, 262), Color3.fromRGB(50, 55, 65), Enum.Material.Metal, true, true)

    -- ---------- TRAP 4: MOVING WALL (Z = 290) ----------
    local wallModel = Instance.new("Model")
    wallModel.Name = "MovingWall"
    wallModel.Parent = trapsFolder

    MapService.CreatePart(wallModel, "Walkway", Vector3.new(12, 2, 26), CFrame.new(0, 10, 290), Color3.fromRGB(50, 55, 65), Enum.Material.DiamondPlate, true, true)
    MapService.CreatePart(wallModel, "SideHousing", Vector3.new(4, 16, 26), CFrame.new(-14, 18, 290), Color3.fromRGB(35, 40, 45), Enum.Material.Metal, true, true)
    local sign = MapService.CreatePart(wallModel, "WarningSign", Vector3.new(1, 4, 12), CFrame.new(-11.9, 18, 290), Color3.fromRGB(50, 50, 50), Enum.Material.SmoothPlastic, true, false)

    -- Battering pusher wall recessed at X = -11
    MapService.CreatePart(wallModel, "Pusher", Vector3.new(4, 10, 22), CFrame.new(-11, 16, 290), Color3.fromRGB(0, 170, 255), Enum.Material.Metal, true, true)

    -- CHECKPOINT 3 ISLAND (Z = 330)
    local cp3 = Instance.new("Model")
    cp3.Name = "Checkpoint3"
    cp3.Parent = map
    MapService.CreatePart(cp3, "Island", Vector3.new(20, 4, 16), CFrame.new(0, 10, 330), Color3.fromRGB(40, 45, 55), Enum.Material.Metal, true, true)
    local pad3 = MapService.CreatePart(cp3, "Pad", Vector3.new(10, 1, 10), CFrame.new(0, 12.5, 330), Color3.fromRGB(0, 200, 100), Enum.Material.Neon, true, true)
    pad3:SetAttribute("CheckpointIndex", 3)

    -- Island Hops to Trap 5
    MapService.CreatePart(courseFolder, "Hop1", Vector3.new(6, 2, 6), CFrame.new(-3, 10, 348), Color3.fromRGB(50, 55, 65), Enum.Material.DiamondPlate, true, true)
    MapService.CreatePart(courseFolder, "Hop2", Vector3.new(6, 2, 6), CFrame.new(3, 10, 360), Color3.fromRGB(50, 55, 65), Enum.Material.DiamondPlate, true, true)

    -- ---------- TRAP 5: ROTATING PLATFORM (Z = 375) ----------
    local rotModel = Instance.new("Model")
    rotModel.Name = "RotatingPlatform"
    rotModel.Parent = trapsFolder

    local spinPad = MapService.CreatePart(rotModel, "SpinPlatform", Vector3.new(16, 2, 16), CFrame.new(0, 10, 375), Color3.fromRGB(150, 60, 220), Enum.Material.DiamondPlate, true, true)

    local beacons = Instance.new("Folder")
    beacons.Name = "Beacons"
    beacons.Parent = rotModel
    MapService.CreatePart(beacons, "B1", Vector3.new(2, 4, 2), CFrame.new(-10, 12, 375), Color3.fromRGB(50, 50, 50), Enum.Material.SmoothPlastic, true, true)
    MapService.CreatePart(beacons, "B2", Vector3.new(2, 4, 2), CFrame.new(10, 12, 375), Color3.fromRGB(50, 50, 50), Enum.Material.SmoothPlastic, true, true)

    -- Runway to Trap 6
    MapService.CreatePart(courseFolder, "FinalRunway", Vector3.new(12, 2, 30), CFrame.new(0, 10, 405), Color3.fromRGB(45, 50, 60), Enum.Material.Metal, true, true)

    -- ---------- TRAP 6: PITFALL (Z = 445) ----------
    local pitModel = Instance.new("Model")
    pitModel.Name = "Pitfall"
    pitModel.Parent = trapsFolder

    MapService.CreatePart(pitModel, "PitFrameL", Vector3.new(2, 2, 32), CFrame.new(-7, 10, 445), Color3.fromRGB(30, 35, 40), Enum.Material.Metal, true, true)
    MapService.CreatePart(pitModel, "PitFrameR", Vector3.new(2, 2, 32), CFrame.new(7, 10, 445), Color3.fromRGB(30, 35, 40), Enum.Material.Metal, true, true)

    local warningFrame = Instance.new("Folder")
    warningFrame.Name = "WarningFrame"
    warningFrame.Parent = pitModel
    MapService.CreatePart(warningFrame, "EdgeL", Vector3.new(1, 1, 32), CFrame.new(-6.5, 11.2, 445), Color3.fromRGB(50, 50, 50), Enum.Material.SmoothPlastic, true, false)
    MapService.CreatePart(warningFrame, "EdgeR", Vector3.new(1, 1, 32), CFrame.new(6.5, 11.2, 445), Color3.fromRGB(50, 50, 50), Enum.Material.SmoothPlastic, true, false)

    -- Dual trapdoors
    MapService.CreatePart(pitModel, "HatchLeft", Vector3.new(6, 2, 30), CFrame.new(-3, 10, 445), Color3.fromRGB(70, 75, 85), Enum.Material.DiamondPlate, true, true)
    MapService.CreatePart(pitModel, "HatchRight", Vector3.new(6, 2, 30), CFrame.new(3, 10, 445), Color3.fromRGB(70, 75, 85), Enum.Material.DiamondPlate, true, true)

    -- ==================== 5. FINISH PLATFORM (Z = 490) ====================
    local finish = Instance.new("Model")
    finish.Name = "Finish"
    finish.Parent = map

    MapService.CreatePart(finish, "Floor", Vector3.new(30, 4, 30), CFrame.new(0, 10, 490), Color3.fromRGB(40, 50, 60), Enum.Material.DiamondPlate, true, true)

    -- Golden victory arch
    MapService.CreatePart(finish, "ArchL", Vector3.new(3, 16, 3), CFrame.new(-12, 20, 485), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, true, true)
    MapService.CreatePart(finish, "ArchR", Vector3.new(3, 16, 3), CFrame.new(12, 20, 485), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, true, true)
    MapService.CreatePart(finish, "ArchTop", Vector3.new(27, 3, 3), CFrame.new(0, 28, 485), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, true, true)

    -- Finish Pad
    local finishPad = MapService.CreatePart(finish, "FinishPad", Vector3.new(14, 1, 14), CFrame.new(0, 12.5, 490), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, true, true)

    -- ==================== 6. PHYSICAL CONTROLLER BUTTONS ====================
    -- Place physical 3D console buttons on the controller walkway overlooking each trap
    local trapZPositions = {
        CollapsingBridge = 65,
        SwingingHammer = 140,
        FallingCeiling = 225,
        MovingWall = 290,
        RotatingPlatform = 375,
        Pitfall = 445,
    }

    for trapId, zPos in pairs(trapZPositions) do
        local console = Instance.new("Model")
        console.Name = "Console_" .. trapId
        console.Parent = controllerArea

        -- Console pedestal
        MapService.CreatePart(console, "Stand", Vector3.new(2, 4, 3), CFrame.new(32, 28, zPos), Color3.fromRGB(30, 30, 35), Enum.Material.Metal, true, true)
        -- Red activation button
        local button = MapService.CreatePart(console, "Button", Vector3.new(1.2, 0.6, 1.2), CFrame.new(32, 30.3, zPos), Color3.fromRGB(255, 30, 30), Enum.Material.Neon, true, true)
        button:SetAttribute("TrapId", trapId)

        local clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 14
        clickDetector.Parent = button

        clickDetector.MouseClick:Connect(function(player: Player)
            if TrapService then
                TrapService.RequestTrapActivation(player, trapId)
            end
        end)
    end

    -- ==================== 7. KILLZONE ====================
    local killZone = Instance.new("Part")
    killZone.Name = "KillZone"
    killZone.Size = Vector3.new(1000, 4, 1000)
    killZone.CFrame = CFrame.new(0, GameConfig.Coordinates.KillZoneY, 200)
    killZone.Color = Color3.fromRGB(255, 0, 0)
    killZone.Material = Enum.Material.Neon
    killZone.Transparency = 0.5
    killZone.Anchored = true
    killZone.CanCollide = false
    killZone.Parent = map

    return map
end

function MapService.WireMapTriggers(map: Folder)
    -- Wire Checkpoint pads
    for i = 1, 3 do
        local cpModel = map:FindFirstChild("Checkpoint" .. i)
        local pad = cpModel and cpModel:FindFirstChild("Pad") :: BasePart?
        if pad then
            pad.Touched:Connect(function(hit)
                local char = hit.Parent
                local player = char and Players:GetPlayerFromCharacter(char)
                if player and CheckpointService then
                    CheckpointService.OnCheckpointTouched(player, i, pad)
                end
            end)
        end
    end

    -- Wire Finish Pad
    local finish = map:FindFirstChild("Finish")
    local finishPad = finish and finish:FindFirstChild("FinishPad") :: BasePart?
    if finishPad then
        finishPad.Touched:Connect(function(hit)
            local char = hit.Parent
            local player = char and Players:GetPlayerFromCharacter(char)
            if player and RoundService then
                RoundService.OnRunnerFinished(player)
            end
        end)
    end

    -- Wire KillZone
    local killZone = map:FindFirstChild("KillZone") :: BasePart?
    if killZone then
        killZone.Touched:Connect(function(hit)
            local char = hit.Parent
            local hum = char and char:FindFirstChild("Humanoid") :: Humanoid?
            if hum and hum.Health > 0 then
                hum:TakeDamage(1000)
            end
        end)
    end

    -- Register traps for reset tracking
    local trapsFolder = map:FindFirstChild("Traps")
    if trapsFolder and TrapService then
        for _, trapModel in ipairs(trapsFolder:GetChildren()) do
            if trapModel:IsA("Model") then
                TrapService.RegisterTrapParts(trapModel.Name, trapModel)
            end
        end
    end
end

return MapService
