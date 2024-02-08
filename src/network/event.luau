--[[
    FileName    > class.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 01/08/2023
--]]

local RunService = game:GetService("RunService")

local root = script.Parent.Parent
local dependencies = root.dependencies

local utility = require(script.Parent.Parent.utility)
local encode = require(script.Parent.encode)
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

local event = {}

local function stand(identifier: string, kind: types.EventType)
	if standing[kind][identifier] then
		return standing[kind][identifier]
	end

	standing[kind][identifier] = setmetatable({}, event)

	return standing[kind][identifier]
end

do
	event.__index = event

	local isServer = RunService:IsServer()

	function event.new(identifier: string, kind: "Local" | "Remote" | "ReplicatedRemote")
		utility.assert(not main.events[identifier], "network: identifier already used, shadowing is not allowed")
		utility.assert(
			kind == "Remote" and isServer or kind ~= "Remote",
			"network: cannot create remote from the client"
		)

		local self = standing[kind][identifier] :: typeof(setmetatable({}, event)) or setmetatable({}, event)

		self.Identifier = identifier
		self.signal = Signal.new()
		self.Limiter = limiter.new(-1, -1)
		self.Kind = kind or "Local"
		self.callhandler = nil :: (<Parameter, Return>(...Parameter) -> ...Return)?
		self.maid = Janitor.new()

		main.makeEvent(self)
		self.maid:Add(self.signal)
		self.maid:Add(self.Limiter)

		return self
	end

	function event.Limit(self: event, rpm: number, rps: number)
		self.limiter.maxRPS = rps
		self.limiter.maxRPM = rpm
	end

	function event.Destroy(self: event)
		self.maid:Destroy()

		main.removeEvent(self)
	end

	function event.On<Argument>(self: event, callback: (...Argument) -> ())
		return self.signal:Connect(callback :: () -> ())
	end

	function event.Emit(self: event, ...: any?)
		if self.Kind == "Local" then
			self.signal:Fire(...)
		elseif self.Kind == "Remote" or self.Kind == "ReplicatedRemote" then
			local parameters = { ... }
			local param1 = parameters[1]
			local packet = {}

			if isServer then
				table.remove(parameters, 1)
				packet.eventEmitType = EventEmitType.Player(param1)
			else
				packet.eventEmitType = EventEmitType.Server()
			end
			
			packet.params = parameters
			packet.identifier = self.Identifier
			packet.clock = DateTime.now().UnixTimestampMillis

			main.addOutgoingQueue(self, packet)
		end
	end

	function event.EmitAll(self: event, ...: any)
		local packet = {}

		packet.eventEmitType = EventEmitType.AllPlayers()
		packet.params = { ... }
		packet.identifier = self.Identifier
		packet.clock = DateTime.now().UnixTimestampMillis

		main.addOutgoingQueue(self, packet)
	end

	function event.EmitExcept(self: event, exceptions: {Player}, ...: any)
		local packet = {}

		packet.eventEmitType = EventEmitType.ExceptSomePlayers(exceptions)
		packet.params = { ... }
		packet.identifier = self.Identifier
		packet.clock = DateTime.now().UnixTimestampMillis

		main.addOutgoingQueue(self, packet)
	end

	function event.EmitOnly(self: event, inclusion: {Player}, ...: any)
		local packet = {}

		packet.eventEmitType = EventEmitType.SomePlayers(inclusion)
		packet.params = { ... }
		packet.identifier = self.Identifier
		packet.clock = DateTime.now().UnixTimestampMillis

		main.addOutgoingQueue(self, packet)
	end

	function event.Call(self: event, ...: any?)
		if self.Kind == "Local" then
			return Promise.new(function(resolve)
				resolve({ self.callhandler() })
			end)
		elseif self.Kind == "Remote" or self.Kind == "ReplicatedRemote" then
			--utility.assert(not isServer, "network: For security reasons, you cannot call a client")
			if isServer then
				return Promise.reject("network: For security reasons, you cannot call a client")
			end
			local parameters = { ... }
			local packet = {}

			packet.params = parameters
			packet.identifier = self.Identifier
			packet.callId = main.calls
			packet.callStatus = "QueuedOutgoing"
			packet.clock = DateTime.now().UnixTimestampMillis

			main.calls += 1

			main.addOutgoingCallQueue(self, packet)

			return Promise.new(function(resolve, reject)
				packet.callResolve = resolve
				packet.callReject = reject
			end)
		end
		return Promise.reject("network: Invalid remote kind for call")
	end

	function event.OnCall<Parameter, Return>(self: event, callback: (...Parameter) -> ...Return)
		self.callHandler = callback
	end

	type event = typeof(event.new("", "Local"))
	class.new = event.new
end

class.stand = stand

return class
