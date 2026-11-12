run(function()
	local BetterChat
	local Transparency
	local FontSize
	local Timestamps
	local HideDefault
	local MaxMessages
	local SavedPosition
	local starterGui = cloneref(game:GetService('StarterGui'))
	local window, scroller, input, layout
	local lines = {}
	local defaultState
	local DEFAULT_POSITION = '16,220'

	local function escape(text)
		return (tostring(text):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'))
	end

	local function stripTags(text)
		return (tostring(text):gsub('<[^>]->', ''))
	end

	local function hex(c)
		return string.format('#%02x%02x%02x', math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
	end

	local function nameColor(plr)
		if plr and plr.Team then
			return plr.TeamColor.Color
		end
		return Color3.fromRGB(220, 220, 220)
	end

	local function legacy()
		return textChatService.ChatVersion == Enum.ChatVersion.LegacyChatService
	end

	local function applyPosition()
		if not window then return end
		local x, y = tostring(SavedPosition.Value):match('^(%-?%d+),(%-?%d+)$')
		window.Position = UDim2.fromOffset(tonumber(x) or 16, tonumber(y) or 220)
	end

	local function restyle()
		if not window then return end
		window.BackgroundTransparency = Transparency.Value
		for _, label in lines do
			label.TextSize = FontSize.Value
		end
		input.TextSize = FontSize.Value
	end

	local function atBottom()
		return scroller.CanvasPosition.Y >= scroller.AbsoluteCanvasSize.Y - scroller.AbsoluteSize.Y - 4
	end

	local function push(speaker, text, prefixColor)
		if not scroller then return end
		local follow = atBottom()
		local label = Instance.new('TextLabel')
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -6, 0, 0)
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.TextWrapped = true
		label.RichText = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.6
		label.TextSize = FontSize.Value
		label.Font = Enum.Font.GothamMedium
		local stamp = Timestamps.Enabled and '<font color="#9a9a9a">['..os.date('%H:%M')..']</font> ' or ''
		local who = speaker and ('<font color="'..hex(prefixColor or Color3.new(1, 1, 1))..'"><b>'..escape(speaker)..'</b></font>: ') or ''
		label.Text = stamp..who..escape(stripTags(text))
		label.LayoutOrder = (lines[#lines] and lines[#lines].LayoutOrder or 0) + 1
		label.Parent = scroller
		table.insert(lines, label)
		while #lines > MaxMessages.Value do
			table.remove(lines, 1):Destroy()
		end
		if follow then
			task.defer(function()
				if scroller then
					scroller.CanvasPosition = Vector2.new(0, scroller.AbsoluteCanvasSize.Y)
				end
			end)
		end
	end

	local function send(text)
		if text:gsub('%s', '') == '' then return end
		if legacy() then
			local events = replicatedStorage:FindFirstChild('DefaultChatSystemChatEvents')
			local request = events and events:FindFirstChild('SayMessageRequest')
			if request then
				request:FireServer(text, 'All')
			end
		else
			local channels = textChatService:FindFirstChild('TextChannels')
			local config = textChatService:FindFirstChildOfClass('ChatInputBarConfiguration')
			local channel = config and config.TargetTextChannel or channels and channels:FindFirstChild('RBXGeneral')
			if channel then
				task.spawn(pcall, channel.SendAsync, channel, text)
			end
		end
	end

	local function setDefault(hidden)
		if hidden then
			if defaultState then return end
			defaultState = {}
			if legacy() then
				defaultState.Legacy = starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
				pcall(starterGui.SetCoreGuiEnabled, starterGui, Enum.CoreGuiType.Chat, false)
			else
				for _, class in {'ChatWindowConfiguration', 'ChatInputBarConfiguration'} do
					local config = textChatService:FindFirstChildOfClass(class)
					if config then
						defaultState[class] = config.Enabled
						config.Enabled = false
					end
				end
			end
		elseif defaultState then
			if defaultState.Legacy ~= nil then
				pcall(starterGui.SetCoreGuiEnabled, starterGui, Enum.CoreGuiType.Chat, defaultState.Legacy)
			end
			for _, class in {'ChatWindowConfiguration', 'ChatInputBarConfiguration'} do
				local config = textChatService:FindFirstChildOfClass(class)
				if config and defaultState[class] ~= nil then
					config.Enabled = defaultState[class]
				end
			end
			defaultState = nil
		end
	end

	local function build()
		window = Instance.new('Frame')
		window.Name = 'BetterChat'
		window.Size = UDim2.fromOffset(380, 230)
		window.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		window.BorderSizePixel = 0
		window.Active = true
		window.Parent = vape.gui
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = window
		local bar = Instance.new('TextLabel')
		bar.Name = 'Bar'
		bar.Size = UDim2.new(1, 0, 0, 20)
		bar.BackgroundTransparency = 1
		bar.Text = '  Chat'
		bar.TextXAlignment = Enum.TextXAlignment.Left
		bar.TextColor3 = Color3.fromRGB(180, 180, 180)
		bar.TextSize = 12
		bar.Font = Enum.Font.GothamBold
		bar.Active = true
		bar.Parent = window
		scroller = Instance.new('ScrollingFrame')
		scroller.Size = UDim2.new(1, -10, 1, -54)
		scroller.Position = UDim2.fromOffset(5, 20)
		scroller.BackgroundTransparency = 1
		scroller.BorderSizePixel = 0
		scroller.ScrollBarThickness = 3
		scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroller.CanvasSize = UDim2.new()
		scroller.Parent = window
		layout = Instance.new('UIListLayout')
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 2)
		layout.Parent = scroller
		input = Instance.new('TextBox')
		input.Size = UDim2.new(1, -10, 0, 26)
		input.Position = UDim2.new(0, 5, 1, -31)
		input.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
		input.BackgroundTransparency = 0.2
		input.BorderSizePixel = 0
		input.ClearTextOnFocus = false
		input.PlaceholderText = 'Press / to chat'
		input.Text = ''
		input.TextXAlignment = Enum.TextXAlignment.Left
		input.TextColor3 = Color3.new(1, 1, 1)
		input.TextSize = FontSize.Value
		input.Font = Enum.Font.Gotham
		input.Parent = window
		local inputCorner = Instance.new('UICorner')
		inputCorner.CornerRadius = UDim.new(0, 4)
		inputCorner.Parent = input
		local padding = Instance.new('UIPadding')
		padding.PaddingLeft = UDim.new(0, 6)
		padding.Parent = input

		BetterChat:Clean(input.FocusLost:Connect(function(enter)
			if enter then
				send(input.Text)
				input.Text = ''
			end
		end))
		local dragging, dragStart, startPos
		BetterChat:Clean(bar.InputBegan:Connect(function(io)
			if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
				dragging, dragStart, startPos = true, io.Position, window.Position
			end
		end))
		BetterChat:Clean(inputService.InputChanged:Connect(function(io)
			if dragging and (io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch) then
				local delta = io.Position - dragStart
				window.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
			end
		end))
		BetterChat:Clean(inputService.InputEnded:Connect(function(io)
			if dragging and (io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch) then
				dragging = false
				SavedPosition:SetValue(window.Position.X.Offset..','..window.Position.Y.Offset)
			end
		end))
		applyPosition()
		restyle()
	end

	local function listen()
		if legacy() then
			local events = replicatedStorage:FindFirstChild('DefaultChatSystemChatEvents')
			local done = events and events:FindFirstChild('OnMessageDoneFiltering')
			if done then
				BetterChat:Clean(done.OnClientEvent:Connect(function(data)
					if type(data) ~= 'table' then return end
					local plr = data.FromSpeaker and playersService:FindFirstChild(data.FromSpeaker)
					push(data.FromSpeaker, data.Message or '', nameColor(plr))
				end))
			else
				local function hook(plr)
					BetterChat:Clean(plr.Chatted:Connect(function(message)
						push(plr.DisplayName, message, nameColor(plr))
					end))
				end
				for _, plr in playersService:GetPlayers() do
					hook(plr)
				end
				BetterChat:Clean(playersService.PlayerAdded:Connect(hook))
			end
		else
			BetterChat:Clean(textChatService.MessageReceived:Connect(function(message)
				local source = message.TextSource
				local plr = source and playersService:GetPlayerByUserId(source.UserId)
				if plr then
					push(plr.DisplayName, message.Text, nameColor(plr))
				else
					local prefix = stripTags(message.PrefixText or '')
					push(prefix ~= '' and prefix:gsub(':%s*$', '') or nil, message.Text, Color3.fromRGB(255, 210, 120))
				end
			end))
		end
	end

	BetterChat = vape.Categories.Utility:CreateModule({
		Name = 'BetterChat',
		Function = function(callback)
			if callback then
				build()
				listen()
				setDefault(HideDefault.Enabled)
				BetterChat:Clean(inputService.InputBegan:Connect(function(io, processed)
					if processed or io.KeyCode ~= Enum.KeyCode.Slash or not HideDefault.Enabled then return end
					task.defer(function()
						if input then
							input:CaptureFocus()
							input.Text = ''
						end
					end)
				end))
			else
				setDefault(false)
				if window then
					window:Destroy()
				end
				window, scroller, input, layout = nil, nil, nil, nil
				table.clear(lines)
			end
		end,
		Tooltip = 'A movable chat window with timestamps and team colours'
	})
	Transparency = BetterChat:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Default = 0.4,
		Decimal = 100,
		Function = restyle
	})
	FontSize = BetterChat:CreateSlider({
		Name = 'Font size',
		Min = 10,
		Max = 22,
		Default = 14,
		Function = restyle
	})
	Timestamps = BetterChat:CreateToggle({
		Name = 'Timestamps',
		Default = true
	})
	HideDefault = BetterChat:CreateToggle({
		Name = 'Hide default chat',
		Default = true,
		Function = function(callback)
			if BetterChat.Enabled then
				setDefault(callback)
			end
		end,
		Tooltip = 'Hides the default chat while this window is open'
	})
	MaxMessages = BetterChat:CreateSlider({
		Name = 'Max messages',
		Min = 20,
		Max = 300,
		Default = 100,
		Function = function(val)
			while #lines > val do
				table.remove(lines, 1):Destroy()
			end
		end
	})
	SavedPosition = BetterChat:CreateTextBox({
		Name = 'Window position',
		Default = DEFAULT_POSITION,
		Visible = false,
		Function = applyPosition
	})
end)
