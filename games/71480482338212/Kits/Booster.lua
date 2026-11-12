run(function()
	local Booster
	local Subs
	local InfiniteFuel, FloatBypass, NoFallDamage, AntiVoid, AntiHit
	local MinFall
	local BobHeight
	local VoidDrop, VoidHeight
	local HitRange, HitHeight, HitKeep, HitDodge
	local FLAT = Vector3.new(1, 0, 1)
	local REASSERT = 0.5
	local TAP_LEAD = 0.15
	local BOB_PERIOD, BOB_RISE, BOB = 0.3, 0.4, 1
	local MIN_PHASE = 0.06
	local LEAD, HOLD = 0.18, 0.08
	local STRIKE_UP, STRIKE_REACH = 9, 12.5
	local jet = {On = false, SentAt = 0, Lv = nil, Told = false, Reassert = nil, FilterAt = 0, Game = nil, Owned = false, SearchAt = 0, Spoof = false, PushFrames = 0, UserBoost = false}
	local fall = {Peak = nil, Fired = false, Until = 0}
	local ctl = {Active = false, Owner = nil, V = 0, Push = false, SwitchAt = 0, Goal = 0}
	local void = {Active = false, Since = 0, Ground = nil}
	local hit = {Lifted = false, Idle = 0, Resting = false, RestAt = 0, ReleasedAt = 0, Struck = 0, Seen = nil, GateSince = nil, GateAt = 0, ManagedAt = 0, ReachOf = nil, ReachSince = nil, Up = STRIKE_UP, Sent = 0, Landed = 0, WindowAt = 0, Gate = nil}
	local dangers = {}

	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	rayCheck.RespectCanCollide = true

	local function filter(now)
		if now - jet.FilterAt < 1 then return end
		jet.FilterAt = now
		local list = {workspace:FindFirstChild('PlayersContainer') or lplr.Character, gameCamera}
		for _, name in {'FakeBlocksContainer', 'ProjectilesContainer', 'DroppedItemsContainer'} do
			local found = workspace:FindFirstChild(name)
			if found then table.insert(list, found) end
		end
		if lplr.Character then table.insert(list, lplr.Character) end
		rayCheck.FilterDescendantsInstances = list
	end

	local function floorBelow(position, depth)
		local result = workspace:Raycast(position, Vector3.new(0, -depth, 0), rayCheck)
		if result and result.Instance.Transparency < 1 then return result end
	end

	local function wave(t, amp)
		local phase = (t % BOB_PERIOD) / BOB_PERIOD
		if phase < BOB_RISE then
			return amp * phase / BOB_RISE, true
		end
		return amp * (1 - (phase - BOB_RISE) / (1 - BOB_RISE)), false
	end

	local function equipped()
		local value = lplr:FindFirstChild('EquippedBackpack')
		return value ~= nil and value.Value == 'Jetpack'
	end

	local function jetState()
		local state = bedfight.JetpackState
		return type(state) == 'table' and state or nil
	end

	local function gameFuelRunning()
		local gui = lplr:FindFirstChild('PlayerGui')
		gui = gui and gui:FindFirstChild('JetpackFuelGui')
		return gui ~= nil and gui.Enabled
	end

	local function send(on)
		jet.On = on
		jet.SentAt = tick()
		if remotes.Jetpack and remotes.Jetpack.Parent then
			pcall(function()
				remotes.Jetpack:FireServer(on)
			end)
		end
	end

	local function upvalue(fn, index)
		local a, b = debug.getupvalue(fn, index)
		if type(a) == 'string' and b ~= nil then return b end
		return a
	end

	local function findGame()
		local g = jet.Game
		if g then
			if g.Hum.Parent and g.Hum.Parent == lplr.Character then return g end
			jet.Game, jet.Owned = nil, false
		end
		local now = tick()
		if now < jet.SearchAt or not (getconnections and debug.getupvalues and debug.getupvalue and debug.setupvalue and bedfight.ButtonProperties) then return nil end
		jet.SearchAt = now + 2
		local trigger
		pcall(function()
			local signal = bedfight.ButtonProperties.new('Jump').Active:GetPropertyChangedSignal('Value')
			for _, conn in getconnections(signal) do
				local fn = conn.Function
				if type(fn) == 'function' then
					for _, up in debug.getupvalues(fn) do
						if type(up) == 'function' and debug.info(up, 'n') == 'Trigger' then
							trigger = up
							break
						end
					end
				end
				if trigger then break end
			end
		end)
		if not trigger then return nil end
		g = {Trigger = trigger}
		for i, up in debug.getupvalues(trigger) do
			if g.State == nil and type(up) == 'boolean' then g.State = i end
			if typeof(up) == 'Instance' then
				if up:IsA('Humanoid') then
					g.Hum, g.HumIndex = up, i
				elseif up:IsA('LinearVelocity') then
					g.Lv = up
				end
			end
		end
		if not (g.State and g.Hum and g.Lv) or g.Hum.Parent ~= lplr.Character then return nil end
		local hum = g.Hum
		g.Proxy = setmetatable({}, {__index = function(_, key)
			if key == 'FloorMaterial' and jet.Spoof then return Enum.Material.Air end
			return hum[key]
		end})
		jet.Game = g
		return g
	end

	local function gameOn(g)
		return upvalue(g.Trigger, g.State) == true
	end

	local function trigger(g, on)
		if on then
			jet.Spoof = true
			pcall(debug.setupvalue, g.Trigger, g.HumIndex, g.Proxy)
		end
		pcall(g.Trigger, on)
		if on then
			pcall(debug.setupvalue, g.Trigger, g.HumIndex, g.Hum)
			jet.Spoof = false
		end
		jet.SentAt = tick()
	end

	local function boosting()
		return jet.UserBoost == true
	end

	local function hold(wants)
		local g = findGame()
		if not g then
			if wants then
				if not jet.On or tick() - jet.SentAt >= REASSERT or (jet.Reassert and tick() >= jet.Reassert) then
					jet.Reassert = nil
					send(true)
				end
			elseif jet.On then
				send(false)
			end
			return false
		end
		if wants then
			if not gameOn(g) then
				g.Lv.Enabled = false
				trigger(g, true)
				if gameOn(g) and not g.Lv.Enabled then
					pcall(debug.setupvalue, g.Trigger, g.State, false)
				end
				jet.Owned = gameOn(g)
			end
		elseif jet.Owned then
			jet.Owned = false
			if gameOn(g) and not boosting() then trigger(g, false) end
		end
		jet.On = gameOn(g)
		return true
	end

	local function template()
		local scripts = lplr:FindFirstChild('PlayerScripts')
		local manager = scripts and scripts:FindFirstChild('KitsManagerScript')
		local booster = manager and manager:FindFirstChild('Booster')
		return booster and booster:FindFirstChild('LinearVelocity')
	end

	local function setForce(speed)
		if not speed then
			if jet.Lv then jet.Lv.Enabled = false end
			return
		end
		local root = bodyRoot()
		local character = lplr.Character
		if not (root and character) then return end
		local lv = jet.Lv
		if not (lv and lv.Parent == character) then
			local source = template()
			lv = source and source:Clone() or Instance.new('LinearVelocity')
			lv.Name = 'AetherBooster'
			lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
			lv.LineDirection = Vector3.new(0, 1, 0)
			lv.RelativeTo = Enum.ActuatorRelativeTo.World
			lv.ForceLimitMode = Enum.ForceLimitMode.Magnitude
			lv.MaxForce = 1000000
			lv.Enabled = false
			lv.Parent = character
			jet.Lv = lv
		end
		local attachment = root:FindFirstChild('RootAttachment')
		if not attachment then return end
		if lv.Attachment0 ~= attachment then lv.Attachment0 = attachment end
		if lv.LineVelocity ~= speed then lv.LineVelocity = speed end
		if not lv.Enabled then lv.Enabled = true end
	end

	local function airborne(hip)
		if store.split then
			local real = realRoot()
			return not floorBelow(real.Position, hip + 0.75)
		end
		return entitylib.character.Humanoid.FloorMaterial == Enum.Material.Air
	end

	local function releaseHit()
		if hit.Lifted then
			hit.Lifted = false
			hit.ReleasedAt = tick()
			if store.antiHit == 'booster' then store.antiHit = nil end
			mergeRoot('BoosterAntiHit')
		end
		hit.ReachOf, hit.ReachSince = nil, nil
	end

	local function shut()
		releaseHit()
		if jet.Owned or jet.On then hold(false) end
		setForce(nil)
		fall.Peak, fall.Fired, fall.Until = nil, false, 0
		void.Active = false
		ctl.Active = false
	end

	local function cooldown()
		local data = store.tools.sword and bedfight.SwordsData and bedfight.SwordsData[store.tools.sword]
		return type(data) == 'table' and data.DamageCooldown or 0.3
	end

	local function room(y, now)
		local least = math.huge
		for _, shot in dangers do
			if now >= shot.From then
				least = math.min(least, math.abs(shot.Y - y) - shot.Need)
			end
		end
		return least
	end

	local function stepFall(now, body, hum, hip)
		if not NoFallDamage.Enabled or store.split or store.flyOn or store.dashOn or hum.FloorMaterial ~= Enum.Material.Air then
			fall.Peak, fall.Fired = nil, false
			return now < fall.Until
		end
		local y = body.Position.Y
		fall.Peak = math.max(fall.Peak or y, y)
		local vy = body.AssemblyLinearVelocity.Y
		if not fall.Fired and vy < -15 then
			local speed = -vy
			local below = floorBelow(body.Position, hip + speed * 0.3 + 6)
			if below and fall.Peak - hip - below.Position.Y >= MinFall.Value then
				local drop = math.max(y - hip - below.Position.Y, 0)
				local g = workspace.Gravity
				local t = (-speed + math.sqrt(speed * speed + 2 * g * drop)) / g
				if t <= math.clamp(14 / speed, 0.08, TAP_LEAD) + 1 / 60 then
					fall.Fired = true
					fall.Until = now + t + 0.05
					jet.PushFrames = 1
				end
			end
		end
		return now < fall.Until
	end

	local function manual()
		if jet.UserBoost or inputService:GetFocusedTextBox() then return jet.UserBoost == true end
		return inputService:IsKeyDown(Enum.KeyCode.Space) or inputService:IsKeyDown(Enum.KeyCode.LeftShift)
	end

	local function level(dt, body, goal)
		local y, g = body.Position.Y, workspace.Gravity
		local source = jet.Game and jet.Game.Lv or template()
		local lift = source and source.LineVelocity or 50
		local up = math.max((source and source.MaxForce or 7000) / math.max(body.AssemblyMass, 1) - g, 60)
		local band = BobHeight.Value / 2
		local now = tick()
		local v = ctl.V
		if ctl.Push then
			if v > 0 and y + v * dt + v * v / (2 * g) >= goal + band then
				ctl.Push = false
			end
		elseif v < 0 and y + v * dt - v * v / (2 * up) <= goal - band and now - ctl.SwitchAt >= MIN_PHASE then
			ctl.Push, ctl.SwitchAt = true, now
		end
		ctl.V = ctl.Push and math.min(v + up * dt, lift) or math.max(v - g * dt, -lift * 3)
		return ctl.V, ctl.Push
	end

	local function stepLevel(dt, body, hum)
		local y = body.Position.Y
		local grounded = hum.FloorMaterial ~= Enum.Material.Air
		local owner
		if grounded then
			void.Ground = y
			void.Active = false
		elseif AntiVoid.Enabled and void.Ground and not store.split then
			if not void.Active and body.AssemblyLinearVelocity.Y < -5 and y < void.Ground - VoidDrop.Value and not floorBelow(body.Position, 400) then
				void.Active = true
				releaseHit()
			end
			if void.Active and floorBelow(body.Position, math.max(y - void.Ground, 0) + 30) then
				void.Active = false
			end
			if void.Active then owner = 'void' end
		else
			void.Active = false
		end
		if not owner and FloatBypass.Enabled and not grounded and not store.split and not floorBelow(body.Position, 400) then
			owner = 'float'
		end
		if not owner or store.dashOn or manual() then
			ctl.Active = false
			return nil, false
		end
		if not ctl.Active or ctl.Owner ~= owner then
			ctl.Active, ctl.Owner = true, owner
			ctl.V = math.clamp(body.AssemblyLinearVelocity.Y, -150, 50)
			ctl.Push, ctl.SwitchAt = false, 0
			ctl.Goal = y
		end
		return level(dt, body, owner == 'void' and void.Ground + VoidHeight.Value or ctl.Goal)
	end

	local function stepHit(now, body, hip, fuel, infinite)
		if not AntiHit.Enabled or store.flyOn or store.dashOn or void.Active then
			releaseHit()
			return false
		end
		local regular = vape.Modules.AntiHit
		if regular and regular.Enabled then
			releaseHit()
			if not jet.Told then
				jet.Told = true
				notif('Booster', 'AntiHit is on, so the Booster AntiHit waits until you turn it off.', 5, 'warning')
			end
			return false
		end
		for i = #dangers, 1, -1 do
			if dangers[i].To < now then table.remove(dangers, i) end
		end
		local danger = dangers[1]
		local threat = canFight() and store.targets({Range = HitRange.Value, Players = true, NPCs = true, Limit = 1})[1]
		if threat or danger then
			hit.Idle = now
		elseif now - hit.Idle > 0.6 then
			releaseHit()
			return false
		end
		local under = floorBelow(body.Position, HitHeight.Value + hip + 20)
		if not under then
			releaseHit()
			return false
		end
		if not hit.Lifted then
			if store.split or store.antiHit or not splitRoot('BoosterAntiHit') then return false end
			hit.Lifted = true
			store.antiHit = 'booster'
		end

		if store.struckAt ~= hit.Seen then
			hit.Seen = store.struckAt
			hit.Struck = now
			hit.GateSince = nil
			hit.Sent += 1
		elseif hit.GateSince and now - hit.GateAt > 0.15 then
			hit.GateSince = nil
		end
		if now - hit.WindowAt >= 1 + lplr:GetNetworkPing() then
			if hit.Sent >= 3 then
				if hit.Landed == 0 then
					hit.Up = math.max(hit.Up - 2.5, 0)
				elseif hit.Up < STRIKE_UP then
					hit.Up = math.min(hit.Up + 0.25, STRIKE_UP)
				end
			end
			hit.Sent, hit.Landed, hit.WindowAt = 0, 0, now
		end

		if not store.strikeGate then store.strikeGate = hit.Gate end
		if not infinite then
			if fuel <= 0.08 and not hit.Resting then
				hit.Resting, hit.RestAt = true, now
			elseif hit.Resting and fuel >= 0.6 then
				hit.Resting = false
			end
		else
			hit.Resting = false
		end

		local spot = Vector3.new(body.Position.X, under.Position.Y + hip, body.Position.Z)
		local top = spot.Y + HitHeight.Value
		store.antiHitAt = now
		hit.ManagedAt = now

		local fighting = now - (store.melee or 0) < 0.4
		local target = HitKeep.Enabled and fighting and store.meleeTarget or nil
		if target and not (target.RootPart and target.RootPart.Parent) then target = nil end
		local reach = math.min(store.meleeRange or 14, 14)
		local strikeY
		if target then
			local far = math.min(reach - 0.75, STRIKE_REACH)
			local aimed = target.RootPart.Position
			local flat = ((aimed - spot) * FLAT).Magnitude
			strikeY = math.clamp(aimed.Y + math.min(far > flat and math.sqrt(far * far - flat * flat) or 0, hit.Up), spot.Y, top)
		end
		local due = target and math.max(store.meleeDue or now, hit.Struck + cooldown()) or nil
		local strike = due and ((due - now <= LEAD and now - due < 0.3) or now - hit.Struck < HOLD)

		hit.WaveStart = hit.WaveStart or now
		local off, rising = wave(now - hit.WaveStart, BOB)
		local y
		if hit.Resting then
			y, rising = spot.Y, false
		elseif strike then
			y = math.max(strikeY - BOB + off, spot.Y)
		else
			y = top - BOB + off
		end
		if danger and room(y, now) < 0 then
			local best, most = y, room(y, now)
			local try = top
			while try >= spot.Y do
				local space = room(try, now)
				if space > most + 0.5 then
					best, most = try, space
				end
				try -= 3
			end
			if room(spot.Y, now) > most + 0.5 then best = spot.Y end
			y = best
		end

		local at = Vector3.new(spot.X, y, spot.Z)
		if target and (at - target.RootPart.Position).Magnitude <= reach - 0.25 then
			if hit.ReachOf ~= target or not hit.ReachSince then
				hit.ReachOf, hit.ReachSince = target, now
			end
		else
			hit.ReachOf, hit.ReachSince = nil, nil
		end
		sendRoot(CFrame.new(at) * body.CFrame.Rotation)
		return y - spot.Y > 0.75 and rising or (hit.Resting and now - hit.RestAt < 0.2)
	end

	local function drive(dt)
		if not entitylib.isAlive or not equipped() then
			shut()
			return
		end
		local now = tick()
		filter(now)
		local body, hum, hip = bodyRoot(), entitylib.character.Humanoid, entitylib.character.HipHeight
		local state = jetState()
		local infinite = InfiniteFuel.Enabled
		if infinite and state then state.Fuel = 1 end
		local fuel = state and state.Fuel or 1

		local force, pushing = stepLevel(dt, body, hum)
		local tapping = stepFall(now, body, hum, hip)
		local bobbing = stepHit(now, body, hip, fuel, infinite)
		local wants = pushing or bobbing or tapping or now - hit.ReleasedAt < 0.4

		if not infinite and fuel <= 0 then
			wants, force = false, nil
			ctl.Active = false
		end
		local native = hold(wants)
		if not native and state and not infinite then
			if wants then
				state.Fuel = math.max(fuel - dt / 3, 0)
			elseif fuel < 1 and not gameFuelRunning() and not airborne(hip) then
				state.Fuel = math.min(fuel + dt / 10, 1)
			end
		end
		setForce(force)
	end

	Booster = vape.Categories.Kits:CreateModule({
		Name = 'Booster',
		Category = 'Ability',
		Tags = {'Experimental'},
		Function = function(callback)
			if callback then
				jet.Told, jet.On, jet.FilterAt = false, false, 0
				hit.Up, hit.Sent, hit.Landed, hit.WindowAt = STRIKE_UP, 0, 0, tick()
				if not equipped() then
					notif('Booster', 'No Jetpack equipped. Buy it in the Booster kit shop, nothing here works until then.', 7, 'warning')
				end

				hit.Gate = function(ent)
					local now = tick()
					if not HitKeep.Enabled or now - hit.ManagedAt > 0.1 then return true end
					hit.GateAt = now
					hit.GateSince = hit.GateSince or now
					if now - hit.GateSince > 0.45 then return true end
					if now - hit.Struck < cooldown() - 0.02 then return false end
					return hit.ReachOf == ent and hit.ReachSince ~= nil and now - hit.ReachSince >= LEAD
				end
				if not store.strikeGate then store.strikeGate = hit.Gate end

				jet.Game, jet.Owned, jet.SearchAt = nil, false, 0
				Booster:Clean(runService.PreSimulation:Connect(function()
					local g = jet.Game
					if not (g and jet.Owned) then return end
					local state = jetState()
					local push = (boosting() or jet.PushFrames > 0) and (not state or state.Fuel > 0)
					if jet.PushFrames > 0 then jet.PushFrames -= 1 end
					if g.Lv.Enabled ~= push then g.Lv.Enabled = push end
				end))
				Booster:Clean(entitylib.Events.LocalAdded:Connect(function()
					jet.Lv, jet.On = nil, false
					jet.Game, jet.Owned, jet.SearchAt = nil, false, 0
					hit.Lifted = false
					if store.antiHit == 'booster' then store.antiHit = nil end
					fall.Peak, fall.Fired, fall.Until = nil, false, 0
					void.Active, void.Ground = false, nil
					table.clear(dangers)
				end))
				Booster:Clean(inputService.InputBegan:Connect(function(input, processed)
					if processed or not entitylib.isAlive then return end
					if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonX then
						jet.UserBoost = entitylib.character.Humanoid.FloorMaterial == Enum.Material.Air
					end
				end))
				Booster:Clean(inputService.InputEnded:Connect(function(input)
					if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonX then
						jet.Reassert = tick() + 0.06
						jet.UserBoost = false
					end
				end))
				if remotes.DamageIndicator then
					Booster:Clean(remotes.DamageIndicator.OnClientEvent:Connect(function(victim)
						local target = store.meleeTarget
						if hit.Lifted and target and victim == target.Character then
							hit.Landed += 1
						end
					end))
				end
				local remote = replicatedStorage:FindFirstChild('Remotes')
				remote = remote and remote:FindFirstChild('ReplicateProjectile')
				if remote then
					Booster:Clean(remote.OnClientEvent:Connect(function(userId, _, name, origin, speed, unit)
						if not (AntiHit.Enabled and HitDodge.Enabled) or userId == lplr.UserId or not entitylib.isAlive then return end
						if typeof(origin) ~= 'Vector3' or typeof(unit) ~= 'Vector3' or type(speed) ~= 'number' then return end
						local data = bedfight.ProjectilesData and bedfight.ProjectilesData[name]
						if type(data) ~= 'table' then return end
						local shooter = playersService:GetPlayerByUserId(userId)
						if shooter and lplr.Team and shooter.Team == lplr.Team and lplr.Team.Name ~= 'Spectators' then return end
						local body = bodyRoot().Position
						local velocity = unit * speed
						local across = velocity * FLAT
						if across.Magnitude < 1 then return end
						local t = ((body - origin) * FLAT):Dot(across) / across.Magnitude ^ 2
						if t <= 0 or t > math.min(data.LifeTime or 5, 4) then return end
						local gravity = typeof(data.Gravity) == 'Vector3' and data.Gravity or Vector3.zero
						local at = origin + velocity * t + gravity * (t * t / 2)
						local blast = data.BlastRadius or 0
						if ((at - body) * FLAT).Magnitude > blast + 8 or #dangers >= 24 then return end
						local now = tick()
						table.insert(dangers, {From = now, To = now + t + 0.35 + math.min(lplr:GetNetworkPing(), 0.4), Y = at.Y, Need = math.max(5, blast + 3)})
					end))
				end
				Booster:Clean(runService.Heartbeat:Connect(drive))
			else
				shut()
				if store.strikeGate == hit.Gate then store.strikeGate = nil end
				table.clear(dangers)
			end
		end,
		Tooltip = 'Experimental: the Booster kit jetpack, split into modules you can use together'
	})

	Subs = Booster:CreateSubModules({Name = 'Booster modules'})
	Booster.SubModules = Subs

	InfiniteFuel = Subs:Create({
		Name = 'InfiniteFuel',
		Default = true,
		Tooltip = 'Keeps your jetpack fuel full',
		Function = function() end
	})

	FloatBypass = Subs:Create({
		Name = 'FloatBypass',
		Tooltip = 'Over the void, presses and releases the jetpack like a player would, so you hover almost level and are not flagged for floating',
		Function = function() end
	})
	BobHeight = FloatBypass:CreateSlider({
		Name = 'Bob height',
		Min = 0.5,
		Max = 3,
		Default = 1,
		Decimal = 10,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How far you rise and fall between presses while hovering'
	})

	NoFallDamage = Subs:Create({
		Name = 'NoFallDamage',
		Tooltip = 'Taps the jetpack once just before you land from a fall that would hurt, like a quick press of Space',
		Function = function(callback)
			if not callback then fall.Peak, fall.Fired, fall.Until = nil, false, 0 end
		end
	})
	MinFall = NoFallDamage:CreateSlider({
		Name = 'Minimum fall',
		Min = 10,
		Max = 30,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'Falls shorter than this are left alone'
	})

	AntiVoid = Subs:Create({
		Name = 'AntiVoid',
		Tooltip = 'Holds the jetpack to fly you back up when you fall into the void, then hovers until there is ground below you',
		Function = function(callback)
			if not callback then
				void.Active = false
				setForce(nil)
			end
		end
	})
	VoidDrop = AntiVoid:CreateSlider({
		Name = 'Fall distance',
		Min = 2,
		Max = 30,
		Default = 6,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How far below where you last stood you fall, with only void under you, before it lifts you'
	})
	VoidHeight = AntiVoid:CreateSlider({
		Name = 'Lift to',
		Min = 0,
		Max = 20,
		Default = 5,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How far above where you last stood it lifts you'
	})

	AntiHit = Subs:Create({
		Name = 'AntiHit',
		Tooltip = 'Lifts your hitbox out of sword reach while enemies are close, with the jetpack keeping it up',
		Function = function(callback)
			if not callback then releaseHit() end
		end
	})
	HitRange = AntiHit:CreateSlider({
		Name = 'Range',
		Min = 10,
		Max = 40,
		Default = 22,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How close an enemy must be before your hitbox lifts'
	})
	HitHeight = AntiHit:CreateSlider({
		Name = 'Hover height',
		Min = 12,
		Max = 24,
		Default = 17,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How high above the ground your hitbox waits'
	})
	HitKeep = AntiHit:CreateToggle({
		Name = 'Keep your hits',
		Default = true,
		Tooltip = 'Brings your hitbox into reach as Killaura lands each hit'
	})
	HitDodge = AntiHit:CreateToggle({
		Name = 'Dodge projectiles',
		Default = true,
		Tooltip = 'Moves your hitbox out of the way of incoming shots'
	})
end)
