run(function()
	local Speed
	local Mode
	local MoveMethod
	local Value
	local WallCheck
	local TPFrequency
	local PulseLength
	local PulseDelay
	local AutoJump
	local CustomJump
	local JumpPower
	local Intermission
	local state = tribes.UIState
	local nextTeleport = 0
	local initialHumanoid, initialWalkSpeed
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.RespectCanCollide = true
	local PAUSED = {Intro = true, PreRound = true, RoundEnd = true, MatchEnd = true}

	local function restoreWalkSpeed()
		if initialHumanoid and initialHumanoid.Parent and initialWalkSpeed and initialHumanoid.WalkSpeed == Value.Value then
			initialHumanoid.WalkSpeed = initialWalkSpeed
		end
		initialHumanoid, initialWalkSpeed = nil, nil
	end

	local function directMove()
		if inputService:GetFocusedTextBox() then return Vector3.zero end
		local x = (inputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (inputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
		local z = (inputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (inputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
		local look = gameCamera.CFrame.LookVector * Vector3.new(1, 0, 1)
		local right = gameCamera.CFrame.RightVector * Vector3.new(1, 0, 1)
		if look.Magnitude < 0.01 or right.Magnitude < 0.01 then return Vector3.zero end
		local vector = look.Unit * z + right.Unit * x
		return vector.Magnitude > 1 and vector.Unit or vector
	end

	local function moveCFrame(root, hum, direction, dt)
		local offset = direction * math.max(Value.Value - hum.WalkSpeed, 0) * dt
		if offset.Magnitude <= 0.0001 then return end
		if WallCheck.Enabled then
			rayParams.FilterDescendantsInstances = {lplr.Character, gameCamera}
			rayParams.CollisionGroup = root.CollisionGroup
			local hit = workspace:Raycast(root.Position, offset, rayParams)
			if hit then
				local stepTo = hit.Position - root.Position - offset.Unit * 0.4
				if stepTo:Dot(offset) <= 0 then return end
				offset = stepTo
			end
		end
		root.CFrame += offset
	end

	local function setVisible()
		if not (Mode and WallCheck and TPFrequency and PulseLength and PulseDelay) then return end
		local mode = Mode.Value
		WallCheck.Object.Visible = mode == 'CFrame' or mode == 'TP'
		TPFrequency.Object.Visible = mode == 'TP'
		PulseLength.Object.Visible = mode == 'Pulse'
		PulseDelay.Object.Visible = mode == 'Pulse'
	end

	local function update(dt)
		local modules = vape.Modules
		if gameapi.Options.AutoKilling or (modules.PlayerAttach and modules.PlayerAttach.Enabled) or (modules.Fly and modules.Fly.Enabled) or (modules.LongJump and modules.LongJump.Enabled) then return end
		if Intermission.Enabled and state and state.InMatch() then
			local phase = state.Phase() or state.PhaseClock()
			if PAUSED[phase] then
				restoreWalkSpeed()
				return
			end
		end
		if not entitylib.isAlive then return end
		local root, hum = entitylib.character.RootPart, entitylib.character.Humanoid
		local current = hum:GetState()
		if current == Enum.HumanoidStateType.Climbing or current == Enum.HumanoidStateType.Seated then return end

		local direction = (MoveMethod.Value == 'Direct' and directMove() or hum.MoveDirection) * Vector3.new(1, 0, 1)
		if direction.Magnitude > 1 then
			direction = direction.Unit
		end
		local mode = Mode.Value
		local vertical = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
		local targetVelocity = direction * Value.Value
		if mode == 'Velocity' then
			root.AssemblyLinearVelocity = targetVelocity + vertical
		elseif mode == 'Impulse' then
			local difference = (targetVelocity - root.AssemblyLinearVelocity) * Vector3.new(1, 0, 1)
			if difference.Magnitude > (direction == Vector3.zero and 10 or 2) then
				root:ApplyImpulse(difference * root.AssemblyMass)
			end
		elseif mode == 'CFrame' then
			moveCFrame(root, hum, direction, dt)
		elseif mode == 'TP' then
			if os.clock() >= nextTeleport then
				nextTeleport = os.clock() + TPFrequency.Value
				moveCFrame(root, hum, direction, 1)
			end
		elseif mode == 'WalkSpeed' then
			if initialHumanoid ~= hum then
				initialHumanoid, initialWalkSpeed = hum, hum.WalkSpeed
			end
			if hum.WalkSpeed ~= Value.Value then
				hum.WalkSpeed = Value.Value
			end
		elseif mode == 'Pulse' then
			local length = math.max(0.05, PulseLength.Value)
			local phase = (os.clock() % (length + math.max(0, PulseDelay.Value))) / length
			local bonus = math.max(Value.Value - hum.WalkSpeed, 0) * (1 - math.min(phase, 1))
			root.AssemblyLinearVelocity = direction * (hum.WalkSpeed + bonus) + vertical
		end

		if AutoJump.Enabled and direction.Magnitude > 0.05 and hum.FloorMaterial ~= Enum.Material.Air then
			if CustomJump.Enabled then
				local v = root.AssemblyLinearVelocity
				root.AssemblyLinearVelocity = Vector3.new(v.X, JumpPower.Value, v.Z)
			else
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end

	Speed = vape.Categories.Blatant:CreateModule({
		Name = 'Speed',
		Function = function(callback)
			if callback then
				nextTeleport = 0
				Speed:Clean(runService.PreSimulation:Connect(update))
			else
				restoreWalkSpeed()
			end
		end,
		ExtraText = function()
			return Mode.Value
		end,
		Tooltip = 'Increases your movement speed'
	})
	Mode = Speed:CreateDropdown({
		Name = 'Mode',
		List = {'Velocity', 'Impulse', 'CFrame', 'TP', 'WalkSpeed', 'Pulse'},
		Function = function()
			restoreWalkSpeed()
			setVisible()
		end,
		Tooltip = 'How your speed is raised'
	})
	MoveMethod = Speed:CreateDropdown({
		Name = 'Move mode',
		List = {'MoveDirection', 'Direct'},
		Tooltip = 'How your movement direction is read'
	})
	Value = Speed:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	WallCheck = Speed:CreateToggle({
		Name = 'Wall check',
		Default = true,
		Darker = true,
		Visible = false
	})
	TPFrequency = Speed:CreateSlider({
		Name = 'TP frequency',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Default = 0.3,
		Suffix = 's',
		Darker = true,
		Visible = false
	})
	PulseLength = Speed:CreateSlider({
		Name = 'Pulse length',
		Min = 0.05,
		Max = 1,
		Decimal = 100,
		Default = 0.3,
		Suffix = 's',
		Darker = true,
		Visible = false
	})
	PulseDelay = Speed:CreateSlider({
		Name = 'Pulse delay',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Default = 0.3,
		Suffix = 's',
		Darker = true,
		Visible = false
	})
	AutoJump = Speed:CreateGroup({
		Name = 'AutoJump',
		Function = function(callback)
			if CustomJump then
				JumpPower.Object.Visible = callback and CustomJump.Enabled
			end
		end
	})
	CustomJump = AutoJump:CreateToggle({
		Name = 'Custom jump',
		Darker = true,
		Function = function(callback)
			if JumpPower then
				JumpPower.Object.Visible = callback and AutoJump.Enabled
			end
		end
	})
	JumpPower = Speed:CreateSlider({
		Name = 'Jump power',
		Min = 1,
		Max = 50,
		Default = 30,
		Darker = true,
		Visible = false
	})
	Intermission = Speed:CreateToggle({
		Name = 'Intermission',
		Default = true,
		Tooltip = 'Waits for the round to start before speeding you up'
	})
	setVisible()
end)
