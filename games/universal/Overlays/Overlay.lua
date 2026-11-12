run(function()
	local Overlay
	local O = {}
	local state = {
		frames = {},
		samples = {},
		history = {},
		status = 'GOOD',
		lowSince = nil,
		awaitRecovery = nil,
		cooldownUntil = 0,
		lastEvent = nil,
		events = {},
		transitions = {},
		enabled = {},
		lastScan = 0,
		auto = {Active = false, RecoverSince = nil, Disabled = {}, StartedAt = 0},
		performanceMode = false,
		errors = {},
		startedAt = os.clock(),
		lastNotifyAt = 0,
	}
	local hud, titleLabel, bodyLabel, graphFrame, graphBars = nil, nil, nil, nil, {}
	local ui = {}
	local rafConn, scanLoop = nil, nil
	local nextSampleAt = 0

	local ACCENT = Color3.fromRGB(190, 115, 255)
	local BAD = Color3.fromRGB(250, 80, 80)
	local WARN = Color3.fromRGB(236, 160, 43)
	local GOOD = Color3.fromRGB(99, 220, 130)

	local function toHex(color)
		return string.format('#%02x%02x%02x', math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
	end

	local function textList(option)
		if not option then return {} end
		return option.ListEnabled or option.Value or {}
	end

	local function modules()
		local list = {}
		for _, module in pairs(vape.Modules or {}) do table.insert(list, module) end
		for _, panel in ipairs({vape.Legit, vape.Kits}) do
			if panel and panel.Modules then
				for _, module in pairs(panel.Modules) do table.insert(list, module) end
			end
		end
		return list
	end

	local function moduleConnections(module)
		local count = 0
		for _, connection in ipairs(module.Connections or {}) do
			if typeof(connection) == 'RBXScriptConnection' then
				count += 1
			end
		end
		return count
	end

	local function entityCount()
		local library = vape.Libraries and vape.Libraries.entity
		return library and library.List and #library.List or 0
	end

	local function currentPing()
		local ok, value = pcall(function() return lplr:GetNetworkPing() end)
		local ping = ok and tonumber(value)
		if ping and ping > 0 then
			return math.floor(ping * 1000 + 0.5)
		end
		return nil
	end

	local function currentStore()
		local ok, store = pcall(function() return getgenv and getgenv().store end)
		return ok and type(store) == 'table' and store or nil
	end

	local function currentKit()
		local store = currentStore()
		local kit = store and (store.equippedKit or store.kit) or nil
		if not kit or kit == '' or kit == 'none' then
			kit = lplr:GetAttribute('PlayingAsKit') or lplr:GetAttribute('PlayingAsKits')
		end
		return kit and tostring(kit) ~= '' and tostring(kit) or nil
	end

	local function gameActivity()
		local character = lplr and lplr.Character
		local humanoid = character and character:FindFirstChildOfClass('Humanoid')
		local root = character and (character.PrimaryPart or character:FindFirstChild('HumanoidRootPart'))
		if not root then return 'no character' end
		local activity = humanoid and humanoid.MoveDirection.Magnitude > 0.05 and 'moving' or 'standing'
		if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
			activity = activity..', airborne'
		end
		return activity
	end

	local profiler = vape.Libraries and vape.Libraries.profiler
	local statsService = cloneref(game:GetService('Stats'))
	local contentProvider = cloneref(game:GetService('ContentProvider'))
	local ENGINE_STATS = {
		{'Heartbeat', 'HeartbeatTimeMs'}, {'Physics', 'PhysicsStepTimeMs'},
		{'RenderCPU', 'RenderCPUFrameTime'}, {'RenderGPU', 'RenderGPUFrameTime'},
		{'Instances', 'InstanceCount'}, {'Primitives', 'PrimitivesCount'},
		{'Moving', 'MovingPrimitivesCount'}, {'Contacts', 'ContactsCount'},
		{'Recv', 'DataReceiveKbps'}, {'Send', 'DataSendKbps'},
	}
	local readableStats
	local function readStat(object, key)
		return object[key]
	end

	local function readEngine()
		local out = {}
		if not readableStats then
			readableStats = {}
			for _, entry in ENGINE_STATS do
				local ok, value = pcall(readStat, statsService, entry[2])
				if ok and tonumber(value) then table.insert(readableStats, entry) end
			end
		end
		for _, entry in readableStats do
			local ok, value = pcall(readStat, statsService, entry[2])
			value = ok and tonumber(value) or nil
			if value and (entry[1] == 'RenderCPU' or entry[1] == 'RenderGPU') and value < 1 then value *= 1000 end
			out[entry[1]] = value
		end
		local ok, memory = pcall(function() return statsService:GetTotalMemoryUsageMb() end)
		if ok then out.Memory = tonumber(memory) end
		local queueOk, queue = pcall(function() return contentProvider.RequestQueueSize end)
		if queueOk then out.Assets = tonumber(queue) end
		return out
	end

	local activity
	local activityConnections = {}
	local function freshActivity()
		return {Adds = 0, Removes = 0, GuiAdds = 0, Classes = {}, Dealt = 0, Taken = 0, Kills = 0, Deaths = 0,
			Placed = 0, Broken = 0, Beds = 0, Respawned = false}
	end
	activity = freshActivity()

	local function takeActivity()
		local out = activity
		activity = freshActivity()
		return out
	end

	local function track(signal, callback)
		local ok, connection = pcall(function() return signal:Connect(callback) end)
		if ok and connection then table.insert(activityConnections, connection) end
	end

	local function startActivity()
		activity = freshActivity()
		track(workspace.DescendantAdded, function(object)
			activity.Adds += 1
			local class = object.ClassName
			activity.Classes[class] = (activity.Classes[class] or 0) + 1
		end)
		track(workspace.DescendantRemoving, function() activity.Removes += 1 end)
		local playerGui = lplr:FindFirstChildOfClass('PlayerGui')
		if playerGui then
			track(playerGui.DescendantAdded, function() activity.GuiAdds += 1 end)
		end
		track(lplr.CharacterAdded, function() activity.Respawned = true end)
		local events = getgenv and getgenv().vapeEvents
		local function event(name)
			local value = type(events) == 'table' and rawget(events, name)
			return typeof(value) == 'Instance' and value:IsA('BindableEvent') and value.Event or nil
		end
		local damage = event('EntityDamageEvent')
		if damage then
			track(damage, function(data)
				local character = lplr.Character
				if type(data) ~= 'table' or not character then return end
				if data.fromEntity == character then activity.Dealt += 1 end
				if data.entityInstance == character then activity.Taken += 1 end
			end)
		end
		local death = event('EntityDeathEvent')
		if death then
			track(death, function(data)
				local character = lplr.Character
				if type(data) ~= 'table' or not character then return end
				if data.fromEntity == character and data.entityInstance ~= character then activity.Kills += 1 end
				if data.entityInstance == character then activity.Deaths += 1 end
			end)
		end
		local placed = event('PlaceBlockEvent')
		if placed then
			track(placed, function(data)
				if type(data) == 'table' and data.player == lplr then activity.Placed += 1 end
			end)
		end
		local broken = event('BreakBlockEvent')
		if broken then
			track(broken, function(data)
				if type(data) == 'table' and data.player == lplr then activity.Broken += 1 end
			end)
		end
		local beds = event('BedwarsBedBreak')
		if beds then track(beds, function() activity.Beds += 1 end) end
	end

	local function stopActivity()
		for _, connection in activityConnections do
			pcall(function() connection:Disconnect() end)
		end
		table.clear(activityConnections)
	end

	local function playerSnapshot()
		local snap = {Nearby = 0}
		local character = lplr.Character
		local humanoid = character and character:FindFirstChildOfClass('Humanoid')
		local root = character and (character.PrimaryPart or character:FindFirstChild('HumanoidRootPart'))
		if root then
			local velocity = root.AssemblyLinearVelocity
			snap.Speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
			snap.Vertical = velocity.Y
			for _, player in playersService:GetPlayers() do
				if player ~= lplr then
					local other = player.Character
					local otherRoot = other and other.PrimaryPart
					if otherRoot and (otherRoot.Position - root.Position).Magnitude <= 30 then
						snap.Nearby += 1
					end
				end
			end
		end
		if humanoid then
			snap.Health = humanoid.Health
			snap.Airborne = humanoid.FloorMaterial == Enum.Material.Air
			snap.Moving = humanoid.MoveDirection.Magnitude > 0.05
			snap.State = humanoid:GetState().Name
		end
		local store = currentStore()
		local held = store and store.hand and store.hand.tool
		if typeof(held) == 'Instance' then
			snap.Tool = held.Name
		else
			local tool = character and character:FindFirstChildOfClass('Tool')
			snap.Tool = tool and tool.Name or nil
		end
		snap.Mouse1 = inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		snap.Mouse2 = inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
		local menuOk, menuVisible = pcall(function() return vape.gui.ScaledGui.ClickGui.Visible end)
		snap.Menu = menuOk and menuVisible == true
		return snap
	end

	local function describeKey(key)
		if profiler then return profiler.Describe(key) end
		return {File = tostring(key), Line = 0, Label = tostring(key), Pack = '?'}
	end

	local function topClasses(classes, limit)
		local list = {}
		for class, count in classes do list[#list + 1] = {class, count} end
		table.sort(list, function(a, b) return a[2] > b[2] end)
		local out = {}
		for index = 1, math.min(limit, #list) do out[index] = list[index][1]..' '..list[index][2] end
		return table.concat(out, ', ')
	end

	local function aggregate(from, to)
		local agg = {Samples = 0, Frames = 0, FrameMs = 0, Worst = 0, AeMs = 0, Code = {}, HeapDrop = 0,
			HeapFirst = nil, HeapLast = nil, Engine = {}, EngineMax = {}, EngineCount = {},
			Act = freshActivity(), Players = {}, Fps = {}}
		for _, entry in state.samples do
			if entry.At >= from and entry.At <= to then
				agg.Samples += 1
				agg.Fps[#agg.Fps + 1] = math.floor(entry.Fps + 0.5)
				agg.Frames += entry.FrameCount or 0
				agg.FrameMs += entry.IntervalMs or 0
				agg.Worst = math.max(agg.Worst, entry.WorstMs or 0)
				agg.AeMs += entry.AeMs or 0
				agg.HeapDrop = math.max(agg.HeapDrop, entry.HeapDrop or 0)
				agg.HeapFirst = agg.HeapFirst or entry.Heap
				agg.HeapLast = entry.Heap or agg.HeapLast
				for _, cost in entry.Prof or {} do
					local slot = agg.Code[cost.Key]
					if not slot then
						slot = {Key = cost.Key, Kind = cost.Kind, Time = 0, Calls = 0, Alloc = 0, Max = 0}
						agg.Code[cost.Key] = slot
					end
					slot.Time += cost.Time
					slot.Calls += cost.Calls
					slot.Alloc += cost.Alloc
					slot.Max = math.max(slot.Max, cost.Max)
				end
				for name, value in entry.Engine or {} do
					agg.Engine[name] = (agg.Engine[name] or 0) + value
					agg.EngineCount[name] = (agg.EngineCount[name] or 0) + 1
					agg.EngineMax[name] = math.max(agg.EngineMax[name] or value, value)
				end
				local act = entry.Act
				if act then
					for _, name in {'Adds', 'Removes', 'GuiAdds', 'Dealt', 'Taken', 'Kills', 'Deaths', 'Placed', 'Broken', 'Beds'} do
						agg.Act[name] += act[name] or 0
					end
					agg.Act.Respawned = agg.Act.Respawned or act.Respawned
					for class, count in act.Classes or {} do
						agg.Act.Classes[class] = (agg.Act.Classes[class] or 0) + count
					end
				end
				if entry.Player then agg.Players[#agg.Players + 1] = entry.Player end
			end
		end
		for name, total in agg.Engine do agg.Engine[name] = total / agg.EngineCount[name] end
		agg.AvgFrameMs = agg.Frames > 0 and agg.FrameMs / agg.Frames or 0
		agg.Seconds = math.max(to - from, 0.25)
		return agg
	end

	local function codeByFile(code, frames)
		local files = {}
		for _, slot in code do
			local described = describeKey(slot.Key)
			local file = files[described.File]
			if not file then
				file = {File = described.File, Time = 0, Calls = 0, Alloc = 0, Max = 0, Top = nil}
				files[described.File] = file
			end
			file.Time += slot.Time
			file.Calls += slot.Calls
			file.Alloc += slot.Alloc
			file.Max = math.max(file.Max, slot.Max)
			if not file.Top or slot.Time > file.Top.Time then
				file.Top = {Label = described.Label, Kind = slot.Kind, Time = slot.Time}
			end
		end
		local list = {}
		for _, file in files do
			file.PerFrame = frames > 0 and file.Time * 1000 / frames or 0
			list[#list + 1] = file
		end
		table.sort(list, function(a, b) return a.Time > b.Time end)
		return list
	end

	local function fmt(value, decimals)
		if tonumber(value) == nil then return '?' end
		return string.format('%.'..(decimals or 1)..'f', tonumber(value))
	end

	local function describeDoing(agg)
		local players = agg.Players
		if #players == 0 then return {'no character data'} end
		local lines = {}
		local maxSpeed, minVertical, airborne, moving, mouse1, mouse2, menu, nearby = 0, 0, 0, 0, 0, 0, false, 0
		local tools, states = {}, {}
		for _, snap in players do
			maxSpeed = math.max(maxSpeed, snap.Speed or 0)
			minVertical = math.min(minVertical, snap.Vertical or 0)
			if snap.Airborne then airborne += 1 end
			if snap.Moving then moving += 1 end
			if snap.Mouse1 then mouse1 += 1 end
			if snap.Mouse2 then mouse2 += 1 end
			if snap.Menu then menu = true end
			nearby = math.max(nearby, snap.Nearby or 0)
			if snap.Tool then tools[snap.Tool] = true end
			if snap.State then states[snap.State] = true end
		end
		local count = #players
		local movement = moving > count / 2 and string.format('moving (up to %s studs/s)', fmt(maxSpeed, 0)) or 'mostly standing still'
		if airborne > 0 then
			movement ..= airborne == count and ', in the air the whole time' or ', partly in the air'
			if minVertical < -40 then movement ..= string.format(', falling at up to %s studs/s', fmt(-minVertical, 0)) end
		end
		lines[#lines + 1] = 'Movement: '..movement
		local toolList = {}
		for tool in tools do toolList[#toolList + 1] = tool end
		lines[#lines + 1] = 'Holding: '..(#toolList > 0 and table.concat(toolList, ', ') or 'nothing')
		local input = {}
		if mouse1 > 0 then input[#input + 1] = 'left mouse held (attacking / mining)' end
		if mouse2 > 0 then input[#input + 1] = 'right mouse held (placing / aiming)' end
		if menu then input[#input + 1] = 'ElevateV4 menu open' end
		lines[#lines + 1] = 'Input: '..(#input > 0 and table.concat(input, ', ') or 'no mouse buttons held')
		local act = agg.Act
		local fight = {}
		if act.Dealt > 0 then fight[#fight + 1] = act.Dealt..' hit(s) dealt' end
		if act.Taken > 0 then fight[#fight + 1] = act.Taken..' hit(s) taken' end
		if act.Kills > 0 then fight[#fight + 1] = act.Kills..' kill(s)' end
		if act.Deaths > 0 then fight[#fight + 1] = 'you died' end
		if act.Respawned then fight[#fight + 1] = 'you respawned' end
		lines[#lines + 1] = 'Combat: '..(#fight > 0 and table.concat(fight, ', ') or 'none')..string.format(' - %d player(s) within 30 studs', nearby)
		local world = {}
		if act.Placed > 0 then world[#world + 1] = act.Placed..' block(s) placed' end
		if act.Broken > 0 then world[#world + 1] = act.Broken..' block(s) broken' end
		if act.Beds > 0 then world[#world + 1] = act.Beds..' bed(s) destroyed' end
		if #world > 0 then lines[#lines + 1] = 'World: '..table.concat(world, ', ') end
		local stateList = {}
		for name in states do stateList[#stateList + 1] = name end
		if #stateList > 0 then lines[#lines + 1] = 'Humanoid state: '..table.concat(stateList, ', ') end
		return lines
	end

	local function diagnose(from, to)
		local window = aggregate(from, to)
		local base = aggregate(from - 10, from - 1)
		local causes = {}
		local function cause(score, confidence, title, detail, advice)
			causes[#causes + 1] = {Score = score, Confidence = confidence, Title = title, Detail = detail, Advice = advice}
		end
		local frameMs = math.max(window.AvgFrameMs, 1)
		local aePerFrame = window.Frames > 0 and window.AeMs / window.Frames or 0
		local aeShare = aePerFrame / frameMs
		local files = codeByFile(window.Code, window.Frames)
		local slowCalls = profiler and profiler.SlowCalls(from - 0.25) or {}
		local longest
		for _, call in slowCalls do
			if call.At <= to + 0.25 and (not longest or call.Ms > longest.Ms) then longest = call end
		end

		if profiler and (aeShare >= 0.2 or (longest and longest.Ms >= 25)) then
			local top = files[1]
			local name = top and top.File or 'ElevateV4'
			local confidence = (aeShare >= 0.5 or (longest and longest.Ms >= window.Worst * 0.5)) and 'Confirmed' or 'Likely'
			local detail = string.format('ElevateV4 code ran %sms per frame (%d%% of the %sms frame)', fmt(aePerFrame), math.floor(aeShare * 100), fmt(frameMs))
			if top then detail ..= string.format('; %s alone %sms per frame (busiest line %s)', top.File, fmt(top.PerFrame), top.Top and top.Top.Label or '?') end
			if longest then
				local described = describeKey(longest.Key)
				detail ..= string.format('; longest single run %s took %sms', described.Label, fmt(longest.Ms))
			end
			cause(aeShare * 100 + (longest and longest.Ms or 0), confidence, 'ElevateV4: '..name, detail,
				'Turn '..name:gsub('%.lua$', ''):match('[^/]+$')..' off to confirm, and send this report so it can be optimised')
		end

		if window.HeapDrop >= 4096 then
			local allocRate = 0
			for _, slot in base.Code do allocRate += slot.Alloc end
			allocRate /= math.max(base.Seconds, 1)
			local spike = window.Worst >= 40
			local topAlloc = {}
			local allocFiles = codeByFile(base.Code, base.Frames)
			table.sort(allocFiles, function(a, b) return a.Alloc > b.Alloc end)
			for index = 1, math.min(3, #allocFiles) do
				if allocFiles[index].Alloc > 0 then
					topAlloc[#topAlloc + 1] = string.format('%s %sKB/s', allocFiles[index].File, fmt(allocFiles[index].Alloc / math.max(base.Seconds, 1), 0))
				end
			end
			cause(spike and 60 or 25, spike and 'Likely' or 'Possible', 'Lua garbage collection',
				string.format('the Lua heap dropped by %sMB in one frame (%sMB -> %sMB); ElevateV4 code was allocating about %sKB/s before it%s',
					fmt(window.HeapDrop / 1024), fmt((window.HeapFirst or 0) / 1024), fmt((window.HeapLast or 0) / 1024), fmt(allocRate, 0),
					#topAlloc > 0 and (' (most: '..table.concat(topAlloc, ', ')..')') or ''),
				'A collection pause is caused by allocation over the previous seconds, not by the code running at that moment')
		end

		local adds = window.Act.Adds
		local baseAddsPerSecond = base.Act.Adds / math.max(base.Seconds, 1)
		local addsPerSecond = adds / window.Seconds
		if adds >= 300 or (addsPerSecond >= 150 and addsPerSecond >= baseAddsPerSecond * 4) then
			local listeners = profiler and profiler.Listeners(workspace.DescendantAdded) or {}
			cause(math.min(addsPerSecond / 20, 60), adds >= 1000 and 'Likely' or 'Possible', 'Burst of new objects in the world',
				string.format('%d instances were created in %ss (normally %d/s); most were %s', adds, fmt(window.Seconds), math.floor(baseAddsPerSecond),
					topClasses(window.Act.Classes, 4))
				..(#listeners > 0 and ('; ElevateV4 handlers that run for every new object: '..table.concat(listeners, ', ')) or ''),
				'Effects, explosions, projectiles or map streaming. FPSBoost (Performance profile) removes most visual effects')
		end
		if window.Act.GuiAdds >= 200 then
			local playerGui = lplr:FindFirstChildOfClass('PlayerGui')
			local listeners = profiler and playerGui and profiler.Listeners(playerGui.DescendantAdded) or {}
			cause(20, 'Possible', 'Burst of new GUI elements',
				string.format('%d GUI objects were created in %ss', window.Act.GuiAdds, fmt(window.Seconds))
				..(#listeners > 0 and ('; ElevateV4 handlers on each one: '..table.concat(listeners, ', ')) or ''),
				'Usually a menu, the shop or kill-feed/damage numbers being built')
		end

		local function engineRise(name, minimum, ratio)
			local now, before = window.EngineMax[name], base.Engine[name]
			if now and now >= minimum and (not before or now >= before * ratio) then return now, before end
		end
		local physics, physicsBefore = engineRise('Physics', 6, 2)
		if physics then
			cause(physics * 2, 'Likely', 'Physics',
				string.format('physics took up to %sms per step (normally %sms); moving parts %s, contacts %s', fmt(physics), fmt(physicsBefore),
					tostring(window.EngineMax.Moving or '?'), tostring(window.EngineMax.Contacts or '?')),
				'Many moving or colliding parts: explosions, falling blocks, lots of players or projectiles')
		end
		local heartbeat, heartbeatBefore = engineRise('Heartbeat', 12, 1.8)
		if heartbeat and not physics then
			cause(heartbeat, 'Possible', 'Game scripts and simulation',
				string.format('the heartbeat step took up to %sms (normally %sms) without ElevateV4 code accounting for it', fmt(heartbeat), fmt(heartbeatBefore)),
				'The game itself was busy; ElevateV4 handlers on game events are not timed, see the listeners above')
		end
		local renderCpu = engineRise('RenderCPU', 12, 1.5)
		local renderGpu = engineRise('RenderGPU', 12, 1.5)
		if renderCpu or renderGpu then
			cause(math.max(renderCpu or 0, renderGpu or 0), 'Likely', 'Rendering',
				string.format('render CPU %sms, GPU %sms per frame at peak', fmt(renderCpu or window.EngineMax.RenderCPU), fmt(renderGpu or window.EngineMax.RenderGPU)),
				'Too much to draw: effects, particles, many parts on screen. Try FPSBoost or lower graphics quality')
		end
		local recv, recvBefore = engineRise('Recv', 60, 2)
		if recv then
			cause(15, 'Possible', 'Network burst', string.format('receiving %skbps (normally %skbps)', fmt(recv, 0), fmt(recvBefore, 0)),
				'The server sent a lot at once (map changes, many players, item drops)')
		end
		if (window.EngineMax.Assets or 0) >= 10 then
			cause(20, 'Possible', 'Assets loading', string.format('%d assets were waiting to load', window.EngineMax.Assets),
				'Textures, sounds or meshes streaming in')
		end
		if window.Act.Respawned or window.Act.Deaths > 0 then
			cause(30, 'Possible', 'Death / respawn', 'your character died or respawned during the drop',
				'Respawning rebuilds your character and HUD, and character modules (Legless, Headless, TransparentCharacter, ArmourTrims, NameTagSpoofer) re-apply')
		end
		if window.Worst >= 500 then
			local culprits, nearest = {}, nil
			for _, call in slowCalls do
				if call.At >= from - 0.5 and call.At <= to + 0.5 then
					if call.Ms >= window.Worst * 0.25 then
						culprits[#culprits + 1] = describeKey(call.Key).Label..' '..fmt(call.Ms)..'ms'
					end
					if not nearest or call.Ms > nearest.Ms then nearest = call end
				end
			end
			cause(window.Worst / 10, #culprits > 0 and 'Likely' or 'Possible', 'Freeze',
				string.format('one frame took %sms', fmt(window.Worst, 0))
				..(#culprits > 0 and ('; ElevateV4 code running then: '..table.concat(culprits, ', '))
					or ('; no timed ElevateV4 code ran long enough to explain it'
						..(nearest and string.format(' (longest nearby: %s %sms)', describeKey(nearest.Key).Label, fmt(nearest.Ms)) or ''))),
				#culprits > 0 and 'That code is the freeze'
					or 'A freeze no timed code explains is the game, an untimed event handler, the executor or the system (memory pressure, asset loading, background programs)')
		end
		if #causes == 0 then
			cause(0, 'Unknown', 'Not explained by anything measured',
				string.format('ElevateV4 code used %sms per frame (%d%%); no GC pause, object burst, physics, render or network spike was seen', fmt(aePerFrame), math.floor(aeShare * 100)),
				'Most likely outside the game: GPU, thermal throttling, background programs or the executor')
		end
		table.sort(causes, function(a, b) return a.Score > b.Score end)

		local engine = {}
		local function engineLine(label, name, unit, decimals)
			if window.EngineMax[name] then
				engine[#engine + 1] = string.format('%s: avg %s%s, peak %s%s (before: %s%s)', label, fmt(window.Engine[name], decimals), unit,
					fmt(window.EngineMax[name], decimals), unit, base.Engine[name] and fmt(base.Engine[name], decimals) or '?', unit)
			end
		end
		engineLine('Heartbeat', 'Heartbeat', 'ms', 1)
		engineLine('Physics step', 'Physics', 'ms', 1)
		engineLine('Render CPU', 'RenderCPU', 'ms', 1)
		engineLine('Render GPU', 'RenderGPU', 'ms', 1)
		engineLine('Instances', 'Instances', '', 0)
		engineLine('Moving parts', 'Moving', '', 0)
		engineLine('Contacts', 'Contacts', '', 0)
		engineLine('Receive', 'Recv', 'kbps', 0)
		engineLine('Send', 'Send', 'kbps', 0)
		engineLine('Memory', 'Memory', 'MB', 0)
		engineLine('Asset queue', 'Assets', '', 0)
		engine[#engine + 1] = string.format('Lua heap: %sMB -> %sMB, largest single-frame drop %sMB', fmt((window.HeapFirst or 0) / 1024),
			fmt((window.HeapLast or 0) / 1024), fmt(window.HeapDrop / 1024))
		engine[#engine + 1] = string.format('World objects: %d created, %d removed%s; GUI objects created: %d', window.Act.Adds, window.Act.Removes,
			window.Act.Adds > 0 and (' ('..topClasses(window.Act.Classes, 5)..')') or '', window.Act.GuiAdds)

		local slowList = {}
		for _, call in slowCalls do
			if call.At <= to + 0.25 then
				slowList[#slowList + 1] = string.format('%s %s (%s) %sms, %sKB', os.date('%H:%M:%S', os.time() - math.floor(os.clock() - call.At)),
					describeKey(call.Key).Label, tostring(call.Kind), fmt(call.Ms), fmt(call.AllocKb, 0))
			end
		end

		return {
			Causes = causes,
			Files = files,
			AePerFrame = aePerFrame,
			AeShare = aeShare,
			FrameMs = frameMs,
			Worst = window.Worst,
			Frames = window.Frames,
			Duration = to - from,
			Fps = window.Fps,
			BeforeFps = base.Fps,
			Engine = engine,
			Doing = describeDoing(window),
			Slow = slowList,
			Measured = profiler ~= nil,
		}
	end

	local function dropOldest(list, count)
		local size = #list
		count = math.min(count, size)
		table.move(list, count + 1, size, 1)
		for index = size - count + 1, size do list[index] = nil end
	end

	local percentileBuffer = {}
	local function framePercentile(percent)
		local frames = state.frames
		local count = #frames
		if count == 0 then return 0 end
		local times = percentileBuffer
		for index = 1, count do times[index] = frames[index].Dt end
		for index = count + 1, #times do times[index] = nil end
		table.sort(times)
		local slice = math.max(1, math.floor(count * percent / 100))
		local total = 0
		for index = count - slice + 1, count do total += times[index] end
		local average = total / slice
		return average > 0 and 1 / average or 0
	end

	local function averageFrames()
		local frames = state.frames
		local count = #frames
		if count == 0 then return 0, 0 end
		local total = 0
		for index = 1, count do total += frames[index].Dt end
		local average = total / count
		return average > 0 and 1 / average or 0, average
	end

	local function enabledModules()
		local list = {}
		for name, entry in pairs(state.enabled) do
			table.insert(list, {Name = name, Module = entry.Module, Connections = entry.Connections})
		end
		table.sort(list, function(a, b)
			if a.Connections == b.Connections then return a.Name < b.Name end
			return a.Connections > b.Connections
		end)
		return list
	end

	local function enabledCount()
		local count = 0
		for _ in pairs(state.enabled) do count += 1 end
		return count
	end

	local function scanModules(now)
		if now - state.lastScan < 0.75 then return end
		state.lastScan = now
		local snapshot = {}
		for _, module in ipairs(modules()) do
			if module.Name ~= Overlay.Name then
				if module.Enabled then
					if state.enabled[module.Name] == nil then
						table.insert(state.transitions, {At = now, Name = module.Name, Enabled = true})
					end
					snapshot[module.Name] = {Module = module, Connections = moduleConnections(module)}
				elseif state.enabled[module.Name] then
					table.insert(state.transitions, {At = now, Name = module.Name, Enabled = false})
				end
			end
		end
		while #state.transitions > 60 do table.remove(state.transitions, 1) end
		state.enabled = snapshot
	end

	local function baselineFps()
		local now = os.clock()
		local total, count = 0, 0
		for index = #state.samples, 1, -1 do
			local sample = state.samples[index]
			local age = now - sample.At
			if age < 3 then continue end
			if age > 15 then break end
			total += sample.Fps
			count += 1
		end
		if count >= 2 then return total / count end
		if state.baseline then return state.baseline end
		return state.lastFps or 0
	end

	local function attribute(now, event)
		local recent = {}
		for index = #state.transitions, 1, -1 do
			local transition = state.transitions[index]
			if now - transition.At > 15 then break end
			recent[#recent + 1] = string.format('%s %s %.1fs before', transition.Name, transition.Enabled and 'on' or 'off', now - transition.At)
		end
		local evidence = {}
		if #recent >= 10 then
			evidence[1] = string.format('%d modules changed state in the 15s before (a profile load or reinject), so none of them is singled out', #recent)
		elseif #recent > 0 then
			evidence[1] = 'Module switches in the 15s before: '..table.concat(recent, ', ')
		else
			evidence[1] = 'No module was switched on or off in the 15s before'
		end
		return nil, nil, evidence
	end

	local function notifyEvent(event)
		if not (O.Notify and O.Notify.Enabled) then return end
		local now = os.clock()
		local cooldown = tonumber(O.NotifyCooldown and O.NotifyCooldown.Value) or 15
		if now < state.lastNotifyAt + cooldown then return end
		state.lastNotifyAt = now
		local text = string.format('FPS dropped from %d to %d', math.floor(event.Before + 0.5), math.floor(event.During + 0.5))
		if O.ShowSuspect and O.ShowSuspect.Enabled and event.Suspect then
			text = string.format('%s - %s (%s). Copy the debug report for details', text, event.Suspect, event.Confidence)
		end
		local severity = (O.Severity and O.Severity.Value) or 'warning'
		pcall(function() vape:CreateNotification('Performance Monitor', text, 6, severity) end)
	end

	local function findModule(name)
		local helper = getgenv and getgenv().getAetherModule
		if type(helper) == 'function' then
			local module = helper(name)
			if module then return module end
		end
		for _, module in ipairs(modules()) do
			if module.Name == name then return module end
		end
	end

	local function restoreAuto()
		if not state.auto.Active then return end
		if O.Restore and O.Restore.Enabled then
			for _, name in ipairs(state.auto.Disabled) do
				local module = findModule(name)
				if module and not module.Enabled and type(module.Toggle) == 'function' then
					pcall(function() module:Toggle() end)
				end
			end
		end
		if state.lastEvent then
			state.lastEvent.Auto = state.lastEvent.Auto or {}
			state.lastEvent.Auto.RestoredAt = os.clock()
			state.lastEvent.Auto.Restored = (O.Restore and O.Restore.Enabled) == true
			state.lastEvent.Auto.Duration = os.clock() - state.auto.StartedAt
		end
		state.auto.Active = false
		state.auto.Disabled = {}
		state.auto.RecoverSince = nil
		state.performanceMode = false
	end

	local function runAuto(event)
		if not (O.AutoActions and O.AutoActions.Enabled) then return end
		local fps = event.During
		if fps > (tonumber(O.TriggerFps and O.TriggerFps.Value) or 60) then return end
		state.auto.Active = true
		state.auto.StartedAt = os.clock()
		state.auto.RecoverSince = nil
		state.auto.Disabled = {}
		state.auto.Before = event.Before
		event.Auto = {Action = {}, Affected = {}, Previous = {}, Restored = false}

		if O.PerformanceMode and O.PerformanceMode.Enabled then
			state.performanceMode = true
			table.insert(event.Auto.Action, 'performance mode')
		end
		if O.DisableModules and O.DisableModules.Enabled then
			for _, name in ipairs(textList(O.AllowedModules)) do
				local module = findModule(name)
				if module and module.Enabled then
					table.insert(state.auto.Disabled, module.Name)
					table.insert(event.Auto.Affected, module.Name)
					table.insert(event.Auto.Previous, {Module = module.Name, Enabled = true})
					pcall(function() module:Toggle() end)
				end
			end
			if #state.auto.Disabled > 0 then
				table.insert(event.Auto.Action, 'disabled '..#state.auto.Disabled..' module(s)')
			end
		end
		if #event.Auto.Action > 0 then
			pcall(function()
				vape:CreateNotification('Performance Monitor', 'Performance drop - '..table.concat(event.Auto.Action, ', '), 6, 'warning')
			end)
		end
	end

	local function fireEvent(now, baseline, current, info)
		local event = {
			At = now,
			Time = os.date('%H:%M:%S'),
			Before = baseline,
			During = current,
			BaselineEntities = info.BaselineEntities or 0,
			Entities = info.Entities or 0,
			BaselinePing = info.BaselinePing,
			Ping = info.Ping,
			Spikes = info.Spikes or 0,
			Game = {MatchState = info.MatchState, Activity = info.Activity, Kit = info.Kit},
			Samples = nil,
		}
		if O.Detailed and O.Detailed.Enabled then
			event.Samples = {}
			local first = math.max(1, #state.history - 60)
			for index = first, #state.history do event.Samples[#event.Samples + 1] = state.history[index] end
		end
		event.Started = info.Started or (now - 1)
		local ok, diagnosis = pcall(diagnose, event.Started - 0.5, now)
		if ok then
			event.Diagnosis = diagnosis
			local top = diagnosis.Causes[1]
			event.Suspect, event.Confidence = top and top.Title, top and top.Confidence or 'Unknown'
		else
			event.DiagnosisError = tostring(diagnosis)
			event.Confidence = 'Unknown'
		end
		local _, _, toggles = attribute(now, event)
		event.Evidence = toggles
		state.pendingEvent = event
		event.Severity = current < baseline * 0.5 and 'severe' or 'moderate'
		table.insert(state.events, event)
		while #state.events > 12 do table.remove(state.events, 1) end
		state.lastEvent = event
		notifyEvent(event)
		if vape.Telemetry and vape.Telemetry.Perf then pcall(vape.Telemetry.Perf, event) end
		runAuto(event)
	end

	local function sample(now)
		local frameCount, frameTotal = 0, 0
		for index = #state.frames, 1, -1 do
			local frame = state.frames[index]
			if now - frame.At > 1 then break end
			frameCount += 1
			frameTotal += frame.Dt
		end
		local averageDt = frameCount > 0 and frameTotal / frameCount or 0
		local fps = averageDt > 0 and 1 / averageDt or 0
		local _, meanDt = averageFrames()
		state.lastFps = fps
		state.baseline = state.baseline and (state.baseline * 0.95 + fps * 0.05) or fps
		local baseline = baselineFps()
		local target = tonumber(O.TargetFps and O.TargetFps.Value) or 60

		local spikeThreshold = (target > 0 and 1000 / target or 16) * 2
		local spikes = 0
		for index = #state.frames, 1, -1 do
			local frame = state.frames[index]
			if now - frame.At > 1 then break end
			if frame.Dt * 1000 > spikeThreshold then spikes += 1 end
		end

		local worst, best = fps, fps
		for index = #state.samples, 1, -1 do
			local entry = state.samples[index]
			if now - entry.At > 60 then break end
			worst = math.min(worst, entry.Fps)
			best = math.max(best, entry.Fps)
		end
		state.worst, state.best = worst, best

		local moduleList = enabledModules()
		local connectionTotal = 0
		for _, entry in ipairs(moduleList) do connectionTotal += entry.Connections end

		if target > 0 then
			if fps >= target * 0.9 then
				state.status = 'GOOD'
			elseif fps >= target * 0.6 then
				state.status = 'FAIR'
			else
				state.status = 'POOR'
			end
		end

		local info = {
			Fps = fps,
			Frame = meanDt * 1000,
			Low = framePercentile(1),
			Spikes = spikes,
			Entities = entityCount(),
			Ping = currentPing(),
			MatchState = currentStore() and currentStore().matchState or nil,
			Activity = gameActivity(),
			Kit = currentKit(),
			Connections = connectionTotal,
			Modules = #moduleList,
		}
		state.lastSample = info

		local since = state.lastSampleAt or (now - 0.25)
		state.lastSampleAt = now
		local intervalFrames, intervalMs, worstMs = 0, 0, 0
		for index = #state.frames, 1, -1 do
			local frame = state.frames[index]
			if frame.At <= since then break end
			intervalFrames += 1
			intervalMs += frame.Dt * 1000
			worstMs = math.max(worstMs, frame.Dt * 1000)
		end
		local prof = profiler and profiler.Collect() or {}
		local aeMs = 0
		for _, cost in prof do aeMs += cost.Time * 1000 end
		local heapDrop = state.heapDrop or 0
		state.heapDrop = 0
		info.AeMs = intervalFrames > 0 and aeMs / intervalFrames or 0
		state.samples[#state.samples + 1] = {
			At = now,
			Fps = fps,
			Frame = info.Frame,
			Low = info.Low,
			Spikes = spikes,
			Entities = info.Entities,
			Ping = info.Ping,
			FrameCount = intervalFrames,
			IntervalMs = intervalMs,
			WorstMs = worstMs,
			AeMs = aeMs,
			Prof = prof,
			Heap = gcinfo(),
			HeapDrop = heapDrop,
			Engine = readEngine(),
			Act = takeActivity(),
			Player = playerSnapshot(),
		}
		local sampleLimit = math.max(tonumber(O.History and O.History.Value) or 240, 60)
		if #state.samples > sampleLimit then
			dropOldest(state.samples, math.max(1, math.floor(sampleLimit / 4)))
		end
		state.history[#state.history + 1] = math.floor(fps + 0.5)
		if #state.history > sampleLimit then
			dropOldest(state.history, math.max(1, math.floor(sampleLimit / 4)))
		end

		if state.awaitRecovery then
			if fps >= target * 0.95 then
				state.awaitRecovery = nil
				local event = state.pendingEvent
				state.pendingEvent = nil
				if event and event.Started then
					local ok, diagnosis = pcall(diagnose, event.Started - 0.5, now)
					if ok then
						event.Diagnosis = diagnosis
						event.Recovered = true
						local top = diagnosis.Causes[1]
						event.Suspect, event.Confidence = top and top.Title, top and top.Confidence or 'Unknown'
					end
				end
			end
			return
		end
		if now < state.cooldownUntil then return end

		local sensitivity = tonumber(O.Sensitivity and O.Sensitivity.Value) or 1
		local minDrop = (tonumber(O.MinDrop and O.MinDrop.Value) or 20) * (2 - sensitivity)
		local minPercent = (tonumber(O.MinPercent and O.MinPercent.Value) or 25) * (2 - sensitivity)
		local drop = baseline - fps
		local percent = baseline > 0 and (drop / baseline) * 100 or 0
		if fps < target and drop >= minDrop and percent >= minPercent then
			state.lowSince = state.lowSince or now
			local minimum = tonumber(O.MinDuration and O.MinDuration.Value) or 0.75
			if now - state.lowSince >= minimum then
				local baselineEntities = info.Entities
				local baselinePing = info.Ping
				for index = #state.samples, 1, -1 do
					local entry = state.samples[index]
					if now - entry.At >= 3 then
						baselineEntities = entry.Entities or baselineEntities
						baselinePing = entry.Ping or baselinePing
						break
					end
				end
				fireEvent(now, baseline, fps, {
					Started = state.lowSince,
					Entities = info.Entities,
					BaselineEntities = baselineEntities,
					Ping = info.Ping,
					BaselinePing = baselinePing,
					Spikes = spikes,
					MatchState = info.MatchState,
					Activity = info.Activity,
					Kit = info.Kit,
				})
				state.lowSince = nil
				state.awaitRecovery = baseline
				state.cooldownUntil = now + (tonumber(O.Cooldown and O.Cooldown.Value) or 10)
			end
		else
			state.lowSince = nil
		end
	end

	local function autoUpdate(now, fps)
		if not state.auto.Active then return end
		local target = tonumber(O.TargetFps and O.TargetFps.Value) or 60
		local recovery = math.min(tonumber(O.RecoveryFps and O.RecoveryFps.Value) or 90, target * 0.9, (state.auto.Before or target) * 0.9)
		if fps >= recovery then
			state.auto.RecoverSince = state.auto.RecoverSince or now
			local duration = tonumber(O.RecoveryDuration and O.RecoveryDuration.Value) or 5
			if now - state.auto.RecoverSince >= duration then
				restoreAuto()
			end
		else
			state.auto.RecoverSince = nil
		end
	end

	local function statusColor()
		if state.status == 'GOOD' then return GOOD end
		if state.status == 'FAIR' then return WARN end
		return BAD
	end

	local function renderBody()
		if not bodyLabel then return end
		local info = state.lastSample
		if not info then
			bodyLabel.Text = 'Collecting samples...'
			return
		end
		local compact = O.Compact and O.Compact.Enabled
		local lines = {}
		local function add(label, value)
			lines[#lines + 1] = string.format('%-10s %s', label, value)
		end
		local average = state.baseline or info.Fps
		if compact then
			lines[#lines + 1] = string.format('FPS %d   AVG %d', math.floor(info.Fps + 0.5), math.floor(average + 0.5))
		else
			add('FPS', string.format('%d', math.floor(info.Fps + 0.5)))
			if O.ShowAverage and O.ShowAverage.Enabled then add('AVG', string.format('%d', math.floor(average + 0.5))) end
			if O.ShowLow and O.ShowLow.Enabled then add('1% LOW', string.format('%d', math.floor(info.Low + 0.5))) end
			if O.ShowFrame and O.ShowFrame.Enabled then add('FRAME', string.format('%.1fms', info.Frame)) end
		end
		if O.ShowStatus and O.ShowStatus.Enabled then
			lines[#lines + 1] = ''
			lines[#lines + 1] = '<font color="'..toHex(statusColor())..'">STATUS    '..state.status..'</font>'
		end
		if O.ShowModules and O.ShowModules.Enabled and not compact then
			lines[#lines + 1] = ''
			if profiler then
				lines[#lines + 1] = string.format('AETHER    %sms/frame', fmt(info.AeMs or 0, 2))
				local now = os.clock()
				local ok, recent = pcall(aggregate, now - 2, now)
				if ok then
					local shown = 0
					for _, file in codeByFile(recent.Code, recent.Frames) do
						if file.PerFrame < 0.01 then break end
						local name = file.File:match('([^/]+)%.lua$') or file.File
						lines[#lines + 1] = string.format('%-14s %sms', name:sub(1, 14), fmt(file.PerFrame, 2))
						shown += 1
						if shown >= 3 then break end
					end
				end
			else
				lines[#lines + 1] = 'profiler unavailable'
			end
		end
		local text = table.concat(lines, '\n')
		if bodyLabel.Text ~= text then
			bodyLabel.Text = text
		end
	end

	local barHeights, barColours = {}, {}
	local function updateGraph()
		if not graphFrame or #graphBars == 0 then return end
		local target = tonumber(O.TargetFps and O.TargetFps.Value) or 60
		local peak = math.max(target, 30)
		local count = #graphBars
		local history = state.history
		local first = #history - count
		for index = 1, count do
			local value = first + index > 0 and history[first + index] or 0
			if value > peak then peak = value end
		end
		for index, bar in ipairs(graphBars) do
			local value = first + index > 0 and history[first + index] or 0
			local height = math.floor(math.clamp(value / peak, 0.03, 1) * 100 + 0.5) / 100
			if barHeights[index] ~= height then
				barHeights[index] = height
				bar.Size = UDim2.new(bar.Size.X.Scale, 0, height, 0)
			end
			local colour = value >= peak * 0.75 and GOOD or (value >= peak * 0.5 and WARN or BAD)
			if barColours[index] ~= colour then
				barColours[index] = colour
				bar.BackgroundColor3 = colour
			end
		end
	end

	local function applyScale()
		if ui.scale then
			ui.scale.Scale = math.clamp(tonumber(O.Scale and O.Scale.Value) or 1, 0.5, 2)
		end
	end

	local function applyVisibility()
		if graphFrame then graphFrame.Visible = O.ShowGraph and O.ShowGraph.Enabled or false end
		if hud and state.performanceMode and bodyLabel then
			bodyLabel.Text = 'PERFORMANCE MODE'
			return
		end
		renderBody()
		updateGraph()
	end

	local function buildHud()
		hud = Instance.new('Frame')
		hud.Name = 'OverlayPerformance'
		hud.BackgroundColor3 = Color3.new()
		hud.BackgroundTransparency = 0.4
		hud.BorderSizePixel = 0
		hud.AutomaticSize = Enum.AutomaticSize.Y
		hud.Size = UDim2.fromOffset(200, 0)
		hud.Parent = Overlay.Children
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = hud
		local stroke = Instance.new('UIStroke')
		stroke.Color = ACCENT
		stroke.Transparency = 0.55
		stroke.Parent = hud
		local padding = Instance.new('UIPadding')
		padding.PaddingTop = UDim.new(0, 8)
		padding.PaddingBottom = UDim.new(0, 8)
		padding.PaddingLeft = UDim.new(0, 10)
		padding.PaddingRight = UDim.new(0, 10)
		padding.Parent = hud
		local layout = Instance.new('UIListLayout')
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 4)
		layout.Parent = hud
		ui.scale = Instance.new('UIScale')
		ui.scale.Parent = hud

		titleLabel = Instance.new('TextLabel')
		titleLabel.Size = UDim2.new(1, 0, 0, 14)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = 'AETHER PERFORMANCE'
		titleLabel.TextColor3 = ACCENT
		titleLabel.TextSize = 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		local paletteFont = vape.Libraries and vape.Libraries.uipallet and vape.Libraries.uipallet.Font
		if typeof(paletteFont) == 'Font' then titleLabel.FontFace = paletteFont end
		titleLabel.LayoutOrder = 1
		titleLabel.Parent = hud

		bodyLabel = Instance.new('TextLabel')
		bodyLabel.Size = UDim2.new(1, 0, 0, 0)
		bodyLabel.AutomaticSize = Enum.AutomaticSize.Y
		bodyLabel.BackgroundTransparency = 1
		bodyLabel.Text = 'Collecting samples...'
		bodyLabel.TextColor3 = Color3.new(1, 1, 1)
		bodyLabel.TextSize = 12
		bodyLabel.RichText = true
		bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
		bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
		bodyLabel.Font = Enum.Font.Code
		bodyLabel.LayoutOrder = 2
		bodyLabel.Parent = hud

		graphFrame = Instance.new('Frame')
		graphFrame.Size = UDim2.new(1, 0, 0, 28)
		graphFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
		graphFrame.BackgroundTransparency = 0.4
		graphFrame.BorderSizePixel = 0
		graphFrame.LayoutOrder = 3
		graphFrame.Parent = hud
		local graphCorner = Instance.new('UICorner')
		graphCorner.CornerRadius = UDim.new(0, 3)
		graphCorner.Parent = graphFrame
		for index = 1, 48 do
			local bar = Instance.new('Frame')
			bar.AnchorPoint = Vector2.new(0, 1)
			bar.Position = UDim2.fromScale((index - 1) / 48, 1)
			bar.Size = UDim2.new(1 / 48 - 0.004, 0, 0.03, 0)
			bar.BackgroundColor3 = GOOD
			bar.BorderSizePixel = 0
			bar.Parent = graphFrame
			graphBars[index] = bar
			barHeights[index], barColours[index] = nil, nil
		end
	end

	local function startSampling()
		state.frames = {}
		state.samples = {}
		state.history = {}
		state.lowSince = nil
		state.awaitRecovery = nil
		state.cooldownUntil = 0
		state.events = {}
		state.transitions = {}
		state.enabled = {}
		state.auto = {Active = false, RecoverSince = nil, Disabled = {}, StartedAt = 0}
		state.performanceMode = false
		state.lastSample = nil
		state.startedAt = os.clock()
		state.lastNotifyAt = 0
		nextSampleAt = 0
		state.lastSampleAt = nil
		state.pendingEvent = nil
		state.heapDrop, state.lastHeap = 0, nil
		if profiler then
			profiler.Reset()
			profiler.Enabled = true
			if profiler.Prepare then profiler.Prepare() end
		end
		startActivity()
		rafConn = runService.RenderStepped:Connect(function(dt)
			local now = os.clock()
			if not dt or dt ~= dt or dt <= 0 then dt = 1 / 60 end
			local limit = math.max(tonumber(O.History and O.History.Value) or 240, 60)
			local heapNow = gcinfo()
			if state.lastHeap and state.lastHeap - heapNow > (state.heapDrop or 0) then
				state.heapDrop = state.lastHeap - heapNow
			end
			state.lastHeap = heapNow
			state.frames[#state.frames + 1] = {At = now, Dt = dt, Ae = profiler and profiler.TakeFrame() * 1000 or 0}
			if #state.frames > limit then
				dropOldest(state.frames, math.max(1, math.floor(limit / 4)))
			end
			if now >= nextSampleAt then
				local refresh = math.clamp(tonumber(O.RefreshRate and O.RefreshRate.Value) or 4, 1, 30)
				local interval = 1 / refresh
				if state.performanceMode then interval = math.max(interval, 0.5) end
				nextSampleAt = now + interval
				sample(now)
				autoUpdate(now, state.lastFps or 0)
				if hud then
					if state.performanceMode then
						if bodyLabel then bodyLabel.Text = 'PERFORMANCE MODE' end
					else
						renderBody()
						updateGraph()
					end
				end
			end
		end)
		scanLoop = task.spawn(function()
			while Overlay.Button and Overlay.Button.Enabled do
				scanModules(os.clock())
				task.wait(0.75)
			end
		end)
	end

	local function stopSampling()
		if profiler then profiler.Enabled = false end
		stopActivity()
		if rafConn then
			pcall(function() rafConn:Disconnect() end)
			rafConn = nil
		end
		if scanLoop then
			pcall(task.cancel, scanLoop)
			scanLoop = nil
		end
		state.performanceMode = false
	end

	local function collectErrors()
		if not (O.CollectErrors and O.CollectErrors.Enabled) then return {'error collection is disabled'} end
		local errors = {}
		for _, entry in ipairs(vape.ErrorLogs or {}) do
			errors[#errors + 1] = string.format('[%s] %s: %s', tostring(entry.Time or '?'), tostring(entry.Module or '?'), tostring(entry.Message or ''))
		end
		local runtime = shared.AetherBedWarsRuntime
		if runtime and type(runtime.Errors) == 'table' then
			for label, entry in pairs(runtime.Errors) do
				errors[#errors + 1] = string.format('[runtime] %s: %s', tostring(label), tostring(entry.Error or entry))
			end
		end
		for _, entry in ipairs(state.errors) do errors[#errors + 1] = entry end
		return errors
	end

	local function copyDebug()
		local report = {}
		local function line(text) report[#report + 1] = text end
		local version = '3.2'
		pcall(function()
			local body = readfile('ElevateV4/profiles/version.txt')
			local value = body and body:match('version%s*=%s*([^\r\n]+)')
			if value then version = value:gsub('%s+$', '') end
		end)
		local commit = 'unknown'
		pcall(function()
			local body = readfile('ElevateV4/profiles/commit.txt')
			if type(body) == 'string' and body ~= '' then commit = body:gsub('%s+', '') end
		end)
		local executor = 'Unknown'
		pcall(function() executor = identifyexecutor and select(1, identifyexecutor()) or executor end)

		line('# ElevateV4 Performance Report')
		line('Generated: '..os.date('%Y-%m-%d %H:%M:%S'))
		line('')
		line('## Environment')
		line('- ElevateV4 version: '..version)
		line('- Loader identity: '..commit)
		line('- Game: '..tostring(game.Name)..' (PlaceId '..tostring(game.PlaceId)..', GameId '..tostring(game.GameId)..')')
		line('- Game pack: '..tostring(vape.Place or 'unknown'))
		line('- Session: '..string.format('%.0f', os.clock() - state.startedAt)..'s')
		line('- Executor: '..tostring(executor))
		line('- Platform: '..(inputService.TouchEnabled and 'mobile' or 'desktop')..'   Ping: '..tostring(currentPing() or 'unknown')..'ms')
		line('- Match state: '..tostring((currentStore() and currentStore().matchState or 'unknown'))..'   Kit: '..tostring(currentKit() or 'unknown'))
		line('')
		line('## Performance')
		local info = state.lastSample
		if info then
			line(string.format('- Current FPS: %d', math.floor(info.Fps + 0.5)))
			line(string.format('- Average FPS (15s baseline): %d', math.floor((state.baseline or info.Fps) + 0.5)))
			line(string.format('- 1%% low: %d', math.floor(info.Low + 0.5)))
			line(string.format('- Minimum / maximum FPS (60s): %d / %d', math.floor((state.worst or info.Fps) + 0.5), math.floor((state.best or info.Fps) + 0.5)))
			line(string.format('- Frame time: %.2fms', info.Frame))
			line(string.format('- Entities: %d   Active modules: %d   Update connections: %d', info.Entities, info.Modules, info.Connections))
			line(string.format('- Frame-time spikes in the last second: %d', info.Spikes))
			line('- Recent FPS history: '..table.concat(state.history, ', '))
		else
			line('- No samples collected yet.')
		end
		line(string.format('- Drops detected this session: %d', #state.events))
		line('')
		line('## Performance events')
		if #state.events == 0 then
			line('- No drops detected this session.')
		else
			for _, event in ipairs(state.events) do
				local d = event.Diagnosis
				line(string.format('### %s  FPS %d -> %d (%s)', event.Time, math.floor(event.Before + 0.5), math.floor(event.During + 0.5), tostring(event.Severity)))
				if not d then
					line('- Diagnosis failed: '..tostring(event.DiagnosisError or 'unknown error'))
				else
					line(string.format('- Lasted about %ss%s; %d frames, average %sms, slowest %sms', fmt(d.Duration), event.Recovered and '' or ' (still low when this report was made)',
						d.Frames, fmt(d.FrameMs), fmt(d.Worst, 0)))
					line('- FPS before: '..table.concat(d.BeforeFps, ', '))
					line('- FPS during: '..table.concat(d.Fps, ', '))
					line('')
					line('**Most likely cause'..(#d.Causes > 1 and 's (most to least likely)' or '')..'**')
					for index, cause in ipairs(d.Causes) do
						line(string.format('%d. %s [%s] - %s', index, cause.Title, cause.Confidence, cause.Detail))
						if cause.Advice then line('   What to do: '..cause.Advice) end
					end
					line('')
					line('**What you were doing**')
					for _, entry in ipairs(d.Doing) do line('- '..entry) end
					line('')
					if d.Measured then
						line(string.format('**ElevateV4 code during the drop** (%sms per frame, %d%% of frame time)', fmt(d.AePerFrame, 2), math.floor(d.AeShare * 100)))
						local shown = 0
						for _, file in ipairs(d.Files) do
							if file.PerFrame < 0.01 then break end
							line(string.format('- %s: %sms/frame, %d run(s), longest %sms, %sKB allocated; busiest: %s (%s)', file.File, fmt(file.PerFrame, 2),
								file.Calls, fmt(file.Max * 1000, 2), fmt(file.Alloc, 0), file.Top and file.Top.Label or '?', file.Top and tostring(file.Top.Kind) or '?'))
							shown += 1
							if shown >= 8 then break end
						end
						if shown == 0 then line('- No measurable ElevateV4 code ran.') end
						if #d.Slow > 0 then
							line('- Single runs over 4ms around the drop:')
							for _, entry in ipairs(d.Slow) do line('  - '..entry) end
						end
						line('- Not timed: handlers on game events (instance added, remotes, input), which show up under the causes above when they matter.')
					else
						line('**ElevateV4 code**: the profiler is not loaded, so code cost was not measured.')
					end
					line('')
					line('**Engine**')
					for _, entry in ipairs(d.Engine) do line('- '..entry) end
				end
				if event.Evidence then
					for _, evidence in ipairs(event.Evidence) do line('- '..evidence) end
				end
				if event.Auto then
					line(string.format('- Automatic response: %s', #event.Auto.Action > 0 and table.concat(event.Auto.Action, ', ') or 'none'))
					if #event.Auto.Affected > 0 then line('- Modules affected: '..table.concat(event.Auto.Affected, ', ')) end
					if event.Auto.RestoredAt then
						line(string.format('- Restored after %.1fs: %s', event.Auto.Duration or 0, tostring(event.Auto.Restored)))
					end
				end
				line('')
			end
		end
		line('')
		line('## ElevateV4 code cost this session')
		if profiler then
			local seconds = math.max(os.clock() - state.startedAt, 1)
			local files = codeByFile(profiler.Totals(), 1)
			if #files == 0 then
				line('- Nothing measured yet.')
			else
				line('Total time each file\'s code has run since the monitor was switched on, heaviest first.')
				for index = 1, math.min(15, #files) do
					local file = files[index]
					line(string.format('- %s: %sms per second, %d run(s), longest %sms, %sKB/s allocated; busiest: %s', file.File,
						fmt(file.Time * 1000 / seconds, 2), file.Calls, fmt(file.Max * 1000, 2), fmt(file.Alloc / seconds, 1), file.Top and file.Top.Label or '?'))
				end
			end
		else
			line('- The profiler is not loaded.')
		end
		line('')
		line('## Enabled modules')
		local names = {}
		for _, entry in ipairs(enabledModules()) do
			names[#names + 1] = entry.Connections > 0 and (entry.Name..' ('..entry.Connections..')') or entry.Name
		end
		line(#names > 0 and table.concat(names, ', ') or 'No ElevateV4 modules are enabled.')
		line('(numbers are active frame connections)')
		line('')
		line('## Errors')
		local errors = collectErrors()
		if #errors == 0 then
			line('- No errors recorded.')
		else
			for _, entry in ipairs(errors) do line('- '..entry) end
		end
		line('')
		local body = table.concat(report, '\n')
		if type(setclipboard) == 'function' then
			pcall(setclipboard, body)
			pcall(function() vape:CreateNotification('Performance Monitor', 'Debug report copied to clipboard.', 4, 'info') end)
		else
			pcall(function() vape:CreateNotification('Performance Monitor', 'Clipboard is unavailable on this executor.', 4, 'warning') end)
		end
	end

	Overlay = vape:CreateOverlay({
		Name = 'Performance Monitor',
		Icon = getcustomasset('ElevateV4/assets/new/info.png'),
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromOffset(12, 13),
		Function = function(callback)
			if callback then
				buildHud()
				applyScale()
				applyVisibility()
				startSampling()
			else
				stopSampling()
				if hud then hud:Destroy() end
				hud, titleLabel, bodyLabel, graphFrame = nil, nil, nil, nil
				graphBars = {}
			end
		end,
	})

	O.RefreshRate = {Value = 4}
	O.ShowAverage = {Enabled = true}
	O.ShowLow = {Enabled = true}
	O.ShowFrame = {Enabled = true}
	O.ShowStatus = {Enabled = true}
	O.ShowModules = {Enabled = true}
	O.TargetFps = {Value = 60}
	O.MinDrop = {Value = 20}
	O.MinPercent = {Value = 25}
	O.MinDuration = {Value = 0.75}
	O.History = {Value = 240}
	O.Sensitivity = {Value = 1}
	O.Attribution = {Enabled = true}
	O.Confidence = {Value = 'Possible'}
	O.Cooldown = {Value = 10}
	O.Severity = {Value = 'warning'}
	O.NotifyCooldown = {Value = 15}
	O.ShowSuspect = {Enabled = true}
	O.TriggerFps = {Value = 60}
	O.RecoveryFps = {Value = 90}
	O.RecoveryDuration = {Value = 5}
	O.PerformanceMode = {Enabled = true}
	O.DisableModules = {Enabled = true}
	O.Restore = {Enabled = true}
	O.AllowedModules = {
		ListEnabled = {'Killaura', 'SilentAura', 'ProjectileAura', 'ESP', 'NameTags', 'Chams', 'PlayerOutline', 'HitboxESP', 'Tracers', 'Arrows'}
	}
	O.Detailed = {Enabled = false}
	O.Profiling = {Enabled = true}
	O.CollectErrors = {Enabled = true}
	O.GameState = {Enabled = true}

	O.Scale = Overlay:CreateSlider({
		Name = 'Scale',
		Min = 0.5,
		Max = 2,
		Default = 1,
		Decimal = 100,
		Function = function() applyScale() end,
	})
	O.Compact = Overlay:CreateToggle({
		Name = 'Compact',
		Default = false,
		Function = function() applyVisibility() end,
	})
	O.ShowGraph = Overlay:CreateToggle({
		Name = 'Graph',
		Default = true,
		Function = function() applyVisibility() end,
	})
	O.Notify = Overlay:CreateToggle({
		Name = 'Notify',
		Default = true,
		Tooltip = 'Tells you about frame drops and their likely cause',
	})
	O.AutoActions = Overlay:CreateToggle({
		Name = 'Automatic Actions',
		Default = false,
		Function = function(enabled)
			if not enabled then restoreAuto() end
		end,
		Tooltip = 'Turns off heavy visuals during frame drops',
	})
	Overlay:CreateButton({
		Name = 'Copy Debug Information',
		Tooltip = 'Copies a report you can paste into a bug report',
		Function = copyDebug,
	})
end)
