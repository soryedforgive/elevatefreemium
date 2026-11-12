run(function()
	local CapeChanger
	local Cape
	local before

	local function set(name)
		local value = lplr:FindFirstChild('Cape')
		if value and (name == '' or bedfight.CapesData[name]) then
			value.Value = name
		end
	end

	CapeChanger = vape.Categories.Render:CreateModule({
		Name = 'CapeChanger',
		Function = function(callback)
			local value = lplr:FindFirstChild('Cape')
			if callback then
				before = before or (value and value.Value) or ''
				set(Cape.Value)
			elseif before then
				set(before)
				before = nil
			end
		end,
		Tooltip = 'Wears any cape on your screen, only you can see it'
	})
	local list = {}
	for name in bedfight.CapesData do
		if type(name) == 'string' and bedfight.Capes:FindFirstChild(name) then
			table.insert(list, name)
		end
	end
	table.sort(list)
	Cape = CapeChanger:CreateDropdown({
		Name = 'Cape',
		List = list,
		Function = function(val)
			if CapeChanger.Enabled then
				set(val)
			end
		end
	})
end)
