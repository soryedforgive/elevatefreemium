
local profiler = {Enabled = false}

local clock = os.clock
local heap = gcinfo
local running = coroutine.running
local debugInfo = debug.info
local realTask = task
local realRunService = cloneref and cloneref(game:GetService('RunService')) or game:GetService('RunService')

local SLOW_SECONDS = 0.004
local SLOW_KEEP = 64

local stats = {}
local slow = {}
local frameTotal = 0
local originals = setmetatable({}, {__mode = 'k'})
local curThread, curKey, curKind, curStart, curHeap = nil, nil, nil, 0, 0
local depth = 0
local stackThread, stackKey, stackKind, stackElapsed, stackAlloc = {}, {}, {}, {}, {}
local resumeKey = setmetatable({}, {__mode = 'k'})
local resumeKind = setmetatable({}, {__mode = 'k'})

local function suspendCurrent()
	if curThread then
		depth += 1
		stackThread[depth], stackKey[depth], stackKind[depth] = curThread, curKey, curKind
		stackElapsed[depth], stackAlloc[depth] = clock() - curStart, heap() - curHeap
	end
end

local function resumeOuter()
	if depth > 0 then
		curThread, curKey, curKind = stackThread[depth], stackKey[depth], stackKind[depth]
		curStart, curHeap = clock() - stackElapsed[depth], heap() - stackAlloc[depth]
		stackThread[depth] = nil
		depth -= 1
	else
		curThread = nil
	end
end

local function normaliseChunk(source)
	source = tostring(source or '?')
	source = source:match('^%[string "(.*)"%]$') or source
	source = source:gsub('^[=@]', '')
	return source
end

local functionKeys = setmetatable({}, {__mode = 'k'})
local function keyOfFunction(fn)
	local key = functionKeys[fn]
	if key then return key end
	local ok, source, line = pcall(debugInfo, fn, 'sl')
	key = ok and (normaliseChunk(source)..':'..tostring(line or 0)) or '?:0'
	functionKeys[fn] = key
	return key
end

local function charge(key, seconds, alloc, kind)
	if seconds < 0 then seconds = 0 end
	if alloc < 0 then alloc = 0 end
	local entry = stats[key]
	if not entry then
		entry = {Key = key, Kind = kind, Time = 0, Calls = 0, Alloc = 0, Max = 0, ITime = 0, ICalls = 0, IAlloc = 0, IMax = 0}
		stats[key] = entry
	end
	entry.Time += seconds
	entry.Calls += 1
	entry.Alloc += alloc
	entry.ITime += seconds
	entry.ICalls += 1
	entry.IAlloc += alloc
	if seconds > entry.Max then entry.Max = seconds end
	if seconds > entry.IMax then entry.IMax = seconds end
	frameTotal += seconds
	if seconds >= SLOW_SECONDS then
		slow[#slow + 1] = {At = clock(), Key = key, Kind = kind, Ms = seconds * 1000, AllocKb = alloc}
		if #slow > SLOW_KEEP then table.remove(slow, 1) end
	end
end

local function finish(thread, ...)
	if curThread == thread then
		charge(curKey, clock() - curStart, heap() - curHeap, curKind)
		resumeOuter()
	end
	return ...
end

local function wrap(fn, kind)
	if type(fn) ~= 'function' or originals[fn] then return fn end
	local key = keyOfFunction(fn)
	local wrapped = function(...)
		if not profiler.Enabled then return fn(...) end
		local thread = running()
		suspendCurrent()
		curThread, curKey, curKind, curStart, curHeap = thread, key, kind, clock(), heap()
		return finish(thread, fn(...))
	end
	originals[wrapped] = fn
	return wrapped
end
local function beforeYield(thread, level)
	if not profiler.Enabled then return end
	if curThread == thread then
		charge(curKey, clock() - curStart, heap() - curHeap, curKind)
		resumeKey[thread], resumeKind[thread] = curKey, curKind
		resumeOuter()
	elseif not resumeKey[thread] then
		local ok, source, line = pcall(debugInfo, level + 2, 'sl')
		resumeKey[thread] = ok and (normaliseChunk(source)..':'..tostring(line or 0)) or '?:0'
		resumeKind[thread] = 'loop'
	end
end

local function afterYield(thread, ...)
	if profiler.Enabled and resumeKey[thread] then
		suspendCurrent()
		curThread, curKey, curKind, curStart, curHeap = thread, resumeKey[thread], resumeKind[thread] or 'loop', clock(), heap()
	end
	return ...
end
local frameConnection
pcall(function()
	frameConnection = realRunService.PreRender:Connect(function()
		if curThread or depth > 0 then
			curThread = nil
			for index = 1, depth do stackThread[index] = nil end
			depth = 0
		end
	end)
end)

local proxyTask = setmetatable({}, {__index = realTask})
proxyTask.wait = function(...)
	local thread = running()
	beforeYield(thread, 2)
	return afterYield(thread, realTask.wait(...))
end
proxyTask.spawn = function(target, ...)
	if not profiler.Enabled then return realTask.spawn(target, ...) end
	return realTask.spawn(wrap(target, 'task'), ...)
end
proxyTask.defer = function(target, ...)
	if not profiler.Enabled then return realTask.defer(target, ...) end
	return realTask.defer(wrap(target, 'task'), ...)
end
proxyTask.delay = function(seconds, target, ...)
	if not profiler.Enabled then return realTask.delay(seconds, target, ...) end
	return realTask.delay(seconds, wrap(target, 'task'), ...)
end

local FRAME_SIGNALS = {'Heartbeat', 'Stepped', 'RenderStepped', 'PreRender', 'PreAnimation', 'PreSimulation', 'PostSimulation'}
local signalProxies = {}

for _, name in FRAME_SIGNALS do
	local ok, signal = pcall(function() return realRunService[name] end)
	if ok and signal then
		local proxy = {Signal = signal}
		function proxy:Connect(fn) return signal:Connect(wrap(fn, name)) end
		function proxy:Once(fn) return signal:Once(wrap(fn, name)) end
		function proxy:ConnectParallel(fn) return signal:ConnectParallel(fn) end
		function proxy:Wait()
			local thread = running()
			beforeYield(thread, 2)
			return afterYield(thread, signal:Wait())
		end
		signalProxies[name] = proxy
	end
end

local proxyRunService = setmetatable({Instance = realRunService}, {
	__index = function(_, key)
		local proxy = signalProxies[key]
		if proxy then return proxy end
		local value = realRunService[key]
		if key == 'BindToRenderStep' then
			return function(_, name, priority, fn)
				return realRunService:BindToRenderStep(name, priority, wrap(fn, 'RenderStep:'..tostring(name)))
			end
		end
		if type(value) == 'function' then
			return function(_, ...) return value(realRunService, ...) end
		end
		return value
	end
})

profiler.Task = proxyTask
profiler.RunService = proxyRunService
profiler.Wrap = wrap

function profiler.Unwrap(fn)
	return originals[fn] or fn
end
function profiler.RealSignal(name)
	return realRunService[name]
end
function profiler.TakeFrame()
	local total = frameTotal
	frameTotal = 0
	return total
end
function profiler.Collect()
	local out = {}
	for _, entry in stats do
		if entry.ICalls > 0 then
			out[#out + 1] = {Key = entry.Key, Kind = entry.Kind, Time = entry.ITime, Calls = entry.ICalls, Alloc = entry.IAlloc, Max = entry.IMax}
			entry.ITime, entry.ICalls, entry.IAlloc, entry.IMax = 0, 0, 0, 0
		end
	end
	return out
end

function profiler.Totals()
	return stats
end

function profiler.SlowCalls(since)
	local out = {}
	for _, entry in slow do
		if entry.At >= (since or 0) then out[#out + 1] = entry end
	end
	return out
end

function profiler.Reset()
	table.clear(stats)
	table.clear(slow)
	frameTotal = 0
end
local lineMaps = {}
local described = {}
local builders = {}
local MARKER = '--@aether-file '
local function stepLineMap(chunk, budget)
	local builder = builders[chunk]
	if not builder then return true end
	local text, position, line, map = builder.Text, builder.Position, builder.Line, builder.Map
	local started = clock()
	local find, sub = string.find, string.sub
	while true do
		local start = find(text, MARKER, position, true)
		if not start then
			lineMaps[chunk] = map
			builders[chunk] = nil
			return true
		end
		local newline = find(text, '\n', position, true)
		while newline and newline < start do
			line += 1
			newline = find(text, '\n', newline + 1, true)
		end
		local lineEnd = newline or (#text + 1)
		map[#map + 1] = {Line = line, Name = sub(text, start + #MARKER, lineEnd - 1)}
		position = start + 1
		builder.Position, builder.Line = position, line
		if budget and clock() - started >= budget then return false end
	end
end

local function lineMapFor(chunk)
	local map = lineMaps[chunk]
	if map ~= nil then return map end
	if not builders[chunk] then
		local sources = shared.AetherPackSources
		local text = sources and sources[chunk]
		if type(text) ~= 'string' then
			lineMaps[chunk] = false
			return false
		end
		sources[chunk] = nil
		builders[chunk] = {Text = text, Position = 1, Line = 1, Map = {}}
	end
	stepLineMap(chunk, nil)
	return lineMaps[chunk] or false
end

local preparing = false
function profiler.Prepare()
	local sources = shared.AetherPackSources
	if preparing or type(sources) ~= 'table' then return end
	for chunk, text in sources do
		if type(text) == 'string' and lineMaps[chunk] == nil and not builders[chunk] then
			sources[chunk] = nil
			builders[chunk] = {Text = text, Position = 1, Line = 1, Map = {}}
		end
	end
	if next(builders) == nil then return end
	preparing = true
	realTask.spawn(function()
		while next(builders) ~= nil do
			local chunk = next(builders)
			stepLineMap(chunk, 0.001)
			realTask.wait()
		end
		preparing = false
	end)
end
function profiler.Describe(key)
	local cached = described[key]
	if cached then return cached end
	local chunk, line = tostring(key):match('^(.*):(%d+)$')
	line = tonumber(line) or 0
	chunk = chunk or tostring(key)
	local file, fileLine = nil, line
	local map = lineMapFor(chunk)
	if map and #map > 0 then
		local low, high, found = 1, #map, nil
		while low <= high do
			local mid = (low + high) // 2
			if map[mid].Line <= line then
				found = mid
				low = mid + 1
			else
				high = mid - 1
			end
		end
		if found then
			file = map[found].Name
			fileLine = line - map[found].Line
		end
	end
	if not file then
		local pack, name = chunk:match('^([^/]+)/(.+)$')
		if pack and name then
			file, chunk = name, pack
		end
	end
	local result = {
		Pack = chunk,
		File = file or chunk,
		Line = fileLine,
		Label = (file or chunk)..':'..tostring(fileLine),
	}
	described[key] = result
	return result
end
function profiler.Listeners(signal)
	local out = {}
	if type(getconnections) ~= 'function' then return out end
	local ok, connections = pcall(getconnections, signal)
	if not ok or type(connections) ~= 'table' then return out end
	for _, connection in connections do
		local fn = connection and connection.Function
		if type(fn) == 'function' and (type(isexecutorclosure) ~= 'function' or isexecutorclosure(fn)) then
			out[#out + 1] = profiler.Describe(keyOfFunction(originals[fn] or fn)).Label
		end
	end
	return out
end
function profiler.Destroy()
	profiler.Enabled = false
	if frameConnection then
		pcall(function() frameConnection:Disconnect() end)
		frameConnection = nil
	end
	profiler.Reset()
end

return profiler
