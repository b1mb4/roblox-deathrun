--!strict
--[[
    Enums.luau
    Centralized game enums for Roblox Deathrun.
]]

local Enums = {}

Enums.PlayerState = {
    Lobby = "Lobby",
    Runner = "Runner",
    TrapController = "TrapController",
    Spectator = "Spectator",
}

Enums.RoundState = {
    WaitingForPlayers = "WaitingForPlayers",
    Intermission = "Intermission",
    InProgress = "InProgress",
    RoundEnded = "RoundEnded",
}

Enums.WinReason = {
    RunnersEscaped = "RunnersEscaped",
    AllRunnersEliminated = "AllRunnersEliminated",
    TimeExpired = "TimeExpired",
    NotEnoughPlayers = "NotEnoughPlayers",
    RoundReset = "RoundReset",
}

Enums.TrapStatus = {
    Ready = "Ready",
    Active = "Active",
    Cooldown = "Cooldown",
}

return Enums
