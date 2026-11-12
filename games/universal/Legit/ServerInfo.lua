run(function()
    local ServerInfo
    local Uptime
    local label

    local function uptimeText()
	local seconds = math.max(math.floor(workspace.DistributedGameTime), 0)
	local hours, minutes = seconds // 3600, (seconds % 3600) // 60
	if hours > 0 then
		return string.format('%dh %02dm', hours, minutes)
	end
	return string.format('%dm %02ds', minutes, seconds % 60)
    end

    ServerInfo = vape.Categories.Legit:CreateModule({
	Name = 'ServerInfo',
	Category = 'Hud',
	Function = function(callback)
		if callback then
			local lastText
			repeat
				local text = #playersService:GetPlayers()..'/'..playersService.MaxPlayers..' players'
				if Uptime.Enabled then
					text ..= ' | '..uptimeText()
				end
				if text ~= lastText then
					lastText = text
					label.Text = text
				end
				task.wait(1)
			until not ServerInfo.Enabled
		end
	end,
	Size = UDim2.fromOffset(180, 41),
	Tooltip = 'Shows the player count and how long the server has run',
    })
    ServerInfo:CreateFont({
	Name = 'Font',
	Blacklist = 'Gotham',
	Function = function(val)
		label.FontFace = val
	end,
    })
    ServerInfo:CreateColorSlider({
	Name = 'Colour',
	DefaultValue = 0,
	DefaultOpacity = 0.5,
	Function = function(hue, sat, val, opacity)
		label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
		label.BackgroundTransparency = 1 - opacity
	end,
    })
    Uptime = ServerInfo:CreateToggle({
	Name = 'Server age',
	Default = true,
	Tooltip = 'Adds how long the server has been running',
    })
    ServerInfo:CreateButton({
	Name = 'Copy server ID',
	Tooltip = 'Copies this server\'s ID so a friend can join',
	Function = function()
		local copied = setclipboard and pcall(setclipboard, game.JobId)
		notif('ServerInfo', copied and 'Server ID copied.' or 'Your executor cannot copy to the clipboard.', 4, copied and 'info' or 'warning')
	end,
    })
    label = Instance.new('TextLabel')
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.5
    label.TextSize = 15
    label.Font = Enum.Font.Gotham
    label.Text = '0/0 players'
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundColor3 = Color3.new()
    label.Parent = ServerInfo.Children
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = label
end)
