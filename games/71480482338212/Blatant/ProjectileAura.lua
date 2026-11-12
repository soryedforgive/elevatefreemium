run(function()
	local ProjectileAura
	local Targets
	local Range
	local List
	local Delay
	local Sort
	local Part
	local FOV
	local ring
	local nextShot = {}

	local function getWeapon()
		for name in store.inventory do
			local data = bedfight.RangedData[name]
			if type(data) == 'table' and table.find(List.ListEnabled, name) and (nextShot[name] or 0) < tick() then
				for _, projectile in data.ProjectileOrder or {data.Projectile} do
					local meta = bedfight.ProjectilesData[projectile]
					if meta and (store.inventory[meta.Projectile or projectile] or 0) > 0 then
						return name, data, projectile, meta
					end
				end
			end
		end
	end

	local function launch(projectile, meta, origin, velocity)
		local container = workspace:FindFirstChild('ProjectilesContainer')
		if not container then return nil end
		local shot = bedfight.ProjectilesController.new(nil, velocity, meta)
		shot:AddProjectile(meta.Projectile or projectile)
		shot.ProjectileRoot.CFrame = CFrame.lookAlong(origin, velocity.Unit)
		shot.UpdatedVelocity = velocity
		shot.Projectile.Parent = container
		return shot:Play()
	end

	ProjectileAura = vape.Categories.Blatant:CreateModule({
		Name = 'ProjectileAura',
		Function = function(callback)
			ring.Update(callback)
			if callback then
				local switched = false
				repeat
					local fired = false
					if canFight() and tick() - (store.melee or 0) > 0.5 then
						local weapon, data, projectile, meta = getWeapon()
						local ent = weapon and store.targets({
							Range = Range.Value,
							FOV = ring.Show.Enabled and FOV.Value or nil,
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Walls = Targets.Walls.Enabled,
							Sort = Sort.Value
						})[1]

						if ent then
							local root = realRoot()
							local origin = bedfight.Ranged.GetFireOrigin(root, data.Offset)
							local speed = meta.Speed.Max
							local point = store.aimPoint(origin, speed, math.abs(meta.Gravity.Y), ent, ent[Part.Value] or ent.RootPart)

							if point and (point - origin).Magnitude > 1 then
								fired = true
								switched = true
								targetinfo.Targets[ent] = tick() + 1
								if equipServer(weapon, 'ProjectileAura') or (store.sentAt and tick() - store.sentAt > 0.6) then
									local velocity = (point - origin).Unit * speed
									local ok, id = pcall(launch, projectile, meta, origin, velocity)
									if ok and id then
										nextShot[weapon] = tick() + math.max(data.Cooldown or 0, Delay.Value)
										fireRemote('ShootProjectile', id, weapon, velocity.Unit, velocity, CFrame.lookAt(gameCamera.CFrame.Position, point))
									end
								end
							end
						end
					end

					if switched and not fired then
						switched = false
						syncTool('ProjectileAura')
					end
					task.wait(0.05)
				until not ProjectileAura.Enabled
			else
				syncTool('ProjectileAura')
			end
		end,
		Tooltip = 'Shoots enemies around you'
	})
	Targets = ProjectileAura:CreateTargets({
		Players = true,
		Walls = true
	})
	Sort = ProjectileAura:CreateDropdown({
		Name = 'Target mode',
		List = store.sortList,
		Tooltip = 'Who to prefer when several targets are in range'
	})
	Part = ProjectileAura:CreateDropdown({
		Name = 'Part',
		List = {'RootPart', 'Head'},
		Tooltip = 'Where on the body shots aim'
	})
	List = ProjectileAura:CreateMultiDropdown({
		Name = 'Weapons',
		List = {'Bow', 'Crossbow', 'Fireball', 'Teleorb', 'Hotdog'},
		Default = {'Bow', 'Crossbow'},
		Tooltip = 'Which ranged weapons it fires'
	})
	Delay = ProjectileAura:CreateSlider({
		Name = 'Fire delay',
		Min = 0.2,
		Max = 3,
		Default = 0.8,
		Decimal = 10,
		Suffix = 's',
		Tooltip = 'Time between shots'
	})
	Range = ProjectileAura:CreateSlider({
		Name = 'Range',
		Min = 10,
		Max = 150,
		Default = 80,
		Suffix = 'studs'
	})
	ring = store.ring(ProjectileAura, 'BFPAuraFOVCircle', 'Shows the range around your cursor')
	ring.Radius = function()
		return FOV.Value
	end
	FOV = ProjectileAura:CreateSlider({
		Name = 'FOV',
		Min = 1,
		Max = 1000,
		Default = 300,
		Darker = true,
		Visible = function()
			return ring.Show.Enabled
		end,
		Tooltip = 'How far from your cursor a target can be'
	})
end)
