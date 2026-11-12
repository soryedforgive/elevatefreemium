run(function()
	local AntiKillParts
	local Whitelist
	local LearnDamage
	local changed = {}
	local generation = 0
	local KEYWORDS = {'kill', 'lava', 'acid', 'death', 'deadly', 'magma', 'toxic', 'poison'}

	local function whitelisted(part)
		local name = part.Name:lower()
		for _, v in Whitelist.ListEnabled do
			if name == v:lower() then
				return true
			end
		end
		return false
	end

	local function deadlyName(name)
		name = name:lower()
		for _, word in KEYWORDS do
			if name:find(word, 1, true) then
				return true
			end
		end
		return false
	end

	local function disarm(part)
		if changed[part] ~= nil or not part.CanTouch or whitelisted(part) then return end
		if lplr.Character and part:IsDescendantOf(lplr.Character) then return end
		changed[part] = part.CanTouch
		part.CanTouch = false
	end

	local function consider(obj)
		if obj:IsA('BasePart') and deadlyName(obj.Name) then
			disarm(obj)
		end
	end

	local function restore()
		for part, original in changed do
			if part.Parent then
				pcall(function()
					part.CanTouch = original
				end)
			end
		end
		table.clear(changed)
	end

	local function scan(gen)
		local list = workspace:GetDescendants()
		local started = os.clock()
		for i = 1, #list do
			if gen ~= generation then return end
			consider(list[i])
			if os.clock() - started > 0.002 then
				task.wait()
				started = os.clock()
			end
		end
	end

	local function learn(humanoid, character)
		local last = humanoid.Health
		return humanoid.HealthChanged:Connect(function(health)
			local hurt = health < last
			last = health
			if not hurt or not LearnDamage.Enabled then return end
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = {character}
			for _, limb in character:GetChildren() do
				if limb:IsA('BasePart') then
					for _, part in workspace:GetPartsInPart(limb, params) do
						if part.CanTouch and part:FindFirstChildWhichIsA('TouchTransmitter') then
							disarm(part)
						end
					end
				end
			end
		end)
	end

	AntiKillParts = vape.Categories.World:CreateModule({
		Name = 'AntiKillParts',
		Function = function(callback)
			generation += 1
			if callback then
				local gen = generation
				task.spawn(scan, gen)
				AntiKillParts:Clean(workspace.DescendantAdded:Connect(function(obj)
					if deadlyName(obj.Name) then
						consider(obj)
					end
				end))
				local damage
				local function hook()
					if damage then
						damage:Disconnect()
						damage = nil
					end
					if entitylib.isAlive then
						damage = learn(entitylib.character.Humanoid, entitylib.character.Character)
					end
				end
				hook()
				AntiKillParts:Clean(entitylib.Events.LocalAdded:Connect(hook))
				AntiKillParts:Clean(function()
					if damage then
						damage:Disconnect()
						damage = nil
					end
				end)
			else
				restore()
			end
		end,
		Tooltip = 'Stops kill bricks and lava from touching you'
	})
	Whitelist = AntiKillParts:CreateTextList({
		Name = 'Whitelist',
		Placeholder = 'Part name to leave alone',
		Tooltip = 'Parts with these exact names are never changed'
	})
	LearnDamage = AntiKillParts:CreateToggle({
		Name = 'Learn from damage',
		Default = true,
		Tooltip = 'Also disables parts that hurt you'
	})
end)
