-- Edited from BridgeNet2
local freeThread: thread? -- Thread reusage

local function passer(fn: (...any) -> (), ...): ()
	local acquiredThread = freeThread
	freeThread = nil
	fn(...)
	freeThread = acquiredThread
end

local function yielder(): ()
	while true do
		passer(coroutine.yield())
	end
end

return function(fn: (...any) -> (), ...): ()
	if freeThread == nil then
		freeThread = coroutine.create(yielder)
		coroutine.resume(freeThread :: thread)
	end
	task.spawn(freeThread :: thread, fn, ...)
end
