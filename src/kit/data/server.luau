--!strict
--[[
    FileName    > clientDataHandler.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 09/01/2023
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
local ProfileService = require(dependencies.ProfileService)
local utility = require(root.utility)
local helper = require(script.Parent.helper)
local dataHandler = require(script.Parent.dataHandler)

local network = require(root.network)

local remotes = {
	datastoreOffline = network.remote("__stellaData__datastoreOffline"),
	datastoreOnline = network.remote("__stellaData__datastoreOnline"),
	dataChanged = network.remote("__stellaData__dataChanged"),
	dataUpdated = network.remote("__stellaData__dataUpdated"),
	updateData = network.remote("__stellaData__updateData"),
}

local server = {}

local playerDataCache = {}
local isDatastoreActive = false
local datastoreError
local datastore

local loadPlayerData = function(player, store)
	local data = dataHandler.new("PLAYER/" .. player.UserId, store)

	data.profile:AddUserId(player.UserId)
	data.profile:Reconcile()

	if data == nil then
		return player:Kick("DATASTORE ERROR")
	end
	if player:IsDescendantOf(Players) then
		playerDataCache[player] = data
	end

	data._maid:Add(player.AncestryChanged:Connect(function()
		if not player:IsDescendantOf(Players) then
			data:Destroy()
			playerDataCache[player] = nil
		end
	end))
	data._maid:Add(data.changed:Connect(function(changes)
		remotes.dataChanged:emit(player, changes)
	end))

	return data.data
end

-- >> TYPE
local TYPE = function()
	local public = {}

	local settings = require(ReplicatedStorage.__stella)

	public.profile = ProfileService.GetProfileStore():LoadProfileAsync()
	public.data = settings.DataTemplate
	public.changed = Signal.new()

	type template = typeof(settings.DataTemplate)

	function public:apply(f: (template) -> ()) end

	function public:connect(key: { string }, f: (changes: { new: any, old: any? }) -> ()) end

	return public
end

server.waitForDataStore = function()
	if isDatastoreActive then
		return
	end
	repeat
		task.wait()
	until isDatastoreActive
	return
end

server.start = function()
	remotes.datastoreOnline:onCall(function(player)
		if datastoreError then
			remotes.datastoreOffline:emit(player, datastoreError)
		end
		return isDatastoreActive
	end)

	remotes.updateData:on(function(player, ...)
		server.waitForDataStore()

		local data = loadPlayerData(player, datastore)

		remotes.dataUpdated:emit(player, data)
	end)

	Promise.try(function()
		local _datastore = ProfileService.GetProfileStore(utility.settings.DataScope, utility.settings.DataTemplate)
		local isValid = t.table(_datastore)

		assert(isValid, "Datastore failed to load")

		local profile = ProfileService.GetProfileStore(utility.settings.DataScope, utility.settings.DataTemplate)

		return _datastore
	end)
		:andThen(function(store)
			datastore = store
			remotes.datastoreOnline:emit(network.EventEmitType.AllPlayers(), "datastoreOnline")
			isDatastoreActive = true
		end)
		:catch(function(err)
			warn(err.error)
			remotes.datastoreOnline:emit(network.EventEmitType.AllPlayers(), "datastoreOffline", err)
			isDatastoreActive = false
			datastoreError = err
		end)
end

server.getPlayer = function(player): typeof(TYPE())?
	if player:IsDescendantOf(Players) then
		if not playerDataCache[player] then
			repeat
				task.wait()
			until playerDataCache[player] or not player:IsDescendantOf(Players)
		end
		return playerDataCache[player]
	end
	return nil
end

return server
