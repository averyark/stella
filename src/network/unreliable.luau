--[[
    FileName    > class.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 01/08/2023
--]]

local RunService = game:GetService("RunService")

local root = script.Parent.Parent
local dependencies = root.dependencies

local utility = require(root.utility)
local Signal = require(dependencies.Signal)
local Janitor = require(dependencies.Janitor)
local Promise = require(dependencies.Promise)
local t = require(dependencies.t)
local iris = require(dependencies.iris)
local BoatTween = require(dependencies.BoatTween)
local squash = require(dependencies.squash)

local main = require(script.Parent.main)
local limiter = require(script.Parent.limiter)
local types = require(script.Parent.types)

local EventEmitType = main.EventEmitType

local class = {}

local standing = { Local = {}, Remote = {}, ReplicatedRemote = {} }

local unreliable = {}

local function stand(identifier: string, kind: types.EventType)
	if standing[kind][identifier] then
		return standing[kind][identifier]
	end

	standing[kind][identifier] = setmetatable({}, unreliable)

	return standing[kind][identifier]
end

do
	unreliable.__index = unreliable

	local isServer = RunService:IsServer()

	function unreliable.new(identifier: string, kind: "Remote" | "ReplicatedRemote")
		utility.assert(not main.events[identifier], "network: identifier already used, shadowing is not allowed")
		utility.assert(
			kind == "Remote" and isServer or kind ~= "Remote",
			"network: cannot create remote from the client"
		)

		local self = standing[kind][identifier] :: typeof(setmetatable({}, unreliable)) or setmetatable({}, unreliable)

		self.identifier = identifier
		self.signal = Signal.new()
		self.limiter = limiter.new(-1, -1)
		self.kind = kind or "Remote"
		self.callhandler = nil :: (<Parameter, Return>(...Parameter) -> ...Return)?
		self.maid = Janitor.new()

		main.makeEvent(self)
		self.maid:Add(self.signal)
		self.maid:Add(self.limiter)

		return self
	end

	function unreliable.limit(self: unreliable, rps: number, rpm: number)
		self.limiter.maxRPS = rps
		self.limiter.maxRPM = rpm
	end

	function unreliable.Destroy(self: unreliable)
		self.maid:Destroy()

		main.removeEvent(self)
	end

	function unreliable.on<Argument>(self: unreliable, callback: (...Argument) -> ())
		return self.signal:Connect(callback :: () -> ())
	end

	function unreliable.emit(self: unreliable, ...: any?)
		if self.kind == "Remote" or self.kind == "ReplicatedRemote" then
			local parameters = { ... }
			local param1 = parameters[1]
			local eventEmitType = if t.table(param1) and param1.kind then param1 else nil

			if typeof(param1) == "Instance" and param1:IsA("Player") then
				eventEmitType = EventEmitType.Player(param1)
			end

			utility.assert(isServer and eventEmitType or not isServer, "network: missing EventEmitType")

			if eventEmitType then
				table.remove(parameters, 1)
			end

			local packet = {}

			packet.eventEmitType = eventEmitType or EventEmitType.Server()
			packet.params = parameters
			packet.identifier = self.identifier

			main.addOutgoingQueue(self, packet)
		end
	end

	type unreliable = typeof(unreliable.new("", "Remote"))
	class.new = unreliable.new
end

class.stand = stand

return class
