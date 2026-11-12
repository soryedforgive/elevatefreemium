run(function()
	local AutoUpgrade
	local attempted = {}

	AutoUpgrade = vape.Categories.Inventory:CreateModule({
		Name = 'AutoUpgrade',
		Function = function(callback)
			if callback then
				repeat
					local economy = tribes.Economy
					if economy and not inMatch() and economy.ReadyList then
						local ok, ready = pcall(economy.ReadyList)
						if ok and type(ready) == 'table' then
							local now = os.clock()
							for _, item in ready do
								if type(item) == 'string' and now >= (attempted[item] or 0) then
									attempted[item] = now + 1.5
									pcall(economy.Upgrade, item)
									break
								end
							end
						end
					end
					task.wait(0.3)
				until not AutoUpgrade.Enabled
			else
				table.clear(attempted)
			end
		end,
		Tooltip = 'Upgrades your gear in the lobby when ready'
	})
end)
