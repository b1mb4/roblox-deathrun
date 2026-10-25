--!strict
--[[
    RoundService.luau
    Authoritative server-side round lifecycle manager:
    - WaitingForPlayers -> Intermission -> Team Assignment -> InProgress -> Win Evaluation -> Results -> Reset
    - Handles disconnects, eliminations, single-runner alerts, and solo/multiplayer scaling.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enums = require(Shared:WaitForChild("Enums"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Types = require(Shared:WaitForChild("Types"))

local RoundService = {}

local currentRoundState: string = Enums.RoundState.WaitingForPlayers
local roundTimeRemaining: number = 0
local totalRunnersAtStart: number = 0
local lastControllerPlayer: Player? = nil
local lastRunnerAlertGiven: boolean = false
local roundLoopActive: boolean = false

local NetworkService: any
local PlayerStateService: any
local TrapService: any
local ScoringService: any
local CheckpointService: any

function RoundService.Init(deps: {
    NetworkService: any,
    PlayerStateService: any,
    TrapService: any,
    ScoringService: any,
    CheckpointService: any,
})
    NetworkService = deps.NetworkService
    PlayerStateService = deps.PlayerStateService
    TrapService = deps.TrapService
    ScoringService = deps.ScoringService
    CheckpointService = deps.CheckpointService

    -- Start background round lifecycle loop
    task.spawn(function()
        RoundService.StartRoundLoop()
    end)
end

function RoundService.IsRoundInProgress(): boolean
    return currentRoundState == Enums.RoundState.InProgress
end

function RoundService.GetRoundState(): string
    return currentRoundState
end

function RoundService.StartRoundLoop()
    if roundLoopActive then return end
    roundLoopActive = true

    while true do
        -- STEP 1: WAITING FOR PLAYERS
        currentRoundState = Enums.RoundState.WaitingForPlayers
        while #Players:GetPlayers() < GameConfig.MinPlayersToStart do
            RoundService.BroadcastRoundStatus(0)
            task.wait(1.0)
        end

        -- STEP 2: INTERMISSION
        currentRoundState = Enums.RoundState.Intermission
        for i = GameConfig.IntermissionDuration, 1, -1 do
            if #Players:GetPlayers() < GameConfig.MinPlayersToStart then
                break
            end
            RoundService.BroadcastRoundStatus(i)
            task.wait(1.0)
        end

        if #Players:GetPlayers() >= GameConfig.MinPlayersToStart then
            -- STEP 3: SETUP & START ROUND
            RoundService.SetupAndStartRound()

            -- STEP 4: ACTIVE ROUND LOOP
            while currentRoundState == Enums.RoundState.InProgress and roundTimeRemaining > 0 do
                task.wait(1.0)
                roundTimeRemaining -= 1
                RoundService.BroadcastRoundStatus(roundTimeRemaining)

                local activeRunners = PlayerStateService.GetActiveRunners()
                local runnerCount = #activeRunners

                -- Check last runner remaining announcement
                if runnerCount == 1 and totalRunnersAtStart > 1 and not lastRunnerAlertGiven then
                    lastRunnerAlertGiven = true
                    local lastRunner = activeRunners[1]
                    NetworkService.FireAllClients(
                        "Announcement",
                        "LAST RUNNER STANDING!",
                        string.format("%s is the only runner left! Survive to escape!", lastRunner.DisplayName),
                        Color3.fromRGB(255, 215, 0),
                        "LastRunner"
                    )
                end

                -- Check win condition: all runners dead
                if runnerCount == 0 then
                    RoundService.EndRound("TrapControllers", Enums.WinReason.AllRunnersEliminated)
                    break
                end
            end

            -- Check time expiration
            if currentRoundState == Enums.RoundState.InProgress and roundTimeRemaining <= 0 then
                RoundService.EndRound("TrapControllers", Enums.WinReason.TimeExpired)
            end

            -- STEP 5: RESULTS SCREEN & RESET
            task.wait(GameConfig.ResultsDuration)
            RoundService.CleanupAfterRound()
        end
    end
end

function RoundService.SetupAndStartRound()
    currentRoundState = Enums.RoundState.InProgress
    roundTimeRemaining = GameConfig.RoundDuration
    lastRunnerAlertGiven = false

    -- Reset services
    TrapService.ResetAllTraps()
    CheckpointService.ResetCheckpoints()
    ScoringService.ResetRoundRewards()
    PlayerStateService.ClearAliveRunners()

    local allPlayers = Players:GetPlayers()
    local controllers: { Player } = {}
    local runners: { Player } = {}

    if #allPlayers == 1 then
        -- Solo testing mode: player is runner
        table.insert(runners, allPlayers[1])
    else
        -- Multiplayer mode: choose 1 controller (rotate if possible)
        local chosenController = allPlayers[1]
        for _, p in ipairs(allPlayers) do
            if p ~= lastControllerPlayer then
                chosenController = p
                break
            end
        end
        lastControllerPlayer = chosenController
        table.insert(controllers, chosenController)

        for _, p in ipairs(allPlayers) do
            if p ~= chosenController then
                table.insert(runners, p)
            end
        end
    end

    totalRunnersAtStart = #runners

    -- Assign roles and teleport players
    for _, controller in ipairs(controllers) do
        PlayerStateService.SetPlayerState(controller, Enums.PlayerState.TrapController)
        controller:LoadCharacter()
        task.wait(0.1)
        PlayerStateService.TeleportTo(controller, GameConfig.Coordinates.ControllerSpawn)
    end

    for _, runner in ipairs(runners) do
        PlayerStateService.SetPlayerState(runner, Enums.PlayerState.Runner)
        PlayerStateService.MarkRunnerAlive(runner)
        runner:LoadCharacter()
        task.wait(0.1)
        PlayerStateService.TeleportTo(runner, GameConfig.Coordinates.RunnerSpawn)
    end

    -- Close / open start barrier
    RoundService.SetStartBarrier(false) -- closed
    task.wait(2.0)
    RoundService.SetStartBarrier(true) -- open!

    NetworkService.FireAllClients(
        "Announcement",
        "ROUND STARTED!",
        "Runners: Navigate the course to escape! Controllers: Eliminate them!",
        Color3.fromRGB(0, 200, 255),
        "RoundStart"
    )

    RoundService.BroadcastRoundStatus(roundTimeRemaining)
end

function RoundService.EndRound(winnerTeam: string, reason: string)
    if currentRoundState ~= Enums.RoundState.InProgress then return end
    currentRoundState = Enums.RoundState.RoundEnded

    -- Award participation points to all connected players
    for _, player in ipairs(Players:GetPlayers()) do
        ScoringService.AddPoints(player, GameConfig.Points.Participation)
    end

    -- Award wins to winner team
    if winnerTeam == "Runners" then
        for _, runner in ipairs(PlayerStateService.GetActiveRunners()) do
            ScoringService.AddWin(runner)
        end
    elseif winnerTeam == "TrapControllers" then
        for _, controller in ipairs(PlayerStateService.GetTrapControllers()) do
            ScoringService.AddWin(controller)
        end
    end

    local title = winnerTeam == "Runners" and "RUNNERS ESCAPED!" or "TRAP CONTROLLERS WIN!"
    local subtitle = ""
    if reason == Enums.WinReason.RunnersEscaped then
        subtitle = "A runner reached the finish line!"
    elseif reason == Enums.WinReason.AllRunnersEliminated then
        subtitle = "All runners were eliminated!"
    elseif reason == Enums.WinReason.TimeExpired then
        subtitle = "Time expired! The controllers defended the course!"
    end

    NetworkService.FireAllClients(
        "Announcement",
        title,
        subtitle,
        winnerTeam == "Runners" and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 75, 75),
        "Victory"
    )

    NetworkService.FireAllClients("RoundStateChanged", currentRoundState, 0, {
        RunnersCount = #PlayerStateService.GetActiveRunners(),
        ControllersCount = #PlayerStateService.GetTrapControllers(),
        TotalRunnersStart = totalRunnersAtStart,
        WinnerTeam = winnerTeam,
        WinReason = reason,
    })
end

function RoundService.OnRunnerFinished(player: Player)
    if currentRoundState ~= Enums.RoundState.InProgress then return end
    if PlayerStateService.GetPlayerState(player) ~= Enums.PlayerState.Runner then return end

    if ScoringService.CanRewardFinish(player) then
        ScoringService.RecordFinish(player)
        ScoringService.AddPoints(player, GameConfig.Points.Finish)
        ScoringService.AddWin(player)

        NetworkService.FireAllClients(
            "Announcement",
            string.format("%s REACHED THE FINISH!", player.DisplayName),
            "Runners win this round!",
            Color3.fromRGB(255, 215, 0),
            "Finish"
        )

        RoundService.EndRound("Runners", Enums.WinReason.RunnersEscaped)
    end
end

function RoundService.OnRunnerEliminated(player: Player)
    if currentRoundState ~= Enums.RoundState.InProgress then return end

    local remainingRunners = PlayerStateService.GetActiveRunners()
    if #remainingRunners == 0 then
        RoundService.EndRound("TrapControllers", Enums.WinReason.AllRunnersEliminated)
    else
        RoundService.UpdateRoundHUD()
    end
end

function RoundService.OnPlayerLeft(player: Player)
    if currentRoundState == Enums.RoundState.InProgress then
        local activeRunners = PlayerStateService.GetActiveRunners()
        if #activeRunners == 0 then
            RoundService.EndRound("TrapControllers", Enums.WinReason.AllRunnersEliminated)
        else
            RoundService.UpdateRoundHUD()
        end
    end
end

function RoundService.UpdateRoundHUD()
    RoundService.BroadcastRoundStatus(roundTimeRemaining)
end

function RoundService.BroadcastRoundStatus(timeRemaining: number)
    local runners = PlayerStateService and PlayerStateService.GetActiveRunners() or {}
    local controllers = PlayerStateService and PlayerStateService.GetTrapControllers() or {}

    NetworkService.FireAllClients("RoundStateChanged", currentRoundState, timeRemaining, {
        RunnersCount = #runners,
        ControllersCount = #controllers,
        TotalRunnersStart = totalRunnersAtStart,
    })
end

function RoundService.SetStartBarrier(isOpen: boolean)
    local barrier = Workspace:FindFirstChild("Map") 
        and Workspace.Map:FindFirstChild("RunnerStart") 
        and Workspace.Map.RunnerStart:FindFirstChild("Barrier") :: BasePart?

    if barrier then
        barrier.CanCollide = not isOpen
        barrier.Transparency = isOpen and 0.9 or 0.3
        barrier.Color = isOpen and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
    end
end

function RoundService.CleanupAfterRound()
    TrapService.ResetAllTraps()
    RoundService.SetStartBarrier(false)

    -- Move all players back to lobby
    for _, player in ipairs(Players:GetPlayers()) do
        PlayerStateService.SetPlayerState(player, Enums.PlayerState.Lobby)
        player:LoadCharacter()
        task.wait(0.1)
        PlayerStateService.TeleportTo(player, GameConfig.Coordinates.LobbySpawn)
    end
end

return RoundService
