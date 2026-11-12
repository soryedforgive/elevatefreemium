run(function()
	local ItemCollector
	local Range
	local Avoid
	local Dwell
	local Items
	local MinHealth
	local skipped = setmetatable({}, {__mode = 'k'})
	local visits = setmetatable({}, {__mode = 'k'})
	local allowed = {}

	local function enemyNear(position, distance)
		if distance <= 0 then return false end
		for _, ent in entitylib.List do
			if ent.Targetable and ent.RootPart and (ent.RootPart.Position - position).Magnitude < distance then
				return true
			end
		end
		return false
	end

	local function wanted(item)
		if not (item:IsA('Model') and item.PrimaryPart and item:IsDescendantOf(workspace)) then return false end
		if (skipped[item] or 0) > tick() then return false end
		return allowed[item.Name:lower()] == true
	end

	local function route(items, origin)
		local stops = {}
		table.clear(allowed)
		for _, name in Items.ListEnabled do
			allowed[name:lower()] = true
		end
		for _, item in items do
			if wanted(item) then
				local position = item.PrimaryPart.Position
				if (position - origin).Magnitude <= Range.Value and not enemyNear(position, Avoid.Value) then
					local pile
					for _, stop in stops do
						if (stop.Position - position).Magnitude < 6 then
							pile = stop
							break
						end
					end
					if pile then
						table.insert(pile.Items, item)
					else
						table.insert(stops, {Position = position, Items = {item}})
					end
				end
			end
		end

		local ordered, from = {}, origin
		while #stops > 0 do
			local best, bestDistance
			for index, stop in stops do
				local distance = (stop.Position - from).Magnitude
				if not bestDistance or distance < bestDistance then
					best, bestDistance = index, distance
				end
			end
			local stop = table.remove(stops, best)
			table.insert(ordered, stop)
			from = stop.Position
		end
		return ordered
	end

	local function ready()
		return ItemCollector.Enabled and entitylib.isAlive and not outranked('itemCollector') and (lplr:GetAttribute('Health') or 100) >= MinHealth.Value
	end

	ItemCollector = vape.Categories.World:CreateModule({
		Name = 'ItemCollector',
		Function = function(callback)
			if callback then
				local items = collection('item', ItemCollector)
				local idleSince = tick()
				repeat
					local stops = ready() and store.noShoot < tick() and route(items, bodyRoot().Position) or {}
					if #stops > 0 and splitRoot('ItemCollector') then
						idleSince = tick()
						for _, stop in stops do
							if not ready() then break end
							local started = tick()
							repeat
								sendRoot(stop.Position + Vector3.new(0, 2.5, 0))
								runService.Heartbeat:Wait()
							until tick() - started >= Dwell.Value or not ready()
							for _, item in stop.Items do
								visits[item] = (visits[item] or 0) + 1
								if visits[item] >= 4 then
									visits[item] = nil
									skipped[item] = tick() + 10
								end
							end
						end
					elseif tick() - idleSince > 1 then
						mergeRoot('ItemCollector')
					end
					task.wait(#stops > 0 and 0.05 or 0.25)
				until not ItemCollector.Enabled
			else
				mergeRoot('ItemCollector')
			end
		end,
		Tooltip = 'Picks up coins and items from anywhere on the map'
	})
	Range = ItemCollector:CreateSlider({
		Name = 'Range',
		Min = 10,
		Max = 1500,
		Default = 1500,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Avoid = ItemCollector:CreateSlider({
		Name = 'Avoid enemies',
		Min = 0,
		Max = 100,
		Default = 20,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'Skips items with an enemy this close'
	})
	Dwell = ItemCollector:CreateSlider({
		Name = 'Time per pile',
		Min = 0.1,
		Max = 0.6,
		Default = 0.2,
		Decimal = 100,
		Suffix = 's',
		Tooltip = 'How long your hitbox waits on each pile'
	})
	MinHealth = ItemCollector:CreateSlider({
		Name = 'Min health',
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = 'hp'
	})
	Items = ItemCollector:CreateMultiDropdown({
		Name = 'Items',
		List = {'BronzeCoin', 'IronCoin', 'GoldCoin', 'Shard'},
		Default = {'BronzeCoin', 'IronCoin', 'GoldCoin', 'Shard'},
		Tooltip = 'The drops to pick up'
	})
end)
