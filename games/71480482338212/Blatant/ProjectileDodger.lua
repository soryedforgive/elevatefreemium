run(function()
	local ProjectileDodger
	local Range
	local Strength
	local EdgeCheck
	local dodgeUntil, dodgeDirection = 0, Vector3.zero
	local FLAT = Vector3.new(1, 0, 1)
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	rayCheck.RespectCanCollide = true

	local function hasGround(position)
		if not EdgeCheck.Enabled then return true end
		rayCheck.FilterDescendantsInstances = {workspace:FindFirstChild('PlayersContainer') or lplr.Character, gameCamera}
		local hit = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), rayCheck)
		return hit ~= nil and hit.Instance.Transparency < 1
	end

	local function safeSide(root, direction)
		local side = direction:Cross(Vector3.yAxis) * FLAT
		side = side.Magnitude > 0.01 and side.Unit or root.CFrame.RightVector
		if hasGround(root.Position + side * 6) then return side end
		if hasGround(root.Position - side * 6) then return -side end
	end

	ProjectileDodger = vape.Categories.Blatant:CreateModule({
		Name = 'ProjectileDodger',
		Function = function(callback)
			if callback then
				local remote = replicatedStorage:FindFirstChild('Remotes')
				remote = remote and remote:FindFirstChild('ReplicateProjectile')
				if remote then
					ProjectileDodger:Clean(remote.OnClientEvent:Connect(function(userId, _, name, origin, speed, unit)
						if userId == lplr.UserId or not entitylib.isAlive or store.antiHit or store.flyOn then return end
						if typeof(origin) ~= 'Vector3' or typeof(unit) ~= 'Vector3' or type(speed) ~= 'number' then return end
						local data = bedfight.ProjectilesData and bedfight.ProjectilesData[name]
						if type(data) ~= 'table' or name == 'Teleorb' then return end
						local shooter = playersService:GetPlayerByUserId(userId)
						if shooter and lplr.Team and shooter.Team == lplr.Team and lplr.Team.Name ~= 'Spectators' then return end
						local root = bodyRoot()
						if (origin - root.Position).Magnitude > Range.Value + 120 then return end
						local velocity = unit * speed
						local across = velocity * FLAT
						if across.Magnitude < 1 then return end
						local t = ((root.Position - origin) * FLAT):Dot(across) / across.Magnitude ^ 2
						if t <= 0 or t > math.min(data.LifeTime or 5, 3) then return end
						local gravity = typeof(data.Gravity) == 'Vector3' and data.Gravity or Vector3.zero
						local at = origin + velocity * t + gravity * (t * t / 2)
						if (at - root.Position).Magnitude > (data.BlastRadius or 0) + 6 then return end
						local side = safeSide(root, velocity.Unit)
						if side then
							dodgeDirection = side
							dodgeUntil = os.clock() + math.clamp(t + 0.15, 0.25, 0.6)
						end
					end))
				end

				ProjectileDodger:Clean(runService.PostSimulation:Connect(function(dt)
					if os.clock() >= dodgeUntil or not entitylib.isAlive or store.antiHit or store.flyOn then return end
					local root = bodyRoot()
					local movement = dodgeDirection * Strength.Value * dt
					if not hasGround(root.Position + movement * 4) then
						dodgeUntil = 0
						return
					end
					root.CFrame += movement
				end))
			else
				dodgeUntil, dodgeDirection = 0, Vector3.zero
			end
		end,
		Tooltip = 'Dodges incoming projectiles without stepping off edges'
	})
	Range = ProjectileDodger:CreateSlider({
		Name = 'Range',
		Min = 10,
		Max = 80,
		Default = 45,
		Suffix = ' studs'
	})
	Strength = ProjectileDodger:CreateSlider({
		Name = 'Dodge Strength',
		Min = 10,
		Max = 30,
		Default = 24,
		Suffix = ' studs a second',
		Tooltip = 'How fast you step aside'
	})
	EdgeCheck = ProjectileDodger:CreateToggle({
		Name = 'Edge Check',
		Default = true
	})
end)
