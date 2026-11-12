local run = function(func)
	local success, result = xpcall(func, debug and debug.traceback or tostring)
	if not success then
		warn('[ElevateV4] Skipped a SkyWars module during startup: '..tostring(result))
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
local httpService = cloneref(game:GetService('HttpService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local tweenService = cloneref(game:GetService('TweenService'))
local runService = shared.vape.Libraries.profiler and shared.vape.Libraries.profiler.RunService or cloneref(game:GetService('RunService'))
local task = shared.vape.Libraries.profiler and shared.vape.Libraries.profiler.Task or task

local isnetworkowner = isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer

local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local uipallet = vape.Libraries.uipallet
local tween = vape.Libraries.tween
local color = vape.Libraries.color
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local getcustomasset = vape.Libraries.getcustomasset

local skywars, remotes = {}, {}
local store = {
	blocks = {},
	hand = {},
	inventory = {},
	tools = {},
	noShoot = tick()
}
local ViewmodelTool
local ViewmodelMotor
local split

local function collection(tags, module, customadd, customremove)
	tags = typeof(tags) ~= 'table' and {tags} or tags
	local objs, connections = {}, {}

	for _, tag in tags do
		table.insert(connections, collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			if customadd then
				customadd(objs, v, tag)
				return
			end
			table.insert(objs, v)
		end))
		table.insert(connections, collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if customremove then
				customremove(objs, v, tag)
				return
			end
			v = table.find(objs, v)
			if v then
				table.remove(objs, v)
			end
		end))

		for _, v in collectionService:GetTagged(tag) do
			if customadd then
				customadd(objs, v, tag)
				continue
			end
			table.insert(objs, v)
		end
	end

	local cleanFunc = function(self)
		for _, v in connections do
			v:Disconnect()
		end
		table.clear(connections)
		table.clear(objs)
		table.clear(self)
	end
	if module then
		module:Clean(cleanFunc)
	end
	return objs, cleanFunc
end

local function getItem(check)
	for _, item in store.inventory do
		if item.Type == check then
			return item
		end
	end
end

local function getSword()
	local bestSword, bestSwordSlot, bestSwordDamage = nil, nil, 0
	for slot, item in store.inventory do
		item = skywars.ItemMeta[item.Type]
		local swordDamage = item and item.Melee and item.Melee.Damage or 0
		if swordDamage > bestSwordDamage then
			bestSword, bestSwordSlot, bestSwordDamage = item, slot, swordDamage
		end
	end
	return bestSword, bestSwordSlot
end

local function getPickaxe()
	local bestPick, bestPickSlot, bestPickDamage = nil, nil, math.huge
	for slot, item in store.inventory do
		item = skywars.ItemMeta[item.Type]
		local pickDamage = item and item.Pickaxe and item.Pickaxe.TimeMultiplier or math.huge
		if pickDamage < bestPickDamage then
			bestPick, bestPickSlot, bestPickDamage = item, slot, pickDamage
		end
	end
	return bestPick, bestPickSlot
end

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

local function notif(...)
	return vape:CreateNotification(...)
end

local function parsePositions(v, func)
	if v:IsA('Part') and v.Size // 1 == v.Size then
		local start = (v.Position - (v.Size / 2)) + Vector3.new(1.5, 1.5, 1.5)
		for x = 0, v.Size.X - 1, 3 do
			for y = 0, v.Size.Y - 1, 3 do
				for z = 0, v.Size.Z - 1, 3 do
					func(start + Vector3.new(x, y, z))
				end
			end
		end
	end
end

local function waitForChildOfType(obj, name, timeout, prop)
	local checktick = tick() + timeout
	local returned
	repeat
		returned = prop and obj[name] or obj:FindFirstChildOfClass(name)
		if returned or checktick < tick() then break end
		task.wait()
	until false
	return returned
end

local struck, struckFrame = {}, nil
local function fireRemote(name, ...)
	local id = remotes[name]
	local event = id and skywars.Remotes and skywars.Remotes[id]
	if not event then return false end
	if name == 'updateActiveItem' then
		store.serverItem, store.serverItemAt = (...), tick()
	elseif name == 'strike' or name == 'strikeEntity' then
		local target, frame = (...), store.frame
		if struckFrame ~= frame then
			struckFrame = frame
			table.clear(struck)
		end
		if frame and target ~= nil then
			if struck[target] then return true end
			struck[target] = true
		end
	end
	event:fire(...)
	return true
end
local function heldName()
	return store.hand and store.hand.Name or nil
end
local function equip(item)
	if not item then
		if store.handBack then return end
		store.handBack = true
		task.defer(function()
			store.handBack = nil
			local name = heldName()
			if store.serverItem ~= name or (store.serverItemAt or 0) < tick() - 1 then
				fireRemote('updateActiveItem', name)
			end
		end)
		return
	end
	local name = item.Name
	if store.serverItem ~= name or (store.serverItemAt or 0) < tick() - 1 then
		fireRemote('updateActiveItem', name)
	end
end
local function voidFloor()
	if (store.floorAt or 0) > tick() then return store.floor end
	if store.lowDirty then
		store.lowDirty = nil
		local low = math.huge
		for pos in store.blocks do
			if pos.Y < low then
				low = pos.Y
			end
		end
		store.lowBlock = low
	end
	local low = store.lowBlock or math.huge
	store.floor, store.floorAt = low == math.huge and -1000 or low - 12, tick() + 10
	return store.floor
end
local function framePing()
	if store.pingFrame ~= store.frame or not store.frame then
		store.pingFrame, store.ping = store.frame, lplr:GetNetworkPing()
	end
	return store.ping
end
local function attachPosition(ent, height)
	local root = ent.RootPart
	local lead = math.clamp(framePing() + 0.05, 0.15, 0.35)
	local offset = root.AssemblyLinearVelocity * lead
	if ent.Humanoid and ent.Humanoid.FloorMaterial == Enum.Material.Air then
		offset += Vector3.new(0, -0.5 * workspace.Gravity * lead * lead, 0)
	else
		offset = Vector3.new(offset.X, 0, offset.Z)
	end
	if offset.Magnitude > 45 then
		offset = offset.Unit * 45
	end
	local position = root.Position + offset + Vector3.new(0, height, 0)
	return Vector3.new(position.X, math.max(position.Y, voidFloor()), position.Z)
end
local function fallen(ent)
	return ent.RootPart.Position.Y < voidFloor() - 25
end
local function bodyRoot()
	return entitylib.character.RootPart
end
local function realRoot()
	return split and split.Real or entitylib.character.RootPart
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
	if entitylib.character.RootPart == clone then
		entitylib.character.RootPart = real
		entitylib.character.HumanoidRootPart = real
	end
	if real.Parent and clone.Parent and character.Parent then
		local velocity = clone.AssemblyLinearVelocity
		character.Parent = replicatedStorage
		real.Parent = character
		real.CFrame = clone.CFrame
		clone:Destroy()
		character.PrimaryPart = real
		character.Parent = workspace
		real.CanCollide = true
		real.AssemblyLinearVelocity = velocity
	else
		clone:Destroy()
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
	if not (character and character.Parent == workspace and real and real.Parent == character and isnetworkowner(real)) then return nil end
	local velocity = real.AssemblyLinearVelocity
	character.Parent = replicatedStorage
	local clone = real:Clone()
	clone.Parent = character
	real.Parent = workspace
	clone.AssemblyLinearVelocity = velocity
	character.PrimaryPart = clone
	character.Parent = workspace
	real.CanCollide = false
	entitylib.character.RootPart = clone
	entitylib.character.HumanoidRootPart = clone
	split = {Real = real, Clone = clone, Character = character, Owners = {[owner] = true}, GoalAt = 0}
	store.split = split
	return real
end
local function sendRoot(position)
	if not entitylib.isAlive then return end
	if split then
		split.Goal, split.GoalAt, split.GoalFrame = position, tick(), store.frame
		split.Real.CFrame = CFrame.new(position) * (split.Clone.CFrame - split.Clone.CFrame.Position)
		split.Real.AssemblyLinearVelocity = Vector3.zero
		return
	end
	local root = entitylib.character.RootPart
	root.CFrame = CFrame.new(position) * (root.CFrame - root.CFrame.Position)
	root.AssemblyLinearVelocity = Vector3.zero
end
local OWNERS = {'staller', 'antiDeath', 'autoClutch', 'autoWin', 'breakerTrip', 'voidPush', 'spawnTrap', 'boxAura', 'infiniteAura', 'playerAttach', 'reach', 'eggProtector', 'godMode'}
local function outranked(name)
	for _, flag in OWNERS do
		if flag == name then return false end
		if store[flag] then return true end
	end
	return false
end
local function strikeReady(ent)
	local last = ent.LastHit
	if not last then return true end
	return tick() - last >= math.clamp(0.4 - framePing() * 2 - 0.08, 0.05, 0.3)
end
local function blockMeta(item)
	if not item then return nil end
	if item.Rewrite then
		local team = skywars.TeamController and skywars.TeamController:getPlayerTeamId(lplr)
		item = skywars.ItemMeta[(item.Rewrite.Type:gsub('{TeamId}', team or 'White'))]
	end
	return item and item.Block and item or nil
end
function store.cell(position)
	return Vector3.new(math.round(position.X / 3) * 3, math.round(position.Y / 3) * 3, math.round(position.Z / 3) * 3)
end
function store.blockItem(count)
	local best, bestTime, amount
	for _, item in store.inventory do
		local meta = skywars.ItemMeta[item.Type]
		local block = (item.Quantity or 1) >= (count or 1) and blockMeta(meta)
		if block and not block.Block.CollectionTag and block.Block.BreakTime ~= math.huge and (not bestTime or block.Block.BreakTime > bestTime) then
			best, bestTime, amount = meta, block.Block.BreakTime, item.Quantity or 1
		end
	end
	return best, amount or 0
end
store.neighbours = {Vector3.new(0, 3, 0), Vector3.new(0, -3, 0)}
for x = -1, 1 do
	for z = -1, 1 do
		if x ~= 0 or z ~= 0 then
			table.insert(store.neighbours, Vector3.new(x * 3, 0, z * 3))
		end
	end
end
store.pendingCells = {}

function store.filled(cell)
	return store.blocks[cell] ~= nil or (store.pendingCells[cell] or 0) > tick()
end

function store.anchored(cell)
	for _, offset in store.neighbours do
		if store.filled(cell + offset) then return true end
	end
	return false
end
function store.orderCells(cells, extras)
	local order, done = {}, {}
	local function sendable(cell)
		if done[cell] then return false end
		for _, offset in store.neighbours do
			local n = cell + offset
			if done[n] or store.filled(n) then return true end
		end
		return false
	end
	local wanted = {}
	for _, cell in cells do
		if not store.filled(cell) then
			table.insert(wanted, cell)
		end
	end
	repeat
		local progress = false
		for _, cell in wanted do
			if sendable(cell) then
				done[cell] = true
				table.insert(order, cell)
				progress = true
			end
		end
		if not progress and extras then
			for _, extra in extras do
				if not store.filled(extra) and sendable(extra) then
					local useful = false
					for _, cell in wanted do
						if not done[cell] and (cell - extra).Magnitude < 5 then
							useful = true
							break
						end
					end
					if useful then
						done[extra] = true
						table.insert(order, extra)
						progress = true
						break
					end
				end
			end
		end
	until not progress
	return order
end
function store.cellFree(cell)
	local util = skywars.BlockUtil
	if not util then return true end
	local ok, result = pcall(util.canPlace, cell, lplr)
	return not ok or result
end
function store.placeCells(cells, item)
	if #cells == 0 or not item or not skywars.InventoryController then return 0 end
	local now = tick()
	for cell, untilAt in store.pendingCells do
		if untilAt < now then
			store.pendingCells[cell] = nil
		end
	end
	equip(item)
	local sent = 0
	for _, cell in cells do
		local id = skywars.InventoryController:registerItemPrediction(item.Name, -1)
		if id and id ~= '' then
			fireRemote('placeBlock', cell, 0, id)
			store.pendingCells[cell] = tick() + math.clamp(lplr:GetNetworkPing() * 2 + 0.3, 0.4, 1.2)
			sent += 1
		end
	end
	equip(nil)
	return sent
end

run(function()
	entitylib.addPlayer = function(plr)
		if plr.Character then
			entitylib.refreshEntity(plr.Character, plr)
		end
		entitylib.PlayerConnections[plr] = {
			plr.CharacterAdded:Connect(function(char)
				entitylib.refreshEntity(char, plr)
			end),
			plr.CharacterRemoving:Connect(function(char)
				entitylib.removeEntity(char, plr == lplr)
			end),
			plr:GetAttributeChangedSignal('TeamId'):Connect(function()
				for _, v in entitylib.List do
					if v.Targetable ~= entitylib.targetCheck(v) then
						entitylib.refreshEntity(v.Character, v.Player)
					end
				end

				if plr == lplr then
					entitylib.start()
				else
					entitylib.refreshEntity(plr.Character, plr)
				end
			end)
		}
	end

	entitylib.addEntity = function(char, plr, teamfunc)
		if not char then return end
		entitylib.EntityThreads[char] = task.spawn(function()
			local hum = waitForChildOfType(char, 'Humanoid', 10)
			local humrootpart = hum and waitForChildOfType(hum, 'RootPart', workspace.StreamingEnabled and 9e9 or 10, true)
			local head = char:WaitForChild('Head', 10) or humrootpart

			if hum and humrootpart then
				local entity = {
					Connections = {},
					Character = char,
					Health = plr and plr:GetAttribute('Health') or 100,
					Head = head,
					Humanoid = hum,
					HumanoidRootPart = humrootpart,
					HipHeight = hum.HipHeight + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
					MaxHealth = 100,
					NPC = plr == nil,
					Player = plr,
					RootPart = humrootpart,
					TeamCheck = teamfunc
				}

				if plr == lplr then
					entity.GroundPosition = Vector3.zero
					entitylib.character = entity
					entitylib.isAlive = true
					entitylib.Events.LocalAdded:Fire(entity)
				else
					entity.Targetable = (teamfunc or entitylib.targetCheck)(entity)
					table.insert(entity.Connections, hum.AnimationPlayed:Connect(function(track)
						entitylib.Events.AnimationPlayed:Fire(plr, track)
					end))

					for _, v in entitylib.getUpdateConnections(entity) do
						table.insert(entity.Connections, v:Connect(function()
							local health = plr and plr:GetAttribute('Health') or 100
							if health < entity.Health then
								entity.LastHit = tick()
							end
							entity.Health = health
							entitylib.Events.EntityUpdated:Fire(entity)
						end))
					end

					table.insert(entitylib.List, entity)
					entitylib.Events.EntityAdded:Fire(entity)
				end
			end
			entitylib.EntityThreads[char] = nil
		end)
	end

	entitylib.getUpdateConnections = function(ent)
		local connections = {
			{
				Connect = function()
					ent.Friend = ent.Player and isFriend(ent.Player) or nil
					ent.Target = ent.Player and isTarget(ent.Player) or nil
					return {Disconnect = function() end}
				end
			}
		}
		if ent.Player then
			table.insert(connections, 1, ent.Player:GetAttributeChangedSignal('Health'))
		end
		return connections
	end

	entitylib.targetCheck = function(ent)
		if ent.TeamCheck then
			return ent:TeamCheck()
		end
		if ent.NPC then return true end
		if isFriend(ent.Player) then return false end
		if not select(2, whitelist:get(ent.Player)) then return false end
		local mine, theirs = lplr:GetAttribute('TeamId'), ent.Player:GetAttribute('TeamId')
		if mine == nil or theirs == nil then return true end
		return mine ~= theirs
	end

	entitylib.getEntityColor = function(ent)
		ent = ent.Player
		if not (ent and vape.Categories.Main.Options['Use team color'].Enabled) then return end
		if isFriend(ent, true) then
			return Color3.fromHSV(vape.Categories.Friends.Options['Friends color'].Hue, vape.Categories.Friends.Options['Friends color'].Sat, vape.Categories.Friends.Options['Friends color'].Value)
		end
		local team = ent:GetAttribute('TeamId')
		if not (team and skywars.TeamController) then return end
		local ok, teamColor = pcall(skywars.TeamController.getTeamColour, skywars.TeamController, team)
		return ok and typeof(teamColor) == 'Color3' and teamColor or nil
	end
end)
entitylib.start()

run(function()
	local include = replicatedStorage:WaitForChild('rbxts_include', 30)
	local started = tick()

	local function gameRequire(module, timeout)
		local deadline = tick() + timeout
		repeat
			local known = false
			if getloadedmodules then
				local ok, list = pcall(getloadedmodules)
				if ok and type(list) == 'table' then
					known = true
					if table.find(list, module) then
						return require(module)
					end
				end
			end
			if not known and tick() - started > 8 then
				return require(module)
			end
			task.wait(0.1)
		until tick() > deadline
		error('the game has not loaded '..module.Name..' yet')
	end

	local core = gameRequire(include['node_modules']['@flamework'].core.out, 45)
	local Flamework, Reflect = core.Flamework, core.Reflect
	local ids, found = {}, {}

	local deadline = tick() + 45
	local ignited = false
	repeat
		local ok, value = pcall(debug.getupvalue, Flamework.ignite, 1)
		if ok and value then
			ignited = true
			break
		end
		task.wait(0.1)
	until tick() > deadline
	if not ignited then
		error('the game did not finish starting')
	end

	local function searchFunction(list, func, depth)
		local ok, constants = pcall(debug.getconstants, func)
		if ok and type(constants) == 'table' then
			for _, v in constants do
				if type(v) == 'string' and v:find('^%x%x%x%x%x%x%x%x%-%x%x%x%x%-') and not table.find(list, v) then
					table.insert(list, v)
				end
			end
		end
		if depth > 0 then
			local protoOk, protos = pcall(debug.getprotos, func)
			if protoOk and type(protos) == 'table' then
				for _, proto in protos do
					searchFunction(list, proto, depth - 1)
				end
			end
		end
	end

	for id, class in Reflect.idToObj do
		local name = tostring(class)
		if type(class) == 'table' and not ids[name] then
			ids[name] = id
			local methods = {}
			for method, func in class do
				if type(func) == 'function' then
					local list = {}
					searchFunction(list, func, 2)
					if #list > 0 then
						methods[method] = list
					end
				end
			end
			found[name] = methods
		end
	end

	local function event(controller, method, index)
		local list = found[controller] and found[controller][method]
		return list and list[index or 1] or nil
	end

	remotes.strike = event('MeleeController', 'strikeDesktop')
	for _, id in (found.MeleeController and found.MeleeController.attemptStrikeDesktop or {}) do
		if id ~= remotes.strike then
			remotes.strikeEntity = id
		end
	end
	remotes.updateActiveItem = event('HotbarController', 'updateActiveItem')
	remotes.chargeBow = event('ProjectileController', 'chargeBow')
	remotes.placeBlock = event('BlockController', 'placeBlock')
	remotes.hitBlock = event('BlockController', 'hitBlock')
	remotes.openChest = event('ChestController', 'openChest')
	remotes.updateChest = event('ChestController', 'updateChest')
	remotes.closeChest = event('ChestController', 'closeChest')
	remotes.chestContents = event('ChestController', 'onStart')
	remotes.purchaseItem = event('GameShopController', 'purchaseItem')
	remotes.purchaseItemUpgrade = event('GameShopController', 'purchaseItemUpgrade')
	remotes.purchaseTeamUpgrade = event('GameShopController', 'purchaseTeamUpgrade')
	remotes.usePowerUp = event('PowerUpController', 'usePowerUp')
	remotes.knockback = event('PlayerVelocityController', 'onStart')
	remotes.itemPrediction = event('InventoryController', 'registerItemPrediction')
	remotes.damage = event('HealthController', 'onStart')
	remotes.projectileEvents = found.ProjectileController and found.ProjectileController.onStart or {}

	local scripts = lplr:WaitForChild('PlayerScripts', 30):WaitForChild('TS', 30)
	skywars = setmetatable({
		CameraUtil = gameRequire(scripts.util['camera-util'], 15).CameraUtil,
		FireOrigin = gameRequire(replicatedStorage.TS.projectile['projectile-constants'], 15).ProjectileConstants.ORIGIN_OFFSET,
		Gravity = gameRequire(replicatedStorage.TS.world['world-constants'], 15).WorldConstants.WORLD_ACCELERATION.Y,
		ItemMeta = gameRequire(replicatedStorage.TS.item.item, 15).Items,
		Remotes = gameRequire(scripts.events, 15).Events,
		Store = gameRequire(scripts.ui.rodux['global-store'], 15).GlobalStore,
		Shop = gameRequire(replicatedStorage.TS.game.shop['game-shop'], 15).Shops,
		MeleeConstants = gameRequire(replicatedStorage.TS.melee['melee-constants'], 15).MeleeConstants,
		BlockConstants = gameRequire(replicatedStorage.TS.block['block-constants'], 15).BlockConstants,
		BlockUtil = gameRequire(replicatedStorage.TS.util['block-util'], 15).BlockUtil
	}, {
		__index = function(self, ind)
			local id = ids[ind]
			if not id then return nil end
			local ok, dependency = pcall(Flamework.resolveDependency, id)
			if ok and dependency ~= nil then
				rawset(self, ind, dependency)
				return dependency
			end
			return nil
		end
	})

	local kills = sessioninfo:AddItem('Kills')
	local eggs = sessioninfo:AddItem('Eggs')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	task.delay(1, function()
		games:Increment()
	end)

	local function updateStore(newStore, oldStore)
		if newStore.GameCurrency ~= oldStore.GameCurrency and newStore.GameCurrency then
			vapeEvents.CurrencyChange:Fire(table.clone(newStore.GameCurrency.Quantities))
		end

		if newStore.ActiveSlot ~= oldStore.ActiveSlot and newStore.Inventory then
			store.hand = newStore.Inventory.Contents[newStore.ActiveSlot]
			store.hand = store.hand and skywars.ItemMeta[store.hand.Type] or {}
			store.serverItem, store.serverItemAt = heldName(), tick()
		end

		if newStore.Inventory ~= oldStore.Inventory and newStore.Inventory then
			local before = heldName()
			store.inventory = newStore.Inventory.Contents
			store.hand = newStore.Inventory.Contents[newStore.ActiveSlot]
			store.hand = store.hand and skywars.ItemMeta[store.hand.Type] or {}
			store.tools.sword, store.tools.swordSlot = getSword()
			store.tools.pickaxe, store.tools.pickaxeSlot = getPickaxe()
			if heldName() ~= before then
				store.serverItemAt = 0
			end
			vapeEvents.InventoryAmountChanged:Fire()
		end

		if oldStore.Profile and oldStore.Profile.WasTeleporting and newStore.Profile and newStore.Profile.Stats ~= oldStore.Profile.Stats and newStore.Profile.Stats and oldStore.Profile.Stats then
			if newStore.Profile.Stats.Kills ~= oldStore.Profile.Stats.Kills and oldStore.Profile.Stats.Kills then
				kills:Increment()
			end

			if newStore.Profile.Stats.Wins ~= oldStore.Profile.Stats.Wins and oldStore.Profile.Stats.Wins then
				wins:Increment()
			end
		end
	end

	local storeChanged = skywars.Store.changed:connect(updateStore)
	updateStore(skywars.Store:getState(), {})

	vape:Clean(entitylib.Events.LocalAdded:Connect(function()
		store.serverItemAt = 0
	end))
	vape:Clean(entitylib.Events.LocalRemoved:Connect(function()
		if split then
			local clone = split.Clone
			split = nil
			store.split = nil
			pcall(clone.Destroy, clone)
		end
	end))
	vape:Clean(runService.PreSimulation:Connect(function()
		store.frame = (store.frame or 0) + 1
	end))
	vape:Clean(runService.Heartbeat:Connect(function()
		if not split then return end
		local real, clone = split.Real, split.Clone
		if not (entitylib.isAlive and real.Parent and clone.Parent) then
			mergeRoot(nil, true)
			return
		end
		if split.GoalAt > tick() - 0.1 then
			if split.GoalFrame ~= store.frame or not store.frame then
				real.CFrame = CFrame.new(split.Goal) * (clone.CFrame - clone.CFrame.Position)
				real.AssemblyLinearVelocity = Vector3.zero
			end
		else
			real.CFrame = clone.CFrame
			real.AssemblyLinearVelocity = clone.AssemblyLinearVelocity
		end
	end))
	vape:Clean(function()
		mergeRoot(nil, true)
	end)

	task.spawn(function()
		repeat
			if entitylib.isAlive then
				entitylib.character.GroundPosition = entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air and bodyRoot().Position or entitylib.character.GroundPosition
			end
			task.wait()
		until vape.Loaded == nil
	end)

	local function addBlock(pos, v)
		store.blocks[pos] = v
		if pos.Y < (store.lowBlock or math.huge) then
			store.lowBlock = pos.Y
		end
	end
	local function trackContainer(container)
		vape:Clean(container.DescendantAdded:Connect(function(v)
			parsePositions(v, function(pos)
				addBlock(pos, v)
			end)
		end))
		vape:Clean(container.DescendantRemoving:Connect(function(v)
			parsePositions(v, function(pos)
				if store.blocks[pos] == v then
					store.blocks[pos] = nil
					if pos.Y == store.lowBlock then
						store.lowDirty = true
					end
				end
			end)
		end))
		for _, v in container:GetDescendants() do
			parsePositions(v, function(pos)
				addBlock(pos, v)
			end)
		end
	end

	if workspace:FindFirstChild('BlockContainer') then
		trackContainer(workspace.BlockContainer)
	end
	vape:Clean(workspace.ChildAdded:Connect(function(v)
		if v.Name == 'BlockContainer' then
			table.clear(store.blocks)
			store.lowBlock, store.lowDirty = nil, nil
			trackContainer(v)
		end
	end))

	if type(vape.SetGameInfo) == 'function' then
		vape:SetGameInfo({Name = 'SkyWars'})
	end

	vape:Clean(function()
		for _, v in vapeEvents do
			v:Destroy()
		end
		table.clear(ids)
		table.clear(found)
		table.clear(remotes)
		table.clear(vapeEvents)
		table.clear(skywars)
		table.clear(store.blocks)
		table.clear(store)
		storeChanged:disconnect()
		storeChanged = nil
	end)
end)

if not skywars.Store then
	notif('ElevateV4', 'SkyWars did not start because the game was still loading. Reinject once you are in the match.', 15, 'alert')
end

for _, v in {
	'Reach', 'TriggerBot', 'Disabler', 'SilentAim', 'AutoRejoin', 'Rejoin', 'ServerHop', 'MurderMystery',
	'Killaura', 'AutoClicker', 'AntiVoid', 'NoFallDamage', 'AutoObby'
} do
	vape:Remove(v)
end
