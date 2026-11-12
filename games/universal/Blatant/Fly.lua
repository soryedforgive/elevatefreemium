run(function()
	local Value
	local VerticalValue
	local WallCheck
	local PopBalloons
	local TP
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	local up, down, oldDeflate = 0, 0

	local function bedwarsEnv()
		return rawget(getgenv(), 'bedwars')
	end

	local function storeEnv()
		return rawget(getgenv(), 'store')
	end

	local function eventsEnv()
		return rawget(getgenv(), 'vapeEvents')
	end

	local function hasItem(name)
		local currentStore = storeEnv()
		local items = currentStore and currentStore.inventory and currentStore.inventory.inventory and currentStore.inventory.inventory.items
		if type(items) ~= 'table' then return false end
		for _, item in items do
			local itemType = item.itemType or item.Name
			local toolName = item.tool and item.tool.Name or ''
			if itemType == name or tostring(toolName):find(name, 1, true) then
				return true
			end
		end
		return false
	end

	Fly = vape.Categories.Blatant:CreateModule({
		Name = 'Fly',
		Function = function(callback)
			frictionTable.Fly = callback or nil
			updateVelocity()
			if callback then
				up, down = 0, 0
				local bw = bedwarsEnv()
				local balloon = bw and bw.BalloonController
				if balloon then
					oldDeflate = balloon.deflateBalloon
					balloon.deflateBalloon = function() end
					if lplr.Character and (lplr.Character:GetAttribute('InflatedBalloons') or 0) == 0 and hasItem('balloon') then
						pcall(function() balloon:inflateBalloon() end)
					end
					local events = eventsEnv()
					if events and events.AttributeChanged then
						Fly:Clean(events.AttributeChanged.Event:Connect(function(changed)
							if changed == 'InflatedBalloons' and (lplr.Character:GetAttribute('InflatedBalloons') or 0) == 0 and hasItem('balloon') then
								pcall(function() balloon:inflateBalloon() end)
							end
						end))
					end
				end

				local tpTick, tpToggle, oldy = tick(), true
				local lastPosition, engineSpeed, lastPush = nil, 0, 0
				Fly:Clean(runService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive and isnetworkowner(entitylib.character.RootPart) then
						local root = entitylib.character.RootPart
						local moveDirection = entitylib.character.Humanoid.MoveDirection
						local currentStore = storeEnv()
						local balloons = lplr.Character and (lplr.Character:GetAttribute('InflatedBalloons') or 0) or 0
						local flyAllowed = balloons > 0 or (currentStore and currentStore.matchState == 2) or not bw
						local mass = (0.9 + (flyAllowed and 6 or 0) * (tick() % 0.4 < 0.2 and -1 or 1)) + ((up + down) * VerticalValue.Value)
						local speed = Value.Value
						local travelled = lastPosition and (root.Position - lastPosition) or Vector3.zero
						lastPosition = root.Position
						local achieved = math.min(Vector3.new(travelled.X, 0, travelled.Z).Magnitude / math.max(dt, 1e-4), 500)
						engineSpeed = engineSpeed + (math.max(achieved - lastPush, 0) - engineSpeed) * 0.5
						lastPush = 0
						local destination = moveDirection * math.max(speed - engineSpeed, 0) * dt
						rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
						rayCheck.CollisionGroup = root.CollisionGroup

						if WallCheck.Enabled then
							local ray = workspace:Raycast(root.Position, destination, rayCheck)
							if ray then
								destination = ((ray.Position + ray.Normal) - root.Position)
							end
						end

						if not flyAllowed then
							if tpToggle then
								local airleft = tick() - (entitylib.character.AirTime or tick())
								if airleft > 2 then
									if not oldy then
										local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayCheck)
										if ray and TP.Enabled then
											tpToggle = false
											oldy = root.Position.Y
											tpTick = tick() + 0.11
											root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, ray.Position.Y + (entitylib.character.HipHeight or 3), root.Position.Z), root.CFrame.LookVector)
										end
									end
								end
							else
								if oldy then
									if tpTick < tick() then
										root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, oldy, root.Position.Z), root.CFrame.LookVector)
										tpToggle = true
										oldy = nil
									else
										mass = 0
									end
								end
							end
						end

						root.CFrame += destination
						lastPush = destination.Magnitude / math.max(dt, 1e-4)
						local velocity = root.AssemblyLinearVelocity
						local current = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
						local walking = entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air
						local target = walking and math.min(speed, current) or speed
						root.AssemblyLinearVelocity = (moveDirection * target) + Vector3.new(0, mass, 0)
					end
				end))
				Fly:Clean(inputService.InputBegan:Connect(function(input)
					if not inputService:GetFocusedTextBox() then
						if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
							up = 1
						elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
							down = -1
						end
					end
				end))
				Fly:Clean(inputService.InputEnded:Connect(function(input)
					if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
						up = 0
					elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
						down = 0
					end
				end))
				if inputService.TouchEnabled then
					pcall(function()
						local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
						Fly:Clean(jumpButton:GetPropertyChangedSignal('ImageRectOffset'):Connect(function()
							up = jumpButton.ImageRectOffset.X == 146 and 1 or 0
						end))
					end)
				end
			else
				local bw = bedwarsEnv()
				local balloon = bw and bw.BalloonController
				if balloon and oldDeflate then
					balloon.deflateBalloon = oldDeflate
				end
				if PopBalloons.Enabled and entitylib.isAlive and balloon and (lplr.Character:GetAttribute('InflatedBalloons') or 0) > 0 then
					for _ = 1, 3 do
						pcall(function() balloon:deflateBalloon() end)
					end
				end
				oldDeflate = nil
			end
		end,
		ExtraText = function()
			return bedwarsEnv() and 'Heatseeker' or 'Normal'
		end,
		Tooltip = 'Lets you fly'
	})
	Value = Fly:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	VerticalValue = Fly:CreateSlider({
		Name = 'Vertical Speed',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	WallCheck = Fly:CreateToggle({
		Name = 'Wall Check',
		Default = true
	})
	PopBalloons = Fly:CreateToggle({
		Name = 'Pop Balloons',
		Default = true
	})
	TP = Fly:CreateToggle({
		Name = 'TP Down',
		Default = true
	})
	Fly:CreateButton({
		Name = 'Reset to default speeds',
		Tooltip = 'Sets speed back to the game\'s default',
		Function = function()
			Value:SetValue(20)
		end,
	})
end)
