run(function()
    local Reach
    local Targets
    local Mode
    local Value
    local Chance
    local Overlay = OverlapParams.new()
    Overlay.FilterType = Enum.RaycastFilterType.Include
    local modified = {}
    local rand = Random.new()

    local function restore()
	for part, saved in modified do
		pcall(function()
			part.Size = saved.Size
			part.Massless = saved.Massless
		end)
	end
	table.clear(modified)
    end

    Reach = vape.Categories.Combat:CreateModule({
	Name = 'Reach',
	ExtraText = function() return tostring(Value.Value) end,
	Function = function(callback)
		if callback then
			repeat
				local tool = getTool()
				tool = tool and tool:FindFirstChildWhichIsA('TouchTransmitter', true)
				if tool then
					if Mode.Value == 'TouchInterest' then
						if type(firetouchinterest) ~= 'function' then
							notif('Reach', 'Your executor has no firetouchinterest. Use Resize mode instead.', 6, 'warning')
							Reach:Toggle()
							return
						end
						if next(modified) then
							restore()
						end
						local entites = {}
						for _, v in entitylib.List do
							if v.Targetable then
								if not Targets.Players.Enabled and v.Player then
									continue
								end
								if not Targets.NPCs.Enabled and v.NPC then
									continue
								end
								table.insert(entites, v.Character)
							end
						end

						Overlay.FilterDescendantsInstances = entites
						local parts = workspace:GetPartBoundsInBox(
							tool.Parent.CFrame * CFrame.new(0, 0, Value.Value / 2),
							tool.Parent.Size + Vector3.new(0, 0, Value.Value),
							Overlay
						)

						for _, v in parts do
							if rand:NextNumber(0, 100) > Chance.Value then
								task.wait(0.2)
								break
							end

							firetouchinterest(tool.Parent, v, 1)
							firetouchinterest(tool.Parent, v, 0)
						end
					else
						local part = tool.Parent
						if not modified[part] then
							modified[part] = {Size = part.Size, Massless = part.Massless}
						end
						local size = modified[part].Size + Vector3.new(0, 0, Value.Value)
						if part.Size ~= size then
							part.Size = size
						end
						if not part.Massless then
							part.Massless = true
						end
					end
				end

				task.wait()
			until not Reach.Enabled
		else
			restore()
		end
	end,
	Tooltip = 'Extends tool attack reach',
    })
    Targets = Reach:CreateTargets({ Players = true })
    Mode = Reach:CreateDropdown({
	Name = 'Mode',
	List = { 'TouchInterest', 'Resize' },
	Function = function(val)
		Chance.Object.Visible = val == 'TouchInterest'
	end,
	Tooltip = 'How your weapon\'s reach is extended',
    })
    Value = Reach:CreateSlider({
	Name = 'Range',
	Min = 0,
	Max = 2,
	Decimal = 10,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end,
    })
    Chance = Reach:CreateSlider({
	Name = 'Chance',
	Min = 0,
	Max = 100,
	Default = 100,
	Suffix = '%',
    })
end)
