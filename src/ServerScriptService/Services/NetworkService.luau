--!strict
--[[
    NetworkService.luau
    Manages client-server communication channels and RemoteEvents.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkService = {}
local RemotesFolder: Folder

local REMOTE_EVENTS = {
    "ActivateTrap",
    "TrapStateChanged",
    "PlayerStateChanged",
    "RoundStateChanged",
    "Announcement",
    "CheckpointReached",
    "DevToggleRole",
}

function NetworkService.Init()
    local existing = ReplicatedStorage:FindFirstChild("Remotes")
    if existing and existing:IsA("Folder") then
        RemotesFolder = existing
    else
        RemotesFolder = Instance.new("Folder")
        RemotesFolder.Name = "Remotes"
        RemotesFolder.Parent = ReplicatedStorage
    end

    for _, remoteName in ipairs(REMOTE_EVENTS) do
        if not RemotesFolder:FindFirstChild(remoteName) then
            local remote = Instance.new("RemoteEvent")
            remote.Name = remoteName
            remote.Parent = RemotesFolder
        end
    end
end

function NetworkService.GetRemote(name: string): RemoteEvent
    local remote = RemotesFolder:FindFirstChild(name)
    if not remote or not remote:IsA("RemoteEvent") then
        error(string.format("RemoteEvent %s not found in Remotes folder", name))
    end
    return remote
end

function NetworkService.FireClient(player: Player, remoteName: string, ...: any)
    local remote = NetworkService.GetRemote(remoteName)
    remote:FireClient(player, ...)
end

function NetworkService.FireAllClients(remoteName: string, ...: any)
    local remote = NetworkService.GetRemote(remoteName)
    remote:FireAllClients(...)
end

function NetworkService.ConnectServerEvent(remoteName: string, callback: (player: Player, ...any) -> ())
    local remote = NetworkService.GetRemote(remoteName)
    return remote.OnServerEvent:Connect(callback)
end

return NetworkService
