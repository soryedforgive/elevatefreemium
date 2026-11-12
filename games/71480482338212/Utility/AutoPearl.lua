run(function()
	local AutoPearl
	local FallSpeed
	local Search
	local Cooldown
	local nextThrow = 0
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	rayCheck.RespectCanCollide = true
	local DIRECTIONS = {Vector3.xAxis, Vector3.zAxis, -Vector3.xAxis, -Vector3.zAxis, Vector3.new(0.7, 0, 0.7), Vector3.new(-0.7, 0, 0.7), Vector3.new(0.7, 0, -0.7), Vector3.new(-0.7, 0, -0.7)}

	local function filter()
		local list = {workspace:FindFirstChild('PlayersContainer') or lplr.Character, gameCamera}
		for _, name in {'ProjectilesContainer', 'FakeBlocksContainer', 'DroppedItemsContainer'} do
			local folder = workspace:FindFirstChild(name)
			if folder then table.insert(list, folder) end
		end
		rayCheck.FilterDescendantsInstances = list
	end

	local function groundNear(origin)
		for step = 3, Search.Value, 3 do
			for _, direction in DIRECTIONS do
				local hit = workspace:Raycast(origin + direction * step + Vector3.new(0, 3, 0), Vector3.new(0, -80, 0), rayCheck)
				if hit and hit.Instance.Transparency < 1 then
					return hit.Position + Vector3.new(0, 0.5, 0)
				end
			end
		end
	end

	AutoPearl = vape.Categories.Utility:CreateModule({
		Name = 'AutoPearl',
		Function = function(callback)
			if callback then
				local lastGround
				repeat
					if entitylib.isAlive and tick() >= nextThrow and not store.flyOn and (store.inventory.Teleorb or 0) > 0 and store.throwTeleorb then
						local root = bodyRoot()
						filter()
						if entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
							lastGround = root.Position
						elseif store.inVoid(root, 0.7) and root.AssemblyLinearVelocity.Y < -FallSpeed.Value then
							local spot = groundNear(root.Position + Vector3.new(0, 30, 0)) or (lastGround and groundNear(lastGround + Vector3.new(0, 5, 0)))
							if spot and store.throwTeleorb(spot, 'AutoPearl') then
								nextThrow = tick() + Cooldown.Value
							end
						end
					end
					task.wait(0.05)
				until not AutoPearl.Enabled
			end
		end,
		Tooltip = 'Throws a teleorb onto nearby ground when falling into the void'
	})
	FallSpeed = AutoPearl:CreateSlider({
		Name = 'Fall speed',
		Min = 10,
		Max = 150,
		Default = 50,
		Suffix = 'studs a second',
		Tooltip = 'How fast you must be falling before it acts'
	})
	Search = AutoPearl:CreateSlider({
		Name = 'Search range',
		Min = 6,
		Max = 90,
		Default = 45,
		Suffix = function(val) return val == 1 and 'stud' or 'studs' end,
		Tooltip = 'How far it looks for ground to land on'
	})
	Cooldown = AutoPearl:CreateSlider({
		Name = 'Cooldown',
		Min = 0.5,
		Max = 10,
		Default = 2,
		Decimal = 10,
		Suffix = 's'
	})
end)
