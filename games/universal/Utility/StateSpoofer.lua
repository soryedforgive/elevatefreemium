run(function()
	local StateSpoofer
	local State
	local Mode

	local hook
	local heartbeat

	local function rakNetAvailable()
		local ok, found = pcall(function()
			return raknet ~= nil and raknet.add_send_hook ~= nil and raknet.remove_send_hook ~= nil
		end)
		return ok and found == true
	end

	local function removeHook()
		if hook then
			pcall(raknet.remove_send_hook, hook)
			hook = nil
		end
		if heartbeat then
			heartbeat:Disconnect()
			heartbeat = nil
		end
	end

	local function restart()
		if StateSpoofer and StateSpoofer.Enabled then
			StateSpoofer:Toggle()
			StateSpoofer:Toggle()
		end
	end

	StateSpoofer = vape.Categories.Utility:CreateModule({
		Name = 'StateSpoofer',
		Function = function(callback)
			removeHook()
			if not callback then return end

			if Mode.Value == 'RakNet' then
				if not rakNetCheck('StateSpoofer') then
					StateSpoofer:Toggle()
					return
				end

				hook = function(packet)
					pcall(function()
						local data = packet.AsBuffer
						local packetId = packet.AsArray and packet.AsArray[1]
						if not packetId and data and buffer.len(data) > 0 then
							packetId = buffer.readu8(data, 0)
						end
						if packetId == 0x1b and data and buffer.len(data) >= 26 then
							local state = Enum.HumanoidStateType[State.Value]
							if state then
								buffer.writeu8(data, 25, state.Value + 32)
								packet:SetData(data)
							end
						end
					end)
				end

				raknet.add_send_hook(hook)
			else
				if type(sethiddenproperty) ~= 'function' then
					notif('StateSpoofer', 'Your executor has no sethiddenproperty, so Direct mode cannot work here.', 6, 'warning')
					StateSpoofer:Toggle()
					return
				end

				heartbeat = runService.Heartbeat:Connect(function()
					if entitylib.isAlive then
						local state = Enum.HumanoidStateType[State.Value]
						if state then
							pcall(sethiddenproperty, entitylib.character.Humanoid, 'NetworkHumanoidState', state.Value)
						end
					end
				end)
			end
		end,
		Tooltip = 'Changes the character state others see'
	})

	local states = {}
	for _, v in Enum.HumanoidStateType:GetEnumItems() do
		if v.Name ~= 'None' then
			table.insert(states, v.Name)
		end
	end

	State = StateSpoofer:CreateDropdown({
		Name = 'Humanoid State',
		List = states
	})

	Mode = StateSpoofer:CreateDropdown({
		Name = 'Mode',
		List = {'RakNet', 'Direct'},
		Default = rakNetAvailable() and 'RakNet' or 'Direct',
		Function = restart,
		Tooltip = 'How it changes the state others see'
	})

	vape:Clean(removeHook)
end)
