run(function()
	local StaffDetector
	local Leave
	local GROUP = 776581204
	local STAFF = {Mod = true, Admin = true, Dev = true, Analytics = true, Artist = true}
	local checked = setmetatable({}, {__mode = 'k'})

	local function check(plr)
		if plr == lplr or checked[plr] then return end
		checked[plr] = true
		task.spawn(function()
			local ok, role = pcall(plr.GetRoleInGroup, plr, GROUP)
			if not (ok and STAFF[role]) or not StaffDetector.Enabled then return end
			notif('StaffDetector', plr.DisplayName..' (@'..plr.Name..') is '..role..' staff and is in your server', 15, 'alert')
			if Leave.Enabled then
				task.wait(1)
				lplr:Kick('StaffDetector: '..role..' '..plr.Name..' joined')
			end
		end)
	end

	StaffDetector = vape.Categories.Utility:CreateModule({
		Name = 'StaffDetector',
		Function = function(callback)
			if callback then
				table.clear(checked)
				for _, plr in playersService:GetPlayers() do
					check(plr)
				end
				StaffDetector:Clean(playersService.PlayerAdded:Connect(check))
			end
		end,
		Tooltip = 'Detects staff in your server'
	})
	Leave = StaffDetector:CreateToggle({
		Name = 'Leave',
		Tooltip = 'Leaves the game when one is found'
	})
end)
