run(function()
	local DropESP
	local MaxDistance
	local ShowDistance
	local Toggles = {}
	local drops = {}
	local labels = {}
	local folder = Instance.new('Folder')
	folder.Parent = vape.gui
	vape:Clean(folder)
	local KINDS = {
		{Name = 'BronzeCoin', Label = 'Bronze', Colour = Color3.fromRGB(205, 127, 50)},
		{Name = 'IronCoin', Label = 'Iron', Colour = Color3.fromRGB(215, 215, 225)},
		{Name = 'GoldCoin', Label = 'Gold', Colour = Color3.fromRGB(255, 210, 40)},
		{Name = 'Shard', Label = 'Shard', Colour = Color3.fromRGB(180, 100, 255)}
	}
	local byName = {}
	for i, kind in KINDS do
		kind.Order = i
		byName[kind.Name] = kind
	end

	local function getLabel(key)
		local ref = labels[key]
		if ref then return ref end
		local anchor = Instance.new('Part')
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.one
		local billboard = Instance.new('BillboardGui')
		billboard.Adornee = anchor
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.fromOffset(200, 16)
		billboard.StudsOffset = Vector3.new(0, 2, 0)
		billboard.Parent = folder
		local label = Instance.new('TextLabel')
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 12
		label.TextStrokeTransparency = 0.4
		label.RichText = true
		label.Parent = billboard
		anchor.Parent = gameCamera
		ref = {Anchor = anchor, Billboard = billboard, Label = label}
		labels[key] = ref
		return ref
	end

	local function clearLabels()
		for _, ref in labels do
			ref.Anchor:Destroy()
			ref.Billboard:Destroy()
		end
		table.clear(labels)
	end

	local function update()
		local origin = entitylib.isAlive and bodyRoot().Position or gameCamera.CFrame.Position
		local piles = {}
		for _, drop in drops do
			local kind = byName[drop.Name]
			local part = kind and Toggles[kind.Name].Enabled and (drop.PrimaryPart or drop:FindFirstChild('Hitbox'))
			if part then
				local position = part.Position
				if (position - origin).Magnitude <= MaxDistance.Value then
					local key = Vector3.new(position.X // 8, position.Y // 8, position.Z // 8)
					local pile = piles[key]
					if not pile then
						pile = {Sum = Vector3.zero, Count = 0, Kinds = {}}
						piles[key] = pile
					end
					pile.Sum += position
					pile.Count += 1
					pile.Kinds[kind] = (pile.Kinds[kind] or 0) + 1
				end
			end
		end

		for key, ref in labels do
			if not piles[key] then
				ref.Anchor:Destroy()
				ref.Billboard:Destroy()
				labels[key] = nil
			end
		end

		for key, pile in piles do
			local ref = getLabel(key)
			local centre = pile.Sum / pile.Count
			if not ref.Position or (ref.Position - centre).Magnitude > 0.5 then
				ref.Position = centre
				ref.Anchor.CFrame = CFrame.new(centre)
			end
			local parts = {}
			for _, kind in KINDS do
				local count = pile.Kinds[kind]
				if count then
					table.insert(parts, string.format('<font color="#%s">%s x%d</font>', kind.Colour:ToHex(), kind.Label, count))
				end
			end
			local text = table.concat(parts, ' ')
			if ShowDistance.Enabled then
				text ..= string.format(' [%d]', (centre - origin).Magnitude)
			end
			if ref.Text ~= text then
				ref.Text = text
				ref.Label.Text = text
			end
		end
	end

	DropESP = vape.Categories.Render:CreateModule({
		Name = 'DropESP',
		Function = function(callback)
			if callback then
				drops = collection('item', DropESP)
				repeat
					update()
					task.wait(0.3)
				until not DropESP.Enabled
			else
				clearLabels()
			end
		end,
		Tooltip = 'Shows coins and shards through walls'
	})
	for _, kind in KINDS do
		Toggles[kind.Name] = DropESP:CreateToggle({
			Name = kind.Label,
			Default = true
		})
	end
	MaxDistance = DropESP:CreateSlider({
		Name = 'Max distance',
		Min = 20,
		Max = 1000,
		Default = 400,
		Suffix = 'studs'
	})
	ShowDistance = DropESP:CreateToggle({
		Name = 'Distance',
		Default = true
	})
end)
