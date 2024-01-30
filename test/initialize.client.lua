--[[
    FileName    > initialize.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 31/05/2023
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local stella = require(ReplicatedStorage.Packages.stella)
local network = stella.network

-- network.remote()

stella.module.setModuleFolder(ReplicatedStorage.client)
stella.start():andThen(function() 
    print("Stella load completed")
end)
