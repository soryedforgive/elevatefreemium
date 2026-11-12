run(function()
	local ChestESP
	local Colour
	local MaxDistance
	local ShowDistance
	local Reference = {}
	local folder = Instance.new('Folder')
	folder.Parent = vape.gui
	vape:Clean(folder)

	local function added(chest)
		if Reference[chest] then return end
		local part = chest:IsA('BasePart') and chest or chest:IsA('Model') and (chest.PrimaryPart or chest:FindFirstChildWhichIsA('BasePart'))
		if not part then return end
		local colour = Color3.fromHSV(Colour.Hue, Colour.Sat, Colour.Value)
		local box = Instance.new('BoxHandleAdornment')
		box.Adornee = part
		box.AlwaysOnTop = true
		box.ZIndex = 0
		box.Size = (chest:IsA('Model') and chest:GetExtentsSize() or part.Size) + Vector3.new(0.1, 0.1, 0.1)
		box.Color3 = colour
		box.Transparency = 1 - Colour.Opacity
		box.Parent = folder
		local billboard = Instance.new('BillboardGui')
		billboard.Adornee = part
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.fromOffset(120, 16)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.Parent = folder
		local label = Instance.new('TextLabel')
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 12
		label.TextColor3 = colour
		label.TextStrokeTransparency = 0.4
		label.Text = 'Chest'
		label.Parent = billboard
		Reference[chest] = {Box = box, Billboard = billboard, Label = label, Part = part}
	end

	local function removed(chest)
		local ref = Reference[chest]
		if ref then
			Reference[chest] = nil
			ref.Box:Destroy()
			ref.Billboard:Destroy()
		end
	end

	ChestESP = vape.Categories.Render:CreateModule({
		Name = 'ChestESP',
		Function = function(callback)
			if callback then
				collection('block:chest', ChestESP, function(objs, chest)
					table.insert(objs, chest)
					added(chest)
				end, function(objs, chest)
					local index = table.find(objs, chest)
					if index then
						table.remove(objs, index)
					end
					removed(chest)
				end)

				repeat
					local origin = entitylib.isAlive and bodyRoot().Position or gameCamera.CFrame.Position
					for _, ref in Reference do
						local dist = (ref.Part.Position - origin).Magnitude
						local shown = dist <= MaxDistance.Value
						if ref.Shown ~= shown then
							ref.Shown = shown
							ref.Box.Visible = shown
							ref.Billboard.Enabled = shown
						end
						if shown then
							local text = ShowDistance.Enabled and string.format('Chest [%d]', dist) or 'Chest'
							if ref.Text ~= text then
								ref.Text = text
								ref.Label.Text = text
							end
						end
					end
					task.wait(0.25)
				until not ChestESP.Enabled
			else
				for chest in table.clone(Reference) do
					removed(chest)
				end
			end
		end,
		Tooltip = 'Shows chests through walls'
	})
	Colour = ChestESP:CreateColorSlider({
		Name = 'Colour',
		DefaultHue = 0.1,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			local colour = Color3.fromHSV(hue, sat, val)
			for _, ref in Reference do
				ref.Box.Color3 = colour
				ref.Box.Transparency = 1 - (opacity or 0.5)
				ref.Label.TextColor3 = colour
			end
		end
	})
	MaxDistance = ChestESP:CreateSlider({
		Name = 'Max distance',
		Min = 20,
		Max = 1000,
		Default = 400,
		Suffix = 'studs'
	})
	ShowDistance = ChestESP:CreateToggle({
		Name = 'Distance',
		Default = true
	})
end)
