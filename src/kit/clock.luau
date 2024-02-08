-- Derived from Red's Clock

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local clock = {}
do
	clock.__index = clock

	function clock.new(interval: number, callback: () -> ())
		local self = setmetatable({}, clock)

		self.interval = interval
		self.callback = callback
		self.dt = 0
		self.paused = false

		self.connection = RunService.Heartbeat:Connect(function(dt)
			self:advance(dt)
		end)

		return self
	end

	function clock.pause(self: Clock)
		if self.connection then
			self.paused = true
			self.connection:Disconnect()
		end
	end

	function clock.resume(self: Clock)
		if self.connection.Connected then
			return
		end

		self.paused = false

		self.connection = RunService.Heartbeat:Connect(function(dt)
			self:advance(dt)
		end)
	end

	function clock.advance(self: Clock, dt: number)
		self.dt += dt

		if self.dt >= self.interval * 10 then
			local skipped = math.floor(self.dt / self.interval)
			self.dt -= skipped * self.interval

			return
		end

		if self.dt >= self.interval then
			self.dt -= self.interval
			self.callback(dt)
		end
	end

	function clock.Destroy(self: Clock)
		if self.connection then
			self.connection:Disconnect()
			self.connection = nil
		end
	end

	export type Clock = typeof(clock.new(...))
end

return {
	new = clock.new,
}