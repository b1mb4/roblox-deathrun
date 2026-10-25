--!strict
--[[
    build_full_place.luau
    Builds the complete Roblox Deathrun experience into:
    - Deathrun.rbxlx (Roblox XML place file)
    - Deathrun.rbxl (Roblox binary place file)
    Populates all 3D instances into Workspace.Map with CS2/industrial aesthetic.
]]

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

print("[Builder] Deserializing Rojo base place...")
local xml = fs.readFile("Deathrun.rbxlx")
local place = roblox.deserializePlace(xml)

local ws = place:GetService("Workspace")
local lighting = place:GetService("Lighting")

-- 1. Configure Lighting for dramatic tactical Deathrun atmosphere
lighting.ClockTime = 19.5 -- Dusk/night tactical lighting
lighting.Brightness = 1.8
lighting.OutdoorAmbient = roblox.Color3.fromRGB(45, 50, 65)
lighting.Ambient = roblox.Color3.fromRGB(35, 40, 50)
lighting.FogColor = roblox.Color3.fromRGB(20, 22, 30)
lighting.FogStart = 100
lighting.FogEnd = 700

local function createPart(parent: any, name: string, size: any, cframe: any, color: any, material: any, anchored: boolean, canCollide: boolean)
    local p = roblox.Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cframe
    p.Color = color
    p.Material = material
    p.Anchored = anchored ~= nil and anchored or true
    p.CanCollide = canCollide ~= nil and canCollide or true
    p.TopSurface = roblox.Enum.SurfaceType.Smooth
    p.BottomSurface = roblox.Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

-- Remove any old Map folder in Workspace
local existingMap = ws:FindFirstChild("Map")
if existingMap then
    existingMap:Destroy()
end

local map = roblox.Instance.new("Folder")
map.Name = "Map"
map.Parent = ws

print("[Builder] Constructing Lobby...")
-- ==================== 1. LOBBY ====================
local lobby = roblox.Instance.new("Folder")
lobby.Name = "Lobby"
lobby.Parent = map

createPart(lobby, "Floor", roblox.Vector3.new(50, 4, 50), roblox.CFrame.new(0, 50, -80), roblox.Color3.fromRGB(30, 32, 40), roblox.Enum.Material.Metal, true, true)
createPart(lobby, "WallBack", roblox.Vector3.new(50, 16, 2), roblox.CFrame.new(0, 60, -105), roblox.Color3.fromRGB(20, 22, 28), roblox.Enum.Material.SmoothPlastic, true, true)
createPart(lobby, "WallLeft", roblox.Vector3.new(2, 16, 50), roblox.CFrame.new(-25, 60, -80), roblox.Color3.fromRGB(20, 22, 28), roblox.Enum.Material.SmoothPlastic, true, true)
createPart(lobby, "WallRight", roblox.Vector3.new(2, 16, 50), roblox.CFrame.new(25, 60, -80), roblox.Color3.fromRGB(20, 22, 28), roblox.Enum.Material.SmoothPlastic, true, true)
local glassWall = createPart(lobby, "WallFrontGlass", roblox.Vector3.new(50, 16, 1), roblox.CFrame.new(0, 60, -55), roblox.Color3.fromRGB(180, 220, 255), roblox.Enum.Material.Glass, true, true)
glassWall.Transparency = 0.7

local lobbySpawn = roblox.Instance.new("SpawnLocation")
lobbySpawn.Name = "LobbySpawn"
lobbySpawn.Size = roblox.Vector3.new(12, 1, 12)
lobbySpawn.CFrame = roblox.CFrame.new(0, 52.5, -80)
lobbySpawn.Color = roblox.Color3.fromRGB(0, 170, 255)
lobbySpawn.Material = roblox.Enum.Material.Neon
lobbySpawn.Anchored = true
lobbySpawn.CanCollide = true
lobbySpawn.Neutral = true
lobbySpawn.Parent = lobby

print("[Builder] Constructing Runner Starting Platform...")
-- ==================== 2. RUNNER START ====================
local runnerStart = roblox.Instance.new("Folder")
runnerStart.Name = "RunnerStart"
runnerStart.Parent = map

createPart(runnerStart, "Floor", roblox.Vector3.new(30, 4, 30), roblox.CFrame.new(0, 10, 10), roblox.Color3.fromRGB(45, 50, 60), roblox.Enum.Material.DiamondPlate, true, true)

local runnerSpawn = roblox.Instance.new("SpawnLocation")
runnerSpawn.Name = "RunnerSpawn"
runnerSpawn.Size = roblox.Vector3.new(10, 1, 10)
runnerSpawn.CFrame = roblox.CFrame.new(0, 12.5, 10)
runnerSpawn.Color = roblox.Color3.fromRGB(80, 255, 120)
runnerSpawn.Material = roblox.Enum.Material.Neon
runnerSpawn.Anchored = true
runnerSpawn.CanCollide = true
runnerSpawn.Enabled = false
runnerSpawn.Parent = runnerStart

local barrier = createPart(runnerStart, "Barrier", roblox.Vector3.new(30, 12, 2), roblox.CFrame.new(0, 18, 25), roblox.Color3.fromRGB(255, 50, 50), roblox.Enum.Material.ForceField, true, true)
barrier.Transparency = 0.4

print("[Builder] Constructing Trap Controller Catwalk...")
-- ==================== 3. TRAP CONTROLLER CATWALK ====================
local controllerArea = roblox.Instance.new("Folder")
controllerArea.Name = "TrapControllerArea"
controllerArea.Parent = map

createPart(controllerArea, "WalkwayFloor", roblox.Vector3.new(16, 2, 480), roblox.CFrame.new(38, 25, 250), roblox.Color3.fromRGB(35, 40, 50), roblox.Enum.Material.Metal, true, true)
local railing = createPart(controllerArea, "GlassRailing", roblox.Vector3.new(1, 10, 480), roblox.CFrame.new(30, 31, 250), roblox.Color3.fromRGB(150, 220, 255), roblox.Enum.Material.Glass, true, true)
railing.Transparency = 0.75
createPart(controllerArea, "BackWall", roblox.Vector3.new(1, 14, 480), roblox.CFrame.new(46, 33, 250), roblox.Color3.fromRGB(20, 25, 30), roblox.Enum.Material.SmoothPlastic, true, true)

local controllerSpawn = roblox.Instance.new("SpawnLocation")
controllerSpawn.Name = "ControllerSpawn"
controllerSpawn.Size = roblox.Vector3.new(8, 1, 8)
controllerSpawn.CFrame = roblox.CFrame.new(38, 26.5, 25)
controllerSpawn.Color = roblox.Color3.fromRGB(255, 60, 60)
controllerSpawn.Material = roblox.Enum.Material.Neon
controllerSpawn.Anchored = true
controllerSpawn.CanCollide = true
controllerSpawn.Enabled = false
controllerSpawn.Parent = controllerArea

print("[Builder] Constructing Course and Traps...")
-- ==================== 4. COURSE AND TRAPS ====================
local trapsFolder = roblox.Instance.new("Folder")
trapsFolder.Name = "Traps"
trapsFolder.Parent = map

local courseFolder = roblox.Instance.new("Folder")
courseFolder.Name = "RunnerCourse"
courseFolder.Parent = map

-- Jump pads to Trap 1
createPart(courseFolder, "JumpPad1", roblox.Vector3.new(8, 2, 8), roblox.CFrame.new(-4, 10, 38), roblox.Color3.fromRGB(50, 55, 65), roblox.Enum.Material.DiamondPlate, true, true)
createPart(courseFolder, "JumpPad2", roblox.Vector3.new(8, 2, 8), roblox.CFrame.new(4, 10, 50), roblox.Color3.fromRGB(50, 55, 65), roblox.Enum.Material.DiamondPlate, true, true)

-- TRAP 1: COLLAPSING BRIDGE
local bridgeModel = roblox.Instance.new("Model")
bridgeModel.Name = "CollapsingBridge"
bridgeModel.Parent = trapsFolder

local pillars = roblox.Instance.new("Folder")
pillars.Name = "WarningPillars"
pillars.Parent = bridgeModel
createPart(pillars, "PillarLeft", roblox.Vector3.new(3, 12, 3), roblox.CFrame.new(-10, 16, 65), roblox.Color3.fromRGB(60, 60, 60), roblox.Enum.Material.SmoothPlastic, true, true)
createPart(pillars, "PillarRight", roblox.Vector3.new(3, 12, 3), roblox.CFrame.new(10, 16, 65), roblox.Color3.fromRGB(60, 60, 60), roblox.Enum.Material.SmoothPlastic, true, true)

local planks = roblox.Instance.new("Folder")
planks.Name = "Planks"
planks.Parent = bridgeModel
createPart(planks, "Plank1", roblox.Vector3.new(14, 2, 8), roblox.CFrame.new(0, 10, 60), roblox.Color3.fromRGB(80, 85, 95), roblox.Enum.Material.DiamondPlate, true, true)
createPart(planks, "Plank2", roblox.Vector3.new(14, 2, 8), roblox.CFrame.new(0, 10, 70), roblox.Color3.fromRGB(80, 85, 95), roblox.Enum.Material.DiamondPlate, true, true)
createPart(planks, "Plank3", roblox.Vector3.new(14, 2, 8), roblox.CFrame.new(0, 10, 80), roblox.Color3.fromRGB(80, 85, 95), roblox.Enum.Material.DiamondPlate, true, true)

-- CHECKPOINT 1 (Z = 100)
local cp1 = roblox.Instance.new("Model")
cp1.Name = "Checkpoint1"
cp1.Parent = map
createPart(cp1, "Island", roblox.Vector3.new(20, 4, 16), roblox.CFrame.new(0, 10, 100), roblox.Color3.fromRGB(40, 45, 55), roblox.Enum.Material.Metal, true, true)
createPart(cp1, "Pad", roblox.Vector3.new(10, 1, 10), roblox.CFrame.new(0, 12.5, 100), roblox.Color3.fromRGB(0, 200, 100), roblox.Enum.Material.Neon, true, true)

-- Narrow Beam
createPart(courseFolder, "NarrowBeam", roblox.Vector3.new(6, 2, 24), roblox.CFrame.new(0, 10, 120), roblox.Color3.fromRGB(50, 55, 65), roblox.Enum.Material.DiamondPlate, true, true)

-- TRAP 2: SWINGING HAMMER
local hammerModel = roblox.Instance.new("Model")
hammerModel.Name = "SwingingHammer"
hammerModel.Parent = trapsFolder

local arch = roblox.Instance.new("Folder")
arch.Name = "Arch"
arch.Parent = hammerModel
createPart(arch, "LegL", roblox.Vector3.new(3, 26, 3), roblox.CFrame.new(-12, 23, 140), roblox.Color3.fromRGB(50, 50, 55), roblox.Enum.Material.Metal, true, true)
createPart(arch, "LegR", roblox.Vector3.new(3, 26, 3), roblox.CFrame.new(12, 23, 140), roblox.Color3.fromRGB(50, 50, 55), roblox.Enum.Material.Metal, true, true)
createPart(arch, "TopCross", roblox.Vector3.new(27, 3, 3), roblox.CFrame.new(0, 36, 140), roblox.Color3.fromRGB(50, 50, 55), roblox.Enum.Material.Metal, true, true)
createPart(arch, "BeaconHammer", roblox.Vector3.new(2, 2, 2), roblox.CFrame.new(0, 38, 140), roblox.Color3.fromRGB(255, 170, 0), roblox.Enum.Material.Neon, true, true)

local pivot = createPart(hammerModel, "Pivot", roblox.Vector3.new(2, 2, 2), roblox.CFrame.new(0, 35, 140), roblox.Color3.fromRGB(80, 80, 80), roblox.Enum.Material.Metal, true, false)
pivot.Transparency = 1

local hammerObj = roblox.Instance.new("Model")
hammerObj.Name = "Hammer"
hammerObj.Parent = hammerModel
local pole = createPart(hammerObj, "Pole", roblox.Vector3.new(2, 20, 2), roblox.CFrame.new(0, 24, 140), roblox.Color3.fromRGB(70, 70, 75), roblox.Enum.Material.Metal, true, false)
createPart(hammerObj, "Head", roblox.Vector3.new(10, 5, 5), roblox.CFrame.new(0, 14, 140), roblox.Color3.fromRGB(240, 60, 60), roblox.Enum.Material.DiamondPlate, true, true)
hammerObj.PrimaryPart = pole

createPart(courseFolder, "HammerWalkway", roblox.Vector3.new(8, 2, 30), roblox.CFrame.new(0, 10, 140), roblox.Color3.fromRGB(50, 55, 65), roblox.Enum.Material.DiamondPlate, true, true)

-- CHECKPOINT 2 (Z = 180)
local cp2 = roblox.Instance.new("Model")
cp2.Name = "Checkpoint2"
cp2.Parent = map
createPart(cp2, "Island", roblox.Vector3.new(20, 4, 16), roblox.CFrame.new(0, 10, 180), roblox.Color3.fromRGB(40, 45, 55), roblox.Enum.Material.Metal, true, true)
createPart(cp2, "Pad", roblox.Vector3.new(10, 1, 10), roblox.CFrame.new(0, 12.5, 180), roblox.Color3.fromRGB(0, 200, 100), roblox.Enum.Material.Neon, true, true)

-- TRAP 3: FALLING CEILING
local ceilingModel = roblox.Instance.new("Model")
ceilingModel.Name = "FallingCeiling"
ceilingModel.Parent = trapsFolder

createPart(ceilingModel, "TunnelFloor", roblox.Vector3.new(14, 2, 40), roblox.CFrame.new(0, 10, 225), roblox.Color3.fromRGB(40, 40, 45), roblox.Enum.Material.DiamondPlate, true, true)
createPart(ceilingModel, "TunnelWallL", roblox.Vector3.new(2, 20, 40), roblox.CFrame.new(-8, 20, 225), roblox.Color3.fromRGB(30, 30, 35), roblox.Enum.Material.Metal, true, true)
createPart(ceilingModel, "TunnelWallR", roblox.Vector3.new(2, 20, 40), roblox.CFrame.new(8, 20, 225), roblox.Color3.fromRGB(30, 30, 35), roblox.Enum.Material.Metal, true, true)
createPart(ceilingModel, "TunnelRoof", roblox.Vector3.new(18, 2, 40), roblox.CFrame.new(0, 31, 225), roblox.Color3.fromRGB(30, 30, 35), roblox.Enum.Material.Metal, true, true)

local warningLights = roblox.Instance.new("Folder")
warningLights.Name = "WarningLights"
warningLights.Parent = ceilingModel
createPart(warningLights, "Light1", roblox.Vector3.new(14, 1, 1), roblox.CFrame.new(0, 30, 210), roblox.Color3.fromRGB(50, 50, 50), roblox.Enum.Material.SmoothPlastic, true, false)
createPart(warningLights, "Light2", roblox.Vector3.new(14, 1, 1), roblox.CFrame.new(0, 30, 240), roblox.Color3.fromRGB(50, 50, 50), roblox.Enum.Material.SmoothPlastic, true, false)
createPart(ceilingModel, "Crusher", roblox.Vector3.new(12, 3, 34), roblox.CFrame.new(0, 28, 225), roblox.Color3.fromRGB(220, 40, 40), roblox.Enum.Material.DiamondPlate, true, true)

createPart(courseFolder, "CatwalkMid", roblox.Vector3.new(10, 2, 24), roblox.CFrame.new(0, 10, 262), roblox.Color3.fromRGB(50, 55, 65), roblox.Enum.Material.Metal, true, true)

-- TRAP 4: MOVING WALL
local wallModel = roblox.Instance.new("Model")
wallModel.Name = "MovingWall"
wallModel.Parent = trapsFolder

createPart(wallModel, "Walkway", roblox.Vector3.new(12, 2, 26), roblox.CFrame.new(0, 10, 290), roblox.Color3.fromRGB(50, 55, 65), roblox.Enum.Material.DiamondPlate, true, true)
createPart(wallModel, "SideHousing", roblox.Vector3.new(4, 16, 26), roblox.CFrame.new(-14, 18, 290), roblox.Color3.fromRGB(35, 40, 45), roblox.Enum.Material.Metal, true, true)
createPart(wallModel, "WarningSign", roblox.Vector3.new(1, 4, 12), roblox.CFrame.new(-11.9, 18, 290), roblox.Color3.fromRGB(50, 50, 50), roblox.Enum.Material.SmoothPlastic, true, false)
createPart(wallModel, "Pusher", roblox.Vector3.new(4, 10, 22), roblox.CFrame.new(-11, 16, 290), roblox.Color3.fromRGB(0, 170, 255), roblox.Enum.Material.Metal, true, true)

-- CHECKPOINT 3 (Z = 330)
local cp3 = roblox.Instance.new("Model")
cp3.Name = "Checkpoint3"
cp3.Parent = map
createPart(cp3, "Island", roblox.Vector3.new(20, 4, 16), roblox.CFrame.new(0, 10, 330), roblox.Color3.fromRGB(40, 45, 55), roblox.Enum.Material.Metal, true, true)
createPart(cp3, "Pad", roblox.Vector3.new(10, 1, 10), roblox.CFrame.new(0, 12.5, 330), roblox.Color3.fromRGB(0, 200, 100), roblox.Enum.Material.Neon, true, true)

-- Island Hops
createPart(courseFolder, "Hop1", roblox.Vector3.new(6, 2, 6), roblox.CFrame.new(-3, 10, 348), roblox.Color3.fromRGB(50, 55, 65), roblox.Enum.Material.DiamondPlate, true, true)
createPart(courseFolder, "Hop2", roblox.Vector3.new(6, 2, 6), roblox.CFrame.new(3, 10, 360), roblox.Color3.fromRGB(50, 55, 65), roblox.Enum.Material.DiamondPlate, true, true)

-- TRAP 5: ROTATING PLATFORM
local rotModel = roblox.Instance.new("Model")
rotModel.Name = "RotatingPlatform"
rotModel.Parent = trapsFolder

createPart(rotModel, "SpinPlatform", roblox.Vector3.new(16, 2, 16), roblox.CFrame.new(0, 10, 375), roblox.Color3.fromRGB(150, 60, 220), roblox.Enum.Material.DiamondPlate, true, true)
local beacons = roblox.Instance.new("Folder")
beacons.Name = "Beacons"
beacons.Parent = rotModel
createPart(beacons, "B1", roblox.Vector3.new(2, 4, 2), roblox.CFrame.new(-10, 12, 375), roblox.Color3.fromRGB(50, 50, 50), roblox.Enum.Material.SmoothPlastic, true, true)
createPart(beacons, "B2", roblox.Vector3.new(2, 4, 2), roblox.CFrame.new(10, 12, 375), roblox.Color3.fromRGB(50, 50, 50), roblox.Enum.Material.SmoothPlastic, true, true)

createPart(courseFolder, "FinalRunway", roblox.Vector3.new(12, 2, 30), roblox.CFrame.new(0, 10, 405), roblox.Color3.fromRGB(45, 50, 60), roblox.Enum.Material.Metal, true, true)

-- TRAP 6: PITFALL
local pitModel = roblox.Instance.new("Model")
pitModel.Name = "Pitfall"
pitModel.Parent = trapsFolder

createPart(pitModel, "PitFrameL", roblox.Vector3.new(2, 2, 32), roblox.CFrame.new(-7, 10, 445), roblox.Color3.fromRGB(30, 35, 40), roblox.Enum.Material.Metal, true, true)
createPart(pitModel, "PitFrameR", roblox.Vector3.new(2, 2, 32), roblox.CFrame.new(7, 10, 445), roblox.Color3.fromRGB(30, 35, 40), roblox.Enum.Material.Metal, true, true)

local warningFrame = roblox.Instance.new("Folder")
warningFrame.Name = "WarningFrame"
warningFrame.Parent = pitModel
createPart(warningFrame, "EdgeL", roblox.Vector3.new(1, 1, 32), roblox.CFrame.new(-6.5, 11.2, 445), roblox.Color3.fromRGB(50, 50, 50), roblox.Enum.Material.SmoothPlastic, true, false)
createPart(warningFrame, "EdgeR", roblox.Vector3.new(1, 1, 32), roblox.CFrame.new(6.5, 11.2, 445), roblox.Color3.fromRGB(50, 50, 50), roblox.Enum.Material.SmoothPlastic, true, false)

createPart(pitModel, "HatchLeft", roblox.Vector3.new(6, 2, 30), roblox.CFrame.new(-3, 10, 445), roblox.Color3.fromRGB(70, 75, 85), roblox.Enum.Material.DiamondPlate, true, true)
createPart(pitModel, "HatchRight", roblox.Vector3.new(6, 2, 30), roblox.CFrame.new(3, 10, 445), roblox.Color3.fromRGB(70, 75, 85), roblox.Enum.Material.DiamondPlate, true, true)

print("[Builder] Constructing Finish Platform...")
-- ==================== 5. FINISH PLATFORM ====================
local finish = roblox.Instance.new("Model")
finish.Name = "Finish"
finish.Parent = map

createPart(finish, "Floor", roblox.Vector3.new(30, 4, 30), roblox.CFrame.new(0, 10, 490), roblox.Color3.fromRGB(40, 50, 60), roblox.Enum.Material.DiamondPlate, true, true)
createPart(finish, "ArchL", roblox.Vector3.new(3, 16, 3), roblox.CFrame.new(-12, 20, 485), roblox.Color3.fromRGB(255, 215, 0), roblox.Enum.Material.Neon, true, true)
createPart(finish, "ArchR", roblox.Vector3.new(3, 16, 3), roblox.CFrame.new(12, 20, 485), roblox.Color3.fromRGB(255, 215, 0), roblox.Enum.Material.Neon, true, true)
createPart(finish, "ArchTop", roblox.Vector3.new(27, 3, 3), roblox.CFrame.new(0, 28, 485), roblox.Color3.fromRGB(255, 215, 0), roblox.Enum.Material.Neon, true, true)
createPart(finish, "FinishPad", roblox.Vector3.new(14, 1, 14), roblox.CFrame.new(0, 12.5, 490), roblox.Color3.fromRGB(255, 215, 0), roblox.Enum.Material.Neon, true, true)

print("[Builder] Adding 3D Physical Controller Terminals...")
-- ==================== 6. PHYSICAL CONTROLLER TERMINALS ====================
local trapZPositions = {
    CollapsingBridge = 65,
    SwingingHammer = 140,
    FallingCeiling = 225,
    MovingWall = 290,
    RotatingPlatform = 375,
    Pitfall = 445,
}

for trapId, zPos in pairs(trapZPositions) do
    local console = roblox.Instance.new("Model")
    console.Name = "Console_" .. trapId
    console.Parent = controllerArea

    createPart(console, "Stand", roblox.Vector3.new(2, 4, 3), roblox.CFrame.new(32, 28, zPos), roblox.Color3.fromRGB(30, 30, 35), roblox.Enum.Material.Metal, true, true)
    local button = createPart(console, "Button", roblox.Vector3.new(1.2, 0.6, 1.2), roblox.CFrame.new(32, 30.3, zPos), roblox.Color3.fromRGB(255, 30, 30), roblox.Enum.Material.Neon, true, true)

    local clickDetector = roblox.Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 14
    clickDetector.Parent = button
end

print("[Builder] Constructing KillZone...")
-- ==================== 7. KILLZONE ====================
local killZone = createPart(map, "KillZone", roblox.Vector3.new(1000, 4, 1000), roblox.CFrame.new(0, -20, 200), roblox.Color3.fromRGB(255, 0, 0), roblox.Enum.Material.Neon, true, false)
killZone.Transparency = 0.5

print("[Builder] Serializing place to Deathrun.rbxlx and Deathrun.rbxl...")
local outXml = roblox.serializePlace(place, true)
fs.writeFile("Deathrun.rbxlx", outXml)

local outBinary = roblox.serializePlace(place, false)
fs.writeFile("Deathrun.rbxl", outBinary)

print(string.format("[Builder] Successfully built places! XML: %d bytes, Binary: %d bytes", #outXml, #outBinary))
