--[[
    FileName    > client.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 31/05/2023
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local root = script.Parent.Parent.Parent

local dependencies = root.dependencies
local number = require(root.kit.number)
local Promise = require(dependencies.Promise)
local Signal = require(dependencies.Signal)
local Janitor = require(dependencies.Janitor)
local t = require(dependencies.t)
local utility = require(root.utility)
local helper = require(script.Parent.helper)
local settings = require(ReplicatedStorage.__stella)

local absoluteMatch = helper.absoluteMatch
local match = helper.match
local fromPath = helper.fromPath
local deepCopy = helper.deepCopy
local checkIfExist = helper.checkIfExist
local compare = helper.compare

local network = require(root.network)

local remotes = {
	datastoreOffline = network.remote("__stellaData__datastoreOffline"),
	datastoreOnline = network.remote("__stellaData__datastoreOnline"),
	dataChanged = network.remote("__stellaData__dataChanged"),
	dataUpdated = network.remote("__stellaData__dataUpdated"),
	updateData = network.remote("__stellaData__updateData"),
}

local client = {}
local data

local connectedFunctions = {}

local changed = function(changes)
	local snapchot = deepCopy(data)

	for _, change in pairs(changes) do
		local pathUpper1 = #change.path == 1 and {} or helper.table.cut(change.path, 1, #change.path - 1)
		fromPath(data, pathUpper1)[change.key] = change.new
	end

	for pathTable, connectedFunction in pairs(connectedFunctions) do
		if absoluteMatch(pathTable, changes) then
			Promise.try(connectedFunction, {
				new = fromPath(data, pathTable),
				old = fromPath(snapchot, pathTable),
			})
		end
	end
end

local initialize = function(_data)
	if data then
		return
	end

	data = _data

	for pathTable, connectedFunction in pairs(connectedFunctions) do
		Promise.try(connectedFunction, {
			new = fromPath(data, pathTable),
		})
	end

	remotes.dataChanged:on(changed)
	return
end

client.start = function()
	local retrieveDataFromServer = function()
		if data then
			return
		end
		remotes.updateData:emit()
	end

	remotes.datastoreOnline:call():andThen(function(status)
		print(status)
		if status == true then
			retrieveDataFromServer()
		end
	end)

	remotes.datastoreOffline:on(function(err)
		warn("DATASTORE IS OFFLINE", err.error)
		--notify.new(things.symbols.notificationType.Warning, "Critical DataStore Incident", err.error)
	end)
	remotes.dataUpdated:on(initialize)
	remotes.datastoreOnline:on(retrieveDataFromServer)
end

client.connect = function(_, path: { string }, f: (changes: { new: any, old: any }) -> ())
	connectedFunctions[path] = f

	if data then
		Promise.try(f, {
			new = fromPath(data, path),
		})
	end
end

client.wait = function()
	repeat
		task.wait()
	until data
end

client.get = function()
	return data :: typeof(settings.DataTemplate)
end

return client