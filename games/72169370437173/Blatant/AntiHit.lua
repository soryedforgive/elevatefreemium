run(function()
	local AntiHit
	local Melee
	local Range
	local Height
	local Dodge
	local DodgeHeight
	local MaxAir
	local KeepHits
	local shots = {}
	local airSince, restUntil = nil, 0
	local SAFE = 8.3
	local REST = 0.2

	local function pathAt(shot, t)
		return shot.Origin + shot.Velocity * t - Vector3.new(0, 0.5 * shot.Gravity * t * t, 0)
	end

	local function closest(shot, pos)
		local best, at = math.huge, nil
		for i = 0, 40 do
			local t = i * 0.05
			local d = (pathAt(shot, t) - pos).Magnitude
			if d < best then
				best, at = d, t
			end
		end
		return best, at
	end

	AntiHit = vape.Categories.Blatant:CreateModule({
		Name = 'AntiHit',
		Function = function(callback)
			if callback then
				AntiHit:Clean(vapeEvents.EnemyShot.Event:Connect(function(shooter, origin, velocity, gravity)
					if not (Dodge.Enabled and entitylib.isAlive and isEnemy(shooter)) then return end
					table.insert(shots, {Origin = origin, Velocity = velocity, Gravity = gravity, Born = tick() - lplr:GetNetworkPing()})
				end))
				AntiHit:Clean(runService.Heartbeat:Connect(function()
					if not (entitylib.isAlive and inMatch() and canAct()) or store.outranked('AntiHit') then
						store.release('AntiHit')
						airSince = nil
						return
					end
					local now = tick()
					local pos = store.body()
					local goal

					if Melee.Enabled then
						for _, ent in entitylib.List do
							if ent.Targetable and ent.Health > 0 then
								local delta = ent.RootPart.Position - pos
								if Vector3.new(delta.X, 0, delta.Z).Magnitude <= Range.Value and store.heldClass(ent.Character) == 'Melee' then
									goal = math.max(goal or -math.huge, ent.RootPart.Position.Y + math.max(Height.Value, SAFE))
								end
							end
						end
					end

					for i = #shots, 1, -1 do
						local shot = shots[i]
						local age = now - shot.Born
						if age > 2 then
							table.remove(shots, i)
						else
							local dist, at = closest(shot, pos)
							if dist < 4 and at and at - age < 0.35 and at - age > -0.1 then
								goal = math.max(goal or -math.huge, pathAt(shot, at).Y + DodgeHeight.Value)
							end
						end
					end

					if goal and KeepHits.Enabled and store.strikeAt and now >= store.strikeAt - 0.08 and now <= store.strikeAt + 0.1 then
						goal = nil
					end

					if goal and MaxAir.Value > 0 then
						airSince = airSince or now
						if now < restUntil then
							goal = nil
						elseif now - airSince > MaxAir.Value then
							restUntil, airSince = now + REST, nil
							goal = nil
						end
					elseif not goal then
						airSince = nil
					end

					if goal and goal > pos.Y - 0.5 then
						store.lift('AntiHit', goal)
					else
						store.release('AntiHit')
					end
				end))
			else
				store.release('AntiHit')
				table.clear(shots)
				airSince = nil
			end
		end,
		Tooltip = 'Moves your hitbox out of reach of enemy weapons and shots'
	})
	Melee = AntiHit:CreateToggle({
		Name = 'Melee',
		Default = true,
		Tooltip = 'Raises your hitbox above close enemies with melee weapons'
	})
	Range = AntiHit:CreateSlider({
		Name = 'Range',
		Min = 4,
		Max = 25,
		Default = 14,
		Suffix = 'studs',
		Tooltip = 'How close an enemy must be before your hitbox lifts'
	})
	Height = AntiHit:CreateSlider({
		Name = 'Height',
		Min = 8.3,
		Max = 14,
		Default = 9,
		Decimal = 10,
		Suffix = 'studs',
		Tooltip = 'How far above the target you stay'
	})
	Dodge = AntiHit:CreateToggle({
		Name = 'Dodge projectiles',
		Default = true,
		Tooltip = 'Moves your hitbox out of the way of incoming shots'
	})
	DodgeHeight = AntiHit:CreateSlider({
		Name = 'Dodge height',
		Min = 3,
		Max = 10,
		Default = 5,
		Suffix = 'studs',
		Tooltip = 'How far above a passing shot you rise'
	})
	KeepHits = AntiHit:CreateToggle({
		Name = 'Keep your hits',
		Default = true,
		Tooltip = 'Brings your hitbox into reach as Killaura lands each hit'
	})
	MaxAir = AntiHit:CreateSlider({
		Name = 'Max air time',
		Min = 0,
		Max = 5,
		Default = 0,
		Decimal = 10,
		Suffix = 's',
		Tooltip = 'How long to stay up before coming down, 0 to stay up'
	})
end)
