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
	DEBUG_ENABLED = true,
	MODULE_LOAD_ANALYSIS_REPORT = true,
	TEST_MODE = false,
	ADMINISTRATOR = {},

	NETWORK_RPS = 60,
	NETWORK_RPM = -1,
	NETWORK_DEBUG_ENABLED = true,
	NETWORK_LIMIT_RATE = true,

	DATA_SCOPE = "StellaData",
	DATA_TEMPLATE = {},
	DATA_FAIL_FALLBACK_RESOLVER = function(err)
		for _, player in pairs(Players:GetPlayers()) do
			-- Inform the player
		end
		-- Stop new players from joining
		Players.PlayerAdded:Connect(function(player)
			player:Kick(`A fatal datastore incident occurred, please report to the developers: {err}`)
		end)
	end,

	ACTIONS = {},

	UI_SCALE_MODES = {
		[1] = 0.5, -- Mini: 480p
		[2] = 1, -- Small: 720p (Recommended UI development mode, Develop UIs in 1280x720 Emulation)
		[3] = 1.5, -- Medium: 1080p
		[4] = 2, -- Large: 2k
		[5] = 3, -- Mega: 4k
	},
	UI_SCALE_THRESHOLD = {
		[1] = Vector2.new(0, 0), -- At least have a positive screen resolution..
		[2] = Vector2.new(1080, 620),
		[3] = Vector2.new(1720, 980),
		[4] = Vector2.new(2360, 1340),
		[5] = Vector2.new(3640, 2060),
	},
	UI_SCALE_TAG = "AutoScale"
}

export type settings = (typeof(stellaSettingsFallback) & {
	ADMINISTRATOR: {
		{ Type: "UserId", Id: number }
		| { Type: "Group", Id: number, Rank: number? }
		| { Type: "All", State: boolean }
	},
	DATA_TEMPLATE: { [any]: any },
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
