run(function()
	local SpawnTrap
	local Range
	local Width
	local Notify
	local funnels = {}
	local active
	local REACH = 18
	local RETRY = 3
	local CHECK = 5
	local SIDES = {Vector3.new(3, 0, 0), Vector3.new(-3, 0, 0), Vector3.new(0, 0, 3), Vector3.new(0, 0, -3)}
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include

	local function release()
		if active then
			active.Arrived, active.Spot = nil, nil
		end
		active = nil
		store.spawnTrap = nil
		mergeRoot('SpawnTrap')
	end

	local function ring(cells, centre, radius)
		if radius == 0 then
			table.insert(cells, centre)
			return
		end
		for x = -radius, radius do
			for z = -radius, radius do
				if math.max(math.abs(x), math.abs(z)) == radius then
					table.insert(cells, centre + Vector3.new(x * 3, 0, z * 3))
				end
			end
		end
	end

	local function funnelCells(spawn, floor, width)
		local cells = {}
		local column = Vector3.new(spawn.X, 0, spawn.Z)
		local top = spawn.Y + 6
		local mouth = spawn.Y - 3 * width
		for y = floor.Y + 3, spawn.Y + 3, 3 do
			local centre = column + Vector3.new(0, y, 0)
			if width > 0 and y >= mouth then
				ring(cells, centre, math.min(math.round((y - mouth) / 3), width) + 1)
			else
				for _, side in SIDES do
					table.insert(cells, centre + side)
				end
			end
		end
		local roof = column + Vector3.new(0, top, 0)
		for radius = 0, width do
			ring(cells, roof, radius)
		end
		table.insert(cells, roof + Vector3.new((width + 1) * 3, 0, 0))
		return cells, top
	end

	local function spawnFor(team, eggs, spawns)
		local egg
		for _, v in eggs do
			if v:GetAttribute('TeamId') == team and v.PrimaryPart then
				egg = v
				break
			end
		end
		if not (egg and (egg:GetAttribute('Health') or 0) > 0) then return nil end
		local best, bestDist
		for _, spawn in spawns:GetChildren() do
			if spawn:IsA('BasePart') then
				local dist = (spawn.Position - egg.PrimaryPart.Position).Magnitude
				if not bestDist or dist < bestDist then
					best, bestDist = spawn, dist
				end
			end
		end
		return best
	end

	local function build(spawnPart, map)
		local spawn = store.cell(spawnPart.Position)
		rayParams.FilterDescendantsInstances = {map}
		local hit = workspace:Raycast(spawnPart.Position, Vector3.new(0, -150, 0), rayParams)
		if not hit then return nil end
		local floor = store.cell(hit.Position - Vector3.new(0, 1.5, 0))
		local cells, top = funnelCells(spawn, floor, Width.Value)
		return {Part = spawnPart, Cells = cells, Top = top, Column = Vector3.new(spawn.X, 0, spawn.Z), Width = Width.Value, Next = 0}
	end

	local function missing(funnel)
		local list = {}
		for _, cell in funnel.Cells do
			if not store.filled(cell) and store.cellFree(cell) then
				table.insert(list, cell)
			end
		end
		return list
	end

	local function holdBeside(funnel, cell)
		local spot = funnel.Column + Vector3.new(0, math.min(cell.Y + 6, funnel.Top - 3), 0)
		if (realRoot().Position - spot).Magnitude <= 2 and funnel.Spot == spot then
			sendRoot(spot)
			return spot, tick() - (funnel.Arrived or tick()) > 0.35
		end
		if not splitRoot('SpawnTrap') then return nil end
		store.spawnTrap = true
		funnel.Spot, funnel.Arrived = spot, tick()
		sendRoot(spot)
		return spot, false
	end

	local function step(eggs)
		if not entitylib.isAlive or outranked('spawnTrap') then
			if active or store.spawnTrap then release() end
			return
		end
		local container = workspace:FindFirstChild('BlockContainer')
		local map = container and container:FindFirstChild('Map')
		local spawns = map and map:FindFirstChild('SpawnLocations')
		if not spawns then return end

		if not active then
			local mine = lplr:GetAttribute('TeamId')
			local origin = bodyRoot().Position
			local wanted = {}
			for _, plr in playersService:GetPlayers() do
				local team = plr:GetAttribute('TeamId')
				if plr ~= lplr and team and team ~= mine then
					wanted[team] = true
				end
			end
			local best, bestDist
			for team in wanted do
				local part = spawnFor(team, eggs, spawns)
				local dist = part and (part.Position - origin).Magnitude
				if dist and dist <= Range.Value then
					local funnel = funnels[part]
					if not funnel or funnel.Width ~= Width.Value then
						funnel = build(part, map)
						funnels[part] = funnel
					end
					if funnel and tick() >= funnel.Next and (not bestDist or dist < bestDist) then
						best, bestDist = funnel, dist
					end
				end
			end
			if not best then return end
			active = best
		end

		local funnel = active
		local open = missing(funnel)
		if #open == 0 then
			if not funnel.Done and Notify.Enabled then
				notif('SpawnTrap', 'Funnel over a spawn is up.', 3)
			end
			funnel.Done, funnel.Next = true, tick() + CHECK
			release()
			return
		end
		local order = store.orderCells(open)
		if #order == 0 then
			funnel.Next = tick() + RETRY
			release()
			return
		end
		local item, amount = store.blockItem(1)
		if not item then
			if Notify.Enabled and not funnel.Warned then
				notif('SpawnTrap', 'You carry no blocks to build a funnel.', 4, 'warning')
			end
			funnel.Warned, funnel.Next = true, tick() + RETRY
			release()
			return
		end

		local origin = realRoot().Position
		local first = order[1]
		local reach = not store.spawnTrap and (first - origin).Magnitude <= REACH
		if not reach then
			local spot, ready = holdBeside(funnel, first)
			if not (spot and ready) then return end
			origin = spot
		end
		local batch = {}
		for _, cell in order do
			if #batch >= amount then break end
			if (cell - origin).Magnitude <= REACH then
				table.insert(batch, cell)
			end
		end
		store.placeCells(batch, item)
		funnel.Done = false
	end

	SpawnTrap = vape.Categories.Blatant:CreateModule({
		Name = 'SpawnTrap',
		Function = function(callback)
			if callback then
				local eggs = collection('egg', SpawnTrap)
				SpawnTrap:Clean(entitylib.Events.LocalRemoved:Connect(function()
					active = nil
					store.spawnTrap = nil
				end))
				repeat
					step(eggs)
					task.wait(active and 0.05 or 0.25)
				until not SpawnTrap.Enabled
			else
				release()
				table.clear(funnels)
			end
		end,
		Tooltip = 'Traps enemy spawns so players respawn inside a funnel'
	})
	Range = SpawnTrap:CreateSlider({
		Name = 'Range',
		Min = 20,
		Max = 1000,
		Default = 1000,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How far away a spawn can be'
	})
	Width = SpawnTrap:CreateSlider({
		Name = 'Mouth width',
		Min = 0,
		Max = 2,
		Default = 1,
		Tooltip = 'How wide the top of the trap is'
	})
	Notify = SpawnTrap:CreateToggle({
		Name = 'Notify',
		Default = true
	})
end)
