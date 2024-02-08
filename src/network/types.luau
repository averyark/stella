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
	clock: number
}
export type event = {
	Identifier: string,
	Kind: EventType,
	Limiter: limiter,

	Limit: (number, number) -> (),
	Emit: (event, ...any) -> (),
	EmitAll: (event, ...any) -> (),
	EmitExcept: (event, exceptions: {Player}, ...any) -> (),
	EmitOnly: (event, inclusion: {Player}, ...any) -> (),

	On: <Arguments>(event, callback: (...Arguments) -> ()) -> connection,
	Call: (event, ...any) -> promise,
	OnCall: <Parameter, Return>(self: event, callback: (...Parameter) -> ...Return) -> (),
}
export type value = {
	Identifier: string,
	Limiter: limiter,
	Value: any,
	OldValue: any,
	InitialCall: boolean,
	OnValueChanged: signal,

	Listen: <Value>(value, callback: (newValue: Value, oldValue: Value) -> ()) -> (),
	Set: <Value>(value, Value) -> (),
	Get: <Value>(value) -> Value,
	Limit: (number, number) -> (),
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
