run(function()
    local Xray
    local List
    local Transparency
    local modified = setmetatable({}, {__mode = 'k'})
    local kept = {}
    local generation = 0

    local function modifyPart(v)
	if not v:IsA('BasePart') or kept[v.Name] then return end
	local character = lplr.Character
	if character and v:IsDescendantOf(character) then return end
	modified[v] = true
	v.LocalTransparencyModifier = Transparency.Value
    end

    Xray = vape.Categories.World:CreateModule({
	Name = 'Xray',
	Function = function(callback)
		generation += 1
		if callback then
			local current = generation
			table.clear(kept)
			for _, name in List.ListEnabled do
				kept[name] = true
			end
			Xray:Clean(workspace.DescendantAdded:Connect(modifyPart))
			local started = os.clock()
			for _, v in workspace:GetDescendants() do
				if current ~= generation then return end
				modifyPart(v)
				if os.clock() - started > 0.002 then
					task.wait()
					started = os.clock()
				end
			end
		else
			for part in modified do
				pcall(function()
					part.LocalTransparencyModifier = 0
				end)
			end
			table.clear(modified)
		end
	end,
	Tooltip = 'Shows the listed parts through walls',
    })
    List = Xray:CreateTextList({
	Name = 'Part',
	Function = function()
		if Xray.Enabled then
			Xray:Toggle()
			Xray:Toggle()
		end
	end,
	Tooltip = 'Names of the parts to keep solid',
    })
    Transparency = Xray:CreateSlider({
	Name = 'Transparency',
	Min = 0.1,
	Max = 1,
	Default = 0.5,
	Decimal = 10,
	Function = function(value)
		for part in modified do
			part.LocalTransparencyModifier = value
		end
	end,
	Tooltip = 'How see-through everything else becomes',
    })
end)

