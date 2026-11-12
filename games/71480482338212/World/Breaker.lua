run(function()
	local Breaker
	local BreakerType
	local BreakChance
	local CombatOnly
	local Angle
	local Range
	local UpdateRate
	local Custom
	local Bed
	local SelfBreak
	local AutoTool
	local LimitItem
	local Animation
	local box
	local lock, lostAt, lastLine
	local lastHit, jitter = 0, 0
	local confirmed, warned = false, false
	local rng = Random.new()
	local tracks, viewTracks = {}, {}
	local skip = setmetatable({}, {__mode = 'k'})
	local left = setmetatable({}, {__mode = 'k'})
	local full = {}
	local httpService = cloneref(game:GetService('HttpService'))
	local HEALTH_FILE = 'ElevateV4/profiles/bedfightblocks.json'
	local fullSaved = 0
	pcall(function()
		if isfile and isfile(HEALTH_FILE) then
			for kind, health in httpService:JSONDecode(readfile(HEALTH_FILE)) do
				if type(health) == 'number' and health > 0 then full[kind] = health end
			end
		end
	end)
	local function saveHealth()
		if not writefile or tick() - fullSaved < 5 then return end
		fullSaved = tick()
		pcall(writefile, HEALTH_FILE, httpService:JSONEncode(full))
	end
	local SIDE, DOWN, UP = 5, 2, 4
	local NEIGHBOURS = {
		{1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}, {0, 0, 1}, {0, 0, -1}
	}
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	local routeAt = 0
	local FACES = {
		Vector3.zero,
		Vector3.new(1.35, 0, 0), Vector3.new(-1.35, 0, 0),
		Vector3.new(0, 1.35, 0), Vector3.new(0, -1.35, 0),
		Vector3.new(0, 0, 1.35), Vector3.new(0, 0, -1.35)
	}

	local function isLegit()
		return BreakerType.Value == 'Legit'
	end

	local function unlock()
		lock, lostAt = nil, nil
	end

	local function placedBlock(part)
		local placed = workspace:FindFirstChild('PlayersBlocksContainer')
		if not (placed and part:IsDescendantOf(placed)) then return nil end
		local object = part.Parent:IsA('Model') and part.Parent or part
		return object, object.Parent.Name
	end

	local function toolFor(kind)
		local held = heldName()
		local data = held and bedfight.MiningData[held]
		local holding = type(data) == 'table' and data.Cooldown ~= nil
		if (LimitItem.Enabled or not AutoTool.Enabled) and not holding then return nil end
		if AutoTool.Enabled then
			return getTool(kind)
		end
		return held, data.Damages and data.Damages[kind] or data.DefaultDamage or 0
	end

	local function hitsFor(object, kind)
		local tool, damage = toolFor(kind)
		if not tool or (damage or 0) <= 0 then return math.huge end
		return math.ceil((left[object] or full[kind] or 30) / damage)
	end

	local function probes(hitbox, from)
		local cf, size = hitbox.CFrame, hitbox.Size
		local long = size.X > size.Z and Vector3.new(size.X / 4, 0, 0) or Vector3.new(0, 0, size.Z / 4)
		local half = size / 2 - Vector3.new(0.3, 0.3, 0.3)
		local near = cf:PointToObjectSpace(from)
		return {
			cf * Vector3.new(math.clamp(near.X, -half.X, half.X), math.clamp(near.Y, -half.Y, half.Y), math.clamp(near.Z, -half.Z, half.Z)),
			hitbox.Position,
			cf * long,
			cf * -long
		}
	end

	local function trace(from, point, bed, params)
		local list = {}
		local origin = from
		for _ = 1, 10 do
			local ray = point - origin
			if ray.Magnitude < 0.05 then
				return list
			end
			local hit = workspace:Raycast(origin, ray, params)
			if not hit then
				return list
			end
			if hit.Instance:IsDescendantOf(bed) then
				return list, hit
			end
			local object, kind = placedBlock(hit.Instance)
			if not object then return nil end
			table.insert(list, {Object = object, Part = hit.Instance, Kind = kind})
			origin = hit.Position + ray.Unit * 0.1
		end
		return nil
	end

	local function visible(from, part, params)
		for _, offset in FACES do
			local point = part.Position + offset
			local hit = workspace:Raycast(from, point - from, params)
			if hit and hit.Instance == part then
				return hit, point
			end
		end
	end

	local function cellId(x, y, z)
		return (x + 8) * 256 + (y + 8) * 16 + (z + 8)
	end

	local function route(bed, hitbox, body, reach, from, params, prefer)
		local placed = workspace:FindFirstChild('PlayersBlocksContainer')
		local centre = snap(hitbox.Position)
		local list = {}
		if placed then
			table.insert(list, placed)
		end
		local map = mapBlocks()
		if map then
			table.insert(list, map)
		end
		overlap.FilterDescendantsInstances = list

		local grid = {}
		local size = Vector3.new(SIDE * 2 + 1, DOWN + UP + 1, SIDE * 2 + 1) * 3
		local middle = centre + Vector3.new(0, (UP - DOWN) * 1.5, 0)
		for _, part in workspace:GetPartBoundsInBox(CFrame.new(middle), size, overlap) do
			if not part.CanCollide then continue end
			local offset = part.Position - centre
			if placed and part:IsDescendantOf(placed) then
				local object, kind = placedBlock(part)
				local x, y, z = math.round(offset.X / 3), math.round(offset.Y / 3), math.round(offset.Z / 3)
				if object and math.abs(x) <= SIDE and math.abs(z) <= SIDE and y >= -DOWN and y <= UP then
					grid[cellId(x, y, z)] = {Object = object, Part = part, Kind = kind}
				end
			else
				local cf, half = part.CFrame, part.Size / 2
				local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
				local ex = math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z - 1
				local ey = math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z - 1
				local ez = math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z - 1
				for x = math.max(-SIDE, math.ceil((offset.X - ex) / 3)), math.min(SIDE, math.floor((offset.X + ex) / 3)) do
					for y = math.max(-DOWN, math.ceil((offset.Y - ey) / 3)), math.min(UP, math.floor((offset.Y + ey) / 3)) do
						for z = math.max(-SIDE, math.ceil((offset.Z - ez) / 3)), math.min(SIDE, math.floor((offset.Z + ez) / 3)) do
							grid[cellId(x, y, z)] = false
						end
					end
				end
			end
		end

		local long = hitbox.Size.X > hitbox.Size.Z and Vector3.new(hitbox.Size.X / 4, 0, 0) or Vector3.new(0, 0, hitbox.Size.Z / 4)
		local dist, prev, where, isBed = {}, {}, {}, {}
		local buckets = {[0] = {}}
		for _, point in {hitbox.CFrame * long, hitbox.CFrame * -long} do
			local offset = snap(point) - centre
			local x, y, z = math.round(offset.X / 3), math.round(offset.Y / 3), math.round(offset.Z / 3)
			local id = cellId(x, y, z)
			if not isBed[id] then
				isBed[id] = true
				dist[id] = 0
				where[id] = {x, y, z}
				table.insert(buckets[0], id)
			end
		end

		local goals, edges = {}, {}
		local rays = 0
		local cost, highest = 0, 0
		while cost <= highest and #goals == 0 and not (#edges > 0 and cost > dist[edges[1]] + 6) do
			local bucket = buckets[cost]
			local index = 1
			while bucket and index <= #bucket do
				local id = bucket[index]
				index += 1
				if dist[id] ~= cost then continue end
				local at = where[id]
				local x, y, z = at[1], at[2], at[3]
				if not isBed[id] and not grid[id] then
					local point = centre + Vector3.new(x, y, z) * 3
					if from and rays < 250 and (point - body).Magnitude <= reach + 3 then
						rays += 1
						if not workspace:Raycast(from, point - from, params) then
							table.insert(goals, id)
							continue
						end
					end
					if math.abs(x) == SIDE or math.abs(z) == SIDE or y == UP then
						table.insert(edges, id)
						continue
					end
				end
				for _, step in NEIGHBOURS do
					local nx, ny, nz = x + step[1], y + step[2], z + step[3]
					if math.abs(nx) > SIDE or math.abs(nz) > SIDE or ny < -DOWN or ny > UP then continue end
					local nid = cellId(nx, ny, nz)
					if isBed[nid] then continue end
					local cell = grid[nid]
					local extra = 0
					if cell == false then
						continue
					elseif cell then
						if (cell.Part.Position - body).Magnitude > reach or (skip[cell.Object] or 0) > tick() then continue end
						extra = hitsFor(cell.Object, cell.Kind)
						if extra == math.huge then continue end
					end
					local total = cost + extra
					if total < (dist[nid] or math.huge) then
						dist[nid] = total
						prev[nid] = id
						where[nid] = {nx, ny, nz}
						buckets[total] = buckets[total] or {}
						table.insert(buckets[total], nid)
						highest = math.max(highest, total)
					end
				end
			end
			cost += 1
		end
		local seen = #goals > 0
		if not seen then goals = edges end
		if #goals == 0 then return nil end

		local function world(id)
			local at = where[id]
			return centre + Vector3.new(at[1], at[2], at[3]) * 3
		end
		local function entry(goal)
			local open, id = goal, prev[goal]
			while id do
				if isBed[id] then
					local side, to = world(open), world(id)
					return {Object = bed, Part = hitbox, Kind = 'Bed', Bed = bed, Cell = to, From = side, Direction = (to - side).Unit, Routed = true, BedCell = to, Face = seen and (side + to) / 2 or nil}
				end
				local cell = grid[id]
				if cell then
					local side = world(open)
					return {Object = cell.Object, Part = cell.Part, Kind = cell.Kind, Bed = bed, Cell = snap(cell.Part.Position), From = side, Direction = (cell.Part.Position - side).Unit, Routed = true, Face = seen and (side + cell.Part.Position) / 2 or nil}
				end
				open, id = id, prev[id]
			end
		end
		local best, bestScore, seen = nil, math.huge, {}
		for _, goal in goals do
			local found = entry(goal)
			if found and not seen[found.Object] then
				seen[found.Object] = true
				local score = (found.Part.Position - body).Magnitude
				if found.Object == prefer then
					score -= 2000
				elseif from and visible(from, found.Part, params) then
					score -= 1000
				end
				if score < bestScore then
					best, bestScore = found, score
				end
			end
		end
		if not best then return nil end
		return dist[goals[1]], best
	end

	local function play(cache, animator, anim)
		if not (anim and animator) then return end
		if cache.Animator ~= animator then
			table.clear(cache)
			cache.Animator = animator
		end
		cache[anim] = cache[anim] or animator:LoadAnimation(anim)
		cache[anim]:Play()
	end

	local function swing(tool)
		local data = bedfight.MiningData[tool]
		local anims = data.Animations or bedfight.MiningData.DefaultAnimation
		local anim = anims and anims.Mine
		if not anim then return end
		play(tracks, entitylib.character.Humanoid:FindFirstChildOfClass('Animator'), anim.Animation)
		if heldName() == tool then
			play(viewTracks, bedfight.ViewModelHandler.ViewModelAnimator, anim.ViewModel)
		end
	end

	local function strike(target)
		local tool = toolFor(target.Kind)
		if not tool then return end
		local now = tick()
		local legit = isLegit()
		local cooldown = bedfight.MiningData[tool].Cooldown or 0.3
		if now - lastHit < cooldown + (legit and jitter or 0) then return end
		lastHit, jitter = now, rng:NextNumber(0, 0.05)
		if legit and BreakChance.Value < 100 and (not CombatOnly.Enabled or store.inCombat()) and rng:NextNumber(0, 100) >= BreakChance.Value then return end
		target.Sent = (target.Sent or 0) + 1
		equipServer(tool, 'Breaker')
		fireRemote('MineBlock', tool, target.Object, target.Cell, target.From, target.Direction)
		if Animation.Enabled then
			pcall(swing, tool)
		end
	end

	local function step()
		local legit = isLegit()
		local body = entitylib.character.RootPart.Position
		local from = legit and gameCamera.CFrame.Position or body + Vector3.new(0, 1.5, 0)
		local look = gameCamera.CFrame.LookVector
		local reach = Range.Value
		local params = blockParams()
		local team = lplr.Team.Name

		local function allowed(position)
			if (position - body).Magnitude > reach then return false end
			if legit and Angle.Value < 360 then
				local dir = position - from
				if dir.Magnitude > 0.5 and math.deg(math.acos(math.clamp(look:Dot(dir.Unit), -1, 1))) > Angle.Value / 2 then return false end
			end
			return true
		end

		local target, candidate, score = nil, nil, math.huge
		local reachable = {}
		local beds = Bed.Enabled and workspace:FindFirstChild('BedsContainer')
		for _, bed in beds and beds:GetChildren() or {} do
			local hitbox = bed:FindFirstChild('BedHitbox')
			if not hitbox or bed:GetAttribute('Team') == team or (hitbox.Position - body).Magnitude > reach + 4 then continue end
			table.insert(reachable, {bed, hitbox})
			for index, point in probes(hitbox, from) do
				local list, hit = trace(from, point, bed, params)
				if not list then continue end
				if #list == 0 then
					local cell = hit and snap(hit.Position - hit.Normal * 1.5) or snap(point)
					if allowed(cell) and toolFor('Bed') then
						target = {Object = bed, Part = hitbox, Kind = 'Bed', Cell = cell, From = from, Direction = (point - from).Unit}
						break
					end
				elseif legit and not lock then
					local first = list[1]
					if not allowed(first.Part.Position) or (skip[first.Object] or 0) > tick() then continue end
					local cost = (first.Part.Position - body).Magnitude + #list * 3
					if lastLine and lastLine[1] == bed and lastLine[2] == index then
						cost -= 1000
					end
					if cost < score then
						first.Bed, first.Line = bed, index
						candidate, score = first, cost
					end
				end
			end
			if target then break end
		end

		if not target then
			if lock then
				local gone = not lock.Object.Parent or not lock.Part.Parent or (lock.Bed and not (lock.Bed.Parent and Bed.Enabled))
				if gone or (lock.Part.Position - body).Magnitude > reach or not toolFor(lock.Kind) then
					unlock()
				elseif confirmed and (lock.Sent or 0) >= 6 and tick() - (lock.Progress or lock.Since) > 2.5 then
					skip[lock.Object] = tick() + 4
					unlock()
				end
			end

			if not legit and (not lock or lock.Routed) and tick() - routeAt > (lock and 0.5 or 0.2) then
				routeAt = tick()
				local best = math.huge
				for _, v in reachable do
					local cost, found = route(v[1], v[2], body, reach, from, params, lock and lock.Object)
					if cost and toolFor(found.Kind) and (cost < best or (cost == best and lock and found.Object == lock.Object)) then
						best, candidate = cost, found
					end
				end
				if lock and candidate then
					if candidate.Object == lock.Object then
						lock.Cost, lock.CostSent = best, lock.Sent or 0
						lock.Face = candidate.Face or lock.Face
						candidate = nil
					elseif best < (lock.Cost or math.huge) - ((lock.Sent or 0) - (lock.CostSent or 0)) then
						unlock()
					else
						candidate = nil
					end
				end
				if candidate then
					candidate.Cost, candidate.CostSent = best, 0
				end
			end
			if not lock and candidate then
				lock = candidate
				lock.Since = tick()
				if candidate.Line then
					lastLine = {candidate.Bed, candidate.Line}
				end
			end

			if not lock and #Custom.ListEnabled > 0 then
				local placed = workspace:FindFirstChild('PlayersBlocksContainer')
				local own = team..' Wool'
				local found = {}
				for _, folder in placed and placed:GetChildren() or {} do
					local wanted = false
					for _, name in Custom.ListEnabled do
						if name:lower() == folder.Name:lower() then
							wanted = true
							break
						end
					end
					if not wanted then continue end
					for _, object in folder:GetChildren() do
						local part = object:IsA('BasePart') and object or object:FindFirstChildWhichIsA('BasePart', true)
						if part and (SelfBreak.Enabled or object.Name ~= own) and (skip[object] or 0) <= tick() and allowed(part.Position) then
							table.insert(found, {Object = object, Part = part, Kind = folder.Name, Distance = (part.Position - body).Magnitude})
						end
					end
				end
				table.sort(found, function(a, b)
					return a.Distance < b.Distance
				end)
				for i = 1, math.min(#found, 6) do
					if toolFor(found[i].Kind) and (not legit or visible(from, found[i].Part, params)) then
						lock = found[i]
						lock.Since = tick()
						break
					end
				end
			end

			if lock and not target then
				local hit, point = visible(from, lock.Part, params)
				if not hit and lock.Face then
					local ray = workspace:Raycast(from, (lock.Face - from) * 1.05, params)
					if ray and ray.Instance == lock.Part then
						hit, point = ray, lock.Face
					end
				end
				local blocker
				if not hit and not legit and not lock.Routed then
					local ray = workspace:Raycast(from, lock.Part.Position - from, params)
					local object, kind = ray and placedBlock(ray.Instance)
					if object and object ~= lock.Object and (ray.Instance.Position - body).Magnitude <= reach and toolFor(kind) then
						blocker = {Object = object, Part = ray.Instance, Kind = kind, Cell = snap(ray.Position - ray.Normal * 1.5), From = from, Direction = (ray.Position - from).Unit}
					end
				end
				if blocker then
					lostAt = nil
					target = blocker
				elseif legit and not (hit and allowed(lock.Part.Position)) then
					lostAt = lostAt or tick()
					if tick() - lostAt > 1.5 then
						unlock()
					end
				elseif lock.Routed and not hit then
					lostAt = nil
					lock.Side = lock.Side or {lock.From, lock.Direction}
					if (lock.Sent or 0) % 6 < 3 then
						lock.From, lock.Direction = lock.Side[1], lock.Side[2]
					else
						lock.From, lock.Direction = from, (lock.Part.Position - from).Unit
					end
					lock.Cell = lock.BedCell or snap(lock.Part.Position)
					target = lock
				else
					lostAt = nil
					point = point or lock.Part.Position
					lock.Cell = hit and snap(hit.Position - hit.Normal * 1.5) or snap(lock.Part.Position)
					lock.From, lock.Direction = from, (point - from).Unit
					target = lock
				end
			end
		end

		if target then
			strike(target)
		end
		return target, lock ~= nil
	end

	Breaker = vape.Categories.World:CreateModule({
		Name = 'Breaker',
		Function = function(callback)
			if callback then
				local display = replicatedStorage:FindFirstChild('Remotes') and replicatedStorage.Remotes:FindFirstChild('DisplayBlockHealth')
				if display then
					Breaker:Clean(display.OnClientEvent:Connect(function(object, _, health, max)
						if typeof(object) ~= 'Instance' or type(health) ~= 'number' then return end
						left[object] = health
						if type(max) == 'number' and object.Parent and object.Parent.Parent == workspace:FindFirstChild('PlayersBlocksContainer') then
							if full[object.Parent.Name] ~= max then
								full[object.Parent.Name] = max
								saveHealth()
							end
						end
						if lock and lock.Object == object then
							lock.Progress = tick()
							confirmed = true
						end
					end))
				end

				local switched = false
				repeat
					local target, busy
					if canFight() and inMatch() then
						local ok, a, b = pcall(step)
						if ok then
							target, busy = a, b
						elseif not warned then
							warned = true
							warn('[ElevateV4] Breaker: '..tostring(a))
						end
					else
						unlock()
					end

					if target then
						switched = true
					elseif switched and not busy then
						switched = false
						syncTool('Breaker')
					end
					if box then
						box.Adornee = target and target.Part or nil
						if target then
							box.Size = target.Part.Size + Vector3.new(0.1, 0.1, 0.1)
						end
					end
					task.wait(1 / UpdateRate.Value)
				until not Breaker.Enabled
			else
				unlock()
				syncTool('Breaker')
				if box then
					box.Adornee = nil
				end
			end
		end,
		ExtraText = function()
			return BreakerType.Value
		end,
		Tooltip = 'Breaks enemy beds around you'
	})
	BreakerType = Breaker:CreateDropdown({
		Name = 'Breaker Type',
		List = {'Blatant', 'Legit'},
		Default = 'Blatant',
		Tooltip = 'Blatant - the fastest way in, through walls\nLegit - only blocks you could reach yourself',
		Function = function()
			unlock()
		end
	})
	BreakChance = Breaker:CreateSlider({
		Name = 'Break Chance',
		Min = 1,
		Max = 100,
		Default = 100,
		Suffix = '%',
		Darker = true,
		Visible = function()
			return BreakerType.Value == 'Legit'
		end,
		Tooltip = 'Chance that each mining hit is sent'
	})
	CombatOnly = Breaker:CreateToggle({
		Name = 'Only while in combat',
		Darker = true,
		Visible = function()
			return BreakerType.Value == 'Legit'
		end,
		Tooltip = 'Only applies Break Chance during fights'
	})
	Angle = Breaker:CreateSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 120,
		Darker = true,
		Visible = function()
			return BreakerType.Value == 'Legit'
		end,
		Tooltip = 'How far from your view a block can be'
	})
	Range = Breaker:CreateSlider({
		Name = 'Break range',
		Min = 1,
		Max = 18,
		Default = 18,
		Suffix = 'studs',
		Tooltip = 'How far away a block can be mined'
	})
	UpdateRate = Breaker:CreateSlider({
		Name = 'Update rate',
		Min = 1,
		Max = 120,
		Default = 60,
		Suffix = 'hz'
	})
	Custom = Breaker:CreateTextList({
		Name = 'Custom',
		Placeholder = 'block name',
		Tooltip = 'Extra blocks to mine when in range'
	})
	Bed = Breaker:CreateToggle({
		Name = 'Break Bed',
		Default = true
	})
	Animation = Breaker:CreateToggle({
		Name = 'Animation',
		Tooltip = 'Plays the mining swing'
	})
	SelfBreak = Breaker:CreateToggle({
		Name = 'Self Break',
		Tooltip = 'Also mines your own blocks'
	})
	AutoTool = Breaker:CreateToggle({
		Name = 'Auto Tool',
		Default = true,
		Tooltip = 'Uses the best tool you own for each block'
	})
	LimitItem = Breaker:CreateToggle({
		Name = 'Limit to items',
		Tooltip = 'Only works while holding the item it uses'
	})
	Breaker:CreateToggle({
		Name = 'Show target',
		Default = true,
		Function = function(callback)
			if callback then
				box = Instance.new('BoxHandleAdornment')
				box.AlwaysOnTop = true
				box.ZIndex = 0
				box.Color3 = Color3.fromRGB(255, 80, 80)
				box.Transparency = 0.6
				box.Parent = vape.gui
			elseif box then
				box:Destroy()
				box = nil
			end
		end
	})
end)
