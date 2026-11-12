run(function()
	local Glide
	local FallSpeed
	local HoldSpace
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	local filterFor

	local function jumpHeight(humanoid)
		if humanoid.UseJumpPower then
			return humanoid.JumpPower ^ 2 / (2 * math.max(workspace.Gravity, 1))
		end
		return humanoid.JumpHeight
	end

	Glide = vape.Categories.Blatant:CreateModule({
		Name = 'Glide',
		Function = function(callback)
			if callback then
				Glide:Clean(runService.PreSimulation:Connect(function()
					if not entitylib.isAlive then return end
					local humanoid, root = entitylib.character.Humanoid, entitylib.character.RootPart
					if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then return end
					if HoldSpace.Enabled and not (inputService:IsKeyDown(Enum.KeyCode.Space) or inputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA) or humanoid.Jump) then return end
					local velocity = root.AssemblyLinearVelocity
					if velocity.Y >= -FallSpeed.Value then return end
					if filterFor ~= lplr.Character then
						filterFor = lplr.Character
						rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
					end
					rayCheck.CollisionGroup = root.CollisionGroup
					local clearance = humanoid.HipHeight + root.Size.Y / 2 + jumpHeight(humanoid) + 1
					if workspace:Raycast(root.Position, Vector3.new(0, -clearance, 0), rayCheck) then return end
					root.AssemblyLinearVelocity = Vector3.new(velocity.X, -FallSpeed.Value, velocity.Z)
				end))
			end
		end,
		Tooltip = 'Slows your fall when the ground is far below'
	})
	FallSpeed = Glide:CreateSlider({
		Name = 'Fall speed',
		Min = 0,
		Max = 50,
		Default = 8,
		Suffix = function(val)
			return val == 1 and 'stud/s' or 'studs/s'
		end
	})
	HoldSpace = Glide:CreateToggle({
		Name = 'Only when holding Space',
		Default = true
	})
end)
