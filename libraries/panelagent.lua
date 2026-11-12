local API = 'https://api.ElevateV4.xyz'
local SETTINGS_PATH = 'ElevateV4/profiles/telemetry.json'
local OWNER_NAME = 'ElevateV4Owner'
local BEAT_SECONDS = 8

local cloneref = cloneref or function(obj) return obj end
local requestFunction = request or http_request or (syn and syn.request) or (http and http.request)
local httpService = cloneref(game:GetService('HttpService'))
local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local marketplaceService = cloneref(game:GetService('MarketplaceService'))

local old = shared.AetherPanel
if type(old) == 'table' and type(old.Stop) == 'function' then
	pcall(old.Stop, 'restart')
end

local player = playersService.LocalPlayer
if not player then return end

local api = {
	IsOwner = player.Name == OWNER_NAME,
	Detected = {},
	Changed = Instance.new('BindableEvent'),
	Enabled = type(requestFunction) == 'function',
	Silenced = false
}

local alive = true
local detected = api.Detected
local blockedTools = {}
local connections = {}

local function readLink()
	local link = ''
	pcall(function()
		local telemetry = shared.AetherTelemetry
		if type(telemetry) == 'table' and type(telemetry.GetLink) == 'function' then
			link = tostring(telemetry.GetLink() or '')
		end
	end)
	if link == '' then
		pcall(function()
			local body = isfile and isfile(SETTINGS_PATH) and readfile(SETTINGS_PATH) or nil
			local decoded = type(body) == 'string' and select(2, pcall(httpService.JSONDecode, httpService, body)) or nil
			if type(decoded) == 'table' and type(decoded.Link) == 'string' then link = decoded.Link end
		end)
	end
	return link
end
readLink()

local function send(route, body, authorized)
	if not api.Enabled or not alive then return nil end
	local headers = {['Content-Type'] = 'application/json'}
	if authorized then
		local link = readLink()
		if link ~= '' then headers.Authorization = 'Link ' .. link end
	end
	local ok, response = pcall(requestFunction, {
		Url = API .. route,
		Method = 'POST',
		Headers = headers,
		Body = httpService:JSONEncode(body)
	})
	if not ok or type(response) ~= 'table' then return nil end
	local status = tonumber(response.StatusCode or response.Status) or 0
	local decoded = type(response.Body) == 'string' and select(2, pcall(httpService.JSONDecode, httpService, response.Body)) or nil
	return status, type(decoded) == 'table' and decoded or nil
end

local function jobId()
	local id = tostring(game.JobId or '')
	if id == '' then id = 'local-' .. tostring(game.PlaceId) .. '-' .. tostring(game.PrivateServerId or '') end
	return id
end

local function version()
	local value
	pcall(function()
		value = readfile('ElevateV4/profiles/version.txt'):match('version%s*=%s*([%w%.%-_]+)')
	end)
	return value or 'unknown'
end

function api.GameName()
	local name
	pcall(function()
		local info = marketplaceService:GetProductInfo(game.PlaceId)
		if type(info) == 'table' and type(info.Name) == 'string' and info.Name ~= '' then
			name = info.Name
		end
	end)
	if name then return name end
	if type(game.Name) == 'string' and game.Name ~= '' then return game.Name end
	return 'this game'
end

local function kick(reason)
	if pcall(function() player:Kick(reason) end) then return true end
	if pcall(function() game:Shutdown() end) then return true end
	return false
end

local function kill()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	if not character or not humanoid then
		local waitUntil = os.clock() + 3
		while alive and os.clock() < waitUntil do
			task.wait(0.2)
			character = player.Character
			humanoid = character and character:FindFirstChildOfClass('Humanoid')
			if humanoid then break end
		end
	end
	if not character or not humanoid then return false end
	local function once()
		pcall(function() humanoid.Health = 0 end)
		pcall(function() humanoid:TakeDamage(humanoid.MaxHealth) end)
		pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Dead) end)
		for _, part in character:GetChildren() do
			if part:IsA('BasePart') then pcall(function() part:BreakJoints() end) end
		end
		pcall(function() character:BreakJoints() end)
	end
	once()
	task.spawn(function()
		local deadline = os.clock() + 2
		while alive and os.clock() < deadline do
			pcall(once)
			task.wait(0.1)
		end
	end)
	return true
end

local function say(message)
	if type(message) ~= 'string' or message == '' then return false end
	local sent = false
	pcall(function()
		local textChat = cloneref(game:GetService('TextChatService'))
		if textChat.ChatVersion == Enum.ChatVersion.TextChatService then
			local channels = textChat:FindFirstChild('TextChannels')
			local channel = channels and (channels:FindFirstChild('RBXGeneral') or channels:FindFirstChild('RBXGame'))
			if channel and channel:IsA('TextChannel') then
				channel:SendAsync(message)
				sent = true
			end
		end
	end)
	if not sent then
		pcall(function()
			local events = replicatedStorage:FindFirstChild('DefaultChatSystemChatEvents')
			local remote = events and events:FindFirstChild('SayMessageRequest')
			if remote then
				remote:FireServer(message, 'All')
				sent = true
			end
		end)
	end
	if not sent then
		pcall(function()
			local remote = replicatedStorage:FindFirstChild('SayMessageRequest')
			if remote then
				remote:FireServer(message, 'All')
				sent = true
			end
		end)
	end
	return sent
end

local OFFENSIVE_CATEGORIES = {Combat = true, Blatant = true}
local OFFENSIVE_NAMES = 'killaura,aimbot,silentaim,triggerbot,autoclicker,reach,aura,aimassist,autoshoot,bowaimbot,spinbot'

local function offensive(module)
	if OFFENSIVE_CATEGORIES[tostring(module.Category or '')] then return true end
	local name = tostring(module.Name or ''):lower()
	for word in OFFENSIVE_NAMES:gmatch('[^,]+') do
		if name:find(word, 1, true) then return true end
	end
	return false
end
local function silenceModules()
	local vape = shared.vape
	if type(vape) ~= 'table' then return false end
	local disabled = 0
	local function consider(module)
		if type(module) ~= 'table' or not module.Enabled or type(module.Toggle) ~= 'function' then return end
		if offensive(module) and pcall(module.Toggle, module) then disabled += 1 end
	end
	if type(vape.Modules) == 'table' then
		for _, module in vape.Modules do consider(module) end
	end
	for _, panel in {vape.Legit, vape.Kits} do
		if type(panel) == 'table' and type(panel.Modules) == 'table' then
			for _, module in panel.Modules do consider(module) end
		end
	end
	return disabled > 0
end

local function blockTool(tool)
	if typeof(tool) ~= 'Instance' or not tool:IsA('Tool') then return end
	local first = not blockedTools[tool]
	blockedTools[tool] = true
	if first then
		pcall(function()
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass('Humanoid')
			if humanoid then humanoid:UnequipTools() end
		end)
	end
	if type(getconnections) == 'function' then
		pcall(function()
			for _, connection in getconnections(tool.Activated) do
				pcall(function() connection:Disable() end)
				pcall(function() connection:Disconnect() end)
			end
		end)
	end
end

local function blockTools()
	pcall(function()
		local character = player.Character
		if character then
			for _, child in character:GetChildren() do blockTool(child) end
		end
		local backpack = player:FindFirstChildOfClass('Backpack')
		if backpack then
			for _, child in backpack:GetChildren() do blockTool(child) end
		end
	end)
end
local watched = {}

local function watch(character)
	if not api.Silenced or not alive or typeof(character) ~= 'Instance' or watched[character] then return end
	watched[character] = true
	silenceModules()
	pcall(function()
		table.insert(connections, character.ChildAdded:Connect(function(child)
			if child:IsA('Tool') then blockTool(child) end
		end))
	end)
	blockTools()
end

local function unarm()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	if not humanoid then return end
	local holds = false
	for _, child in character:GetChildren() do
		if child:IsA('Tool') then
			holds = true
			break
		end
	end
	if not holds then return end
	pcall(function() humanoid:UnequipTools() end)
	local backpack = player:FindFirstChildOfClass('Backpack')
	if not backpack then return end
	for _, child in character:GetChildren() do
		if child:IsA('Tool') then pcall(function() child.Parent = backpack end) end
	end
end
local function enforce()
	if not api.Silenced or not alive then return end
	pcall(silenceModules)
	pcall(blockTools)
	pcall(unarm)
end

local enforcing = false

function api.Silence()
	if api.Silenced and enforcing then return end
	api.Silenced = true
	enforce()
	pcall(watch, player.Character)
	if enforcing then return end
	enforcing = true
	task.spawn(function()
		while alive do
			task.wait(0.5)
			pcall(enforce)
		end
	end)
end

pcall(function()
	local backpack = player:FindFirstChildOfClass('Backpack')
	if backpack then
		table.insert(connections, backpack.ChildAdded:Connect(function() blockTools() end))
	end
	if player.Character then watch(player.Character) end
	table.insert(connections, player.CharacterAdded:Connect(watch))
end)

local function handle(entry)
	local verb = type(entry.command) == 'string' and entry.command or nil
	if verb == 'kick' then
		kick('Get shitted on by the owner')
	elseif verb == 'kill' then
		kill()
	elseif verb == 'uninject' then
		local vape = shared.vape
		api.Enabled = false
		alive = false
		if type(vape) == 'table' and type(vape.Uninject) == 'function' then
			pcall(vape.Uninject, vape)
		end
		if type(vape) == 'table' and typeof(vape.gui) == 'Instance' then
			pcall(function() vape.gui:Destroy() end)
		end
		local playerGui = player:FindFirstChildOfClass('PlayerGui')
		if playerGui then
			for _, screen in playerGui:GetChildren() do
				if screen:IsA('ScreenGui') and screen:GetAttribute('ElevateV4') then
					pcall(function() screen:Destroy() end)
				end
			end
		end
		shared.vape = nil
		if shared.AetherPanel == api then shared.AetherPanel = nil end
	elseif verb == 'reveal' then
		say(type(entry.text) == 'string' and entry.text or ('I am exploiting in ' .. api.GameName() .. ' with ElevateV4'))
	elseif verb == 'unhittable' then
		api.Silence()
	end
end

local function updateDetected(users)
	local nextList = {}
	for _, entry in users do
		local userId = tonumber(entry.userId)
		local other = userId and playersService:GetPlayerByUserId(userId) or nil
		if other and other ~= player and other.Parent then
			table.insert(nextList, {UserId = other.UserId, Name = other.Name, Player = other})
		end
	end
	local changed = #nextList ~= #detected
	if not changed then
		for index, entry in detected do
			if not nextList[index] or nextList[index].UserId ~= entry.UserId then
				changed = true
				break
			end
		end
	end
	table.clear(detected)
	for _, entry in nextList do table.insert(detected, entry) end
	if changed then pcall(function() api.Changed:Fire() end) end
end

local function beat()
	if not api.Enabled or not alive then return end
	local status, body = send('/v1/panel/beat', {
		userId = player.UserId,
		name = player.Name,
		jobId = jobId(),
		placeId = tostring(game.PlaceId),
		version = version()
	})
	if status ~= 200 or type(body) ~= 'table' then return end
	if type(body.users) == 'table' then updateDetected(body.users) end
	if type(body.commands) == 'table' then
		for _, entry in body.commands do
			if type(entry) == 'table' then pcall(handle, entry) end
		end
	end
end

function api.Refresh()
	api.Wake = true
end

function api.Send(userId, verb, text)
	if not api.IsOwner then return false, 'Only the script owner can use the Panel' end
	if not api.Enabled then return false, 'This executor cannot send HTTP requests' end
	if readLink() == '' then return false, 'Link your account first (GUI settings > General > Link code)' end
	local status, body = send('/v1/panel/command', {
		target = tostring(userId),
		jobId = jobId(),
		command = verb,
		text = text
	}, true)
	if status == 200 and type(body) == 'table' and body.ok then return true end
	if status == 401 then return false, 'That link code is not valid any more, make a new one' end
	if status == 403 then return false, 'The Panel only accepts the script owner account' end
	if status == 429 then return false, 'The Panel is rate limited, try again shortly' end
	if status == nil then return false, 'The Panel backend could not be reached' end
	return false, 'The Panel refused the command (' .. tostring(status) .. ')'
end

function api.Stop()
	alive = false
	api.Enabled = false
	for _, connection in connections do
		pcall(function() connection:Disconnect() end)
	end
	table.clear(connections)
	table.clear(blockedTools)
	pcall(function() api.Changed:Destroy() end)
	if shared.AetherPanel == api then shared.AetherPanel = nil end
end

shared.AetherPanel = api

task.spawn(function()
	while alive do
		pcall(beat)
		local waited = 0
		api.Wake = false
		while alive and not api.Wake and waited < BEAT_SECONDS do
			task.wait(0.25)
			waited += 0.25
		end
	end
end)

return api
