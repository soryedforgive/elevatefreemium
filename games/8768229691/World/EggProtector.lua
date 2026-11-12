run(function()
	local EggProtector
	local Range
	local hop
	local pending, fails = {}, {}
	local LEGIT = 18
	local SERVER = 20
	local faces = {
		Vector3.new(3, 0, 0),
		Vector3.new(-3, 0, 0),
		Vector3.new(0, 0, 3),
		Vector3.new(0, 0, -3),
		Vector3.new(0, 3, 0)
	}

	local function release()
		hop = nil
		if store.eggProtector then
			store.eggProtector = nil
			equip(nil)
		end
		mergeRoot('EggProtector')
	end

	local function ownEgg(eggs)
		local team = lplr:GetAttribute('TeamId')
		for _, v in eggs do
			if v.PrimaryPart and v:GetAttribute('TeamId') == team and (v:GetAttribute('Health') or 0) > 0 then
				return v
			end
		end
	end

	local function eggCell(egg)
		local position = egg.PrimaryPart.Position + Vector3.new(0, 1.5, 0)
		return Vector3.new(math.round(position.X / 3) * 3, math.round(position.Y / 3) * 3, math.round(position.Z / 3) * 3)
	end

	local function getBlock()
		local best, bestTime
		for _, item in store.inventory do
			local meta = skywars.ItemMeta[item.Type]
			local block = (item.Quantity or 1) > 0 and blockMeta(meta)
			if block and not block.Block.CollectionTag and block.Block.BreakTime ~= math.huge and (not bestTime or block.Block.BreakTime > bestTime) then
				best, bestTime = meta, block.Block.BreakTime
			end
		end
		return best
	end

	local function exposed(cell)
		local open, waiting = nil, false
		for _, face in faces do
			local spot = cell + face
			if not store.blocks[spot] then
				if (pending[spot] or 0) > tick() then
					waiting = true
				elseif not open then
					open = spot
				end
			end
		end
		return open, waiting
	end

	local function canPlace(spot)
		local util = skywars.BlockUtil
		if not util then return true end
		local ok, result = pcall(function()
			return util.canPlace(spot) and util.hasAdjacentBlock(spot)
		end)
		return not ok or result
	end

	local function step(eggs)
		if not entitylib.isAlive or outranked('eggProtector') then
			release()
			return
		end
		local egg = ownEgg(eggs)
		if not egg then
			release()
			return
		end
		local cell = eggCell(egg)
		if (cell - bodyRoot().Position).Magnitude > Range.Value then
			release()
			return
		end
		local spot, waiting = exposed(cell)
		local item = spot and getBlock()
		if not item then
			if not waiting then
				release()
			elseif hop then
				sendRoot(hop.Spot)
			end
			return
		end

		if hop or (spot - realRoot().Position).Magnitude > SERVER then
			if not splitRoot('EggProtector') then return end
			store.eggProtector = true
			if not hop or hop.Cell ~= cell then
				hop = {Cell = cell, Spot = cell + Vector3.new(0, 9, 0), Since = tick()}
			end
			sendRoot(hop.Spot)
			if tick() - hop.Since < 0.4 then return end
		end
		if not canPlace(spot) then
			pending[spot] = tick() + 1
			return
		end

		equip(item)
		local id = skywars.InventoryController:registerItemPrediction(item.Name, -1)
		if id and id ~= '' then
			fireRemote('placeBlock', spot, 0, id)
		end
		equip(nil)
		fails[spot] = (fails[spot] or 0) + 1
		pending[spot] = tick() + (fails[spot] > 3 and 5 or 0.5)
		if fails[spot] > 3 then
			fails[spot] = nil
		end
	end

	EggProtector = vape.Categories.World:CreateModule({
		Name = 'EggProtector',
		Function = function(callback)
			if callback then
				local eggs = collection('egg', EggProtector)
				EggProtector:Clean(entitylib.Events.LocalRemoved:Connect(function()
					hop = nil
					store.eggProtector = nil
				end))
				repeat
					step(eggs)
					task.wait(0.05)
				until not EggProtector.Enabled
			else
				release()
				table.clear(pending)
				table.clear(fails)
			end
		end,
		Tooltip = 'Covers your egg with blocks whenever a side is open'
	})
	Range = EggProtector:CreateSlider({
		Name = 'Place range',
		Min = 1,
		Max = 1000,
		Default = LEGIT,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How far from your egg you can be'
	})
	EggProtector:CreateButton({
		Name = 'Reset to default range',
		Tooltip = 'Sets the range back to the game\'s default',
		Function = function()
			Range:SetValue(LEGIT)
		end
	})
end)
