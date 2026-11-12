local API = 'https://api.ElevateV4.xyz'
local SETTINGS_PATH = 'ElevateV4/profiles/telemetry.json'
local SESSION_PATH = 'ElevateV4/profiles/telemetrysession.json'
local MAX_QUEUE = 40
local MAX_BATCH = 12
local MAX_REPORTS = 25
local MAX_PERF = 15

local cloneref = cloneref or function(obj) return obj end
local httpService = cloneref(game:GetService('HttpService'))
local playersService = cloneref(game:GetService('Players'))
local requestFunction = request or http_request or (syn and syn.request) or (http and http.request)

local old = shared.AetherTelemetry
if type(old) == 'table' and type(old.Stop) == 'function' then
	pcall(old.Stop)
end

local function readJson(path)
	local ok, body = pcall(function() return isfile(path) and readfile(path) or nil end)
	if not ok or type(body) ~= 'string' then return nil end
	local decoded, value = pcall(httpService.JSONDecode, httpService, body)
	return decoded and type(value) == 'table' and value or nil
end

local function writeJson(path, value)
	pcall(function() writefile(path, httpService:JSONEncode(value)) end)
end

local function hexId(length)
	return (httpService:GenerateGUID(false):gsub('-', ''):lower() .. httpService:GenerateGUID(false):gsub('-', ''):lower()):sub(1, length)
end

local settings = readJson(SETTINGS_PATH) or {}
if settings.Enabled == nil then settings.Enabled = true end
if type(settings.Link) ~= 'string' then settings.Link = '' end
if type(settings.SeenBanner) ~= 'string' then settings.SeenBanner = '' end

local api = {
	Api = API,
	Enabled = settings.Enabled,
	Server = {Enabled = true, Errors = true, Heartbeat = 120},
	Banner = nil,
	ConfigLoaded = false
}

local alive = true
local queue = {}
local sending = false
local failures = 0
local pausedUntil = 0
local reports = 0
local perfReports = 0
local recent = {}
local pack
local player = playersService.LocalPlayer

local function validLink(code)
	return type(code) == 'string' and code:match('^alk_[%w_%-]+$') ~= nil and #code >= 24 and #code <= 84
end

local function headers()
	local out = {['Content-Type'] = 'application/json'}
	if validLink(settings.Link) then out.Authorization = 'Link ' .. settings.Link end
	return out
end

local function send(method, route, body)
	if not requestFunction then return nil end
	local ok, response = pcall(requestFunction, {
		Url = API .. route,
		Method = method,
		Headers = headers(),
		Body = body and httpService:JSONEncode(body) or nil
	})
	if not ok or type(response) ~= 'table' then return nil end
	local status = tonumber(response.StatusCode or response.Status) or 0
	local decoded = type(response.Body) == 'string' and select(2, pcall(httpService.JSONDecode, httpService, response.Body)) or nil
	return status, type(decoded) == 'table' and decoded or nil
end

local function applyServer(state)
	if type(state) ~= 'table' then return end
	api.Server.Enabled = state.enabled ~= false
	api.Server.Errors = state.errors ~= false
	local beat = tonumber(state.heartbeat)
	if beat then api.Server.Heartbeat = math.clamp(beat, 30, 900) end
end
local userId = player and player.UserId or 0
local saved = readJson(SESSION_PATH)
local launch = hexId(16)
local resumed = type(old) == 'table' and old.Sid and old.UserId == userId and not old.Ended
local sid
if resumed then
	sid = old.Sid
elseif saved and type(saved.Sid) == 'string' and saved.Sid:match('^%x+$') and #saved.Sid == 32
	and saved.User == userId and tonumber(saved.At) and os.time() - saved.At < 300 then
	sid = saved.Sid
	resumed = true
else
	sid = hexId(32)
end
api.Sid, api.UserId, api.Launch, api.Queue = sid, userId, launch, queue
if resumed and type(old) == 'table' then old.Superseded = true end

local function stamp()
	writeJson(SESSION_PATH, {Sid = sid, User = userId, At = os.time()})
end

local function meta()
	local version
	pcall(function()
		version = readfile('ElevateV4/profiles/version.txt'):match('version%s*=%s*([%w%.%-_]+)')
	end)
	local commit = type(shared.ElevateV4Commit) == 'string' and shared.ElevateV4Commit or nil
	if not (commit and commit:match('^%x+$')) then
		pcall(function() commit = readfile('ElevateV4/profiles/commit.txt'):match('^%s*(%x+)%s*$') end)
	end
	local executor
	pcall(function()
		local name, ver = identifyexecutor()
		executor = tostring(name) .. (ver and (' ' .. tostring(ver)) or '')
	end)
	return {
		version = version,
		commit = commit and #commit >= 7 and commit:sub(1, 40) or nil,
		place = tostring(game.PlaceId),
		pack = pack,
		executor = executor and executor:sub(1, 60) or nil
	}
end

local function sendable()
	return alive and api.Enabled and api.Server.Enabled and requestFunction ~= nil and player ~= nil
end

local flush
local function schedule(delay)
	task.delay(delay, function()
		if flush then flush() end
	end)
end

flush = function()
	if sending or not sendable() or #queue == 0 or os.clock() < pausedUntil then return end
	sending = true
	local count = math.min(#queue, MAX_BATCH)
	local batch = table.move(queue, 1, count, 1, {})
	task.spawn(function()
		local status, body = send('POST', '/v1/telemetry', {
			v = 1,
			sid = sid,
			launch = launch,
			player = {id = player.UserId, name = player.Name},
			meta = meta(),
			events = batch
		})
		if status == 200 or status == 400 or status == 413 then
			table.move(queue, count + 1, #queue + count, 1)
			failures = 0
			if body then applyServer(body.telemetry) end
		else
			failures += 1
			pausedUntil = os.clock() + math.min(30 * 2 ^ (failures - 1), 900)
			if failures >= 4 then table.clear(queue) end
		end
		sending = false
		if #queue > 0 and alive then schedule(2) end
	end)
end

local function push(event)
	if not sendable() then return end
	if #queue >= MAX_QUEUE then return end
	if event.type == 'hb' then
		for _, queued in queue do
			if queued.type == 'hb' then return end
		end
	end
	table.insert(queue, event)
end

function api.Report(kind, code, message, stack, context)
	local perf = kind == 'perf'
	if not sendable() or not api.Server.Errors or (perf and perfReports >= MAX_PERF) or (not perf and reports >= MAX_REPORTS) then return end
	message = tostring(message or ''):sub(1, 600)
	if message == '' then return end
	local key = tostring(kind) .. '|' .. tostring(code) .. '|' .. message:sub(1, 120)
	local now = os.clock()
	if recent[key] and now - recent[key] < 60 then return end
	recent[key] = now
	if perf then perfReports += 1 else reports += 1 end
	push({
		type = perf and 'perf' or 'error',
		kind = kind,
		code = code and tostring(code):sub(1, 64) or nil,
		message = message,
		stack = stack and tostring(stack):sub(1, 2000) or nil,
		context = type(context) == 'table' and context or nil
	})
	schedule(10)
end

function api.Perf(event)
	if type(event) ~= 'table' then return end
	api.Report('perf', 'fps_drop', string.format('fps %d -> %d (%s)', math.floor(tonumber(event.Before) or 0), math.floor(tonumber(event.During) or 0), tostring(event.Severity or 'drop')), nil, {
		before = math.floor(tonumber(event.Before) or 0),
		during = math.floor(tonumber(event.During) or 0),
		suspect = event.Suspect and tostring(event.Suspect):sub(1, 120) or nil,
		confidence = event.Confidence and tostring(event.Confidence) or nil,
		entities = tonumber(event.Entities)
	})
end

function api.SetPack(name)
	pack = name and tostring(name):match('^[%w%-_]+$') or nil
end

function api.SetEnabled(enabled)
	enabled = enabled and true or false
	if settings.Enabled == enabled and api.Enabled == enabled then return end
	settings.Enabled = enabled
	api.Enabled = enabled
	writeJson(SETTINGS_PATH, settings)
	if enabled then
		push({type = 'reinject'})
		schedule(1)
	else
		table.clear(queue)
	end
end

function api.GetLink()
	return settings.Link
end
function api.SetLink(code, callback)
	code = tostring(code or ''):match('^%s*(.-)%s*$')
	if code ~= '' and not validLink(code) then
		if callback then callback(false, 'That is not a link code. Make one on the dashboard Account page.') end
		return
	end
	settings.Link = code
	writeJson(SETTINGS_PATH, settings)
	if code == '' then
		if callback then callback(true, {linked = false}) end
		return
	end
	api.Me(callback)
end

function api.Me(callback)
	task.spawn(function()
		if not validLink(settings.Link) then
			if callback then callback(true, {linked = false}) end
			return
		end
		local status, body = send('GET', '/v1/client/me?roblox=' .. tostring(userId))
		if not callback then return end
		if status == 200 and body then
			callback(true, body)
		else
			callback(false, status and ('The backend answered ' .. tostring(status) .. '.') or 'The backend could not be reached.')
		end
	end)
end
function api.ShowBanner(vape)
	task.spawn(function()
		local waited = 0
		while not api.ConfigLoaded and waited < 20 and alive do
			task.wait(0.5)
			waited += 0.5
		end
		local banner = api.Banner
		if not alive or type(banner) ~= 'table' or type(banner.text) ~= 'string' then return end
		local id = tostring(banner.id or banner.text)
		if banner.level ~= 'critical' and settings.SeenBanner == id then return end
		settings.SeenBanner = id
		writeJson(SETTINGS_PATH, settings)
		local kind = banner.level == 'critical' and 'alert' or banner.level == 'warning' and 'warning' or 'info'
		pcall(function()
			vape:CreateNotification('ElevateV4', banner.text:sub(1, 300), banner.level == 'critical' and 20 or 12, kind)
		end)
	end)
end

function api.Stop(final)
	if not alive then return end
	if api.Superseded then final = nil end
	alive = false
	api.Ended = final ~= nil
	if final and api.Enabled and api.Server.Enabled and requestFunction and player then
		task.spawn(send, 'POST', '/v1/telemetry', {
			v = 1, sid = sid, launch = launch,
			player = {id = player.UserId, name = player.Name},
			meta = meta(),
			events = {{type = 'end', reason = tostring(final):sub(1, 30)}}
		})
		pcall(delfile, SESSION_PATH)
	end
end
task.spawn(function()
	local status, body = send('GET', '/v1/client/config')
	if status == 200 and body then
		applyServer(body.telemetry)
		api.Banner = type(body.banner) == 'table' and body.banner or nil
	end
	api.ConfigLoaded = true
end)

if sendable() then
	push({type = resumed and 'reinject' or 'start'})
	if resumed and type(old.Queue) == 'table' then
		for _, event in old.Queue do
			if type(event) == 'table' and (event.type == 'error' or event.type == 'perf') and #queue < MAX_QUEUE then
				table.insert(queue, event)
			end
		end
	end
	local pending = shared.AetherTelemetryPending
	shared.AetherTelemetryPending = nil
	if type(pending) == 'table' then
		for _, entry in pending do
			if type(entry) == 'table' then api.Report(entry[1], entry[2], entry[3]) end
		end
	end
	stamp()
	schedule(8)
end

pcall(function()
	player.OnTeleport:Connect(function(state)
		if alive and state == Enum.TeleportState.Started then stamp() end
	end)
end)

task.spawn(function()
	while alive do
		task.wait(api.Server.Heartbeat)
		if not alive then break end
		if sendable() then
			push({type = 'hb'})
			stamp()
			flush()
		end
	end
end)

shared.AetherTelemetry = api
return api
