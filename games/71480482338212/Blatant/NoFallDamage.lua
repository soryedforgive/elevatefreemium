run(function()
	local NoFallDamage
	local Trigger
	local Lethal
	local Notify
	local FREE = 18
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	rayCheck.RespectCanCollide = true

	NoFallDamage = vape.Categories.Blatant:CreateModule({
		Name = 'NoFallDamage',
		Function = function(callback)
			if not callback then return end
			local peak, tried, told = nil, 0, false
			NoFallDamage:Clean(runService.Heartbeat:Connect(function()
				if not entitylib.isAlive or store.flyOn or store.dashOn or store.split then
					peak = nil
					return
				end
				local hum, root = entitylib.character.Humanoid, entitylib.character.RootPart
				local y = root.Position.Y
				if hum.FloorMaterial ~= Enum.Material.Air then
					peak = y
					return
				end
				peak = math.max(peak or y, y)
				local fallen = peak - y
				if fallen < Trigger.Value or root.AssemblyLinearVelocity.Y > -10 or tick() - tried < 0.15 then return end
				rayCheck.FilterDescendantsInstances = {workspace:FindFirstChild('PlayersContainer') or lplr.Character, gameCamera}
				local hit = workspace:Raycast(root.Position, Vector3.new(0, -400, 0), rayCheck)
				if not hit then return end
				local height = entitylib.character.HipHeight + root.Size.Y / 2
				local drop = peak - (hit.Position.Y + height)
				if drop <= FREE then return end
				if Lethal.Enabled and (drop - 20) * 2 < entitylib.character.Humanoid.Health then return end
				if root.Position.Y - height - hit.Position.Y < 1.5 then return end
				tried = tick()
				local placed, why = store.catchBlock('NoFallDamage')
				if placed then
					told = false
				elseif why == 'none' and not told and Notify.Enabled then
					told = true
					notif('NoFallDamage', 'You have no blocks to land on.', 3, 'warning')
				end
				task.delay(0.3, function()
					if tick() - tried >= 0.3 then
						syncTool('NoFallDamage')
					end
				end)
			end))
		end,
		Tooltip = 'Prevents fall damage by placing a block under you'
	})
	Trigger = NoFallDamage:CreateSlider({
		Name = 'Catch after',
		Min = 4,
		Max = 16,
		Default = 12,
		Suffix = 'studs',
		Tooltip = 'How far you fall before a block is placed under you'
	})
	Lethal = NoFallDamage:CreateToggle({
		Name = 'Only lethal falls',
		Tooltip = 'Only catches a fall that would kill you'
	})
	Notify = NoFallDamage:CreateToggle({
		Name = 'Notify',
		Default = true
	})
end)
