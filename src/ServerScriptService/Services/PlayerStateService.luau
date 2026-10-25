--!strict
--[[
    PlayerStateService.luau
    Authoritative server-side management of player states and team transitions:
    - Lobby -> Runner / TrapController
    - Runner Death -> Switch to TrapController & Respawn at Controller Walkway
    - Spectator handling for mid-round joins
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enums = require(Shared:WaitForChild("Enums"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local PlayerStateService = {}

local playerStates: { [Player]: string } = {}
local aliveRunners: { [Player]: boolean } = {}
local NetworkService: any
local ScoringService: any
local RoundService: any
local TrapService: any

function PlayerStateService.Init(deps: { 
    NetworkService: any, 
    ScoringService: any, 
    RoundService: any, 
    TrapService: any 
})
    NetworkService = deps.NetworkService
    ScoringService = deps.ScoringService
    RoundService = deps.RoundService
    TrapService = deps.TrapService

    Players.PlayerAdded:Connect(function(player)
        PlayerStateService.OnPlayerAdded(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        PlayerStateService.OnPlayerRemoving(player)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        PlayerStateService.OnPlayerAdded(player)
    end

    -- Hook up DevMode role toggle
    NetworkService.ConnectServerEvent("DevToggleRole", function(player: Player)
        if not GameConfig.DevMode then return end
        local currentState = PlayerStateService.GetPlayerState(player)
        if currentState == Enums.PlayerState.Runner then
            PlayerStateService.SetPlayerState(player, Enums.PlayerState.TrapController)
            PlayerStateService.TeleportTo(player, GameConfig.Coordinates.ControllerSpawn)
            NetworkService.FireClient(player, "Announcement", "DEV ROLE SWITCHED", "You are now a Trap Controller", Color3.fromRGB(255, 100, 100))
        else
            PlayerStateService.SetPlayerState(player, Enums.PlayerState.Runner)
            aliveRunners[player] = true
            PlayerStateService.TeleportTo(player, GameConfig.Coordinates.RunnerSpawn)
            NetworkService.FireClient(player, "Announcement", "DEV ROLE SWITCHED", "You are now a Runner", Color3.fromRGB(100, 255, 100))
        end
        if RoundService and RoundService.UpdateRoundHUD then
            RoundService.UpdateRoundHUD()
        end
    end)
end

function PlayerStateService.OnPlayerAdded(player: Player)
    playerStates[player] = Enums.PlayerState.Lobby

    player.CharacterAdded:Connect(function(character)
        PlayerStateService.OnCharacterAdded(player, character)
    end)

    if player.Character then
        PlayerStateService.OnCharacterAdded(player, player.Character)
    end
end

function PlayerStateService.OnCharacterAdded(player: Player, character: Model)
    local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
    if not humanoid then return end

    humanoid.Died:Connect(function()
        PlayerStateService.OnCharacterDied(player, character)
    end)

    -- Teleport to appropriate spawn based on current state
    task.spawn(function()
        task.wait(0.1)
        local state = playerStates[player]
        if state == Enums.PlayerState.Runner then
            PlayerStateService.TeleportTo(player, GameConfig.Coordinates.RunnerSpawn)
        elseif state == Enums.PlayerState.TrapController then
            PlayerStateService.TeleportTo(player, GameConfig.Coordinates.ControllerSpawn)
        else
            PlayerStateService.TeleportTo(player, GameConfig.Coordinates.LobbySpawn)
        end
    end)
end

function PlayerStateService.OnCharacterDied(player: Player, _character: Model)
    local state = playerStates[player]
    if state == Enums.PlayerState.Runner then
        aliveRunners[player] = nil

        -- Check if killed by an active trap for kill attribution
        local killer = TrapService and TrapService.GetRecentTrapController()
        if killer and killer ~= player then
            ScoringService.AddKill(killer)
            ScoringService.AddPoints(killer, GameConfig.Points.TrapKill)
            NetworkService.FireClient(killer, "Announcement", 
                "RUNNER ELIMINATED!", 
                string.format("+%d Pts (Eliminated %s)", GameConfig.Points.TrapKill, player.DisplayName), 
                Color3.fromRGB(255, 200, 50), 
                "Kill"
            )
        end

        -- Broadcast elimination to all players
        NetworkService.FireAllClients("Announcement", 
            "RUNNER ELIMINATED", 
            string.format("%s fell and became a Trap Controller!", player.DisplayName), 
            Color3.fromRGB(255, 75, 75), 
            "Death"
        )

        -- Transition runner to TrapController
        PlayerStateService.SetPlayerState(player, Enums.PlayerState.TrapController)

        -- Notify RoundService of elimination
        if RoundService then
            RoundService.OnRunnerEliminated(player)
        end

        -- Respawn player at trap controller observation area after delay
        task.delay(GameConfig.DeathRespawnDelay, function()
            if player.Parent and playerStates[player] == Enums.PlayerState.TrapController then
                player:LoadCharacter()
                task.wait(0.1)
                PlayerStateService.TeleportTo(player, GameConfig.Coordinates.ControllerSpawn)
                NetworkService.FireClient(player, "Announcement", 
                    "YOU ARE NOW A TRAP CONTROLLER", 
                    "Activate traps to eliminate the remaining runners!", 
                    Color3.fromRGB(255, 100, 100), 
                    "Siren"
                )
            end
        end)
    end
end

function PlayerStateService.OnPlayerRemoving(player: Player)
    playerStates[player] = nil
    aliveRunners[player] = nil

    if RoundService then
        RoundService.OnPlayerLeft(player)
    end
end

function PlayerStateService.SetPlayerState(player: Player, state: string)
    playerStates[player] = state
    NetworkService.FireClient(player, "PlayerStateChanged", state)
end

function PlayerStateService.GetPlayerState(player: Player): string
    return playerStates[player] or Enums.PlayerState.Lobby
end

function PlayerStateService.GetActiveRunners(): { Player }
    local list = {}
    for player, isAlive in pairs(aliveRunners) do
        if isAlive and player.Parent and playerStates[player] == Enums.PlayerState.Runner then
            table.insert(list, player)
        end
    end
    return list
end

function PlayerStateService.GetTrapControllers(): { Player }
    local list = {}
    for player, state in pairs(playerStates) do
        if state == Enums.PlayerState.TrapController and player.Parent then
            table.insert(list, player)
        end
    end
    return list
end

function PlayerStateService.MarkRunnerAlive(player: Player)
    aliveRunners[player] = true
end

function PlayerStateService.ClearAliveRunners()
    table.clear(aliveRunners)
end

function PlayerStateService.TeleportTo(player: Player, position: Vector3)
    local character = player.Character
    if character then
        local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if root then
            root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
        end
    end
end

return PlayerStateService
