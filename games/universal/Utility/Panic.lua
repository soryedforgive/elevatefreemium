run(function()
	local Panic
	local armedUntil = 0

	local function everyModule()
		local lists = {vape.Modules}
		if vape.Legit and vape.Legit.Modules then
			table.insert(lists, vape.Legit.Modules)
		end
		if vape.Kits and vape.Kits.Modules then
			table.insert(lists, vape.Kits.Modules)
		end
		return lists
	end

	Panic = vape.Categories.Utility:CreateModule({
		Name = 'Panic',
		Function = function(callback)
			if callback then
				local now = tick()
				if now > armedUntil then
					armedUntil = now + 8
					notif('Panic', 'Panic is armed. Activate Panic again within 8 seconds to turn every module off.', 8, 'warning')
					Panic:Toggle()
					return
				end
				armedUntil = 0
				for _, list in everyModule() do
					local enabled = {}
					for _, v in list do
						if v ~= Panic and v.Enabled then
							table.insert(enabled, v)
						end
					end
					for _, v in enabled do
						if v.Enabled then
							pcall(v.Toggle, v)
						end
					end
				end
				if Panic.Enabled then
					Panic:Toggle()
				end
			end
		end,
		Tooltip = 'Press twice to turn off every enabled module',
	})
end)
