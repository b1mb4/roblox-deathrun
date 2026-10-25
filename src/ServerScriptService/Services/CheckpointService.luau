--!strict
--[[
    CheckpointService.luau
    Authoritative server-side checkpoint progression for runners.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Enums = require(Shared:WaitForChild("Enums"))

local CheckpointService = {}

local highestCheckpoint: { [Player]: number } = {}
local NetworkService: any
local ScoringService: any
local PlayerStateService: any

function CheckpointService.Init(deps: { NetworkService: any, ScoringService: any, PlayerStateService: any })
    NetworkService = deps.NetworkService
    ScoringService = deps.ScoringService
    PlayerStateService = deps.PlayerStateService
end

function CheckpointService.OnCheckpointTouched(player: Player, checkpointIndex: number, padPart: BasePart)
    if not PlayerStateService or PlayerStateService.GetPlayerState(player) ~= Enums.PlayerState.Runner then
        return
    end

    local current = highestCheckpoint[player] or 0
    if checkpointIndex > current then
        highestCheckpoint[player] = checkpointIndex
        ScoringService.AddPoints(player, GameConfig.Points.Checkpoint)

        NetworkService.FireClient(player, "CheckpointReached", checkpointIndex)
        NetworkService.FireClient(player, "Announcement", 
            string.format("CHECKPOINT %d REACHED!", checkpointIndex), 
            string.format("+%d Points", GameConfig.Points.Checkpoint), 
            Color3.fromRGB(80, 255, 120), 
            "Checkpoint"
        )

        -- Visual effect on checkpoint pad
        task.spawn(function()
            local originalColor = padPart.Color
            padPart.Color = Color3.fromRGB(0, 255, 100)
            padPart.Material = Enum.Material.Neon
            task.wait(1.5)
            padPart.Color = originalColor
        end)
    end
end

function CheckpointService.GetPlayerCheckpoint(player: Player): number
    return highestCheckpoint[player] or 0
end

function CheckpointService.ResetCheckpoints()
    table.clear(highestCheckpoint)
end

function CheckpointService.OnPlayerRemoving(player: Player)
    highestCheckpoint[player] = nil
end

return CheckpointService
