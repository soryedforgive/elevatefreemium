run(function()
	local Timer
	local Value

	Timer = vape.Categories.Blatant:CreateModule({
		Name = 'Timer',
		Function = function(callback)
			if callback then
				Timer:Clean(runService.RenderStepped:Connect(function(dt)
					if Value.Value > 1 and entitylib.isAlive then
						local root = entitylib.character.RootPart
						if not root or not root.Parent then return end
						runService:Pause()
						pcall(workspace.StepPhysics, workspace, dt * (Value.Value - 1), {root})
						runService:Run()
					end
				end))
			end
		end,
		ExtraText = function()
			return Value.Value..'x'
		end,
		Tooltip = 'Changes the game speed'
	})
	Value = Timer:CreateSlider({
		Name = 'Value',
		Min = 1,
		Max = 3,
		Decimal = 10
	})
end)
