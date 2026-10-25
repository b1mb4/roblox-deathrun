--!strict
--[[
    TrapConfig.luau
    Centralized configuration for all 6 functional Deathrun traps.
    Configurable cooldowns and active durations matching specification:
    - Collapsing Bridge: 8s cooldown, 3s active
    - Swinging Hammer: 6s cooldown, 2s active
    - Falling Ceiling: 10s cooldown, 3s active
    - Moving Wall: 7s cooldown, 4s active
    - Rotating Platform: 9s cooldown, 5s active
    - Pitfall: 12s cooldown, 3s active
]]

export type TrapDefinition = {
    Id: string,
    DisplayName: string,
    Description: string,
    Cooldown: number,
    ActiveDuration: number,
    WarningDuration: number,
    Keybind: string,
    AccentColor: Color3,
    Icon: string,
    SectionIndex: number,
    ZCenter: number,
}

local Color3 = Color3 or (function()
    local ok, roblox = pcall(function() return require("@lune/roblox") end)
    return if ok and roblox and roblox.Color3 then roblox.Color3 else nil
end)()

local TrapConfig: { [string]: TrapDefinition } = {
    ["CollapsingBridge"] = {
        Id = "CollapsingBridge",
        DisplayName = "Collapsing Bridge",
        Description = "Bridge sections vanish, dropping runners into the void",
        Cooldown = 8.0,
        ActiveDuration = 3.0,
        WarningDuration = 0.5,
        Keybind = "1",
        AccentColor = Color3.fromRGB(240, 80, 80),
        Icon = "🌉",
        SectionIndex = 1,
        ZCenter = 65,
    },
    ["SwingingHammer"] = {
        Id = "SwingingHammer",
        DisplayName = "Swinging Hammer",
        Description = "Massive pendulum hammer sweeps across the narrow walkway",
        Cooldown = 6.0,
        ActiveDuration = 2.0,
        WarningDuration = 0.4,
        Keybind = "2",
        AccentColor = Color3.fromRGB(255, 160, 40),
        Icon = "🔨",
        SectionIndex = 2,
        ZCenter = 140,
    },
    ["FallingCeiling"] = {
        Id = "FallingCeiling",
        DisplayName = "Falling Ceiling",
        Description = "Spiked crusher ceiling slams down inside the tunnel",
        Cooldown = 10.0,
        ActiveDuration = 3.0,
        WarningDuration = 0.6,
        Keybind = "3",
        AccentColor = Color3.fromRGB(220, 50, 50),
        Icon = "🧱",
        SectionIndex = 3,
        ZCenter = 225,
    },
    ["MovingWall"] = {
        Id = "MovingWall",
        DisplayName = "Moving Wall",
        Description = "Heavy battering ram pushes runners sideways into the abyss",
        Cooldown = 7.0,
        ActiveDuration = 4.0,
        WarningDuration = 0.5,
        Keybind = "4",
        AccentColor = Color3.fromRGB(50, 180, 255),
        Icon = "🛡️",
        SectionIndex = 4,
        ZCenter = 290,
    },
    ["RotatingPlatform"] = {
        Id = "RotatingPlatform",
        DisplayName = "Rotating Platform",
        Description = "Platform spins rapidly and tilts, flinging runners off",
        Cooldown = 9.0,
        ActiveDuration = 5.0,
        WarningDuration = 0.5,
        Keybind = "5",
        AccentColor = Color3.fromRGB(180, 70, 255),
        Icon = "🔄",
        SectionIndex = 5,
        ZCenter = 375,
    },
    ["Pitfall"] = {
        Id = "Pitfall",
        DisplayName = "Pitfall Trap",
        Description = "Floor trapdoors snap open downward into a fiery chasm",
        Cooldown = 12.0,
        ActiveDuration = 3.0,
        WarningDuration = 0.5,
        Keybind = "6",
        AccentColor = Color3.fromRGB(255, 40, 140),
        Icon = "🕳️",
        SectionIndex = 6,
        ZCenter = 445,
    },
}

-- Array of ordered trap IDs for consistent UI display and sequential level order
local OrderedTrapIds = {
    "CollapsingBridge",
    "SwingingHammer",
    "FallingCeiling",
    "MovingWall",
    "RotatingPlatform",
    "Pitfall",
}

return {
    Traps = TrapConfig,
    Order = OrderedTrapIds,
}
