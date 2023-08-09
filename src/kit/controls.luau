--!nonstrict
--[[
    FileName    > controls.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 12/06/2023
--]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local root = script.Parent.Parent

local dependencies = root.dependencies
local number = require(root.kit.number)
local Promise = require(dependencies.Promise)
local Signal = require(dependencies.Signal)
local Janitor = require(dependencies.Janitor)
local t = require(dependencies.t)

local utility = require(root.utility)

local player = Players.LocalPlayer
local controls = {}

local actionSignals = {}

controls.focusing = nil :: string?
controls.focusChanged = Signal.new()

local function unfocus()
	controls.focusing = utility.settings.ControlsDefaultFocus
	controls.focusChanged:Fire(controls.focusing)
end

local function focus(category: string)
	controls.focusing = category
	controls.focusChanged:Fire(controls.focusing)
end

local function onAction(action: number): signal
    local signal = actionSignals[action]
	if not signal then
        
		return utility.warn("controls: invalid action:" .. action)
	end
	return signal
end

local function fireAction(action: number, info, input: InputObject)
    local signal = actionSignals[action]
    if not signal then
        utility.warn("controls: invalid action:" .. action)
		return
	end
	if info.category ~= "all" and info.category ~= nil then
		if typeof(info.category) == "table" then
			if not table.find(info.category, controls.focusing) then
				return
			end
			return
		else
			if info.category ~= controls.focusing then
				return
			end
		end
	end
	
	signal:Fire(input)
end

export type controlInfo = {
    state: Enum.UserInputState?,
    action: number,
    kind: controlKind,
    value: any,
    category: string,
}

type controlKind = "UserInputType" | "KeyCode" | "MultiKeycode"
type signal = typeof(Signal.new())

local function processInput(input: InputObject, info: controlInfo)
	if input.UserInputState ~= info.state and info.state ~= nil then
		return
	end

	if info.kind == "KeyCode" then
		if input.KeyCode == info.value then
			fireAction(info.action, info, input)
		end
		return
	elseif info.kind == "MultiKeycode" then
		for _, keycode in pairs(info.value) do
			if not UserInputService:IsKeyDown(keycode) then
				return
			end
		end
		fireAction(info.action, info, input)
		return
	elseif info.kind == "UserInputType" then
		if input.UserInputType == info.value then
			fireAction(info.action, info, input)
		end
		return
	end
end

function controls.start()
	local function process(input)
		if UserInputService.KeyboardEnabled then
			for _, info in pairs(utility.settings.ControlMap["pc"]) do
				processInput(input, info)
			end
		end
		if UserInputService.TouchEnabled then
			for _, info in pairs(utility.settings.ControlMap["mobile"]) do
				processInput(input, info)
			end
		end
		if UserInputService.GamepadEnabled then
			for _, info in pairs(utility.settings.ControlMap["xbox"]) do
				processInput(input, info)
			end
		end
	end

    for actionName, actionId in pairs(utility.settings.ControlActions) do
        actionSignals[actionId] = Signal.new()
    end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		process(input)
	end)
	UserInputService.InputChanged:Connect(function(input, processed)
		if processed then
			return
		end
		process(input)
	end)
	UserInputService.InputEnded:Connect(function(input, processed)
		if processed then
			return
		end
		process(input)
	end)
end

controls.unfocus = unfocus
controls.focus = focus
controls.onAction = onAction

return controls
