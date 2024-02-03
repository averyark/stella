--[[
    FileName    > initialize.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 31/05/2023
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local stella = require(ReplicatedStorage.Packages.stella)
local network = stella.network

local actions = require(ReplicatedStorage.STELLA_CONFIG.ACTIONS)
local connections = require(ReplicatedStorage.STELLA_CONFIG.CONNECTIONS)

-- network.remote()

stella.module.setModuleFolder(ReplicatedStorage.client)
stella.start():andThen(function() 
    print("Stella load completed")
end)