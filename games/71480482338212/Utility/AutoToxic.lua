run(function()
	local AutoToxic
	local GG, GGDelay
	local TrollTriggers
	local trollCooldown = 0
	local dead = false
	local Toggles, Actions, Lists, Emotes, Delays, said = {}, {}, {}, {}, {}, {}
	local textChatService = cloneref(game:GetService('TextChatService'))

	local function doSend(text, delay)
		if not text or text == '' then return end
		local wait = delay and delay.Value or 0
		local function push()
			if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
				textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(text)
			else
				replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(text, 'All')
			end
		end
		if wait > 0 then
			task.delay(wait, function() pcall(push) end)
		else
			pcall(push)
		end
	end

	local function emoteList()
		local list = {'None'}
		local folder = lplr:FindFirstChild('EmoteWheel')
		for _, slot in folder and folder:GetChildren() or {} do
			if slot:IsA('StringValue') and slot.Value ~= '' and not table.find(list, slot.Value) then
				table.insert(list, slot.Value)
			end
		end
		return list
	end
	local function playEmote(name)
		local folder = lplr:FindFirstChild('EmoteWheel')
		for _, slot in folder and folder:GetChildren() or {} do
			if slot:IsA('StringValue') and slot.Value == name then
				bedfight.Signals.PlayEmote:Fire(slot.Name)
				fireRemote('PlayEmote', tonumber(slot.Name) or slot.Name)
				return
			end
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

	local function bedOf(team)
		local container = workspace:FindFirstChild('BedsContainer')
		for _, bed in container and container:GetChildren() or {} do
			if bed:GetAttribute('Team') == team then
				return bed
			end
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

				local folder = replicatedStorage:FindFirstChild('Remotes')
				local killLog = folder and folder:FindFirstChild('KillLog')
				local bedBroken = folder and folder:FindFirstChild('OnBedBroken')
				local winning = folder and folder:FindFirstChild('GameRemotes') and folder.GameRemotes:FindFirstChild('OnWinningTeam')

				if killLog then
					AutoToxic:Clean(killLog.OnClientEvent:Connect(function(first, second)
						if type(first) ~= 'string' or type(second) ~= 'string' then return end
						if second == lplr.Name then
							if not dead and first ~= lplr.Name then
								dead = true
								local killer = playersService:FindFirstChild(first)
								trigger('Death', killer and killer.DisplayName or first, 'my gaming chair subscription expired :( | <obj>')
							end
						elseif first == lplr.Name then
							local killed = playersService:FindFirstChild(second)
							local final = killed and killed.Team and not bedOf(killed.Team.Name)
							local name = killed and killed.DisplayName or second
							if final and Toggles.FinalKill.Enabled then
								trigger('FinalKill', name, 'sit down | <obj>')
							else
								trigger('Kill', name, 'vxp on top | <obj>')
							end
						end
					end))
				end

				if bedBroken then
					AutoToxic:Clean(bedBroken.OnClientEvent:Connect(function()
						trigger('BedDestroyed', '', 'how dare you >:(')
					end))
				end

				local function watchBeds(container)
					AutoToxic:Clean(container.ChildRemoved:Connect(function(bed)
						if not (Toggles.BedBreak.Enabled and entitylib.isAlive and bed:IsA('Model')) then return end
						local team = bed:GetAttribute('Team')
						if not team or (lplr.Team and team == lplr.Team.Name) then return end
						local ok, pivot = pcall(bed.GetPivot, bed)
						if ok and (pivot.Position - entitylib.character.RootPart.Position).Magnitude <= 24 then
							trigger('BedBreak', tostring(team):lower(), 'nice bed lul | <obj>')
						end
					end))
				end
				if workspace:FindFirstChild('BedsContainer') then
					watchBeds(workspace.BedsContainer)
				end
				AutoToxic:Clean(workspace.ChildAdded:Connect(function(v)
					if v.Name == 'BedsContainer' then
						watchBeds(v)
					end
				end))

				if winning then
					AutoToxic:Clean(winning.OnClientEvent:Connect(function(info)
						if GG.Enabled then
							doSend('gg', GGDelay)
						end
						local winner = type(info) == 'table' and tostring(info.WinningTeam)
						if winner and lplr.Team and lplr.Team.Name == winner then
							trigger('Win', nil, 'yall garbage')
						end
					end))
				end

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
	event('FinalKill', 'Final Kill', 'When you kill someone whose bed is gone')
	event('BedBreak', 'Bed Break', 'When you break a bed')
	event('BedDestroyed', 'Bed Destroyed', 'When your own bed is destroyed')
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
end)
