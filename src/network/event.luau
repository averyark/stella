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

local standing = {Local = {}, Remote = {}, ReplicatedRemote = {}}

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

		self.identifier = identifier
		self.signal = Signal.new()
		self.limiter = limiter.new(-1, -1)
		self.kind = kind or "Local"
		self.callhandler = nil :: (<Parameter, Return>(...Parameter) -> ...Return)?
		self.maid = Janitor.new()

		main.makeEvent(self)
		self.maid:Add(self.signal)
		self.maid:Add(self.limiter)

		return self
	end

	function event.limit(self: event, rps: number, rpm: number)
		self.limiter.maxRPS = rps
		self.limiter.maxRPM = rpm
	end

	function event.Destroy(self: event)
		
		self.maid:Destroy()

		main.removeEvent(self)
	end

	function event.on<Argument>(self: event, callback: (...Argument) -> ())
		
		return self.signal:Connect(callback:: () -> ())
	end

	function event.emit(self: event, ...: any?)
		if self.kind == "Local" then
			self.signal:Fire(...)
		elseif self.kind == "Remote" or self.kind == "ReplicatedRemote" then
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

	function event.call(self: event, ...: any?)
		if self.kind == "Local" then
			return Promise.new(function(resolve)
				resolve({ self.callhandler() })
			end)
		elseif self.kind == "Remote" or self.kind == "ReplicatedRemote" then
			--utility.assert(not isServer, "network: For security reasons, you cannot call a client")
			if isServer then
				return Promise.reject("network: For security reasons, you cannot call a client")
			end
			local parameters = { ... }
			local packet = {}

			packet.params = parameters
			packet.identifier = self.identifier
			packet.callId = main.calls
			packet.callStatus = "QueuedOutgoing"

			main.calls += 1

			main.addOutgoingCallQueue(self, packet)

			return Promise.new(function(resolve, reject)
				packet.callResolve = resolve
				packet.callReject = reject
			end)
		end
		return Promise.reject("network: Invalid remote kind for call")
	end

	function event.onCall<Parameter, Return>(self: event, callback: (...Parameter) -> ...Return)
		self.callHandler = callback
	end

	type event = typeof(event.new("", "Local"))
	class.new = event.new
end

class.stand = stand

return class
