--[[
    FileName    > events.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 03/08/2023
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local stella = require(ReplicatedStorage.Packages.stella)

local events = {}

do if RunService:IsServer() then
        events.server = {
            bindableTest = stella.network.bindable("bindableTest")
        }
    else
        events.client = {
            bindableTest = stella.network.bindable("bindableTest")
        }
    end 

    events.remote = {
        remoteTest = stella.network.remote("remoteTest")
    }
end

return events