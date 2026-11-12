local licence = ... or {}
if type(licence) ~= 'table' then licence = {} end
shared.AetherLaunchReload = shared.vapereload == true
shared.vapereload = nil
local running = shared.ElevateV4Loading
if type(running) == 'table' then
	running.Superseded = true
	warn('[Elevate] replacing an earlier launch that had not finished')
	local deadline = os.clock() + 5
	while not running.Done and os.clock() < deadline do
		task.wait(0.1)
	end
end
local launch = {At = os.clock()}
shared.ElevateV4Loading = launch

local cloneref = cloneref or function(object)
	return object
end
local isfile = isfile or function(file)
	local success, result = pcall(readfile, file)
	return success and result ~= nil and result ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
end

local HttpService = cloneref(game:GetService('HttpService'))

-- Public GitHub repo (no token needed).
local OWNER = 'soryedforgive'
local REPO = 'elevatefreemium'
local SOURCE = 'main'
local RAW_ROOT = 'https://raw.githubusercontent.com/'..OWNER..'/'..REPO..'/'
local API_ROOT = 'https://api.github.com/repos/'..OWNER..'/'..REPO..'/'
local COMMIT_URL = API_ROOT..'commits/'..SOURCE
local ROOT = 'ElevateV4/'

-- The rest of the pack builds its download URLs from these.
shared.ElevateV4Base = RAW_ROOT
shared.ElevateV4Api = API_ROOT

for _, folder in {'ElevateV4', 'ElevateV4/games', 'ElevateV4/profiles', 'ElevateV4/assets', 'ElevateV4/libraries', 'ElevateV4/guis'} do
	if not isfolder(folder) then
		pcall(makefolder, folder)
	end
end

local trail = {Path = ROOT..'profiles/startup.txt'}
do
	local named, executor = pcall(function()
		return identifyexecutor and identifyexecutor() or ''
	end)
	trail.Delta = named and tostring(executor):lower():find('delta', 1, true) ~= nil
end
if trail.Delta then
	local ok, body = pcall(readfile, trail.Path)
	local stage, job = '', ''
	if ok and type(body) == 'string' then
		stage, job = body:match('^([^\n]*)\n?([^\n]*)')
	end
	if stage and stage ~= '' and stage ~= 'done' and job ~= tostring(game.JobId) then
		trail.Crashed = stage
		trail.Detail = true
	end
end
function trail.Mark(stage)
	if not trail.Delta then return end
	trail.Stage = stage
	pcall(writefile, trail.Path, tostring(stage)..'\n'..tostring(game.JobId)..'\n'..tostring(os.time()))
end
shared.AetherStartup = trail.Delta and trail or nil
trail.Mark('loader')

local splash = {}
function splash.Show()
	if splash.Gui or not isfile(ROOT..'assets/new/loading.png') then return end
	pcall(function()
		local data = readfile(ROOT..'assets/new/loading.png')
		local copy = ROOT..'assets/registered/elevate-splash-'..#data..'.png'
		if not isfile(copy) then
			if not isfolder(ROOT..'assets/registered') then makefolder(ROOT..'assets/registered') end
			writefile(copy, data)
		end
		local tweens = cloneref(game:GetService('TweenService'))
		local parent = gethui and gethui() or cloneref(game:GetService('CoreGui'))
		local old = parent:FindFirstChild('ElevateV4Splash')
		if old then old:Destroy() end
		local gui = Instance.new('ScreenGui')
		gui.Name = 'ElevateV4Splash'
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 999999
		local shade = Instance.new('Frame')
		shade.Size = UDim2.fromScale(1, 1)
		shade.BackgroundColor3 = Color3.new()
		shade.BackgroundTransparency = 1
		shade.BorderSizePixel = 0
		shade.Parent = gui
		local image = Instance.new('ImageLabel')
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.Size = UDim2.fromOffset(96, 96)
		image.BackgroundTransparency = 1
		image.ScaleType = Enum.ScaleType.Fit
		image.ImageTransparency = 1
		image.Image = getcustomasset(copy)
		image.Parent = gui
		gui.Parent = parent
		local blur
		local camera = workspace.CurrentCamera
		if game.GameId ~= 7534782259 and camera then
			old = camera:FindFirstChild('ElevateV4SplashBlur')
			if old then old:Destroy() end
			blur = Instance.new('BlurEffect')
			blur.Name = 'ElevateV4SplashBlur'
			blur.Size = 0
			blur.Parent = camera
			tweens:Create(blur, TweenInfo.new(0.35), {Size = 16}):Play()
		end
		splash.Gui, splash.Image, splash.Shade, splash.Blur = gui, image, shade, blur
		task.delay(60, function()
			if splash.Gui == gui then splash.Hide() end
		end)
		tweens:Create(shade, TweenInfo.new(0.35), {BackgroundTransparency = 0.45}):Play()
		tweens:Create(image, TweenInfo.new(0.35), {ImageTransparency = 0}):Play()
	end)
end
function splash.Hide()
	local gui, image, shade, blur = splash.Gui, splash.Image, splash.Shade, splash.Blur
	splash.Gui, splash.Image, splash.Shade, splash.Blur = nil, nil, nil, nil
	if not gui then return end
	pcall(function()
		local tweens = cloneref(game:GetService('TweenService'))
		local info = TweenInfo.new(0.35)
		tweens:Create(shade, info, {BackgroundTransparency = 1}):Play()
		if blur then tweens:Create(blur, info, {Size = 0}):Play() end
		local tween = tweens:Create(image, info, {ImageTransparency = 1})
		tween.Completed:Once(function()
			gui:Destroy()
			if blur then blur:Destroy() end
		end)
		tween:Play()
	end)
	task.delay(1, function()
		pcall(gui.Destroy, gui)
		if blur then pcall(blur.Destroy, blur) end
	end)
end
splash.Show()

local ref = SOURCE
local COMMIT_PATH = ROOT..'profiles/commit.txt'
local VERSION_PATH = ROOT..'profiles/version.txt'
local INDEX_PATH = ROOT..'profiles/contents.index.json'
local PIN_PATH = ROOT..'profiles/version-pin.txt'
local pinned
local DOWNLOAD_BATCH = 16

local function usable(success, body)
	if not success or type(body) ~= 'string' or body == '' then
		return nil
	end
	local head = body:sub(1, 300):lower()
	if body == '404: Not Found' or head:find('^%s*404') or head:find('^%s*429') or head:find('^%s*5%d%d:')
		or head:find('^%s*too many requests') or head:find('^%s*retry later') or head:find('^%s*{"message"')
		or head:find('^%s*{"error"') or head:find('<!doctype html') or head:find('^%s*<html') then
		return nil
	end
	return body
end

local function fetch(rel)
	return usable(pcall(function()
		return game:HttpGet(RAW_ROOT..ref..'/'..rel, true)
	end))
end

local function decodeJson(text)
	if type(text) ~= 'string' then return nil end
	local success, decoded = pcall(function()
		return HttpService:JSONDecode(text)
	end)
	return success and decoded or nil
end

local function readLocal(path)
	local success, body = pcall(readfile, path)
	if not success or type(body) ~= 'string' then
		return nil
	end
	return body
end

local function parseVersion(body)
	return (tostring(body or ''):match('version%s*=%s*([^\r\n]+)') or ''):gsub('%s+$', '')
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
local hashSlice = os.clock()
local function hashText(text)
	if text:find('\r', 1, true) then
		text = text:gsub('\r\n', '\n')
	end
	local hash = 2166136261
	for index = 1, #text do
		hash = bit32.bxor(hash, text:byte(index))
		local low = hash % 65536
		local high = (hash - low) / 65536
		hash = (low * 16777619 + (high * 16777619 % 65536) * 65536) % 4294967296
		if index % 16384 == 0 and os.clock() - hashSlice > 0.04 then
			task.wait()
			hashSlice = os.clock()
		end
	end
	if os.clock() - hashSlice > 0.04 then
		task.wait()
		hashSlice = os.clock()
	end
	return string.format('%08x', hash)
end
local function fetchFile(rel, hash)
	for _ = 1, 2 do
		local body = fetch(rel)
		if body and (not hash or hashText(body) == hash) then
			return body
		end
	end
	return nil
end

local function syncContents(contents, forced)
	local files = contents.files
	if type(files) ~= 'table' then
		return 0, -1
	end

	local index = not forced and decodeJson(readLocal(INDEX_PATH)) or nil
	if type(index) ~= 'table' then index = {} end
	local verified = {}

	local jobs = {}
	for _, entry in ipairs(files) do
		local rel, size, hash = entry[1], entry[2], entry[3]
		if type(rel) == 'string' and type(hash) == 'string' then
			local path = ROOT..rel
			local matches
			if index[rel] == hash and isfile(path) then
				matches = true
			else
				local body = readLocal(path)
				matches = body ~= nil and hashText(body) == hash
			end
			if not matches or forced and rel == 'main.lua' then
				table.insert(jobs, {Rel = rel, Path = path, Hash = hash, Size = size})
			else
				verified[rel] = hash
			end
		end
	end

	local function rank(rel)
		if rel == 'main.lua' then return 0 end
		if rel:find('^guis/') or rel:find('^libraries/') or rel:find('^profiles/') then return 1 end
		if rel:find('^games/universal/') then return 2 end
		if rel:find('^games/'..tostring(game.PlaceId)..'/') then return 3 end
		return rel:find('^games/') and 4 or 5
	end
	for order, job in ipairs(jobs) do
		job.Order = order
		job.Rank = rank(job.Rel)
	end
	table.sort(jobs, function(a, b)
		if a.Rank ~= b.Rank then return a.Rank < b.Rank end
		return a.Order < b.Order
	end)

	local written, failed = 0, 0
	local stale = {}
	local function download(list)
		local missed = {}
		local done, cursor = 0, 0
		while cursor < #list do
			cursor += 1
			local job = list[cursor]
			task.spawn(function()
				local body = fetchFile(job.Rel, job.Hash)
				if body then
					ensureParentFolder(job.Path)
					local ok = pcall(writefile, job.Path, body)
					if ok then
						written += 1
						verified[job.Rel] = job.Hash
						local folder = job.Rel:match('^games/([^/]+)/')
						if folder then
							stale[ROOT..'games/'..folder..'/pack.lua'] = true
						end
					else
						failed += 1
					end
				else
					table.insert(missed, job)
				end
				done += 1
			end)
			if cursor % DOWNLOAD_BATCH == 0 then
				repeat task.wait() until done >= cursor or (cursor - done) < DOWNLOAD_BATCH
			end
		end
		repeat task.wait() until done >= #list
		return missed
	end
	local missed = download(jobs)
	if #missed > 0 then
		task.wait(1)
		missed = download(missed)
	end
	for _, job in ipairs(missed) do
		failed += 1
		warn('[Elevate] could not update '..job.Rel..' (hash mismatch or unavailable)')
	end

	for pack in stale do
		pcall(delfile, pack)
	end
	pcall(writefile, INDEX_PATH, HttpService:JSONEncode(verified))
	return written, failed
end

local function getLatestCommit()
	local pin = (readLocal(PIN_PATH) or ''):gsub('%s+', '')
	if #pin == 40 and pin:match('^%x+$') then
		local success, body = pcall(function()
			return game:HttpGet(API_ROOT..'commits/'..pin, true)
		end)
		local decoded = success and decodeJson(body) or nil
		local gone = (success and type(body) == 'string' and body:find('^%s*404'))
			or (success and type(decoded) == 'table' and (decoded.id or decoded.sha) ~= pin)
			or (not success and tostring(body):find('404'))
		if gone then
			pcall(delfile, PIN_PATH)
		else
			pinned = pin
			return pin
		end
	end
	local success, body = pcall(function()
		return game:HttpGet(COMMIT_URL, true)
	end)
	local decoded = success and decodeJson(body) or nil
	local sha = type(decoded) == 'table' and (decoded.id or decoded.sha) or nil
	if type(sha) == 'string' and #sha == 40 then
		return sha
	end
	return nil
end

local function publishFeatures()
	local body = readLocal(ROOT..'profiles/features.json')
	if body and #body > 3 then
		shared.ElevateV4Features = {Ref = SOURCE, Body = body, At = os.clock()}
	end
end

local function runUpdate()
	local commit = getLatestCommit()
	local installed = (readLocal(COMMIT_PATH) or ''):gsub('%s+', '')
	local mainMissing = not isfile(ROOT..'main.lua')

	if commit and installed == commit and not mainMissing then
		shared.ElevateV4Commit = commit
		publishFeatures()
		return
	end
	if commit then ref = commit end

	local contents = decodeJson(fetch('contents.json'))
	if type(contents) ~= 'table' or type(contents.files) ~= 'table' or #contents.files == 0 then
		warn('[Elevate] release contents are unavailable; starting from the cached install')
		publishFeatures()
		return
	end

	local identity = commit or tostring(contents.rev or '')
	if identity ~= '' and installed == identity and not mainMissing then
		shared.ElevateV4Commit = identity
		publishFeatures()
		return
	end

	local previousVersion = parseVersion(readLocal(VERSION_PATH))
	local written, failed = syncContents(contents, mainMissing)
	for _, entry in ipairs(contents.files) do
		local folder = type(entry[1]) == 'string' and entry[1]:match('^games/([^/]+)/files%.txt$')
		local list = folder and readLocal(ROOT..entry[1])
		if list then
			for line in string.gmatch(list, '[^\r\n]+') do
				local name = line:match('^%s*!%s*(.-)%s*$')
				if name and name ~= '' and not name:find('..', 1, true) and isfile(ROOT..'games/'..folder..'/'..name) then
					pcall(delfile, ROOT..'games/'..folder..'/'..name)
				end
			end
		end
	end
	local nextVersion = tostring(contents.version or ''):gsub('%s+$', '')

	if failed == 0 and identity ~= '' then
		pcall(writefile, COMMIT_PATH, identity)
	elseif failed > 0 then
		warn('[Elevate] '..tostring(failed)..' file(s) could not be updated; will retry next launch')
	end
	if nextVersion ~= '' then
		pcall(writefile, VERSION_PATH, 'version = '..nextVersion..'\n')
	end

	shared.ElevateV4Commit = identity ~= '' and identity or nil
	if written > 0 then
		shared.updated = {From = previousVersion, To = nextVersion, Files = written}
	end
	publishFeatures()
end

trail.Mark('update')
if not shared.VapeDeveloper then
	xpcall(runUpdate, function(err)
		warn('[Elevate] update check failed: '..tostring(err))
		shared.AetherTelemetryPending = {{'loader', 'update_check', tostring(err)}}
	end)
else
	publishFeatures()
end

shared.ElevateV4PublicRef = pinned or SOURCE
splash.Show()

local mainSource = readLocal(ROOT..'main.lua')
local mainChunk = mainSource and mainSource:find('%S') and loadstring(mainSource, 'main') or nil
if not mainChunk then
	pcall(writefile, COMMIT_PATH, 'main')
	pcall(delfile, INDEX_PATH)
	local fresh = fetchFile('main.lua')
	mainChunk = fresh and loadstring(fresh, 'main') or nil
	if not mainChunk then
		if shared.ElevateV4Loading == launch then shared.ElevateV4Loading = nil end
		splash.Hide()
		error('[Elevate] main.lua could not be downloaded, try again in a minute', 0)
	end
end
if launch.Superseded then
	launch.Done = true
	return
end
trail.Mark('main')
local ran, runError = pcall(mainChunk, licence)
splash.Hide()
launch.Done = true
if shared.ElevateV4Loading == launch then shared.ElevateV4Loading = nil end
if not ran then
	pcall(writefile, COMMIT_PATH, 'main')
	pcall(delfile, INDEX_PATH)
	if shared.AetherTelemetry then
		pcall(shared.AetherTelemetry.Report, 'startup', 'main_runtime', tostring(runError))
	end
	error(runError, 0)
end
