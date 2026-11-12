run(function()
	local AutoToxic
	local GG, GGDelay
	local TrollTriggers
	local trollCooldown = 0
	local dead = false
	local Toggles, Actions, Lists, Emotes, Delays, said = {}, {}, {}, {}, {}, {}
	local textChatService = cloneref(game:GetService('TextChatService'))
	local oldOpen, openHook, screens

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

	local function nameOf(entry)
		local plr = type(entry) == 'table' and entry.Player
		return type(plr) == 'table' and (plr.DisplayName or plr.UserName) or nil, type(plr) == 'table' and plr.UserId or nil
	end

	local function eggAlive(team)
		if team == nil then return true end
		for _, egg in collectionService:GetTagged('egg') do
			if egg:GetAttribute('TeamId') == team and (egg:GetAttribute('Health') or 0) > 0 then
				return true
			end
		end
		return false
	end

	local function onFeed(data)
		local killerName, killerId = nameOf(data.Killer)
		local killedName, killedId = nameOf(data.Killed)
		if killedId then
			if killedId == lplr.UserId then
				if not dead and killerId and killerId ~= lplr.UserId then
					dead = true
					trigger('Death', killerName, 'my gaming chair subscription expired :( | <obj>')
				end
			elseif killerId == lplr.UserId then
				local victim = playersService:GetPlayerByUserId(killedId)
				if victim and not eggAlive(victim:GetAttribute('TeamId')) and Toggles.FinalKill.Enabled then
					trigger('FinalKill', killedName, 'sit down | <obj>')
				else
					trigger('Kill', killedName, 'vxp on top | <obj>')
				end
			end
			return
		end
		local egg = type(data.Killed) == 'table' and type(data.Killed.Name) == 'string' and data.Killed.Name:match('^(.-) Egg$')
		if not egg then return end
		if egg == tostring(lplr:GetAttribute('TeamId')) then
			if killerId ~= lplr.UserId then
				trigger('BedDestroyed', killerName, 'how dare you >:( | <obj>')
			end
		elseif killerId == lplr.UserId then
			trigger('BedBreak', egg:lower(), 'nice egg lul | <obj>')
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

				local controller = skywars.GameController
				screens = controller and controller.screenController
				if screens and type(screens.open) == 'function' and not openHook then
					oldOpen = screens.open
					openHook = function(self, screen, data, ...)
						if AutoToxic.Enabled and type(data) == 'table' and type(data.Killed) == 'table' then
							task.spawn(onFeed, data)
						end
						return oldOpen(self, screen, data, ...)
					end
					screens.open = openHook
				end

				local ended = controller and controller.GameEnded
				if ended and type(ended.bind) == 'function' then
					local ok, bound = pcall(ended.bind, ended, function(info)
						if not AutoToxic.Enabled then return end
						if GG.Enabled then
							doSend('gg', GGDelay)
						end
						local winners = type(info) == 'table' and type(info.GameResult) == 'table' and info.GameResult.winners
						if type(winners) == 'table' and table.find(winners, lplr) then
							trigger('Win', nil, 'yall garbage')
						end
					end)
					if ok and bound then
						AutoToxic:Clean(function()
							pcall(function()
								if type(bound) == 'function' then
									bound()
								elseif type(bound.disconnect) == 'function' then
									bound:disconnect()
								elseif type(bound.Disconnect) == 'function' then
									bound:Disconnect()
								end
							end)
						end)
					end
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
			elseif openHook and screens and screens.open == openHook then
				screens.open = oldOpen
				openHook, oldOpen = nil, nil
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
	event('FinalKill', 'Final Kill', 'When you kill someone whose egg is gone')
	event('BedBreak', 'Egg Break', 'When you break an egg')
	event('BedDestroyed', 'Egg Destroyed', 'When your own egg is destroyed')
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
