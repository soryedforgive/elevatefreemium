run(function()
	local AutoBank
	local Whitelist
	local Custom
	local LowHP
	local Void
	local Withdraw
	local Rubberband
	local Notify
	local banked = {}
	local bankedAt = 0
	local sent = {}
	local safeSince, lastGround, lostSince
	local spawnedAt = 0

	local function tell(text)
		if Notify.Enabled then
			notif('AutoBank', text, 3)
		end
	end

	local function storage()
		return inMatch() and bedfight.TeamChests:FindFirstChild(lplr.Team.Name) or nil
	end

	local NAMES = {
		Emerald = '^Emerald$',
		Diamond = '^Diamond$',
		Iron = '^Iron$',
		Telepearl = '^Teleorb$',
		Arrow = 'Arrow$',
		Wool = 'Wool$'
	}
	local GROUPS = {'Emerald', 'Diamond', 'Iron', 'Telepearl', 'Arrow', 'Wool'}

	local function matches(group, name)
		return name:find(NAMES[group]) ~= nil
	end

	local function wanted(name)
		for _, group in GROUPS do
			if Whitelist:Has(group) and matches(group, name) then return true end
		end
		local lower = name:lower()
		for _, entry in Custom.ListEnabled do
			if lower == entry:lower() then return true end
		end
		return false
	end

	local function storable(name)
		local data = bedfight.ItemsData and bedfight.ItemsData[name]
		return type(data) == 'table' and data.CanStoreInChest == true
	end

	local function falling(root)
		if entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
			lastGround = root.Position.Y
			return false
		end
		if root.AssemblyLinearVelocity.Y > -10 or (lastGround and root.Position.Y > lastGround - 6) then return false end
		return store.inVoid(root, 0.5)
	end

	local function rubberbanding()
		if not isnetworkowner then return false end
		local real = realRoot()
		if tick() - spawnedAt < 3 or not (real and real.Parent) or isnetworkowner(real) then
			lostSince = nil
			return false
		end
		lostSince = lostSince or tick()
		return tick() - lostSince > 0.5
	end

	local function bank(all)
		local chest = storage()
		if not chest then return end
		local used, count = {}, 0
		for slot in banked do
			used[slot] = true
		end
		for name, amount in store.inventory do
			if amount > 0 and amount ~= math.huge and (wanted(name) or (all and storable(name))) and (sent[name] or 0) < tick() then
				local index
				for i = 1, 20 do
					local slot = chest:FindFirstChild(tostring(i))
					if slot and slot:GetAttribute('Name') == name then
						index = i
						break
					end
				end
				if not index then
					for i = 1, 20 do
						if not used[i] and not chest:FindFirstChild(tostring(i)) then
							index = i
							break
						end
					end
				end
				if index then
					used[index] = true
					banked[index] = name
					sent[name] = tick() + 1
					count += 1
					fireRemote('PutItemInChest', name, lplr.Team.Name, index)
				end
			end
		end
		if count > 0 then
			bankedAt = tick()
			tell(string.format('Put %d %s in your team chest.', count, count == 1 and 'stack' or 'stacks'))
		end
	end

	local function withdraw()
		local chest = storage()
		if not chest or not next(banked) then return end
		local count = 0
		for index, name in banked do
			local slot = chest:FindFirstChild(tostring(index))
			if slot and slot:GetAttribute('Name') == name then
				fireRemote('TakeItemFromChest', lplr.Team.Name, index, name)
				count += 1
			end
		end
		table.clear(banked)
		if count > 0 then
			tell(string.format('Took %d %s back out of your team chest.', count, count == 1 and 'stack' or 'stacks'))
		end
	end

	local function nearShop(root)
		for _, v in collectionService:GetTagged('ItemShopPrompt') do
			if v:IsA('BasePart') and v:IsDescendantOf(workspace) and (v.Position - root.Position).Magnitude <= 10 then
				return true
			end
		end
		return false
	end

	AutoBank = vape.Categories.Inventory:CreateModule({
		Name = 'AutoBank',
		Function = function(callback)
			if callback then
				store.bankSlots = banked
				spawnedAt = tick()
				AutoBank:Clean(entitylib.Events.LocalAdded:Connect(function()
					safeSince, lastGround, lostSince = nil, nil, nil
					spawnedAt = tick()
				end))
				repeat
					if entitylib.isAlive and inMatch() and not store.lobbyBusy then
						local root = entitylib.character.RootPart
						local health = entitylib.character.Humanoid.Health
						local pulled = Rubberband.Enabled and rubberbanding()
						local danger = pulled or health > 0 and health <= LowHP.Value or (Void.Enabled and falling(root))
						if danger then
							safeSince = nil
							bank(pulled)
						elseif next(banked) and tick() - bankedAt > 1 then
							if Withdraw.Value == 'At shop' then
								if nearShop(root) then
									withdraw()
								end
							elseif entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air and health > LowHP.Value + 10 then
								safeSince = safeSince or tick()
								if tick() - safeSince > 1 then
									withdraw()
								end
							else
								safeSince = nil
							end
						end
					end
					task.wait(0.1)
				until not AutoBank.Enabled
			else
				if store.bankSlots == banked then
					store.bankSlots = nil
				end
			end
		end,
		Tooltip = 'Stores your items in your team chest when in danger'
	})
	Whitelist = AutoBank:CreateMultiDropdown({
		Name = 'Whitelist',
		List = GROUPS,
		Default = {'Emerald', 'Diamond', 'Iron'},
		Tooltip = 'Items to put in the chest'
	})
	Custom = AutoBank:CreateTextList({
		Name = 'Custom Whitelist',
		Placeholder = 'item name',
		Tooltip = 'Extra item names to bank, such as Fireball'
	})
	LowHP = AutoBank:CreateSlider({
		Name = 'Low HP',
		Min = 5,
		Max = 90,
		Default = 30,
		Tooltip = 'Health to act at, in hit points'
	})
	Void = AutoBank:CreateToggle({
		Name = 'While falling',
		Default = true,
		Tooltip = 'Also banks while you are falling into the void'
	})
	Rubberband = AutoBank:CreateToggle({
		Name = 'While rubberbanding',
		Tooltip = 'Banks everything you carry while the server is pulling you back'
	})
	Withdraw = AutoBank:CreateDropdown({
		Name = 'Take back',
		List = {'When safe', 'At shop'},
		Tooltip = 'When safe - once you are safe again\nAt shop - only when near a shop'
	})
	Notify = AutoBank:CreateToggle({
		Name = 'Notify',
		Default = true,
		Tooltip = 'Tells you when it banks and takes items back'
	})
end)
