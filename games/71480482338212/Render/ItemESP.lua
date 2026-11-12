run(function()
	local ItemESP
	local MaxDistance
	local ShowAmount
	local ShowDistance
	local Resources
	local Reference = {}
	local colors = {
		Emerald = Color3.fromRGB(50, 220, 80),
		Diamond = Color3.fromRGB(60, 200, 220),
		Iron = Color3.new(1, 1, 1)
	}
	local folder = Instance.new('Folder')
	folder.Parent = vape.gui
	vape:Clean(folder)

	local function itemName(drop)
		return drop:GetAttribute('Name') or drop.Name:match('^(.-)_%d+$') or drop.Name
	end

	local function added(drop)
		if Reference[drop] or not drop:IsA('Model') or not ItemESP.Enabled then return end
		local part = drop:FindFirstChild('Hitbox') or drop:FindFirstChildWhichIsA('BasePart')
		if not part then return end
		local name = itemName(drop)
		if Resources.Enabled and not colors[name] then return end
		local billboard = Instance.new('BillboardGui')
		billboard.Adornee = part
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.fromOffset(170, 16)
		billboard.StudsOffset = Vector3.new(0, 2.5, 0)
		billboard.Parent = folder
		local label = Instance.new('TextLabel')
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 12
		label.TextColor3 = colors[name] or Color3.fromRGB(255, 220, 120)
		label.TextStrokeTransparency = 0.4
		label.Parent = billboard
		Reference[drop] = {Billboard = billboard, Label = label, Part = part, Name = name}
	end

	local function removed(drop)
		local ref = Reference[drop]
		if ref then
			Reference[drop] = nil
			ref.Billboard:Destroy()
		end
	end

	ItemESP = vape.Categories.Render:CreateModule({
		Name = 'ItemESP',
		Function = function(callback)
			if callback then
				local container = workspace:FindFirstChild('DroppedItemsContainer')
				if not container then
					notif('ItemESP', 'This server has no dropped item folder yet.', 5, 'warning')
					return
				end
				ItemESP:Clean(container.ChildAdded:Connect(function(drop)
					task.defer(added, drop)
				end))
				ItemESP:Clean(container.ChildRemoved:Connect(removed))
				for _, drop in container:GetChildren() do
					added(drop)
				end

				repeat
					local origin = entitylib.isAlive and entitylib.character.RootPart.Position or gameCamera.CFrame.Position
					for drop, ref in Reference do
						local dist = (ref.Part.Position - origin).Magnitude
						ref.Billboard.Enabled = dist <= MaxDistance.Value
						if ref.Billboard.Enabled then
							local text = ref.Name
							local amount = drop:GetAttribute('Amount')
							if ShowAmount.Enabled and type(amount) == 'number' and amount > 1 then
								text ..= ' x'..amount
							end
							if ShowDistance.Enabled then
								text ..= string.format(' [%d]', dist)
							end
							ref.Label.Text = text
						end
					end
					task.wait(0.2)
				until not ItemESP.Enabled
			else
				for drop in table.clone(Reference) do
					removed(drop)
				end
			end
		end,
		Tooltip = 'Shows dropped items and their count through walls'
	})
	Resources = ItemESP:CreateToggle({
		Name = 'Resources only',
		Function = function()
			if ItemESP.Enabled then
				ItemESP:Toggle()
				ItemESP:Toggle()
			end
		end,
		Tooltip = 'Only iron, diamonds and emeralds'
	})
	MaxDistance = ItemESP:CreateSlider({
		Name = 'Max distance',
		Min = 20,
		Max = 600,
		Default = 150,
		Suffix = 'studs'
	})
	ShowAmount = ItemESP:CreateToggle({
		Name = 'Amount',
		Default = true
	})
	ShowDistance = ItemESP:CreateToggle({
		Name = 'Distance',
		Default = true
	})
end)
