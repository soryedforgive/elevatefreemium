run(function()
	local Spectate
	local TargetBox
	local Keys
	local EnemiesOnly
	local current
	local oldSubject
	local targetConnection
	local state = {Active = false, Applying = false, Pending = false}

	local function humanoidOf(player)
		local character = player and player.Character
		return character and character:FindFirstChildOfClass('Humanoid') or nil
	end

	local function candidates()
		local list = {}
		for _, player in playersService:GetPlayers() do
			if player ~= lplr and humanoidOf(player) then
				local ent = EnemiesOnly.Enabled and entitylib.getEntity(player) or nil
				if not EnemiesOnly.Enabled or (ent and ent.Targetable) then
					table.insert(list, player)
				end
			end
		end
		return list
	end

	local function apply()
		if not Spectate.Enabled or not current then return end
		local humanoid = humanoidOf(current)
		local camera = gameCamera
		if humanoid and camera and camera.CameraSubject ~= humanoid then
			state.Applying = true
			camera.CameraSubject = humanoid
			state.Applying = false
		end
	end

	local function watch(player, quiet)
		if targetConnection then
			targetConnection:Disconnect()
			targetConnection = nil
		end
		current = player
		if not player then return end

		targetConnection = player.CharacterAdded:Connect(function(character)
			character:WaitForChild('Humanoid', 10)
			if current == player then
				apply()
			end
		end)
		apply()
		if not quiet then
			notif('Spectate', 'Watching '..player.DisplayName..(player.DisplayName ~= player.Name and ' (@'..player.Name..')' or ''), 3)
		end
	end

	local function step(direction)
		if not Spectate.Enabled then return end
		local list = candidates()
		if #list == 0 then
			notif('Spectate', 'There is nobody to watch right now.', 4, 'warning')
			return
		end
		local index = table.find(list, current)
		index = index and ((index - 1 + direction) % #list) + 1 or (direction > 0 and 1 or #list)
		watch(list[index])
	end

	local function find(text)
		text = tostring(text or ''):lower():gsub('^%s+', ''):gsub('%s+$', '')
		if text == '' then return nil end
		local partial
		for _, player in playersService:GetPlayers() do
			if player ~= lplr then
				local name, display = player.Name:lower(), player.DisplayName:lower()
				if name == text or display == text then
					return player
				end
				if not partial and (name:find(text, 1, true) or display:find(text, 1, true)) then
					partial = player
				end
			end
		end
		return partial
	end

	local function restore()
		if not state.Active then return end
		state.Active = false
		if targetConnection then
			targetConnection:Disconnect()
			targetConnection = nil
		end
		current = nil
		local camera = gameCamera
		if camera then
			state.Applying = true
			pcall(function()
				camera.CameraSubject = humanoidOf(lplr) or oldSubject
			end)
			state.Applying = false
		end
		oldSubject = nil
	end

	Spectate = vape.Categories.World:CreateModule({
		Name = 'Spectate',
		Function = function(callback)
			if callback then
				local wanted = find(TargetBox.Value)
				if not (wanted and humanoidOf(wanted)) then
					wanted = candidates()[1]
				end
				if not wanted then
					notif('Spectate', 'There is nobody to watch right now.', 4, 'warning')
					Spectate:Toggle()
					return
				end
				oldSubject = gameCamera and gameCamera.CameraSubject or nil
				state.Active = true
				watch(wanted)

				Spectate:Clean(playersService.PlayerRemoving:Connect(function(player)
					if player == current then
						step(1)
					end
				end))
				if gameCamera then
					Spectate:Clean(gameCamera:GetPropertyChangedSignal('CameraSubject'):Connect(function()
						if state.Applying or state.Pending or not current then return end
						state.Pending = true
						task.delay(0.2, function()
							state.Pending = false
							apply()
						end)
					end))
				end
				Spectate:Clean(inputService.InputBegan:Connect(function(input)
					if not Keys.Enabled or inputService:GetFocusedTextBox() then return end
					if input.KeyCode == Enum.KeyCode.RightBracket then
						step(1)
					elseif input.KeyCode == Enum.KeyCode.LeftBracket then
						step(-1)
					end
				end))
			else
				restore()
			end
		end,
		ExtraText = function()
			return current and current.DisplayName or ''
		end,
		Tooltip = 'Moves your camera onto another player'
	})

	TargetBox = Spectate:CreateTextBox({
		Name = 'Player',
		Placeholder = 'name, or empty for the first player',
		Function = function(enter)
			if not enter or not Spectate.Enabled then return end
			local wanted = find(TargetBox.Value)
			if wanted then
				watch(wanted)
			elseif TargetBox.Value ~= '' then
				notif('Spectate', 'No player matches "'..TargetBox.Value..'".', 4, 'warning')
			end
		end,
		Tooltip = 'Username or display name, part of it is enough'
	})
	Spectate:CreateButton({
		Name = 'Next player',
		Function = function()
			step(1)
		end
	})
	Spectate:CreateButton({
		Name = 'Previous player',
		Function = function()
			step(-1)
		end
	})
	Keys = Spectate:CreateToggle({
		Name = 'Bracket keys',
		Default = true,
		Tooltip = 'Use ] and [ to change player while spectating'
	})
	EnemiesOnly = Spectate:CreateToggle({
		Name = 'Enemies only',
		Tooltip = 'Next and Previous skip your teammates'
	})

	vape:Clean(restore)
end)
