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
local tag = stella.tag

local CONFIG = require(ReplicatedStorage.STELLA_CONFIG)
local ACTIONS = require(ReplicatedStorage.STELLA_CONFIG.ACTIONS)
local CONNECTIONS = require(ReplicatedStorage.STELLA_CONFIG.CONNECTIONS)
local TAGS = require(ReplicatedStorage.STELLA_CONFIG.TAGS)

local test = {}

function test.load()
   
end

function test.preload()
    ReplicatedStorage.Remote.OnServerEvent:Connect(function(player, number)
        TAGS.Stun:Add(player.Character, number)
    end)
    Players.PlayerAdded:Connect(function(player) 
        player.CharacterAdded:Connect(function() 
            TAGS.Stun:ListenToInstance(player.Character, print)
        end)
        if player.Character then
            TAGS.Stun:ListenToInstance(player.Character, print)
        end
    end)
    for _, player in Players:GetPlayers() do
        player.CharacterAdded:Connect(function() 
            TAGS.Stun:ListenToInstance(player.Character, print)
        end)
        if player.Character then
            TAGS.Stun:ListenToInstance(player.Character, print)
        end
    end
end

return module.new("test", test)