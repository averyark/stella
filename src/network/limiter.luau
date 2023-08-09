local RunService = game:GetService("RunService")
--[[
    FileName    > limiter.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 02/08/2023
--]]

local root = script.Parent.Parent
local dependencies = root.dependencies

local clock = require(script.Parent.clock)
local Signal = require(dependencies.Signal)
local Janitor = require(dependencies.Janitor)
local Promise = require(dependencies.Promise)
local t = require(dependencies.t)
local iris = require(dependencies.iris)
local BoatTween = require(dependencies.BoatTween)
local squash = require(dependencies.squash)

local limiters = {}

local limiter = {}
do
	limiter.__index = limiter

	function limiter.Destroy(self: limiter)
		local index = table.find(limiters, self)
		if index then
			table.remove(limiters, index)
		end
	end

	function limiter.new(maxRPS: number, maxRPM: number)
		local self = setmetatable({}, limiter)

		self.maxRPS = maxRPS
		self.maxRPM = maxRPM
		self.rateLastSecond = 0
		self.rateLastMinute = 0
		self.lastRPSCheck = 0
		self.lastRPMCheck = 0

		table.insert(limiters, self)

		return self
	end

	function limiter.check(self: limiter)
		if self.maxRPM and self.maxRPM >= 0 and self.rateLastMinute > self.maxRPM then
			return false
		end
		if self.maxRPS and self.maxRPS >= 0 and self.rateLastSecond > self.maxRPS then
			return false
		end
		return true
	end

	function limiter.increment(self: limiter)
		self.rateLastMinute += 1
		self.rateLastSecond += 1
	end

	type limiter = typeof(limiter.new(1, 1))
end

do
	clock.new(1 / 60, function()
		local clock = os.clock()
		for _, self in pairs(limiters) do
			if clock - self.lastRPMCheck > 60 then
				self.lastRPMCheck = clock
				self.rateLastMinute = 0
			end
			if clock - self.lastRPSCheck > 1 then
				self.lastRPSCheck = clock
				self.rateLastSecond = 0
			end
		end
	end)
end

return {
	new = limiter.new,
}
