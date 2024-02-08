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

local function new(key: string, datastore)
	local profile =
		datastore:LoadProfileAsync(key) :: typeof(ProfileService.GetProfileStore("", {}):LoadProfileAsync(""))

	local self = setmetatable({
		Profile = profile,
		Key = key,
		Data = profile.Data,

		ConnectedFunctions = {},

		OnChanged = Signal.new(),

		_maid = Janitor.new(),
	}, data)

	return self
end

export type dataClass = typeof(new(...))

function data.Apply(self: dataClass, f)
	local snapchot = deepCopy(self.Data)

	return Promise.try(f, self.Data)
		:andThen(function()
			local changes = compare(self.Data, snapchot)

			self.OnChanged:Fire(changes)

			for pathTable, connectedFunction in pairs(self.ConnectedFunctions) do
				if match(pathTable, changes) then
					Promise.try(connectedFunction, {
						new = fromPath(self.Data, pathTable),
						old = fromPath(snapchot, pathTable),
					})
				end
			end
		end)
		:catch(warn)
end

function data.Destroy(self: dataClass)
	self.Profile:Release()
end

function data.Connect(self: dataClass, path, f: (changes: { new: any, old: any? }) -> ())
	assert(t.table(path))
	assert(t.callback(f))
	self.ConnectedFunctions[path] = f
	f({
		new = fromPath(self.Data, path),
	})
end

return {
	new = new,
}
