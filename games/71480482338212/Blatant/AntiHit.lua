run(function()
	local AntiHit
	local Range
	local Height
	local Hits
	local Dodge
	local filtered
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	local UP, DOWN, EARLY = 0.75, 0.13, 0.35
	local MAX_DROP = 18
	local SWING, CLEAR = 14.5, 17.5
	local LEAD, HOLD = 0.18, 0.08
	local STRIKE_UP, STRIKE_REACH = 9, 12.5
	local FLAT = Vector3.new(1, 0, 1)
	local strikeUp, sentHits, landedHits, windowAt = STRIKE_UP, 0, 0, 0

	local idle, lastDraw = 0, 0
	local groundAt, downUntil, standing = 0, 0, false
	local peak, lastSpot, stepped
	local managedAt, gateSince, gateAt = 0, nil, 0
	local reachOf, reachSince
	local struckAt, seenStruck = 0, nil
	local dangers = {}

	local function release()
		if store.antiHit then
			store.antiHit = nil
			mergeRoot('AntiHit')
		end
		reachOf, reachSince, peak, lastSpot, stepped = nil, nil, nil, nil, nil
	end

	local function reach()
		return math.min(store.meleeRange or 14, 14)
	end

	local function cooldown()
		local data = store.tools.sword and bedfight.SwordsData and bedfight.SwordsData[store.tools.sword]
		return type(data) == 'table' and data.DamageCooldown or 0.3
	end

	local function incoming(now)
		for i = #dangers, 1, -1 do
			if dangers[i].To < now then
				table.remove(dangers, i)
			end
		end
		return dangers[1]
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

	AntiHit = vape.Categories.Blatant:CreateModule({
		Name = 'AntiHit',
		Function = function(callback)
			if callback then
				store.strikeGate = function(ent)
					local now = tick()
					if not Hits.Enabled or now - managedAt > 0.1 then return true end
					gateAt = now
					gateSince = gateSince or now
					if now - gateSince > 0.45 then return true end
					if now - struckAt < cooldown() - 0.02 then return false end
					return reachOf == ent and reachSince ~= nil and now - reachSince >= LEAD
				end

				AntiHit:Clean(entitylib.Events.LocalRemoved:Connect(function()
					store.antiHit = nil
					table.clear(dangers)
				end))

				strikeUp, sentHits, landedHits, windowAt = STRIKE_UP, 0, 0, tick()
				if remotes.DamageIndicator then
					AntiHit:Clean(remotes.DamageIndicator.OnClientEvent:Connect(function(victim)
						local target = store.meleeTarget
						if target and victim == target.Character then
							landedHits += 1
						end
					end))
				end

				local remote = replicatedStorage:FindFirstChild('Remotes')
				remote = remote and remote:FindFirstChild('ReplicateProjectile')
				if remote then
					AntiHit:Clean(remote.OnClientEvent:Connect(function(userId, _, name, origin, speed, unit)
						if not Dodge.Enabled or userId == lplr.UserId or not entitylib.isAlive then return end
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
						if ((at - body) * FLAT).Magnitude > blast + 8 then return end
						if #dangers >= 24 then return end
						local now = tick()
						local late = math.min(lplr:GetNetworkPing(), 0.4)
						table.insert(dangers, {From = now, To = now + t + 0.35 + late, Y = at.Y, Need = math.max(5, blast + 3)})
					end))
				end

				AntiHit:Clean(runService.Heartbeat:Connect(function()
					if not entitylib.isAlive or store.flyOn or store.dashOn then
						release()
						return
					end
					local now = tick()
					local danger = incoming(now)
					local threat = canFight() and store.targets({Range = Range.Value, Players = true, NPCs = true, Limit = 1})[1]
					if threat or danger then
						idle = now
					elseif now - idle > 0.6 then
						release()
						return
					end
					if not store.antiHit then
						if not ((threat or danger) and splitRoot('AntiHit')) then return end
						store.antiHit = true
						groundAt, downUntil, standing = now, 0, false
					end
					if store.struckAt ~= seenStruck then
						seenStruck = store.struckAt
						struckAt = now
						gateSince = nil
						sentHits += 1
					elseif gateSince and now - gateAt > 0.15 then
						gateSince = nil
					end
					if now - windowAt >= 1 + lplr:GetNetworkPing() then
						if sentHits >= 3 then
							if landedHits == 0 then
								strikeUp = math.max(strikeUp - 2.5, 0)
							elseif strikeUp < STRIKE_UP then
								strikeUp = math.min(strikeUp + 0.25, STRIKE_UP)
							end
						end
						sentHits, landedHits, windowAt = 0, 0, now
					end

					local fighting = now - (store.melee or 0) < 0.4
					local held = inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and heldName()
					if held then
						if bedfight.RangedData and bedfight.RangedData[held] then
							lastDraw = now
						elseif Hits.Enabled and not fighting and threat and bedfight.SwordsData and bedfight.SwordsData[held] and (threat.RootPart.Position - bodyRoot().Position).Magnitude < SWING + 2 then
							lastDraw = now
						end
					end
					local body = bodyRoot()
					local hip = entitylib.character.HipHeight
					local container = workspace:FindFirstChild('PlayersContainer') or lplr.Character
					if filtered ~= container then
						filtered = container
						rayCheck.FilterDescendantsInstances = {container, gameCamera}
					end
					local under = now - lastDraw >= 0.3 and workspace:Raycast(body.Position, Vector3.new(0, -(MAX_DROP + hip + 2), 0), rayCheck)
					if not under then
						if entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
							groundAt, peak = now, nil
						end
						standing, downUntil = false, 0
						reachOf, reachSince = nil, nil
						return
					end
					local spot = Vector3.new(body.Position.X, under.Position.Y + hip, body.Position.Z)
					store.antiHitAt = now
					managedAt = now

					local stand = spot
					if peak and peak - spot.Y > MAX_DROP + 1.5 then
						if lastSpot and not stepped and ((lastSpot - spot) * FLAT).Magnitude < 12 then
							stand = lastSpot
						end
					else
						lastSpot, stepped = spot, nil
					end

					if standing and now >= downUntil then
						standing = false
						groundAt = now
						peak = stand.Y
						if stand ~= spot then
							stepped = true
							stand = spot
						end
					end

					local top = spot.Y + Height.Value
					local target = Hits.Enabled and fighting and store.meleeTarget or nil
					if target and not (target.RootPart and target.RootPart.Parent) then
						target = nil
					end
					local strikeY, grounded
					if target then
						local far = math.min(reach() - 0.75, STRIKE_REACH)
						local aimed = target.RootPart.Position
						local flat = ((aimed - spot) * FLAT).Magnitude
						strikeY = math.clamp(aimed.Y + math.min(far > flat and math.sqrt(far * far - flat * flat) or 0, strikeUp), spot.Y, top)
						grounded = (aimed - spot).Magnitude <= far
					end
					local due = target and math.max(store.meleeDue or now, struckAt + cooldown()) or nil
					local strike = due and ((due - now <= LEAD and now - due < 0.3) or now - struckAt < HOLD)
					local since = now - groundAt
					local clear = not threat or (threat.RootPart.Position - spot).Magnitude > CLEAR

					local hold = danger and since < 0.85 and room(stand.Y, now) < 0
					local y
					if standing and not hold then
						y = stand.Y
					elseif standing then
						standing, downUntil = false, 0
						y = top
					elseif not hold and (stand ~= spot or since >= UP) then
						standing, downUntil = true, now + DOWN
						y = stand.Y
					elseif since >= EARLY and clear and (not danger or room(stand.Y, now) >= 0) then
						standing, downUntil = true, now + DOWN
						y = stand.Y
					elseif strike then
						y = strikeY
					else
						y = top
					end
					if danger and not standing and room(y, now) < 0 then
						local best, most = y, room(y, now)
						local try = top
						while try >= spot.Y + 3 do
							local space = room(try, now)
							if space > most + 0.5 then
								best, most = try, space
							end
							try -= 3
						end
						y = best
					end
					if standing and strike and grounded and now + HOLD > downUntil then
						downUntil = now + HOLD
					end

					local at = Vector3.new(stand.X, y, stand.Z)
					peak = math.max(peak or y, y)
					if target and (at - target.RootPart.Position).Magnitude <= reach() - 0.25 then
						if reachOf ~= target or not reachSince then
							reachOf, reachSince = target, now
						end
					else
						reachOf, reachSince = nil, nil
					end
					sendRoot(CFrame.new(at) * body.CFrame.Rotation)
				end))
			else
				store.strikeGate = nil
				table.clear(dangers)
				release()
			end
		end,
		Tooltip = 'Lifts your hitbox out of sword reach while enemies are close'
	})
	Range = AntiHit:CreateSlider({
		Name = 'Range',
		Min = 10,
		Max = 40,
		Default = 22,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How close an enemy must be before your hitbox lifts'
	})
	Height = AntiHit:CreateSlider({
		Name = 'Hover height',
		Min = 12,
		Max = 18,
		Default = 17,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How high above the ground your hitbox waits'
	})
	Hits = AntiHit:CreateToggle({
		Name = 'Keep your hits',
		Default = true,
		Tooltip = 'Brings your hitbox into reach as Killaura lands each hit'
	})
	Dodge = AntiHit:CreateToggle({
		Name = 'Dodge projectiles',
		Default = true,
		Tooltip = 'Moves your hitbox out of the way of incoming shots'
	})
end)
