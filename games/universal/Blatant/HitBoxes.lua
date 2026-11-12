run(function()
    local HitBoxes
    local Targets
    local TargetPart
    local Expand
    local modified = setmetatable({}, {__mode = 'k'})
    local wanted = {}

    local function restore(part)
	local saved = modified[part]
	if not saved then return end
	modified[part] = nil
	pcall(function()
		part.Size = saved[1]
		part.Massless = saved[2]
	end)
    end

    HitBoxes = vape.Categories.Blatant:CreateModule({
	Name = 'HitBoxes',
	ExtraText = function() return tostring(Expand.Value) end,
	Function = function(callback)
		if callback then
			repeat
				table.clear(wanted)
				local expand = Vector3.new(Expand.Value, Expand.Value, Expand.Value)
				for _, v in entitylib.List do
					if v.Targetable then
						if not Targets.Players.Enabled and v.Player then
							continue
						end
						if not Targets.NPCs.Enabled and v.NPC then
							continue
						end
						local part = v[TargetPart.Value]
						if part and part.Parent then
							if not modified[part] then
								modified[part] = {part.Size, part.Massless}
							end
							wanted[part] = true
							local size = modified[part][1] + expand
							if part.Size ~= size then
								part.Size = size
							end
							if not part.Massless then
								part.Massless = true
							end
						end
					end
				end
				for part in modified do
					if not wanted[part] then
						restore(part)
					end
				end
				task.wait()
			until not HitBoxes.Enabled
		else
			for part in modified do
				restore(part)
			end
			table.clear(modified)
			table.clear(wanted)
		end
	end,
	Tooltip = 'Expands entities hitboxes',
    })
    Targets = HitBoxes:CreateTargets({ Players = true })
    TargetPart = HitBoxes:CreateDropdown({
	Name = 'Part',
	List = { 'RootPart', 'Head' },
    })
    Expand = HitBoxes:CreateSlider({
	Name = 'Expand amount',
	Min = 0,
	Max = 2,
	Decimal = 10,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end,
    })
end)
