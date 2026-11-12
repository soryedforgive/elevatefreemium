run(function()
	local Velocity
	local Horizontal
	local Vertical
	local writing = false

	local function watch(ent)
		local root = ent.RootPart
		Velocity:Clean(root:GetAttributeChangedSignal('NKb'):Connect(function()
			if writing then return end
			local kb = root:GetAttribute('NKb')
			if typeof(kb) ~= 'Vector3' then return end
			local h, v = Horizontal.Value / 100, Vertical.Value / 100
			writing = true
			if h <= 0 and v <= 0 then
				root:SetAttribute('NKb', nil)
			else
				root:SetAttribute('NKb', Vector3.new(kb.X * h, kb.Y * v, kb.Z * h))
			end
			writing = false
		end))
		for _, key in {'SKb', 'SKbF', 'SKbN'} do
			Velocity:Clean(root:GetAttributeChangedSignal(key):Connect(function()
				if Horizontal.Value <= 0 and Vertical.Value <= 0 and root:GetAttribute(key) ~= nil then
					root:SetAttribute(key, nil)
				end
			end))
		end
	end

	Velocity = vape.Categories.Combat:CreateModule({
		Name = 'Velocity',
		Function = function(callback)
			if callback then
				Velocity:Clean(entitylib.Events.LocalAdded:Connect(watch))
				if entitylib.isAlive then
					watch(entitylib.character)
				end
			end
		end,
		Tooltip = 'Reduces knockback taken'
	})
	Horizontal = Velocity:CreateSlider({
		Name = 'Horizontal',
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = '%'
	})
	Vertical = Velocity:CreateSlider({
		Name = 'Vertical',
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = '%'
	})
end)
