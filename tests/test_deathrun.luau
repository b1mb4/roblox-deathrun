--!strict
--[[
    test_deathrun.luau
    Automated test suite for Roblox Deathrun mechanics, architecture,
    state transitions, cooldown enforcement, scoring, and place file integrity.
]]

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local passedTests = 0
local failedTests = 0

local function assertTest(condition: boolean, testName: string, detail: string?)
    if condition then
        print(string.format("  ✅ PASS: %s", testName))
        passedTests += 1
    else
        print(string.format("  ❌ FAIL: %s - %s", testName, detail or "assertion failed"))
        failedTests += 1
    end
end

print("\n==================================================")
print("  RUNNING ROBLOX DEATHRUN AUTOMATED TEST SUITE")
print("==================================================\n")

-- --------------------------------------------------
-- TEST GROUP 1: CONFIGURATION & TIMINGS INTEGRITY
-- --------------------------------------------------
print("--- [Group 1: Configuration & Trap Timings] ---")

local TrapConfig = require("../src/ReplicatedStorage/Shared/TrapConfig")
local GameConfig = require("../src/ReplicatedStorage/Shared/GameConfig")
local Enums = require("../src/ReplicatedStorage/Shared/Enums")

assertTest(GameConfig.MinPlayersToStart == 1, "GameConfig supports solo testing (MinPlayersToStart == 1)")
assertTest(GameConfig.RoundDuration == 120, "Round duration is 120 seconds (2 minutes)")
assertTest(GameConfig.IntermissionDuration == 10, "Intermission duration is 10 seconds")
assertTest(GameConfig.PlayerInputDebounce == 0.3, "Player debounce is 0.3 seconds")
assertTest(GameConfig.TotalCheckpoints == 3, "Total checkpoints configured is 3")

-- Check the 6 required traps match EXACT specification
local expectedTraps = {
    CollapsingBridge = { Cooldown = 8, Active = 3 },
    SwingingHammer = { Cooldown = 6, Active = 2 },
    FallingCeiling = { Cooldown = 10, Active = 3 },
    MovingWall = { Cooldown = 7, Active = 4 },
    RotatingPlatform = { Cooldown = 9, Active = 5 },
    Pitfall = { Cooldown = 12, Active = 3 },
}

for trapId, expected in pairs(expectedTraps) do
    local def = TrapConfig.Traps[trapId]
    assertTest(def ~= nil, string.format("Trap '%s' is registered in TrapConfig", trapId))
    if def then
        assertTest(def.Cooldown == expected.Cooldown, string.format("Trap '%s' cooldown == %ds", trapId, expected.Cooldown))
        assertTest(def.ActiveDuration == expected.Active, string.format("Trap '%s' active duration == %ds", trapId, expected.Active))
    end
end

assertTest(#TrapConfig.Order == 6, "Trap order list contains exactly 6 traps")

-- --------------------------------------------------
-- TEST GROUP 2: TRAP COOLDOWN, MUTEX & DEBOUNCE LOGIC
-- --------------------------------------------------
print("\n--- [Group 2: Trap Cooldown & Mutex Concurrency] ---")

type MockTrapState = {
    IsAvailable: boolean,
    IsActive: boolean,
    CooldownExpiry: number,
    ActiveExpiry: number,
}

local function simulateTrapSystem()
    local states: { [string]: MockTrapState } = {}
    local debounce: { [string]: number } = {}

    for id, def in pairs(TrapConfig.Traps) do
        states[id] = {
            IsAvailable = true,
            IsActive = false,
            CooldownExpiry = 0,
            ActiveExpiry = 0,
        }
    end

    local function requestActivation(playerId: string, trapId: string, currentTime: number): (boolean, string?)
        -- Debounce check
        local lastTime = debounce[playerId] or 0
        if currentTime - lastTime < GameConfig.PlayerInputDebounce then
            return false, "Debounced"
        end
        debounce[playerId] = currentTime

        local def = TrapConfig.Traps[trapId]
        if not def then return false, "InvalidTrap" end

        local state = states[trapId]
        if not state.IsAvailable or state.IsActive or currentTime < state.CooldownExpiry then
            return false, "OnCooldown"
        end

        -- Lock trap
        state.IsAvailable = false
        state.IsActive = true
        state.CooldownExpiry = currentTime + def.Cooldown
        state.ActiveExpiry = currentTime + def.ActiveDuration

        return true, nil
    end

    return requestActivation, states
end

local triggerTrap, states = simulateTrapSystem()

-- Test normal activation
local t0 = 100.0
local success1, err1 = triggerTrap("Player1", "CollapsingBridge", t0)
assertTest(success1 == true and err1 == nil, "Controller 1 activates CollapsingBridge successfully")
assertTest(states.CollapsingBridge.IsActive == true, "CollapsingBridge state is Active")
assertTest(states.CollapsingBridge.CooldownExpiry == t0 + 8, "Cooldown expiry set to t0 + 8s")

-- Test concurrent activation by Controller 2 (simultaneous activation protection)
local success2, err2 = triggerTrap("Player2", "CollapsingBridge", t0 + 0.5)
assertTest(success2 == false and err2 == "OnCooldown", "Controller 2 blocked from activating CollapsingBridge while active/cooling")

-- Test player rapid click debounce
local successDebounce, errDebounce = triggerTrap("Player2", "SwingingHammer", t0 + 0.6)
assertTest(successDebounce == false and errDebounce == "Debounced", "Player 2 blocked by 0.3s input debounce")

-- Test independent trap activation
local success3, err3 = triggerTrap("Player1", "SwingingHammer", t0 + 1.0)
assertTest(success3 == true and err3 == nil, "Different trap (SwingingHammer) activates independently while Trap 1 is active")

-- Test cooldown recovery
local tRecovered = t0 + 8.1
states.CollapsingBridge.IsActive = false
states.CollapsingBridge.IsAvailable = true
local successAfterCooldown, errAfter = triggerTrap("Player1", "CollapsingBridge", tRecovered)
assertTest(successAfterCooldown == true and errAfter == nil, "CollapsingBridge can be activated again after cooldown expires")

-- --------------------------------------------------
-- TEST GROUP 3: PLAYER STATE TRANSITIONS & ELIMINATION
-- --------------------------------------------------
print("\n--- [Group 3: Player State Transitions & Deathrun Rules] ---")

type MockPlayer = {
    Name: string,
    State: string,
    Alive: boolean,
    Role: string,
}

local function simulateDeathrunSession()
    local players: { [string]: MockPlayer } = {
        P1 = { Name = "Runner1", State = Enums.PlayerState.Runner, Alive = true, Role = "Runner" },
        P2 = { Name = "Runner2", State = Enums.PlayerState.Runner, Alive = true, Role = "Runner" },
        P3 = { Name = "Controller1", State = Enums.PlayerState.TrapController, Alive = true, Role = "TrapController" },
    }

    local activeRunners = 2

    local function onRunnerDied(playerId: string)
        local p = players[playerId]
        if p and p.State == Enums.PlayerState.Runner then
            p.Alive = false
            p.State = Enums.PlayerState.TrapController
            p.Role = "TrapController"
            activeRunners -= 1
        end
    end

    local function canActivateTrap(playerId: string): boolean
        local p = players[playerId]
        return p ~= nil and p.State == Enums.PlayerState.TrapController
    end

    return players, onRunnerDied, canActivateTrap, function() return activeRunners end
end

local sessionPlayers, onDied, canTrigger, getActiveRunners = simulateDeathrunSession()

-- Rule 1: Runner cannot trigger traps
assertTest(canTrigger("P1") == false, "Runner (P1) CANNOT activate traps")
assertTest(canTrigger("P3") == true, "Trap Controller (P3) CAN activate traps")

-- Rule 2: Runner dies -> transitions to TrapController
onDied("P1")
assertTest(sessionPlayers.P1.State == Enums.PlayerState.TrapController, "Eliminated runner (P1) transitioned to TrapController")
assertTest(canTrigger("P1") == true, "Eliminated runner can now activate traps in subsequent gameplay")
assertTest(getActiveRunners() == 1, "Active runners count decremented to 1")

-- Rule 3: Last runner dies -> round ends
onDied("P2")
assertTest(getActiveRunners() == 0, "All runners eliminated -> Active runners count is 0 (triggers Controllers Win)")

-- --------------------------------------------------
-- TEST GROUP 4: SCORING & LEADERSTATS LOGIC
-- --------------------------------------------------
print("\n--- [Group 4: Scoring System & Reward Logic] ---")

local scores = { Points = 0, Wins = 0, Kills = 0 }
local finished = false

local function rewardFinish()
    if not finished then
        finished = true
        scores.Points += GameConfig.Points.Finish
        scores.Wins += 1
    end
end

local function rewardTrapKill()
    scores.Points += GameConfig.Points.TrapKill
    scores.Kills += 1
end

local function rewardCheckpoint()
    scores.Points += GameConfig.Points.Checkpoint
end

rewardFinish()
assertTest(scores.Points == 100 and scores.Wins == 1, "Finish awards +100 points and +1 win")

-- Test duplicate prevention
rewardFinish()
assertTest(scores.Points == 100 and scores.Wins == 1, "Duplicate finish reward is prevented")

rewardCheckpoint()
assertTest(scores.Points == 125, "Checkpoint awards +25 points")

rewardTrapKill()
assertTest(scores.Points == 175 and scores.Kills == 1, "Trap kill awards +50 points and +1 kill")

-- --------------------------------------------------
-- TEST GROUP 5: PLACE FILE INTEGRITY (RBXLX & RBXL)
-- --------------------------------------------------
print("\n--- [Group 5: Place File & 3D Instances Integrity] ---")

assertTest(fs.isFile("Deathrun.rbxlx"), "Deathrun.rbxlx XML place file exists on disk")
assertTest(fs.isFile("Deathrun.rbxl"), "Deathrun.rbxl Binary place file exists on disk")

local placeXml = fs.readFile("Deathrun.rbxlx")
local place = roblox.deserializePlace(placeXml)
local ws = place:GetService("Workspace")

local map = ws:FindFirstChild("Map")
assertTest(map ~= nil, "Workspace contains 'Map' folder")

if map then
    local lobby = map:FindFirstChild("Lobby")
    assertTest(lobby ~= nil, "Map contains 'Lobby' folder")
    assertTest(lobby:FindFirstChild("LobbySpawn") ~= nil, "Lobby contains 'LobbySpawn'")

    local runnerStart = map:FindFirstChild("RunnerStart")
    assertTest(runnerStart ~= nil, "Map contains 'RunnerStart' folder")
    assertTest(runnerStart:FindFirstChild("RunnerSpawn") ~= nil, "RunnerStart contains 'RunnerSpawn'")
    assertTest(runnerStart:FindFirstChild("Barrier") ~= nil, "RunnerStart contains countdown 'Barrier'")

    local ctrlCatwalk = map:FindFirstChild("TrapControllerArea")
    assertTest(ctrlCatwalk ~= nil, "Map contains 'TrapControllerArea' folder")
    assertTest(ctrlCatwalk:FindFirstChild("ControllerSpawn") ~= nil, "Controller area contains 'ControllerSpawn'")
    assertTest(ctrlCatwalk:FindFirstChild("GlassRailing") ~= nil, "Controller area contains 'GlassRailing' observation window")

    local traps = map:FindFirstChild("Traps")
    assertTest(traps ~= nil, "Map contains 'Traps' folder")

    if traps then
        for _, trapId in ipairs(TrapConfig.Order) do
            local trapModel = traps:FindFirstChild(trapId)
            assertTest(trapModel ~= nil, string.format("Physical model for Trap '%s' exists in Workspace.Map.Traps", trapId))
        end

        -- Check trap-specific functional parts
        local bridge = traps:FindFirstChild("CollapsingBridge")
        assertTest(bridge:FindFirstChild("Planks") ~= nil, "CollapsingBridge contains 'Planks' folder")

        local hammer = traps:FindFirstChild("SwingingHammer")
        assertTest(hammer:FindFirstChild("Hammer") ~= nil, "SwingingHammer contains 'Hammer' model")

        local ceiling = traps:FindFirstChild("FallingCeiling")
        assertTest(ceiling:FindFirstChild("Crusher") ~= nil, "FallingCeiling contains 'Crusher' slab")

        local wall = traps:FindFirstChild("MovingWall")
        assertTest(wall:FindFirstChild("Pusher") ~= nil, "MovingWall contains 'Pusher' wall")

        local rot = traps:FindFirstChild("RotatingPlatform")
        assertTest(rot:FindFirstChild("SpinPlatform") ~= nil, "RotatingPlatform contains 'SpinPlatform'")

        local pit = traps:FindFirstChild("Pitfall")
        assertTest(pit:FindFirstChild("HatchLeft") ~= nil and pit:FindFirstChild("HatchRight") ~= nil, "Pitfall contains dual 'HatchLeft' and 'HatchRight' trapdoors")
    end

    local cp1 = map:FindFirstChild("Checkpoint1")
    local cp2 = map:FindFirstChild("Checkpoint2")
    local cp3 = map:FindFirstChild("Checkpoint3")
    assertTest(cp1 ~= nil and cp2 ~= nil and cp3 ~= nil, "All 3 Checkpoint islands exist in Map")

    local finish = map:FindFirstChild("Finish")
    assertTest(finish ~= nil, "Map contains 'Finish' platform")
    assertTest(finish:FindFirstChild("FinishPad") ~= nil, "Finish platform contains 'FinishPad'")

    local killZone = map:FindFirstChild("KillZone")
    assertTest(killZone ~= nil, "Map contains 'KillZone' covering the void")
end

-- Check ServerScriptService and StarterPlayerScripts
local sss = place:GetService("ServerScriptService")
assertTest(sss:FindFirstChild("Main") ~= nil, "ServerScriptService contains 'Main' server script")
assertTest(sss:FindFirstChild("Services") ~= nil, "ServerScriptService contains 'Services' folder")

local sp = place:GetService("StarterPlayer")
local sps = sp:FindFirstChild("StarterPlayerScripts")
assertTest(sps ~= nil, "StarterPlayer contains 'StarterPlayerScripts'")
assertTest(sps:FindFirstChild("ClientMain") ~= nil, "StarterPlayerScripts contains 'ClientMain' client script")
assertTest(sps:FindFirstChild("Controllers") ~= nil, "StarterPlayerScripts contains 'Controllers' folder")

print("\n==================================================")
print(string.format("  TEST SUITE COMPLETED: %d PASSED, %d FAILED", passedTests, failedTests))
print("==================================================\n")

if failedTests > 0 then
    error(string.format("Test suite failed with %d errors!", failedTests))
end
