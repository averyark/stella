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
    local events = require(ReplicatedStorage.shared.events)

    events.server.bindableTest:on(function(...)
        --print(...)
    end)
    events.server.bindableTest:emit("yeah")
    events.server.bindableTest:emit(1, 2)
    
    events.remote.remoteTest:on(function(...)
        --print(...)
        print(...)
    end)
    
    events.remote.remoteTest:onCall(function(player: Player, a, b, c) 
        --print(player, a, b, c)
        return a + b + c, "yes"
    end)
    
    task.wait(7)
    events.remote.remoteTest:emit(network.EventEmitType.AllPlayers(), 1, "2", 3, 4, 6, true, false, Vector3.new())    
end)
