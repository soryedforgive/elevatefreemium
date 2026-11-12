run(function()
	local AntiVision
	local Fog
	local FogRange
	local Atmosphere
	local Smoke
	local Boost
	local saved

	AntiVision = vape.Categories.Render:CreateModule({
		Name = 'AntiVision',
		Function = function(callback)
			if callback then
				local atmosphere = lightingService:FindFirstChildOfClass('Atmosphere')
				saved = {
					FogEnd = lightingService.FogEnd,
					FogStart = lightingService.FogStart,
					Brightness = lightingService.Brightness,
					Ambient = lightingService.Ambient,
					Density = atmosphere and atmosphere.Density,
					Haze = atmosphere and atmosphere.Haze
				}
				AntiVision:Clean(runService.Heartbeat:Connect(function()
					if Fog.Enabled then
						lightingService.FogEnd = FogRange.Value
						lightingService.FogStart = FogRange.Value - 10
					end
					if Atmosphere.Enabled then
						local current = lightingService:FindFirstChildOfClass('Atmosphere')
						if current then
							current.Density = 0
							current.Haze = 0
						end
					end
					if Smoke.Enabled then
						local effect = lightingService:FindFirstChild('SmokeColorCorrection')
						if effect and effect.Enabled then
							effect.Enabled = false
						end
					end
					if Boost.Enabled then
						lightingService.Brightness = 5
						lightingService.Ambient = Color3.fromRGB(150, 150, 150)
					end
				end))
			elseif saved then
				lightingService.FogEnd = saved.FogEnd
				lightingService.FogStart = saved.FogStart
				lightingService.Brightness = saved.Brightness
				lightingService.Ambient = saved.Ambient
				local atmosphere = lightingService:FindFirstChildOfClass('Atmosphere')
				if atmosphere and saved.Density then
					atmosphere.Density = saved.Density
					atmosphere.Haze = saved.Haze
				end
				saved = nil
			end
		end,
		Tooltip = 'Clears fog, haze and smoke so you can always see'
	})
	Fog = AntiVision:CreateGroup({
		Name = 'Remove fog',
		Default = true,
	})
	FogRange = Fog:CreateSlider({
		Name = 'Fog range',
		Min = 1000,
		Max = 200000,
		Default = 100000,
		Darker = true
	})
	Atmosphere = AntiVision:CreateToggle({
		Name = 'Clear atmosphere',
		Default = true
	})
	Smoke = AntiVision:CreateToggle({
		Name = 'No smoke',
		Default = true,
		Tooltip = 'Removes the smoke screen effect'
	})
	Boost = AntiVision:CreateToggle({Name = 'Boost lighting'})
end)
