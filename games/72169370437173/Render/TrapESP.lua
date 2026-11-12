run(function()
	local TrapESP
	local FillColor
	local FillTransparency
	local Walls
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	vape:Clean(Folder)

	local function added(obj)
		if Reference[obj] then return end
		if vape.ThreadFix then
			setthreadidentity(8)
		end
		local mine = lplr.Character and lplr.Character:GetAttribute('Team') or lplr:GetAttribute('Team')
		if mine ~= nil and obj:GetAttribute('Team') == mine then return end
		local box = Instance.new('BoxHandleAdornment')
		box.AlwaysOnTop = Walls.Enabled
		box.Adornee = obj
		box.Size = Vector3.new(3, 1, 3)
		box.ZIndex = 0
		box.Transparency = FillTransparency.Value
		box.Color3 = Color3.fromHSV(FillColor.Hue, FillColor.Sat, FillColor.Value)
		box.Parent = Folder
		Reference[obj] = box
	end

	local function removed(obj)
		local box = Reference[obj]
		if box then
			Reference[obj] = nil
			box:Destroy()
		end
	end

	TrapESP = vape.Categories.Render:CreateModule({
		Name = 'TrapESP',
		Function = function(callback)
			if callback then
				TrapESP:Clean(collectionService:GetInstanceAddedSignal('BearTrap'):Connect(added))
				TrapESP:Clean(collectionService:GetInstanceRemovedSignal('BearTrap'):Connect(removed))
				for _, obj in collectionService:GetTagged('BearTrap') do
					task.spawn(added, obj)
				end
			else
				Folder:ClearAllChildren()
				table.clear(Reference)
			end
		end,
		Tooltip = 'Shows enemy traps through walls'
	})
	FillColor = TrapESP:CreateColorSlider({
		Name = 'Color',
		Function = function(hue, sat, val)
			local color = Color3.fromHSV(hue, sat, val)
			for _, box in Reference do
				box.Color3 = color
			end
		end
	})
	FillTransparency = TrapESP:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Default = 0.5,
		Decimal = 10,
		Function = function(val)
			for _, box in Reference do
				box.Transparency = val
			end
		end
	})
	Walls = TrapESP:CreateToggle({
		Name = 'Render Walls',
		Default = true,
		Function = function(callback)
			for _, box in Reference do
				box.AlwaysOnTop = callback
			end
		end
	})
end)
