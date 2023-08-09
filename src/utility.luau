local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent
local dependencies = root.dependencies

local Signal = require(dependencies.Signal)
local Janitor = require(dependencies.Janitor)
local Promise = require(dependencies.Promise)
local t = require(dependencies.t)
local iris = require(dependencies.iris)
local BoatTween = require(dependencies.BoatTween)
local squash = require(dependencies.squash)

local utility = {}

local function makeStellaWarn(...: string)
	local message = table.concat({ ... }, "")
	warn(`[stella]: warn > {message} {debug.traceback("\n\n", 2)}`)
end

local function makeStellaPrint(...: string)
	local message = table.concat({ ... }, "")
	print(`[stella]: print > {message}`)
end

local function makeStellaAssert(condition: boolean, ...: string)
	local message = table.concat({ ... }, "")
	assert(condition, message)
end

local function makeStellaError(level: number, ...: string)
	local message = table.concat({ ... }, "")
	error(message, level)
end

local function isKind(a: { kind: string, [any]: any }, b: string)
	if not t.table(a) or not t.string(b) then
		return false
	end
	if a.kind == nil or b == nil then
		return false
	end
	if a.kind ~= b then
		return false
	end
	return true
end

local stellaSettingsFallback = {
	DataScope = "StellaData",

	PlayerNetworkingRPS = 90,
	PlayerNetworkingRPM = -1,

	UIDevelopmentResolution = Vector2.new(1280, 720),

	DebugEnabled = true, -- Master Control
	NetworkDebugEnabled = true,
	ModuleLoadAnalysisReport = true,
	TestMode = false,
	LimitNetworkingRate = true,

	Whitelisted = {},
	DataTemplate = {},
	ControlActions = {},
	ControlMap = {
		["pc"] = {},
		["xbox"] = {},
		["mobile"] = {},
	},
	ControlsDefaultFocus = "movement",

	DatastoreFailureFallback = function(err)
		for _, player in pairs(Players:GetPlayers()) do
			-- Inform the player
		end
		-- Stop new players from joining
		Players.PlayerAdded:Connect(function(player)
			player:Kick(`A fatal datastore incident occurred, please report to the developers: {err}`)
		end)
	end,
}

export type settings = (typeof(stellaSettingsFallback) & {
	Whitelisted: {
		{ Type: "UserId", Id: number }
		| { Type: "Group", Id: number, Rank: number? }
		| { Type: "All", State: boolean }
	},
	DataTemplate: { [any]: any },
})?

utility.settings = nil :: settings

do
	if ReplicatedStorage:FindFirstChild("__stella") then
		utility.settings = require(ReplicatedStorage:FindFirstChild("__stella") :: ModuleScript)
	else
		makeStellaWarn("critical error > The \"__stella\" modulescript is required for the stella framework to run")
	end
end

utility.print = makeStellaPrint
utility.warn = makeStellaWarn
utility.assert = makeStellaAssert
utility.error = makeStellaError
utility.isKind = isKind

return utility
