run(function()
	local Fly
	local Value
	local Vertical
	local AirTime
	local Extend
	local GroundCheck
	local ShowUI
	local gui, bar, label
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true

	local function setBar(fraction, text)
		if not gui then return end
		gui.Visible = ShowUI.Enabled
		bar.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		label.Text = text
	end

	Fly = vape.Categories.Blatant:CreateModule({
		Name = 'Fly',
		Function = function(callback)
			store.flyOn = callback or nil
			if callback then
				local air, phase, returnY, landY = 0, 'fly', 0, 0

				Fly:Clean(runService.PreSimulation:Connect(function(dt)
					if not entitylib.isAlive then return end
					local hum, root = entitylib.character.Humanoid, entitylib.character.RootPart
					rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
					local ground = workspace:Raycast(root.Position, Vector3.new(0, -500, 0), rayCheck)
					local height = entitylib.character.HipHeight
					local grounded = ground and ground.Distance <= height + 0.4

					local vertical = 0
					if not inputService:GetFocusedTextBox() then
						vertical = (inputService:IsKeyDown(Enum.KeyCode.Space) and Vertical.Value or 0) - (inputService:IsKeyDown(Enum.KeyCode.LeftShift) and Vertical.Value or 0)
					end

					if phase == 'down' then
						air += dt
						if air >= 0.15 or not ground then
							root.CFrame += Vector3.new(0, returnY - root.Position.Y, 0)
							phase, air = 'fly', 0
						else
							root.CFrame += Vector3.new(0, landY - root.Position.Y, 0)
							vertical = 0
						end
					else
						air = grounded and 0 or air + dt
						if air >= math.min(AirTime.Value, 0.9) then
							if Extend.Enabled and ground and ground.Distance - height <= 15 then
								phase, air, returnY, landY = 'down', 0, root.Position.Y, ground.Position.Y + height
							elseif air >= 0.9 and GroundCheck.Enabled then
								notif('Fly', 'No ground close enough to touch, landing before the server pulls you back.', 4)
								Fly:Toggle()
								return
							end
						end
					end

					local move = hum.MoveDirection * Value.Value
					root.AssemblyLinearVelocity = Vector3.new(move.X, vertical + workspace.Gravity * dt / 2, move.Z)
					local limit = Extend.Enabled and math.min(AirTime.Value, 0.9) or 0.9
					setBar(phase == 'down' and 0 or 1 - air / limit, string.format('%.1fs', phase == 'down' and 0 or math.max(limit - air, 0)))
				end))
			elseif gui then
				gui.Visible = false
			end
		end,
		Tooltip = 'Lets you fly'
	})
	Value = Fly:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 30,
		Default = 24,
		Suffix = 'studs',
		Tooltip = 'How fast you move'
	})
	Vertical = Fly:CreateSlider({
		Name = 'Vertical speed',
		Min = 1,
		Max = 30,
		Default = 24,
		Suffix = 'studs'
	})
	AirTime = Fly:CreateSlider({
		Name = 'Air time',
		Min = 0.5,
		Max = 0.9,
		Default = 0.8,
		Decimal = 10,
		Suffix = 's',
		Tooltip = 'How long you stay up between ground touches'
	})
	Extend = Fly:CreateToggle({
		Name = 'Touch ground',
		Default = true,
		Tooltip = 'Touches the ground briefly so you can keep flying'
	})
	GroundCheck = Fly:CreateToggle({
		Name = 'Disable without ground',
		Default = true,
		Tooltip = 'Turns Fly off when there is no ground close enough to touch'
	})
	ShowUI = Fly:CreateToggle({
		Name = 'Show UI',
		Default = true
	})

	gui = Instance.new('Frame')
	gui.Size = UDim2.fromOffset(220, 12)
	gui.Position = UDim2.new(0.5, -110, 0.72, 0)
	gui.BackgroundColor3 = Color3.new()
	gui.BackgroundTransparency = 0.5
	gui.BorderSizePixel = 0
	gui.Visible = false
	gui.Parent = vape.gui
	bar = Instance.new('Frame')
	bar.Size = UDim2.fromScale(1, 1)
	bar.BackgroundColor3 = Color3.fromRGB(211, 120, 255)
	bar.BorderSizePixel = 0
	bar.Parent = gui
	label = Instance.new('TextLabel')
	label.Size = UDim2.new(1, 0, 0, 16)
	label.Position = UDim2.fromOffset(0, -18)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Text = ''
	label.Parent = gui
	for _, v in {gui, bar} do
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = v
	end
	vape:Clean(gui)
end)
