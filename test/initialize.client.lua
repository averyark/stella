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
    local events = require(ReplicatedStorage.shared.events)

    events.client.bindableTest:on(function(...)
        --print(...)
    end)
    
    events.client.bindableTest:emit("yeah")
    events.client.bindableTest:emit(1, 2)
    
    events.remote.remoteTest:on(function(...)
        --print(...)
    end)
    
    events.remote.remoteTest:call(4, 5, 6):andThen(function(a, b)
        --print(a, b)
    end)
    
    task.wait(8)
    events.remote.remoteTest:emit(1, "2", 3, 4, 6, true)
end)
