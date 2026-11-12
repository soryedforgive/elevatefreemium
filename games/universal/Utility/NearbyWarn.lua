run(function()
	local NearbyWarn
	local Distance
	local Flash
	local FlashColor
	local Pulse
	local Label
	local ShowDistance
	local frame, label

	NearbyWarn = vape.Categories.Utility:CreateModule({
		Name = 'NearbyWarn',
		Function = function(callback)
			if callback then
				local alpha = 0
				NearbyWarn:Clean(runService.Heartbeat:Connect(function(dt)
					local ent = entitylib.isAlive and entitylib.EntityPosition({
						Range = Distance.Value,
						Part = 'RootPart',
						Players = true
					})
					alpha = ent and math.min(alpha + dt * 6, FlashColor.Opacity) or math.max(alpha - dt * 4, 0)
					local shown = alpha
					if Pulse.Enabled then
						shown *= math.abs(math.sin(tick() * 8))
					end
					frame.BackgroundColor3 = Color3.fromHSV(FlashColor.Hue, FlashColor.Sat, FlashColor.Value)
					frame.BackgroundTransparency = Flash.Enabled and 1 - shown or 1
					label.Visible = ent ~= nil and Label.Enabled
					if ent and Label.Enabled then
						local name = ent.Player and ent.Player.DisplayName or ent.Character.Name
						local dist = (ent.RootPart.Position - entitylib.character.RootPart.Position).Magnitude
						label.Text = ShowDistance.Enabled and string.format('%s is %d studs away', name, dist) or name..' is close'
					end
				end))
			else
				frame.BackgroundTransparency = 1
				label.Visible = false
			end
		end,
		Tooltip = 'Warns you when an enemy comes close'
	})
	Distance = NearbyWarn:CreateSlider({
		Name = 'Distance',
		Min = 5,
		Max = 60,
		Default = 15,
		Suffix = 'studs'
	})
	Flash = NearbyWarn:CreateGroup({
		Name = 'Screen flash',
		Default = true,
		Function = function(callback)
			if FlashColor then
			end
		end
	})
	FlashColor = Flash:CreateColorSlider({
		Name = 'Flash color',
		DefaultValue = 0,
		DefaultOpacity = 0.22,
		Darker = true
	})
	Pulse = Flash:CreateToggle({
		Name = 'Pulse',
		Default = true,
		Darker = true
	})
	Label = NearbyWarn:CreateGroup({
		Name = 'Show label',
		Default = true,
	})
	ShowDistance = Label:CreateToggle({
		Name = 'Show distance',
		Default = true,
		Darker = true
	})

	frame = Instance.new('Frame')
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Active = false
	frame.ZIndex = -5
	frame.Parent = vape.gui
	label = Instance.new('TextLabel')
	label.Size = UDim2.fromOffset(280, 30)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 72)
	label.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
	label.BackgroundTransparency = 0.2
	label.TextColor3 = Color3.fromRGB(255, 90, 90)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.Visible = false
	label.Parent = vape.gui
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label
	vape:Clean(frame)
	vape:Clean(label)
end)
