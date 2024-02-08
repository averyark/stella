--!nonstrict
--[[
    FileName    > debugger.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 22/01/2024
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent.Parent
local dependencies = root.dependencies

local actions = require(script.Parent.actions)
local utility = require(ReplicatedStorage.Packages.stella.utility)
local iris = require(dependencies.iris)
local t = require(dependencies.t)
local Signal = require(dependencies.Signal)

local debugger = {}

type iris = typeof(iris)

local widgets = {}

local function sort(a, b)
	return a.priority < b.priority
end

function debugger.Append(callback: (iris: iris) -> (), priority: number?)
	table.insert(widgets, {
		priority = priority or #widgets,
		callback = callback,
	})
	table.sort(widgets, sort)
end

local function isAdministrator(player: Player)
	for _, data in utility.settings.ADMINISTRATOR do
		if data.Kind == "All" then
			if data.State == false then
				return false
			elseif data.State == true then
				return true
			end
		elseif data.Kind == "UserId" then
			if player.UserId == data.Id then
				return true
			end
		elseif data.Kind == "Group" then
			local rank = player:GetRankInGroup(data.Id)
			if rank >= data.Rank then
				return true
			end
		end
	end
	return false
end

if Players.LocalPlayer then
	if utility.settings.DEBUG_ENABLED and isAdministrator(Players.LocalPlayer) then
		local windowSizeState = iris.State(Vector2.new(700, 400))
		local isOpenedState = iris.State(false)

		local isOpened = false

		iris.Init()

		iris:Connect(function()
			iris.Window({"Stella Debug Panel" }, {isOpened = isOpenedState, size = windowSizeState})
			--  We don't need to run the widgets if the panel is not open

			if not isOpened then
				iris.End()
				return
			end

			-- Assume the array is sorted

			for _, widget in widgets do
				widget.callback()
			end

			iris.End()
		end)

		actions
			.new("openDebugPanel")
			:SetPrimitiveInput("keyboard", { Enum.KeyCode.LeftShift, Enum.KeyCode.B })
			:SetPrimitiveInput("console", { Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonX })
			:SetPrimitiveInput("mobile", actions.Button(UDim2.new(1, -95, 1, -170), "", "Debug Panel"))
            :ConnectFiltered(function(...)
				isOpened = not isOpened
				isOpenedState:set(isOpened)
			end, Enum.UserInputState.Begin)
	end
end

return debugger
