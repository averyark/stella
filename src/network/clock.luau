-- Derived from Red's Clock

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = script.Parent.Parent
local dependencies = root.dependencies

local utility = require(root.utility)

local clock = {}
do
	clock.__index = clock

	function clock.new(interval: number, callback: () -> ())
		local self = setmetatable({}, clock)

		self.interval = interval
		self.callback = callback
		self.dt = 0

		self.connection = RunService.Heartbeat:Connect(function(dt)
			self:advance(dt)
		end)

		return self
	end

	function clock.pause(self: Clock)
		if self.Connection then
			self.Connection:Disconnect()
		end
	end

	function clock.resume(self: Clock)
		if self.connection.Connected then
			return
		end

		self.connection = RunService.Heartbeat:Connect(function(dt)
			self:advance(dt)
		end)
	end

	function clock.advance(self: Clock, dt: number)
		self.dt += dt

		if self.dt >= self.interval * 10 then
			local skipped = math.floor(self.dt / self.interval)
			self.dt -= skipped * self.interval

			if utility.settings.NETWORK_DEBUG_ENABLED and utility.settings.DEBUG_ENABLED then
				utility.warn("clock > Clock is falling behind! Skipped " .. skipped .. " intervals")
			end

			return
		end

		if self.dt >= self.interval then
			self.dt -= self.interval
			self.callback()
		end
	end

	export type Clock = typeof(clock.new(...))
end

return {
	new = clock.new,
}
