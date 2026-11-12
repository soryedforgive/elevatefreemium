run(function()
	local StaffDetector
	local Mode
	local Profile
	local Users
	local GROUP, STAFF_RANK = 35136865, 200
	local uninjecting = false
	local checked = setmetatable({}, {__mode = 'k'})

	local function rankOf(plr)
		for _ = 1, 3 do
			local ok, rank = pcall(plr.GetRankInGroup, plr, GROUP)
			if ok then return rank end
			task.wait(1)
		end
		return 0
	end

	local function detected(plr, reason)
		notif('StaffDetector', 'Staff Detected ('..reason..'): '..plr.Name, 60, 'alert')
		if Mode.Value == 'Uninject' then
			if uninjecting then return end
			uninjecting = true
			task.spawn(function()
				vape:Uninject()
			end)
			game:GetService('StarterGui'):SetCore('SendNotification', {
				Title = 'StaffDetector',
				Text = 'Staff Detected\n'..plr.Name,
				Duration = 60
			})
		elseif Mode.Value == 'Leave' then
			task.wait(1)
			lplr:Kick('StaffDetector: '..plr.Name..' joined')
		elseif Mode.Value == 'Profile' then
			if vape.Profile ~= Profile.Value then
				vape.Save = function() end
				vape:Load(true, Profile.Value)
			end
		elseif Mode.Value == 'AutoConfig' then
			vape.Save = function() end
			for _, v in vape.Modules do
				if v.Enabled and v ~= StaffDetector then
					v:Toggle()
				end
			end
			for _, v in vape.Kits.Modules do
				if v.Enabled then
					v:Toggle()
				end
			end
		end
	end

	local function check(plr)
		if plr == lplr or checked[plr] then return end
		checked[plr] = true
		if not vape.Loaded then
			repeat
				task.wait()
			until vape.Loaded or vape.Loaded == nil
		end
		if not vape.Loaded or uninjecting then return end
		local listed = table.find(Users.ListEnabled, tostring(plr.UserId))
		local staff = listed or rankOf(plr) >= STAFF_RANK
		if staff and StaffDetector.Enabled and not uninjecting then
			detected(plr, listed and 'blacklisted_user' or 'staff_role')
		end
	end

	StaffDetector = vape.Categories.Utility:CreateModule({
		Name = 'StaffDetector',
		Function = function(callback)
			if callback then
				table.clear(checked)
				StaffDetector:Clean(playersService.PlayerAdded:Connect(check))
				for _, plr in playersService:GetPlayers() do
					task.spawn(check, plr)
				end
			end
		end,
		Tooltip = 'Detects staff in your server'
	})
	Mode = StaffDetector:CreateDropdown({
		Name = 'Mode',
		List = {'Uninject', 'Leave', 'Profile', 'AutoConfig', 'Notify'},
		Function = function(val)
			if Profile and Profile.Object then
				Profile.Object.Visible = val == 'Profile'
			end
		end
	})
	Profile = StaffDetector:CreateTextBox({
		Name = 'Profile',
		Default = 'default',
		Darker = true,
		Visible = false
	})
	Users = StaffDetector:CreateTextList({
		Name = 'Users',
		Placeholder = 'player (userid)'
	})
end)
