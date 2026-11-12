run(function()
	local AutoRelease
	local Charge

	AutoRelease = vape.Categories.Combat:CreateModule({
		Name = 'AutoRelease',
		Function = function(callback)
			if callback then
				AutoRelease:Clean(runService.Heartbeat:Connect(function()
					local handler, class = store.handler()
					if not handler or not (class == 'Bow' or (class == 'Throw' and handler.winds)) then return end
					if (handler.drawing or handler.winding) and handler:Charge() >= Charge.Value / 100 then
						store.press(handler, false)
					end
				end))
			end
		end,
		Tooltip = 'Releases your shot at the set charge'
	})
	Charge = AutoRelease:CreateSlider({
		Name = 'Charge',
		Min = 10,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
end)
