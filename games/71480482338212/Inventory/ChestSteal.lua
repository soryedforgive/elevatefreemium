run(function()
	local ChestSteal
	local Chests

	local function chestInRange(team)
		if not entitylib.isAlive then return false end
		for _, v in collectionService:GetTagged('TeamChest') do
			if v.Name == team and v:IsDescendantOf(workspace) then
				return (v:GetPivot().Position - entitylib.character.RootPart.Position).Magnitude <= 24
			end
		end
		return false
	end

	local function lootChests()
		local mine = inMatch() and lplr.Team.Name or nil
		if not mine then return end
		for _, storage in bedfight.TeamChests:GetChildren() do
			local own = storage.Name == mine
			if (Chests.Value == 'Own team' and not own) or (Chests.Value == 'Enemy teams' and own) then continue end
			if not chestInRange(storage.Name) then continue end
			for _, slot in storage:GetChildren() do
				local index, item = tonumber(slot.Name), slot:GetAttribute('Name')
				if index and item and item ~= '' and not (own and ((store.bankSlots and store.bankSlots[index]) or (store.lobbySlots and store.lobbySlots[index]))) then
					fireRemote('TakeItemFromChest', storage.Name, index, item)
					task.wait(0.1)
					if not ChestSteal.Enabled then return end
				end
			end
		end
	end

	ChestSteal = vape.Categories.Inventory:CreateModule({
		Name = 'ChestSteal',
		Function = function(callback)
			if callback then
				repeat
					if entitylib.isAlive and inMatch() then
						lootChests()
					end
					task.wait(0.3)
				until not ChestSteal.Enabled
			end
		end,
		Tooltip = 'Takes items from team chests you are standing next to'
	})
	Chests = ChestSteal:CreateDropdown({
		Name = 'Chests',
		List = {'All teams', 'Enemy teams', 'Own team'},
		Tooltip = 'Which team chests to take from'
	})
end)
