run(function()
	local AutoChargeProj
	local Charge
	local class, original, wrapper

	local function hook()
		local controller = skywars.ProjectileController
		local meta = controller and getmetatable(controller)
		class = type(meta) == 'table' and type(rawget(meta, 'getStrength')) == 'function' and meta or nil
		if not class then return false end
		if class.getStrength == wrapper then return true end
		original = class.getStrength
		wrapper = function(self, ...)
			if AutoChargeProj.Enabled then
				return Charge.Value / 100
			end
			return original(self, ...)
		end
		class.getStrength = wrapper
		return true
	end

	AutoChargeProj = vape.Categories.Blatant:CreateModule({
		Name = 'AutoChargeProj',
		Function = function(callback)
			if callback then
				if not hook() then
					notif('AutoChargeProj', 'The bow charge could not be found.', 6, 'warning')
				end
			elseif class and class.getStrength == wrapper then
				class.getStrength = original
				wrapper = nil
			end
		end,
		Tooltip = 'Fires at the set charge however long you draw'
	})
	Charge = AutoChargeProj:CreateSlider({
		Name = 'Charge',
		Min = 1,
		Max = 100,
		Default = 100,
		Suffix = '%',
		Tooltip = 'How far to charge before firing'
	})
end)
