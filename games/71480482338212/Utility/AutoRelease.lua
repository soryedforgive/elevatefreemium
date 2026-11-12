run(function()
	local AutoRelease
	local Percentage
	local Delay
	local old, wrapper
	local reachedAt = setmetatable({}, {__mode = 'k'})

	AutoRelease = vape.Categories.Utility:CreateModule({
		Name = 'AutoRelease',
		Function = function(callback)
			if callback then
				if wrapper then return end
				old = bedfight.Ranged.UpdateBeam
				wrapper = function(self, ...)
					local results = table.pack(old(self, ...))
					if AutoRelease.Enabled then
						pcall(function()
							local range, value = self.Data.ChargeRange, self.Charge
							if not (range and value and self.Activated) then
								reachedAt[self] = nil
								return
							end
							local wanted = range.Min + (range.Max - range.Min) * Percentage.Value / 100
							if value.Value + 1e-3 < wanted then
								reachedAt[self] = nil
								return
							end
							reachedAt[self] = reachedAt[self] or tick()
							if tick() - reachedAt[self] >= Delay.Value / 1000 then
								reachedAt[self] = nil
								task.defer(function()
									if self.Activated then self:Fire() end
								end)
							end
						end)
					end
					return table.unpack(results, 1, results.n)
				end
				bedfight.Ranged.UpdateBeam = wrapper
			elseif wrapper and bedfight.Ranged.UpdateBeam == wrapper then
				bedfight.Ranged.UpdateBeam = old
				old, wrapper = nil, nil
			end
		end,
		Tooltip = 'Releases your shot at the set charge'
	})
	Percentage = AutoRelease:CreateSlider({
		Name = 'Percentage',
		Min = 1,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
	Delay = AutoRelease:CreateSlider({
		Name = 'Release delay',
		Min = 0,
		Max = 500,
		Default = 0,
		Suffix = 'ms',
		Tooltip = 'How long it holds the charge before letting go'
	})
end)
