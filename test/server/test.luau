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
local actions = stella.actions
local array = stella.array
local uiAutoScale = stella.uiAutoScale
local debugger = stella.debugger

local test = {}

function test.load()
   
end

function test.preload()
    
end

return module.new("test", test)