run(function()
	local StreamerMode
	local Name
	local FakeName
	local Rank
	local RankName
	local Board
	local BoardRank
	local BoardScore
	local changed = {}

	local function rankImage()
		for _, v in bedfight.RanksData.Ranks do
			if v.Name == RankName.Value then
				return v.Image
			end
		end
	end

	local function ownTag()
		local gui = lplr.PlayerGui:FindFirstChild('PlayersNameTagGui')
		local head = lplr.Character and lplr.Character:FindFirstChild('Head')
		for _, tag in gui and head and gui:GetChildren() or {} do
			if tag:IsA('BillboardGui') and tag.Adornee == head then
				return tag:FindFirstChild('BottomFrame')
			end
		end
	end

	local function set(obj, prop, value)
		if obj[prop] == value then return end
		changed[obj] = changed[obj] or {}
		if changed[obj][prop] == nil then
			changed[obj][prop] = obj[prop]
		end
		obj[prop] = value
	end

	local function isOwnName(text)
		return text == lplr.Name or text == lplr.DisplayName or text == '@'..lplr.Name
	end

	local function boards()
		local lobby = bedfight.Lobby.Value
		local folder = lobby and lobby:FindFirstChild('Leaderboards')
		local list = {}
		for _, kind in folder and folder:GetChildren() or {} do
			for _, board in kind:GetChildren() do
				local frame = board:FindFirstChild('Bottom') and board.Bottom:FindFirstChild('BottomGui') and board.Bottom.BottomGui:FindFirstChild('Frame')
				if frame then
					table.insert(list, frame)
				end
			end
		end
		return list
	end

	StreamerMode = vape.Categories.Render:CreateModule({
		Name = 'StreamerMode',
		Function = function(callback)
			if callback then
				StreamerMode:Clean(lplr.PlayerGui.DescendantAdded:Connect(function(v)
					if not v:IsA('TextLabel') or not Name.Enabled or v:IsDescendantOf(vape.gui) then return end
					task.defer(function()
						if StreamerMode.Enabled and v.Parent and isOwnName(v.Text) then
							set(v, 'Text', FakeName.Value)
						end
					end)
				end))

				repeat
					local tag = ownTag()
					if tag then
						local label, icon = tag:FindFirstChild('NameLabel'), tag:FindFirstChild('RankIcon')
						if label and Name.Enabled and FakeName.Value ~= '' then
							set(label, 'Text', FakeName.Value)
						end
						local image = icon and Rank.Enabled and rankImage()
						if image then
							set(icon, 'Image', image)
						end
					end
					if Board.Enabled then
						for _, frame in boards() do
							local text, value = frame:FindFirstChild('TextLabel'), frame:FindFirstChild('ValueLabel')
							if text and value then
								set(text, 'Text', '#'..BoardRank.Value..' You:')
								set(value, 'Text', tostring(BoardScore.Value))
							end
						end
					end
					task.wait(0.25)
				until not StreamerMode.Enabled
			else
				for obj, props in changed do
					for prop, value in props do
						pcall(function()
							obj[prop] = value
						end)
					end
				end
				table.clear(changed)
			end
		end,
		Tooltip = 'Hides who you are on your screen'
	})
	Name = StreamerMode:CreateGroup({
		Name = 'Hide name',
		Default = true,
	})
	FakeName = Name:CreateTextBox({
		Name = 'Shown name',
		Default = 'Player',
		Darker = true
	})
	Rank = StreamerMode:CreateGroup({
		Name = 'Change rank icon',
	})
	local ranks = {}
	for _, v in bedfight.RanksData.Ranks do
		table.insert(ranks, v.Name)
	end
	RankName = Rank:CreateDropdown({
		Name = 'Rank',
		List = ranks,
		Darker = true
	})
	Board = StreamerMode:CreateGroup({
		Name = 'Change leaderboard row',
		Function = function(callback)
			if BoardRank then
			end
		end,
		Tooltip = 'Your own row under the lobby leaderboards'
	})
	BoardRank = Board:CreateSlider({
		Name = 'Position',
		Min = 1,
		Max = 100,
		Default = 1,
		Darker = true
	})
	BoardScore = Board:CreateSlider({
		Name = 'Score',
		Min = 0,
		Max = 9999,
		Default = 9999,
		Darker = true
	})
end)
