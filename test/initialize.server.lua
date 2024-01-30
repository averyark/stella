--[[
    FileName    > initialize.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 31/05/2023
--]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local stella = require(ReplicatedStorage.Packages.stella)
local network = stella.network

stella.module.setModuleFolder(ServerScriptService.server)
stella.start():andThen(function() 
  
end)
