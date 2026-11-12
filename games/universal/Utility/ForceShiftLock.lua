run(function()
	local ForceShiftLock
	local Mode
	local Key
	local OFFSET = Vector3.new(1.75, 0, 0)
	local KEYS = {
		Ctrl = {Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl},
		['Left Shift'] = {Enum.KeyCode.LeftShift}
	}
	local BIND = 'AetherForceShiftLock'
	local locked = false
	local nativeLock, humanoidState, clickgui

	local function menuOpen()
		if not (clickgui and clickgui.Parent) then
			clickgui = vape.gui and vape.gui:FindFirstChild('ClickGui', true)
		end
		return clickgui and clickgui.Visible
	end

	local function releaseHumanoid()
		if humanoidState then
			local humanoid = humanoidState.Humanoid
			if humanoid and humanoid.Parent then
				humanoid.AutoRotate = humanoidState.AutoRotate
				if humanoid.CameraOffset == humanoidState.Applied then
					humanoid.CameraOffset = humanoidState.Offset
				end
			end
			humanoidState = nil
		end
	end

	local function release()
		releaseHumanoid()
		if inputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
			inputService.MouseBehavior = Enum.MouseBehavior.Default
		end
	end

	local function step()
		if not locked or not entitylib.isAlive or menuOpen() then
			if humanoidState then
				release()
			end
			return
		end
		local humanoid = entitylib.character.Humanoid
		if humanoidState and humanoidState.Humanoid ~= humanoid then
			humanoidState = nil
		end
		if not humanoidState then
			humanoidState = {Humanoid = humanoid, AutoRotate = humanoid.AutoRotate, Offset = humanoid.CameraOffset}
		end
		inputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		local firstPerson = (gameCamera.Focus.Position - gameCamera.CFrame.Position).Magnitude < 1
		local applied = firstPerson and humanoidState.Offset or OFFSET
		humanoidState.Applied = applied
		if humanoid.CameraOffset ~= applied then
			humanoid.CameraOffset = applied
		end
		if humanoid.Sit or humanoid.PlatformStand then
			if not humanoid.AutoRotate then
				humanoid.AutoRotate = true
			end
			return
		end
		if humanoid.AutoRotate then
			humanoid.AutoRotate = false
		end
		local look = gameCamera.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.01 then
			local root = entitylib.character.RootPart
			root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
		end
	end

	ForceShiftLock = vape.Categories.Utility:CreateModule({
		Name = 'ForceShiftLock',
		Function = function(callback)
			if callback then
				nativeLock = lplr.DevEnableMouseLock
				lplr.DevEnableMouseLock = false
				ForceShiftLock:Clean(lplr:GetPropertyChangedSignal('DevEnableMouseLock'):Connect(function()
					if lplr.DevEnableMouseLock then
						lplr.DevEnableMouseLock = false
					end
				end))
				if Mode.Value == 'Force enable' then
					locked = true
					ForceShiftLock:Clean(inputService.InputBegan:Connect(function(input)
						if inputService:GetFocusedTextBox() then return end
						if table.find(KEYS[Key.Value], input.KeyCode) then
							locked = not locked
						end
					end))
					runService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 1, step)
					ForceShiftLock:Clean(function()
						pcall(function()
							runService:UnbindFromRenderStep(BIND)
						end)
					end)
				end
			else
				locked = false
				release()
				if nativeLock ~= nil then
					lplr.DevEnableMouseLock = nativeLock
					nativeLock = nil
				end
			end
		end,
		Tooltip = 'Forces shift lock on or off, even where the game does not allow it'
	})
	Mode = ForceShiftLock:CreateDropdown({
		Name = 'Mode',
		List = {'Force enable', 'Force disable'},
		Function = function()
			if ForceShiftLock.Enabled then
				ForceShiftLock:Toggle()
				ForceShiftLock:Toggle()
			end
		end,
		Tooltip = 'Force enable - shift lock is available and starts on\nForce disable - shift lock stays off'
	})
	Key = ForceShiftLock:CreateDropdown({
		Name = 'Key',
		List = {'Ctrl', 'Left Shift'},
		Visible = function()
			return Mode.Value == 'Force enable'
		end,
		Tooltip = 'Key that turns shift lock on and off'
	})
end)
