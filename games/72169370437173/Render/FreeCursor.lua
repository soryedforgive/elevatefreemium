run(function()
	local FreeCursor
	local util = tribes.Util
	local cameraApi = (util and util.Camera and util.Camera()) or tribes.Camera
	local hud = tribes.Hud
	local guiService = game:GetService('GuiService')
	local REASON = 'AetherFreeCursor'
	local CROSSHAIRS = {'Melee', 'Bow', 'Gun', 'Spread', 'Throw', 'Use', 'Dot'}

	local function cursorReady()
		return FreeCursor and FreeCursor.Enabled and not guiService.MenuIsOpen and lplr:GetAttribute('MenuOpen') ~= true and not inputService:GetFocusedTextBox()
	end

	local function updateCrosshair(restore)
		local gui = lplr.PlayerGui:FindFirstChild('CombatHUD')
		local center = gui and gui:FindFirstChild('Center')
		if not (center and hud) then return end
		local style = hud.GetStyle()
		local show = restore or not cursorReady()
		for _, name in CROSSHAIRS do
			local item = center:FindFirstChild(name)
			local visible = show and name == style
			if item and item.Visible ~= visible then
				item.Visible = visible
			end
		end
	end

	gameapi.Patch(util, 'IsMouseUnlocked', function(original)
		return function(...)
			if cursorReady() then return false end
			return original(...)
		end
	end)
	gameapi.Patch(cameraApi, 'GetAimRay', function(original)
		return function(...)
			if cursorReady() then
				local position = inputService:GetMouseLocation()
				return gameCamera:ViewportPointToRay(position.X, position.Y)
			end
			return original(...)
		end
	end)
	gameapi.Patch(hud, 'SetStyle', function(original)
		return function(...)
			local result = original(...)
			if cursorReady() then
				updateCrosshair(false)
			end
			return result
		end
	end)

	local function setUnlocked(enabled)
		if not cameraApi then return end
		if enabled then
			pcall(cameraApi.PushMouseUnlock, REASON)
			updateCrosshair(false)
		else
			pcall(cameraApi.PopMouseUnlock, REASON)
			updateCrosshair(true)
		end
	end

	FreeCursor = vape.Categories.Render:CreateModule({
		Name = 'FreeCursor',
		Function = function(callback)
			setUnlocked(callback)
			if callback then
				FreeCursor:Clean(runService.RenderStepped:Connect(function()
					if cursorReady() then
						updateCrosshair(false)
					end
				end))
				FreeCursor:Clean(inputService.InputBegan:Connect(function(input)
					if input.KeyCode == Enum.KeyCode.V and not inputService:GetFocusedTextBox() then
						pcall(cameraApi.ToggleFirstPerson)
					end
				end))
				FreeCursor:Clean(inputService.InputChanged:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseMovement or not inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
					pcall(cameraApi.SetLook, cameraApi.GetYaw() - input.Delta.X * 0.003, cameraApi.GetPitch() - input.Delta.Y * 0.003)
				end))
			end
		end,
		Tooltip = 'Frees your cursor from the middle of the screen'
	})
end)
