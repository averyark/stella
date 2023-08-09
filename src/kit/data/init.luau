--[[
    FileName    > init.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 05/08/2023
--]]

local RunService = game:GetService("RunService")

local data = {}

local isServer = RunService:IsServer()

if isServer then
	local dataServer = require(script.server)

	return dataServer
else
	local dataClient = require(script.client)

	return dataClient
end
