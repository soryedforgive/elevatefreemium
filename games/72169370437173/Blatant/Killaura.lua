run(function()
	local Killaura
	local Targets
	local Range
	local Max
	local FaceTarget
	local GuardCheck
	local AutoBlock
	local BlockMelee
	local BlockProjectiles
	local util, combat = tribes.Util, tribes.Combat
	local focus, attackAt, blocking = nil, 0, false
	local guardUntil, guardPosition = 0, nil
	local previousHumanoid, previousRotate
	local projectiles = {}
	local rand = Random.new()

	local function restoreRotate()
		if previousHumanoid and previousHumanoid.Parent then
			previousHumanoid.AutoRotate = previousRotate
		end
		previousHumanoid, previousRotate = nil, nil
	end

	local function setGuard(enabled)
		if blocking == enabled then return end
		gameapi.Dispatch('Secondary', enabled)
		blocking = enabled
	end

	local function findTargets(root, reach, count)
		local list = {}
		local char = lplr.Character
		local head = char and char:FindFirstChild('Head')
		local source = head and head.Position or root.Position
		local center = gameapi.Cursor()
		local world = store.worldParams()
		for _, model in util.Targets() do
			local guarded = GuardCheck.Enabled and model:GetAttribute('Blocking') == true
			if not guarded and gameapi.Enemy(model, Targets) then
				local part = model:FindFirstChild('HumanoidRootPart')
				if part then
					local delta = part.Position - root.Position
					if delta.Magnitude <= reach and math.abs(delta.Y) < 8 and (not Targets.Walls.Enabled or not workspace:Raycast(source, part.Position - source, world)) then
						local point, visible = gameCamera:WorldToViewportPoint(part.Position)
						table.insert(list, {
							Model = model,
							Part = part,
							Distance = delta.Magnitude,
							Score = visible and point.Z > 0 and (Vector2.new(point.X, point.Y) - center).Magnitude or math.huge
						})
					end
				end
			end
		end
		table.sort(list, function(a, b)
			if math.abs(a.Distance - b.Distance) < 0.1 then
				return a.Score < b.Score
			end
			return a.Distance < b.Distance
		end)
		for i = count + 1, #list do
			list[i] = nil
		end
		return list
	end

	local function sanitize(cf)
		local y, x, z = cf:ToEulerAnglesYXZ()
		return CFrame.Angles(math.clamp(y, -1.3962634015954636, 1.361356816555577), x, z).LookVector
	end

	local function swing(handler, list, root)
		local tuning, preset = handler.tuning, handler.preset or {}
		local now = os.clock()
		local oneHanded = handler:OneHanded()
		local comboTable = oneHanded and (tuning.oneHanded and tuning.oneHanded.combo or {1}) or (tuning.combo or {1})
		local animations = oneHanded and preset.oneSwings or preset.swings or {}
		if now - (handler.lastSwing or 0) <= (tuning.comboWindow or 1) then
			handler.combo = ((handler.combo or 0) % #comboTable) + 1
		else
			handler.combo = 1
		end
		handler.lastSwing = now
		local finisher = #comboTable > 2 and handler.combo == #comboTable
		local hitDelay = preset.hitDelay or 0.1
		pcall(util.PlayAnim, handler.ctx.animator, animations[((handler.combo - 1) % math.max(1, #animations)) + 1], (preset.swingSpeed or 1) * (finisher and 0.95 or 1), 0.05)
		handler.ctx.emit('Swing', {step = handler.combo, finisher = finisher, hitDelay = hitDelay, oneHanded = oneHanded})
		local hits = {}
		for _, entry in list do
			table.insert(hits, entry.Model)
		end
		handler.ctx.send('Swing', {
			dir = sanitize(CFrame.lookAt(root.Position + Vector3.new(0, 1.5, 0), list[1].Part.Position)),
			tool = handler.ctx.tool,
			hits = hits,
			k = math.floor((hitDelay + rand:NextNumber() * 0.03) * 1000),
			w = math.floor(os.clock() * 1000) % 9973
		})
		return handler:Cooldown() + hitDelay
	end

	local function combatEvent(action, payload)
		if not (Killaura.Enabled and AutoBlock.Enabled and type(payload) == 'table') then return end
		if action == 'Swing' and BlockMelee.Enabled then
			local attacker = payload.attacker
			if typeof(attacker) ~= 'Instance' then return end
			if attacker:IsA('Player') then attacker = attacker.Character end
			if not gameapi.Enemy(attacker, Targets) then return end
			local root = entitylib.isAlive and entitylib.character.RootPart
			local enemyRoot = attacker:FindFirstChild('HumanoidRootPart')
			if not (root and enemyRoot) then return end
			local held = attacker:FindFirstChildOfClass('Tool')
			local id = held and held:GetAttribute('WeaponId')
			local tune = type(id) == 'string' and combat.Tuning(id)
			local displacement = root.Position - enemyRoot.Position
			if displacement.Magnitude > (tonumber(tune and tune.range) or 8) + 2 then return end
			local horizontal = displacement * Vector3.new(1, 0, 1)
			local facing = enemyRoot.CFrame.LookVector * Vector3.new(1, 0, 1)
			if horizontal.Magnitude < 0.1 or (facing.Magnitude > 0.1 and facing.Unit:Dot(horizontal.Unit) < 0.1) then return end
			guardPosition = enemyRoot.Position
			guardUntil = math.max(guardUntil, os.clock() + 0.18)
		elseif action == 'Projectile' and BlockProjectiles.Enabled then
			if typeof(payload.origin) ~= 'Vector3' or typeof(payload.velocity) ~= 'Vector3' or payload.velocity.Magnitude < 1 then return end
			local attacker = payload.shooter
			if typeof(attacker) ~= 'Instance' then return end
			if attacker:IsA('Player') then attacker = attacker.Character end
			if not gameapi.Enemy(attacker, Targets) then return end
			local key = type(payload.key) == 'string' and payload.key or tostring(os.clock())
			projectiles[key] = {Start = payload.origin, Velocity = payload.velocity, Gravity = tonumber(payload.gravity) or 0, Seen = os.clock()}
		end
	end

	local function approachingProjectile(root)
		local now = os.clock()
		local body = root.Position + Vector3.new(0, 1, 0)
		for key, shot in projectiles do
			local age = now - shot.Seen
			if age > 2 or age < 0 then
				projectiles[key] = nil
			else
				local current = shot.Start + shot.Velocity * age - Vector3.new(0, shot.Gravity * age * age * 0.5, 0)
				local motion = shot.Velocity - Vector3.new(0, shot.Gravity * age, 0)
				local t = (body - current):Dot(motion) / math.max(motion:Dot(motion), 1)
				if t > 0 and t < 0.3 then
					local impact = current + motion * t - Vector3.new(0, shot.Gravity * t * t * 0.5, 0)
					local moved = body + root.AssemblyLinearVelocity * math.min(t, 0.12)
					if (impact - moved).Magnitude <= 4 and not workspace:Raycast(current, impact - current, store.worldParams()) then
						guardPosition = current
						guardUntil = math.max(guardUntil, now + t + 0.07)
						return true
					end
				end
			end
		end
		return false
	end

	local function step()
		local handler, class = store.handler()
		local root = entitylib.isAlive and entitylib.character.RootPart
		if gameapi.Options.AutoKilling or not canAct() or class ~= 'Melee' or not (handler and handler.ctx and handler.ctx.tool and root) then
			focus, store.meleeTarget, store.strikeAt = nil, nil, nil
			setGuard(false)
			return
		end
		local tuning = handler.tuning
		local limit = math.max(1, math.min(math.floor(Max.Value), tuning.maxTargets or 1))
		local list = findTargets(root, Range.Value, limit)
		local first = list[1]
		local now = os.clock()
		local ready = attackAt <= now

		if AutoBlock.Enabled and tuning.block then
			if BlockProjectiles.Enabled and (tonumber(tuning.block.ranged) or 0) > 0 then
				approachingProjectile(root)
			end
			if now < guardUntil and (not first or not ready) then
				setGuard(true)
				return
			end
		end

		focus = first and first.Part
		local ent = first and entitylib.getEntity(first.Model)
		store.meleeTarget = ent
		store.strikeAt = first and tick() + math.max(attackAt - now, 0) or nil
		for _, entry in list do
			local target = entitylib.getEntity(entry.Model)
			if target then
				targetinfo.Targets[target] = tick() + 1
			end
		end
		if ent and targetinfo.Focus then
			targetinfo.Focus[ent] = tick() + 1
		end

		if first and ready then
			setGuard(false)
			local ok, wait = pcall(swing, handler, list, root)
			attackAt = now + (ok and wait or 0.3)
			if vape.ThreadFix then
				setthreadidentity(8)
			end
		end
	end

	Killaura = vape.Categories.Blatant:CreateModule({
		Name = 'Killaura',
		Function = function(callback)
			if callback then
				local net = tribes.Net
				if net then
					for _, name in {'Event', 'UnreliableEvent'} do
						local ok, remote = pcall(net[name], name == 'Event' and 'CombatFX' or 'CombatFXU')
						if ok and remote then
							Killaura:Clean(remote.OnClientEvent:Connect(combatEvent))
						end
					end
				end
				Killaura:Clean(runService.RenderStepped:Connect(function()
					local hum = entitylib.isAlive and entitylib.character.Humanoid
					local root = entitylib.isAlive and entitylib.character.RootPart
					local position = blocking and guardPosition or (FaceTarget.Enabled and focus and focus.Parent and focus.Position)
					if not (hum and root and position) or gameapi.Options.AutoKilling then
						restoreRotate()
						return
					end
					if previousHumanoid ~= hum then
						restoreRotate()
						previousHumanoid, previousRotate = hum, hum.AutoRotate
					end
					hum.AutoRotate = false
					local flat = Vector3.new(position.X, root.Position.Y, position.Z)
					if (flat - root.Position).Magnitude > 0.1 then
						root.CFrame = CFrame.lookAt(root.Position, flat)
					end
				end))
				repeat
					local ok, err = pcall(step)
					if not ok then
						focus = nil
						setGuard(false)
						warn('[ElevateV4] Killaura: '..tostring(err))
					end
					task.wait()
				until not Killaura.Enabled
			else
				setGuard(false)
				focus, store.meleeTarget, store.strikeAt = nil, nil, nil
				guardUntil, guardPosition = 0, nil
				table.clear(projectiles)
				restoreRotate()
			end
		end,
		Tooltip = 'Attacks players around you without aiming'
	})
	Targets = Killaura:CreateTargets({
		Players = true,
		NPCs = true,
		Walls = true
	})
	Range = Killaura:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 14,
		Default = 14,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Max = Killaura:CreateSlider({
		Name = 'Max targets',
		Min = 1,
		Max = 10,
		Default = 10,
		Tooltip = 'How many targets to hit at once'
	})
	FaceTarget = Killaura:CreateToggle({
		Name = 'Face target',
		Default = true
	})
	GuardCheck = Killaura:CreateToggle({
		Name = 'Guard check',
		Tooltip = 'Waits for enemies to drop their block before swinging at them'
	})
	AutoBlock = Killaura:CreateGroup({
		Name = 'AutoBlock',
		Function = function(callback)
			if BlockMelee then
			end
			if not callback then
				guardUntil, guardPosition = 0, nil
				setGuard(false)
				table.clear(projectiles)
			end
		end,
		Tooltip = 'Blocks while your next swing is not ready'
	})
	BlockMelee = AutoBlock:CreateToggle({
		Name = 'Melee',
		Default = true,
		Darker = true
	})
	BlockProjectiles = AutoBlock:CreateToggle({
		Name = 'Projectiles',
		Default = true,
		Darker = true
	})
end)
