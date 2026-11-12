run(function()
	local PearlTP
	local Limit
	local ITEM = 'Teleorb'
	local lastThrow = 0

	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	rayCheck.RespectCanCollide = true

	local function getMouseTarget(mousePosition)
		rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera, workspace:FindFirstChild('PlayersContainer'), workspace:FindFirstChild('ProjectilesContainer')}
		local ray = gameCamera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
		local result = workspace:Raycast(ray.Origin, ray.Direction * 2048, rayCheck)
		return result and result.Position
	end

	local function solve(origin, target, speed, gravity)
		local delta = target - origin
		local flat = Vector3.new(delta.X, 0, delta.Z)
		local distance = flat.Magnitude
		if distance < 0.5 then
			return Vector3.new(0, delta.Y >= 0 and speed or -speed, 0)
		end
		if gravity <= 0 then
			return delta.Unit * speed
		end
		local root = speed ^ 4 - gravity * (gravity * distance * distance + 2 * delta.Y * speed * speed)
		if root < 0 then return nil end
		local angle = math.atan((speed * speed - math.sqrt(root)) / (gravity * distance))
		return flat.Unit * (math.cos(angle) * speed) + Vector3.new(0, math.sin(angle) * speed, 0)
	end

	local function getPathObstacle(origin, velocity, gravity, target)
		local flight = ((target - origin) * Vector3.new(1, 0, 1)).Magnitude / math.max((velocity * Vector3.new(1, 0, 1)).Magnitude, 1)
		local steps = math.clamp(math.ceil(flight / 0.05), 1, 120)
		local previous = origin
		for i = 1, steps do
			local t = flight * i / steps
			local point = origin + velocity * t + Vector3.new(0, -gravity * t * t / 2, 0)
			if (point - target).Magnitude <= 1.5 then break end
			local segment = point - previous
			if segment.Magnitude > 0 then
				local hit = workspace:Raycast(previous, segment, rayCheck)
				if hit and (hit.Position - target).Magnitude > 1.5 then
					return hit
				end
			end
			previous = point
		end
		return nil
	end

	local function throwPearl(target, owner)
		local quiet = owner ~= nil and owner ~= 'PearlTP'
		owner = owner or 'PearlTP'
		local function say(text, time)
			if not quiet then notif('PearlTP', text, time, 'warning') end
		end
		if not entitylib.isAlive then say('Character missing.', 3) return false end
		if (store.inventory[ITEM] or 0) <= 0 then say('No teleorb available.', 3) return false end
		if not quiet and Limit.Enabled and heldName() ~= ITEM then
			notif('PearlTP', 'Hold a teleorb first.', 3, 'warning')
			return false
		end
		local data = bedfight.RangedData[ITEM]
		local meta = data and bedfight.ProjectilesData[data.Projectile or ITEM]
		if not (meta and meta.Speed) then
			say('Teleorb projectile data unavailable.', 3)
			return false
		end
		local ok, abilities = pcall(function()
			return require(replicatedStorage.Modules.AbilitiesManager)
		end)
		if ok and type(abilities) == 'table' and abilities.Enabled == false then
			say('Abilities are switched off right now.', 3)
			return false
		end
		if tick() - lastThrow < (data.Cooldown or 0.2) then return false end

		local speed, gravity = meta.Speed.Max, math.abs(meta.Gravity.Y)
		local root = realRoot()
		local camera = CFrame.lookAt(gameCamera.CFrame.Position, target)
		local origin, velocity
		for _ = 1, 2 do
			origin = root.Position + camera:VectorToWorldSpace(data.Offset)
			velocity = solve(origin, target, speed, gravity)
			if not velocity then
				say('Target is too far away for the teleorb.', 4)
				return false
			end
			camera = CFrame.lookAlong(gameCamera.CFrame.Position, velocity.Unit)
		end

		local obstacle = getPathObstacle(origin, velocity, gravity, target)
		if obstacle and obstacle.Instance then
			say('Obstacle in the way of the teleorb ('..obstacle.Instance.Name..')', 4)
			return false
		end

		local container = workspace:FindFirstChild('ProjectilesContainer')
		if not container then return false end
		local made, id = pcall(function()
			local shot = bedfight.ProjectilesController.new(nil, velocity, meta)
			shot:AddProjectile(meta.Projectile or data.Projectile or ITEM)
			shot.ProjectileRoot.CFrame = CFrame.lookAlong(origin, velocity.Unit)
			shot.UpdatedVelocity = velocity
			shot.Projectile.Parent = container
			return shot:Play()
		end)
		if not (made and id) then return false end

		lastThrow = tick()
		equipServer(ITEM, owner)
		fireRemote('ShootProjectile', id, ITEM, velocity.Unit, velocity, camera)
		task.delay(0.4, syncTool, owner)
		return true
	end
	store.throwTeleorb = throwPearl
	store.teleorbSpeed = function()
		local data = bedfight.RangedData[ITEM]
		local meta = data and bedfight.ProjectilesData[data.Projectile or ITEM]
		return meta and meta.Speed and meta.Speed.Max, meta and meta.Gravity and math.abs(meta.Gravity.Y), data and data.Cooldown
	end

	PearlTP = vape.Categories.Utility:CreateModule({
		Name = 'PearlTP',
		Function = function(callback)
			if not callback then return end
			local target = entitylib.isAlive and getMouseTarget(inputService:GetMouseLocation())
			if not target then
				notif('PearlTP', 'No valid position under the mouse.', 3, 'warning')
				PearlTP:Toggle()
				return
			end
			throwPearl(target)
			PearlTP:Toggle()
		end,
		Tooltip = 'Throws a teleorb to the spot under your cursor'
	})

	Limit = PearlTP:CreateToggle({Name = 'Limit to item', Tooltip = 'Only works while holding the item it uses'})
end)
