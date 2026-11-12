run(function()
    local HighJump
    local Mode
    local Value
    local AutoDisable
    local busy = false
    local nextJump = 0

    local function jump(fromGround)
	if busy or not entitylib.isAlive then return end
	local humanoid, root = entitylib.character.Humanoid, entitylib.character.RootPart
	if fromGround then
		if humanoid.FloorMaterial == Enum.Material.Air or tick() < nextJump then return end
		nextJump = tick() + 0.25
	end

	if Mode.Value == 'Velocity' then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		root.AssemblyLinearVelocity =
			Vector3.new(root.AssemblyLinearVelocity.X, Value.Value, root.AssemblyLinearVelocity.Z)
	elseif Mode.Value == 'Impulse' then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		task.delay(0, function()
			root:ApplyImpulse(Vector3.new(0, Value.Value - root.AssemblyLinearVelocity.Y, 0) * root.AssemblyMass)
		end)
	else
		busy = true
		local start = math.max(Value.Value - humanoid.JumpHeight, 0)
		if workspace.Gravity <= 0 then
			root.CFrame += Vector3.new(0, start, 0)
			start = 0
		end
		repeat
			if not root.Parent then break end
			root.CFrame += Vector3.new(0, start * 0.016, 0)
			start = start - (workspace.Gravity * 0.016)
			if Mode.Value == 'CFrame' then
				task.wait()
			end
		until start <= 0
		busy = false
	end
    end

    HighJump = vape.Categories.Blatant:CreateModule({
	Name = 'HighJump',
	Function = function(callback)
		if callback then
			if AutoDisable.Enabled then
				jump(false)
				HighJump:Toggle()
			else
				HighJump:Clean(runService.RenderStepped:Connect(function()
					if inputService:GetFocusedTextBox() then return end
					local held = inputService:IsKeyDown(Enum.KeyCode.Space) or inputService:IsKeyDown(Enum.KeyCode.ButtonA)
					if not held and inputService.TouchEnabled and entitylib.isAlive then
						held = entitylib.character.Humanoid.Jump
					end
					if held then
						jump(true)
					end
				end))
			end
		end
	end,
	ExtraText = function()
		return Mode.Value
	end,
	Tooltip = 'Lets you jump higher',
    })
    Mode = HighJump:CreateDropdown({
	Name = 'Mode',
	List = { 'Impulse', 'Velocity', 'CFrame', 'Instant' },
	Tooltip = 'How you are moved up',
    })
    Value = HighJump:CreateSlider({
	Name = 'Velocity',
	Min = 1,
	Max = 150,
	Default = 50,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end,
    })
    AutoDisable = HighJump:CreateToggle({
	Name = 'Auto Disable',
	Default = true,
    })
end)
