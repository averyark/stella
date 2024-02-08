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
local debugger = require(ReplicatedStorage.Packages.stella.kit.debugger)
local number = require(root.kit.number)
local Promise = require(dependencies.Promise)
local Signal = require(dependencies.Signal)
local Janitor = require(dependencies.Janitor)
local iris = require(dependencies.iris)
local t = require(dependencies.t)
local utility = require(root.utility)
local helper = require(script.Parent.helper)

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
local log = {}
local MAX_LOG_DISPLAY_CHANGE = 200
local paused = false
local snapchot = {}

type signal = typeof(Signal.new())

local connectedSignals = {} :: { signal }

local changed = function(changes)
	local snapchot = deepCopy(data)
	local _changes = {}

	print(changes)

	for _, change in pairs(changes) do
		local pathUpper1 = #change.path == 1 and {} or helper.table.cut(change.path, 1, #change.path - 1)
		fromPath(data, pathUpper1)[change.key] = change.new

		local old = fromPath(snapchot, change.path)
		local new = fromPath(data, change.path)

		if utility.settings.DEBUG_ENABLED then
			table.insert(_changes, `old: {utility.typeStringTransform(old, true)} > new: {utility.typeStringTransform(new, true)}`)
		end

		for pathTable, connectedSignal in pairs(connectedSignals) do
			if absoluteMatch(pathTable, change.path) then
				connectedSignal:Fire(old, new)
			end
		end
	end

	if utility.settings.DEBUG_ENABLED and #_changes > 0 then
		if #log > MAX_LOG_DISPLAY_CHANGE then
			table.remove(log, 1)
		end
		table.insert(log, `{DateTime.now():FormatLocalTime("HH:mm:ss:SSS", "en-us")} - {utility.typeStringTransform(_changes)}`)
	end
end

local datastoreError
local isDatastoreOnline = false

local initialize = function(_data)
	if data then
		return
	end

	data = _data

	for pathTable, connectedSignal in pairs(connectedSignals) do
		connectedSignal:Fire(nil, fromPath(data, pathTable))
	end

	return
end

client.start = function()
	local retrieveDataFromServer = function()
		if data then
			return
		end
		remotes.updateData:Emit()
	end

	remotes.datastoreOnline:Call():andThen(function(status)
		if status == true then
			print("Datastore is active and reachable")
			retrieveDataFromServer()
		else
			warn("Datastore is inactive and unreachable")
		end
		isDatastoreOnline = status
	end)

	remotes.datastoreOffline:On(function(err)
		warn("DATASTORE IS OFFLINE", err.error)
		datastoreError = err
		utility.settings.DATA_FAIL_FALLBACK_RESOLVER(err)
	end)
	remotes.dataUpdated:On(initialize)
	remotes.datastoreOnline:On(retrieveDataFromServer)
	remotes.dataChanged:On(changed)

	debugger.Append(function() 
		iris.CollapsingHeader({ "ProfileData analysis" })
			iris.Table(2)
				iris.NextColumn()
				iris.Text("Key")
				iris.NextColumn()
				iris.Text("Value")
				iris.NextColumn()
				iris.Text("DATA_SCOPE")
				iris.NextColumn()
				iris.Text(utility.settings.DATA_SCOPE)
			iris.End()
			iris.Text({`Datastore Status: {isDatastoreOnline and "<font color=\"#00ff00\">Online" or "<font color=\"#ff0000\">Offline"}</font>`, [iris.Args.Text.RichText] = true})
			iris.Text({`Datastore Error: {datastoreError == nil and "None" or "<font color=\"#ff0000\">" .. tostring(datastoreError) .. "</font>"}`, [iris.Args.Text.RichText] = true})
			iris.SeparatorText(`ProfileData Viewer`)
			iris.Table(1)
				iris.NextColumn()
				iris.Text(`{Players.LocalPlayer.Name}'s ProfileData`)
				iris.NextColumn()
				iris.Text({utility.typeStringTransform(data) .. ""} )
			iris.End()
			iris.Tree(`Client profile cache updates`)
			iris.SameLine().Instance.LayoutOrder = -MAX_LOG_DISPLAY_CHANGE-9999
				if iris.Button(paused and "Unpause" or "Pause").clicked() then
					paused = not paused
						snapchot = table.clone(log)
					end
					if iris.Button("Clear").clicked() then
						paused = false
						table.clear(snapchot)
						table.clear(log)
					end
				iris.End()
				for i, v in (paused and snapchot or log) :: {any} do
					iris.Text(v, {[iris.Args.Text.Wrapped] = true}).Instance.LayoutOrder = -i
				end
			iris.End()
		iris.End()
	end, 4)
end

client.Connect = function(_, path: { string }, callback: (new: any, old: any) -> ())
	connectedSignals[path] = Signal.new()

	if data then
		Promise.try(callback, nil, fromPath(data, path))
	end

	return connectedSignals[path]:Connect(callback)
end

client.Wait = function()
	repeat
		task.wait()
	until data
end

client.Get = function()
	return data :: typeof(utility.settings.DATA_TEMPLATE)
end

return client
