local run = function(func)
	local success, result = xpcall(func, debug and debug.traceback or tostring)
	if not success then
		warn('[ElevateV4] Skipped a Tribes module during startup: '..tostring(result))
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
local textChatService = cloneref(game:GetService('TextChatService'))
local runService = shared.vape.Libraries.profiler and shared.vape.Libraries.profiler.RunService or cloneref(game:GetService('RunService'))
local task = shared.vape.Libraries.profiler and shared.vape.Libraries.profiler.Task or task

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer

local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local whitelist = vape.Libraries.whitelist

local tribes = {}
local store = {}

local function notif(...)
	return vape:CreateNotification(...)
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

local function matchOf(model)
	local id = model and model:GetAttribute('MatchId')
	return type(id) == 'string' and id or ''
end
local function isEnemy(model, npc)
	local mine = lplr.Character
	if not (model and mine and model ~= mine) then return false end
	local match = matchOf(mine)
	if match == '' then
		return npc == true and matchOf(model) == ''
	end
	if matchOf(model) ~= match then return false end
	local a, b = mine:GetAttribute('Team'), model:GetAttribute('Team')
	return a ~= nil and b ~= nil and a ~= b
end

local function inMatch()
	return matchOf(lplr.Character) ~= ''
end
local function canAct()
	if tribes.Util then
		local ok, res = pcall(tribes.Util.CanAct)
		if ok then return res end
	end
	return entitylib.isAlive
end

run(function()
	entitylib.targetCheck = function(ent)
		if ent.TeamCheck then
			return ent:TeamCheck()
		end
		if ent.NPC then
			return isEnemy(ent.Character, true)
		end
		if isFriend(ent.Player) then return false end
		if not select(2, whitelist:get(ent.Player)) then return false end
		return isEnemy(ent.Character)
	end

	entitylib.getUpdateConnections = function(ent)
		local hum = ent.Humanoid
		return {
			hum:GetPropertyChangedSignal('Health'),
			hum:GetPropertyChangedSignal('MaxHealth'),
			{
				Connect = function()
					if ent.Player then
						ent.Friend = isFriend(ent.Player) or nil
						ent.Target = isTarget(ent.Player) or nil
					end
					return ent.Character.AttributeChanged:Connect(function(key)
						if key == 'Team' or key == 'MatchId' then
							ent.Targetable = entitylib.targetCheck(ent)
						end
					end)
				end
			}
		}
	end

	local function retarget()
		for _, ent in entitylib.List do
			ent.Targetable = entitylib.targetCheck(ent)
		end
	end

	local function addBot(model)
		if not model:IsA('Model') or playersService:GetPlayerFromCharacter(model) then return end
		entitylib.addEntity(model, nil)
	end

	local oldstart = entitylib.start
	entitylib.start = function()
		oldstart()
		if not entitylib.Running then return end
		for _, tag in {'Bot', 'TrainingDummy', 'Combatant'} do
			for _, model in collectionService:GetTagged(tag) do
				addBot(model)
			end
			table.insert(entitylib.Connections, collectionService:GetInstanceAddedSignal(tag):Connect(addBot))
			table.insert(entitylib.Connections, collectionService:GetInstanceRemovedSignal(tag):Connect(function(model)
				if not playersService:GetPlayerFromCharacter(model) then
					entitylib.removeEntity(model)
				end
			end))
		end
		local function watchLocal(char)
			table.insert(entitylib.Connections, char.AttributeChanged:Connect(function(key)
				if key == 'Team' or key == 'MatchId' then
					retarget()
				end
			end))
		end
		if lplr.Character then
			watchLocal(lplr.Character)
		end
		table.insert(entitylib.Connections, lplr.CharacterAdded:Connect(function(char)
			watchLocal(char)
			task.defer(retarget)
		end))
	end
end)
entitylib.start()

run(function()
	local ps = lplr:WaitForChild('PlayerScripts', 15)
	local combat = ps and ps:WaitForChild('Combat', 15)
	local sharedFolder = replicatedStorage:WaitForChild('Shared', 15)
	local handlers = combat and combat:FindFirstChild('Handlers')
	local ui = ps and ps:FindFirstChild('UI')
	local wanted = {
		Controller = combat and combat:WaitForChild('Controller', 15),
		Util = combat and combat:FindFirstChild('Util'),
		Combat = sharedFolder and sharedFolder:FindFirstChild('Combat'),
		Weapons = sharedFolder and sharedFolder:FindFirstChild('Weapons'),
		Economy = ui and ui:FindFirstChild('Economy'),
		Effects = combat and combat:FindFirstChild('Effects'),
		Hud = combat and combat:FindFirstChild('Hud'),
		Poses = combat and combat:FindFirstChild('Poses'),
		Melee = handlers and handlers:FindFirstChild('Melee'),
		Bow = handlers and handlers:FindFirstChild('Bow'),
		Throw = handlers and handlers:FindFirstChild('Throw'),
		Gun = handlers and handlers:FindFirstChild('Gun'),
		Net = sharedFolder and sharedFolder:FindFirstChild('Net'),
		Simulation = sharedFolder and sharedFolder:FindFirstChild('Simulation'),
		Camera = sharedFolder and sharedFolder:FindFirstChild('Camera'),
		UIState = ui and ui:FindFirstChild('State'),
		UIRemotes = ui and ui:FindFirstChild('Remotes')
	}
	local deadline = tick() + 20
	repeat
		local loaded = {}
		for _, module in getloadedmodules and getloadedmodules() or {} do
			loaded[module] = true
		end
		local missing = false
		local core = {Controller = true, Util = true, Combat = true, Weapons = true, Economy = true}
		for name, module in wanted do
			if not tribes[name] then
				if module and (not getloadedmodules or loaded[module]) then
					local ok, res = pcall(require, module)
					if ok then
						tribes[name] = res
					end
				elseif core[name] then
					missing = true
				end
			end
		end
		if not missing then break end
		task.wait(0.5)
	until tick() > deadline

	if tribes.Controller then
		for i = 1, 6 do
			local ok, value = pcall(debug.getupvalue, tribes.Controller.State, i)
			if ok and type(value) == 'table' and rawget(value, 'speed') and rawget(value, 'pressed') then
				tribes.State = value
				break
			end
		end
	end
end)

run(function()
	local kills = sessioninfo:AddItem('Kills')
	local deaths = sessioninfo:AddItem('Deaths')
	local games = sessioninfo:AddItem('Games')
	local wins = sessioninfo:AddItem('Wins')
	local myId = 'p'..lplr.UserId

	local remotes = replicatedStorage:WaitForChild('Remotes', 15)
	for _, name in {'CombatFX', 'CombatFXU'} do
		local fx = remotes and remotes:FindFirstChild(name)
		if fx then
			vape:Clean(fx.OnClientEvent:Connect(function(kind, data)
				if kind ~= 'Projectile' or type(data) ~= 'table' then return end
				if typeof(data.origin) ~= 'Vector3' or typeof(data.velocity) ~= 'Vector3' then return end
				local shooter = data.shooter
				if typeof(shooter) == 'Instance' and shooter:IsA('Player') then
					shooter = shooter.Character
				end
				if typeof(shooter) ~= 'Instance' or shooter == lplr.Character then return end
				vapeEvents.EnemyShot:Fire(shooter, data.origin, data.velocity, tonumber(data.gravity) or 0, data.key)
			end))
		end
	end

	local event = remotes and remotes:WaitForChild('MatchEvent', 15)
	if not event then return end
	vape:Clean(event.OnClientEvent:Connect(function(name, data)
		if type(data) ~= 'table' then data = {} end
		if name == 'MatchStart' then
			games:Increment()
		elseif name == 'MatchEnd' then
			local you = type(data.you) == 'table' and data.you or {}
			local won
			if you.won ~= nil then
				won = you.won == true
			else
				won = data.winnerTeam ~= nil and data.winnerTeam == (lplr.Character and lplr.Character:GetAttribute('Team') or lplr:GetAttribute('Team'))
			end
			if won then
				wins:Increment()
			end
			vapeEvents.MatchEnded:Fire(won, data)
		elseif name == 'Elimination' then
			if data.killerId == myId and data.victimId ~= myId then
				kills:Increment()
			elseif data.victimId == myId then
				deaths:Increment()
			end
			vapeEvents.Elimination:Fire(data)
		end
	end))
end)

run(function()
	store.KIND = {
		Fists = 'Melee', Sword = 'Melee', Axe = 'Melee', Spear = 'Melee', Dagger = 'Melee', Club = 'Melee',
		Shield = 'Melee', Gauntlets = 'Melee', Scythe = 'Melee', Katana = 'Melee', Hatchets = 'Melee',
		Bow = 'Bow', Crossbow = 'Gun', Musket = 'Gun', Pistol = 'Gun', Blunderbuss = 'Gun',
		Knives = 'Throw', Javelin = 'Throw', Sling = 'Throw', Bomb = 'Throw',
		Herbs = 'Use', Trap = 'Use', Horn = 'Use'
	}

	function store.handler()
		local state = tribes.State
		if not (state and state.handler and type(state.handler.tuning) == 'table') then return nil end
		return state.handler, store.KIND[state.kind] or 'Melee', state.kind
	end

	function store.tools()
		local list = {}
		for _, holder in {lplr.Character, lplr:FindFirstChildOfClass('Backpack')} do
			for _, tool in holder and holder:GetChildren() or {} do
				local id = tool:IsA('Tool') and tool:GetAttribute('WeaponId')
				if type(id) == 'string' then
					local ok, kind = pcall(tribes.Combat.Kind, id)
					kind = ok and kind or nil
					table.insert(list, {Tool = tool, Id = id, Kind = kind, Class = store.KIND[kind] or 'Melee', Held = holder == lplr.Character})
				end
			end
		end
		return list
	end

	function store.heldClass(model)
		local tool = model and model:FindFirstChildOfClass('Tool')
		local id = tool and tool:GetAttribute('WeaponId')
		if type(id) ~= 'string' then return nil end
		local ok, kind = pcall(tribes.Combat.Kind, id)
		return ok and store.KIND[kind] or nil
	end

	local params, paramsAt = nil, 0
	function store.worldParams()
		if not params or tick() - paramsAt > 0.5 then
			paramsAt = tick()
			local ok, res = pcall(function()
				return tribes.Util.WorldParams(tribes.Util.Targets())
			end)
			params = ok and res or RaycastParams.new()
		end
		return params
	end

	function store.equip(tool)
		if not (tribes.Controller and tool) then return false end
		local ok, res = pcall(tribes.Controller.Equip, tool)
		return ok and res
	end

	local history = setmetatable({}, {__mode = 'k'})
	local sampled = 0
	vape:Clean(runService.Heartbeat:Connect(function()
		local now = tick()
		if now - sampled < 0.1 then return end
		sampled = now
		for _, ent in entitylib.List do
			local h = history[ent]
			if not h then
				h = {}
				history[ent] = h
			end
			h.Old, h.OldAt = h.Pos, h.At
			h.Pos, h.At = ent.RootPart.Position, now
		end
	end))

	function store.velocityOf(ent)
		local h = history[ent]
		if not (h and h.Old) or h.At - h.OldAt <= 0 then return Vector3.zero end
		return (h.Pos - h.Old) / (h.At - h.OldAt)
	end

	function store.solve(origin, speed, gravity, pos, vel)
		local lead = lplr:GetNetworkPing() + 0.05
		local t = (pos - origin).Magnitude / speed
		local dir
		for _ = 1, 4 do
			local delta = pos + vel * (t + lead) - origin
			local flat = Vector3.new(delta.X, 0, delta.Z)
			local x, y = flat.Magnitude, delta.Y
			if gravity <= 0.01 or x < 0.5 then
				dir = delta.Unit
				t = delta.Magnitude / speed
			else
				local v2 = speed * speed
				local disc = v2 * v2 - gravity * (gravity * x * x + 2 * y * v2)
				if disc < 0 then return nil end
				local angle = math.atan((v2 - math.sqrt(disc)) / (gravity * x))
				dir = flat.Unit * math.cos(angle) + Vector3.yAxis * math.sin(angle)
				t = x / (speed * math.cos(angle))
			end
		end
		return dir, t
	end

	function store.ballistics(handler, class)
		local tuning = handler.tuning
		local started = class == 'Throw' and handler.start or handler.drawStart
		local charge = started and math.clamp((os.clock() - started) / (tuning.drawTime or (class == 'Throw' and 0.5 or 1)), 0, 1) or 1
		local speed
		if class == 'Bow' or (class == 'Throw' and handler.winds) then
			speed = select(2, tribes.Combat.DrawnShot(tuning, charge))
		else
			speed = tribes.Combat.ShotSpeed(tuning)
		end
		return speed, math.abs(tuning.gravity or (class == 'Gun' and 0 or 60))
	end

	local LIFT = {Bomb = 0.16, Sling = 0.05, Javelin = 0.04}
	function store.aimAt(origin, ent)
		local handler, class = store.handler()
		if not (handler and ent and (class == 'Bow' or class == 'Gun' or class == 'Throw')) then return nil end
		local speed, gravity = store.ballistics(handler, class)
		if not speed or speed <= 0 then return nil end
		local dir = store.solve(origin, speed, gravity, ent.RootPart.Position, store.velocityOf(ent))
		if dir and class == 'Throw' then
			dir = (dir - Vector3.new(0, LIFT[handler.kind] or 0.01, 0)).Unit
		end
		return dir
	end

	if tribes.Util and type(tribes.Util.AimDirection) == 'function' then
		local old = tribes.Util.AimDirection
		local wrapper
		wrapper = function(origin, ...)
			local ent = store.forcedTarget
			if not ent and store.aimPicker then
				local ok, picked = pcall(store.aimPicker, origin)
				ent = ok and picked or nil
			end
			if ent and typeof(origin) == 'Vector3' then
				local ok, dir = pcall(store.aimAt, origin, ent)
				if ok and dir then
					targetinfo.Targets[ent] = tick() + 1
					return dir
				end
			end
			return old(origin, ...)
		end
		tribes.Util.AimDirection = wrapper
		vape:Clean(function()
			if tribes.Util.AimDirection == wrapper then
				tribes.Util.AimDirection = old
			end
		end)
	end

	function store.press(handler, down, ent)
		store.forcedTarget = ent
		local ok, err = pcall(handler.Input, handler, 'Primary', down)
		store.forcedTarget = nil
		return ok, err
	end
end)

run(function()
	local OWNERS = {AutoWin = 3, AntiHit = 1}
	local goals = {}
	store.pulls = 0

	function store.move(owner, position)
		goals[owner] = {Pos = position, At = tick()}
	end

	function store.lift(owner, y)
		goals[owner] = {Y = y, At = tick()}
	end

	function store.release(owner)
		goals[owner] = nil
	end

	function store.mover()
		local best, rank = nil, 0
		local now = tick()
		for owner, goal in goals do
			if now - goal.At < 0.15 and (OWNERS[owner] or 0) > rank then
				best, rank = owner, OWNERS[owner] or 0
			end
		end
		return best
	end

	function store.outranked(owner)
		local top = store.mover()
		return top ~= nil and top ~= owner
	end

	local restore
	vape:Clean(runService.PostSimulation:Connect(function()
		local owner = store.mover()
		store.moving = owner
		restore = nil
		if not (owner and entitylib.isAlive) then return end
		local root, goal = entitylib.character.RootPart, goals[owner]
		if goal.Pos then
			root.CFrame = CFrame.new(goal.Pos) * root.CFrame.Rotation
			root.AssemblyLinearVelocity = Vector3.zero
		else
			restore = root.CFrame
			root.CFrame = restore + Vector3.new(0, goal.Y - restore.Y, 0)
		end
	end))
	runService:BindToRenderStep('AetherTribesHitbox', Enum.RenderPriority.First.Value, function()
		if restore and entitylib.isAlive then
			entitylib.character.RootPart.CFrame = restore
		end
		restore = nil
	end)
	vape:Clean(function()
		runService:UnbindFromRenderStep('AetherTribesHitbox')
	end)

	function store.body()
		return restore and restore.Position or entitylib.character.RootPart.Position
	end

	function store.hitbox()
		local root = entitylib.character.RootPart
		local owner = store.mover()
		local goal = owner and goals[owner]
		if goal and goal.Y then
			return Vector3.new(root.Position.X, goal.Y, root.Position.Z)
		end
		return root.Position
	end

	local function watch(ent)
		local root = ent.RootPart
		vape:Clean(root:GetAttributeChangedSignal('STp'):Connect(function()
			store.pulls += 1
			store.pulledAt = tick()
			vapeEvents.Pulled:Fire(store.moving)
		end))
	end
	vape:Clean(entitylib.Events.LocalAdded:Connect(watch))
	if entitylib.isAlive then
		watch(entitylib.character)
	end
end)
local gameapi = {Options = {}, Shot = {charge = 0, at = 0}}
run(function()
	local combat, util, controller = tribes.Combat, tribes.Util, tribes.Controller
	local options = gameapi.Options
	local patches = {}

	function gameapi.Patch(tab, key, factory)
		if type(tab) ~= 'table' or type(tab[key]) ~= 'function' then return false end
		local old = tab[key]
		local replacement = factory(old)
		local ok = pcall(function()
			tab[key] = replacement
		end)
		if not ok or tab[key] ~= replacement then return false end
		table.insert(patches, {Table = tab, Key = key, Old = old, New = replacement})
		return true
	end
	vape:Clean(function()
		if gameapi.ReleasePrimary then
			gameapi.ReleasePrimary()
		end
		for i = #patches, 1, -1 do
			local patch = patches[i]
			pcall(function()
				if patch.Table[patch.Key] == patch.New then
					patch.Table[patch.Key] = patch.Old
				end
			end)
		end
		table.clear(patches)
	end)

	function gameapi.Tool()
		if not (controller and combat) then return end
		local char = lplr.Character
		local tool = char and char:FindFirstChildOfClass('Tool')
		local ok, state = pcall(controller.State)
		if not ok or type(state) ~= 'table' or state.equipPending then return end
		if tool and state.tool ~= tool.Name then return end
		local id = tool and tool:GetAttribute('WeaponId') or combat.FISTS_ID
		if type(id) ~= 'string' then return end
		local def = tribes.Weapons and tribes.Weapons.Get(id)
		local kind = def and def.kind or (not tool and 'Fists')
		if kind ~= state.kind then return end
		return tool, id, kind, combat.Tuning(id), state
	end

	function gameapi.Valid(model, targets)
		if typeof(model) ~= 'Instance' or not model:IsA('Model') then return false end
		if model == lplr.Character or not model:IsDescendantOf(workspace) then return false end
		local player = playersService:GetPlayerFromCharacter(model)
		if targets then
			if player and not targets.Players.Enabled then return false end
			if not player and not targets.NPCs.Enabled then return false end
		end
		if player and (isFriend(player) or not select(2, whitelist:get(player))) then return false end
		local humanoid = model:FindFirstChildOfClass('Humanoid')
		return humanoid ~= nil and humanoid.Health > 0 and util.CanPredictHit(model)
	end

	function gameapi.Enemy(model, targets)
		return gameapi.Valid(model, targets) and not util.IsTeammate(model)
	end

	function gameapi.Cursor()
		local camera = workspace.CurrentCamera
		if not camera then return Vector2.zero end
		return inputService.TouchEnabled and camera.ViewportSize * 0.5 or inputService:GetMouseLocation()
	end

	function gameapi.Clear(origin, point, model)
		if combat.SmokeBlocks and combat.SmokeBlocks(origin, point) then return false end
		local hit = workspace:Raycast(origin, point - origin, store.worldParams())
		return hit == nil or hit.Instance:IsDescendantOf(model)
	end

	local history = setmetatable({}, {__mode = 'k'})
	function gameapi.TargetVelocity(model, root)
		local now = os.clock()
		local raw = root.AssemblyLinearVelocity
		local record = history[model]
		if not record then
			history[model] = {Position = root.Position, Velocity = raw, Time = now}
			return raw
		end
		local dt = now - record.Time
		if dt < 0.035 then return record.Velocity end
		local displacement = root.Position - record.Position
		if displacement.Magnitude > 15 or dt > 0.4 then
			record.Velocity = raw
		else
			local measured = displacement / math.max(dt, 0.001)
			local candidate = measured.Magnitude < 90 and raw:Lerp(measured, 0.3) or raw
			local response = (candidate - record.Velocity).Magnitude > 12 and 0.85 or 0.6
			record.Velocity = record.Velocity:Lerp(candidate, response)
		end
		record.Position, record.Time = root.Position, now
		return record.Velocity
	end

	function gameapi.TrajectoryClear(origin, velocity, gravity, flight)
		local ballistics = combat.Ballistics
		if not ballistics then return true end
		local params = store.worldParams()
		local projectile = ballistics.new(origin, velocity, gravity)
		local elapsed = 0
		while elapsed < flight - 0.025 do
			local dt = math.min(0.06, flight - elapsed - 0.025)
			if dt <= 0 then break end
			local position, displacement = ballistics.Advance(projectile, dt)
			if ballistics.Cast(position, displacement, 0, params) then return false end
			elapsed += dt
		end
		return true
	end

	local FALL_GRAVITY_SCALE = 1.3
	function gameapi.Aim(origin, target, speed, gravity, checkWalls)
		if typeof(origin) ~= 'Vector3' or not (target and target:IsA('BasePart')) then return nil end
		if type(speed) ~= 'number' or speed <= 0 then return nil end
		gravity = tonumber(gravity) or 0
		local model = target:FindFirstAncestorOfClass('Model')
		local root = model and model:FindFirstChild('HumanoidRootPart')
		local humanoid = model and model:FindFirstChildOfClass('Humanoid')
		local velocity = root and gameapi.TargetVelocity(model, root) or target.AssemblyLinearVelocity
		local airborne = (humanoid and humanoid.FloorMaterial == Enum.Material.Air) or math.abs(velocity.Y) > 1
		local latency = math.clamp(lplr:GetNetworkPing() * 0.65, 0, 0.09)
		local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
		if horizontal.Magnitude > 85 then
			horizontal = horizontal.Unit * 85
		end
		local groundHeight
		if airborne and root and humanoid then
			local hit = workspace:Raycast(root.Position, Vector3.new(0, -24, 0), store.worldParams())
			if hit and root.Position.Y - hit.Position.Y < 16 then
				groundHeight = hit.Position.Y + humanoid.HipHeight + root.Size.Y * 0.5 + (target.Position.Y - root.Position.Y)
			end
		end
		local speedSquared = speed * speed
		local lifetime = math.min(combat.Ballistics and combat.Ballistics.MAX_LIFETIME or 5, 5)

		local function evaluate(t)
			local ahead = t + latency
			local displacement = horizontal * ahead
			local point = target.Position + displacement
			if airborne then
				local rise = workspace.Gravity
				local fall = rise * FALL_GRAVITY_SCALE
				local vy = velocity.Y
				local vertical
				if vy > 0 then
					local apex = vy / rise
					if ahead <= apex then
						vertical = vy * ahead - rise * ahead * ahead * 0.5
					else
						local down = ahead - apex
						vertical = vy * apex - rise * apex * apex * 0.5 - fall * down * down * 0.5
					end
				else
					vertical = vy * ahead - fall * ahead * ahead * 0.5
				end
				local predictedY = target.Position.Y + vertical
				if groundHeight and displacement.Magnitude < 10 then
					predictedY = math.max(predictedY, groundHeight)
				end
				point = Vector3.new(point.X, predictedY, point.Z)
			end
			local offset = point - origin + Vector3.new(0, gravity * t * t * 0.5, 0)
			return offset:Dot(offset) - speedSquared * t * t, offset
		end

		local previous = 0
		for t = 0.025, lifetime, 0.025 do
			if evaluate(t) <= 0 then
				local low, high = previous, t
				for _ = 1, 24 do
					local middle = (low + high) * 0.5
					if evaluate(middle) > 0 then
						low = middle
					else
						high = middle
					end
				end
				local flight = (low + high) * 0.5
				local _, vector = evaluate(flight)
				if vector.Magnitude < 0.001 then return nil end
				local direction = vector.Unit
				if checkWalls and not gameapi.TrajectoryClear(origin, direction * speed, gravity, flight) then
					return nil
				end
				return direction, flight
			end
			previous = t
		end
		return nil
	end

	function gameapi.ShotSpeed(tool, kind, tuning)
		if not tuning then return nil end
		if combat.IsDrawn(kind) then
			local snap = gameapi.Shot
			local charge = snap.tool == tool and os.clock() - snap.at < 0.35 and snap.charge or nil
			if type(charge) == 'number' then
				local ok, _, speed = pcall(combat.DrawnShot, tuning, charge)
				if ok then return speed end
			end
			return nil
		end
		local ok, speed = pcall(combat.ShotSpeed, tuning)
		return ok and speed or nil
	end

	function gameapi.ShotProfile(tool, kind, tuning, speed)
		if not tuning or not kind then return nil end
		speed = tonumber(speed) or gameapi.ShotSpeed(tool, kind, tuning) or tonumber(tuning.speedMax) or tonumber(tuning.speed)
		if not speed or speed <= 0 then return nil end
		local gravity = tonumber(tuning.gravity)
		if gravity == nil then
			gravity = (combat.IsDrawn(kind) or kind == 'Javelin' or kind == 'Knives' or kind == 'Sling' or kind == 'Bomb') and 60 or 0
		end
		return {speed = speed, gravity = gravity}
	end

	function gameapi.Dispatch(action, pressed)
		local ok, state = pcall(controller.State)
		if not ok or type(state) ~= 'table' or state.equipPending or not util.CanAct() then return false end
		if pressed and util.IsMouseUnlocked() then return false end
		return pcall(controller.Dispatch, action, pressed)
	end

	local primaryOwner
	function gameapi.Primary(owner, pressed)
		if pressed then
			if primaryOwner == owner then return true end
			if primaryOwner ~= nil then return false end
			if inputService:GetFocusedTextBox() or lplr:GetAttribute('MenuOpen') == true then return false end
			if not gameapi.Dispatch('Primary', true) then return false end
			primaryOwner = owner
			return true
		end
		if primaryOwner ~= owner then return false end
		primaryOwner = nil
		return pcall(controller.Dispatch, 'Primary', false)
	end

	function gameapi.ReleasePrimary()
		if primaryOwner then
			primaryOwner = nil
			pcall(controller.Dispatch, 'Primary', false)
		end
	end

	for _, handler in {tribes.Bow, tribes.Throw} do
		gameapi.Patch(handler, 'Charge', function(original)
			return function(self, ...)
				local value = original(self, ...)
				gameapi.Shot = {tool = self.ctx and self.ctx.tool, charge = value, at = os.clock()}
				return value
			end
		end)
	end
	options.AutoKilling = false
end)

if not (tribes.State and tribes.Util and tribes.Combat) then
	notif('ElevateV4', 'Tribes did not finish loading before ElevateV4 did, so combat modules will do nothing. Reinject in a moment.', 15, 'alert')
end

for _, v in {'Reach', 'TriggerBot', 'Jesus', 'AutoRejoin', 'Disabler', 'MurderMystery', 'Parkour', 'Wallhop', 'AutoObby'} do
	vape:Remove(v)
end
