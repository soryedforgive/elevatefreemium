run(function()
	local AutoClutch
	local MaxBlocks
	local FallSpeed
	local nextTry = 0
	local SERVER = 20
	local FACES = {Vector3.new(3, 0, 0), Vector3.new(-3, 0, 0), Vector3.new(0, 0, 3), Vector3.new(0, 0, -3), Vector3.new(0, 3, 0), Vector3.new(0, -3, 0)}
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include

	local function release()
		if store.autoClutch then
			store.autoClutch = nil
			mergeRoot('AutoClutch')
		end
	end

	local function route(goal, limit, origin)
		if store.anchored(goal) then return {goal} end
		local from, depth = {[goal] = false}, {[goal] = 0}
		local queue, head = {goal}, 1
		while head <= #queue and head < 1500 do
			local cell = queue[head]
			head += 1
			if depth[cell] < limit then
				for _, face in FACES do
					local n = cell + face
					if from[n] == nil and not store.filled(n) and (n - origin).Magnitude <= SERVER then
						from[n] = cell
						depth[n] = depth[cell] + 1
						if store.anchored(n) then
							local path = {}
							local walk = n
							while walk do
								table.insert(path, walk)
								walk = from[walk]
							end
							return path
						end
						table.insert(queue, n)
					end
				end
			end
		end
		return nil
	end

	local function voidBelow(position)
		local map = workspace:FindFirstChild('BlockContainer')
		if not map then return false end
		rayParams.FilterDescendantsInstances = {map}
		return workspace:Raycast(position, Vector3.new(0, -200, 0), rayParams) == nil
	end

	local function step()
		if not entitylib.isAlive then
			release()
			return
		end
		local root = bodyRoot()
		local velocity = root.AssemblyLinearVelocity
		if velocity.Y > -FallSpeed.Value or tick() < nextTry or outranked('autoClutch') or not voidBelow(root.Position) then
			if store.autoClutch and tick() > nextTry + 0.5 then
				release()
			end
			return
		end

		local lead = math.clamp(lplr:GetNetworkPing() + 0.05, 0.1, 0.4)
		local ahead = root.Position + velocity * Vector3.new(1, 0, 1) * lead
		local fall = math.min(-velocity.Y * lead + 0.5 * workspace.Gravity * lead * lead, 30)
		local goal = store.cell(ahead - Vector3.new(0, entitylib.character.HipHeight + 1.5 + fall, 0))

		local origin = realRoot().Position
		if store.split and (origin - root.Position).Magnitude > 4 then
			if outranked('autoClutch') then return end
			store.autoClutch = true
			sendRoot(root.Position)
			origin = root.Position
		end
		local path = route(goal, MaxBlocks.Value, origin)
		if not path then
			nextTry = tick() + 0.1
			return
		end
		local item = store.blockItem(#path)
		if not item then
			nextTry = tick() + 1
			return
		end
		store.placeCells(path, item)
		nextTry = tick() + 0.2
	end

	AutoClutch = vape.Categories.Blatant:CreateModule({
		Name = 'AutoClutch',
		Function = function(callback)
			if callback then
				AutoClutch:Clean(runService.Heartbeat:Connect(step))
			else
				release()
			end
		end,
		Tooltip = 'Places blocks under you when falling toward the void'
	})
	MaxBlocks = AutoClutch:CreateSlider({
		Name = 'Max blocks',
		Min = 1,
		Max = 8,
		Default = 6,
		Tooltip = 'Longest bridge it builds to reach you'
	})
	FallSpeed = AutoClutch:CreateSlider({
		Name = 'Fall speed',
		Min = 5,
		Max = 80,
		Default = 25,
		Suffix = 'studs/s',
		Tooltip = 'How fast you must be falling before it acts'
	})
end)
