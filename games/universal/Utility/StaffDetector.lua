run(function()
    local StaffDetector
    local Mode
    local Profile
    local Users
    local Group
    local Role
    local uninjecting = false

    local function getRole(plr, id)
	local suc, res
	for _ = 1, 3 do
		suc, res = pcall(function()
			return plr:GetRankInGroup(id)
		end)
		if suc then
			break
		end
	end
	return suc and res or 0
    end

    local function getLowestStaffRole(roles)
	local member = math.huge
	for _, v in roles do
		if v.Rank > 0 and v.Rank < member then
			member = v.Rank
		end
	end
	local highest = math.huge
	for _, v in roles do
		local low = v.Name:lower()
		local staff = low:find('%f[%a]admin') or low:find('%f[%a]dev') or (low:find('%f[%a]mod') and not low:find('%f[%a]model'))
		if staff and v.Rank > member and v.Rank < highest then
			highest = v.Rank
		end
	end
	return highest, member
    end

    local function playerAdded(plr)
	if not vape.Loaded then
		repeat
			task.wait()
		until vape.Loaded or vape.Loaded == nil
	end
	if not vape.Loaded or uninjecting or plr == lplr then
		return
	end

	local user = table.find(Users.ListEnabled, tostring(plr.UserId))
	if user or getRole(plr, tonumber(Group.Value) or 0) >= (tonumber(Role.Value) or math.huge) then
		notif(
			'StaffDetector',
			'Staff Detected (' .. (user and 'blacklisted_user' or 'staff_role') .. '): ' .. plr.Name,
			60,
			'alert'
		)
		whitelist.customtags[plr.Name] = { { text = 'GAME STAFF', color = Color3.new(1, 0, 0) } }

		if Mode.Value == 'Uninject' then
			if uninjecting then
				return
			end
			uninjecting = true
			task.spawn(function()
				vape:Uninject()
			end)
			game:GetService('StarterGui'):SetCore('SendNotification', {
				Title = 'StaffDetector',
				Text = 'Staff Detected\n' .. plr.Name,
				Duration = 60,
			})
		elseif Mode.Value == 'ServerHop' then
			serverHop()
		elseif Mode.Value == 'Profile' then
			if vape.Profile ~= Profile.Value then
				pcall(function()
					vape:Save()
				end)
				vape.Profile = Profile.Value
				vape:Load(true, Profile.Value)
			end
		elseif Mode.Value == 'AutoConfig' then
			for _, v in vape.Modules do
				if v.Enabled then
					v:Toggle()
				end
			end
		end
	end
    end

    StaffDetector = vape.Categories.Utility:CreateModule({
	Name = 'StaffDetector',
	Function = function(callback)
		if callback then
			if Group.Value == '' or Role.Value == '' then
				local placeinfo = { Creator = { CreatorTargetId = tonumber(Group.Value) } }
				if Group.Value == '' then
					placeinfo = marketplaceService:GetProductInfo(game.PlaceId)
					if placeinfo.Creator.CreatorType ~= 'Group' then
						local desc = placeinfo.Description:split('\n')
						for _, str in desc do
							local _, begin = str:find('roblox.com/groups/')
							if begin then
								local endof = str:find('/', begin + 1)
								placeinfo = {
									Creator = {
										CreatorType = 'Group',
										CreatorTargetId = str:sub(begin + 1, endof - 1),
									},
								}
							end
						end
					end

					if placeinfo.Creator.CreatorType ~= 'Group' then
						notif('StaffDetector', 'Automatic Setup Failed (no group detected)', 60, 'warning')
						return
					end
				end

				local groupinfo = groupService:GetGroupInfoAsync(placeinfo.Creator.CreatorTargetId)
				Group:SetValue(placeinfo.Creator.CreatorTargetId)
				Role:SetValue(getLowestStaffRole(groupinfo.Roles))
			else
				local ok, groupinfo = pcall(groupService.GetGroupInfoAsync, groupService, tonumber(Group.Value))
				if ok and groupinfo and groupinfo.Roles then
					local staff, member = getLowestStaffRole(groupinfo.Roles)
					if (tonumber(Role.Value) or 0) <= member then
						Role:SetValue(staff)
					end
				end
			end

			if Group.Value == '' or Role.Value == '' then
				return
			end

			StaffDetector:Clean(playersService.PlayerAdded:Connect(playerAdded))
			for _, v in playersService:GetPlayers() do
				task.spawn(playerAdded, v)
			end
		end
	end,
	Tooltip = 'Detects staff in your server',
    })
    Mode = StaffDetector:CreateDropdown({
	Name = 'Mode',
	List = { 'Uninject', 'ServerHop', 'Profile', 'AutoConfig', 'Notify' },
	Function = function(val)
		if Profile.Object then
			Profile.Object.Visible = val == 'Profile'
		end
	end,
    })
    Profile = StaffDetector:CreateTextBox({
	Name = 'Profile',
	Default = 'default',
	Darker = true,
	Visible = false,
    })
    Users = StaffDetector:CreateTextList({
	Name = 'Users',
	Placeholder = 'player (userid)',
    })
    Group = StaffDetector:CreateTextBox({
	Name = 'Group',
	Placeholder = 'Group Id',
    })
    Role = StaffDetector:CreateTextBox({
	Name = 'Role',
	Placeholder = 'Role Rank',
    })
end)
