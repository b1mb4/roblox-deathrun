local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local xml = fs.readFile("Deathrun.rbxlx")
local place = roblox.deserializePlace(xml)
local ws = place:GetService("Workspace")
print("Workspace found:", ws ~= nil)
