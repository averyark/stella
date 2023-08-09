local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent.Parent
local dependencies = root.dependencies

local BoatTween = require(dependencies.BoatTween)
local utility = require(root.utility)

type easingStyles =
	"RidiculousWiggle"
	| "Quart"
	| "Spring"
	| "ExitExpressive"
	| "SoftSpring"
	| "Sharp"
	| "Bounce"
	| "Back"
	| "UWPAccelerate"
	| "Elastic"
	| "StandardProductive"
	| "Quad"
	| "EntranceExpressive"
	| "Expo"
	| "Circ"
	| "Smooth"
	| "EntranceProductive"
	| "Acceleration"
	| "Sine"
	| "FabricDecelerate"
	| "Standard"
	| "FabricStandard"
	| "ExitProductive"
	| "Quint"
	| "FabricAccelerate"
	| "MozillaCurve"
	| "Linear"
	| "Cubic"
	| "RevBack"
	| "Smoother"
	| "Deceleration"
	| "StandardExpressive"

type easingDirections = "In" | "Out" | "InOut" | "OutIn"

local tween = {}
local groups = {}

-- tweens a instance once
local function tweenInstance(
	object: Instance,
	goals: { [string]: any },
	duration: number?,
	easingStyle: easingStyles?,
	easingDirection: easingDirections?
)
	local _tween = BoatTween:Create(object, {
		Time = duration or 0.3,
		EasingStyle = easingStyle or "Cubic",
		EasingDirection = easingDirection or "Out",
		Goal = goals,
	})

	_tween:Play()

	coroutine.resume(coroutine.create(function()
		_tween.Completed:Wait()
		_tween:Destroy()
		_tween = nil
	end))

	return _tween
end

tween.duration = function(time: number)
	return {type = "time", value = time}
end
tween.easingStyle = function(style: easingStyles)
	return {type = "style", value = style}
end
tween.easingDirection = function(direction: easingDirections)
	return {type = "direction", value = direction}
end

local class = {}
class.__index = class

function class.Destroy(self: sequenceClass)
	for _, object in pairs(self.tween) do
		if object.Destory then
			object.Destory()
		end
	end
	table.clear(self.tween)
end

function class.stop(self: sequenceClass)
	for _, tween in pairs(self.tween) do
		if tween.Destroy then
			tween:Destroy()
			table.remove(self.tween, table.find(self.tween, tween))
		end
	end
	return self
end

function class.play(self: sequenceClass)
	if self.group then
		for _, seq in pairs(self.group) do
			seq:stop()
		end
	end
	for _, seq in pairs(self.sequenceTable) do
		for instance, tweenTable in pairs(seq) do
			if typeof(instance) == "Instance" then
				local _tween = BoatTween:Create(instance, {
					Time = seq.duration or 0.15,
					EasingStyle = seq.style or "Sine",
					EasingDirection = seq.direction or "Out",
					Goal = tweenTable,
				})
				_tween:Play()
				table.insert(self.tween, _tween)
			end
		end
	end
	return self
end

function class.wait(self: sequenceClass)
	self.tween[1].Completed:Wait()
	return self
end

function class.setGroup(self: sequenceClass, group: string)
	if not groups[group] then
		groups[group] = {}
	end
	self.group = groups[group]
	table.insert(groups[group], self)
	return self
end

local function sequence(
	...: { {[Instance | number]: { [string ]: any? }? | typeof(tween.duration(1))? | typeof(tween.easingStyle("Sine"))? | typeof(tween.easingDirection("Out"))?} }
)
	local self = setmetatable({}, class)

	self.sequenceTable = {...}
	self.tween = {}
	self.group = nil :: {}?

	local duration
	local easingStyle
	local easingDirection

	for _, seq in pairs(self.sequenceTable) do
		for _, result in pairs(table.clone(seq)) do
			if result.type == "time" then 
				seq.duration = result.value
			elseif result.type == "style" then
				result.style = result.value
			elseif result.type == "direction" then
				result.direction = result.value 
			end
		end
	end

	return self
end

type sequenceClass = typeof(sequence({}))

tween.instance = tweenInstance
tween.sequence = sequence

tween.instance = tweenInstance

return tween
