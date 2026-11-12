run(function()
	local TimeChanger
	local Value
	local old
	
	TimeChanger = vape.Categories.Legit:CreateModule({
		Name = 'TimeChanger',
		Category = 'Game',
		Function = function(callback)
			if callback then
				old = lightingService.TimeOfDay
				repeat
					local wanted = Value.Value..':00:00'
					if lightingService.TimeOfDay ~= wanted then
						lightingService.TimeOfDay = wanted
					end
					task.wait()
				until not TimeChanger.Enabled
			else
				lightingService.TimeOfDay = old
				old = nil
			end
		end,
		Tooltip = 'Changes the time of day'
	})
	
	Value = TimeChanger:CreateSlider({
		Name = 'Time',
		Min = 0,
		Max = 24,
		Function = function(val)
			if TimeChanger.Enabled then
				lightingService.TimeOfDay = val..':00:00'
			end
		end,
		Default = 12
	})
end)
