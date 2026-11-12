run(function()
	local BedAssist
	local TNT
	local TNTRange
	local Fireball
	local FireballRange
	local DefenceCheck
	local LimitItem
	local tntAt, shotAt, searchAt = 0, 0, 0
	local busyUntil = 0
	local TNT_ITEMS = {'TNT', 'Mega TNT'}
	local TNT_WAIT = 4
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	local bedRay = RaycastParams.new()
	bedRay.FilterType = Enum.RaycastFilterType.Include

	local function enemyBed(part)
		local beds = workspace:FindFirstChild('BedsContainer')
		local model = part
		while model and model.Parent ~= beds do
			model = model.Parent
		end
		if model and model:GetAttribute('Team') ~= lplr.Team.Name then
			return model, model:FindFirstChild('BedHitbox')
		end
	end

	local function covered(hitbox)
		local placed = workspace:FindFirstChild('PlayersBlocksContainer')
		if not placed then return false end
		overlap.FilterDescendantsInstances = {placed}
		return #workspace:GetPartBoundsInBox(hitbox.CFrame, hitbox.Size + Vector3.new(3, 3, 3), overlap) > 0
	end

	local function tntItem()
		local held = heldName()
		for _, name in TNT_ITEMS do
			if (getItem(name) or 0) > 0 and (not LimitItem.Enabled or held == name) then
				return name
			end
		end
	end

	local function tntCell(hitbox, body)
		local centre = snap(hitbox.Position)
		local cells = {}
		for x = -3, 3 do
			for y = -1, 3 do
				for z = -3, 3 do
					local cell = centre + Vector3.new(x * 3, y * 3, z * 3)
					if (cell - body).Magnitude <= TNTRange.Value then
						table.insert(cells, {cell, (cell - hitbox.Position).Magnitude})
					end
				end
			end
		end
		table.sort(cells, function(a, b)
			return a[2] < b[2]
		end)
		for i = 1, math.min(#cells, 40) do
			local ok, info = store.buildable(cells[i][1])
			if ok and not info.Collided then
				return cells[i][1]
			end
		end
	end

	local function placeTNT(body)
		if tick() - tntAt < TNT_WAIT or tick() - searchAt < 0.5 then return false end
		local name = tntItem()
		local beds = name and workspace:FindFirstChild('BedsContainer')
		if beds then
			searchAt = tick()
		end
		for _, bed in beds and beds:GetChildren() or {} do
			local hitbox = bed:FindFirstChild('BedHitbox')
			if not hitbox or bed:GetAttribute('Team') == lplr.Team.Name then continue end
			if (hitbox.Position - body).Magnitude > TNTRange.Value + 6 then continue end
			if DefenceCheck.Enabled and not covered(hitbox) then continue end
			local cell = tntCell(hitbox, body)
			if cell then
				tntAt = tick()
				equipServer(name, 'BedAssist')
				store.placeBlock(name, cell)
				return true
			end
		end
		return false
	end

	local function launch(meta, projectile, origin, velocity)
		local container = workspace:FindFirstChild('ProjectilesContainer')
		if not container then return nil end
		local shot = bedfight.ProjectilesController.new(nil, velocity, meta)
		shot:AddProjectile(meta.Projectile or projectile)
		shot.ProjectileRoot.CFrame = CFrame.lookAlong(origin, velocity.Unit)
		shot.UpdatedVelocity = velocity
		shot.Projectile.Parent = container
		return shot:Play()
	end

	local function throwFireball()
		if (getItem('Fireball') or 0) <= 0 or (LimitItem.Enabled and heldName() ~= 'Fireball') then return false end
		local data = bedfight.RangedData.Fireball
		local projectile = data and (data.Projectile or (data.ProjectileOrder and data.ProjectileOrder[1])) or 'Fireball'
		local meta = bedfight.ProjectilesData[projectile]
		if not (meta and meta.Speed) or tick() - shotAt < math.max(data.Cooldown or 0.55, 0.3) then return false end
		local beds = workspace:FindFirstChild('BedsContainer')
		if not beds then return false end
		bedRay.FilterDescendantsInstances = {beds}
		local mouse = inputService:GetMouseLocation()
		local ray = gameCamera:ViewportPointToRay(mouse.X, mouse.Y)
		local hit = workspace:Raycast(ray.Origin, ray.Direction * (FireballRange.Value + 20), bedRay)
		local bed, hitbox = hit and enemyBed(hit.Instance)
		if not (bed and hitbox) then return false end
		if DefenceCheck.Enabled and not covered(hitbox) then return false end
		local origin = bedfight.Ranged.GetFireOrigin(realRoot(), data.Offset)
		local point = hit.Position
		local distance = (point - origin).Magnitude
		if distance > FireballRange.Value or distance < 1 then return false end
		local speed = meta.Speed.Max
		local gravity = meta.Gravity and math.abs(meta.Gravity.Y) or 0
		local t = distance / speed
		local velocity = (point + Vector3.new(0, gravity * t * t / 2, 0) - origin).Unit * speed
		local ok, id = pcall(launch, meta, projectile, origin, velocity)
		if not (ok and id) then return false end
		shotAt = tick()
		equipServer('Fireball', 'BedAssist')
		fireRemote('ShootProjectile', id, 'Fireball', velocity.Unit, velocity, CFrame.lookAt(gameCamera.CFrame.Position, point))
		return true
	end

	BedAssist = vape.Categories.World:CreateModule({
		Name = 'BedAssist',
		Function = function(callback)
			if callback then
				repeat
					if canFight() and inMatch() then
						local body = realRoot().Position
						local acted = false
						if TNT.Enabled then
							acted = placeTNT(body)
						end
						if not acted and Fireball.Enabled then
							acted = throwFireball()
						end
						if acted then
							busyUntil = tick() + 0.4
						end
					end
					if busyUntil ~= 0 and tick() > busyUntil then
						busyUntil = 0
						syncTool('BedAssist')
					end
					task.wait(0.05)
				until not BedAssist.Enabled
			else
				busyUntil = 0
				syncTool('BedAssist')
			end
		end,
		Tooltip = 'Uses TNT and fireballs on enemy beds'
	})
	TNT = BedAssist:CreateGroup({
		Name = 'TNT',
		Default = true,
		Tooltip = 'Places TNT against an enemy bed in range'
	})
	TNTRange = TNT:CreateSlider({
		Name = 'TNT range',
		Min = 1,
		Max = 60,
		Default = 18,
		Suffix = 'studs',
		Darker = true,
		Tooltip = 'How far away a block can be placed'
	})
	Fireball = BedAssist:CreateGroup({
		Name = 'Fireball',
		Default = true,
		Tooltip = 'Throws a fireball when you aim at an enemy bed'
	})
	FireballRange = Fireball:CreateSlider({
		Name = 'Fireball range',
		Min = 5,
		Max = 150,
		Default = 60,
		Suffix = 'studs',
		Darker = true
	})
	DefenceCheck = BedAssist:CreateToggle({
		Name = 'Bed Defence Check',
		Default = true,
		Tooltip = 'Only goes ahead when blocks are actually covering the bed'
	})
	LimitItem = BedAssist:CreateToggle({
		Name = 'Limit to items',
		Tooltip = 'Only works while holding the item it uses'
	})
end)
