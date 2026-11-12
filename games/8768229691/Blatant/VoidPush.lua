run(function()
	local VoidPush
	local Range
	local Edge
	local Height
	local target
	local edges = setmetatable({}, {__mode = 'k'})
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	local DIRECTIONS = {}
	for i = 0, 7 do
		local angle = i * math.pi / 4
		table.insert(DIRECTIONS, Vector3.new(math.cos(angle), 0, math.sin(angle)))
	end

	local function release()
		target = nil
		store.voidPush = nil
		mergeRoot('VoidPush')
	end

	local function voidDirection(ent)
		local cached = edges[ent]
		if cached and cached.At > tick() then return cached.Direction end
		local map = workspace:FindFirstChild('BlockContainer')
		local best, bestDist
		if map then
			rayParams.FilterDescendantsInstances = {map}
			local origin = ent.RootPart.Position
			for _, direction in DIRECTIONS do
				for dist = 3, Edge.Value, 3 do
					local point = origin + direction * dist
					if not workspace:Raycast(point, Vector3.new(0, -150, 0), rayParams) then
						if not bestDist or dist < bestDist then
							best, bestDist = direction, dist
						end
						break
					end
				end
			end
		end
		edges[ent] = {Direction = best, At = tick() + 0.2}
		return best
	end

	local function candidates(origin)
		local list = {}
		for _, ent in entitylib.List do
			if ent.Targetable and ent.Player and ent.RootPart and ent.RootPart.Parent and ent.Health > 0 and not fallen(ent) and (ent.RootPart.Position - origin).Magnitude <= Range.Value then
				local direction = voidDirection(ent)
				if direction then
					table.insert(list, {Entity = ent, Direction = direction})
				end
			end
		end
		return list
	end

	VoidPush = vape.Categories.Blatant:CreateModule({
		Name = 'VoidPush',
		Function = function(callback)
			if callback then
				VoidPush:Clean(runService.Heartbeat:Connect(function()
					local sword = store.tools.sword
					if not entitylib.isAlive or not sword or outranked('voidPush') then
						release()
						return
					end
					local list = candidates(bodyRoot().Position)
					if #list == 0 then
						if target then release() end
						return
					end
					local pick
					for _, v in list do
						if target and v.Entity == target then
							pick = v
							break
						end
					end
					if not pick then
						for _, v in list do
							if not pick or v.Entity.Health < pick.Entity.Health then
								pick = v
							end
						end
					end
					if not splitRoot('VoidPush') then return end
					store.voidPush = true
					target = pick.Entity
					store.noShoot = tick() + 1

					local side = math.sqrt(math.max(16.5 ^ 2 - Height.Value ^ 2, 1))
					local base = attachPosition(target, 0)
					sendRoot(base - pick.Direction * math.min(side, 8) + Vector3.new(0, Height.Value, 0))
					targetinfo.Targets[target] = tick() + 1
					if strikeReady(target) then
						equip(sword)
						fireRemote('strike', target.Player)
						equip(nil)
					end
				end))
			else
				release()
			end
		end,
		Tooltip = 'Knocks enemies near an edge into the void'
	})
	Range = VoidPush:CreateSlider({
		Name = 'Range',
		Min = 18,
		Max = 1000,
		Default = 150,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Edge = VoidPush:CreateSlider({
		Name = 'Edge distance',
		Min = 3,
		Max = 30,
		Default = 12,
		Suffix = 'studs',
		Tooltip = 'Only enemies this close to a drop into the void are pushed'
	})
	Height = VoidPush:CreateSlider({
		Name = 'Height',
		Min = 0,
		Max = 15,
		Default = 12,
		Suffix = 'studs',
		Tooltip = 'How far above enemies your hitbox stays'
	})
end)
