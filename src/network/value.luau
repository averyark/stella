local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local root = script.Parent.Parent
local dependencies = root.dependencies

local utility = require(script.Parent.Parent.utility)
local Signal = require(dependencies.Signal)
local Janitor = require(dependencies.Janitor)
local Promise = require(dependencies.Promise)
local t = require(dependencies.t)
local iris = require(dependencies.iris)
local BoatTween = require(dependencies.BoatTween)
local squash = require(dependencies.squash)

local types = require(script.Parent.types)
local event = require(script.Parent.event)

local isClient = RunService:IsClient()

local class = {}

type rawEventType = typeof(event.new("", "Remote"))

local function deepCopy<T>(tableToClone: T & { [number]: any }, cache: {}): T | { [number]: any }?
	local result = {}

	cache = if cache then cache else {}

	for key, v in pairs(tableToClone) do
		if typeof(v) == "table" then
			if table.find(cache, v) then
				return
			end -- anti recursive
			table.insert(cache, v)
			result[key] = deepCopy(v, cache)
		else
			result[key] = v
		end
	end

	return result
end

do
	class.__index = class
	function class.Get(self: value)
		return self.Value
	end
	function class.Listen<Parameter>(self: value, callback: (...Parameter) -> ())
		if self.InitialCall then
			Promise.try(callback, self.OldValue, self.Value)
		end
		return self.OnValueChanged:Connect(callback)
	end
	function class.Set(self: value, value: any)
		utility.assert(not isClient, "network: value can only be set from the server")

		if typeof(self.value) == "table" then
			self.OldValue = deepCopy(self.Value, {})
		else
			self.OldValue = self.Value
		end

		self.Value = value
		self:EmitAll(value, self.OldValue)
	end
	function class.new(identifier: string, initialValue: any, inheritance: rawEventType)
		--local
		local self = setmetatable(class, { __index = inheritance })

		self.OldValue = nil
		self.Value = initialValue
		self.OnValueChanged = Signal.new()
		self.InitialCall = false

		if isClient then
			self:Call():andThen(function(newValue)
				if typeof(self.Value) == "table" then
					self.OldValue = deepCopy(self.Value, {})
				else
					self.OldValue = self.Value
				end
				self.Value = newValue
				self.OnValueChanged:Fire(self.OldValue, newValue)
				self.InitialCall = true
			end)
			self.maid:Add(self:On(function(newValue)
				if typeof(self.Value) == "table" then
					self.OldValue = deepCopy(self.Value, {})
				else
					self.OldValue = self.Value
				end
				self.Value = newValue
				self.OnValueChanged:Fire(self.OldValue, newValue)
			end))
		else
			inheritance:OnCall(function(player: Player)
				return self.Value, self.oldValue
			end)
		end

		return self
	end

	export type value = typeof(class.new(""))
end

return class
