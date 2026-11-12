local run = function(func)
	local success, result = xpcall(func, debug and debug.traceback or tostring)
	if not success then
		warn('[ElevateV4] Skipped a BedFight module during startup: '..tostring(result))
	end
	return success
end
local cloneref = cloneref or function(obj)
	return obj
end
local vapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new('BindableEvent')
		return self[index]
	end
})

local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local collectionService = cloneref(game:GetService('CollectionService'))
local lightingService = cloneref(game:GetService('Lighting'))
local tweenService = cloneref(game:GetService('TweenService'))
local runService = shared.vape.Libraries.profiler and shared.vape.Libraries.profiler.RunService or cloneref(game:GetService('RunService'))
local task = shared.vape.Libraries.profiler and shared.vape.Libraries.profiler.Task or task

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer

local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction

local bedfight, remotes = {}, {}
local store = {
	inventory = {},
	tools = {},
	anticheat = {Tables = {}, Blocked = {}, Armed = true}
}

local function notif(...)
	return vape:CreateNotification(...)
end
local function disarmAnticheat(disarm)
	local ac = store.anticheat
	if not getloadedmodules then
		return nil
	end

	for _, v in getloadedmodules() do
		if v.Name == 'ClientModule' then
			local ok, mod = pcall(require, v)
			if ok and type(mod) == 'table' and not ac.Tables[mod] then
				local catch = rawget(mod, 'Catch')
				if type(catch) == 'function' then
					ac.Tables[mod] = catch
					if debug.getupvalue then
						for i = 1, 8 do
							local oku, value = pcall(debug.getupvalue, catch, i)
							if not oku then break end
							if value == true then
								ac.Tripped = true
								break
							end
						end
					end
				end
			end
		end
	end

	local count = 0
	for tab, catch in ac.Tables do
		count += 1
		if not (isreadonly and isreadonly(tab)) then
			rawset(tab, 'Catch', disarm and function(reason)
				reason = tostring(reason)
				ac.Blocked[reason] = (ac.Blocked[reason] or 0) + 1
				vapeEvents.AnticheatBlocked:Fire(reason)
			end or catch)
		end
	end

	ac.Armed = not disarm
	ac.Found = count
	return count
end
disarmAnticheat(true)

local function isFriend(plr, recolor)
	if vape.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(vape.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and vape.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function fireRemote(name, ...)
	local remote = remotes[name]
	if not (remote and remote.Parent) then return false end
	remote:FireServer(...)
	return true
end
do
	local filters, hooked, original = {}, nil, nil
	local function listener()
		local list = getconnections(remotes.Knockback.OnClientEvent)
		for _, v in list do
			local ok, source = pcall(debug.info, v.Function, 's')
			if ok and type(source) == 'string' and source:find('KnockbackScript') then
				return v
			end
		end
		return #list == 1 and list[1] or nil
	end
	store.knockbackFilter = function(name, fn)
		filters[name] = fn
		if fn and not original then
			if not (hookfunction and getconnections and remotes.Knockback) then return false end
			local connection = listener()
			if not (connection and connection.Function) then return false end
			hooked = connection.Function
			original = hookfunction(hooked, function(part, velocity, ...)
				local wait = 0
				if typeof(velocity) == 'Vector3' then
					for _, filter in filters do
						local ok, changed, delay = pcall(filter, velocity)
						if ok then
							if changed == nil then return end
							velocity, wait = changed, math.max(wait, delay or 0)
						end
					end
				end
				if wait > 0 then
					task.delay(wait, original, part, velocity, ...)
					return
				end
				return original(part, velocity, ...)
			end)
		elseif not next(filters) and original then
			hookfunction(hooked, original)
			hooked, original = nil, nil
		end
		return original ~= nil
	end
end

local function getItem(name)
	return store.inventory[name]
end
local function heldTool()
	local character = lplr.Character
	if character then
		for _, v in character:GetChildren() do
			if v:IsA('Model') and v:HasTag('Tool') then
				return v
			end
		end
	end
end

local function heldName()
	local tool = heldTool()
	return tool and tool.Name or nil
end
local function serverTool()
	local value = lplr:FindFirstChild('EquippedTool')
	return value and value.Value ~= '' and value.Value or nil
end
local function sentRecently()
	return store.sentTool ~= nil and store.sentAt ~= nil and tick() - store.sentAt < math.clamp(lplr:GetNetworkPing() * 1.5 + 0.1, 0.2, 1)
end
local function equipServer(name, owner)
	store.toolOwner = owner
	local shown = serverTool() == name
	if sentRecently() then
		if store.sentTool == name then return shown end
	elseif shown then
		return true
	end
	store.sentTool, store.sentAt = name, tick()
	store.toolDirty = true
	fireRemote('EquipTool', name)
	return false
end
local function syncTool(owner)
	if not store.toolDirty then return end
	if owner and store.toolOwner and store.toolOwner ~= owner then return end
	store.toolDirty = nil
	store.toolOwner = nil
	local held = heldName()
	local holding = serverTool()
	if sentRecently() then
		holding = store.sentTool or nil
	end
	if holding ~= held then
		store.sentTool, store.sentAt = held or false, tick()
		fireRemote('EquipTool', held)
	end
end

local function getSword()
	local best, rate, damage = nil, 0, 0
	for name in store.inventory do
		local data = bedfight.SwordsData and bedfight.SwordsData[name]
		if type(data) == 'table' and data.Damage then
			local dps = data.Damage / math.max(data.DamageCooldown or 0.3, 0.05)
			if dps > rate or (dps == rate and data.Damage > damage) then
				best, rate, damage = name, dps, data.Damage
			end
		end
	end
	return best
end
local function getTool(blockName)
	local best, damage = nil, 0
	for name in store.inventory do
		local data = bedfight.MiningData and bedfight.MiningData[name]
		if type(data) == 'table' and data.Cooldown then
			local hit = data.Damages and data.Damages[blockName] or data.DefaultDamage or 0
			if hit > damage then
				best, damage = name, hit
			end
		end
	end
	return best, damage
end
local function getBlock()
	local best, amount = nil, 0
	for name, count in store.inventory do
		local data = bedfight.ItemsData and bedfight.ItemsData[name]
		local template = data and data.Class == 'Blocks' and bedfight.Blocks:FindFirstChild(name)
		if template and template:IsA('BasePart') and not name:find('TNT') and count > amount then
			best, amount = name, count
		end
	end
	return best
end

local function snap(vec)
	return Vector3.new(math.round(vec.X / 3) * 3, math.round(vec.Y / 3) * 3, math.round(vec.Z / 3) * 3)
end
store.blockId = 800000
function store.placeBlock(name, position)
	local template = bedfight.Blocks and bedfight.Blocks:FindFirstChild(name)
	local container = workspace:FindFirstChild('FakeBlocksContainer')
	if not (template and container and bedfight.Block) then return false end
	store.blockId += 1
	local id, queue = store.blockId, bedfight.Block.BlocksInQueue
	local fake = template:Clone()
	fake:PivotTo(CFrame.new(position))
	fake.Parent = container
	queue[id] = {Block = fake, LastTime = time()}
	fireRemote('PlaceBlock', name, id, position)
	task.delay(3, function()
		if queue[id] then
			queue[id] = nil
		end
		fake:Destroy()
	end)
	return fake
end
function store.buildable(position)
	local ok, info = bedfight.Block.GetBuildResult(nil, position, 3)
	return ok and info and not info.InsideAntiBuild and info.InBounds ~= false, info
end
store.catchOrder = {'Wool$', '^Wood Plank$', '^Stone Brick$', '^Blastproof Ceramic$', '^Obsidian$', '^Fake Block$'}
function store.catchBlock(owner, lead)
	if not entitylib.isAlive or store.split then return false end
	local name
	for _, pattern in store.catchOrder do
		for item, count in store.inventory do
			if count > 0 and item:find(pattern) and bedfight.Blocks:FindFirstChild(item) then
				name = item
				break
			end
		end
		if name then break end
	end
	if not name then return false, 'none' end
	local root = entitylib.character.RootPart
	local feet = root.Position.Y - entitylib.character.HipHeight - root.Size.Y / 2 + math.min(root.AssemblyLinearVelocity.Y, 0) * (lead or 0.05)
	local cell = Vector3.new(math.round(root.Position.X / 3) * 3, math.floor((feet - 1.5) / 3) * 3, math.round(root.Position.Z / 3) * 3)
	local _, info = store.buildable(cell)
	if info and info.Collided then return true, cell end
	equipServer(name, owner)
	return store.placeBlock(name, cell) and true or false, cell
end

local function mapBlocks()
	local info = bedfight.GameInfo and bedfight.GameInfo:FindFirstChild('MapInfo')
	local value = info and info:FindFirstChild('BlocksContainer')
	return value and value.Value or nil
end
local blockRay = RaycastParams.new()
blockRay.FilterType = Enum.RaycastFilterType.Include
local function blockParams()
	local list = {}
	for _, name in {'PlayersBlocksContainer', 'BedsContainer'} do
		local container = workspace:FindFirstChild(name)
		if container then
			table.insert(list, container)
		end
	end
	local map = mapBlocks()
	if map then
		table.insert(list, map)
	end
	blockRay.FilterDescendantsInstances = list
	return blockRay
end

local function canFight()
	return entitylib.isAlive and lplr:GetAttribute('PVP') == true
end

local function inMatch()
	return lplr.Team ~= nil and lplr.Team.Name ~= 'Spectators'
end
local split
local function bodyRoot()
	return entitylib.character.RootPart
end

local function realRoot()
	return split and split.Real or entitylib.character.RootPart
end

local function splitJoints(state, part)
	for _, joint in state.Joints do
		if joint[3] then
			local attachment = part:FindFirstChild(joint[3])
			if attachment then
				joint[1][joint[2]] = attachment
			end
		else
			joint[1][joint[2]] = part
		end
	end
end

local function mergeRoot(owner, force)
	if not split then return end
	if owner then
		split.Owners[owner] = nil
	end
	if not force and next(split.Owners) then return end
	local state = split
	split = nil
	store.split = nil
	local real, clone, character = state.Real, state.Clone, state.Character
	if entitylib.character and entitylib.character.RootPart == clone then
		entitylib.character.RootPart = real
		entitylib.character.HumanoidRootPart = real
	end
	if real.Parent and clone.Parent and character.Parent then
		local cf, velocity = clone.CFrame, clone.AssemblyLinearVelocity
		character.Parent = replicatedStorage
		real.Parent = character
		splitJoints(state, real)
		clone:Destroy()
		character.PrimaryPart = real
		character.Parent = state.Home
		real.CanCollide = true
		if isnetworkowner(real) then
			real.CFrame = cf
			real.AssemblyLinearVelocity = velocity
		end
	else
		pcall(clone.Destroy, clone)
	end
end

local function splitRoot(owner)
	if split then
		split.Owners[owner] = true
		return split.Real
	end
	if not entitylib.isAlive then return nil end
	local character = lplr.Character
	local real = entitylib.character.RootPart
	local home = character and character.Parent
	if not (home and home:IsDescendantOf(workspace) and real and real.Parent == character and isnetworkowner(real)) then return nil end

	local joints = {}
	for _, v in character:GetDescendants() do
		if v:IsA('Constraint') then
			for _, prop in {'Attachment0', 'Attachment1'} do
				local ok, attachment = pcall(function()
					return v[prop]
				end)
				if ok and attachment and attachment.Parent == real then
					table.insert(joints, {v, prop, attachment.Name})
				end
			end
		elseif v:IsA('JointInstance') and v.Parent ~= real and v.Name ~= 'HitboxMotor' then
			if v.Part0 == real then
				table.insert(joints, {v, 'Part0'})
			elseif v.Part1 == real then
				table.insert(joints, {v, 'Part1'})
			end
		end
	end
	if #joints == 0 then return nil end

	local velocity = real.AssemblyLinearVelocity
	character.Parent = replicatedStorage
	local clone = real:Clone()
	clone.Parent = character
	real.Parent = workspace
	split = {Real = real, Clone = clone, Character = character, Home = home, Joints = joints, Owners = {[owner] = true}, GoalAt = 0}
	splitJoints(split, clone)
	character.PrimaryPart = clone
	character.Parent = home
	clone.AssemblyLinearVelocity = velocity
	real.CanCollide = false
	entitylib.character.RootPart = clone
	entitylib.character.HumanoidRootPart = clone
	store.split = split
	return real
end
local function sendRoot(cframe)
	if not split then return end
	split.Goal, split.GoalAt = cframe, tick()
	if isnetworkowner(split.Real) then
		split.Real.CFrame = cframe
		split.Real.AssemblyLinearVelocity = Vector3.zero
	end
end

run(function()
	entitylib.targetCheck = function(ent)
		if ent.TeamCheck then
			return ent:TeamCheck()
		end
		if ent.NPC then return true end
		if isFriend(ent.Player) then return false end
		if not select(2, whitelist:get(ent.Player)) then return false end
		if not vape.Categories.Main.Options['Teams by server'].Enabled then return true end
		local mine, theirs = lplr.Team, ent.Player.Team
		if not mine or not theirs or mine ~= theirs then return true end
		return mine.Name == 'Spectators'
	end

	entitylib.isVulnerable = function(ent)
		if ent.Health <= 0 or ent.Character:GetAttribute('Forcefield') then return false end
		return ent.NPC or ent.Player:GetAttribute('PVP') == true
	end

	entitylib.getUpdateConnections = function(ent)
		local hum = ent.Humanoid
		return {
			hum:GetPropertyChangedSignal('Health'),
			hum:GetPropertyChangedSignal('MaxHealth'),
			{
				Connect = function()
					ent.Friend = ent.Player and isFriend(ent.Player) or nil
					ent.Target = ent.Player and isTarget(ent.Player) or nil
					return {Disconnect = function() end}
				end
			}
		}
	end

	entitylib.getEntityColor = function(ent)
		ent = ent.Player
		if not (ent and vape.Categories.Main.Options['Use team color'].Enabled) then return end
		if isFriend(ent, true) then
			return Color3.fromHSV(vape.Categories.Friends.Options['Friends color'].Hue, vape.Categories.Friends.Options['Friends color'].Sat, vape.Categories.Friends.Options['Friends color'].Value)
		end
		return ent.Team and ent.Team.Name ~= 'Spectators' and ent.TeamColor.Color or nil
	end
end)
entitylib.start()

run(function()
	local started = tick()

	local function gameRequire(module)
		local deadline = tick() + 10
		repeat
			local known = false
			if getloadedmodules then
				local ok, list = pcall(getloadedmodules)
				if ok and type(list) == 'table' then
					known = true
					if table.find(list, module) then break end
				end
			end
			if not known and tick() - started > 5 then break end
			task.wait(0.1)
		until tick() > deadline
		return require(module)
	end

	local function child(parent, ...)
		for _, name in {...} do
			parent = parent and parent:WaitForChild(name, 20)
		end
		return parent or error('BedFight is missing '..table.concat({...}, '.'))
	end

	local folder = child(replicatedStorage, 'Remotes')
	local items = child(folder, 'ItemsRemotes')
	for _, name in {'SwordHit', 'EquipTool', 'ShootProjectile', 'PlaceBlock', 'MineBlock', 'Eat', 'DeployBalloon', 'PopBalloon', 'DropItem'} do
		remotes[name] = child(items, name)
	end
	for _, name in {'Queue', 'Knockback', 'PutItemInChest', 'TakeItemFromChest', 'PurchaseItemShopItem', 'TeamUpgrade', 'PlayEmote', 'QueueToOpenServer', 'UpdateLeaderboardRanking', 'DamageIndicator', 'VoteMap'} do
		remotes[name] = child(folder, name)
	end
	remotes.Join = child(folder, 'GameRemotes', 'Join')
	pcall(function()
		local kits = folder:FindFirstChild('KitsRemotes')
		local jet = kits and kits:FindFirstChild('Jetpack')
		if jet then remotes.Jetpack = jet end
	end)

	local modules = child(replicatedStorage, 'Modules')
	local data = child(modules, 'DataModules')
	local handlers = child(replicatedStorage, 'ToolHandlers')
	bedfight = {
		GameInfo = child(replicatedStorage, 'GameInfo'),
		Blocks = child(replicatedStorage, 'Blocks'),
		Capes = child(replicatedStorage, 'Capes'),
		TeamUpgrades = child(replicatedStorage, 'TeamUpgrades'),
		TeamChests = child(replicatedStorage, 'TeamChestsStorage'),
		Lobby = child(replicatedStorage, 'LobbyObject'),
		ItemsData = gameRequire(child(data, 'ItemsData')),
		SwordsData = gameRequire(child(data, 'SwordsData')),
		RangedData = gameRequire(child(data, 'RangedData')),
		ProjectilesData = gameRequire(child(data, 'ProjectilesData')),
		BlocksData = gameRequire(child(data, 'BlocksData')),
		MiningData = gameRequire(child(data, 'MiningData')),
		ItemShopData = gameRequire(child(data, 'ItemShopData')),
		TeamUpgradesData = gameRequire(child(data, 'TeamUpgradesData')),
		CapesData = gameRequire(child(data, 'CapesData')),
		EmotesData = gameRequire(child(data, 'EmotesData')),
		RanksData = gameRequire(child(data, 'RanksData')),
		InventoryHandler = gameRequire(child(modules, 'InventoryHandler')),
		ProjectilesController = gameRequire(child(modules, 'ProjectilesController')),
		PlayerConfig = gameRequire(child(modules, 'PlayerConfigurations')),
		ViewModelHandler = gameRequire(child(modules, 'ViewModelHandler')),
		VelocityUtils = gameRequire(child(modules, 'VelocityUtils')),
		JetpackState = gameRequire(child(modules, 'JetpackState')),
		ButtonProperties = gameRequire(child(modules, 'ButtonProperties')),
		Signals = gameRequire(child(modules, 'Signals')),
		Sword = gameRequire(child(handlers, 'Sword')),
		Ranged = gameRequire(child(handlers, 'Ranged')),
		Block = gameRequire(child(handlers, 'Block'))
	}

	local inventory = child(lplr, 'Inventory')
	local function refresh()
		table.clear(store.inventory)
		for _, v in inventory:GetChildren() do
			if v:IsA('NumberValue') and v.Name ~= '' then
				store.inventory[v.Name] = v.Value
			end
		end
		store.tools.sword = getSword()
		vapeEvents.InventoryChanged:Fire()
	end
	local function watch(v)
		if not v:IsA('NumberValue') then return end
		v:GetPropertyChangedSignal('Value'):Connect(refresh)
		v:GetPropertyChangedSignal('Name'):Connect(refresh)
	end
	vape:Clean(inventory.ChildAdded:Connect(function(v)
		watch(v)
		refresh()
	end))
	vape:Clean(inventory.ChildRemoved:Connect(refresh))
	for _, v in inventory:GetChildren() do
		watch(v)
	end
	refresh()

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local function count(value, item)
		if not value then return end
		local last = value.Value
		vape:Clean(value:GetPropertyChangedSignal('Value'):Connect(function()
			if value.Value > last then
				item:Increment()
			end
			last = value.Value
		end))
	end
	task.spawn(function()
		local stats = lplr:WaitForChild('leaderstats', 20)
		count(stats and stats:WaitForChild('Kills', 5), kills)
		local gameStats = lplr:WaitForChild('GameStats', 20)
		count(gameStats and gameStats:WaitForChild('Beds Broken', 5), beds)
	end)

	local gui = lplr:FindFirstChildOfClass('PlayerGui')
	if gui then
		vape:Clean(gui.ChildAdded:Connect(function(v)
			if v:IsA('LayerCollector') or store.anticheat.Armed then return end
			task.delay(1, function()
				if not store.anticheat.Armed then
					disarmAnticheat(true)
				end
			end)
		end))
	end

	vape:Clean(entitylib.Events.LocalAdded:Connect(function()
		store.sentTool, store.toolDirty, store.toolOwner = nil, nil, nil
	end))

	if type(vape.SetGameInfo) == 'function' then
		vape:SetGameInfo({
			Name = 'BedFight',
			GetKit = function()
				local kit = lplr:FindFirstChild('Kit')
				return kit and kit.Value ~= '' and kit.Value or nil
			end
		})
	end

	vape:Clean(function()
		disarmAnticheat(false)
		for _, v in vapeEvents do
			v:Destroy()
		end
		table.clear(vapeEvents)
		table.clear(remotes)
		table.clear(bedfight)
		table.clear(store)
	end)
end)

run(function()
	local fov = vape.Libraries.fovcircle
	local history = setmetatable({}, {__mode = 'k'})
	local floorRay = RaycastParams.new()
	floorRay.FilterType = Enum.RaycastFilterType.Exclude
	floorRay.RespectCanCollide = true

	store.sortList = {'Distance', 'Cursor', 'Angle', 'Lowest Health', 'Highest Health'}

	store.targets = function(opts)
		local found = {}
		if not entitylib.isAlive then return found end
		local origin = opts.Origin or entitylib.character.RootPart.Position
		local look = gameCamera.CFrame.LookVector
		local sort = opts.Sort or 'Distance'
		local list = {}
		for _, ent in entitylib.List do
			if ent.Player and not opts.Players then continue end
			if ent.NPC and not opts.NPCs then continue end
			if not (ent.Targetable and ent.RootPart and entitylib.isVulnerable(ent)) then continue end
			local delta = ent.RootPart.Position - origin
			local distance = delta.Magnitude
			if distance > opts.Range then continue end
			local pixels = 0
			if fov and (opts.FOV or sort == 'Cursor') then
				local inside, away = fov.ContainsEntity(ent, opts.FOV or math.huge)
				if opts.FOV and not inside then continue end
				pixels = away
			end
			local key = distance
			if sort == 'Cursor' then
				key = pixels
			elseif sort == 'Angle' then
				key = distance > 0.1 and math.acos(math.clamp(look:Dot(delta.Unit), -1, 1)) or 0
			elseif sort == 'Lowest Health' then
				key = ent.Health
			elseif sort == 'Highest Health' then
				key = -ent.Health
			end
			table.insert(list, {Entity = ent, Key = ent.Target and -math.huge or key, Distance = distance})
		end
		table.sort(list, function(a, b)
			if a.Key == b.Key then
				return a.Distance < b.Distance
			end
			return a.Key < b.Key
		end)
		for _, v in list do
			if opts.Walls and entitylib.Wallcheck(opts.WallOrigin or origin, v.Entity.RootPart.Position) then continue end
			table.insert(found, v.Entity)
			if #found >= (opts.Limit or 1) then break end
		end
		return found
	end

	local function motion(ent)
		local root = ent.RootPart
		local now = os.clock()
		local list = history[ent]
		if not list or now - list[#list].At > 0.5 then
			list = {}
			history[ent] = list
		end
		table.insert(list, {At = now, Position = root.Position})
		while #list > 2 and now - list[2].At >= 0.2 do
			table.remove(list, 1)
		end
		local first = list[1]
		if now - first.At < 0.1 then
			return root.AssemblyLinearVelocity
		end
		return (root.Position - first.Position) / (now - first.At)
	end
	store.motion = motion

	store.aimPoint = function(origin, speed, gravity, ent, part, scale)
		local root = ent.RootPart
		local velocity = motion(ent)
		local sideways, upwards = scale and scale.Horizontal or 1, scale and scale.Vertical or 1
		local flat = Vector3.new(velocity.X, 0, velocity.Z) * sideways
		local airborne = ent.Humanoid and ent.Humanoid.FloorMaterial == Enum.Material.Air
		local offset = part.Position - root.Position
		local pull = Vector3.new(0, -gravity, 0)

		local floor
		if airborne then
			floorRay.FilterDescendantsInstances = {workspace:FindFirstChild('PlayersContainer') or ent.Character, gameCamera}
			local ground = workspace:Raycast(root.Position, Vector3.new(0, -60, 0), floorRay)
			floor = ground and ground.Position.Y + (ent.HipHeight or 3)
		end
		local function at(t)
			local position = root.Position + flat * t
			if airborne then
				local y = root.Position.Y + velocity.Y * t - workspace.Gravity * t * t / 2
				if floor then
					y = math.max(y, floor)
				end
				position = Vector3.new(position.X, root.Position.Y + (y - root.Position.Y) * upwards, position.Z)
			end
			return position + offset
		end

		local lead = math.clamp(lplr:GetNetworkPing() + 0.05, 0, 0.4)
		local t = (at(lead) - origin).Magnitude / speed
		local aim
		for _ = 1, 8 do
			aim = at(lead + t) - pull * (t * t / 2)
			t = (aim - origin).Magnitude / speed
		end
		aim = at(lead + t) - pull * (t * t / 2)
		if aim ~= aim then return nil end
		return aim
	end

	store.ring = function(module, name, tooltip)
		local api = {}
		local circle, Show, Colour, Thickness

		function api.Update(state)
			if circle then
				circle:Destroy()
				circle = nil
			end
			if state == nil then
				state = module.Enabled
			end
			if state and Show.Enabled and fov and fov.New then
				circle = fov.New({
					Name = name,
					Parent = vape.gui,
					Visible = function()
						return module.Enabled and Show.Enabled
					end,
					Radius = function()
						return api.Radius and api.Radius() or 0
					end,
					Colour = function()
						return Color3.fromHSV(Colour.Hue, Colour.Sat, Colour.Value)
					end,
					Thickness = function()
						return Thickness.Value
					end
				})
			end
		end

		Show = module:CreateGroup({
			Name = 'FOV Circle',
			Tooltip = tooltip,
			Function = function(callback)
				api.Update()
			end
		})
		Colour = Show:CreateColorSlider({
			Name = 'Circle colour',
			Darker = true
		})
		Thickness = Show:CreateSlider({
			Name = 'Circle thickness',
			Min = 1,
			Max = 8,
			Default = 1,
			Darker = true,
			Tooltip = 'Width of the ring in pixels'
		})
		api.Show = Show
		return api
	end

	local voidState = {Map = nil, Floor = nil, Scanning = false}
	local VOID_MARGIN = 6
	function store.voidFloor()
		local map = mapBlocks()
		if map ~= voidState.Map then
			voidState.Map, voidState.Floor = map, nil
			if map and not voidState.Scanning then
				voidState.Scanning = true
				task.spawn(function()
					local low, started = math.huge, os.clock()
					for _, v in map:GetDescendants() do
						if v:IsA('BasePart') then
							local bottom = v.Position.Y - v.Size.Y / 2
							if bottom < low then low = bottom end
						end
						if os.clock() - started > 0.002 then
							task.wait()
							started = os.clock()
							if voidState.Map ~= map then break end
						end
					end
					if voidState.Map == map and low < math.huge then
						voidState.Floor = low - VOID_MARGIN
					end
					voidState.Scanning = false
				end)
			end
		end
		return voidState.Floor
	end
	function store.inVoid(root, lead)
		local floor = store.voidFloor()
		if not floor then return false end
		root = root or bodyRoot()
		local vy = math.min(root.AssemblyLinearVelocity.Y, 0)
		if root.Position.Y + vy * (lead or 0.3) >= floor then return false end
		return workspace:Raycast(root.Position, Vector3.new(0, -math.max(root.Position.Y - floor, 0) - 50, 0), blockParams()) == nil
	end

	store.inCombat = function()
		if not entitylib.isAlive then return false end
		local health = entitylib.character.Humanoid.Health
		if store.seenHealth and health < store.seenHealth - 0.5 then
			store.hurtAt = tick()
		end
		store.seenHealth = health
		if tick() - (store.hurtAt or 0) < 5 or tick() - (store.melee or 0) < 3 then return true end
		return #store.targets({Range = 20, Players = true, NPCs = true}) > 0
	end
end)

run(function()
	vape:Clean(entitylib.Events.LocalRemoved:Connect(function()
		if split then
			local hum = split.Character.Parent and split.Character:FindFirstChildOfClass('Humanoid')
			if hum and hum.Health > 0 and lplr.Character == split.Character then
				mergeRoot(nil, true)
				return
			end
			local clone = split.Clone
			split = nil
			store.split = nil
			pcall(clone.Destroy, clone)
		end
	end))
	vape:Clean(runService.Heartbeat:Connect(function()
		if not split then return end
		local real, clone = split.Real, split.Clone
		if not (entitylib.isAlive and real.Parent and clone.Parent) then
			mergeRoot(nil, true)
			return
		end
		if not isnetworkowner(real) then return end
		if split.GoalAt > tick() - 0.1 then
			real.CFrame = split.Goal
		else
			real.CFrame = clone.CFrame
		end
		real.AssemblyLinearVelocity = Vector3.zero
	end))
	vape:Clean(function()
		mergeRoot(nil, true)
	end)
end)

if not bedfight.Sword then
	notif('ElevateV4', 'BedFight did not start because the game was still loading. Reinject in a moment.', 15, 'alert')
elseif store.anticheat.Tripped then
	notif('ElevateV4', 'The game\'s anticheat had already flagged this session before ElevateV4 loaded, so nothing you do reaches the server. Rejoin and load ElevateV4 before any other script.', 30, 'alert')
end

for _, v in {
	'Killaura', 'Reach', 'Speed', 'Fly', 'HitBoxes', 'SilentAim', 'Disabler', 'MurderMystery', 'AutoObby', 'MotionBlur'
} do
	vape:Remove(v)
end
