local root = script.Parent.Parent
local dependencies = root.dependencies

local Signal = require(dependencies.Signal)
local Janitor = require(dependencies.Janitor)
local Promise = require(dependencies.Promise)
local t = require(dependencies.t)
local iris = require(dependencies.iris)
local BoatTween = require(dependencies.BoatTween)
local squash = require(dependencies.squash)

type signal = typeof(Signal.new())
type connection = typeof(Signal.new():Connect(function() end))
type promise = typeof(Promise.new(function() end))

export type packet = {
	identifier: string,
	originPlayer: Player?,
	params: { [number]: any? },
	eventEmitType: {
		kind: EventEmitType,
		value: { Player? }?,
		[any]: any?,
	}?,
	callId: number?,
	callReturn: { [number]: any? }?,
	callResolve: (...any) -> ()?,
	callReject: (...any) -> ()?,
	callStatus: CallStatus?,
	callError: string?,
}
export type event = {
	identifier: string,
	kind: EventType,
	limiter: limiter,

	emit: (event, ...any) -> (),
	emitAll: (event, ...any) -> (),
	emitExcept: (event, exceptions: {Player}, ...any) -> (),
	emitOnly: (event, inclusion: {Player}, ...any) -> (),

	on: <Arguments>(event, callback: (...Arguments) -> ()) -> connection,
	call: (event, ...any) -> promise,
	onCall: <Parameter, Return>(self: event, callback: (...Parameter) -> ...Return) -> (),
}
export type value = {
	identifier: string,
	limiter: limiter,
	value: any,

	observe: <Value>(value, callback: (newValue: Value, oldValue: Value) -> ()) -> (),
	set: <Value>(value, Value) -> (),
	get: <Value>(value) -> Value,
}
export type limiter = {
	maxRPS: number,
	maxRPM: number,
	increment: (limiter) -> (),
	check: (limiter) -> boolean,
}

export type CallStatus =
	"QueuedOutgoing"
	| "QueuedIncoming"
	| "WaitingCallReturn"
	| "QueuedOutgoingProcessed"
	| "QueuedIncomingProcessed"
	| "CallCompleted"
export type EventType = "Local" | "Remote" | "ReplicatedRemote"
export type EventEmitType = "Server" | "Player" | "AllPlayers" | "SomePlayers" | "ExceptSomePlayers"

return {}
