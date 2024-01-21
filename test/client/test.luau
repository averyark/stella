--!nonstrict
--[[
    FileName    > test.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 05/08/2023
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local stella = require(ReplicatedStorage.Packages.stella)

local module = stella.module
local data = stella.data
local number = stella.number
local tween = stella.tween
local network = stella.network
local controls = stella.actions

local events = require(ReplicatedStorage.shared.events)

local test = {}

function test.load()
    events.remote.remoteTest:emit("test")
    --error("Something went wrong")
end

function test.preload()
    controls.onAction(stella.actions.TestAction):Connect(function(inputObject: InputObject)
        print(inputObject.UserInputState)
    end)
end

return module.new("test", test)