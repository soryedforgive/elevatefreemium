run(function()
	local AutoWin
	local Health
	local Recover
	local Engage
	local Carry
	local Gear
	local Beds
	local Helpers
	local Override
	local Status
	local Requeue
	local Awake
	local uipallet = vape.Libraries.uipallet
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	local filtered = {}
	local st
	local owned = {}
	local panel, label, shown = nil, nil, ''

	local MAX_DROP = 12
	local SHOP_RANGE = 8
	local WALK_RANGE = 14
	local BRIDGE = {'Wool$', '^Wood Plank$', '^Stone Brick$', '^Blastproof Ceramic$', '^Obsidian$'}
	local KEYS = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space}
	local PAUSE = {'Speed', 'Fly', 'InfiniteFly', 'LongJump', 'TPGlide'}
	local paused = {}

	local function aim()
		local players = workspace:FindFirstChild('PlayersContainer')
		local fake = workspace:FindFirstChild('FakeBlocksContainer')
		local drops = workspace:FindFirstChild('DroppedItemsContainer')
		local character = lplr.Character
		if filtered[1] ~= players or filtered[2] ~= fake or filtered[3] ~= drops or filtered[4] ~= character then
			filtered = {players, fake, drops, character}
			local list = {gameCamera}
			for i = 1, 4 do
				if filtered[i] then
					table.insert(list, filtered[i])
				end
			end
			rayCheck.FilterDescendantsInstances = list
		end
	end

	local function below(position, depth)
		for _ = 1, 4 do
			if depth <= 0 then return nil end
			local hit = workspace:Raycast(position, Vector3.new(0, -depth, 0), rayCheck)
			if not hit then return nil end
			if hit.Instance.Transparency < 1 then return hit end
			depth -= position.Y - hit.Position.Y + 0.1
			position = hit.Position - Vector3.new(0, 0.1, 0)
		end
		return nil
	end

	local function flat(vec)
		return Vector3.new(vec.X, 0, vec.Z)
	end

	local function feetY()
		return entitylib.character.RootPart.Position.Y - entitylib.character.HipHeight
	end

	local function groundAt(point)
		local top = feetY()
		local hit = below(Vector3.new(point.X, top + 3.5, point.Z), 3.5 + MAX_DROP)
		return hit and hit.Position.Y or nil
	end

	local function team()
		return lplr.Team and lplr.Team.Name or nil
	end

	local function bedList()
		local list = {}
		local container = workspace:FindFirstChild('BedsContainer')
		if not container then return list end
		for _, bed in container:GetChildren() do
			local hitbox = bed:FindFirstChild('BedHitbox')
			if hitbox and hitbox:IsA('BasePart') then
				table.insert(list, {Model = bed, Hitbox = hitbox, Team = bed:GetAttribute('Team')})
			end
		end
		return list
	end

	local function ownBed()
		local mine = team()
		for _, bed in bedList() do
			if bed.Team == mine then
				return bed
			end
		end
	end

	local function pivot(obj)
		if obj:IsA('BasePart') then
			return obj.Position
		elseif obj:IsA('Model') then
			return obj:GetPivot().Position
		end
	end

	local function generator()
		local info = bedfight.GameInfo and bedfight.GameInfo:FindFirstChild('MapInfo')
		local value = info and info:FindFirstChild('Generators')
		local folder = value and value.Value and value.Value:FindFirstChild('TeamGenerators')
		local gen = folder and team() and folder:FindFirstChild(team())
		return gen and pivot(gen) or nil
	end

	local function home()
		return generator() or (ownBed() and ownBed().Hitbox.Position) or st.spawn
	end

	local function shopStand()
		local base = home()
		if not base then return nil end
		local best, dist = nil, math.huge
		for _, v in collectionService:GetTagged('ItemShopPrompt') do
			if v:IsA('BasePart') and v:IsDescendantOf(workspace) then
				local mag = (v.Position - base).Magnitude
				if mag < dist then
					best, dist = v, mag
				end
			end
		end
		return dist < 120 and best or nil
	end

	local function shopNear(point)
		local best, dist = nil, math.huge
		for _, v in collectionService:GetTagged('ItemShopPrompt') do
			if v:IsA('BasePart') and v:IsDescendantOf(workspace) then
				local mag = (v.Position - point).Magnitude
				if mag < dist then
					best, dist = v, mag
				end
			end
		end
		return best, dist
	end

	local function food()
		for name, amount in store.inventory do
			local data = bedfight.ItemsData and bedfight.ItemsData[name]
			if amount > 0 and type(data) == 'table' and data.Class == 'Food' then
				return name
			end
		end
	end

	local function count(pattern)
		local total = 0
		for name, amount in store.inventory do
			if name:find(pattern) then
				total += amount
			end
		end
		return total
	end

	local function blockCount()
		local total = 0
		for _, pattern in BRIDGE do
			if pattern ~= '^Obsidian$' then
				total += count(pattern)
			end
		end
		return total
	end

	local function jump(now)
		local hum = entitylib.character.Humanoid
		if hum.FloorMaterial ~= Enum.Material.Air and now - st.jumpedAt > 0.45 then
			st.jumpedAt = now
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end

	local function overridden()
		if not Override.Enabled or inputService:GetFocusedTextBox() then return false end
		for _, key in KEYS do
			if inputService:IsKeyDown(key) then
				return true
			end
		end
		return false
	end

	local function setStatus(goal, action)
		st.goal, st.action = goal, action
	end

	local function helper(name, on)
		local module = vape.Modules[name]
		if not module then return end
		if on and not module.Enabled then
			module:Toggle()
			owned[name] = true
		elseif not on and owned[name] then
			owned[name] = nil
			if module.Enabled then
				module:Toggle()
			end
		end
	end

	local function pauseMovement(on)
		if on then
			for _, name in PAUSE do
				local module = vape.Modules[name]
				if module and module.Enabled then
					paused[name] = true
					module:Toggle()
				end
			end
		else
			for name in paused do
				local module = vape.Modules[name]
				if module and not module.Enabled then
					module:Toggle()
				end
			end
			table.clear(paused)
		end
	end

	local function warnOptions()
		local list = {}
		local function check(module, option, want)
			local mod = vape.Modules[module]
			local opt = mod and mod.Options and mod.Options[option]
			if opt and opt.Enabled ~= want then
				table.insert(list, module..' '..option..(want and ' is off' or ' is on'))
			end
		end
		check('Killaura', 'Require mouse down', false)
		check('Killaura', 'AFK check', false)
		check('Killaura', 'Limit to items', false)
		if Beds.Enabled then
			check('Breaker', 'Break Bed', true)
			check('Breaker', 'Limit to items', false)
		end
		if #list > 0 then
			notif('AutoWin', table.concat(list, ', ')..'. AutoWin needs those to fight and break beds for you.', 10, 'warning')
		end
	end

	local function walkClear(from, to)
		local gap = flat(to - from)
		local length = gap.Magnitude
		if math.abs(to.Y - from.Y) > 8 then return false end
		if length < 1 then return true end
		local dir = gap.Unit
		local top = from.Y - entitylib.character.HipHeight
		for distance = 2, length, 3 do
			local point = from + dir * distance
			if not below(Vector3.new(point.X, top + 3.5, point.Z), 3.5 + MAX_DROP) then
				return false
			end
		end
		return true
	end

	local function arrived(goal, pos)
		if typeof(st.goalKey) == 'Instance' and (goal - pos).Magnitude <= st.stopAt + 2 then return true end
		return flat(goal - pos).Magnitude <= st.stopAt and math.abs(goal.Y - pos.Y) < 8
	end

	local function drive()
		if not (st and entitylib.isAlive) then return end
		local now = tick()
		if overridden() then
			st.manualAt = now
			store.glide.Stop()
			return
		end
		if now - st.manualAt < 0.5 then return end
		if store.glide.Active() then
			lplr:Move(Vector3.zero, false)
			return
		end
		if not st.target then return end
		aim()
		local root = entitylib.character.RootPart
		local hum = entitylib.character.Humanoid
		local pos = root.Position
		local goal = st.target
		local move = Vector3.zero

		if hum.FloorMaterial == Enum.Material.Air and root.AssemblyLinearVelocity.Y < -25 and not below(pos, 40) then
			if store.catchBlock('AutoWin', 0.05) then
				st.placedAt = now
			end
			lplr:Move(Vector3.zero, false)
			return
		end

		if st.walk and not arrived(goal, pos) then
			local dir = flat(goal - pos)
			if dir.Magnitude > 0.1 then
				dir = dir.Unit
				if groundAt(pos + dir * 2.5) then
					move = dir
					local wall = workspace:Raycast(Vector3.new(pos.X, feetY() + 1.2, pos.Z), dir * 2.5, rayCheck)
					if wall and wall.Instance.Transparency < 1 then
						jump(now)
					end
				end
			end
		end
		lplr:Move(move, false)
	end

	local function healthPct()
		local hum = entitylib.character.Humanoid
		return hum.Health / math.max(hum.MaxHealth, 1) * 100
	end

	local function shop(stand, now)
		if now - st.boughtAt < 0.4 then return end
		local gui = lplr.PlayerGui:FindFirstChild('ItemShopGui')
		local module = gui and gui:FindFirstChild('ItemShopHandler')
		if not module then return end
		local ok, handler = pcall(require, module)
		if not ok then return end
		local kit = lplr:FindFirstChild('Kit')
		local okl, list = pcall(bedfight.ItemShopData.GetItemShop, false, kit and kit.Value or '')
		if not okl or type(list) ~= 'table' then return end
		local function try(category, data)
			local okr, result = pcall(handler.GetBuyResult, data.Name, data)
			if okr and result == 'Buy' then
				st.boughtAt = now
				fireRemote('PurchaseItemShopItem', stand, category, data.Name)
				return true
			end
		end
		local have = blockCount()
		local want = st.needBlocks and (st.stockTarget or 1) + Carry.Value or 0
		if have < want and (have ~= st.woolCount or now - (st.woolAt or 0) > 1.5) then
			for _, entry in list do
				if entry.Category == 'Blocks' then
					for _, data in entry.List do
						if data.Name == 'Wool' and try(entry.Category, data) then
							st.woolAt, st.woolCount = now, have
							return
						end
					end
				end
			end
		end
		if not Gear.Enabled then return end
		for _, entry in list do
			if entry.Category == 'Swords' or entry.Category == 'Armor' then
				for i = #entry.List, 1, -1 do
					local data = entry.List[i]
					if data.Max == 1 then
						local okr, result = pcall(handler.GetBuyResult, data.Name, data)
						if okr and result == 'Max' then break end
						if okr and result == 'Buy' and try(entry.Category, data) then return end
					end
				end
			end
		end
	end

	local function gearWanted()
		local gui = lplr.PlayerGui:FindFirstChild('ItemShopGui')
		local module = gui and gui:FindFirstChild('ItemShopHandler')
		if not module then return false end
		local ok, handler = pcall(require, module)
		if not ok then return false end
		local kit = lplr:FindFirstChild('Kit')
		local okl, list = pcall(bedfight.ItemShopData.GetItemShop, false, kit and kit.Value or '')
		if not okl or type(list) ~= 'table' then return false end
		for _, entry in list do
			if entry.Category == 'Swords' or entry.Category == 'Armor' then
				for i = #entry.List, 1, -1 do
					local data = entry.List[i]
					if data.Max == 1 then
						local okr, result = pcall(handler.GetBuyResult, data.Name, data)
						if okr and result == 'Max' then break end
						if okr and result == 'Buy' then return true end
					end
				end
			end
		end
		return false
	end

	local function stonesBetween(a, b)
		local gap = flat(b - a)
		local length = gap.Magnitude
		if length < 1 then return 0 end
		local dir = gap.Unit
		local top = math.max(a.Y, b.Y) + 40
		local stones, run = 0, 0
		for distance = 0, length, 6 do
			local point = a + dir * distance
			if below(Vector3.new(point.X, top, point.Z), 140) then
				if run > 0 then
					stones += math.max(math.ceil((run + 6) / 90) - 1, 0)
					run = 0
				end
			else
				run += 6
			end
		end
		return stones
	end

	local function think(now)
		if Helpers.Enabled and now - (st.helperAt or 0) > 3 then
			st.helperAt = now
			helper('Killaura', true)
			helper('AntiVoid', true)
			helper('AntiHit', true)
			helper('AntiSuffocate', true)
			if Beds.Enabled then
				helper('Breaker', true)
			end
		end
		local hopping = store.glide.Active()
		local pos = hopping and realRoot().Position or entitylib.character.RootPart.Position
		local hp = healthPct()
		if hp < Health.Value then
			st.retreating = true
		elseif st.retreating and hp >= math.max(Recover.Value, Health.Value + 10) then
			st.retreating = false
		end

		local target, goal, stopAt, key, live = nil, nil, 2, nil, false
		local enemy = store.targets({Origin = pos, Range = Engage.Value, Players = true})[1]
		local blocks = blockCount()
		local base = home()
		local stand = base and shopStand()
		local atHome = base and flat(base - pos).Magnitude < 45
		local nearby, nearDist = shopNear(pos)
		if nearby and nearDist <= SHOP_RANGE then
			shop(nearby, now)
		end
		local buyAt = now >= (st.noShop or 0) and (nearby and nearDist < 60 and nearby or stand) or nil

		if st.needBlocks then
			if blocks >= (st.stockTarget or 1) + Carry.Value then
				st.needBlocks, st.stockTarget = false, nil
			end
		elseif hopping and store.glide.Action() == 'Out of blocks' then
			st.needBlocks, st.stockTarget = true, nil
		end
		local enemyPct = enemy and enemy.Health / math.max(enemy.MaxHealth or 100, 1) * 100 or 100
		local finish = enemy and enemyPct <= 25 and (enemy.RootPart.Position - pos).Magnitude < 8
		local crowd = #store.targets({Origin = pos, Range = 26, Players = true, Limit = 4})
		local danger = crowd >= 3 and hp < 85
		local worth = enemy and (hp >= math.min(Health.Value + 30, 90) or enemyPct < hp) and (crowd <= 2 or hp >= 85)
		if Gear.Enabled and now - (st.gearAt or 0) > 2 then
			st.gearAt = now
			st.gearWant = gearWanted()
		end
		if hp < 75 and now - (st.ateAt or 0) > 3 and not (enemy and (enemy.RootPart.Position - pos).Magnitude < 12) then
			local snack = food()
			if snack then
				st.ateAt = now
				st.placedAt = now + 1.6
				equipServer(snack, 'AutoWin')
				fireRemote('Eat', true, snack)
			end
		end

		if st.retreating and base and not finish then
			target, goal, key = base, 'Retreating home', 'home'
		elseif danger and base and not finish then
			target, goal, key = base, 'Avoiding a crowd', 'home'
		elseif enemy and math.abs(enemy.RootPart.Position.Y - pos.Y) < 12 and (worth or finish) then
			target, goal, stopAt, key, live = enemy.RootPart.Position, 'Fighting '..enemy.Player.Name, 2.5, 'fight', true
		elseif base and st.needBlocks then
			local iron = count('^Iron$')
			if not st.stockTarget and buyAt then
				local from = buyAt.Position
				local to = st.destination or (st.target and st.target ~= buyAt.Position and st.target) or from
				st.stockTarget = math.max(stonesBetween(from, to), 1)
			end
			local need = math.ceil(math.max((st.stockTarget or 1) + Carry.Value - blocks, 0) / 8) * 4
			local waited = st.goalKey == 'gen' and now - st.since > 12
			if buyAt and iron >= 4 and (iron >= need or waited or st.goalKey == 'shop') then
				target, goal, stopAt, key = buyAt.Position, 'Buying blocks', SHOP_RANGE - 2, 'shop'
			else
				target, goal, stopAt, key = generator() or base, 'Collecting iron', 1.5, 'gen'
			end
		elseif base and Gear.Enabled and st.gearWant and not enemy and hp >= 60 and buyAt and (atHome or (nearDist and nearDist < 60)) then
			target, goal, stopAt, key = buyAt.Position, 'Upgrading gear', SHOP_RANGE - 2, 'shop'
		else
			local bed, best = nil, math.huge
			if Beds.Enabled then
				local mine = team()
				local current
				for _, v in bedList() do
					if v.Team ~= mine and not (st.failed[v.Model] and st.failed[v.Model] > now) then
						local mag = (v.Hitbox.Position - pos).Magnitude
						if v.Model == st.bed then
							current = v
						end
						if mag < best then
							bed, best = v, mag
						end
					end
				end
				if current and bed ~= current and best > (current.Hitbox.Position - pos).Magnitude * 0.6 then
					bed = current
				end
				st.bed = bed and bed.Model or nil
			end
			if bed then
				local spot = bed.Hitbox.Position
				target, goal, stopAt, key = spot, 'Breaking the '..tostring(bed.Team)..' bed', 12, bed.Model
			else
				local hunt = store.targets({Origin = pos, Range = 2000, Players = true})[1]
				if hunt then
					target, goal, stopAt, key, live = hunt.RootPart.Position, 'Hunting '..hunt.Player.Name, 2.5, 'hunt', true
				elseif base then
					target, goal, stopAt, key = generator() or base, 'Waiting at base', 2, 'idle'
				end
			end
		end

		if target and (key == 'fight' or key == 'hunt' or typeof(key) == 'Instance') then
			st.destination = target
		end
		if key ~= st.goalKey then
			st.goalKey, st.since = key, now
			st.progress, st.progressAt, st.stuck = math.huge, now, 0
		end
		st.target, st.stopAt, st.goal = target, stopAt, goal
		if not target then
			st.walk = false
			store.glide.Stop()
			return
		end

		local distance = (target - pos).Magnitude
		local there = arrived(target, pos)
		local reach = live and math.max(Engage.Value + 6, WALK_RANGE) or WALK_RANGE
		local clear = now >= (st.hopUntil or 0) and flat(target - pos).Magnitude <= reach and walkClear(pos, target)
		local near = clear and reach or stopAt
		st.walk = clear and not hopping

		if hopping then
			store.glide.Goal(target, near, live)
			if store.glide.Settled() then
				store.glide.Stop()
			end
			st.action = store.glide.Action() or 'Hopping'
		elseif not there and not clear and now - st.manualAt >= 0.5 and entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
			if store.glide.Start(target, near, live) then
				st.action = 'Resting'
			else
				st.action = 'Waiting for your hitbox'
			end
		elseif there then
			st.action = key == 'fight' and 'Fighting' or typeof(key) == 'Instance' and 'Mining' or key == 'shop' and 'Shopping' or 'Waiting'
		else
			st.action = live and 'Chasing' or 'Walking'
		end

		if there then
			st.progress, st.progressAt = distance, now
			return
		end
		if distance < st.progress - 2 then
			st.progress, st.progressAt, st.stuck = distance, now, 0
		elseif now - st.progressAt > 6 then
			st.progress, st.progressAt = distance, now
			st.stuck += 1
			if not hopping then
				st.hopUntil = now + 5
			end
			if st.stuck >= 2 and key == 'shop' then
				st.noShop = now + 45
			end
			if st.stuck >= 2 and typeof(key) == 'Instance' then
				st.failed[key] = now + 20
			end
		end
	end

	local function closeStatus()
		if panel then
			panel:Destroy()
		end
		panel, label, shown = nil, nil, ''
	end

	local function openStatus()
		closeStatus()
		panel = Instance.new('Frame')
		panel.Name = 'AutoWinStatus'
		panel.Size = UDim2.fromOffset(260, 70)
		panel.Position = UDim2.new(0.5, -130, 0, 46)
		panel.BackgroundColor3 = uipallet.Main
		panel.BackgroundTransparency = 0.15
		panel.BorderSizePixel = 0
		panel.Parent = vape.gui
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = panel
		label = Instance.new('TextLabel')
		label.Size = UDim2.new(1, -16, 1, -12)
		label.Position = UDim2.fromOffset(8, 6)
		label.BackgroundTransparency = 1
		label.Text = 'AutoWin is starting'
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.TextColor3 = uipallet.Text
		label.TextSize = 13
		label.FontFace = uipallet.Font
		label.Parent = panel
	end

	local function updateStatus()
		if not label then return end
		local lines = {
			'Goal: '..tostring(st.goal or 'nothing to do'),
			'Doing: '..tostring(st.action or 'thinking')..'   blocks '..blockCount(),
			(entitylib.isAlive and 'Health: '..math.floor(healthPct())..'%'..(st.retreating and '   retreating' or '') or 'Dead')
		}
		local text = table.concat(lines, '\n')
		if text ~= shown then
			shown = text
			label.Text = text
		end
	end

	AutoWin = vape.Categories.Utility:CreateModule({
		Name = 'AutoWin',
		Function = function(callback)
			if callback then
				st = {
					failed = {}, manualAt = 0, jumpedAt = 0, placedAt = 0, boughtAt = 0,
					progress = math.huge, progressAt = 0, stuck = 0, stopAt = 2
				}
				if Helpers.Enabled then
					helper('Killaura', true)
					helper('AntiVoid', true)
					helper('AntiHit', true)
					helper('AntiSuffocate', true)
					if Beds.Enabled then
						helper('Breaker', true)
					end
				end
				pauseMovement(true)
				if Requeue.Enabled then
					helper('AutoQueue', true)
				end
				if Awake.Enabled then
					helper('Anti-AFK', true)
				end
				warnOptions()
				if Status.Enabled then
					openStatus()
				end
				AutoWin:Clean(entitylib.Events.LocalAdded:Connect(function()
					task.defer(function()
						if st and entitylib.isAlive then
							st.spawn = entitylib.character.RootPart.Position
							st.spawnAt = tick()
						end
					end)
				end))
				if entitylib.isAlive then
					st.spawn = entitylib.character.RootPart.Position
				end
				runService:BindToRenderStep('AetherAutoWin', Enum.RenderPriority.Camera.Value, function()
					local ok, err = pcall(drive)
					if not ok and st and not st.warned then
						st.warned = true
						warn('[ElevateV4] AutoWin: '..tostring(err))
					end
				end)
				AutoWin:Clean(function()
					pcall(function()
						runService:UnbindFromRenderStep('AetherAutoWin')
					end)
				end)

				local lastStatus = 0
				repeat
					local now = tick()
					if entitylib.isAlive and inMatch() then
						aim()
						local ok, err = pcall(think, now)
						if not ok and st and not st.warned then
							st.warned = true
							warn('[ElevateV4] AutoWin: '..tostring(err))
						end
						if now - st.placedAt > 0.6 then
							syncTool('AutoWin')
						end
					else
						st.target, st.goalKey, st.walk = nil, nil, false
						st.spawnAt = now
						store.glide.Stop()
						setStatus(entitylib.isAlive and 'Waiting for a match' or 'Waiting to respawn', nil)
					end
					if now - lastStatus > 0.25 then
						lastStatus = now
						updateStatus()
					end
					task.wait(0.2)
				until not AutoWin.Enabled
			else
				syncTool('AutoWin')
				store.glide.Stop()
				for name in owned do
					helper(name, false)
				end
				pauseMovement(false)
				closeStatus()
				st = nil
			end
		end,
		Tooltip = 'Plays the match for you'
	})
	Health = AutoWin:CreateSlider({
		Name = 'Health',
		Min = 1,
		Max = 100,
		Default = 40,
		Suffix = '%',
		Tooltip = 'Retreats below this health'
	})
	Recover = AutoWin:CreateSlider({
		Name = 'Recover health',
		Min = 1,
		Max = 100,
		Default = 80,
		Suffix = '%',
		Tooltip = 'Health to reach before it stops retreating'
	})
	Engage = AutoWin:CreateSlider({
		Name = 'Engage range',
		Min = 5,
		Max = 60,
		Default = 24,
		Suffix = 'studs',
		Tooltip = 'Enemies this close are fought before anything else'
	})
	Carry = AutoWin:CreateSlider({
		Name = 'Extra blocks',
		Min = 0,
		Max = 20,
		Default = 0,
		Tooltip = 'Blocks to buy on top of the fewest the trip needs'
	})
	Beds = AutoWin:CreateToggle({
		Name = 'Break beds',
		Default = true,
		Tooltip = 'Goes after enemy beds'
	})
	Gear = AutoWin:CreateToggle({
		Name = 'Buy gear',
		Default = true,
		Tooltip = 'Buys the best sword and armour you can afford'
	})
	Helpers = AutoWin:CreateToggle({
		Name = 'Switch on helpers',
		Default = true,
		Tooltip = 'Turns on the modules it needs while it runs'
	})
	Override = AutoWin:CreateToggle({
		Name = 'Manual override',
		Default = true,
		Tooltip = 'Lets you steer with your movement keys'
	})
	Status = AutoWin:CreateToggle({
		Name = 'Show status',
		Default = true,
		Function = function(callback)
			if not AutoWin.Enabled then return end
			if callback then
				openStatus()
			else
				closeStatus()
			end
		end,
		Tooltip = 'Shows what it is doing at the top of the screen'
	})
	Requeue = AutoWin:CreateToggle({
		Name = 'Requeue',
		Default = true,
		Tooltip = 'Queues for the next match when one ends'
	})
	Awake = AutoWin:CreateToggle({
		Name = 'Keep awake',
		Default = true,
		Tooltip = 'Stops you being kicked for being idle while it runs'
	})
end)
