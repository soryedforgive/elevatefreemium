run(function()
	local AutoObby
	local Delay
	local Skip
	local Notify
	local collection = cloneref(game:GetService('CollectionService'))
	local NUMBER_KEYS = {'Stage', 'Checkpoint', 'CheckpointNumber', 'StageNumber', 'Order', 'Index', 'Number', 'Level', 'Id', 'ID'}
	local STAT_NAMES = {'stage', 'stages', 'checkpoint', 'checkpoints', 'cp', 'level', 'levels'}
	local BAD = {'kill', 'lava', 'death', 'spawner', 'backstage', 'respawnbutton', 'skip'}
	local BUDGET = 0.006
	local run_id = 0

	local function say(text, kind)
		if Notify.Enabled then
			notif('AutoObby', text, 4, kind)
		end
	end

	local function bad(lower)
		for _, word in BAD do
			if lower:find(word, 1, true) then return true end
		end
		return false
	end

	local function groupWord(lower)
		if bad(lower) then return false end
		return lower:find('checkpoint', 1, true) or lower:find('check point', 1, true) or lower:find('stage', 1, true)
			or lower:find('spawn', 1, true) or lower:find('level', 1, true) or lower:find('^cps?$') ~= nil
	end

	local function itemWord(lower)
		if bad(lower) then return false end
		return lower:find('checkpoint', 1, true) or lower:find('check point', 1, true) or lower:find('spawnpoint', 1, true)
			or lower:find('^cp[%s_%-]*%d+$') ~= nil or lower:find('^stage[%s_%-]*%d+') ~= nil or lower:find('^level[%s_%-]*%d+') ~= nil
	end

	local function numberFromName(name)
		local digits = name:match('(%d+)%D*$')
		return digits and tonumber(digits) or nil
	end

	local function numberOf(inst)
		for _, key in NUMBER_KEYS do
			local value = tonumber(inst:GetAttribute(key))
			if value then return value end
			local child = inst:FindFirstChild(key)
			if child and child:IsA('ValueBase') then
				value = tonumber(child.Value)
				if value then return value end
			end
		end
		local value = numberFromName(inst.Name)
		if value then return value end
		local parent = inst.Parent
		for _ = 1, 2 do
			if not parent or parent == workspace then break end
			value = numberFromName(parent.Name)
			if value then return value end
			parent = parent.Parent
		end
		return nil
	end

	local function targetOf(inst)
		if inst:IsA('BasePart') then return inst end
		local spawnPad, named, touching, first
		for _, part in inst:GetDescendants() do
			if part:IsA('BasePart') then
				first = first or part
				if part:IsA('SpawnLocation') then
					spawnPad = spawnPad or part
				elseif itemWord(part.Name:lower()) or part.Name:lower():find('spawn', 1, true) or part.Name:lower():find('touch', 1, true) then
					named = named or part
				elseif part:FindFirstChildOfClass('TouchTransmitter') then
					touching = touching or part
				end
			end
		end
		return spawnPad or named or touching or (inst:IsA('Model') and inst.PrimaryPart) or first
	end

	local function groupOf(inst)
		local parent = inst.Parent
		for _ = 1, 3 do
			if not parent or parent == workspace then break end
			if groupWord(parent.Name:lower()) then return parent end
			parent = parent.Parent
		end
		return inst.Parent or workspace
	end

	local function playerOwned(inst)
		local model = inst:FindFirstAncestorOfClass('Model')
		while model do
			if model:FindFirstChildOfClass('Humanoid') then return true end
			model = model:FindFirstAncestorOfClass('Model')
		end
		return false
	end

	local function scan(mine, scope)
		local found, seen = {}, {}
		local function add(inst, weight, tagged)
			local part = targetOf(inst)
			if not part or seen[part] or playerOwned(part) then return end
			seen[part] = true
			table.insert(found, {
				Part = part,
				Number = numberOf(inst),
				Weight = weight,
				Tagged = tagged,
				Group = groupOf(inst)
			})
		end
		for _, tag in collection:GetAllTags() do
			local lower = tag:lower()
			if not bad(lower) and (lower:find('checkpoint', 1, true) or lower:find('stage', 1, true) or lower == 'cp') then
				for _, inst in collection:GetTagged(tag) do
					if inst:IsDescendantOf(workspace) then
						add(inst, 4, true)
					end
				end
			end
		end
		local started = os.clock()
		for _, inst in (scope or workspace):GetDescendants() do
			if os.clock() - started > BUDGET then
				task.wait()
				if mine ~= run_id then return nil end
				started = os.clock()
			end
			local parent = inst.Parent
			local isPart = inst:IsA('BasePart')
			if parent and (isPart or inst:IsA('Model')) then
				local lower = inst.Name:lower()
				if inst:IsA('SpawnLocation') then
					if not bad(lower) then
						add(inst, 3)
					end
				elseif itemWord(lower) then
					add(inst, isPart and 3 or 2)
				elseif parent ~= workspace and groupWord(parent.Name:lower()) then
					add(inst, 1)
				end
			end
		end
		return found
	end

	local function choose(found)
		local tagged = {}
		for _, entry in found do
			if entry.Tagged then
				table.insert(tagged, entry)
			end
		end
		if #tagged >= 2 then
			found = tagged
		end
		local groups = {}
		for _, entry in found do
			local group = groups[entry.Group]
			if not group then
				group = {Numbers = {}, Count = 0, Entries = {}}
				groups[entry.Group] = group
			end
			table.insert(group.Entries, entry)
			if entry.Number then
				local old = group.Numbers[entry.Number]
				if not old then
					group.Count += 1
				end
				if not old or entry.Weight > old.Weight then
					group.Numbers[entry.Number] = entry
				end
			end
		end
		local best
		for _, group in groups do
			if not best or group.Count > best.Count then
				best = group
			end
		end
		if best and best.Count >= 2 then
			local list = {}
			for _, entry in best.Numbers do
				table.insert(list, entry)
			end
			table.sort(list, function(a, b)
				return a.Number < b.Number
			end)
			return list, true
		end
		local strong = {}
		for _, entry in found do
			if entry.Weight >= 2 then
				table.insert(strong, entry)
			end
		end
		local pool = #strong >= 1 and strong or found
		table.clear(groups)
		return pool, false
	end

	local function nearestOrder(pool, from)
		local left, list = table.clone(pool), {}
		while #left > 0 do
			local best, dist = 1, math.huge
			for i, entry in left do
				local mag = (entry.Part.Position - from).Magnitude
				if mag < dist then
					best, dist = i, mag
				end
			end
			local entry = table.remove(left, best)
			table.insert(list, entry)
			from = entry.Part.Position
		end
		return list
	end

	local function stat()
		local holder = lplr:FindFirstChild('leaderstats')
		for _, name in STAT_NAMES do
			if holder then
				for _, value in holder:GetChildren() do
					if value:IsA('ValueBase') and value.Name:lower() == name then
						local number = tonumber(value.Value)
						if number then return number end
					end
				end
			end
			for key, value in lplr:GetAttributes() do
				if key:lower() == name and tonumber(value) then
					return tonumber(value)
				end
			end
		end
		return nil
	end

	local function signature()
		return tostring(stat())..'|'..tostring(lplr.RespawnLocation)..'|'..tostring(lplr.Team)
	end

	local function halfHeight(part)
		local cf, size = part.CFrame, part.Size
		return (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
	end

	local function moveTo(part)
		if not (entitylib.isAlive and part.Parent) then return end
		local root = entitylib.character.RootPart
		local position = part.Position
		if part.CanCollide then
			position += Vector3.new(0, halfHeight(part) + entitylib.character.HipHeight - 0.25, 0)
		end
		root.CFrame = CFrame.new(position) * root.CFrame.Rotation
		root.AssemblyLinearVelocity = Vector3.zero
		if firetouchinterest then
			pcall(firetouchinterest, root, part, 0)
			task.defer(pcall, firetouchinterest, root, part, 1)
		end
	end

	local function moveToSpot(position)
		if not entitylib.isAlive then return end
		pcall(function()
			lplr:RequestStreamAroundAsync(position)
		end)
		if not entitylib.isAlive then return end
		local root = entitylib.character.RootPart
		root.CFrame = CFrame.new(position + Vector3.new(0, entitylib.character.HipHeight + 1, 0)) * root.CFrame.Rotation
		root.AssemblyLinearVelocity = Vector3.zero
	end

	local function visit(entry, mine)
		local part = entry.Part
		local before = signature()
		local known = stat() ~= nil or part:IsA('SpawnLocation')
		moveTo(part)
		local start = os.clock()
		local retried = false
		repeat
			task.wait(0.05)
			if mine ~= run_id then return end
			if not entitylib.isAlive then
				repeat
					task.wait(0.2)
					if mine ~= run_id then return end
				until entitylib.isAlive
				moveTo(part)
				start = os.clock()
			end
			local elapsed = os.clock() - start
			if not part.CanCollide then
				moveTo(part)
			elseif not retried and known and elapsed >= math.max(Delay.Value, 0.6) and signature() == before then
				retried = true
				moveTo(part)
			end
			local moved = signature() ~= before
		until elapsed >= Delay.Value and (moved or not known or elapsed >= Delay.Value + 1.5)
		return signature() ~= before
	end

	local function keyOf(entry)
		return entry.Number or entry.Part
	end

	AutoObby = vape.Categories.Blatant:CreateModule({
		Name = 'AutoObby',
		Function = function(callback)
			run_id += 1
			if not callback then return end
			local mine = run_id
			local function finish(text, kind)
				if mine ~= run_id then return end
				say(text, kind)
				task.defer(function()
					if mine == run_id and AutoObby.Enabled then
						AutoObby:Toggle()
					end
				end)
			end
			AutoObby:Clean(task.spawn(function()
				local visited, reached = {}, 0
				local ok, err = pcall(function()
				while not entitylib.isAlive do
					task.wait(0.2)
					if mine ~= run_id then return end
				end
				local announced, scope, missed = false, nil, 0
				while true do
					local found = scan(mine, scope)
					if not found then return end
					if #found == 0 and not announced then
						return finish('No checkpoints found here', 'warning')
					end
					local list, numbered = choose(found)
					if not numbered then
						list = nearestOrder(list, entitylib.character.RootPart.Position)
					end
					local done = numbered and Skip.Enabled and stat() or nil
					local pending = {}
					for _, entry in list do
						if not visited[keyOf(entry)] and not (done and entry.Number <= done) then
							entry.Position = entry.Part.Position
							table.insert(pending, entry)
						end
					end
					if #pending == 0 then
						if not scope then break end
						scope = nil
						if missed >= 3 then break end
						missed += 1
					else
						missed = 0
						if not announced then
							announced = true
							say(('Found %d checkpoints'):format(#pending))
						end
						if numbered and workspace.StreamingEnabled and pending[1].Group ~= workspace then
							scope = pending[1].Group
						end
						for _, entry in pending do
							if not entry.Part.Parent then
								moveToSpot(entry.Position)
								task.wait(0.3)
								if mine ~= run_id then return end
								break
							end
							visited[keyOf(entry)] = true
							visit(entry, mine)
							if mine ~= run_id then return end
							reached += 1
						end
					end
				end
				if reached == 0 then
					finish('Every checkpoint is already done')
				else
					finish(('Finished, visited %d checkpoints'):format(reached))
				end
				end)
				if not ok then
					warn('[ElevateV4] AutoObby: '..tostring(err))
					finish('Stopped because of an error, see the console', 'warning')
				end
			end))
		end,
		Tooltip = 'Teleports you to every checkpoint in order until none are left'
	})
	Delay = AutoObby:CreateSlider({
		Name = 'Delay',
		Min = 0.1,
		Max = 3,
		Default = 0.5,
		Decimal = 10,
		Suffix = 's',
		Tooltip = 'How long to stay on each checkpoint'
	})
	Skip = AutoObby:CreateToggle({
		Name = 'Skip finished',
		Default = true,
		Tooltip = 'Skips checkpoints you have already reached'
	})
	Notify = AutoObby:CreateToggle({
		Name = 'Notify',
		Default = true,
		Tooltip = 'Tells you how many checkpoints it found and when it is done'
	})
end)
