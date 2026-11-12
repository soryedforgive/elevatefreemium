run(function()
	local InfiniteBedDefence
	local Layers
	local Order
	local STRONG = {'^Obsidian$', '^Blastproof Ceramic$', '^Stone Brick$', '^Wood Plank$', 'Wool$'}
	local RETRY = 1.5
	local STUCK, STUCK_RETRY = 4, 10

	local function stock()
		local counts, ranks = {}, {}
		for name, count in store.inventory do
			if count > 0 and bedfight.Blocks:FindFirstChild(name) then
				for i, pattern in STRONG do
					if name:find(pattern) then
						counts[name], ranks[name] = count, i
						break
					end
				end
			end
		end
		return counts, ranks
	end

	local function pickBlock(counts, ranks)
		local best
		for name, count in counts do
			if count > 0 then
				local better = not best
				if best then
					if Order.Value == 'Most first' then
						better = count > counts[best]
					elseif Order.Value == 'Strongest first' then
						better = ranks[name] < ranks[best]
					else
						better = ranks[name] > ranks[best]
					end
				end
				if better then best = name end
			end
		end
		return best
	end

	local function ownBed()
		local container = workspace:FindFirstChild('BedsContainer')
		local team = lplr.Team and lplr.Team.Name
		if not (container and team) then return end
		for _, bed in container:GetChildren() do
			local hitbox = bed:GetAttribute('Team') == team and bed:FindFirstChild('BedHitbox')
			if hitbox then return bed, hitbox end
		end
	end

	local function plan(hitbox, layers)
		local size = hitbox.Size
		local beds = {snap(hitbox.Position)}
		if math.max(size.X, size.Z) > 4 then
			local axis = size.X >= size.Z and hitbox.CFrame.RightVector or hitbox.CFrame.LookVector
			beds = {snap(hitbox.Position + axis * 1.5), snap(hitbox.Position - axis * 1.5)}
		end
		local base = beds[1].Y
		local cells, rings, seen = {}, {}, {}
		for _, bed in beds do
			seen[tostring(bed)] = true
		end
		for layer = 1, layers do
			rings[layer] = {}
		end
		for _, bed in beds do
			for dx = -layers, layers do
				for dy = 0, layers do
					for dz = -layers, layers do
						local cell = bed + Vector3.new(dx, dy, dz) * 3
						local key = tostring(cell)
						if not seen[key] and cell.Y >= base then
							local steps = math.huge
							for _, other in beds do
								local d = (cell - other) / 3
								steps = math.min(steps, math.round(math.abs(d.X) + math.abs(d.Y) + math.abs(d.Z)))
							end
							if steps <= layers then
								seen[key] = true
								cells[key] = {Cell = cell, Layer = steps}
								table.insert(rings[steps], key)
							end
						end
					end
				end
			end
		end
		for _, ring in rings do
			table.sort(ring, function(a, b)
				local ca, cb = cells[a].Cell, cells[b].Cell
				if ca.Y ~= cb.Y then return ca.Y < cb.Y end
				return a < b
			end)
		end
		return cells, rings
	end

	local function isOpen(cell)
		local _, info = store.buildable(cell)
		return info and not info.Collided and not info.InsideAntiBuild and info.InBounds ~= false
	end

	InfiniteBedDefence = vape.Categories.World:CreateModule({
		Name = 'InfiniteBedDefence',
		Function = function(callback)
			if not callback then
				syncTool('InfiniteBedDefence')
				return
			end
			local cells, rings, planned = {}, {}, nil
			local sent, tries, committed, warned = {}, {}, {}, {}
			local lastPlace, told = 0, false

			local function ready()
				return canFight() and inMatch()
			end

			local function stuck(key)
				return (tries[key] or 0) >= STUCK
			end

			local function pending(key)
				local s = sent[key]
				return s ~= nil and tick() - s.At < (stuck(key) and STUCK_RETRY or RETRY)
			end

			local function place(list, counts, ranks)
				local equipped
				for _, key in list do
					local block = pickBlock(counts, ranks)
					if not block then
						if not told then
							told = true
							notif('InfiniteBedDefence', 'You have no blocks left to patch your bed defence with.', 4, 'warning')
						end
						return
					end
					if equipped ~= block then
						equipped = block
						equipServer(block, 'InfiniteBedDefence')
					end
					if store.placeBlock(block, cells[key].Cell) then
						told = false
						counts[block] -= 1
						sent[key] = {At = tick(), Block = block}
						tries[key] = (tries[key] or 0) + 1
						lastPlace = tick()
					end
				end
			end

			local function scan()
				local counts, ranks = stock()
				local work, spare, inner = {}, 0, true
				for layer = 1, #rings do
					local open, need, waiting = {}, 0, 0
					for _, key in rings[layer] do
						if not committed[layer] and not inner then break end
						if isOpen(cells[key].Cell) then
							if pending(key) then
								local block = sent[key].Block
								if counts[block] then
									counts[block] = math.max(counts[block] - 1, 0)
								end
								if not stuck(key) then
									waiting += 1
								end
							else
								table.insert(open, key)
								if not stuck(key) then
									need += 1
								end
							end
						else
							sent[key], tries[key] = nil, nil
						end
					end
					if not committed[layer] then
						if not inner then break end
						spare = 0
						for _, count in counts do
							spare += count
						end
						for _, key in work do
							if not stuck(key) then
								spare -= 1
							end
						end
						if need > spare then
							if not warned[layer] then
								warned[layer] = true
								notif('InfiniteBedDefence', string.format('Layer %d needs %d blocks and you have %d. It starts once you have enough.', layer, need, math.max(spare, 0)), 5, 'warning')
							end
							break
						end
						committed[layer], warned[layer] = true, nil
					end
					for _, key in open do
						table.insert(work, key)
					end
					inner = inner and need == 0 and waiting == 0
				end
				if #work > 0 then
					place(work, counts, ranks)
				end
			end

			local function watch(container)
				InfiniteBedDefence:Clean(container.DescendantRemoving:Connect(function(part)
					if not part:IsA('BasePart') or not ready() then return end
					local key = tostring(snap(part.Position))
					local data = cells[key]
					if data and committed[data.Layer] then
						sent[key] = nil
						place({key}, stock())
					end
				end))
			end
			local placed = workspace:FindFirstChild('PlayersBlocksContainer')
			if placed then
				watch(placed)
			else
				InfiniteBedDefence:Clean(workspace.ChildAdded:Connect(function(child)
					if child.Name == 'PlayersBlocksContainer' then
						watch(child)
					end
				end))
			end

			repeat
				if ready() then
					local _, hitbox = ownBed()
					if hitbox then
						local key = tostring(hitbox.Position)..Layers.Value
						if planned ~= key then
							planned = key
							cells, rings = plan(hitbox, Layers.Value)
							table.clear(sent)
							table.clear(tries)
							table.clear(committed)
							table.clear(warned)
						end
						scan()
					else
						planned, cells, rings = nil, {}, {}
						table.clear(committed)
					end
				end
				if lastPlace > 0 and tick() - lastPlace > 0.4 then
					lastPlace = 0
					syncTool('InfiniteBedDefence')
				end
				task.wait(0.5)
			until not InfiniteBedDefence.Enabled
		end,
		Tooltip = 'Covers your bed in blocks from anywhere and repairs them when broken'
	})
	Layers = InfiniteBedDefence:CreateSlider({
		Name = 'Layers',
		Min = 1,
		Max = 4,
		Default = 2,
		Tooltip = 'How many layers of blocks to build'
	})
	Order = InfiniteBedDefence:CreateDropdown({
		Name = 'Blocks',
		List = {'Strongest first', 'Cheapest first', 'Most first'},
		Default = 'Strongest first',
		Tooltip = 'Which of your blocks to use first'
	})
end)
