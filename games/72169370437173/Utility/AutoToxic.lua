run(function()
	local AutoToxic
	local GG, GGDelay
	local TrollTriggers
	local trollCooldown = 0
	local dead = false
	local Toggles, Actions, Lists, Emotes, Delays, said = {}, {}, {}, {}, {}, {}
	local presets = {}
	local myId = 'p'..lplr.UserId

	local function doSend(text, delay)
		if not text or text == '' then return end
		local wait = delay and delay.Value or 0
		local function push()
			local channel = textChatService.ChatInputBarConfiguration.TargetTextChannel
			if not channel then return end
			local ok, free = pcall(textChatService.CanUserChatAsync, textChatService, lplr.UserId)
			if not ok or free then
				channel:SendAsync(text)
			elseif presets[text] or presets[text == 'gg' and 'Good game' or 'So close'] then
				channel:SendPresetAsync(presets[text] or presets[text == 'gg' and 'Good game' or 'So close'])
			end
		end
		if wait > 0 then
			task.delay(wait, function() pcall(push) end)
		else
			task.spawn(pcall, push)
		end
	end

	local DEFAULT_EMOTES = {'wave', 'point', 'dance', 'dance2', 'dance3', 'laugh', 'cheer'}
	local function emoteList()
		local list = {'None'}
		pcall(function()
			local hum = lplr.Character and lplr.Character:FindFirstChildOfClass('Humanoid')
			local description = hum and hum:FindFirstChildOfClass('HumanoidDescription')
			for name in description and description:GetEmotes() or {} do
				table.insert(list, name)
			end
		end)
		for _, name in DEFAULT_EMOTES do
			if not table.find(list, name) then
				table.insert(list, name)
			end
		end
		return list
	end
	local function playEmote(name)
		local character = lplr.Character
		local hum = character and character:FindFirstChildOfClass('Humanoid')
		if not hum or hum.Health <= 0 then return end
		local ok, played = pcall(hum.PlayEmote, hum, name)
		if ok and played then return end
		local animate = character:FindFirstChild('Animate')
		local bindable = animate and animate:FindFirstChild('PlayEmote')
		if bindable then
			pcall(bindable.Invoke, bindable, name)
		end
	end

	local function emote(name)
		local choice = Emotes[name] and Emotes[name].Value
		if not choice or choice == 'None' then return end
		task.delay(Delays[name].Value, function()
			local deadline = tick() + 10
			while not entitylib.isAlive and tick() < deadline do
				task.wait(0.25)
			end
			pcall(playEmote, choice)
		end)
	end

	local function message(name, obj, default)
		local tab = Lists[name].ListEnabled
		local custommsg = #tab > 0 and tab[math.random(1, #tab)] or default
		if not custommsg then return end
		for _ = 1, #tab > 1 and 8 or 0 do
			if custommsg ~= said[name] then break end
			custommsg = tab[math.random(1, #tab)]
		end
		said[name] = custommsg
		doSend((custommsg:gsub('<obj>', obj or '')), Delays[name])
	end

	local function trigger(name, obj, default)
		if not Toggles[name].Enabled then return end
		local action = Actions[name].Value
		if action ~= 'Emote' then
			message(name, obj, default)
		end
		if action ~= 'Message' then
			emote(name)
		end
	end

	AutoToxic = vape.Categories.Utility:CreateModule({
		Name = 'AutoToxic',
		Function = function(callback)
			if callback then
				dead = false
				AutoToxic:Clean(entitylib.Events.LocalAdded:Connect(function()
					dead = false
				end))

				AutoToxic:Clean(vapeEvents.Elimination.Event:Connect(function(data)
					if data.victimId == myId then
						if not dead and data.killerId and data.killerId ~= myId then
							dead = true
							trigger('Death', data.killerName, 'my gaming chair subscription expired :( | <obj>')
						end
					elseif data.killerId == myId then
						trigger('Kill', data.victimName, 'vxp on top | <obj>')
					end
				end))
				AutoToxic:Clean(vapeEvents.MatchEnded.Event:Connect(function(won)
					if GG.Enabled then
						doSend('gg', GGDelay)
					end
					if won then
						trigger('Win', nil, 'yall garbage')
					end
				end))

				local function handleIncoming(speakerName, text, speakerUserId)
					if not Toggles.Troll.Enabled or not text or text == '' then return end
					if speakerUserId and speakerUserId == lplr.UserId then return end
					if speakerName and speakerName == lplr.Name then return end
					if tick() < trollCooldown then return end
					local lower = text:lower()
					for _, phrase in TrollTriggers.ListEnabled do
						if phrase ~= '' and lower:find(phrase:lower(), 1, true) then
							trollCooldown = tick() + 6
							task.spawn(trigger, 'Troll', speakerName, 'mad cause bad | <obj>')
							break
						end
					end
				end

				if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
					AutoToxic:Clean(textChatService.MessageReceived:Connect(function(msg)
						local src = msg.TextSource
						handleIncoming(src and src.Name, msg.Text, src and src.UserId)
					end))
				else
					pcall(function()
						AutoToxic:Clean(replicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(data)
							if type(data) == 'table' then
								handleIncoming(data.FromSpeaker, data.Message, nil)
							end
						end))
					end)
				end
			end
		end,
		Tooltip = 'Sends a message or plays an emote after a certain action'
	})

	local function refresh(key)
		local toggle, action = Toggles[key], Actions[key]
		local on = toggle and toggle.Enabled
		local value = action and action.Value or 'Message'
		if action then action.Object.Visible = on end
		if Lists[key] then Lists[key].Object.Visible = on and value ~= 'Emote' end
		if Emotes[key] then Emotes[key].Object.Visible = on and value ~= 'Message' end
		if Delays[key] then Delays[key].Object.Visible = on end
		if key == 'Troll' and TrollTriggers then TrollTriggers.Object.Visible = on end
	end

	local function event(key, label, tooltip, extra)
		Toggles[key] = AutoToxic:CreateToggle({
			Name = label..' ',
			Tooltip = tooltip,
			Function = function()
				refresh(key)
			end
		})
		if extra then extra() end
		Actions[key] = AutoToxic:CreateDropdown({
			Name = label..' Action',
			List = {'Message', 'Emote', 'Both'},
			Default = 'Message',
			Darker = true,
			Visible = false,
			Tooltip = 'Message - sends a random line from the list\nEmote - plays the chosen emote\nBoth - does both',
			Function = function()
				refresh(key)
			end
		})
		Emotes[key] = AutoToxic:CreateDropdown({
			Name = label..' Emote',
			List = emoteList(),
			Default = 'None',
			Darker = true,
			Visible = false,
			Tooltip = 'Emote to play when this happens'
		})
		Lists[key] = AutoToxic:CreateTextList({
			Name = key == 'Troll' and 'Troll Replies' or label,
			Tooltip = key == 'Troll' and 'Replies to send, <obj> is the accuser\'s name' or 'One of these is picked at random, <obj> is the other player or team',
			Default = key == 'Troll' and {'mad cause bad | <obj>', 'skill issue <obj>', 'cry about it <obj>', 'not my fault youre bad', 'imagine losing to a "hacker" lol'} or nil,
			Darker = true,
			Visible = false
		})
		Delays[key] = AutoToxic:CreateSlider({
			Name = label..' Delay',
			Min = key == 'Troll' and 0.5 or 0,
			Max = 10,
			Default = key == 'Troll' and 1.5 or 0,
			Decimal = 10,
			Suffix = 's',
			Darker = true,
			Visible = false,
			Tooltip = 'How long to wait before acting, 0 for instant'
		})
		refresh(key)
	end

	GG = AutoToxic:CreateToggle({
		Name = 'AutoGG',
		Default = true,
		Tooltip = 'Says gg when the match ends, won or lost',
		Function = function(callback)
			if GGDelay then GGDelay.Object.Visible = callback end
		end
	})
	GGDelay = AutoToxic:CreateSlider({
		Name = 'AutoGG Delay',
		Min = 0,
		Max = 10,
		Default = 0,
		Decimal = 10,
		Suffix = 's',
		Darker = true,
		Tooltip = 'How long to wait before saying gg, 0 for instant'
	})
	GGDelay.Object.Visible = GG.Enabled
	event('Kill', 'Kill', 'When you kill someone')
	event('Win', 'Win', 'When your team wins the match')
	event('Death', 'Death', 'When someone kills you')
	event('Troll', 'Troll', 'Replies when someone calls you a hacker or cheater in chat', function()
		TrollTriggers = AutoToxic:CreateTextList({
			Name = 'Troll Triggers',
			Tooltip = 'Phrases that trigger a reply, matched anywhere in their message',
			Default = {'hacker', 'hacks', 'hacking', 'hax', 'cheater', 'cheating', 'cheat', 'exploiter', 'exploiting', 'aimbot'},
			Darker = true,
			Visible = false
		})
	end)

	task.spawn(pcall, function()
		for _, group in textChatService:GetPresetsAsync().categoryGroups do
			for _, category in group.categories do
				for _, msg in category.messages do
					presets[msg.value] = msg.presetId
				end
			end
		end
	end)
end)
