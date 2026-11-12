run(function()
	local TNTDetector
	local MaxDistance
	local Color
	local Reference = {}
	local fuses = {
		TNT = 4.3,
		['Mega TNT'] = 5.5,
		['Smoke TNT'] = 1.8,
		Bomb = 3.5
	}
	local folder = Instance.new('Folder')
	folder.Parent = vape.gui
	vape:Clean(folder)

	local function added(obj, kind)
		if Reference[obj] or not TNTDetector.Enabled then return end
		local part = obj:IsA('BasePart') and obj or obj:IsA('Model') and (obj.PrimaryPart or obj:FindFirstChildWhichIsA('BasePart'))
		if not part then return end
		local box = Instance.new('BoxHandleAdornment')
		box.Adornee = part
		box.Size = part.Size + Vector3.new(0.2, 0.2, 0.2)
		box.AlwaysOnTop = true
		box.ZIndex = 0
		box.Transparency = 0.55
		box.Parent = folder
		local billboard = Instance.new('BillboardGui')
		billboard.Adornee = part
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.fromOffset(170, 18)
		billboard.StudsOffset = Vector3.new(0, 3.5, 0)
		billboard.Parent = folder
		local label = Instance.new('TextLabel')
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 13
		label.TextStrokeTransparency = 0.4
		label.Parent = billboard
		Reference[obj] = {Box = box, Billboard = billboard, Label = label, Part = part, Kind = kind, Placed = tick()}
	end

	local function removed(obj)
		local ref = Reference[obj]
		if ref then
			Reference[obj] = nil
			ref.Box:Destroy()
			ref.Billboard:Destroy()
		end
	end

	TNTDetector = vape.Categories.Render:CreateModule({
		Name = 'TNTDetector',
		Function = function(callback)
			if callback then
				local container = workspace:FindFirstChild('PlayersBlocksContainer')
				if not container then
					notif('TNTDetector', 'This server has no placed block folder yet.', 5, 'warning')
					return
				end
				local function watch(kind)
					if not fuses[kind.Name] then return end
					TNTDetector:Clean(kind.ChildAdded:Connect(function(obj)
						added(obj, kind.Name)
					end))
					TNTDetector:Clean(kind.ChildRemoved:Connect(removed))
					for _, obj in kind:GetChildren() do
						added(obj, kind.Name)
					end
				end
				TNTDetector:Clean(container.ChildAdded:Connect(watch))
				for _, kind in container:GetChildren() do
					watch(kind)
				end

				repeat
					local origin = entitylib.isAlive and entitylib.character.RootPart.Position or gameCamera.CFrame.Position
					local color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
					for obj, ref in table.clone(Reference) do
						if not obj.Parent then
							removed(obj)
							continue
						end
						local dist = (ref.Part.Position - origin).Magnitude
						local left = math.max(fuses[ref.Kind] - (tick() - ref.Placed), 0)
						local shown = dist <= MaxDistance.Value
						ref.Box.Visible = shown
						ref.Box.Color3 = color
						ref.Billboard.Enabled = shown
						ref.Label.TextColor3 = Color3.fromHSV(math.clamp(left / fuses[ref.Kind], 0, 1) / 3, 0.9, 1)
						ref.Label.Text = string.format('%s %.1fs [%d]', ref.Kind, left, dist)
					end
					task.wait(0.05)
				until not TNTDetector.Enabled
			else
				for obj in table.clone(Reference) do
					removed(obj)
				end
			end
		end,
		Tooltip = 'Marks placed TNT and bombs with the time left until they go off'
	})
	Color = TNTDetector:CreateColorSlider({
		Name = 'Color',
		DefaultValue = 0
	})
	MaxDistance = TNTDetector:CreateSlider({
		Name = 'Max distance',
		Min = 20,
		Max = 400,
		Default = 200,
		Suffix = 'studs'
	})
end)
