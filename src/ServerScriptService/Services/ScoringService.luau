--!strict
--[[
    ScoringService.luau
    Authoritative server-side scoring and leaderstats system.
]]

local Players = game:GetService("Players")

local ScoringService = {}

local finishedThisRound: { [Player]: boolean } = {}

function ScoringService.Init()
    Players.PlayerAdded:Connect(function(player)
        ScoringService.CreateLeaderstats(player)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        ScoringService.CreateLeaderstats(player)
    end
end

function ScoringService.CreateLeaderstats(player: Player)
    if player:FindFirstChild("leaderstats") then
        return
    end

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"

    local points = Instance.new("IntValue")
    points.Name = "Points"
    points.Value = 0
    points.Parent = leaderstats

    local wins = Instance.new("IntValue")
    wins.Name = "Wins"
    wins.Value = 0
    wins.Parent = leaderstats

    local kills = Instance.new("IntValue")
    kills.Name = "Kills"
    kills.Value = 0
    kills.Parent = leaderstats

    leaderstats.Parent = player
end

function ScoringService.AddPoints(player: Player, amount: number)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local points = leaderstats:FindFirstChild("Points") :: IntValue?
        if points then
            points.Value += amount
        end
    end
end

function ScoringService.AddWin(player: Player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local wins = leaderstats:FindFirstChild("Wins") :: IntValue?
        if wins then
            wins.Value += 1
        end
    end
end

function ScoringService.AddKill(player: Player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local kills = leaderstats:FindFirstChild("Kills") :: IntValue?
        if kills then
            kills.Value += 1
        end
    end
end

function ScoringService.CanRewardFinish(player: Player): boolean
    return not finishedThisRound[player]
end

function ScoringService.RecordFinish(player: Player)
    finishedThisRound[player] = true
end

function ScoringService.ResetRoundRewards()
    table.clear(finishedThisRound)
end

return ScoringService
