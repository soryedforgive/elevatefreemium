run(function()
	local ArmorHUD
	local Sword
	local Background
	local icons = {}
	local holder

	local function image(name)
		local data = name and name ~= '' and bedfight.ItemsData[name]
		return data and data.Image or nil
	end

	local function update()
		local info = lplr:FindFirstChild('EquippedArmorInfo')
		local list = {}
		for _, slot in {'Helmet', 'Chestplate', 'Pants'} do
			local value = info and info:FindFirstChild(slot)
			table.insert(list, image(value and value.Value) or false)
		end
		table.insert(list, Sword.Enabled and image(store.tools.sword) or false)
		for i, icon in icons do
			icon.Image = list[i] or ''
			icon.Visible = list[i] ~= false
		end
	end

	ArmorHUD = vape.Categories.Legit:CreateModule({
		Name = 'ArmorHUD',
		Category = 'Hud',
		Function = function(callback)
			if callback then
				ArmorHUD:Clean(vapeEvents.InventoryChanged.Event:Connect(update))
				local info = lplr:FindFirstChild('EquippedArmorInfo')
				for _, v in info and info:GetChildren() or {} do
					if v:IsA('StringValue') then
						ArmorHUD:Clean(v:GetPropertyChangedSignal('Value'):Connect(update))
					end
				end
				update()
			end
		end,
		Size = UDim2.fromOffset(48, 184),
		Tooltip = 'Shows the armor you wear and your best sword'
	})
	Sword = ArmorHUD:CreateToggle({
		Name = 'Sword',
		Default = true,
		Function = function()
			if ArmorHUD.Enabled then
				update()
			end
		end
	})
	Background = ArmorHUD:CreateColorSlider({
		Name = 'Colour',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			holder.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			holder.BackgroundTransparency = 1 - opacity
		end
	})

	holder = Instance.new('Frame')
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundColor3 = Color3.new()
	holder.BackgroundTransparency = 0.5
	holder.Parent = ArmorHUD.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = holder
	local layout = Instance.new('UIListLayout')
	layout.Padding = UDim.new(0, 4)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = holder
	for i = 1, 4 do
		local icon = Instance.new('ImageLabel')
		icon.Size = UDim2.fromOffset(40, 40)
		icon.BackgroundTransparency = 1
		icon.ScaleType = Enum.ScaleType.Fit
		icon.LayoutOrder = i
		icon.Visible = false
		icon.Parent = holder
		icons[i] = icon
	end
end)
