run(function()
	local AutoSkip
	local Words
	local Delay
	local buttons = setmetatable({}, {__mode = 'k'})
	local pressedAt = setmetatable({}, {__mode = 'k'})
	local playerGui = lplr:WaitForChild('PlayerGui', 10)

	local function matches(button)
		local texts = {button.Name}
		if button:IsA('TextButton') then
			table.insert(texts, button.Text)
		end
		for _, child in button:GetChildren() do
			if child:IsA('TextLabel') then
				table.insert(texts, child.Text)
			end
		end
		for _, text in texts do
			local lower = string.lower(text)
			for _, word in Words.ListEnabled do
				if word ~= '' and lower:find(string.lower(word), 1, true) then
					return true
				end
			end
		end
		return false
	end

	local function shown(button)
		local node = button
		while node and node ~= playerGui do
			if node:IsA('GuiObject') and not node.Visible then return false end
			if node:IsA('LayerCollector') and not node.Enabled then return false end
			node = node.Parent
		end
		return node == playerGui
	end

	local function press(button)
		local fired = false
		if getconnections then
			for _, signal in {button.Activated, button.MouseButton1Click, button.MouseButton1Down} do
				local ok, conns = pcall(getconnections, signal)
				for _, conn in ok and conns or {} do
					if pcall(conn.Fire, conn) then
						fired = true
					end
				end
				if fired then return true end
			end
		end
		if firesignal then
			fired = pcall(firesignal, button.Activated) or pcall(firesignal, button.MouseButton1Click)
		end
		return fired
	end

	local function consider(obj)
		if not obj:IsA('GuiButton') or obj:IsDescendantOf(vape.gui) then return end
		if matches(obj) then
			buttons[obj] = true
		end
	end

	AutoSkip = vape.Categories.Utility:CreateModule({
		Name = 'AutoSkip',
		Function = function(callback)
			if callback then
				if not playerGui then return end
				table.clear(buttons)
				for _, obj in playerGui:GetDescendants() do
					consider(obj)
				end
				AutoSkip:Clean(playerGui.DescendantAdded:Connect(function(obj)
					if obj:IsA('GuiButton') then
						task.defer(consider, obj)
					elseif obj:IsA('TextLabel') and obj.Parent and obj.Parent:IsA('GuiButton') then
						task.defer(consider, obj.Parent)
					end
				end))
				repeat
					local now = tick()
					for button in buttons do
						if not button.Parent then
							buttons[button] = nil
						elseif shown(button) and now - (pressedAt[button] or 0) > 0.5 then
							pressedAt[button] = now
							task.delay(Delay.Value, function()
								if AutoSkip.Enabled and button.Parent and shown(button) then
									press(button)
								end
							end)
						end
					end
					task.wait(0.2)
				until not AutoSkip.Enabled
			end
		end,
		Tooltip = 'Skips the chest screens after a match'
	})
	Words = AutoSkip:CreateTextList({
		Name = 'Words',
		Default = {'skip'},
		Tooltip = 'Text to look for on buttons',
		Function = function()
			if AutoSkip.Enabled and playerGui then
				table.clear(buttons)
				for _, obj in playerGui:GetDescendants() do
					consider(obj)
				end
			end
		end
	})
	Delay = AutoSkip:CreateSlider({
		Name = 'Delay',
		Min = 0,
		Max = 3,
		Default = 0.3,
		Decimal = 10,
		Suffix = 's',
		Tooltip = 'How long a skip button is shown before it is pressed'
	})
end)
