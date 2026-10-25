--!strict
--[[
    Types.luau
    Shared type definitions for Roblox Deathrun.
]]

export type PlayerState = "Lobby" | "Runner" | "TrapController" | "Spectator"
export type RoundState = "WaitingForPlayers" | "Intermission" | "InProgress" | "RoundEnded"
export type WinReason = "RunnersEscaped" | "AllRunnersEliminated" | "TimeExpired" | "NotEnoughPlayers" | "RoundReset"

export type TrapRuntimeState = {
    Id: string,
    IsAvailable: boolean,
    IsActive: boolean,
    CooldownExpiry: number,
    ActiveExpiry: number,
    LastActivatedBy: Player?,
}

export type RoundStatusData = {
    RoundState: RoundState,
    TimeRemaining: number,
    RunnersCount: number,
    ControllersCount: number,
    TotalRunnersStart: number,
    WinnerTeam: string?,
    WinReason: WinReason?,
}

return {}
