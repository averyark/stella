local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent
local dependencies = root.dependencies

local number = require(root.kit.number)
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

local function typeStringTransform(value: any, sameLine: boolean?)
	local newLine = sameLine and "" or "\n"
	local space = sameLine and " " or "    "
	local valueType = typeof(value)

	local function numberTransformation(n)
		local rounded = math.round(n * 10000) / 10000
		if math.abs(rounded) == 0 then
			return 0
		end
		return if rounded > 999 then number.commaFormat(rounded) else tostring(rounded)
	end

	local function tableTranslate(key, val, i, cache, str, nocomma)
		str = str and str .. "{" or str
		if table.find(cache, val) then
			return "[REC_T_REF_1]"
		end
		table.insert(cache, val)
		i = i and i + 1 or (sameLine and 0 or 1)
		for k, v in pairs(val) do
			if table.find(cache, v) then
				return "[REC_T_REF_2]"
			end
			if typeof(v) == "table" then
				str = `{str}{nocomma and "" or ","}{newLine}{(space):rep(i or 0)}[{typeStringTransform(k)}] = {tableTranslate(
					k,
					v,
					i,
					cache,
					"",
					true
				)}`
				nocomma = false
			else
				str = if not str
					then "{" .. newLine .. `{(space):rep(i or 0)}[{typeStringTransform(k)}] = {typeStringTransform(v)}`
					else `{str}{nocomma and "" or ","}{newLine}{(space):rep(i or 0)}[{typeStringTransform(k)}] = {typeStringTransform(
						v
					)}`
				nocomma = false
			end
		end
		if not str then
			str = "{}"
		else
			str = str .. `{newLine}{(space):rep(i - 1 or 0)}}`
		end
		task.wait()
		return str
	end

	if valueType == "table" then
		return tableTranslate("", value, nil, {}, "", true)
	elseif valueType == "string" then
		return `"{value}"`
	elseif valueType == "number" then
		return numberTransformation(value)
	elseif valueType == "Vector3" then
		local x, y, z = value.X, value.Y, value.Z
		return `Vector3({numberTransformation(x)}, {numberTransformation(y)}, {numberTransformation(z)})`
	elseif valueType == "function" then
		return "function"
	elseif valueType == "Instance" then
		return `(class: {value.ClassName})[{value.Name})]`
	end
	return tostring(value)
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
	ADMINISTRATOR = {} :: {
		{ Kind: "UserId", Id: number }
		| { Kind: "Group", Id: number, Rank: number? }
		| { Kind: "All", State: boolean }
	},

	NETWORK_RPS = 60,
	NETWORK_RPM = -1,
	NETWORK_DEBUG_ENABLED = false,
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
	UI_SCALE_TAG = "AutoScale",

	TAGS = {
			
	}
}

export type settings = (typeof(stellaSettingsFallback) & {
	--[[ADMINISTRATOR: {
		{ Kind: "UserId", Id: number }
		| { Kind: "Group", Id: number, Rank: number? }
		| { Kind: "All", State: boolean }
	},]]
	DATA_TEMPLATE: { [any]: any },
})?

utility.settings = nil :: settings

utility.settings = require(ReplicatedStorage["STELLA_CONFIG"])

utility.print = makeStellaPrint
utility.warn = makeStellaWarn
utility.assert = makeStellaAssert
utility.error = makeStellaError
utility.isKind = isKind
utility.iris = iris
utility.typeStringTransform = typeStringTransform

return utility
