local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ACTIONS = require(script.ACTIONS)
local DATA_TEMPLATE = require(script.DATA_TEMPLATE)

local actions = {
    TestAction = 1,
    TestAction2 = 2,
}

return {
    DEBUG_ENABLED = true,
	MODULE_LOAD_ANALYSIS_REPORT = true,
	TEST_MODE = false,
	ADMINISTRATOR = {
        { Type = "UserId", Id = 540209459 }
    },

	NETWORK_RPS = 60,
	NETWORK_RPM = -1,
	NETWORK_DEBUG_ENABLED = true,
	NETWORK_LIMIT_RATE = true,

	DATA_SCOPE = "StellaData",
	DATA_TEMPLATE = DATA_TEMPLATE,
	DATA_FAIL_FALLBACK_RESOLVER = function(err)
		for _, player in pairs(Players:GetPlayers()) do
			-- Inform the player
		end
		-- Stop new players from joining
		Players.PlayerAdded:Connect(function(player)
			player:Kick(`A fatal datastore incident occurred, please report to the developers: {err}`)
		end)
	end,

	ACTIONS = ACTIONS,

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

