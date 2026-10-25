--!strict
--[[
    SoundController.luau
    Client sound effects player for UI clicks, alarms, and notifications.
]]

local SoundService = game:GetService("SoundService")

local SoundController = {}
local soundsFolder: Folder

-- Standard Roblox verified audio assets or procedural pitch sounds
local SOUND_CONFIGS = {
    Click = { SoundId = "rbxasset://sounds/uiclick.wav", Volume = 0.5, Pitch = 1.0 },
    Error = { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6, Pitch = 0.5 },
    TrapAlarm = { SoundId = "rbxasset://sounds/action_falling.mp3", Volume = 0.7, Pitch = 1.2 },
    Victory = { SoundId = "rbxasset://sounds/victory.wav", Volume = 0.8, Pitch = 1.0 },
    Death = { SoundId = "rbxasset://sounds/ouch.ogg", Volume = 0.6, Pitch = 0.9 },
    Checkpoint = { SoundId = "rbxasset://sounds/bell.wav", Volume = 0.6, Pitch = 1.2 },
    RoundStart = { SoundId = "rbxasset://sounds/button.wav", Volume = 0.8, Pitch = 1.5 },
}

local createdSounds: { [string]: Sound } = {}

function SoundController.Init()
    soundsFolder = Instance.new("Folder")
    soundsFolder.Name = "DeathrunSounds"
    soundsFolder.Parent = SoundService

    for name, config in pairs(SOUND_CONFIGS) do
        local sound = Instance.new("Sound")
        sound.Name = name
        sound.SoundId = config.SoundId
        sound.Volume = config.Volume
        sound.PlaybackSpeed = config.Pitch
        sound.Parent = soundsFolder
        createdSounds[name] = sound
    end
end

function SoundController.PlaySound(name: string)
    local sound = createdSounds[name]
    if sound then
        sound:Play()
    end
end

return SoundController
