run(function()
	local KnockbackDelay
	local Delay
	local Chance
	local rand = Random.new()

	local function delayed(velocity)
		if rand:NextNumber(0, 100) > Chance.Value then return velocity, 0 end
		return velocity, Delay.Value / 1000
	end

	KnockbackDelay = vape.Categories.Utility:CreateModule({
		Name = 'KnockbackDelay',
		Function = function(callback)
			if callback then
				if not store.knockbackFilter('KnockbackDelay', delayed) then
					store.knockbackFilter('KnockbackDelay', nil)
					notif('KnockbackDelay', 'Your executor cannot hook the knockback handler.', 6, 'warning')
					KnockbackDelay:Toggle()
				end
			else
				store.knockbackFilter('KnockbackDelay', nil)
			end
		end,
		Tooltip = 'Delays the knockback you take'
	})
	Delay = KnockbackDelay:CreateSlider({
		Name = 'Delay',
		Min = 0,
		Max = 500,
		Default = 150,
		Suffix = 'ms'
	})
	Chance = KnockbackDelay:CreateSlider({
		Name = 'Chance',
		Min = 0,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
end)
