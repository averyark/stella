local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = script
local dependencies = root.dependencies
local kit = root.kit

local ROOT_CONFIG = ReplicatedStorage:FindFirstChild("STELLA_CONFIG")
local __stella = require(ROOT_CONFIG)

local Signal = require(dependencies.Signal)
local Janitor = require(dependencies.Janitor)
local Promise = require(dependencies.Promise)
local t = require(dependencies.t)
local iris = require(dependencies.iris)
local BoatTween = require(dependencies.BoatTween)
local squash = require(dependencies.squash)

local value = require(script.network.value)
local utility = require(root.utility)
local uiAutoScale = if RunService:IsClient() then require(kit.uiAutoScale) else nil
local number = require(kit.number)
local tween = require(kit.tween)
local module = require(kit.module)
local array = require(kit.array)
local actions = require(kit.actions)
local data = require(kit.data)
local network = require(root.network)
local debugger = require(kit.debugger)
local tag = require(kit.tag)

local stella = {}

local stellaStartupPromise = nil :: typeof(Promise.new(function() end))?

local function typeStringTransform(value: any, sameLine: boolean?)
	local newLine = not sameLine and "" or "\n"
	local valueType = typeof(value)

	local function numberTransformation(number)
		local rounded = math.round(number * 10000) / 10000
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
		i = i and i + 1 or 1
		for k, v in pairs(val) do
			if table.find(cache, v) then
				return "[REC_T_REF_2]"
			end
			if typeof(v) == "table" then
				str = `{str}{nocomma and "" or ","}{newLine}{("    "):rep(i or 0)}[{typeStringTransform(k)}] = {tableTranslate(
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
					then "{" .. newLine .. `{("    "):rep(i or 0)}[{typeStringTransform(k)}] = {typeStringTransform(v)}`
					else `{str}{nocomma and "" or ","}{newLine}{("    "):rep(i or 0)}[{typeStringTransform(k)}] = {typeStringTransform(
						v
					)}`
				nocomma = false
			end
		end
		if not str then
			str = "{}"
		else
			str = str .. `{newLine}{("    "):rep(i - 1 or 0)}}`
		end
		task.wait()
		return str
	end

	if valueType == "table" then
		return tableTranslate("", value, 0, {}, "", true)
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

local function start()
	if stellaStartupPromise then
		return stellaStartupPromise
	end

	stellaStartupPromise = Promise.new(function(resolve, reject)
		if RunService:IsClient() then
			--[[iris.Init()

            iris:Connect(function() 
                local windowSize = iris.State(Vector2.new(350, 300))
        
                iris.Window({"Stella Framework Runtime Info"}, {size = windowSize})
        
                    local rollingDT = iris.State(0)
                    local lastT = iris.State(os.clock())
        
                    local t = os.clock()
                    local dt = t - lastT.value
                    rollingDT.value += (dt - rollingDT.value) * 0.2
                    lastT.value = t
                    iris.Text({string.format("Average %.3f ms/frame (%.1f FPS)", rollingDT.value*1000, 1/rollingDT.value)})
                iris.End()
            end)]]
			repeat
				task.wait()
			until ROOT_CONFIG:FindFirstChild("coreModulesLoaded")

			network.start()
			data.start()
			actions.start()
			module.start()
			uiAutoScale.start()
			tag.start()

			local serverBench = {} :: typeof(module.info)

			if utility.settings.DEBUG_ENABLED then
				debugger.Append(function()
					iris.CollapsingHeader({ "Module analysis" })
					do
						iris.Text("Client Module Load-time Analysis")
						iris.Separator()
						iris.Text({
							`Preload queries: {#module.info.attempts.preload} Load queries: {#module.info.attempts.load}`,
						})
						iris.Text({
							`Failed preload queries: {#module.info.errored.preload} Failed load queries: {#module.info.errored.load}`,
						})

						local merge = {}

						for _, bench in pairs(module.info.bench.preload) do
							merge[bench.identifier] = {
								preload = bench.bench,
							}
						end
						for _, bench in pairs(module.info.bench.load) do
							local tb = merge[bench.identifier]
							if tb then
								tb.load = bench.bench
							else
								merge[bench.identifier] = {
									load = bench.bench,
								}
							end
						end

						iris.Table({ 3 })
							iris.NextRow()
								iris.Text("Module identifier")
								iris.NextColumn()
								iris.Text("Preload bench")
								iris.NextColumn()
								iris.Text("Load bench")
							iris.NextRow()
							for identifier, bench in pairs(merge) do
								iris.NextColumn()
								iris.Text({ identifier })
								iris.NextColumn()
								if bench.preload then
									iris.Text({ number.decimalUnitFormat(bench.preload) })
								else
									iris.Text({ "" })
								end
								iris.NextColumn()
								if bench.load then
									iris.Text({ number.decimalUnitFormat(bench.load) })
								else
									iris.Text({ "" })
								end
								iris.NextRow()
							end
						iris.End()

						iris.Text({
							`Observed startup errors ({#module.info.errored.preload + #module.info.errored.load})`,
						})
						iris.Separator()
						for _, value in pairs(module.info.errored.preload) do
							iris.TextWrapped({
								`[{value.identifier}]: Error occurred at preload \n\n {value.err.error}`,
								Color3.fromRGB(255, 68, 68),
							})
						end
						for _, value in pairs(module.info.errored.load) do
							iris.TextWrapped({
								`[{value.identifier}]: <font color="rgb(255, 68, 68)">Error occurred at load \n\n {value.err.error}</font>`,
							})
						end

						iris.Separator()
					end
					if serverBench.attempts then
						do
							iris.Text("Server Module Load-time Analysis")
							iris.Separator()

							iris.Text({
								`Preload queries: {#serverBench.attempts.preload} Load queries: {#serverBench.attempts.load}`,
							})
							iris.Text({
								`Failed preload queries: {#serverBench.errored.preload} Failed load queries: {#serverBench.errored.load}`,
							})

							local merge = {}

							for _, bench in pairs(serverBench.bench.preload) do
								merge[bench.identifier] = {
									preload = bench.bench,
								}
							end
							for _, bench in pairs(serverBench.bench.load) do
								local tb = merge[bench.identifier]
								if tb then
									tb.load = bench.bench
								else
									merge[bench.identifier] = {
										load = bench.bench,
									}
								end
							end

							iris.Table({ 3 })
							iris.NextRow()
							iris.Text("Module identifier")
							iris.NextColumn()
							iris.Text("Preload bench")
							iris.NextColumn()
							iris.Text("Load bench")
							iris.NextRow()
							for identifier, bench in pairs(merge) do
								iris.NextColumn()
								iris.Text({ identifier })
								iris.NextColumn()
								if bench.preload then
									iris.Text({ number.decimalUnitFormat(bench.preload) })
								else
									iris.Text({ "" })
								end
								iris.NextColumn()
								if bench.load then
									iris.Text({ number.decimalUnitFormat(bench.load) })
								else
									iris.Text({ "" })
								end
								iris.NextRow()
							end
							iris.End()

							iris.Text({
								`Observed startup errors ({#serverBench.errored.preload + #serverBench.errored.load})`,
							})
							iris.Separator()
							for _, value in pairs(serverBench.errored.preload) do
								iris.TextWrapped({
									`[{value.identifier}]: Error occurred at preload \n\n {value.err.error}`,
									Color3.fromRGB(255, 68, 68),
								})
							end
							for _, value in pairs(serverBench.errored.load) do
								iris.TextWrapped({
									`[{value.identifier}]: <font color="rgb(255, 68, 68)">Error occurred at load \n\n {value.err.error}</font>`,
								})
							end

							iris.Separator()
						end
					end
					iris.End()

					iris.CollapsingHeader({ "Action Controls" })
					iris.SeparatorText({ "Actions" })
					for _, action in actions.Objects do
						local isRootEnabled = action.Enabled and action.Loaded and (not action.Category or actions.IsCategoryActive(action.Category))
						iris.Tree({`id: {action.Id}`})
							iris.SeparatorText("Metadata")
							iris.Table({ 2 })
								iris.Text("Index")
								iris.NextColumn()
								iris.Text("Value")
								iris.NextColumn()
									iris.Text({"Tags"})
									iris.NextColumn()
									iris.Text(action.Category or "")
								iris.NextColumn()
									iris.Text({"Enabled"})
									iris.NextColumn()
									iris.Text({tostring(action.Enabled), [iris.Args.Text.Color]= action.Enabled and Color3.new(0,1,0) or action.Enabled and Color3.new(1,0,0)})
								iris.NextColumn()
									iris.Text({"Loaded"})
									iris.NextColumn()
									iris.Text({tostring(action.Loaded), [iris.Args.Text.Color]= action.Loaded and Color3.new(0,1,0) or action.Enabled and Color3.new(1,0,0)})
								iris.NextColumn()
									iris.Text({"IsActivated"})
									iris.NextColumn()
									iris.Text({tostring(action.IsActivated), [iris.Args.Text.Color]= action.IsActivated and Color3.new(0,1,0) or action.Enabled and Color3.new(1,0,0)})
								iris.NextColumn()
							iris.End()
							iris.SeparatorText("Inputs")
							iris.Table({ 4 })
								iris.Text("Identifier")
								iris.NextColumn()
								iris.Text("Input")
								iris.NextColumn()
								iris.Text("Tags")
								iris.NextColumn()
								iris.Text("isListening")
								for identifier, input in action.Input do
									iris.NextColumn()
									iris.Text({identifier})
									iris.NextColumn()
									if type(input.value) == "table" then
										local newValue = table.clone(input.value)
										for i, v in newValue do
											newValue[i] = v.Name
										end
										iris.Text(table.concat(newValue, ", "))
									else
										iris.Text(tostring(input.value))	
									end
									
									iris.NextColumn()
									iris.Text(input.category or "")
									iris.NextColumn()
									if not isRootEnabled then
										iris.Text({"false", [iris.Args.Text.Color]=Color3.new(1,0,0)})
									else
										if not action.Category or actions.IsCategoryActive(action.Category) then
											iris.Text({"true", [iris.Args.Text.Color]=Color3.new(0,1,0)})
										else
											iris.Text({"false", [iris.Args.Text.Color]=Color3.new(1,0,0)})
										end
									end
								end
							iris.End()
						iris.End()
					end
					
					iris.SeparatorText({ "Tags" })
					iris.Table({ 2 })
							iris.Text("TagId")
							iris.NextColumn()
							iris.Text("Enabled")
							for tagId, state in actions.CategoryStates do
								iris.NextColumn()
								iris.Text(tagId)
								iris.NextColumn()
								if state then
									iris.Text({"true", [iris.Args.Text.Color]=Color3.new(0,1,0)})
								else
									iris.Text({"false", [iris.Args.Text.Color]=Color3.new(1,0,0)})
								end
							end
						iris.End()
					iris.End()
					
				end, 1)

				local values = {
					serverModuleLog = network.value("serverModuleLog", {}),
				}

				values.serverModuleLog:Listen(function(old, new)
					serverBench = new
				end)
			end
		else
			network.start()
			data.start()
			tag.start()

			local values = {
				serverModuleLog = network.value("serverModuleLog", {}),
			}

			local coreModulesLoadedTag = Instance.new("StringValue")
			coreModulesLoadedTag.Name = "coreModulesLoaded"
			coreModulesLoadedTag.Parent = ROOT_CONFIG

			module.start()

			local serverModulesLoadedTag = Instance.new("StringValue")
			serverModulesLoadedTag.Name = "serverModulesLoaded"
			serverModulesLoadedTag.Parent = ROOT_CONFIG

			values.serverModuleLog:Set(module.info)
		end

		resolve()
	end)

	return stellaStartupPromise
end

type DATA_TEMPLATE = typeof(__stella.DATA_TEMPLATE)
type connection = typeof(Signal.new():Connect(function() end))

stella.iris = iris
stella.module = module
stella.number = number
stella.tween = tween
stella.data = data :: typeof(data) & {
	get: () -> DATA_TEMPLATE,
	connect: (any, path: { string }, f: (changes: { new: any, old: any }) -> ()) -> connection,
	wait: () -> (),
}
stella.actions = actions
stella.array = array
stella.uiAutoScale = uiAutoScale
stella.debugger = debugger
stella.tag = tag

stella.start = start
stella.network = network

return stella
