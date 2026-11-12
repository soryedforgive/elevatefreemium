run(function()
	local NoSlide
	local Limit
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	rayCheck.RespectCanCollide = true
	local character

	local function gripOf(hit)
		local part = hit.Instance
		local custom = part:IsA('BasePart') and part.CustomPhysicalProperties
		if custom then return custom.Friction end
		return PhysicalProperties.new(hit.Material).Friction
	end

	NoSlide = vape.Categories.Blatant:CreateModule({
		Name = 'NoSlide',
		Function = function(callback)
			if callback then
				NoSlide:Clean(runService.PreSimulation:Connect(function()
					if not entitylib.isAlive then return end
					local humanoid = entitylib.character.Humanoid
					if humanoid.FloorMaterial == Enum.Material.Air or humanoid.Sit or humanoid.PlatformStand then return end
					local root = entitylib.character.RootPart
					if character ~= lplr.Character then
						character = lplr.Character
						rayCheck.FilterDescendantsInstances = {character, gameCamera}
					end
					local hit = workspace:Raycast(root.Position, Vector3.new(0, -(entitylib.character.HipHeight + root.Size.Y / 2 + 2), 0), rayCheck)
					if not (hit and gripOf(hit) < Limit.Value) then return end
					local floor = hit.Instance:IsA('BasePart') and hit.Instance:GetVelocityAtPosition(hit.Position) or Vector3.zero
					local want = humanoid.MoveDirection * humanoid.WalkSpeed + floor
					local now = root.AssemblyLinearVelocity
					if now.X ~= want.X or now.Z ~= want.Z then
						root.AssemblyLinearVelocity = Vector3.new(want.X, now.Y, want.Z)
					end
				end))
			end
		end,
		Tooltip = 'Stops you sliding on slippery floors like ice'
	})
	Limit = NoSlide:CreateSlider({
		Name = 'Slippery below',
		Min = 0.05,
		Max = 0.5,
		Default = 0.15,
		Decimal = 100,
		Tooltip = 'Floors with less grip than this count as slippery'
	})
end)
