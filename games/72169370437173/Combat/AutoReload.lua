run(function()
	local AutoReload
	local Range
	local clearSince

	AutoReload = vape.Categories.Combat:CreateModule({
		Name = 'AutoReload',
		Function = function(callback)
			if callback then
				repeat
					local handler, class = store.handler()
					if handler and class == 'Gun' and entitylib.isAlive and not handler.reloading and type(handler.ammo) == 'number' and handler.ammo < (handler.magazine or 0) then
						local near = false
						local pos = store.body()
						for _, ent in entitylib.List do
							if ent.Targetable and ent.Health > 0 and (ent.RootPart.Position - pos).Magnitude <= Range.Value then
								near = true
								break
							end
						end
						if handler.ammo <= 0 or not near then
							clearSince = clearSince or tick()
							if handler.ammo <= 0 or tick() - clearSince > 0.75 then
								pcall(handler.RequestReload, handler)
								clearSince = nil
							end
						else
							clearSince = nil
						end
					else
						clearSince = nil
					end
					task.wait(0.1)
				until not AutoReload.Enabled
			end
		end,
		Tooltip = 'Reloads your gun when it is empty, or when no enemy is near'
	})
	Range = AutoReload:CreateSlider({
		Name = 'Safe range',
		Min = 0,
		Max = 100,
		Default = 35,
		Suffix = 'studs',
		Tooltip = 'Only reloads a part-used magazine with no enemy this close'
	})
end)
