local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = script
local dependencies = root.dependencies
local kit = root.kit

local __stella = require(ReplicatedStorage.__stella)
local data = require(script.kit.data)
local value = require(script.network.value)
local utility = require(root.utility)
local Signal = require(dependencies.Signal)
local Janitor = require(dependencies.Janitor)
local Promise = require(dependencies.Promise)
local t = require(dependencies.t)
local iris = require(dependencies.iris)
local BoatTween = require(dependencies.BoatTween)
local squash = require(dependencies.squash)

local number = require(kit.number)
local tween = require(kit.tween)
local module = require(kit.module)
local controls = require(kit.controls)

local network = require(root.network)

local stella = {}

local stellaStartupPromise = nil :: typeof(Promise.new(function() end))?

local function typeStringTransform(value: any)
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
				str =
					`{str}{nocomma and "" or ","}\n{("    "):rep(i or 0)}[{typeStringTransform(k)}] = {tableTranslate(k, v, i, cache, "", true)}`
				nocomma = false
			else
				str = if not str
					then "{\n" .. `{("    "):rep(i or 0)}[{typeStringTransform(k)}] = {typeStringTransform(v)}`
					else `{str}{nocomma and "" or ","}\n{("    "):rep(i or 0)}[{typeStringTransform(k)}] = {typeStringTransform(v)}`
				nocomma = false
			end
		end
		if not str then
			str = "{}"
		else
			str = str .. `\n{("    "):rep(i - 1 or 0)}}`
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
            until ReplicatedStorage.__stella:FindFirstChild("coreModulesLoaded")

			if utility.settings.DebugEnabled then
				utility.settings.ControlActions.__stellaAction_DebugPanel = -1
				table.insert(utility.settings.ControlMap.pc, {
					kind = "MultiKeycode",
					action = utility.settings.ControlActions.__stellaAction_DebugPanel,
					value = {Enum.KeyCode.LeftControl, Enum.KeyCode.G},
					state = Enum.UserInputState.Begin
				})
			end

			network.start()
			data.start()
			controls.start()
			module.start()

			local windowSizeState = iris.State(Vector2.new(500, 300))
			local isOpenedState = iris.State(false)

			local isOpened = false

			local serverBench = {} :: typeof(module.info)

			if utility.settings.DebugEnabled then

				iris.Init()

				iris:Connect(function() 
					iris.Window({"Stella Debug Panel", nil, nil, nil, true, nil, nil, true}, {size = windowSizeState, isOpened = isOpenedState})
						iris.CollapsingHeader({"Module analysis"})
						do
							iris.Text("Client Module Load-time Analysis")
							iris.Separator()
							iris.Text({`Preload queries: {#module.info.attempts.preload} Load queries: {#module.info.attempts.load}`})
							iris.Text({`Failed preload queries: {#module.info.errored.preload} Failed load queries: {#module.info.errored.load}`})
							
							local merge = {}

							for _, bench in pairs(module.info.bench.preload) do
								merge[bench.identifier] = {
									preload = bench.bench
								}
							end
							for _, bench in pairs(module.info.bench.load) do
								local tb = merge[bench.identifier]
								if tb then
									tb.load = bench.bench
								else
									merge[bench.identifier] = {
										load = bench.bench
									}
								end
							end

							iris.Table({3})
								iris.NextRow()
								iris.Text("Module identifier")
								iris.NextColumn()
								iris.Text("Preload bench")
								iris.NextColumn()
								iris.Text("Load bench")
								iris.NextRow()
								for identifier, bench in pairs(merge) do
									iris.NextColumn()
									iris.Text({identifier})
									iris.NextColumn()
									if bench.preload then
										iris.Text({number.decimalUnitFormat(bench.preload)})
									else
										iris.Text({""})
									end
									iris.NextColumn()
									if bench.load then
										iris.Text({number.decimalUnitFormat(bench.load)})
									else
										iris.Text({""})
									end
									iris.NextRow()
								end
							iris.End()

							iris.Text{(`Observed startup errors ({#module.info.errored.preload + #module.info.errored.load})`)}
							iris.Separator()
							for _, value in pairs(module.info.errored.preload) do
								iris.TextWrapped({
									`[{value.identifier}]: Error occurred at preload \n\n {value.err.error}`, Color3.fromRGB(255, 68, 68)
								})
							end
							for _, value in pairs(module.info.errored.load) do
								iris.TextWrapped({
									`[{value.identifier}]: <font color="rgb(255, 68, 68)">Error occurred at load \n\n {value.err.error}</font>`, 
								})
							end
							
							iris.Separator()
						end
						if serverBench.attempts then do
							iris.Text("Server Module Load-time Analysis")
							iris.Separator()
							
							iris.Text({`Preload queries: {#serverBench.attempts.preload} Load queries: {#serverBench.attempts.load}`})
							iris.Text({`Failed preload queries: {#serverBench.errored.preload} Failed load queries: {#serverBench.errored.load}`})
							
							local merge = {}

							for _, bench in pairs(serverBench.bench.preload) do
								merge[bench.identifier] = {
									preload = bench.bench
								}
							end
							for _, bench in pairs(serverBench.bench.load) do
								local tb = merge[bench.identifier]
								if tb then
									tb.load = bench.bench
								else
									merge[bench.identifier] = {
										load = bench.bench
									}
								end
							end

							iris.Table({3})
								iris.NextRow()
								iris.Text("Module identifier")
								iris.NextColumn()
								iris.Text("Preload bench")
								iris.NextColumn()
								iris.Text("Load bench")
								iris.NextRow()
								for identifier, bench in pairs(merge) do
									iris.NextColumn()
									iris.Text({identifier})
									iris.NextColumn()
									if bench.preload then
										iris.Text({number.decimalUnitFormat(bench.preload)})
									else
										iris.Text({""})
									end
									iris.NextColumn()
									if bench.load then
										iris.Text({number.decimalUnitFormat(bench.load)})
									else
										iris.Text({""})
									end
									iris.NextRow()
								end
							iris.End()

							iris.Text{(`Observed startup errors ({#serverBench.errored.preload + #serverBench.errored.load})`)}
							iris.Separator()
							for _, value in pairs(serverBench.errored.preload) do
								iris.TextWrapped({
									`[{value.identifier}]: Error occurred at preload \n\n {value.err.error}`, Color3.fromRGB(255, 68, 68)
								})
							end
							for _, value in pairs(serverBench.errored.load) do
								iris.TextWrapped({
									`[{value.identifier}]: <font color="rgb(255, 68, 68)">Error occurred at load \n\n {value.err.error}</font>`, 
								})
							end
							
							iris.Separator()
						end end
						iris.End()

						iris.CollapsingHeader({"Network analysis"})
						iris.Button({"Observe Packets"})
						iris.End()
						iris.CollapsingHeader({"Controls analysis"})
						iris.Text({`Focus: {controls.focusing}`})
						iris.End()
					iris.End()
				end)

				local values = {
					serverModuleLog = network.value("serverModuleLog", {})
				}

				values.serverModuleLog:observe(function(old, new) 
					serverBench = new
				end)

				controls.onAction(utility.settings.ControlActions.__stellaAction_DebugPanel):Connect(function()		
					isOpened = not isOpened
					isOpenedState:set(isOpened)
				end)
			end
		else
			network.start()
			data.start()

			local values = {
				serverModuleLog = network.value("serverModuleLog", {})
			}

			local coreModulesLoadedTag = Instance.new("StringValue")
            coreModulesLoadedTag.Name = "coreModulesLoaded"
            coreModulesLoadedTag.Parent = ReplicatedStorage.__stella

			module.start()

			local serverModulesLoadedTag = Instance.new("StringValue")
            serverModulesLoadedTag.Name = "serverModulesLoaded"
            serverModulesLoadedTag.Parent = ReplicatedStorage.__stella

			values.serverModuleLog:set(module.info)
		end

		resolve()
	end)

	return stellaStartupPromise
end

stella.module = module
stella.number = number
stella.tween = tween
stella.data = data
stella.controls = controls
stella.actions = utility.settings.ControlActions :: typeof(__stella.ControlActions)
stella.controlsMap = utility.settings.ControlsMap :: typeof(__stella.ControlMap)

stella.start = start
stella.network = network

return stella
