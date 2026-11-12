run(function()
	local NoSlowdown

	local function normalSpeed(hum)
		local sprint = bedfight.ButtonProperties.new('Sprint')
		local speed = (hum:GetAttribute('DefaultSpeed') or 16) + (hum:GetAttribute('SpeedBoost') or 0) + (sprint.Active.Value and 4 or 0)
		return math.min(speed, 24)
	end

	NoSlowdown = vape.Categories.Blatant:CreateModule({
		Name = 'NoSlowdown',
		Function = function(callback)
			if callback then
				local function hook(ent)
					local hum = ent.Humanoid
					NoSlowdown:Clean(hum:GetPropertyChangedSignal('WalkSpeed'):Connect(function()
						if hum:GetAttribute('SpeedLock') and hum.WalkSpeed < normalSpeed(hum) then
							hum.WalkSpeed = normalSpeed(hum)
						end
					end))
				end
				NoSlowdown:Clean(entitylib.Events.LocalAdded:Connect(hook))
				if entitylib.isAlive then
					hook(entitylib.character)
				end
			end
		end,
		Tooltip = 'Stops items and weapons slowing you down'
	})
end)
