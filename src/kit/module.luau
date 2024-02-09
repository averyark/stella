--!nonstrict
--[[
    FileName    > module.luau
    Author      > AveryArk
    Contact     > Twitter: https://twitter.com/averyark_
    Created     > 01/06/2023
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = script.Parent.Parent

local dependencies = root.dependencies
local number = require(root.kit.number)
local Promise = require(dependencies.Promise)
local Signal = require(dependencies.Signal)
local Janitor = require(dependencies.Janitor)
local t = require(dependencies.t)

local utility = require(root.utility)

local module = {}

local clientModules = {}
local sharedModules = {}

local clientModuleContainer

module.setModuleFolder = function(container: Instance)
	local promises = {}
	for _, module in pairs(container:GetDescendants()) do
		if module:IsA("ModuleScript") then
			local modulepath: any = module :: any
			table.insert(
				promises,
				Promise.new(function(resolve)
					resolve(require(module))
				end):catch(function(err)
					utility.warn(`{module.Name} > initialization failed with error:\n\n {err.error}`)
				end)
			)
		end
	end

	Promise.all(promises):andThen(function()
		clientModuleContainer = container
	end)
end

module.new = function<m>(
	identifier: string,
	methods: m & {
		[any]: any,
		load: () -> ()?,
		preload: () -> ()?,
	}
)
	local metatable = {}

	metatable.identifier = identifier

	methods.__index = methods

	table.insert(clientModules, {
		metatable = metatable,
		methods = methods,
	})

	return setmetatable(metatable, methods) :: typeof(metatable) & m
end

module.info = {}

module.start = function()
	local waitingClock = os.clock()
	local warned = false

	repeat
		task.wait(0.1)
		if os.clock() - waitingClock >= 5 and not warned then
			utility.warn("Did you forget to set the module container?")
			warned = true
		end
	until clientModuleContainer

	local bench = {
		load = {},
		preload = {},
	}
	local errored = {
		load = {},
		preload = {},
	}
	local attempts = {
		load = {},
		preload = {},
	}
	for _, module in pairs(clientModules) do
		if module.methods.preload then
			table.insert(attempts.preload, module.metatable.identifier)
			local beginClock = os.clock()
			Promise.new(function(resolve)
				module.methods.preload()
				table.insert(bench.preload, {
					identifier = module.metatable.identifier,
					bench = os.clock() - beginClock,
				})
				resolve()
			end)
				:catch(function(err)
					utility.warn(`Module errored while preloading -> ({module.metatable.identifier}) \n\n {err.trace}`)
					table.insert(errored.preload, {
						identifier = module.metatable.identifier,
						err = err,
					})
				end)
				:await()
		end
	end
	for _, module in pairs(clientModules) do
		if module.methods.load then
			table.insert(attempts.load, module.metatable.identifier)
			local moduleErroredOnPreload = false
			for _, _module in pairs(errored.preload) do
				if _module.identifier == module.metatable.identifier then
					moduleErroredOnPreload = true
				end
			end
			if moduleErroredOnPreload then
				continue
			end
			local beginClock = os.clock()
			Promise.new(function(resolve)
				module.methods.load()
				table.insert(bench.load, {
					identifier = module.metatable.identifier,
					bench = os.clock() - beginClock,
				})
				resolve()
			end):catch(function(err)
				utility.warn(`Module errored while loading -> ({module.metatable.identifier}) \n\n {err.trace}`)
				table.insert(errored.load, {
					identifier = module.metatable.identifier,
					err = err,
				})
			end)
		end
	end

	if utility.settings.DEBUG_ENABLED then
		module.info.bench = bench
		module.info.attempts = attempts
		module.info.errored = errored
	end

	if utility.settings.MODULE_LOAD_ANALYSIS_REPORT then
		local benchPreloadString = ""
		for _, preloadBench in pairs(bench.preload) do
			benchPreloadString =
				`{benchPreloadString}\n\t[{preloadBench.identifier}]: ({number.decimalUnitFormat(preloadBench.bench)})`
		end
		local benchLoadString = ""
		for _, loadBench in pairs(bench.load) do
			benchLoadString =
				`{benchLoadString}\n\t[{loadBench.identifier}]: ({number.decimalUnitFormat(loadBench.bench)})`
		end

		--[[utility.print(
			`Client Module Analysis Report:\n{string.rep("-", 30)}\nPreload queries: ({#attempts.preload}), Successful preloads: ({#attempts.preload - #errored.preload}), Failed preloads: ({#errored.preload}), Preload benchmarks:{benchPreloadString}\n{string.rep(
				"-",
				30
			)}\nLoad queries: ({#attempts.load}), Successful loads: ({#attempts.load - #errored.load}), Failed loads: ({#errored.load}), Load benchmarks:{benchLoadString}\n{string.rep(
				"-",
				30
			)}`
		)]]
	end
end

return module
