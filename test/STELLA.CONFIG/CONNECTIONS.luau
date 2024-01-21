local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local stella = require(ReplicatedStorage.Packages.stella)
local network = stella.network

return {
    test = network.remote("test")
}