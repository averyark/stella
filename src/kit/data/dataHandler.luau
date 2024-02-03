--[[
    FileName    > dataHandler.lua
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 08/01/2023
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

if RunService:IsClient() then
	return error("CANNOT BE CALLED ON THE CLIENT")
end

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

local network = require(root.network)

local absoluteMatch = helper.absoluteMatch
local match = helper.match
local fromPath = helper.fromPath
local deepCopy = helper.deepCopy
local checkIfExist = helper.checkIfExist
local compare = helper.compare

local data = {}

data.__index = data

function data.apply(self: dataClass, f)
	local snapchot = deepCopy(self.data)

	Promise.try(f, self.data)
		:andThen(function()
			local changes = compare(self.data, snapchot)

			self.changed:Fire(changes)

			for pathTable, connectedFunction in pairs(self.connectedFunctions) do
				if match(pathTable, changes) then
					Promise.try(connectedFunction, {
						new = fromPath(self.data, pathTable),
						old = fromPath(snapchot, pathTable),
					})
				end
			end
		end)
		:catch(warn)
end

function data.Destroy(self: dataClass)
	self.profile:Release()
end

function data.connect(self: dataClass, path, f: (changes: { new: any, old: any? }) -> ())
	assert(t.table(path))
	assert(t.callback(f))
	self.connectedFunctions[path] = f
	f({
		new = fromPath(self.data, path),
	})
end

function data.new(key: string, datastore)
	local profile =
		datastore:LoadProfileAsync(key) :: typeof(ProfileService.GetProfileStore("", {}):LoadProfileAsync(""))

	local self = setmetatable({
		profile = profile,
		key = key,
		data = profile.Data,

		connectedFunctions = {},

		changed = Signal.new(),

		_maid = Janitor.new(),
	}, data)

	return self
end

export type dataClass = typeof(data.new(""))

return {
	new = data.new,
}
