--!strict
--[[
    GameConfig.luau
    Centralized configuration for Roblox Deathrun round rules, timers, and scoring.
]]

local Vector3 = Vector3 or (function()
    local ok, roblox = pcall(function() return require("@lune/roblox") end)
    return if ok and roblox and roblox.Vector3 then roblox.Vector3 else nil
end)()

local GameConfig = {
    -- Player & Round settings
    MinPlayersToStart = 1, -- Supports 1-player testing mode and multiplayer (CS2 Deathrun)
    IntermissionDuration = 10, -- Seconds between rounds
    RoundDuration = 120, -- Seconds per active round (2 minutes)
    ResultsDuration = 7, -- Seconds to show winner and scoreboard before reset
    
    -- Controller & Input settings
    PlayerInputDebounce = 0.3, -- Short server-side debounce to prevent click spamming
    DeathRespawnDelay = 2.0, -- Seconds after runner death before respawning as TrapController
    
    -- Runner parameters
    RunnerLives = 1, -- Standard 1-life elimination Deathrun
    CheckpointsEnabled = true,
    TotalCheckpoints = 3,
    
    -- Scoring & Rewards
    Points = {
        Finish = 100,
        Checkpoint = 25,
        TrapKill = 50,
        Participation = 10,
    },
    
    -- Developer & Testing settings
    DevMode = true, -- Enables developer debug controls (/switch, testing UI)
    
    -- Level Spawns and Geometry coordinates
    Coordinates = {
        LobbySpawn = Vector3.new(0, 52, -80),
        RunnerSpawn = Vector3.new(0, 12, 10),
        ControllerSpawn = Vector3.new(38, 27, 25),
        FinishPad = Vector3.new(0, 12, 490),
        KillZoneY = -20,
    }
}

return GameConfig
