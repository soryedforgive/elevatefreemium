run(function()
	local FastClimb
	local restingWalkSpeed, written

	local CLIMB_TO_WALK = 0.7
	local climbingNow, stateConnection = false, nil

	local function watchState(character)
		if stateConnection then stateConnection:Disconnect() stateConnection = nil end
		climbingNow = false
		local humanoid = character and character:FindFirstChildOfClass('Humanoid')
		if not humanoid then return end
		climbingNow = humanoid:GetState() == Enum.HumanoidStateType.Climbing
		stateConnection = humanoid.StateChanged:Connect(function(_, new)
			climbingNow = new == Enum.HumanoidStateType.Climbing
		end)
	end

	local function apply()
		if not climbingNow and not restingWalkSpeed then return end
		local character = lplr.Character
		local humanoid = character and character:FindFirstChildOfClass('Humanoid')
		if not humanoid or humanoid.Health <= 0 then return end

		local climbing = FastClimb.Enabled and humanoid:GetState() == Enum.HumanoidStateType.Climbing
		if climbing then
			if not restingWalkSpeed or (written and math.abs(humanoid.WalkSpeed - written) > 0.05) then
				restingWalkSpeed = humanoid.WalkSpeed
			end
			local want = math.clamp(FastClimb.ClimbSpeed.Value, 1, 100)
			local target = math.clamp(want / CLIMB_TO_WALK, 1, 512)
			if math.abs(humanoid.WalkSpeed - target) > 0.05 then
				humanoid.WalkSpeed = target
			end
			written = target
		elseif restingWalkSpeed then
			local restore = restingWalkSpeed
			restingWalkSpeed, written = nil, nil
			pcall(function()
				humanoid.WalkSpeed = restore
			end)
		end
	end

	FastClimb = vape.Categories.Blatant:CreateModule({
		Name = 'FastClimb',
		Function = function(callback)
			if callback then
				watchState(lplr.Character)
				FastClimb:Clean(runService.PreSimulation:Connect(apply))
				FastClimb:Clean(lplr.CharacterAdded:Connect(function(character)
					restingWalkSpeed, written = nil, nil
					character:WaitForChild('Humanoid', 10)
					if FastClimb.Enabled then watchState(character) end
				end))
				FastClimb:Clean(function()
					if stateConnection then stateConnection:Disconnect() stateConnection = nil end
					climbingNow = false
				end)
				apply()
			else
				local character = lplr.Character
				local humanoid = character and character:FindFirstChildOfClass('Humanoid')
				if humanoid and restingWalkSpeed then
					local restore = restingWalkSpeed
					restingWalkSpeed, written = nil, nil
					pcall(function()
						humanoid.WalkSpeed = restore
					end)
				else
					restingWalkSpeed, written = nil, nil
				end
			end
		end,
		Tooltip = 'Climbs faster'
	})

	FastClimb.ClimbSpeed = FastClimb:CreateSlider({
		Name = 'Climb Speed',
		Min = 1,
		Max = 100,
		Default = 32,
		Suffix = 'studs/s',
		Tooltip = 'How fast you climb',
		Function = function()
			apply()
		end
	})
end)
