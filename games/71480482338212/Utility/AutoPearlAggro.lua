run(function()
	local AutoPearlAggro
	local MaxDistance
	local MinHealth
	local Cooldown
	local nextThrow = 0
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	rayCheck.RespectCanCollide = true

	local function filter()
		local list = {workspace:FindFirstChild('PlayersContainer') or lplr.Character, gameCamera}
		for _, name in {'ProjectilesContainer', 'FakeBlocksContainer', 'DroppedItemsContainer'} do
			local folder = workspace:FindFirstChild(name)
			if folder then table.insert(list, folder) end
		end
		rayCheck.FilterDescendantsInstances = list
	end

	local function landing(origin, velocity, gravity, life)
		local previous = origin
		for t = 0.05, life, 0.05 do
			local point = origin + velocity * t + gravity * (t * t / 2)
			local hit = workspace:Raycast(previous, point - previous, rayCheck)
			if hit then
				return hit.Instance.Transparency < 1 and hit.Position or nil
			end
			if point.Y < -500 then return nil end
			previous = point
		end
	end

	local function healthy()
		local hum = entitylib.isAlive and entitylib.character.Humanoid
		return hum and hum.MaxHealth > 0 and hum.Health / hum.MaxHealth * 100 >= MinHealth.Value
	end

	AutoPearlAggro = vape.Categories.Utility:CreateModule({
		Name = 'AutoPearlAggro',
		Function = function(callback)
			if not callback then return end
			local remote = replicatedStorage:FindFirstChild('Remotes')
			remote = remote and remote:FindFirstChild('ReplicateProjectile')
			if not remote then
				notif('AutoPearlAggro', 'The projectile event was not found.', 5, 'warning')
				return
			end
			AutoPearlAggro:Clean(remote.OnClientEvent:Connect(function(userId, _, name, origin, speed, unit)
				if name ~= 'Teleorb' or userId == lplr.UserId or tick() < nextThrow then return end
				if typeof(origin) ~= 'Vector3' or typeof(unit) ~= 'Vector3' or type(speed) ~= 'number' then return end
				if not (canFight() and healthy() and store.throwTeleorb) or (store.inventory.Teleorb or 0) <= 0 then return end
				local shooter = playersService:GetPlayerByUserId(userId)
				if shooter and lplr.Team and shooter.Team == lplr.Team and lplr.Team.Name ~= 'Spectators' then return end
				local data = bedfight.ProjectilesData and bedfight.ProjectilesData.Teleorb
				local gravity = data and typeof(data.Gravity) == 'Vector3' and data.Gravity or Vector3.new(0, -100, 0)
				filter()
				local spot = landing(origin, unit * speed, gravity, math.min(data and data.LifeTime or 10, 10))
				if not spot then return end
				local mine = bodyRoot().Position
				if (spot - mine).Magnitude > MaxDistance.Value or (spot - mine).Magnitude < (origin - mine).Magnitude then return end
				if store.throwTeleorb(spot + Vector3.new(0, 1, 0), 'AutoPearlAggro') then
					nextThrow = tick() + Cooldown.Value
				end
			end))
		end,
		Tooltip = 'Throws your teleorb to where an enemy\'s will land'
	})
	MaxDistance = AutoPearlAggro:CreateSlider({
		Name = 'Max distance',
		Min = 10,
		Max = 200,
		Default = 120,
		Suffix = function(val) return val == 1 and 'stud' or 'studs' end,
		Tooltip = 'How far away an enemy orb can land and still be followed'
	})
	MinHealth = AutoPearlAggro:CreateSlider({
		Name = 'Min health',
		Min = 0,
		Max = 100,
		Default = 30,
		Suffix = '%',
		Tooltip = 'Does not follow below this health'
	})
	Cooldown = AutoPearlAggro:CreateSlider({
		Name = 'Cooldown',
		Min = 0.5,
		Max = 15,
		Default = 3,
		Decimal = 10,
		Suffix = 's'
	})
end)
