--[[
    FileName    > init.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 01/08/2023
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = script.Parent.Parent
local dependencies = root.dependencies

local clock = require(script.Parent.clock)
local limiter = require(script.Parent.limiter)
local recycledThread = require(script.Parent.recycledThread)
local Signal = require(dependencies.Signal)
local Janitor = require(dependencies.Janitor)
local Promise = require(dependencies.Promise)
local t = require(dependencies.t)
local iris = require(dependencies.iris)
local BoatTween = require(dependencies.BoatTween)
local squash = require(dependencies.squash)
local utility = require(root.utility)
local types = require(script.Parent.types)

local network = {}
local outgoingQueue = {}
local incomingQueue = {}
local callQueue = {}
local localQueue = {}
local eventCache = {} :: { types.event }
local playerLimiters = {} :: { types.limiter }

local function createChannel(name)
	local channel = Instance.new("RemoteEvent")
	channel.Name = name
	channel.Parent = ReplicatedStorage
	return channel
end

local channel: RemoteEvent = ReplicatedStorage:FindFirstChild("__stellaNetworking")
	or createChannel("__stellaNetworking")
local coreChannel: RemoteEvent = ReplicatedStorage:FindFirstChild("__stellaNetworkingCore")
	or createChannel("__stellaNetworkingCore")

type connection = typeof(Signal.new():Connect(function() end))
type promise = typeof(Promise.new(function() end))

local EventEmitType = {
	Server = function()
		return {
			kind = "Server",
		}
	end,
	Player = function(player: Player)
		utility.assert(t.instanceIsA("Player")(player))
		return {
			kind = "Player",
			value = { player },
		}
	end,
	AllPlayers = function()
		return {
			kind = "AllPlayers",
			value = Players:GetPlayers(),
		}
	end,
	SomePlayers = function(include: { Player? })
		utility.assert(t.array(include))
		return {
			kind = "SomePlayers",
			clients = include,
		}
	end,
	ExceptSomePlayers = function(exclude: { Player? })
		utility.assert(t.array(exclude))
		local clients = {}
		for _, player in pairs(Players:GetPlayers()) do
			if not table.find(exclude, player) then
				table.insert(clients, player)
			end
		end
		return {
			kind = "ExceptSomePlayers",
			clients = clients,
		}
	end,
}

local function findCall(id: number)
	for _, call in pairs(callQueue) do
		if call.callId == id then
			return call
		end
	end
	return
end

local function removeFromQueue(queue: { [number]: types.packet }, packet: types.packet, message: string?)
	local index = table.find(queue, packet)
	if index then
		if utility.settings.DebugEnabled and utility.settings.NetworkDebugEnabled then
			utility.print("network: removed from queue: " .. (message or "not provied") .. debug.traceback("\n\n", 2))
		end
		table.remove(queue, index)
	end
end

local function validate(self: types.event, packet: types.packet)
	if not self.limiter:check() then
		return false, "Gateway throttling: Event ratelimit"
	end

	self.limiter:increment()

	if packet.originPlayer then
		local playerLimiter = playerLimiters[packet.originPlayer]

		if not playerLimiter:check() then
			return false, "Gateway throttling: Player ratelimit"
		end

		playerLimiter:increment()
	else
		return false, "Origin player is not set, couldn't validate request"
	end
	return true
end

local function addOutgoingQueue(self: types.event, packet: types.packet)
	table.insert(outgoingQueue, packet)
end

local function addOutgoingCallQueue(self: types.event, packet: types.packet)
	table.insert(callQueue, packet)
end

network.log = {}
network.calls = 1

local function safeKick(player: Player, msg: string)
	pcall(function()
		utility.warn(`network > {player.Name} > {msg}`)
		player:Kick(msg)
	end)
end

local stringValue = Instance.new("StringValue")
stringValue.Value = ""
stringValue.Name = "emptyEventIdentifier"

local function makeEvent(self: types.event)
	eventCache[self.identifier] = self
    
	if not channel:FindFirstChild(self.identifier) and self.kind == "Remote" then
		local identifierSV = stringValue:Clone()
		identifierSV.Name = self.identifier
		identifierSV.Parent = channel
	end
end

local function removeEvent(self: types.event)
	local identifierSV = channel:FindFirstChild(self.identifier)
	if identifierSV then
		identifierSV:Destroy()
	end
	eventCache[self.identifier] = nil
end

network.events = eventCache

local function addServerIncomingQueue(player: Player, packet: types.packet)
	-- Reject fabricated packets
	if not t.table(packet) then
		safeKick(
			player,
			"Stella observed an unexpected behaviour, report to the developers if this error persists: (1)"
		)
		return false, 1
	end

	local event = eventCache[packet.identifier]

	if not event then
		utility.warn(`network: {player.Name}: Packet has an unknown receiving end`)
		return false, 4
	end

	packet.originPlayer = player

	-- Gate keeper
	local passed, message = validate(event, packet)

	if not passed then
		utility.warn(`network: {player.Name}: Failed validation: {message}`)
		return false, 5
	end

	if packet.callId then
		if packet.callStatus ~= "WaitingCallReturn" then
			utility.warn("network: call packet dropped because it was sent with an invalid call status")
			return false, 6
		end
		
		if event.callHandler then
			local callPromise = Promise.new(function(resolve)
				resolve({ event.callHandler(packet.originPlayer, unpack(packet.params)) })
			end)
			callPromise:andThen(function(capturedReturn)
				packet.callReturn = capturedReturn
				packet.callStatus = "QueuedOutgoingProcessed"
				table.insert(callQueue, packet)
			end)
			callPromise:catch(function(err)
				packet.callError = err.error
				packet.callStatus = "QueuedOutgoingProcessed"
				table.insert(callQueue, packet)
			end)
		else
			packet.callError = "Event doesn't have a call handler: " .. packet.identifier .. debug.traceback("\n\n")
			packet.callStatus = "QueuedOutgoingProcessed"
			table.insert(callQueue, packet)
		end
	else
		table.insert(incomingQueue, packet)
	end

	return true
end

local function addClientIncomingQueue(packet: types.packet)
	if packet.callId then
		local rootCallPacket = findCall(packet.callId)
		if not rootCallPacket then
			removeFromQueue(
				callQueue,
				rootCallPacket,
				"network: call packet dropped because the root packet cannot be found"
			)
			return
		end
		local event = eventCache[rootCallPacket.identifier]

		if not event then
			removeFromQueue(callQueue, rootCallPacket, `network: Packet has an unknown receiving end`)
			return
		end
		if packet.callStatus ~= "QueuedIncomingProcessed" then
			removeFromQueue(
				callQueue,
				rootCallPacket,
				"network: call packet dropped because it was sent with an invalid call status"
			)
			return
		end

		rootCallPacket.callError = packet.callError
		rootCallPacket.callReturn = packet.callReturn

		if rootCallPacket.callError or not rootCallPacket.callReturn then
			if rootCallPacket.callReject then
				local errMsg = `network: call failed with error ({rootCallPacket.identifier}): \n\n{packet.callError}`
				rootCallPacket.callReject(errMsg)
				removeFromQueue(callQueue, rootCallPacket, `network: call failed with error`)
				return
			else
				removeFromQueue(
					callQueue,
					rootCallPacket,
					`network: call failed with error ({rootCallPacket.identifier}): \n\n{packet.callError}`
				)
				return
			end
		end

		rootCallPacket.callResolve(packet.callReturn and unpack(packet.callReturn))
		rootCallPacket.callStatus = "CallCompleted"

		removeFromQueue(callQueue, rootCallPacket, "Packet is processed")
	else
		local event = eventCache[packet.identifier]

		if not event then
			utility.warn(`network: Packet has an unknown receiving end`)
			return
		end

		table.insert(incomingQueue, packet)
	end

	return true
end

local function start()
	-- Process local events
	-- Process incoming events
	-- Send events in outgoing queue

	local isServer = RunService:IsServer()

	if isServer then
		channel.OnServerEvent:Connect(function(player: Player, packets: { types.packet? })
			--print(packets)
			if not playerLimiters[player] then
				-- Player has not yet loaded
				return
			end
			for _, packet in pairs(packets) do
				addServerIncomingQueue(player, packet)
			end
		end)

		coreChannel.OnServerEvent:Connect(function(player: Player, operation: string, data: {})
			if operation == "clientConnected" then
				if playerLimiters[player] then
					utility.warn(`network > {player.Name} is already connected`)
					return
				end
				if utility.settings.LimitNetworkingRate then
					playerLimiters[player] =
						limiter.new(utility.settings.PlayerNetworkingRPS, utility.settings.PlayerNetworkingRPM)
				else
					playerLimiters[player] = limiter.new(-1, -1) -- no limit
				end
			end
		end)
	else
		channel.OnClientEvent:Connect(function(packets: { types.packet? })
			--print(packets)
			for _, packet in pairs(packets) do
				addClientIncomingQueue(packet)
			end
		end)
		coreChannel:FireServer("clientConnected")
	end

	clock.new(1 / 60, function()
		debug.profilebegin("__stellaNetwork_Processing")

		do
			debug.profilebegin("__stellaNetwork_incomingQueueProcessing")
			-- Processing requests from the client
			if isServer then
				for _, packet in pairs(table.clone(incomingQueue)) do
					local event = eventCache[packet.identifier]

					if not event then
						removeFromQueue(incomingQueue, packet, "Packet has an unknown receiving end")
						continue
					end

					eventCache[packet.identifier].signal:Fire(packet.originPlayer, unpack(packet.params))

					removeFromQueue(incomingQueue, packet, "Packet is processed")
				end
			else
				for _, packet in pairs(table.clone(incomingQueue)) do
					local event = eventCache[packet.identifier]

					if not event then
						removeFromQueue(incomingQueue, packet, "Packet has an unknown receiving end")
						continue
					end

					eventCache[packet.identifier].signal:Fire(unpack(packet.params))

					removeFromQueue(incomingQueue, packet, "Packet is processed")
				end
			end
			debug.profileend()
		end

		do
			debug.profilebegin("__stellaNetwork_outgoingQueueProcessing")

			-- Processing requests from the client
			if isServer then
				for _, packet in pairs(table.clone(outgoingQueue)) do
					if not packet.eventEmitType then
						removeFromQueue(outgoingQueue, packet, "Packet does not have a EventEmitType")
						continue
					end
					if packet.eventEmitType.kind == "Server" then
						removeFromQueue(outgoingQueue, packet, "Packet is NOT expected to have a Server EventEmitType")
						continue
					end

					local event = eventCache[packet.identifier]

					if not event then
						removeFromQueue(outgoingQueue, packet, "Packet has an unknown receiving end")
						continue
					end

					--[[if packet.eventEmitType.kind == "AllPlayers" then
						channel:FireAllClients(packet)
					elseif packet.eventEmitType.kind == "Player" then
						if packet.eventEmitType.value and #packet.eventEmitType.value > 0 then
							channel:FireClient(packet.eventEmitType.value[1])
						end
					elseif
						packet.eventEmitType.kind == "ExceptSomePlayers"
						or packet.eventEmitType.kind == "SomePlayers"
					then
						for _, player in pairs(packet.eventEmitType.value) do
							channel:FireClient(player, packet)
						end
					end

					removeFromQueue(outgoingQueue, packet, "Packet is processed")]]
				end

				-- Send queue over to clients

				local playerReceivePackets = {}

				for player in pairs(playerLimiters) do
					playerReceivePackets[player] = {}
				end
				for _, packet in pairs(table.clone(callQueue)) do
					if packet.callStatus ~= "QueuedOutgoingProcessed" then
						continue
					end
					if not packet.originPlayer then
						removeFromQueue(callQueue, packet, "Packet is missing originPlayer")
					end
					local playerPackets = playerReceivePackets[packet.originPlayer]
					if not playerPackets then
						continue
					end
					packet.callStatus = "QueuedIncomingProcessed"
					packet.eventEmitType = nil -- reduce bytes sent over the remote
					packet.originPlayer = nil
					packet.identifier = nil
					packet.params = nil
					table.insert(playerPackets, packet)
				end
				for _, packet in pairs(outgoingQueue) do
					for _, player in pairs(packet.eventEmitType.value) do
						local playerPackets = playerReceivePackets[player]
						if not playerPackets then
							continue
						end
						packet.eventEmitType = nil -- reduce bytes sent over the remote
						table.insert(playerPackets, packet)
					end
				end
				--print(outgoingQueue, playerReceivePackets[Players:FindFirstChild("averyark")])
				for player, packets in pairs(playerReceivePackets) do
					if #packets < 1 then
						continue
					end
					channel:FireClient(player, packets)
				end
				table.clear(outgoingQueue)
			else
				local packets = {}

				for _, packet in pairs(table.clone(outgoingQueue)) do
					if packet.eventEmitType.kind == "Local" then
						removeFromQueue(outgoingQueue, packet, "Packet is expected to NOT have Local EventEmitType")
						continue
					end
					if packet.eventEmitType.kind ~= "Server" then
						removeFromQueue(
							outgoingQueue,
							packet,
							`Packet is NOT expected to have a {packet.eventEmitType.kind} EventEmitType`
						)
						continue
					end

					local event = eventCache[packet.identifier]

					if not event then
						removeFromQueue(outgoingQueue, packet, "Packet has an unknown receiving end")
						continue
					end

					packet.eventEmitType = nil -- reduce bytes sent over the remote
					table.insert(packets, packet)
					removeFromQueue(outgoingQueue, packet, "Packet is processed")
				end

				for _, packet in pairs(table.clone(callQueue)) do
					if packet.callStatus ~= "QueuedOutgoing" then
						continue
					end
					packet.callStatus = "WaitingCallReturn"
					table.insert(packets, packet)
					removeFromQueue(outgoingQueue, packet, "Packet is processed")
				end
				if #packets > 0 then
					if utility.settings.DebugEnabled and utility.settings.NetworkDebugEnabled then
						table.insert(network.log, { now = DateTime.now(), packets = packets })
					end
					channel:FireServer(packets)
				end
			end
			debug.profileend()
		end
	end)
end

network.start = start
network.makeEvent = makeEvent
network.removeEvent = removeEvent
network.addOutgoingCallQueue = addOutgoingCallQueue
network.addOutgoingQueue = addOutgoingQueue
network.EventEmitType = EventEmitType

return network
