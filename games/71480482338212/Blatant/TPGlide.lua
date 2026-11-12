run(function()
	local TPGlide
	local Direction
	local StopBed
	local BedRange
	local Rest
	local Notify
	local LINE = Color3.fromRGB(211, 120, 255)
	local RAY = Color3.fromRGB(80, 220, 255)
	local NEXT = Color3.fromRGB(99, 220, 130)
	local HOP_SPEED = 300
	local BODY_RATE, BODY_SPEED = 3, 160
	local LANES = {3, 8, 14}
	local MAX_HOP, MAX_UP, MAX_DOWN, MAX_CHECKS = 100, 30, 18, 60
	local ANGLES = {0, 20, -20, 40, -40, 60, -60, 80, -80}
	local ONWARD = {0, 30, -30}
	local BEHIND = {100, -100, 120, -120, 140, -140, 160, -160, 180}
	local RINGS = {100, 88, 76, 64, 52, 40, 28, 16, 8}
	local LEVELS = {0, 6, -6, 12, -12, 18, -18}
	local GOAL_RINGS = {4, 6, 8, 10, 12, 14}
	local CORNERS = {Vector3.new(1.2, 0, 1.2), Vector3.new(1.2, 0, -1.2), Vector3.new(-1.2, 0, 1.2), Vector3.new(-1.2, 0, -1.2)}
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	rayCheck.RespectCanCollide = true
	local boxCheck = OverlapParams.new()
	boxCheck.FilterType = Enum.RaycastFilterType.Exclude
	boxCheck.RespectCanCollide = true
	local st

	local function tell(key, text)
		if not st or st.Told[key] then return end
		st.Told[key] = true
		if Notify.Enabled and not st.Goal then
			notif('TPGlide', text, 3, 'warning')
		end
	end

	local function castDown(origin)
		local from = origin
		for _ = 1, 3 do
			local hit = workspace:Raycast(from, Vector3.new(0, -1500, 0), rayCheck)
			if not hit then return nil end
			if hit.Instance.Transparency < 1 then return hit end
			from = hit.Position - Vector3.new(0, 0.1, 0)
		end
		return nil
	end

	local function clear(x, feet, z)
		return #workspace:GetPartBoundsInBox(CFrame.new(x, feet + 2.9, z), Vector3.new(1.6, 4.6, 1.6), boxCheck) == 0
	end

	local function groundNear(x, feet, z)
		local hit = workspace:Raycast(Vector3.new(x, feet + MAX_UP + 3, z), Vector3.new(0, -(MAX_UP + MAX_DOWN + 3), 0), rayCheck)
		if hit and hit.Normal.Y > 0.7 and hit.Instance.Transparency < 1 then
			return hit
		end
		return nil
	end

	local function firm(x, y, z)
		for _, c in CORNERS do
			local hit = workspace:Raycast(Vector3.new(x + c.X, y + 1.5, z + c.Z), Vector3.new(0, -5, 0), rayCheck)
			if not (hit and hit.Instance.Transparency < 1) then return false end
		end
		return true
	end

	local function cellAt(x, feet, z)
		return Vector3.new(math.round(x / 3) * 3, math.round((feet - 1.5) / 3) * 3, math.round(z / 3) * 3)
	end

	local function blockName()
		for _, pattern in store.catchOrder do
			for item, count in store.inventory do
				if count > 0 and item:find(pattern) and bedfight.Blocks:FindFirstChild(item) then
					return item
				end
			end
		end
		return nil
	end

	local function placeStone(t, now)
		local name = blockName()
		if not name then
			tell('blocks', 'You have no blocks for the next step, so your hitbox is waiting')
			return false
		end
		st.Told.blocks = nil
		equipServer(name, 'TPGlide')
		store.placeBlock(name, t.Cell)
		t.At, t.Tries = now, t.Tries + 1
		st.PlacedAt = now
		task.delay(0.4, function()
			if st and tick() - st.PlacedAt >= 0.39 then
				syncTool('TPGlide')
			end
		end)
		return true
	end

	local function ready(t)
		if not t.Cell then return true end
		local top = t.Pos.Y
		local hit = workspace:Raycast(Vector3.new(t.Pos.X, top + 1, t.Pos.Z), Vector3.new(0, -2, 0), rayCheck)
		return hit ~= nil and math.abs(hit.Position.Y - top) < 0.3
	end

	local function enemyBeds()
		local list = {}
		local container = workspace:FindFirstChild('BedsContainer')
		local team = lplr.Team and lplr.Team.Name
		for _, bed in container and container:GetChildren() or {} do
			if bed:GetAttribute('Team') ~= team then
				local box = bed:FindFirstChild('BedHitbox')
				if box then
					table.insert(list, box.Position)
				end
			end
		end
		return list
	end

	local function nearBed(beds, position)
		for _, bed in beds do
			if (bed - position).Magnitude <= (st.Near or BedRange.Value) then
				return true
			end
		end
		return false
	end

	local function heading(beds)
		if st.Goal then
			local flat = Vector3.new(st.Goal.X - st.Pos.X, 0, st.Goal.Z - st.Pos.Z)
			if flat.Magnitude > 1 then
				st.Dir = flat.Unit
			end
			return st.Dir
		end
		if Direction.Value == 'Nearest enemy bed' then
			local best, most = nil, math.huge
			for _, bed in beds do
				local flat = Vector3.new(bed.X - st.Pos.X, 0, bed.Z - st.Pos.Z)
				if flat.Magnitude > 1 and flat.Magnitude < most then
					best, most = flat.Unit, flat.Magnitude
				end
			end
			if best then
				st.Dir = best
				return best
			end
		end
		local look = gameCamera.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude > 0.05 then
			st.Dir = flat.Unit
		end
		return st.Dir
	end

	local function onward(option, dir, hop)
		for _, angle in ONWARD do
			local way = CFrame.Angles(0, math.rad(angle), 0):VectorToWorldSpace(dir)
			for _, share in {0.6, 1} do
				local p = option.Pos + way * hop * share
				if groundNear(p.X, option.Pos.Y, p.Z) then return true end
			end
		end
		return false
	end

	local function visitedPenalty(x, z, hop)
		for _, spot in st.Visited do
			if (spot.X - x) ^ 2 + (spot.Z - z) ^ 2 < 144 then
				return hop * 0.6
			end
		end
		return 0
	end

	local function tryAngles(angles, options, dir, hop, stones, beds)
		local pos, feet = st.Pos, st.Feet
		for _, angle in angles do
			local way = CFrame.Angles(0, math.rad(angle), 0):VectorToWorldSpace(dir)
			local covered, seen = 0, 0
			for i = #RINGS, 1, -1 do
				local d = RINGS[i]
				if d <= hop then
					local x, z = pos.X + way.X * d, pos.Z + way.Z * d
					local hit = groundNear(x, feet, z)
					seen += 1
					if hit then
						covered += 1
						local size = hit.Instance.Size
						if math.max(size.X, size.Y, size.Z) <= 3.1 then
							x, z = hit.Instance.Position.X, hit.Instance.Position.Z
						end
						local y = hit.Position.Y
						local dx, dy, dz = x - pos.X, y - feet, z - pos.Z
						local ahead = dx * dir.X + dz * dir.Z
						if (ahead >= 3 or st.Stuck) and dx * dx + dy * dy + dz * dz <= hop * hop and dx * dx + dz * dz > 4 then
							local side = math.abs(dx * dir.Z - dz * dir.X)
							local landing = Vector3.new(x, y, z)
							local score = ahead + covered / seen * hop * 0.35 - math.abs(dy) * 0.5 - side * 0.1 - visitedPenalty(x, z, hop)
							if #beds > 0 and nearBed(beds, landing) then
								score += hop
							end
							local goal = st.Goal
							if goal and (x - goal.X) ^ 2 + (z - goal.Z) ^ 2 < 1600 then
								score -= math.abs(y - goal.Y) * 0.5
							end
							table.insert(options, {Pos = landing, Dist = d, Score = score})
						end
					elseif stones and d >= 6 and (math.abs(angle) <= 20 or st.Stuck) then
						table.insert(options, {
							X = x,
							Z = z,
							Dist = d,
							Stone = true,
							Score = d * way:Dot(dir) - hop * 0.5 - (angle ~= 0 and 6 or 0) - visitedPenalty(x, z, hop)
						})
					end
				end
			end
		end
	end

	local function free(a, b)
		return workspace:Spherecast(a, 1.3, b - a, rayCheck) == nil
	end

	local function route(a, b)
		local top = math.max(a.Y, b.Y)
		for _, lift in LANES do
			local y = top + lift
			if y - b.Y <= 20 then
				local p1, p2 = Vector3.new(a.X, y, a.Z), Vector3.new(b.X, y, b.Z)
				if free(a, p1) and free(p1, p2) and free(p2, b) then
					return {a, p1, p2, b}
				end
			end
		end
		if st.Through then
			return {a, b}
		end
		return nil
	end

	local exposed

	local function landNear(goal, hop)
		local from = Vector3.new(st.Pos.X, st.Feet, st.Pos.Z)
		local best, bestScore, bestRoute
		for _, r in GOAL_RINGS do
			for i = 0, 11 do
				local a = i * math.pi / 6
				local x, z = goal.X + math.cos(a) * r, goal.Z + math.sin(a) * r
				local hit = workspace:Raycast(Vector3.new(x, goal.Y + 3.5, z), Vector3.new(0, -16, 0), rayCheck)
				if hit and hit.Normal.Y > 0.7 and hit.Instance.Transparency < 1 and (not st.Open or exposed(Vector3.new(x, hit.Position.Y + 2, z), goal)) then
					local y = hit.Position.Y
					local spot = Vector3.new(x, y, z)
					local length = (spot - from).Magnitude
					if length <= hop + 2 and math.abs(y - goal.Y) <= 7 and math.abs(y - st.Feet) <= 24 and clear(x, y, z) and firm(x, y, z) then
						local score = r * 1.5 + length * 0.2
						if not bestScore or score < bestScore then
							local pts = route(st.Pos, spot + Vector3.new(0, st.Offset, 0))
							if pts then
								best, bestScore, bestRoute = spot, score, pts
							end
						end
					end
				end
			end
			if best and r >= 6 then break end
		end
		return best, bestRoute
	end

	function exposed(from, goal)
		return workspace:Raycast(from, goal - from, rayCheck) == nil
	end

	local DIRS = {
		{1, 0, 0, 1}, {-1, 0, 0, 1}, {0, 0, 1, 1}, {0, 0, -1, 1}, {0, 1, 0, 1.2}, {0, -1, 0, 1.2},
		{1, 0, 1, 1.41}, {1, 0, -1, 1.41}, {-1, 0, 1, 1.41}, {-1, 0, -1, 1.41}
	}

	local function gridPlan(goal, hop)
		local offset = st.Offset
		local grid = st.Grid
		if not grid or tick() - grid.At > 2 then
			grid = {Cache = {}, At = tick()}
			st.Grid = grid
		end
		local cache = grid.Cache
		local function open(i, j, k)
			local key = (i + 512) * 1048576 + (j + 512) * 1024 + (k + 512)
			local v = cache[key]
			if v == nil then
				v = #workspace:GetPartBoundsInBox(CFrame.new(i * 3, j * 3, k * 3), Vector3.new(2.6, 2.6, 2.6), boxCheck) == 0
				cache[key] = v
			end
			return v
		end
		local function body(i, j, k)
			return open(i, j, k) and open(i, j + 1, k)
		end
		local function feetAt(i, j, k)
			return Vector3.new(i * 3, j * 3 - 1.5, k * 3)
		end
		local si, sj, sk = math.round(st.Pos.X / 3), math.round((st.Feet + 1.5) / 3), math.round(st.Pos.Z / 3)
		local gi, gj, gk = math.round(goal.X / 3), math.round((goal.Y + 1.5) / 3), math.round(goal.Z / 3)
		local loI, hiI = math.min(si, gi) - 8, math.max(si, gi) + 8
		local loJ, hiJ = math.min(sj, gj) - 8, math.max(sj, gj) + 8
		local loK, hiK = math.min(sk, gk) - 8, math.max(sk, gk) + 8
		local radius = math.max(st.Near or 6, 6)

		local nodes, heap, size = {}, {}, 0
		local function push(node)
			size += 1
			local at = size
			heap[at] = node
			while at > 1 do
				local up = at // 2
				if heap[up].F <= node.F then break end
				heap[at], heap[up] = heap[up], node
				at = up
			end
		end
		local function pop()
			local top = heap[1]
			local last = heap[size]
			heap[size] = nil
			size -= 1
			if size > 0 then
				heap[1] = last
				local at = 1
				while true do
					local l = at * 2
					if l > size then break end
					local r = l + 1
					local c = (r <= size and heap[r].F < heap[l].F) and r or l
					if heap[c].F >= last.F then break end
					heap[at], heap[c] = heap[c], last
					at = c
				end
			end
			return top
		end
		local function heur(i, j, k)
			local dx, dy, dz = i - gi, j - gj, k - gk
			return math.sqrt(dx * dx + dy * dy + dz * dz)
		end

		local start = {I = si, J = sj, K = sk, G = 0, F = heur(si, sj, sk)}
		nodes[(si + 512) * 1048576 + (sj + 512) * 1024 + (sk + 512)] = start
		push(start)
		local ending, fallback, fallbackDistance
		local t0, count = os.clock(), 0
		while size > 0 and count < 1500 and os.clock() - t0 < 0.03 do
			local node = pop()
			if not node.Closed then
				node.Closed = true
				count += 1
				local i, j, k = node.I, node.J, node.K
				if (node == start or body(i, j, k)) and not open(i, j - 1, k) then
					local feet = feetAt(i, j, k)
					local d = (feet + Vector3.new(0, 2, 0) - goal).Magnitude
					if d <= radius and math.abs(feet.Y - goal.Y) <= 7 and (not st.Open or exposed(feet + Vector3.new(0, 2, 0), goal)) then
						ending = node
						break
					end
					if not fallbackDistance or d < fallbackDistance - 0.5 then
						fallback, fallbackDistance = node, d
					end
				end
				for _, dir in DIRS do
					local ni, nj, nk = i + dir[1], j + dir[2], k + dir[3]
					if ni >= loI and ni <= hiI and nj >= loJ and nj <= hiJ and nk >= loK and nk <= hiK and body(ni, nj, nk)
						and (dir[1] == 0 or dir[3] == 0 or (body(i + dir[1], j, k) and body(i, j, k + dir[3]))) then
						local key = (ni + 512) * 1048576 + (nj + 512) * 1024 + (nk + 512)
						local g = node.G + dir[4]
						local other = nodes[key]
						if not other then
							other = {I = ni, J = nj, K = nk, G = g, F = g + heur(ni, nj, nk), Parent = node}
							nodes[key] = other
							push(other)
						elseif not other.Closed and g < other.G then
							other.G, other.F, other.Parent = g, g + heur(ni, nj, nk), node
							push(other)
						end
					end
				end
			end
		end
		ending = ending or fallback
		if not ending or ending == start then return nil end

		local path = {}
		local at = ending
		while at do
			table.insert(path, 1, at)
			at = at.Parent
		end
		local points = {st.Pos}
		for n = 2, #path do
			local f = feetAt(path[n].I, path[n].J, path[n].K)
			points[n] = f + Vector3.new(0, offset, 0)
		end
		local reach = {0}
		for n = 2, #points do
			reach[n] = reach[n - 1] + (points[n] - points[n - 1]).Magnitude
		end

		local tried = 0
		for n = #path, 2, -1 do
			local node = path[n]
			if reach[n] <= hop * 1.6 and not open(node.I, node.J - 1, node.K) and body(node.I, node.J, node.K) then
				local feet = feetAt(node.I, node.J, node.K)
				local rise = feet.Y - st.Feet
				if rise <= MAX_UP and rise >= -MAX_DOWN then
					tried += 1
					local out = {points[1]}
					local a = 1
					local peak = points[1].Y
					while a < n do
						local b = n
						while b > a + 1 and not free(points[a], points[b]) do
							b = a + math.ceil((b - a) / 2)
						end
						table.insert(out, points[b])
						peak = math.max(peak, points[b].Y)
						a = b
					end
					local length = 0
					for m = 2, #out do
						length += (out[m] - out[m - 1]).Magnitude
					end
					if length <= hop + 2 and peak - points[n].Y <= 20 then
						return {Pos = feet, Dist = length, Route = out}
					end
					if tried >= 8 then break end
				end
			end
		end
		return nil
	end

	local function plan()
		local feet = st.Feet
		local goal = st.Goal
		local beds = goal and {goal} or (StopBed.Enabled or Direction.Value == 'Nearest enemy bed') and enemyBeds() or {}
		local dir = heading(beds)
		local hop = math.min(MAX_HOP, st.MaxHop, st.HopCap or math.huge)
		local stones = blockName() ~= nil
		local options = {}
		local scored = (goal or StopBed.Enabled) and beds or {}
		if goal then
			local left = Vector3.new(goal.X - st.Pos.X, 0, goal.Z - st.Pos.Z).Magnitude
			if left <= hop + GOAL_RINGS[#GOAL_RINGS] then
				local spot, pts = landNear(goal, hop)
				if spot then
					return {Pos = spot, Dist = (spot - Vector3.new(st.Pos.X, feet, st.Pos.Z)).Magnitude, Route = pts}
				end
				local inside = gridPlan(goal, hop)
				if inside then
					return inside
				end
			end
			hop = math.min(hop, math.max(left + 2, 8))
		end
		tryAngles(ANGLES, options, dir, hop, stones, scored)
		if st.Stuck then
			tryAngles(BEHIND, options, dir, hop, stones, scored)
		end
		local function best(a, b)
			return a.Score > b.Score
		end
		table.sort(options, best)
		local looked = 0
		for _, option in options do
			if looked >= 4 then break end
			if not option.Stone then
				looked += 1
				if onward(option, dir, hop) then
					option.Score += hop * 0.25
				end
			end
		end
		table.sort(options, best)
		local checks = 0
		for _, option in options do
			if checks >= MAX_CHECKS then break end
			if option.Stone then
				for _, level in LEVELS do
					checks += 1
					local at = feet + level
					if clear(option.X, at, option.Z) then
						local cell = cellAt(option.X, at, option.Z)
						if not st.Bad[tostring(cell)] then
							local _, info = store.buildable(cell)
							if info and not info.Collided and not info.InsideAntiBuild and info.InBounds ~= false then
								local pos = Vector3.new(cell.X, cell.Y + 1.5, cell.Z)
								local pts = route(st.Pos, pos + Vector3.new(0, st.Offset, 0))
								if pts then
									return {Pos = pos, Cell = cell, Tries = 0, Dist = option.Dist, Route = pts}
								end
							end
						end
					end
				end
			else
				checks += 1
				if clear(option.Pos.X, option.Pos.Y, option.Pos.Z) and firm(option.Pos.X, option.Pos.Y, option.Pos.Z) then
					local pts = route(st.Pos, option.Pos + Vector3.new(0, st.Offset, 0))
					if pts then
						return {Pos = option.Pos, Dist = option.Dist, Route = pts}
					end
				end
			end
		end
		if goal then
			local left = Vector3.new(goal.X - st.Pos.X, 0, goal.Z - st.Pos.Z)
			local aim = left.Magnitude > 45 and Vector3.new(st.Pos.X + left.Unit.X * 45, goal.Y, st.Pos.Z + left.Unit.Z * 45) or goal
			local around = gridPlan(aim, hop)
			if around then
				return around
			end
		end
		if not stones then
			local wanted = {}
			tryAngles(ANGLES, wanted, dir, hop, true, scored)
			for _, option in wanted do
				if option.Stone then
					tell('blocks', 'You have no blocks for the next step, so your hitbox is waiting')
					break
				end
			end
		end
		return nil
	end

	local function stop()
		if st and st.Conn then
			st.Conn:Disconnect()
		end
		if st then
			store.flyOn = nil
			syncTool('TPGlide')
		end
		st = nil
	end

	local function merge()
		if store.split and store.split.Owners.TPGlide and entitylib.isAlive then
			local body = bodyRoot()
			body.CFrame = CFrame.new(st.Real.Position) * body.CFrame.Rotation
			body.AssemblyLinearVelocity = Vector3.zero
			mergeRoot('TPGlide')
		end
		stop()
	end

	local function catch(now)
		local gy = st.Ray and st.Ray.Position.Y
		if gy and math.abs(st.Feet - gy) <= 0.6 then
			st.Feet, st.StandSince, st.Catch = gy, now, nil
			return
		end
		local c = st.Catch
		if c and ready(c) then
			st.Feet, st.StandSince, st.Catch = c.Pos.Y, now, nil
			st.Pos = Vector3.new(c.Pos.X, c.Pos.Y + st.Offset, c.Pos.Z)
			return
		end
		if not c then
			local cell = cellAt(st.Pos.X, st.Feet, st.Pos.Z)
			c = {Pos = Vector3.new(cell.X, cell.Y + 1.5, cell.Z), Cell = cell, Tries = 0}
			st.Catch = c
		end
		if not c.At or now - c.At > 1 + lplr:GetNetworkPing() then
			placeStone(c, now)
		end
	end

	local function atGoal()
		local goal = st.Goal
		return goal and (Vector3.new(goal.X - st.Pos.X, 0, goal.Z - st.Pos.Z).Magnitude <= st.Near and math.abs(goal.Y - st.Pos.Y) < 8 or (goal - st.Pos).Magnitude <= st.Near)
	end

	local function moveBody(now)
		local dt = math.min(now - (st.BodyAt or now), 0.1)
		st.BodyAt = now
		local body = bodyRoot()
		local from = body.Position
		local trail = st.Trail
		local target = trail[1] or st.Pos
		if trail[1] and (target - from).Magnitude < 1.5 then
			table.remove(trail, 1)
			target = trail[1] or st.Pos
		end
		local gap = target - from
		local dist = gap.Magnitude
		local speed = (trail[1] or dist > 8) and BODY_SPEED or math.min(dist * BODY_RATE, BODY_SPEED)
		local step = math.min(dist, speed * dt)
		local flat = Vector3.new(gap.X, 0, gap.Z)
		local rotation = body.CFrame.Rotation
		if flat.Magnitude > 1 then
			rotation = rotation:Lerp(CFrame.lookAt(Vector3.zero, flat.Unit), math.min(dt * 8, 1))
		end
		body.CFrame = CFrame.new(dist > 0.05 and from + gap.Unit * step or target) * rotation
		body.AssemblyLinearVelocity = Vector3.zero
	end

	local function frame()
		if not (st and entitylib.isAlive and store.split and store.split.Owners.TPGlide) then
			stop()
			if TPGlide.Enabled then
				TPGlide:Toggle()
			end
			return
		end
		local real, now = st.Real, tick()
		if st.Goal then
			moveBody(now)
		end
		if not isnetworkowner(real) then
			st.Pulled, st.Leg, st.Target, st.Catch = true, nil, nil, nil
			return
		end
		if st.Pulled then
			st.Pulled = false
			st.Pos = real.Position
			table.clear(st.Trail)
			st.Feet = st.Pos.Y - st.Offset
			st.StandSince = nil
			st.Rest = math.min(st.Rest + 0.4, 4)
			st.MaxHop = math.max(st.MaxHop - 10, 40)
			st.Good = 0
			st.Told.pulled = nil
			tell('pulled', ('Your hitbox was pulled back, now resting %.1fs and hopping %d studs at most'):format(st.Rest, st.MaxHop))
		end

		local leg = st.Leg
		if leg then
			local a = math.min((now - leg.T0) / leg.Dur, 1)
			local along, pts = a * leg.Length, leg.Points
			local at = pts[#pts]
			for i = 2, #pts do
				local seg = (pts[i] - pts[i - 1]).Magnitude
				if along <= seg then
					at = pts[i - 1]:Lerp(pts[i], seg > 0 and along / seg or 1)
					break
				end
				along -= seg
			end
			st.Pos = at
			sendRoot(CFrame.new(st.Pos) * st.Rot)
			if a >= 1 then
				st.Leg = nil
				st.Fails = 0
				st.Feet = leg.Feet
				st.StandSince = now
				st.HopCap = nil
				table.clear(st.Bad)
				table.insert(st.Visited, 1, st.Pos)
				st.Visited[9] = nil
				st.Good += 1
				if st.Good >= 3 then
					st.Good = 0
					st.MaxHop = math.min(st.MaxHop + 10, MAX_HOP)
					st.Rest = math.max(st.Rest - 0.2, Rest.Value)
				end
				if st.Stopping then
					return merge()
				end
			end
			return
		end

		sendRoot(CFrame.new(st.Pos) * st.Rot)
		st.Ray = castDown(st.Pos)
		if StopBed.Enabled and TPGlide.Enabled and now >= (st.BedAt or 0) then
			st.BedAt = now + 0.1
			if nearBed(enemyBeds(), st.Pos) then
				if Notify.Enabled then
					notif('TPGlide', 'Reached an enemy bed', 3)
				end
				TPGlide:Toggle()
				return
			end
		end
		if not st.StandSince then
			catch(now)
			if st.Stopping then
				return merge()
			end
			return
		end
		if st.Stopping then
			return merge()
		end
		if atGoal() then
			st.Target = nil
			return
		end

		if not (st.Target and st.Target.At) and now >= (st.PlanAt or 0) then
			st.Target = plan()
			st.PlanAt = now + 0.5
			if st.Target then
				st.Told.blocked = nil
				st.Told.blocks = nil
				st.Fails, st.Through = 0, false
			else
				st.Fails = (st.Fails or 0) + 1
				if st.Fails >= 8 and not st.Through then
					st.Through = true
					tell('walled', 'No open route, so the next hop may cross blocks')
				end
				st.HopCap = nil
				if st.Stuck then
					tell('blocked', 'Nowhere to land around you, so your hitbox is waiting')
				else
					st.Stuck, st.PlanAt = true, now
				end
			end
		end
		local t = st.Target
		if not t then return end
		local stood = now - st.StandSince
		if t.Cell and not ready(t) then
			local ping = lplr:GetNetworkPing()
			if stood >= st.Rest - 0.4 - ping and (not t.At or now - t.At > 1 + ping) then
				if t.Tries >= 3 then
					st.Bad[tostring(t.Cell)] = true
					st.Target = nil
					st.HopCap = t.Dist - 9
					tell('refused', 'A stepping block was refused, trying a shorter hop')
				else
					placeStone(t, now)
				end
			end
			return
		end
		if stood >= st.Rest then
			local to = t.Pos + Vector3.new(0, st.Offset, 0)
			local flat = Vector3.new(to.X - st.Pos.X, 0, to.Z - st.Pos.Z)
			if flat.Magnitude > 0.5 then
				st.Rot = CFrame.lookAt(Vector3.zero, flat.Unit)
			end
			local pts = t.Route or {st.Pos, to}
			local length = 0
			for i = 2, #pts do
				length += (pts[i] - pts[i - 1]).Magnitude
				if st.Goal then
					table.insert(st.Trail, pts[i])
				end
			end
			st.Leg = {Points = pts, Length = length, T0 = now, Dur = math.max(length / HOP_SPEED, 1 / 60), Feet = t.Pos.Y}
			st.Target, st.StandSince, st.Stuck = nil, nil, false
		end
	end

	local function part(name, size, color)
		local p = Instance.new('Part')
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Size = size
		p.Parent = gameCamera
		TPGlide:Clean(p)
		return p
	end

	local function outline(color, adornee)
		local box = Instance.new('SelectionBox')
		box.Color3 = color
		box.SurfaceColor3 = color
		box.SurfaceTransparency = 0.8
		box.LineThickness = 0.04
		box.Adornee = adornee
		box.Parent = gameCamera
		TPGlide:Clean(box)
		return box
	end

	local function makeVisuals()
		local v = {}
		v.Line = part('TPGlideLine', Vector3.new(0.25, 0.25, 0.1), LINE)
		v.Marker = part('TPGlideMarker', Vector3.new(0.2, 2.5, 2.5), LINE)
		v.Marker.Shape = Enum.PartType.Cylinder
		v.Beam = part('TPGlideRay', Vector3.new(0.12, 1, 0.12), RAY)
		v.Cell = part('TPGlideCell', Vector3.new(3, 3, 3), RAY)
		v.Cell.Transparency = 1
		v.NextCell = part('TPGlideNext', Vector3.new(3, 3, 3), NEXT)
		v.NextCell.Transparency = 1
		local board = Instance.new('BillboardGui')
		board.Size = UDim2.fromOffset(120, 24)
		board.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
		board.AlwaysOnTop = true
		local label = Instance.new('TextLabel')
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = LINE
		label.TextStrokeTransparency = 0.4
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.Text = '0 studs'
		label.Parent = board
		board.Parent = v.Marker
		v.Label = label
		v.Box = outline(RAY)
		v.NextBox = outline(NEXT)
		return v
	end

	local function render()
		if not (st and st.Visuals and entitylib.isAlive) then return end
		local v = st.Visuals
		local b, hb = bodyRoot().Position, st.Pos
		local a = Vector3.new(b.X, st.BaseY, b.Z)
		local c = Vector3.new(hb.X, st.BaseY, hb.Z)
		local len = (c - a).Magnitude
		v.Line.Size = Vector3.new(0.25, 0.25, math.max(len, 0.05))
		v.Line.CFrame = len > 0.05 and CFrame.lookAt((a + c) / 2, c) or CFrame.new(a)
		v.Marker.CFrame = CFrame.new(c) * CFrame.Angles(0, 0, math.pi / 2)
		local travelled = math.floor(Vector3.new(hb.X - st.Start.X, 0, hb.Z - st.Start.Z).Magnitude)
		if travelled ~= st.Shown then
			st.Shown = travelled
			v.Label.Text = travelled .. ' studs'
		end

		local hit = st.Ray
		local drop = hit and hb.Y - hit.Position.Y or 400
		v.Beam.Size = Vector3.new(0.12, math.max(drop, 0.05), 0.12)
		v.Beam.CFrame = CFrame.new(hb.X, hb.Y - drop / 2, hb.Z)

		local target
		if hit then
			local inst = hit.Instance
			local s = inst.Size
			if math.max(s.X, s.Y, s.Z) <= 12 then
				target = inst
			else
				local p = hit.Position - hit.Normal * 1.5
				local cell = Vector3.new(math.round(p.X / 3) * 3, math.round(p.Y / 3) * 3, math.round(p.Z / 3) * 3)
				if cell ~= st.CellAt then
					st.CellAt = cell
					v.Cell.CFrame = CFrame.new(cell)
				end
				target = v.Cell
			end
		end
		if target ~= st.Under then
			st.Under = target
			v.Box.Adornee = target
		end

		local t = st.Target
		local nextAt = t and (t.Cell or cellAt(t.Pos.X, t.Pos.Y, t.Pos.Z))
		if nextAt ~= st.NextAt then
			st.NextAt = nextAt
			if nextAt then
				v.NextCell.CFrame = CFrame.new(nextAt)
			end
			v.NextBox.Adornee = nextAt and v.NextCell or nil
		end
	end

	local function begin(real, grounded, dir, goal, near)
		store.flyOn = true
		local list = {gameCamera, real}
		for _, name in {'PlayersContainer', 'FakeBlocksContainer', 'DroppedItemsContainer'} do
			local container = workspace:FindFirstChild(name)
			if container then
				table.insert(list, container)
			end
		end
		if lplr.Character then
			table.insert(list, lplr.Character)
		end
		rayCheck.FilterDescendantsInstances = list
		boxCheck.FilterDescendantsInstances = list
		local offset = entitylib.character.HipHeight
		local feet = real.Position.Y - offset
		local now = tick()
		st = {
			Real = real,
			Pos = real.Position,
			Start = real.Position,
			Offset = offset,
			Feet = feet,
			BaseY = feet,
			Dir = dir,
			Rot = CFrame.lookAt(Vector3.zero, dir),
			Rest = Rest.Value,
			MaxHop = MAX_HOP,
			Good = 0,
			Visited = {},
			Bad = {},
			StandSince = grounded and now - Rest.Value * 0.5 or nil,
			PlacedAt = 0,
			Told = {},
			Goal = goal,
			Near = near,
			Trail = {},
			Fails = 0
		}
		st.Conn = runService.PreSimulation:Connect(frame)
		vape:Clean(st.Conn)
	end

	store.glide = {
		Active = function()
			return st ~= nil and st.Goal ~= nil
		end,
		Start = function(goal, near, open)
			if st then
				if st.Goal and st.Stopping then
					st.Stopping = false
					st.Goal, st.Near, st.Open = goal, near, open
					return true
				end
				return false
			end
			if store.dashOn or not entitylib.isAlive then return false end
			if store.split then
				if store.antiHit and not store.flyOn then
					store.flyOn = 'glide'
				end
				return false
			end
			if store.flyOn and store.flyOn ~= 'glide' then return false end
			local body = entitylib.character.RootPart
			local look = body.CFrame.LookVector
			local dir = Vector3.new(goal.X - body.Position.X, 0, goal.Z - body.Position.Z)
			if dir.Magnitude < 1 then
				dir = Vector3.new(look.X, 0, look.Z)
			end
			if dir.Magnitude < 0.05 then
				dir = Vector3.new(0, 0, -1)
			end
			local grounded = entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air
			local real = splitRoot('TPGlide')
			if not real then
				if store.flyOn == 'glide' then
					store.flyOn = nil
				end
				return false
			end
			begin(real, grounded, dir.Unit, goal, near)
			st.Open = open
			return true
		end,
		Goal = function(goal, near, open)
			if st and st.Goal then
				st.Goal, st.Near, st.Open = goal, near, open
			end
		end,
		Settled = function()
			return st ~= nil and st.Goal ~= nil and not st.Leg and st.StandSince ~= nil and atGoal() and (bodyRoot().Position - st.Pos).Magnitude < 3
		end,
		Action = function()
			if not st then return nil end
			if st.Leg then return 'Hopping' end
			if st.Told.blocks then return 'Out of blocks' end
			if st.Told.blocked then return 'Nowhere to land' end
			if st.Target and st.Target.Cell then return 'Placing a block' end
			return 'Resting'
		end,
		Stop = function()
			if store.flyOn == 'glide' then
				store.flyOn = nil
			end
			if not (st and st.Goal) then return end
			if store.split and store.split.Owners.TPGlide and entitylib.isAlive then
				st.Stopping = true
			else
				stop()
			end
		end
	}

	TPGlide = vape.Categories.Blatant:CreateModule({
		Name = 'TPGlide',
		Function = function(callback)
			if callback then
				if st and st.Stopping and not st.Goal then
					st.Stopping = false
					st.Under, st.CellAt, st.Shown, st.NextAt = nil, nil, nil, nil
					st.Visuals = makeVisuals()
					TPGlide:Clean(runService.RenderStepped:Connect(render))
					return
				end
				local function cancel(text)
					if Notify.Enabled then
						notif('TPGlide', text, 3)
					end
					task.defer(function()
						if TPGlide.Enabled then
							TPGlide:Toggle()
						end
					end)
				end
				if not entitylib.isAlive then return cancel('You need to be alive') end
				if store.split or store.flyOn or store.dashOn then return cancel('Another module is using your hitbox right now') end
				local body = entitylib.character.RootPart
				local look = gameCamera.CFrame.LookVector
				local dir = Vector3.new(look.X, 0, look.Z)
				if dir.Magnitude < 0.05 then
					look = body.CFrame.LookVector
					dir = Vector3.new(look.X, 0, look.Z)
				end
				dir = dir.Unit
				local grounded = entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air
				local real = splitRoot('TPGlide')
				if not real then return cancel('Could not split your hitbox right now') end
				begin(real, grounded, dir)
				st.Visuals = makeVisuals()
				TPGlide:Clean(runService.RenderStepped:Connect(render))
			elseif st and st.Goal then
				return
			else
				if st and store.split and store.split.Owners.TPGlide and entitylib.isAlive then
					st.Stopping, st.Visuals = true, nil
				else
					stop()
				end
			end
		end,
		Tooltip = 'Hops your hitbox across the map, placing blocks only when needed. Turning off brings you to it'
	})
	Direction = TPGlide:CreateDropdown({
		Name = 'Direction',
		List = {'Camera', 'Nearest enemy bed'},
		Tooltip = 'Camera - hops where you look\nNearest enemy bed - heads for the closest bed'
	})
	StopBed = TPGlide:CreateGroup({
		Name = 'Stop near enemy bed',
		Default = true,
		Tooltip = 'Stops once your hitbox is close to an enemy bed'
	})
	BedRange = StopBed:CreateSlider({
		Name = 'Bed range',
		Min = 6,
		Max = 40,
		Default = 15,
		Suffix = 'studs',
		Tooltip = 'How close the hitbox has to get to the bed'
	})
	Rest = TPGlide:CreateSlider({
		Name = 'Rest',
		Min = 1.5,
		Max = 4,
		Default = 1.6,
		Decimal = 10,
		Suffix = 's',
		Tooltip = 'How long your hitbox rests between hops'
	})
	Notify = TPGlide:CreateToggle({
		Name = 'Notify',
		Default = true
	})
end)
