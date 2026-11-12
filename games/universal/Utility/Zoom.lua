run(function()
	local Zoom
	local Hotkey
	local ZoomFOV
	local Smoothing
	local keyCode
	local lastValidKey = 'C'
	local held = false
	local amount = 0
	local baseFov
	local RENDER_NAME = 'AetherZoom'

	local function applyHotkey(silent)
		local text = tostring(Hotkey and Hotkey.Value or ''):gsub('%s', ''):upper()
		if #text == 1 and text:match('%a') and Enum.KeyCode[text] then
			keyCode = Enum.KeyCode[text]
			lastValidKey = text
			if Hotkey.Value ~= text then Hotkey:SetValue(text) end
			return
		end
		held = false
		if not silent then
			notif('Zoom', 'The hotkey must be a single letter', 3, 'warning')
		end
		Hotkey:SetValue(lastValidKey)
	end

	local function step(dt)
		local camera = workspace.CurrentCamera
		if not camera then return end
		local goal = held and 1 or 0
		if goal == 1 and amount == 0 then
			baseFov = camera.FieldOfView
		end
		if amount == goal and goal == 0 then return end

		if Smoothing.Value <= 0 then
			amount = goal
		else
			local alpha = 1 - math.exp(-(30 / Smoothing.Value) * dt)
			amount += (goal - amount) * alpha
			if math.abs(goal - amount) < 0.001 then amount = goal end
		end

		if baseFov then
			camera.FieldOfView = baseFov + (ZoomFOV.Value - baseFov) * amount
			if amount == 0 then
				camera.FieldOfView = baseFov
				baseFov = nil
			end
		end
	end

	local function unbind()
		pcall(runService.UnbindFromRenderStep, runService, RENDER_NAME)
	end

	Zoom = vape.Categories.Utility:CreateModule({
		Name = 'Zoom',
		Function = function(callback)
			unbind()
			held = false
			if callback then
				applyHotkey(true)
				runService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 1, step)
				Zoom:Clean(unbind)
				Zoom:Clean(inputService.InputBegan:Connect(function(input, processed)
					if processed or inputService:GetFocusedTextBox() then return end
					if keyCode and input.KeyCode == keyCode then held = true end
				end))
				Zoom:Clean(inputService.InputEnded:Connect(function(input)
					if keyCode and input.KeyCode == keyCode then held = false end
				end))
			else
				local camera = workspace.CurrentCamera
				if camera and baseFov then camera.FieldOfView = baseFov end
				baseFov, amount = nil, 0
			end
		end,
		Tooltip = 'Zooms in while you hold the hotkey'
	})
	Hotkey = Zoom:CreateTextBox({
		Name = 'Hotkey',
		Default = 'C',
		Placeholder = 'Letter...',
		Function = function()
			applyHotkey()
		end,
		Tooltip = 'A single letter'
	})
	ZoomFOV = Zoom:CreateSlider({
		Name = 'Zoom FOV',
		Min = 5,
		Max = 60,
		Default = 20,
		Tooltip = 'Field of view while zoomed. Lower zooms in further'
	})
	Smoothing = Zoom:CreateSlider({
		Name = 'Smoothing',
		Min = 0,
		Max = 10,
		Default = 3,
		Decimal = 10,
		Tooltip = 'How slowly it eases in and out'
	})
end)
