run(function()
	local Keybinds
	local FontOption
	local Hide
	local TextSize
	local BorderColor
	local Title
	local TitleOffset = {}
	local Sort
	local EnabledOnly
	local Dim
	local ShowMenu
	local ShowConfigs
	local Custom
	local CustomBox
	local holder
	local label
	local stroke
	local shown

	local function keys(bind)
		if type(bind) ~= 'table' or bind.Button or #bind == 0 then return nil end
		return table.concat(bind, ' + '):upper()
	end

	local function escape(str)
		return (tostring(str):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'))
	end

	local function collect()
		local list = {}
		local function add(modules)
			if type(modules) ~= 'table' then return end
			for name, module in modules do
				local bound = keys(module.Bind)
				if bound and (module.Enabled or not EnabledOnly.Enabled) and not table.find(Hide.ListEnabled, name) then
					table.insert(list, {Name = module.DisplayName or name, Keys = bound, On = module.Enabled})
				end
			end
		end
		add(vape.Modules)
		add(vape.Legit and vape.Legit.Modules)
		add(vape.Kits and vape.Kits.Modules)

		local key = Sort.Value == 'Key' and 'Keys' or 'Name'
		table.sort(list, function(a, b)
			if a[key] == b[key] then
				return a.Name < b.Name
			end
			return a[key] < b[key]
		end)

		if ShowConfigs.Enabled then
			for _, profile in vape.Profiles or {} do
				local bound = keys(profile.Bind)
				if bound then
					table.insert(list, {Name = 'Config '..tostring(profile.Name), Keys = bound, On = profile.Name == vape.Profile})
				end
			end
		end
		if ShowMenu.Enabled then
			local bound = keys(vape.Keybind)
			if bound then
				table.insert(list, 1, {Name = 'Menu', Keys = bound, On = true})
			end
		end
		return list
	end

	local function render()
		local lines = {}
		if Title.Enabled then
			table.insert(lines, TitleOffset.Enabled and '<b>Keybinds</b>\n<font size="4"> </font>' or '<b>Keybinds</b>')
		end
		local list = collect()
		for _, v in list do
			local line = escape(v.Name)..': '..escape(v.Keys)
			table.insert(lines, (Dim.Enabled and not v.On) and '<font transparency="0.45">'..line..'</font>' or line)
		end
		if #list == 0 then
			table.insert(lines, '<font transparency="0.45">No keybinds set</font>')
		end
		if Custom.Enabled and CustomBox.Value ~= '' then
			table.insert(lines, CustomBox.Value)
		end
		return table.concat(lines, '\n')
	end

	local function update(force)
		local text = render()
		if not force and text == shown then return end
		shown = text
		label.Text = text
		label.FontFace = FontOption.Value
		label.TextSize = TextSize.Value
		local size = getfontsize(removeTags(text), label.TextSize, label.FontFace)
		holder.Size = UDim2.fromOffset(size.X + 16, size.Y + (Title.Enabled and TitleOffset.Enabled and 4 or 16))
	end

	local function refresh()
		if Keybinds and Keybinds.Button and Keybinds.Button.Enabled and CustomBox then
			update(true)
		end
	end

	Keybinds = vape:CreateOverlay({
		Name = 'Keybinds',
		Icon = getcustomasset('ElevateV4/assets/new/bind.png'),
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromOffset(13, 14),
		Function = function(callback)
			if callback then
				shown = nil
				repeat
					update()
					task.wait(0.25)
				until not Keybinds.Button or not Keybinds.Button.Enabled
			end
		end
	})

	holder = Instance.new('Frame')
	holder.BackgroundColor3 = Color3.new()
	holder.BackgroundTransparency = 0.5
	holder.Parent = Keybinds.Children
	vape:Clean(Keybinds.Children:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
		if vape.ThreadFix then
			setthreadidentity(8)
		end
		local newside = Keybinds.Children.AbsolutePosition.X > (vape.gui.AbsoluteSize.X / 2)
		holder.Position = UDim2.fromScale(newside and 1 or 0, 0)
		holder.AnchorPoint = Vector2.new(newside and 1 or 0, 0)
	end))
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = holder
	label = Instance.new('TextLabel')
	label.Size = UDim2.new(1, -16, 1, -16)
	label.Position = UDim2.fromOffset(8, 8)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextSize = 16
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.new()
	label.TextStrokeTransparency = 0.8
	label.Font = Enum.Font.Arial
	label.RichText = true
	label.Text = ''
	label.Parent = holder
	stroke = Instance.new('UIStroke')
	stroke.Enabled = false
	stroke.Color = Color3.fromHSV(0.44, 1, 1)
	stroke.Parent = holder
	addBlur(holder)

	FontOption = Keybinds:CreateFont({
		Name = 'Font',
		Blacklist = 'Arial',
		Function = refresh
	})
	Hide = Keybinds:CreateTextList({
		Name = 'Blacklist',
		Tooltip = 'Name of a module to leave out',
		Icon = getcustomasset('ElevateV4/assets/new/blockedicon.png'),
		Tab = getcustomasset('ElevateV4/assets/new/blockedtab.png'),
		TabSize = UDim2.fromOffset(21, 16),
		Color = Color3.fromRGB(250, 50, 56)
	})
	Sort = Keybinds:CreateDropdown({
		Name = 'Sort',
		List = {'Name', 'Key'},
		Tooltip = 'How the list is ordered'
	})
	Keybinds:CreateColorSlider({
		Name = 'Background Colour',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			holder.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			holder.BackgroundTransparency = 1 - opacity
		end
	})
	BorderColor = Keybinds:CreateColorSlider({
		Name = 'Border Colour',
		Function = function(hue, sat, val, opacity)
			stroke.Color = Color3.fromHSV(hue, sat, val)
			stroke.Transparency = 1 - opacity
		end,
		Darker = true,
		Visible = false
	})
	TextSize = Keybinds:CreateSlider({
		Name = 'Text Size',
		Min = 1,
		Max = 30,
		Default = 16,
		Function = refresh
	})
	Title = Keybinds:CreateGroup({
		Name = 'Title',
		Function = function(callback)
			if TitleOffset and TitleOffset.Object then
			end
			refresh()
		end,
		Default = true
	})
	TitleOffset = Title:CreateToggle({
		Name = 'Offset',
		Default = true,
		Darker = true,
		Function = refresh
	})
	Keybinds:CreateToggle({
		Name = 'Border',
		Function = function(callback)
			stroke.Enabled = callback
			BorderColor.Object.Visible = callback
		end
	})
	EnabledOnly = Keybinds:CreateToggle({
		Name = 'Only enabled',
		Tooltip = 'Lists a bound module only while it is switched on'
	})
	Dim = Keybinds:CreateToggle({
		Name = 'Dim disabled',
		Default = true,
		Tooltip = 'Modules that are switched off are shown fainter'
	})
	ShowMenu = Keybinds:CreateToggle({
		Name = 'Menu key',
		Default = true,
		Tooltip = 'Also shows the key that opens the menu'
	})
	ShowConfigs = Keybinds:CreateToggle({
		Name = 'Config keys',
		Default = true,
		Tooltip = 'Also shows the keys bound to configs'
	})
	Custom = Keybinds:CreateGroup({
		Name = 'Add custom text',
	})
	CustomBox = Custom:CreateTextBox({
		Name = 'Custom text',
		Darker = true
	})
end)
