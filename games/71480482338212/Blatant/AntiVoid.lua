run(function()
	local AntiVoid
	local Mode
	local Drop
	local Notify
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	rayCheck.RespectCanCollide = true
	local SPACING, KEEP, SAMPLE = 3, 80, 0.1
	local STEP, SPEED = 12, 300

	local function filter()
		local list = {workspace:FindFirstChild('PlayersContainer') or lplr.Character, gameCamera}
		local fake = workspace:FindFirstChild('FakeBlocksContainer')
		if fake then table.insert(list, fake) end
		rayCheck.FilterDescendantsInstances = list
	end

	local function floorAt(position, depth)
		local hit = workspace:Raycast(position + Vector3.new(0, 1, 0), Vector3.new(0, -(depth + 1), 0), rayCheck)
		if hit and hit.Instance.Transparency < 1 then return hit end
	end

	local function settle(position, height)
		local hit = floorAt(position - Vector3.new(0, height - 1, 0), 3)
		if not hit then return end
		local goal = position
		local part = hit.Instance
		if not part:IsA('Terrain') then
			local half = part.Size / 2
			local at = part.CFrame:PointToObjectSpace(hit.Position)
			local top = part.CFrame:PointToWorldSpace(Vector3.new(
				half.X > 1.5 and math.clamp(at.X, 1.5 - half.X, half.X - 1.5) or 0,
				at.Y,
				half.Z > 1.5 and math.clamp(at.Z, 1.5 - half.Z, half.Z - 1.5) or 0
			))
			goal = Vector3.new(top.X, hit.Position.Y + height, top.Z)
			if not floorAt(goal - Vector3.new(0, height - 1, 0), 3) then return end
		end
		if workspace:Raycast(goal, Vector3.new(0, 3, 0), rayCheck) then return end
		return goal
	end

	AntiVoid = vape.Categories.Blatant:CreateModule({
		Name = 'AntiVoid',
		Function = function(callback)
			if callback then
				local trail, sampled, moving, latest = {}, 0, false, nil
				local tried, told = 0, false
				AntiVoid:Clean(entitylib.Events.LocalAdded:Connect(function()
					table.clear(trail)
					latest = nil
				end))

				local function remember(position)
					local last = trail[#trail]
					if last and (last - position).Magnitude < SPACING then return end
					for i = #trail, 1, -1 do
						if (trail[i] - position).Magnitude < SPACING then
							table.remove(trail, i)
						end
					end
					table.insert(trail, position)
					if #trail > KEEP then table.remove(trail, 1) end
				end

				local function lastFooting(height)
					local spot = latest and settle(latest, height)
					if spot then return spot end
					for i = #trail, math.max(#trail - 15, 1), -1 do
						spot = settle(trail[i], height)
						if spot then return spot end
					end
				end

				local function bringBack(root, spot)
					moving = true
					task.spawn(function()
						local goal = CFrame.new(spot + Vector3.new(0, 0.5, 0)) * root.CFrame.Rotation
						while entitylib.isAlive and AntiVoid.Enabled and root.Parent do
							local gap = goal.Position - root.Position
							local step = SPEED * runService.Heartbeat:Wait()
							root.AssemblyLinearVelocity = Vector3.zero
							if gap.Magnitude <= math.max(step, STEP) then
								root.CFrame = goal
								break
							end
							root.CFrame = CFrame.new(root.Position + gap.Unit * step) * goal.Rotation
						end
						if root.Parent then root.AssemblyLinearVelocity = Vector3.zero end
						moving = false
					end)
				end

				local held
				local function release()
					held = nil
					mergeRoot('AntiVoid')
				end
				AntiVoid:Clean(release)

				local function hitbox(hum, root, height)
					if held then
						if not (store.split and store.split.Owners.AntiVoid) then
							held = nil
							return true
						end
						sendRoot(held)
						if hum.FloorMaterial ~= Enum.Material.Air then
							release()
						elseif held.Position.Y - root.Position.Y > Drop.Value and not workspace:Raycast(root.Position, Vector3.new(0, -400, 0), rayCheck) then
							root.CFrame = held
							root.AssemblyLinearVelocity = Vector3.zero
							release()
							if Notify.Enabled then
								notif('AntiVoid', 'Put you back on your hitbox.', 3)
							end
						end
						return true
					end
					if hum.FloorMaterial ~= Enum.Material.Air or store.flyOn or store.split or not latest then return false end
					if not isnetworkowner(realRoot()) then return false end
					if workspace:Raycast(root.Position, Vector3.new(0, -400, 0), rayCheck) then return false end
					local spot = lastFooting(height)
					if spot and splitRoot('AntiVoid') then
						held = CFrame.new(spot) * root.CFrame.Rotation
						sendRoot(held)
					end
					return true
				end

				AntiVoid:Clean(runService.Heartbeat:Connect(function()
					if moving or not entitylib.isAlive then return end
					local hum, root = entitylib.character.Humanoid, bodyRoot()
					local height = entitylib.character.HipHeight + root.Size.Y / 2
					filter()
					if hum.FloorMaterial ~= Enum.Material.Air then
						if tick() - sampled >= SAMPLE then
							sampled = tick()
							local below = floorAt(root.Position, height + 1.5)
							if below then
								latest = Vector3.new(root.Position.X, below.Position.Y + height, root.Position.Z)
								remember(latest)
							end
						end
						if not held then
							return
						end
					end
					if Mode.Value == 'Hitbox' then
						hitbox(hum, root, height)
						return
					end
					if store.flyOn or store.dashOn or not latest then return end
					if root.AssemblyLinearVelocity.Y > -5 then return end
					if latest.Y - root.Position.Y < Drop.Value then return end
					if not isnetworkowner(realRoot()) then return end
					if workspace:Raycast(root.Position, Vector3.new(0, -400, 0), rayCheck) then return end

					if Mode.Value == 'Block' then
						if tick() - tried < 0.15 then return end
						tried = tick()
						local placed, why = store.catchBlock('AntiVoid', 0.1)
						task.delay(0.3, function()
							if tick() - tried >= 0.3 then
								syncTool('AntiVoid')
							end
						end)
						if placed then
							told = false
							return
						end
						if why ~= 'none' then return end
						if not told and Notify.Enabled then
							told = true
							notif('AntiVoid', 'No blocks left, so you are taken back instead.', 3, 'warning')
						end
					end
					local spot = lastFooting(height)
					if not spot then return end
					bringBack(root, spot)
					if Notify.Enabled then
						notif('AntiVoid', 'Put you back where you last stood.', 3)
					end
				end))
			end
		end,
		Tooltip = 'Prevents you from falling into the void'
	})
	Mode = AntiVoid:CreateDropdown({
		Name = 'Mode',
		List = {'Hitbox', 'Teleport', 'Block'},
		Default = 'Hitbox',
		Tooltip = 'Hitbox - keeps your hitbox on the ground\nTeleport - takes you back to the ground\nBlock - puts a block under you'
	})
	Drop = AntiVoid:CreateSlider({
		Name = 'Fall distance',
		Min = 4,
		Max = 40,
		Default = 10,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How far you fall before it brings you back'
	})
	Notify = AntiVoid:CreateToggle({
		Name = 'Notify',
		Default = true
	})
end)
