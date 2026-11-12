run(function()
	local EggESP
	local Own
	local Dead
	local ShowHealth
	local ShowDistance
	local Fill
	local Reference = {}
	local folder = Instance.new('Folder')
	folder.Parent = vape.gui
	vape:Clean(folder)

	local function teamColour(team)
		local controller = skywars.TeamController
		if controller and team then
			local ok, result = pcall(controller.getTeamColour, controller, team)
			if ok and typeof(result) == 'Color3' then return result end
		end
		return Color3.new(1, 1, 1)
	end

	local function refresh(egg)
		local ref = Reference[egg]
		if not ref then return end
		local team = egg:GetAttribute('TeamId')
		local health = egg:GetAttribute('Health') or 0
		local shown = (Own.Enabled or team ~= lplr:GetAttribute('TeamId')) and (Dead.Enabled or health > 0)
		ref.Box.Visible = shown
		ref.Billboard.Enabled = shown
		ref.Shown = shown
		local colour = teamColour(team)
		if ref.Colour ~= colour then
			ref.Colour = colour
			ref.Box.Color3 = colour
			ref.Label.TextColor3 = colour
		end
		ref.Team = team
		ref.Health = health
		ref.Text = nil
	end

	local function added(egg)
		if Reference[egg] or not egg:IsA('Model') then return end
		local part = egg.PrimaryPart or egg:FindFirstChildWhichIsA('BasePart')
		if not part then return end
		local box = Instance.new('BoxHandleAdornment')
		box.Adornee = part
		box.AlwaysOnTop = true
		box.ZIndex = 0
		local centre, size = egg:GetBoundingBox()
		box.Size = size + Vector3.new(0.2, 0.2, 0.2)
		box.CFrame = part.CFrame:ToObjectSpace(centre)
		box.Transparency = Fill.Value
		box.Parent = folder
		local billboard = Instance.new('BillboardGui')
		billboard.Adornee = part
		billboard.AlwaysOnTop = true
		billboard.Size = UDim2.fromOffset(180, 18)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.Parent = folder
		local label = Instance.new('TextLabel')
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 13
		label.TextStrokeTransparency = 0.4
		label.Parent = billboard
		local ref = {Box = box, Billboard = billboard, Label = label, Part = part, Connections = {}}
		Reference[egg] = ref
		for _, name in {'Health', 'TeamId'} do
			table.insert(ref.Connections, egg:GetAttributeChangedSignal(name):Connect(function()
				refresh(egg)
			end))
		end
		refresh(egg)
	end

	local function removed(egg)
		local ref = Reference[egg]
		if ref then
			Reference[egg] = nil
			for _, connection in ref.Connections do
				connection:Disconnect()
			end
			ref.Box:Destroy()
			ref.Billboard:Destroy()
		end
	end

	EggESP = vape.Categories.Render:CreateModule({
		Name = 'EggESP',
		Function = function(callback)
			if callback then
				collection('egg', EggESP, function(objs, egg)
					table.insert(objs, egg)
					added(egg)
				end, function(objs, egg)
					local index = table.find(objs, egg)
					if index then
						table.remove(objs, index)
					end
					removed(egg)
				end)
				EggESP:Clean(lplr:GetAttributeChangedSignal('TeamId'):Connect(function()
					for egg in Reference do
						refresh(egg)
					end
				end))

				repeat
					local origin = entitylib.isAlive and bodyRoot().Position or gameCamera.CFrame.Position
					for egg, ref in Reference do
						if ref.Shown then
							local text = (ref.Team or '?')..' egg'
							if ShowHealth.Enabled then
								text ..= ' '..math.floor(ref.Health)..' HP'
							end
							if ShowDistance.Enabled then
								text ..= string.format(' [%d]', (ref.Part.Position - origin).Magnitude)
							end
							if ref.Text ~= text then
								ref.Text = text
								ref.Label.Text = text
							end
						end
					end
					task.wait(0.25)
				until not EggESP.Enabled
			else
				for egg in table.clone(Reference) do
					removed(egg)
				end
			end
		end,
		Tooltip = 'Shows eggs through walls with their team and health'
	})
	Fill = EggESP:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Default = 0.55,
		Decimal = 100,
		Function = function(val)
			for _, ref in Reference do
				ref.Box.Transparency = val
			end
		end
	})
	Own = EggESP:CreateToggle({
		Name = 'Own egg',
		Function = function()
			for egg in Reference do
				refresh(egg)
			end
		end
	})
	Dead = EggESP:CreateToggle({
		Name = 'Broken eggs',
		Function = function()
			for egg in Reference do
				refresh(egg)
			end
		end,
		Tooltip = 'Keeps showing eggs that have already been broken'
	})
	ShowHealth = EggESP:CreateToggle({
		Name = 'Health',
		Default = true
	})
	ShowDistance = EggESP:CreateToggle({
		Name = 'Distance',
		Default = true
	})
end)
