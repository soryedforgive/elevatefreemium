run(function()
	local AutoWin
	local Requeue
	local util, combat, controller = tribes.Util, tribes.Combat, tribes.Controller
	local state, queueApi = tribes.UIState, tribes.UIRemotes
	local options = gameapi.Options
	local target
	local held = false
	local fighting = false
	local generation = 0
	local nextEquip, equippedReadyAt, nextSearch = 0, 0, 0
	local oldHumanoid, oldAutoRotate
	local lastQueueAt, lastQueueKey = -math.huge, nil
	local queueBusy, matchFinished, replayWaitUntil = false, false, 0

	local function attack(enabled)
		if held == enabled then return end
		if enabled then
			held = gameapi.Primary('AutoWin', true)
		else
			gameapi.Primary('AutoWin', false)
			held = false
		end
	end

	local function enemy(model)
		return model and gameapi.Enemy(model)
	end

	local function nearest(root)
		local best, bestDistance
		for _, model in util.Targets() do
			if enemy(model) then
				local part = model:FindFirstChild('HumanoidRootPart')
				if part then
					local distance = (part.Position - root.Position).Magnitude
					if not bestDistance or distance < bestDistance then
						best, bestDistance = model, distance
					end
				end
			end
		end
		return best
	end

	local function strongest()
		local best, bestScore
		for _, container in {lplr.Character, lplr:FindFirstChildOfClass('Backpack')} do
			for _, item in container and container:GetChildren() or {} do
				local id = item:IsA('Tool') and item:GetAttribute('WeaponId')
				local kind = type(id) == 'string' and combat.Kind(id)
				if kind and combat.IsMelee(kind) then
					local tuning = combat.Tuning(id)
					local damage = tonumber(tuning and tuning.damage) or 0
					local delay = math.max(tonumber(tuning and tuning.cooldown) or 0.5, 0.15)
					local score = damage * (tonumber(tuning and tuning.backstabMult) or 1) / delay
					if not bestScore or score > bestScore then
						best, bestScore = item, score
					end
				end
			end
		end
		return best
	end

	local function restoreRotate()
		if oldHumanoid and oldHumanoid.Parent then
			oldHumanoid.AutoRotate = oldAutoRotate
		end
		oldHumanoid, oldAutoRotate = nil, nil
	end

	local function setFighting(enabled)
		if fighting == enabled then return end
		fighting = enabled
		options.AutoKilling = enabled
		if not enabled then
			attack(false)
			target = nil
			restoreRotate()
		end
	end

	gameapi.Patch(util, 'GetAimRay', function(original)
		return function(...)
			local ray = original(...)
			if not (fighting and enemy(target)) then return ray end
			local _, _, kind = gameapi.Tool()
			local part = target:FindFirstChild('HumanoidRootPart')
			if not (kind and combat.IsMelee(kind) and part) then return ray end
			local aim = part.Position + part.AssemblyLinearVelocity * 0.04 - ray.Origin
			return aim.Magnitude > 0.01 and Ray.new(ray.Origin, aim.Unit) or ray
		end
	end)
	gameapi.Patch(util, 'FaceCamera', function(original)
		return function(...)
			if fighting and enemy(target) then return end
			return original(...)
		end
	end)
	gameapi.Patch(tribes.Melee, 'Detect', function(original)
		return function(self, nativeRange, nativeArc, maxTargets)
			if not fighting then
				return original(self, nativeRange, nativeArc, maxTargets)
			end
			if not (enemy(target) and self.ctx and self.ctx.root) then return {} end
			local part = target:FindFirstChild('HumanoidRootPart')
			if not part then return {} end
			local root = self.ctx.root
			local delta = part.Position - root.Position
			if delta.Magnitude > (tonumber(nativeRange) or 8) + 1.2 or math.abs(delta.Y) >= 8 then return {} end
			local head = self.ctx.char and self.ctx.char:FindFirstChild('Head')
			local origin = head and head.Position or root.Position
			if workspace:Raycast(origin, part.Position - origin, store.worldParams()) then return {} end
			return {target}
		end
	end)

	local function follow()
		if not fighting then return end
		local char = lplr.Character
		local root = char and char:FindFirstChild('HumanoidRootPart')
		local humanoid = char and char:FindFirstChildOfClass('Humanoid')
		if not (root and humanoid and humanoid.Health > 0 and util.CanAct()) then
			target = nil
			attack(false)
			restoreRotate()
			return
		end
		if not (enemy(target) and target:FindFirstChild('HumanoidRootPart')) then
			target = nil
			attack(false)
			if os.clock() >= nextSearch then
				nextSearch = os.clock() + 0.15
				target = nearest(root)
			end
		end
		local part = target and target:FindFirstChild('HumanoidRootPart')
		if not part then
			restoreRotate()
			return
		end
		if oldHumanoid ~= humanoid then
			restoreRotate()
			oldHumanoid, oldAutoRotate = humanoid, humanoid.AutoRotate
		end
		humanoid.AutoRotate = false
		local look = part.CFrame.LookVector * Vector3.new(1, 0, 1)
		if look.Magnitude < 0.01 then return end
		local back = part.Position - look.Unit * 2.8
		local position = Vector3.new(back.X, part.Position.Y, back.Z)
		root.CFrame = CFrame.lookAt(position, Vector3.new(part.Position.X, position.Y, part.Position.Z))
		local ent = entitylib.getEntity(target)
		if ent then
			targetinfo.Targets[ent] = tick() + 1
		end
	end

	local function fight()
		local char = lplr.Character
		local root = char and char:FindFirstChild('HumanoidRootPart')
		local humanoid = char and char:FindFirstChildOfClass('Humanoid')
		local part = target and target:FindFirstChild('HumanoidRootPart')
		local best = strongest()
		if not (root and humanoid and humanoid.Health > 0 and util.CanAct() and part and enemy(target) and best) then
			attack(false)
			return
		end
		local equipped, _, kind, tuning, held2 = gameapi.Tool()
		if equipped ~= best then
			attack(false)
			local ok, current = pcall(controller.State)
			if ok and current and not current.equipPending and os.clock() >= nextEquip then
				nextEquip = os.clock() + 0.5
				pcall(controller.Equip, best)
				equippedReadyAt = os.clock() + 0.2
			end
			return
		end
		if not (kind and combat.IsMelee(kind) and tuning) or (held2 and held2.equipPending) or os.clock() < equippedReadyAt then
			attack(false)
			return
		end
		attack((part.Position - root.Position).Magnitude <= (tonumber(tuning.range) or 8) + 0.7)
	end

	local function queue(action, key, token)
		local now = os.clock()
		if queueBusy or now - lastQueueAt < 8 then return end
		if key == lastQueueKey and now - lastQueueAt < 15 then return end
		if state.Get('Queued') == true or lplr:GetAttribute('Teleporting') == true then return end
		queueBusy, lastQueueAt = true, now
		task.spawn(function()
			local ok, transport, accepted = pcall(queueApi.Invoke, 'QueueAction', action)
			queueBusy = false
			if AutoWin.Enabled and generation == token and ok and transport == true and accepted == true then
				lastQueueKey = key
			end
		end)
	end

	local function endMatch(token)
		if not AutoWin.Enabled or generation ~= token then return end
		setFighting(false)
		matchFinished = true
		replayWaitUntil = os.clock() + 12
		if not Requeue.Enabled then return end
		local match = state.Match
		local id = match and match.matchId or state.SeenMatchId()
		task.delay(0.25, function()
			if AutoWin.Enabled and generation == token then
				queue('PlayAgain', 'play:'..tostring(id or 'last'), token)
			end
		end)
	end

	AutoWin = vape.Categories.Utility:CreateModule({
		Name = 'AutoWin',
		Function = function(callback)
			generation += 1
			local token = generation
			matchFinished, replayWaitUntil = false, 0
			if not callback then
				setFighting(false)
				return
			end
			if not (state and queueApi and controller and util and combat) then
				notif('AutoWin', 'Tribes has not finished loading. Reinject in a moment.', 6, 'warning')
				return
			end
			local remotes = replicatedStorage:FindFirstChild('Remotes')
			local matchEvent = remotes and remotes:FindFirstChild('MatchEvent')
			if matchEvent then
				AutoWin:Clean(matchEvent.OnClientEvent:Connect(function(event)
					if event == 'MatchEnd' then
						endMatch(token)
					end
				end))
			end
			AutoWin:Clean(runService.Heartbeat:Connect(follow))

			repeat
				local ok, err = pcall(function()
					local phase = state.PhaseClock()
					local alive = state.IsAlive()
					if phase == 'MatchEnd' then
						if not matchFinished then
							endMatch(token)
						end
						setFighting(false)
					elseif matchFinished then
						setFighting(false)
						if state.InMatch() and phase == 'PreRound' then
							matchFinished = false
						end
					elseif state.InMatch() then
						setFighting(alive and (phase == 'Live' or phase == 'Overtime'))
						if fighting then
							fight()
						end
					else
						setFighting(false)
						if Requeue.Enabled and state.GetPlayerState() == 'Lobby' and state.Get('Queued') ~= true and os.clock() >= replayWaitUntil then
							queue('Queue', 'lobby:'..tostring(state.SeenMatchId()), token)
						end
					end
				end)
				if not ok then
					attack(false)
					warn('[ElevateV4] AutoWin: '..tostring(err))
				end
				task.wait(fighting and 0.04 or 0.2)
			until not AutoWin.Enabled or generation ~= token
			setFighting(false)
		end,
		Tooltip = 'Plays the match for you'
	})
	Requeue = AutoWin:CreateToggle({
		Name = 'Requeue',
		Default = true,
		Tooltip = 'Queues for the next match when one ends'
	})
end)
