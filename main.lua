local license = ... or {}
if type(license) ~= 'table' then license = {} end
local launch = shared.ElevateV4Loading
local function superseded()
	return type(launch) == 'table' and launch.Superseded == true
end
local function waitForGame()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
end
local function report(kind, code, message)
	local telemetry = shared.AetherTelemetry
	if telemetry and telemetry.Report then
		pcall(telemetry.Report, kind, code, tostring(message))
	end
end
local trail = type(shared.AetherStartup) == 'table' and shared.AetherStartup or nil
local function mark(stage)
	if trail and trail.Mark then trail.Mark(stage) end
end

local vape
local rawLoadstring = loadstring
local loadstring = function(...)
	local res, err = rawLoadstring(...)
	if err and vape then
		vape:CreateNotification('ElevateV4', 'Failed to load : '..err, 30, 'alert')
	end
	return res, err
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))
local starterGui = cloneref(game:GetService('StarterGui'))

local SOURCE_COMMIT = 'main'
local BEDWARS_UNIVERSE = 2619619496
local PLACE_ALIAS = {
	[6872265039] = 6872265039,
	[16008862571] = 6872265039,
	[6872274481] = 6872274481,
	[8444591321] = 6872274481,
	[8560631822] = 6872274481,
	[132768098780837] = 6872274481,
	[8768229691] = 8768229691,
	[8542275097] = 8768229691,
	[8592115909] = 8768229691,
	[8951451142] = 8768229691,
	[13246639586] = 8768229691,
	[8542259458] = 8768229691,
	[71480482338212] = 71480482338212,
	[71657866091528] = 71480482338212,
	[74441430126650] = 71480482338212,
	[72169370437173] = 72169370437173,
}
local DOWNLOAD_BATCH = 24

local function toast(title, text, duration)
	pcall(function()
		starterGui:SetCore('SendNotification', {
			Title = title or 'ElevateV4',
			Text = text or '',
			Duration = duration or 6
		})
	end)
end

local function ensureParentFolder(path)
	local parent = path:match('^(.*)/[^/]+$')
	if not parent or parent == '' then
		return
	end
	local acc = ''
	for part in string.gmatch(parent, '[^/]+') do
		acc = acc == '' and part or (acc..'/'..part)
		if not isfolder(acc) then
			pcall(makefolder, acc)
		end
	end
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet(shared.ElevateV4Base..SOURCE_COMMIT..'/'..select(1, path:gsub('ElevateV4/', '')), true)
		end)
		if not suc or res == '404: Not Found' or (type(res) == 'string' and (res:find('^%s*<!doctype html') or res:find('^%s*Too many requests') or res:find('^%s*Retry later'))) then
			error(res)
		end
		ensureParentFolder(path)
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local function fetchRemote(rel)
	local suc, res = pcall(function()
		return game:HttpGet(shared.ElevateV4Base..SOURCE_COMMIT..'/'..rel, true)
	end)
	if not suc or type(res) ~= 'string' then
		return nil
	end
	local head = res:sub(1, 300):lower()
	if res == '404: Not Found' or head:find('^%s*404') or head:find('^%s*<!doctype html') or head:find('^%s*<html')
		or head:find('^%s*too many requests') or head:find('^%s*retry later') then
		return nil
	end
	return res
end

local function parseFileList(list)
	local names = {}
	for line in string.gmatch(list, '[^\r\n]+') do
		line = line:gsub('^%s+', ''):gsub('%s+$', '')
		if line ~= '' and not line:find('^#') then
			table.insert(names, line)
		end
	end
	return names
end
local PACK_HEADER = '--ElevateV4 pack'

local function hashString(text)
	local hash = 2166136261
	for index = 1, #text do
		hash = bit32.bxor(hash, text:byte(index))
		hash = (hash * 16777619) % 4294967296
	end
	return string.format('%08x', hash)
end
local function installedCommit()
	if type(shared.ElevateV4Commit) == 'string' and shared.ElevateV4Commit ~= '' then
		return shared.ElevateV4Commit
	end
	if not isfile('ElevateV4/profiles/commit.txt') then return 'main' end
	local ok, body = pcall(readfile, 'ElevateV4/profiles/commit.txt')
	if ok and type(body) == 'string' then
		local commit = body:gsub('%s+', '')
		if commit ~= '' then return commit end
	end
	return 'main'
end

local function packKey(folder, list)
	return hashString(folder..'\n'..installedCommit()..'\n'..list)
end

local function packHeader(key, count)
	return PACK_HEADER..' key='..key..' count='..count..'\n'
end

local function packKeyOf(body)
	if type(body) ~= 'string' then return nil end
	local line = body:match('^[^\r\n]*')
	if not line or line:sub(1, #PACK_HEADER) ~= PACK_HEADER then return nil end
	return line:match('key=(%x+)')
end

local function downloadParallel(folder, names, phaseStart, phaseSpan)
	local bodies = table.create(#names)
	local done, cursor = 0, 0
	while cursor < #names do
		cursor += 1
		local idx, name = cursor, names[cursor]
		task.spawn(function()
			local ok, body = pcall(downloadFile, 'ElevateV4/games/'..folder..'/'..name)
			if ok then
				bodies[idx] = body
			else
				warn('[ElevateV4] skipped '..folder..'/'..name..': '..tostring(body))
			end
			done += 1
		end)
		if cursor % DOWNLOAD_BATCH == 0 then
			repeat task.wait() until done >= cursor or (cursor - done) < DOWNLOAD_BATCH
		end
	end
	repeat task.wait() until done >= #names
	return bodies
end
local function packLooksValid(body)
	if type(body) ~= 'string' or #body < 4096 then return false end
	local head = body:sub(1, 8192)
	return head:find('run(function', 1, true) ~= nil
		or head:find('CreateModule', 1, true) ~= nil
		or head:find('vape', 1, true) ~= nil
end
local function fileMarker(name)
	return '--@aether-file '..tostring(name)..'\n'
end

local function rememberPackSource(folder, text)
	shared.AetherPackSources = shared.AetherPackSources or {}
	shared.AetherPackSources[folder] = text
end

local function buildPack(job)
	local folder = job.Folder
	local listPath = 'ElevateV4/games/'..folder..'/files.txt'

	local list = isfile(listPath) and select(2, pcall(readfile, listPath)) or nil
	if type(list) ~= 'string' or list == '' then
		list = fetchRemote('games/'..folder..'/files.txt')
		if list then
			ensureParentFolder(listPath)
			pcall(writefile, listPath, list)
		end
	end
	if type(list) ~= 'string' or list == '' then
		job.Error = 'no files.txt'
		return
	end
	local names = parseFileList(list)
	if #names == 0 then
		job.Error = 'empty files.txt'
		return
	end
	job.Names = names
	job.Key = packKey(folder, list)

	local packPath = 'ElevateV4/games/'..folder..'/pack.lua'
	local detail = trail and trail.Detail
	if isfile(packPath) and not detail then
		local cached = select(2, pcall(readfile, packPath))
		if packKeyOf(cached) == job.Key and packLooksValid(cached) then
			local chunk, err = loadstring(cached, folder)
			if chunk then
				job.Chunk = chunk
				rememberPackSource(folder, cached)
				return
			end
			warn('[ElevateV4] cached pack for '..folder..' does not compile: '..tostring(err))
		elseif packKeyOf(cached) == nil then
			warn('[ElevateV4] discarding pack cache '..folder..' written by an older loader')
		else
			warn('[ElevateV4] discarding stale pack cache '..folder..' (module list or release changed)')
		end
		pcall(delfile, packPath)
	end

	local bodies = downloadParallel(folder, names)
	local chunks = {}
	for index = 1, #names do
		if bodies[index] then
			local crumb = detail and 'if shared.AetherStartup then shared.AetherStartup.Mark('..string.format('%q', 'pack '..folder..'/'..names[index])..') end\n' or ''
			table.insert(chunks, fileMarker(names[index])..crumb..bodies[index])
		end
	end
	job.Bodies = bodies
	if #chunks < #names then
		job.Error = 'incomplete module download ('..#chunks..'/'..#names..')'
		warn('[ElevateV4] '..folder..': '..job.Error)
		return
	end

	local packed = packHeader(job.Key, #names)..table.concat(chunks, '\n')
	if not packLooksValid(packed) then
		job.Error = 'assembled pack failed validation'
		return
	end
	local chunk, err = loadstring(packed, folder)
	if not chunk then
		warn('[ElevateV4] compile failed '..folder..': '..tostring(err))
		local kept = {}
		for index = 1, #names do
			local body = bodies[index]
			if body then
				local ok, oneErr = rawLoadstring(body, folder..'/'..names[index])
				if ok then
					table.insert(kept, fileMarker(names[index])..body)
				else
					warn('[ElevateV4] skipping '..folder..'/'..names[index]..': '..tostring(oneErr))
				end
			end
		end
		if #kept == 0 then return end
		packed = packHeader(job.Key, #kept)..table.concat(kept, '\n')
		if not packLooksValid(packed) then return end
		chunk, err = loadstring(packed, folder)
		if not chunk then
			warn('[ElevateV4] compile failed '..folder..' after skipping broken modules: '..tostring(err))
			return
		end
	end
	if not detail then
		ensureParentFolder(packPath)
		pcall(writefile, packPath, packed)
	end
	job.Chunk = chunk
	rememberPackSource(folder, packed)
end

local function preparePack(folder)
	local job = {Folder = folder, Ready = false}
	task.spawn(function()
		local ok, err = pcall(buildPack, job)
		if not ok then
			job.Error = tostring(err)
			warn('[ElevateV4] pack preparation failed '..folder..': '..tostring(err))
		end
		job.Ready = true
	end)
	return job
end

local function runPack(job)
	if not job.Ready then
		repeat task.wait() until job.Ready
	end
	if job.Chunk then
		local ok, result = pcall(job.Chunk, license)
		if ok then
			return true
		end
		warn('[ElevateV4] pack run failed '..job.Folder..': '..tostring(result))
		job.Error = job.Error or tostring(result)
		return false, result
	end
	local ran = 0
	if job.Bodies and job.Names then
		for index, name in ipairs(job.Names) do
			local body = job.Bodies[index]
			if body then
				local one, oneErr = loadstring(body, job.Folder..'/'..name)
				if one then
					if pcall(one, license) then
						ran += 1
					end
				else
					warn('[ElevateV4] compile failed '..job.Folder..'/'..name..': '..tostring(oneErr))
				end
			end
		end
	else
		local reason = job.Error or 'no module sources'
		warn('[ElevateV4] '..job.Folder..' modules unavailable: '..reason)
		return false, reason
	end
	return ran > 0, job.Error
end

local function resolvePlace()
	local id = game.PlaceId
	if PLACE_ALIAS[id] then
		return PLACE_ALIAS[id]
	end
	if game.GameId == BEDWARS_UNIVERSE then
		if id == 6872265039 or id == 16008862571 then
			return 6872265039
		end
		return 6872274481
	end
	if game.GameId == 7534782259 then
		return 71480482338212
	end
	if game.GameId == 10768498581 then
		return 72169370437173
	end
	if game.GameId == 3258873704 then
		return 8768229691
	end
	return id
end
local function armMatchHold()
	local env = getgenv and getgenv()
	if not env or env.matchDodgeHold then return end
	local function left(name)
		local ok, value = pcall(function()
			local path = 'ElevateV4/profiles/'..name..'.txt'
			return isfile(path) and readfile(path)
		end)
		return ok and value == 'true'
	end
	env.matchDodgeActive = left('matchdodge')
	env.regionLockActive = left('regionlock')
	env.regionLockAllowed = not env.regionLockActive
	if not (env.matchDodgeActive or env.regionLockActive) then return end
	if not (hookmetamethod and newcclosure and checkcaller and getnamecallmethod) then return end
	if identifyexecutor and table.find({'Madium', 'Solara', 'Xeno'}, (identifyexecutor())) then return end
	local player = playersService.LocalPlayer
	if player and player:GetAttribute('PlayerConnected') then return end

	local hold = {Held = true, Claimed = false, Started = os.clock()}
	function hold.Release()
		if not hold.Held then return end
		hold.Held = false
		env.dodged = false
		if hold.Remote then
			pcall(function() hold.Remote:FireServer() end)
			hold.Remote = nil
		end
	end
	local old
	local hooked = pcall(function()
		old = hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
			if hold.Held and not checkcaller() and getnamecallmethod() == 'FireServer' and tostring(self) == 'PlayerReady' then
				hold.Remote = self
				env.dodged = true
				return
			end
			return old(self, ...)
		end))
	end)
	if not hooked or not old then return end
	env.matchDodgeHold = hold
	task.delay(45, function()
		if not hold.Claimed then hold.Release() end
	end)
end
if tostring(PLACE_ALIAS[game.PlaceId]) == '6872274481' then
	pcall(armMatchHold)
end

local function finishLoading()
	vape.Init = nil
	mark('config')
	local loaded, loadError = pcall(function()
		vape:Load()
	end)
	if not loaded then
		warn('[ElevateV4] config load failed: '..tostring(loadError))
		report('startup', 'config_load', loadError)
		pcall(function()
			vape:CreateNotification('ElevateV4', 'Your config could not be loaded, so changes will not be saved this session: '..tostring(loadError):sub(1, 120), 20, 'alert')
		end)
	end
	task.spawn(function()
		local ticks = 0
		repeat
			pcall(function()
				ticks += 1
				if ticks % 6 == 0 then
					vape:Save()
				else
					vape:FlushPendingSave()
				end
			end)
			task.wait(10)
		until not vape.Loaded
	end)

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) then
			local autoExecute = vape.AutoExecute
			if (autoExecute ~= nil and autoExecute.Enabled == false) or shared.AetherAutoExecute == false then
				return
			end
			teleportedServers = true
			local teleportScript = 'getgenv().script_key = '..string.format('%q', tostring(shared.ElevateV4Key))..'\n'..[[
				shared.vapereload = true
				if shared.VapeDeveloper then
					loadstring(readfile('ElevateV4/init.lua'), 'loader')()
				else
					loadstring(game:HttpGet(]]..string.format('%q', shared.ElevateV4Base..'main/init.lua')..[[, true), 'loader')()
				end
			]]
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end
			pcall(function()
				vape:Save()
			end)
			queue_on_teleport(teleportScript)
		end
	end))

	mark('done')
	if trail then trail.Detail = nil end
	local bind = table.concat(vape.GUIBind and vape.GUIBind.Keys or vape.Keybind or {'RightShift'}, ' + '):upper()
	local msg = vape.VapeButton and 'Press the ElevateV4 button to open GUI' or 'Press '..bind..' to open GUI'
	if vape.CreateNotification then
		pcall(function()
			vape:CreateNotification('Finished Loading', msg, 4)
		end)
		if shared.AetherTelemetry then
			pcall(shared.AetherTelemetry.ShowBanner, vape)
		end
		local update = type(shared.updated) == 'table' and shared.updated or nil
		if update and not update.Notified then
			update.Notified = true
			task.delay(1, function()
				local files = tonumber(update.Files) or 0
				local text
				if update.From and update.From ~= '' and update.To and update.To ~= '' then
					text = 'Script has updated from v'..update.From..' to v'..update.To..'. '..files..' files changed'
				elseif update.To and update.To ~= '' then
					text = 'Script has updated to v'..update.To..'. '..files..' files changed'
				else
					return
				end
				pcall(function()
					vape:CreateNotification('ElevateV4', text, 10, 'info')
				end)
			end)
		end
	end
end

if not isfile('ElevateV4/profiles/gui.txt') then
	writefile('ElevateV4/profiles/gui.txt', 'new')
end
local gui = 'new'

if not isfolder('ElevateV4/assets/'..gui) then
	makefolder('ElevateV4/assets/'..gui)
end
local universalJob, placeJob, place
if not shared.VapeIndependent then
	universalJob = preparePack('universal')
	if PLACE_ALIAS[game.PlaceId] or game.GameId ~= 0 then
		place = resolvePlace()
		placeJob = preparePack(tostring(place))
	end
end
if shared.AetherProfiler and type(shared.AetherProfiler.Destroy) == 'function' then
	pcall(shared.AetherProfiler.Destroy)
end
shared.AetherProfiler = nil
pcall(function()
	local chunk = loadstring(downloadFile('ElevateV4/libraries/profiler.lua'), 'profiler')
	shared.AetherProfiler = chunk and chunk() or nil
end)
-- telemetry disabled
if shared.AetherTelemetry then
	pcall(shared.AetherTelemetry.SetPack, place or resolvePlace())
end
if trail and trail.Crashed and not trail.Reported then
	trail.Reported = true
	report('startup', 'unfinished', 'the last launch stopped at: '..tostring(trail.Crashed))
	toast('ElevateV4', 'The last launch did not finish (stopped at '..tostring(trail.Crashed)..'). This launch records each step so the cause can be found.', 12)
end
mark('gui compile')
local guiPath = 'ElevateV4/guis/'..gui..'.lua'
local guiChunk, guiErr = loadstring(downloadFile(guiPath), 'gui')
if not guiChunk then
	local fresh = fetchRemote('guis/'..gui..'.lua')
	if fresh then
		guiChunk, guiErr = loadstring(fresh, 'gui')
		if guiChunk then
			pcall(writefile, guiPath, fresh)
		end
	end
	if not guiChunk then
		pcall(delfile, 'ElevateV4/profiles/contents.index.json')
		report('gui', 'compile', guiErr)
		error('[ElevateV4] The '..tostring(gui)..' frontend failed to compile: '..tostring(guiErr))
	end
end
mark('waiting for game')
waitForGame()
if tostring(resolvePlace()) == '6872274481' then
	pcall(armMatchHold)
end
if superseded() then return end
if type(shared.ElevateV4Loading) == 'table' then shared.ElevateV4Loading.At = os.clock() end
if shared.vape then
	local ok, err = pcall(shared.vape.Uninject, shared.vape)
	if not ok then
		warn('[ElevateV4] the old instance did not uninject cleanly: '..tostring(err))
	end
	shared.vape = nil
end
pcall(function()
	for _, child in game:GetService('Players').LocalPlayer.PlayerGui:GetChildren() do
		if child:GetAttribute('ElevateV4') then
			child:Destroy()
		end
	end
end)
-- panel agent disabled
mark('gui')
vape = guiChunk(license)
if type(vape) ~= 'table' then
	error('[ElevateV4] The '..tostring(gui)..' frontend did not return a controller')
end
if type(vape.Clean) ~= 'function' or type(vape.Remove) ~= 'function' then
	local fallbackConnections = {}
	if type(vape.Clean) ~= 'function' then
		vape.Clean = function(_, ...)
			for index = 1, select('#', ...) do
				local item = select(index, ...)
				if item ~= nil then
					table.insert(fallbackConnections, item)
				end
			end
		end
		vape.CleanFallback = function()
			for _, item in fallbackConnections do
				pcall(function()
					if typeof(item) == 'Instance' then
						item:Destroy()
					elseif type(item) == 'table' and type(item.Disconnect) == 'function' then
						item:Disconnect()
					elseif type(item) == 'thread' then
						task.cancel(item)
					elseif type(item) == 'function' then
						item()
					end
				end)
			end
			table.clear(fallbackConnections)
		end
	end
	if type(vape.Remove) ~= 'function' then
		vape.Remove = function(self, name)
			local module = type(self) == 'table' and self.Modules and self.Modules[name]
			if not module then return end
			if type(module.Toggle) == 'function' and module.Enabled then
				pcall(module.Toggle, module, false)
			end
			if typeof(module.Object) == 'Instance' then
				pcall(function() module.Object:Destroy() end)
			end
		end
	end
end
if superseded() then
	pcall(function()
		vape.gui:Destroy()
	end)
	return
end
shared.vape = vape
_G.vape = vape

if not shared.VapeIndependent then
	if not placeJob then
		place = resolvePlace()
		placeJob = preparePack(tostring(place))
	end
	mark('pack universal')
	if not runPack(universalJob) then
		warn('[ElevateV4] universal modules are unavailable')
		report('pack', 'universal', universalJob.Error or 'universal modules are unavailable')
	end
	vape.Place = place
	if shared.AetherTelemetry then pcall(shared.AetherTelemetry.SetPack, place) end
	if superseded() then return end
	mark('pack '..tostring(place))
	local placeRan, placeError = runPack(placeJob)
	if not placeRan then
		local reason = tostring(placeError or placeJob.Error or 'unknown error')
		if placeJob.Error == 'no files.txt' then
			warn('[ElevateV4] No game module for '..tostring(game.PlaceId)..' -> '..tostring(place))
			toast('ElevateV4', 'No game pack for '..tostring(game.PlaceId)..'. Universal only.', 8)
		else
			warn('[ElevateV4] game pack '..tostring(place)..' (place '..tostring(game.PlaceId)..') failed: '..reason)
			report('pack', tostring(place), reason)
			toast('ElevateV4', 'The game pack for '..tostring(place)..' failed to start: '..(reason:match('^[^\n]*') or reason):sub(1, 140)..'. Universal only.', 15)
		end
	end
	if superseded() then return end
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end
