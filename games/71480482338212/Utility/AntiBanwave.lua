run(function()
	local AntiBanwave
	local Notify
	local warned = {}
	local userOff = false

	AntiBanwave = vape.Categories.Utility:CreateModule({
		Name = 'AntiBanwave',
		Function = function(callback)
			if callback then
				userOff = false
				local found = disarmAnticheat(true)
				if found == nil then
					notif('AntiBanwave', 'Your executor cannot reach the game\'s anticheat (no getloadedmodules). Capes, bed visuals and speed changes can get this session flagged.', 15, 'alert')
				elseif store.anticheat.Tripped then
					notif('AntiBanwave', 'The anticheat already went off this session, so your actions no longer reach the server. Rejoin to fix it.', 15, 'alert')
				elseif found == 0 and vape.Loaded then
					notif('AntiBanwave', 'The anticheat was not found yet. It is checked again whenever the game sends a new copy.', 8, 'warning')
				end

				AntiBanwave:Clean(vapeEvents.AnticheatBlocked.Event:Connect(function(reason)
					if Notify.Enabled and not warned[reason] then
						warned[reason] = true
						notif('AntiBanwave', 'Stopped a detection: '..reason, 8, 'warning')
					end
				end))
			else
				table.clear(warned)
				if vape.Loaded then
					userOff = true
					disarmAnticheat(false)
					notif('AntiBanwave', 'The anticheat is live again. One detection now cuts you off from the server until you rejoin.', 10, 'alert')
				end
			end
		end,
		ExtraText = function()
			local total = 0
			for _, v in store.anticheat.Blocked do
				total += v
			end
			return total > 0 and total..' stopped' or ''
		end,
		Tooltip = 'Stops the game\'s client check from flagging you'
	})
	Notify = AntiBanwave:CreateToggle({
		Name = 'Notify',
		Default = true,
		Tooltip = 'Tells you what the anticheat tried to flag'
	})

	task.spawn(function()
		repeat task.wait(0.5) until vape.Loaded ~= false
		task.wait(1)
		if vape.Loaded and not userOff and not AntiBanwave.Enabled then
			AntiBanwave:Toggle()
		end
	end)
end)
