--[[
    FileName    > init.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 01/08/2023
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = script.Parent
local dependencies = root.dependencies

local utility = require(script.Parent.utility)
local Signal = require(dependencies.Signal)
local Janitor = require(dependencies.Janitor)
local Promise = require(dependencies.Promise)
local t = require(dependencies.t)
local iris = require(dependencies.iris)
local BoatTween = require(dependencies.BoatTween)
local squash = require(dependencies.squash)

-- Class
local network = {}

local main = require(script.main)
local event = require(script.event)
local types = require(script.types)
local value = require(script.value)

local isClient = RunService:IsClient()

local started = false

network.new = event.new

network.bindable = function(identifier: string): types.event
    if main.events[identifier] then
        return main.events[identifier]
    end
	return event.new(identifier, "Local")
end
network.remote = function(identifier: string): types.event
    if not started and isClient then
        return event.stand(identifier, if isClient then "ReplicatedRemote" else "Remote")
    end
    if main.events[identifier] then
        return main.events[identifier]
    end
	if isClient then
		local remote = main.events[identifier]
		if remote then
			return remote
		end

		_, remote = Promise.retryWithDelay(function()
			return Promise.new(function(resolve, reject)
				local remote = main.events[identifier] :: types.event?
                if remote then
                    return resolve(remote)
                end
                return reject()
			end)
		end, 5, 1):await()

		if remote then
			return remote
		end
        return utility.warn(`network: failed to retrieve remote with identifier of {identifier}, is it registered on the server?`
		)
	end
    
	return event.new(identifier, "Remote")
end
network.value = function<Value>(identifier: string, initialValue: Value): types.value
	return value.new(identifier, initialValue, network.remote(identifier))
end

--[[network.bulkMake = function(bulkMakeTable: {
	remote: {string}?,
	values: {string}?,
	server: {string}?,
	client: {string}?,
}): {
	remote: {types.event}?,
	values: {types.value}?,
	server: {types.event}?,
	client: {types.event}?,
}
	local newTable = {}
	if bulkMakeTable.remote then
		newTable.remote = {}
		for _, identifier in pairs(bulkMakeTable.remote) do
			newTable.remote[identifier] = network.remote(identifier)
		end
	end
	return newTable
end]]

network.log = main.log
network.EventEmitType = main.EventEmitType
network.start = function()
	if RunService:IsClient() then
        main.start()
		local channel = ReplicatedStorage:FindFirstChild("__stellaNetworking")
		local function registerClientEvent(identifier: string)
			if main.events[identifier] then
				return
			end
			event.new(identifier, "ReplicatedRemote")
		end
		channel.ChildAdded:Connect(function(identifierSV)
			if identifierSV:IsA("StringValue") then
				registerClientEvent(identifierSV.Name)
			end
		end)
		channel.ChildRemoved:Connect(function(identifierSV)
			if identifierSV:IsA("StringValue") then
				local self = main.events[identifierSV.Name]
				main.removeEvent(self)
			end
		end)
		for _, identifierSV in pairs(channel:GetChildren()) do
			if identifierSV:IsA("StringValue") then
				registerClientEvent(identifierSV.Name)
			end
		end
        started = true
    else
        Promise.try(function() 
            main.start()
        end)
        
        started = true
	end
end

return network
