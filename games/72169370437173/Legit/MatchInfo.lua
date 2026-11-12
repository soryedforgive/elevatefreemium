run(function()
	local MatchInfo
	local label

	local function arena()
		local arenas = workspace:FindFirstChild('Arenas')
		local id = lplr.Character and lplr.Character:GetAttribute('MatchId')
		return arenas and type(id) == 'string' and id ~= '' and arenas:FindFirstChild(id)
	end

	MatchInfo = vape.Categories.Legit:CreateModule({
		Name = 'MatchInfo',
		Category = 'Hud',
		Function = function(callback)
			if callback then
				repeat
					local a = arena()
					local text = 'Lobby'
					if a then
						local team = lplr.Character:GetAttribute('Team') == 2 and 2 or 1
						local mine, theirs = a:GetAttribute('Score'..team) or 0, a:GetAttribute('Score'..(3 - team)) or 0
						local left = math.floor(math.max(0, (a:GetAttribute('PhaseEndsAt') or 0) - workspace:GetServerTimeNow()))
						text = string.format('Round %d  %d - %d  %s %d:%02d', math.floor(a:GetAttribute('Round') or 0), math.floor(mine), math.floor(theirs), tostring(a:GetAttribute('Phase') or ''), left // 60, left % 60)
					end
					if label.Text ~= text then
						label.Text = text
					end
					task.wait(0.25)
				until not MatchInfo.Enabled
			end
		end,
		Size = UDim2.fromOffset(220, 41),
		Tooltip = 'Shows the round, the score and the time left'
	})
	MatchInfo:CreateFont({
		Name = 'Font',
		Blacklist = 'Gotham',
		Function = function(val)
			label.FontFace = val
		end
	})
	MatchInfo:CreateColorSlider({
		Name = 'Colour',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			label.BackgroundTransparency = 1 - opacity
		end
	})
	label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.5
	label.TextSize = 15
	label.Font = Enum.Font.Gotham
	label.Text = 'Lobby'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = MatchInfo.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)
