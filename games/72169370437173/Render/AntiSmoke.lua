run(function()
	local AntiSmoke

	gameapi.Patch(tribes.Effects, 'SmokeCloud', function(original)
		return function(...)
			if AntiSmoke and AntiSmoke.Enabled then return end
			return original(...)
		end
	end)
	gameapi.Patch(tribes.Combat, 'SmokeBlocks', function(original)
		return function(...)
			if AntiSmoke and AntiSmoke.Enabled then return false end
			return original(...)
		end
	end)

	AntiSmoke = vape.Categories.Render:CreateModule({
		Name = 'AntiSmoke',
		Function = function(callback)
			if callback then
				local fx = workspace:FindFirstChild('FX')
				for _, object in fx and fx:GetChildren() or {} do
					if object:IsA('BasePart') and object.Name == 'PuffFX' and object:FindFirstChild('Body') and object:FindFirstChild('Low') then
						object:Destroy()
					end
				end
			end
		end,
		Tooltip = 'Hides smoke clouds so you can see through them'
	})
end)
