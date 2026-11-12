run(function()
	local AutoChargeProj
	local Percentage
	local old, wrapper

	AutoChargeProj = vape.Categories.Blatant:CreateModule({
		Name = 'AutoChargeProj',
		Function = function(callback)
			if callback then
				if wrapper then return end
				old = bedfight.Ranged.UpdateBeam
				wrapper = function(self, ...)
					if AutoChargeProj.Enabled then
						pcall(function()
							local range, value = self.Data.ChargeRange, self.Charge
							if range and value and self.Activated then
								local wanted = range.Min + (range.Max - range.Min) * Percentage.Value / 100
								if value.Value < wanted then
									value.Value = wanted
								end
							end
						end)
					end
					return old(self, ...)
				end
				bedfight.Ranged.UpdateBeam = wrapper
			elseif wrapper and bedfight.Ranged.UpdateBeam == wrapper then
				bedfight.Ranged.UpdateBeam = old
				old, wrapper = nil, nil
			end
		end,
		Tooltip = 'Instantly charges projectile items to the set charge'
	})
	Percentage = AutoChargeProj:CreateSlider({
		Name = 'Percentage',
		Min = 0,
		Max = 100,
		Default = 50,
		Suffix = '%'
	})
end)
