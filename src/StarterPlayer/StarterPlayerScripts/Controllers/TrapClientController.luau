--!strict
--[[
    TrapClientController.luau
    Handles client input for trap triggers (keyboard 1-6 & UI buttons)
    and synchronizes shared trap cooldowns and active states.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TrapConfig = require(Shared:WaitForChild("TrapConfig"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local TrapClientController = {}

type ClientTrapState = {
    IsAvailable: boolean,
    IsActive: boolean,
    CooldownRemaining: number,
    ActiveRemaining: number,
    CooldownTotal: number,
    LastUpdated: number,
}

local clientTrapStates: { [string]: ClientTrapState } = {}
local lastClickTime: number = 0
local SoundController: any
local onStateChangedCallback: ((trapId: string, state: ClientTrapState) -> ())? = nil

local activateRemote: RemoteEvent? = nil
local stateChangedRemote: RemoteEvent? = nil

function TrapClientController.Init(deps: { SoundController: any })
    SoundController = deps.SoundController

    -- Initialize local state cache for each trap
    for id, def in pairs(TrapConfig.Traps) do
        clientTrapStates[id] = {
            IsAvailable = true,
            IsActive = false,
            CooldownRemaining = 0,
            ActiveRemaining = 0,
            CooldownTotal = def.Cooldown,
            LastUpdated = os.clock(),
        }
    end

    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if remotes then
        activateRemote = remotes:WaitForChild("ActivateTrap") :: RemoteEvent
        stateChangedRemote = remotes:WaitForChild("TrapStateChanged") :: RemoteEvent

        stateChangedRemote.OnClientEvent:Connect(function(
            trapId: string,
            isAvailable: boolean,
            isActive: boolean,
            cooldownRemaining: number,
            activeRemaining: number,
            _triggeredBy: string?
        )
            TrapClientController.UpdateTrapState(trapId, isAvailable, isActive, cooldownRemaining, activeRemaining)
        end)
    end

    -- Hook up keyboard number shortcuts [1] to [6]
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyName = input.KeyCode.Name
            local keyMap: { [string]: string } = {
                One = "CollapsingBridge",
                Two = "SwingingHammer",
                Three = "FallingCeiling",
                Four = "MovingWall",
                Five = "RotatingPlatform",
                Six = "Pitfall",
            }
            local trapId = keyMap[keyName]
            if trapId then
                TrapClientController.RequestActivation(trapId)
            end
        end
    end)
end

function TrapClientController.SetOnStateChanged(callback: (trapId: string, state: ClientTrapState) -> ())
    onStateChangedCallback = callback
end

function TrapClientController.RequestActivation(trapId: string)
    local now = os.clock()
    if now - lastClickTime < GameConfig.PlayerInputDebounce then
        return
    end
    lastClickTime = now

    local state = clientTrapStates[trapId]
    if not state then return end

    if not state.IsAvailable or state.IsActive or state.CooldownRemaining > 0 then
        if SoundController then
            SoundController.PlaySound("Error")
        end
        return
    end

    if SoundController then
        SoundController.PlaySound("Click")
    end

    if activateRemote then
        activateRemote:FireServer(trapId)
    end
end

function TrapClientController.UpdateTrapState(
    trapId: string,
    isAvailable: boolean,
    isActive: boolean,
    cooldownRemaining: number,
    activeRemaining: number
)
    local state = clientTrapStates[trapId]
    if not state then return end

    state.IsAvailable = isAvailable
    state.IsActive = isActive
    state.CooldownRemaining = cooldownRemaining
    state.ActiveRemaining = activeRemaining
    state.LastUpdated = os.clock()

    if onStateChangedCallback then
        onStateChangedCallback(trapId, state)
    end
end

function TrapClientController.GetTrapState(trapId: string): ClientTrapState?
    return clientTrapStates[trapId]
end

return TrapClientController
