--!strict
--[[
    ClientMain.client.luau
    Client bootstrap for Roblox Deathrun.
    Wires all client controllers and remote network events.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local localPlayer = Players.LocalPlayer
local controllersFolder = script.Parent:WaitForChild("Controllers")

local SoundController = require(controllersFolder:WaitForChild("SoundController"))
local NotificationController = require(controllersFolder:WaitForChild("NotificationController"))
local TrapClientController = require(controllersFolder:WaitForChild("TrapClientController"))
local UIController = require(controllersFolder:WaitForChild("UIController"))

print("[RobloxDeathrun Client] Initializing client subsystems...")

-- Initialize Controllers
SoundController.Init()
TrapClientController.Init({ SoundController = SoundController })
UIController.Init({ TrapClientController = TrapClientController })

-- Wire NotificationController with the main ScreenGui
local playerGui = localPlayer:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("DeathrunMainGui") :: ScreenGui
NotificationController.Init(mainGui)

-- Listen to server Remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if remotes then
    local playerStateChanged = remotes:WaitForChild("PlayerStateChanged") :: RemoteEvent
    local roundStateChanged = remotes:WaitForChild("RoundStateChanged") :: RemoteEvent
    local announcement = remotes:WaitForChild("Announcement") :: RemoteEvent
    local checkpointReached = remotes:WaitForChild("CheckpointReached") :: RemoteEvent

    playerStateChanged.OnClientEvent:Connect(function(newRole: string)
        UIController.UpdateRole(newRole)
    end)

    roundStateChanged.OnClientEvent:Connect(function(state: string, timeRemaining: number, extra: any)
        UIController.UpdateRoundStatus(state, timeRemaining, extra)
    end)

    announcement.OnClientEvent:Connect(function(title: string, subtitle: string, color: Color3?, sound: string?)
        NotificationController.ShowBanner(title, subtitle, color)
        if sound and SoundController then
            SoundController.PlaySound(sound)
        end
    end)

    checkpointReached.OnClientEvent:Connect(function(index: number)
        UIController.UpdateCheckpoint(index)
    end)
end

print("[RobloxDeathrun Client] Client ready! Ready for Deathrun action.")
