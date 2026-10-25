--!strict
--[[
    Main.server.luau
    Server entry point for Roblox Deathrun.
    Initializes all core architecture services in strict dependency order:
    1. NetworkService (RemoteEvents)
    2. ScoringService (Leaderstats & rewards)
    3. CheckpointService (Runner checkpoint progression)
    4. PlayerStateService (Lobby / Runner / TrapController state management)
    5. TrapService (Shared cooldowns & physical hazard execution)
    6. RoundService (Round lifecycle, win conditions & timer)
    7. MapService (Map creation, spawns, and triggers)
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Services = ServerScriptService:WaitForChild("Services")

local NetworkService = require(Services:WaitForChild("NetworkService"))
local ScoringService = require(Services:WaitForChild("ScoringService"))
local CheckpointService = require(Services:WaitForChild("CheckpointService"))
local PlayerStateService = require(Services:WaitForChild("PlayerStateService"))
local TrapService = require(Services:WaitForChild("TrapService"))
local RoundService = require(Services:WaitForChild("RoundService"))
local MapService = require(Services:WaitForChild("MapService"))

print("[RobloxDeathrun] Starting server initialization...")

-- Step 1: Initialize Network Remotes
NetworkService.Init()

-- Step 2: Initialize Scoring & Leaderstats
ScoringService.Init()

-- Step 3: Wire CheckpointService
CheckpointService.Init({
    NetworkService = NetworkService,
    ScoringService = ScoringService,
    PlayerStateService = PlayerStateService,
})

-- Step 4: Wire PlayerStateService
PlayerStateService.Init({
    NetworkService = NetworkService,
    ScoringService = ScoringService,
    RoundService = RoundService,
    TrapService = TrapService,
})

-- Step 5: Wire TrapService
TrapService.Init({
    NetworkService = NetworkService,
    PlayerStateService = PlayerStateService,
    RoundService = RoundService,
})

-- Step 6: Wire RoundService
RoundService.Init({
    NetworkService = NetworkService,
    PlayerStateService = PlayerStateService,
    TrapService = TrapService,
    ScoringService = ScoringService,
    CheckpointService = CheckpointService,
})

-- Step 7: Wire MapService
MapService.Init({
    RoundService = RoundService,
    CheckpointService = CheckpointService,
    TrapService = TrapService,
})

print("[RobloxDeathrun] Server initialization completed successfully! Deathrun round manager is online.")
