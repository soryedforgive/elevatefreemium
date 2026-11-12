run(function()
    local ZoomUnlocker
    local Distance

    local old

    ZoomUnlocker = vape.Categories.Render:CreateModule({
	Name = 'ZoomUnlocker',
	Tooltip = 'Changes how far you can zoom out',
	Function = function(call)
		if call then
			old = lplr.CameraMaxZoomDistance
			lplr.CameraMaxZoomDistance = Distance.Value
		else
			lplr.CameraMaxZoomDistance = old
			old = nil
		end
	end,
    })

    Distance = ZoomUnlocker:CreateSlider({
	Name = 'Distance',
	Min = (lplr.CameraMinZoomDistance or 0),
	Max = 300,
	Decimal = 5,
	Default = (lplr.CameraMaxZoomDistance or 14),
	Function = function(val)
		if ZoomUnlocker.Enabled then
			lplr.CameraMaxZoomDistance = val
		end
	end,
    })
    ZoomUnlocker:CreateButton({
	Name = 'Reset to default zoom',
	Tooltip = 'Sets zoom back to the game\'s default',
	Function = function()
		Distance:SetValue(14)
	end,
    })
end)

