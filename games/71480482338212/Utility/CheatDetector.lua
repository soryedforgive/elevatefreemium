run(function()
	local CheatDetector
	local SelfTest
	local toggles = {}
	local CheatersFlagged = {}
	local httpService = cloneref(game:GetService('HttpService'))

	local SAMPLE_STEP = 0.05
	local HISTORY_TIME = 3
	local FLAG_SCORE = 70
	local SCORE_DECAY = 1
	local REASON_LIFE = 25
	local REASON_COOLDOWN = 5
	local LIVE_DELAY = 5
	local SPAWN_GRACE = 3
	local TEAM_GRACE = 4
	local HIT_GRACE = 1.5

	local SPEED_LIMIT = 28
	local SPEED_TIME = 1
	local SPEED_SPAN = 0.6
	local MAX_VERTICAL_SPEED = 25
	local FLY_HEIGHT = 9
	local FLY_TIME = 1.6
	local FLY_VERTICAL = 2
	local TELEPORT_DISTANCE = 14
	local DASH_DISTANCE = 30
	local MAX_GAP = 0.6
	local BOUNCE_MIN = 8
	local BOUNCE_FLAT = 6
	local BOUNCE_PAIR = 1.5
	local BOUNCE_WINDOW = 6
	local UNDER_MAP_DROP = 25
	local UNDER_MAP_WINDOW = 2
	local ORB_WINDOW = 12.5
	local ORB_AFTER = 2.5

	local SPEED_KITS = {hacker = true, rhino = true, smasher = true, specter = true, booster = true}
	local FLY_KITS = {booster = true, ninja = true}

	local tips = {
		Speed = 'Flags players moving faster than the game allows',
		Fly = 'Flags players floating in the air',
		AntiDeaths = 'Flags players teleporting, including out of a fall into the void',
		Hitbox = 'Flags players whose hitbox bounces up and down to dodge hits'
	}

	local history = {}
	local meta = {}
	local score = {}
	local flagged = {}
	local airTime = {}
	local speedTime = {}
	local antiTracks = {}
	local bounce = {}
	local orb = {}
	local shots = {}
	local liveSince = 0

	local function resetPlayer(plr)
		history[plr] = nil
		meta[plr] = nil
		score[plr] = nil
		airTime[plr] = nil
		speedTime[plr] = nil
		antiTracks[plr] = nil
		bounce[plr] = nil
		orb[plr.UserId] = nil
	end

	local function resetAll()
		table.clear(history)
		table.clear(meta)
		table.clear(score)
		table.clear(flagged)
		table.clear(airTime)
		table.clear(speedTime)
		table.clear(antiTracks)
		table.clear(bounce)
		table.clear(orb)
		table.clear(shots)
	end

	local function isOn(name)
		local t = toggles[name]
		return t and t.Enabled
	end

	local function whitelisted(plr)
		local ok, targetable = pcall(function()
			return select(2, whitelist:get(plr))
		end)
		return ok and targetable == false
	end

	local function ignored(plr)
		if not plr or not plr.Parent then return true end
		if plr == lplr and not (SelfTest and SelfTest.Enabled) then return true end
		if CheatersFlagged[plr] then return true end
		if isFriend(plr) then return true end
		if whitelisted(plr) then return true end
		return false
	end

	local function getEntities()
		if SelfTest and SelfTest.Enabled and entitylib.character then
			local list = table.clone(entitylib.List)
			table.insert(list, entitylib.character)
			return list
		end
		return entitylib.List
	end

	local function kitOf(plr)
		local value = plr:FindFirstChild('Kit')
		local name = value and value.Value
		if type(name) ~= 'string' then return '' end
		return (name:lower():gsub('_%d+$', ''))
	end

	local function matchLive()
		local info = bedfight.GameInfo
		local status = info and info:FindFirstChild('Status')
		return status ~= nil and status.Value == 'Started' and os.clock() - liveSince >= LIVE_DELAY
	end

	local function persist(plr, reason)
		pcall(function()
			if isfolder and not isfolder('ElevateV4') then makefolder('ElevateV4') end
			local path = 'ElevateV4/exploiters.json'
			local decoded = {}
			if isfile and isfile(path) then
				local body = select(2, pcall(readfile, path))
				local parsed = body and select(2, pcall(httpService.JSONDecode, httpService, body))
				if type(parsed) == 'table' then decoded = parsed end
			end
			table.insert(decoded, {name = plr.Name, userId = plr.UserId, reason = reason, at = os.time()})
			pcall(writefile, path, httpService:JSONEncode(decoded))
		end)
	end

	local function flagPlayer(plr, reasons)
		local key = tostring(plr)
		local now = os.clock()
		if flagged[key] and now < flagged[key] then return end
		flagged[key] = now + 20

		CheatersFlagged[plr] = true
		pcall(function()
			whitelist.customtags[plr.Name] = {{text = 'CHEATER', color = Color3.fromRGB(235, 60, 60)}}
		end)
		persist(plr, reasons)
		notif('CheatDetector', (plr.DisplayName or plr.Name)..' is probably cheating: '..reasons, 12, 'alert')
	end

	local function addScore(plr, amount, reason, label, cooldown)
		if not plr or ignored(plr) then return end
		local now = os.clock()
		local s = score[plr]
		if not s then
			s = {value = 0, seen = {}, labels = {}}
			score[plr] = s
		end
		if s.seen[reason] and now - s.seen[reason] < (cooldown or REASON_COOLDOWN) then return end
		s.seen[reason] = now
		s.labels[reason] = label
		s.value = s.value + amount
		if s.value >= FLAG_SCORE then
			local list = {}
			for r in s.labels do
				list[#list + 1] = s.labels[r]
			end
			table.sort(list)
			flagPlayer(plr, table.concat(list, ' + '))
			s.value = 0
			table.clear(s.seen)
			table.clear(s.labels)
		end
	end

	local function pushSample(plr, ent)
		local root = ent.RootPart
		if not root then return end
		local h = history[plr]
		if not h then
			h = {}
			history[plr] = h
		end
		local cf = root.CFrame
		local last = h[#h]
		if last and (cf.Position - last.pos).Magnitude < 0.01 then return end
		local now = os.clock()
		h[#h + 1] = {t = now, pos = cf.Position, vel = root.AssemblyLinearVelocity}
		while h[3] and now - h[1].t > HISTORY_TIME do
			table.remove(h, 1)
		end
	end

	local function trackMeta(plr, ent)
		local now = os.clock()
		local m = meta[plr]
		if not m then
			m = {spawn = now, lastDamaged = 0, char = ent.Character, team = plr.Team}
			meta[plr] = m
		end
		if m.char ~= ent.Character then
			m.char = ent.Character
			m.spawn = now
			history[plr] = nil
			airTime[plr] = nil
			speedTime[plr] = nil
			antiTracks[plr] = nil
			bounce[plr] = nil
		end
		if m.team ~= plr.Team then
			m.team = plr.Team
			m.grace = now + TEAM_GRACE
			history[plr] = nil
		end
		return m
	end

	local function getHumanoid(ent)
		if ent.Humanoid then return ent.Humanoid end
		return ent.Character and ent.Character:FindFirstChildOfClass('Humanoid')
	end

	local function settled(plr, ent)
		if not matchLive() then return false end
		local char, root = ent.Character, ent.RootPart
		if not char or not root or not char.Parent or not root.Parent then return false end
		local m = meta[plr]
		if not m then return false end
		local now = os.clock()
		if now - m.spawn < SPAWN_GRACE or now < (m.grace or 0) then return false end
		if now < (orb[plr.UserId] or 0) then return false end
		if plr.Team and plr.Team.Name == 'Spectators' then return false end
		if plr:GetAttribute('PVP') ~= true then return false end
		if char:GetAttribute('Forcefield') == true then return false end
		local hum = getHumanoid(ent)
		if not hum or hum.Health <= 0 then return false end
		local balloons = plr:FindFirstChild('BalloonsAmount')
		if balloons and balloons.Value > 0 then return false end
		if now - m.lastDamaged < HIT_GRACE then return false end
		if lplr:GetNetworkPing() > 0.4 then return false end
		return true
	end

	local function checkFly(plr, ent, dt, rayParams)
		if not isOn('Fly') or FLY_KITS[kitOf(plr)] then
			airTime[plr] = 0
			return
		end
		local root = ent.RootPart
		local ignore = {ent.Character, gameCamera}
		if lplr.Character then table.insert(ignore, lplr.Character) end
		rayParams.FilterDescendantsInstances = ignore
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -250, 0), rayParams)
		local groundDist = hit and (root.Position.Y - hit.Position.Y) or 250
		local vertical = root.AssemblyLinearVelocity.Y
		if groundDist > FLY_HEIGHT and math.abs(vertical) < FLY_VERTICAL then
			airTime[plr] = (airTime[plr] or 0) + dt
			if airTime[plr] >= FLY_TIME then
				airTime[plr] = 0
				addScore(plr, 50, 'fly', 'floating '..math.floor(groundDist)..' studs off the ground')
			end
		else
			airTime[plr] = 0
		end
	end

	local function checkSpeed(plr, ent, dt)
		if not isOn('Speed') or SPEED_KITS[kitOf(plr)] then
			speedTime[plr] = 0
			return
		end
		local h = history[plr]
		if not h or #h < 6 then
			speedTime[plr] = 0
			return
		end
		local now = os.clock()
		local newest, oldest, prev
		local maxStep = 0
		for i = #h, 1, -1 do
			local s = h[i]
			if now - s.t > 1 then break end
			if not newest then newest = s end
			if prev then
				local step = ((prev.pos - s.pos) * Vector3.new(1, 0, 1)).Magnitude
				if step > maxStep then maxStep = step end
			end
			prev = s
			oldest = s
		end
		if not newest or not oldest or now - newest.t > 0.3 then
			speedTime[plr] = 0
			return
		end
		local span = newest.t - oldest.t
		if span < SPEED_SPAN or maxStep > 8 or math.abs(newest.vel.Y) > MAX_VERTICAL_SPEED then
			speedTime[plr] = 0
			return
		end
		local speed = ((newest.pos - oldest.pos) * Vector3.new(1, 0, 1)).Magnitude / span
		if speed > SPEED_LIMIT then
			speedTime[plr] = (speedTime[plr] or 0) + dt
			if speedTime[plr] >= SPEED_TIME then
				speedTime[plr] = 0
				addScore(plr, 45, 'speed', 'moving at '..math.floor(speed)..' studs a second')
			end
		else
			speedTime[plr] = 0
		end
	end

	local function checkJump(plr, ent)
		local h = history[plr]
		if not h or #h < 2 then return end
		local latest, previous = h[#h], h[#h - 1]
		if latest.done then return end
		latest.done = true
		local dt = latest.t - previous.t
		if dt <= 0 then return end
		local rest = previous.vel.Magnitude < 2
		if dt > MAX_GAP and not rest then return end
		if not settled(plr, ent) then return end
		local kit = kitOf(plr)
		local delta = latest.pos - previous.pos
		local unexplained = delta - previous.vel * math.min(dt, MAX_GAP)
		local size = unexplained.Magnitude
		local flat = Vector3.new(unexplained.X, 0, unexplained.Z).Magnitude
		local vertical = unexplained.Y
		if math.abs(vertical) >= BOUNCE_MIN and flat < BOUNCE_FLAT and isOn('Hitbox') then
			if SPEED_KITS[kit] then return end
			local b = bounce[plr]
			if not b then
				b = {last = nil, pairs = {}}
				bounce[plr] = b
			end
			local sign = vertical > 0 and 1 or -1
			if b.last and b.last.sign ~= sign and latest.t - b.last.t <= BOUNCE_PAIR then
				table.insert(b.pairs, latest.t)
				b.last = nil
			else
				b.last = {t = latest.t, sign = sign}
			end
			while b.pairs[1] and latest.t - b.pairs[1] > BOUNCE_WINDOW do
				table.remove(b.pairs, 1)
			end
			if #b.pairs >= 2 then
				table.clear(b.pairs)
				addScore(plr, 70, 'hitbox', 'hitbox bouncing '..math.floor(math.abs(vertical))..' studs up and down')
			end
			return
		end
		if not isOn('AntiDeaths') or size < (SPEED_KITS[kit] and DASH_DISTANCE or TELEPORT_DISTANCE) + (dt > MAX_GAP and 8 or 0) then return end
		addScore(plr, 40, 'teleport', 'teleporting '..math.floor(size)..' studs at once', 3)
		if delta.Y <= -UNDER_MAP_DROP then
			antiTracks[plr] = {time = latest.t, depth = -delta.Y}
		elseif delta.Y >= UNDER_MAP_DROP then
			local under = antiTracks[plr]
			if under and latest.t - under.time <= UNDER_MAP_WINDOW then
				addScore(plr, 45, 'undermap', 'dropped '..math.floor(under.depth)..' studs and came straight back')
				antiTracks[plr] = nil
			end
		end
	end

	local function decayScores(dt)
		local now = os.clock()
		for plr, s in score do
			s.value = math.max(0, s.value - SCORE_DECAY * dt)
			for reason, t in s.seen do
				if now - t > REASON_LIFE then
					s.seen[reason] = nil
					s.labels[reason] = nil
				end
			end
			if s.value <= 0 and not next(s.seen) then
				score[plr] = nil
			end
		end
	end

	CheatDetector = vape.Categories.Utility:CreateModule({
		Name = 'CheatDetector',
		Tooltip = 'Flags possible cheaters',
		Function = function(callback)
			if callback then
				resetAll()
				liveSince = 0

				local info = bedfight.GameInfo
				local status = info and info:FindFirstChild('Status')
				if status then
					CheatDetector:Clean(status:GetPropertyChangedSignal('Value'):Connect(function()
						liveSince = os.clock()
						resetAll()
					end))
				end

				CheatDetector:Clean(playersService.PlayerRemoving:Connect(function(plr)
					resetPlayer(plr)
					flagged[tostring(plr)] = nil
				end))

				if remotes.DamageIndicator then
					CheatDetector:Clean(remotes.DamageIndicator.OnClientEvent:Connect(function(victim)
						local plr = typeof(victim) == 'Instance' and playersService:GetPlayerFromCharacter(victim)
						local m = plr and meta[plr]
						if m then m.lastDamaged = os.clock() end
					end))
				end

				if remotes.ReplicateProjectile then
					CheatDetector:Clean(remotes.ReplicateProjectile.OnClientEvent:Connect(function(userId, key, name)
						if type(name) == 'string' and (name:lower():find('orb', 1, true) or name:lower():find('pearl', 1, true)) and type(userId) == 'number' then
							shots[key] = userId
							orb[userId] = os.clock() + ORB_WINDOW
						end
					end))
				end

				if remotes.DestroyProjectile then
					CheatDetector:Clean(remotes.DestroyProjectile.OnClientEvent:Connect(function(key)
						local userId = shots[key]
						if userId then
							shots[key] = nil
							orb[userId] = os.clock() + ORB_AFTER
						end
					end))
				end

				CheatDetector:Clean(task.spawn(function()
					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					rayParams.RespectCanCollide = true
					local last = os.clock()
					local decayAccum = 0
					repeat
						local now = os.clock()
						local dt = now - last
						last = now
						decayAccum = decayAccum + dt

						for _, ent in getEntities() do
							local plr = ent.Player
							if plr and not ignored(plr) and ent.RootPart and ent.Character then
								trackMeta(plr, ent)
								pushSample(plr, ent)
								if settled(plr, ent) then
									checkFly(plr, ent, dt, rayParams)
									checkSpeed(plr, ent, dt)
								else
									airTime[plr] = 0
									speedTime[plr] = 0
								end
								checkJump(plr, ent)
							end
						end

						if decayAccum >= 1 then
							decayScores(decayAccum)
							decayAccum = 0
						end

						task.wait(SAMPLE_STEP)
					until not CheatDetector.Enabled
					resetAll()
				end))
			else
				resetAll()
			end
		end
	})

	SelfTest = CheatDetector:CreateToggle({
		Name = 'Self',
		Default = false,
		Tooltip = 'Test on yourself'
	})

	for _, name in {'Speed', 'Fly', 'AntiDeaths', 'Hitbox'} do
		toggles[name] = CheatDetector:CreateToggle({
			Name = name,
			Default = true,
			Tooltip = tips[name]
		})
	end
end)
