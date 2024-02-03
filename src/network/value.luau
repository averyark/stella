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
	function class.get(self: value)
		return self.value
	end
	function class.observe<Parameter>(self: value, callback: (...Parameter) -> ())
		if self.initialCall then
			Promise.try(callback, self.oldValue, self.value)
		end
		return self.valueChanged:Connect(callback)
	end
	function class.set(self: value, value: any)
		utility.assert(not isClient, "network: value can only be set from the server")

		if typeof(self.value) == "table" then
			self.oldValue = deepCopy(self.value, {})
		else
			self.oldValue = self.value
		end

		self.value = value
		self:emitAll(value, self.oldValue)
	end
	function class.new(identifier: string, initialValue: any, inheritance: rawEventType)
		--local
		local self = setmetatable(class, { __index = inheritance })

		self.oldValue = nil
		self.value = initialValue
		self.valueChanged = Signal.new()
		self.initialCall = false

		if isClient then
			self:call():andThen(function(newValue)
				if typeof(self.value) == "table" then
					self.oldValue = deepCopy(self.value, {})
				else
					self.oldValue = self.value
				end
				self.value = newValue
				self.valueChanged:Fire(self.oldValue, newValue)
				self.initialCall = true
			end)
			self.maid:Add(self:on(function(newValue)
				if typeof(self.value) == "table" then
					self.oldValue = deepCopy(self.value, {})
				else
					self.oldValue = self.value
				end
				self.value = newValue
				self.valueChanged:Fire(self.oldValue, newValue)
			end))
		else
			inheritance:onCall(function(player: Player)
				return self.value, self.oldValue
			end)
		end

		return self
	end

	export type value = typeof(class.new(""))
end

return class
