run(function()
	local InfiniteFly
	local Value
	local Vertical
	local Notify
	local state
	local landing = false
	local active = false
	local lastHop = 0
	local strict = false
	local logged = false
	local LOG = 'ElevateV4/profiles/infiniteflylog.txt'
	local filtered
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	local WALK = 22
	local HOP, HOP_SPEED, REST = 100, 450, 2
	local SAFE = HOP - 4
	local STROLL = 0.5
	local FREE_DROP = 18
	local STEP_UP = 4
	local SIDES = {Vector3.zero, Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1)}

	local function tell(text, kind)
		if Notify.Enabled then
			notif('InfiniteFly', text, 6, kind)
		end
	end

	local function log(text)
		if not (writefile and appendfile and isfile and readfile) then return end
		pcall(function()
			local line = os.date('%H:%M:%S ') .. text .. '\n'
			if not logged then
				logged = true
				if not (isfile(LOG) and #readfile(LOG) < 30000) then
					writefile(LOG, line)
					return
				end
			end
			appendfile(LOG, line)
		end)
	end

	local function aim()
		local container = workspace:FindFirstChild('PlayersContainer') or lplr.Character
		if filtered ~= container then
			filtered = container
			rayCheck.FilterDescendantsInstances = {container, gameCamera}
		end
	end

	local function floor(position, depth)
		return workspace:Raycast(position, Vector3.new(0, -depth, 0), rayCheck)
	end

	local function walkable(st, point, height)
		local feet = (height or st.Root.Position.Y) - st.Hip
		local hit = floor(Vector3.new(point.X, feet + STEP_UP, point.Z), STEP_UP + FREE_DROP)
		if not hit or hit.Instance.Transparency >= 1 then return nil end
		return hit.Position.Y + st.Hip
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

	local function landable(st, point, top)
		local from = st.Root.Position
		local depth = top - (from.Y - st.Hip - FREE_DROP) + 1
		local y
		for i, side in SIDES do
			local hit = below(Vector3.new(point.X, top, point.Z) + side, depth)
			if not hit then return nil, nil, i == 1 and 'none' or 'edge' end
			if i == 1 then
				y = hit.Position.Y
			elseif math.abs(hit.Position.Y - y) > 3 then
				return nil, nil, 'edge'
			end
		end
		local spot = Vector3.new(point.X, y + st.Hip, point.Z)
		local near = (spot - from).Magnitude <= HOP + 0.5
		return spot, near, not near and 'far' or nil
	end

	local function touchdown(st, position)
		local from = st.Root.Position
		local line = (from - position) * Vector3.new(1, 0, 1)
		local length = line.Magnitude
		local top = math.max(position.Y, from.Y) + 6
		local why
		for back = 0, length, 3 do
			local spot, near, reason = landable(st, back > 0 and position + line.Unit * back or position, back == 0 and position.Y or top)
			if spot and near then
				return spot, back, why
			end
			why = why or reason
		end
		return from, length, why
	end

	local function owned(st, now)
		if not isnetworkowner(realRoot()) then
			st.HeldAt = st.HeldAt or now
			st.Leg = nil
			return false
		elseif st.HeldAt then
			st.HeldAt = nil
			st.Root = CFrame.new(realRoot().Position) * st.Root.Rotation
			st.Still = now
			st.Pulls = (st.Pulls or 0) + 1
			tell('The server moved your hitbox back. It carries on from there.', 'warning')
		end
		return true
	end

	local function park(st)
		local now = tick()
		if owned(st, now) then
			st.Still = st.Still or now
			st.Blocked = nil
		end
	end


	local function due(st, length)
		local stand = strict and REST or REST - math.max(HOP - length, 0) / st.Rate
		return math.max(st.Still + stand, lastHop + REST)
	end

	local function leap(st, to, final, now)
		local from = st.Root.Position
		local length = (to - from).Magnitude
		st.Leg = {From = from, To = to, Time = math.max(length, 25) / HOP_SPEED, Alpha = 0, Final = final}
		st.Early = now - st.Still < REST
		st.Jumps = (st.Jumps or 0) + 1
		st.Note ..= string.format(', jump %d studs %.2fs after landing, stood %.2fs', length, now - st.Landed, now - st.Still)
		lastHop = now + st.Leg.Time
	end

	local function landSafe(st)
		landing = true
		st.Landing = true
		aim()
		local body = bodyRoot()
		local now = tick()
		local goal, back, why = touchdown(st, body.Position)
		if back > 2 then
			local home = (goal - st.Root.Position).Magnitude < 0.5
			local reason = 'There is no firm ground under you'
			if why == 'far' then
				reason = 'That spot is more than one jump from your hitbox'
			elseif why == 'none' then
				local deep = below(body.Position, 700)
				if deep then
					reason = string.format('The ground there is %d studs below your hitbox and the server counts more than 18 as a fall', st.Root.Position.Y - st.Hip - deep.Position.Y)
				end
			end
			tell(reason .. (home and ', so you are back where your hitbox stands.' or string.format(', so you landed %d studs back.', back)), 'warning')
		end
		st.Still = st.Still or now
		st.Landed = now
		st.Jumps, st.Early = nil, nil
		st.Note = string.format('flight %.2fs, hitbox %d studs off%s', now - st.Took, (goal - st.Root.Position).Magnitude, back > 2 and string.format(', landed %d back (%s)', back, tostring(why)) or '')
		body.CFrame = CFrame.new(goal) * body.CFrame.Rotation
		body.AssemblyLinearVelocity = Vector3.zero

		local done, outcome, air = false, nil, nil
		local function release()
			outcome, done = 'again', true
		end
		st.Release = release
		local conn
		conn = runService.Heartbeat:Connect(function(dt)
			if done then return end
			if not (entitylib.isAlive and store.split) then
				outcome, done = 'gone', true
				return
			end
			local now = tick()
			store.antiHitAt = now
			if not owned(st, now) then
				outcome, done = 'pulled', true
				return
			end
			local target = bodyRoot().Position
			local grounded = entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air
			air = not grounded and (air or now) or nil
			local leg = st.Leg
			if leg then
				if leg.Final and grounded and (target - leg.From).Magnitude <= HOP + 0.5 then
					leg.To = target
				end
				leg.Alpha = math.min(leg.Alpha + dt / leg.Time, 1)
				st.Root = CFrame.new(leg.From:Lerp(leg.To, leg.Alpha)) * st.Root.Rotation
				if leg.Alpha >= 1 then
					st.Leg = nil
					st.Still = now
				end
			else
				local from = st.Root.Position
				local offset = target - from
				local length = offset.Magnitude
				local flat = offset * Vector3.new(1, 0, 1)
				local distance = flat.Magnitude
				if length < 1.5 then
					outcome, done = 'joined', true
					return
				end
				local y
				if distance > 0.05 and distance <= WALK * STROLL then
					aim()
					local point = from + flat.Unit * math.min(WALK * dt, distance)
					y = walkable(st, point)
					if y then
						st.Root = CFrame.new(point.X, y, point.Z) * st.Root.Rotation
						st.Still = now
					end
				end
				if y or not grounded then
					if air and now - air > 1.5 then
						outcome, done = 'fell', true
						return
					end
				elseif length <= HOP + 0.5 then
					if now >= due(st, length) then
						leap(st, target, true, now)
					end
				elseif now >= due(st, HOP) and distance > 1 then
					aim()
					local top = math.max(from.Y, target.Y) + 6
					for reach = HOP - 4, 20, -8 do
						local spot, near = landable(st, from + flat.Unit * reach, top)
						if spot and near then
							leap(st, spot, false, now)
							break
						end
					end
					if not st.Leg then
						outcome, done = 'stuck', true
						return
					end
				end
				if now - st.Landed > 15 then
					outcome, done = 'late', true
					return
				end
			end
			sendRoot(st.Root)
		end)
		repeat task.wait() until done
		conn:Disconnect()
		if st.Release == release then
			st.Release = nil
		end
		if outcome == 'again' then
			log('took off again: ' .. st.Note)
			return
		end

		local early = st.Early
		if store.split and entitylib.isAlive and outcome ~= 'joined' then
			local real = realRoot()
			local clone = bodyRoot()
			clone.CFrame = isnetworkowner(real) and st.Root or real.CFrame
			clone.AssemblyLinearVelocity = Vector3.zero
			if outcome == 'fell' then
				tell('You fell before your hitbox got to you, so you are back where it stands.', 'warning')
			elseif outcome == 'pulled' then
				tell(st.Jumps and 'The server refused the jump, so you are back where your hitbox stood. It lets go of you after about four seconds.' or 'The server took your hitbox, so you are back where it stands. It lets go of you after about four seconds.', 'warning')
			else
				tell('Your hitbox could not get to you, so you are back where it stands.', 'warning')
			end
		end
		mergeRoot('InfiniteFly')
		store.flyOn = nil
		active = false
		landing = false
		state = nil

		if outcome == 'joined' and st.Jumps then
			local stop = tick() + 1.2
			repeat
				task.wait()
				if state or not entitylib.isAlive then break end
				if not isnetworkowner(entitylib.character.RootPart) then
					outcome = 'pulled after joining'
					tell('The server refused the jump and put you back. It lets go of you after about four seconds.', 'warning')
					break
				end
			until tick() > stop
		end
		if early and not strict and (outcome == 'pulled' or outcome == 'pulled after joining') then
			strict = true
			tell('Landings now wait until the hitbox has stood for two seconds, for the rest of this session.')
		end
		log(string.format('%s: %s%s, rate %d, ping %dms%s', outcome, st.Note, early and ' (early)' or '', st.Rate, lplr:GetNetworkPing() * 1000, strict and ', strict' or ''))
	end

	InfiniteFly = vape.Categories.Blatant:CreateModule({
		Name = 'InfiniteFly',
		Function = function(callback)
			if callback then
				local st = state
				if landing and st and st.Release and store.split and entitylib.isAlive then
					st.Release()
					landing = false
					st.Landing = nil
					if st.Leg then
						st.Leg.Final = nil
					end
				else
					if landing or not entitylib.isAlive or store.flyOn or store.dashOn then
						task.defer(function()
							if InfiniteFly.Enabled then
								InfiniteFly:Toggle()
							end
						end)
						return
					end
					aim()
					local body = bodyRoot()
					local hip = entitylib.character.HipHeight
					local under = floor(body.Position, FREE_DROP + hip + 2)
					local pace = (body.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
					local real = under and splitRoot('InfiniteFly')
					if not real then
						tell(under and 'Could not take off right now.' or 'Take off from the ground, or from less than 18 studs above it.', 'warning')
						task.defer(function()
							if InfiniteFly.Enabled then
								InfiniteFly:Toggle()
							end
						end)
						return
					end

					local speed = vape.Modules.Speed
					local option = speed and speed.Enabled and speed.Options and speed.Options.Speed
					st = {
						Root = CFrame.new(body.Position.X, under.Position.Y + hip, body.Position.Z) * body.CFrame.Rotation,
						Hip = hip,
						Still = tick(),
						Took = tick(),
						Rate = math.clamp(math.max(pace, option and option.Value or 0), WALK, 60)
					}
				end
				state = st
				store.flyOn = true
				active = true
				InfiniteFly:Clean(runService.PreSimulation:Connect(function(dt)
					if not (entitylib.isAlive and store.split) then
						if state == st then
							state = nil
						end
						InfiniteFly:Toggle()
						return
					end
					store.antiHitAt = tick()
					local hum, clone = entitylib.character.Humanoid, bodyRoot()
					if not st.Leg then
						park(st)
					end
					sendRoot(st.Root)

					local vertical = 0
					if not inputService:GetFocusedTextBox() then
						vertical = (inputService:IsKeyDown(Enum.KeyCode.Space) and Vertical.Value or 0) - (inputService:IsKeyDown(Enum.KeyCode.LeftShift) and Vertical.Value or 0)
					end
					local move = hum.MoveDirection * Value.Value
					local ahead = (clone.Position - st.Root.Position) * Vector3.new(1, 0, 1)
					local gone = ahead.Magnitude
					if gone > 0.1 then
						local out = ahead.Unit
						local along = move:Dot(out)
						local now = tick()
						if now - (st.Looked or 0) > 0.1 then
							st.Looked = now
							aim()
							local spot = landable(st, clone.Position, clone.Position.Y)
							st.Level = spot and spot.Y - st.Root.Position.Y or nil
						end
						local level = st.Level or 0
						local room = math.sqrt(math.max(SAFE * SAFE - level * level, 0)) - gone
						local pace = math.max(room, 0) * 4
						if room < 3 and along > pace then
							st.Capped = now
							st.CappedSince = st.CappedSince or now
							if not st.LimitTold and now - st.CappedSince > 1.5 then
								st.LimitTold = true
								tell(string.format('You can fly up to %d studs from where you took off, so the landing is instant.', SAFE))
							end
						else
							st.CappedSince = nil
						end
						if along > pace then
							move -= out * (along - pace)
						end
					end
					clone.AssemblyLinearVelocity = Vector3.new(move.X, vertical + workspace.Gravity * dt / 2, move.Z)
				end))
			else
				local st = state
				if st and not st.Landing and store.split and entitylib.isAlive then
					task.spawn(landSafe, st)
				elseif active and not landing then
					mergeRoot('InfiniteFly')
					store.flyOn = nil
					active = false
					state = nil
				end
			end
		end,
		ExtraText = function()
			local st = state
			if not (st and store.split and entitylib.isAlive) then return '' end
			local behind = ((bodyRoot().Position - st.Root.Position) * Vector3.new(1, 0, 1)).Magnitude
			if st.Landing then
				return 'landing'
			end
			if st.Capped and tick() - st.Capped < 0.3 then
				return string.format('%d out, limit', behind)
			end
			return string.format(st.Looked and not st.Level and '%d out, no landing' or '%d out', behind)
		end,
		Tooltip = 'Flies freely and lands you safely when switched off'
	})
	Value = InfiniteFly:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 150,
		Default = 40,
		Suffix = 'studs',
		Tooltip = 'How fast you fly'
	})
	Vertical = InfiniteFly:CreateSlider({
		Name = 'Vertical speed',
		Min = 1,
		Max = 150,
		Default = 40,
		Suffix = 'studs'
	})
	Notify = InfiniteFly:CreateToggle({
		Name = 'Notify',
		Default = true,
		Tooltip = 'Tells you when something goes wrong'
	})
end)
