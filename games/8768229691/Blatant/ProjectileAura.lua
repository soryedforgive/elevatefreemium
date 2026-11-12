run(function()
	local ProjectileAura
	local Targets
	local Range
	local List
	local Delay
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	local FireDelays = {}

	local function getProjectiles()
		local items = {}
		for _, item in store.inventory do
			item = skywars.ItemMeta[item.Type]
			local ranged = item and item.Ranged
			if ranged and table.find(List.ListEnabled, ranged.ProjectileType) and (ranged.RequiresAmmo == false or getItem(ranged.ProjectileType)) then
				table.insert(items, item)
			end
		end
		return items
	end

	ProjectileAura = vape.Categories.Blatant:CreateModule({
		Name = 'ProjectileAura',
		Function = function(callback)
			if callback then
				repeat
					local projectiles = entitylib.isAlive and getProjectiles()
					local ent = projectiles and #projectiles > 0 and entitylib.EntityPosition({
						Origin = realRoot().Position,
						Part = 'RootPart',
						Range = Range.Value,
						Players = Targets.Players.Enabled,
						NPCs = Targets.NPCs.Enabled,
						Wallcheck = Targets.Walls.Enabled
					})

					if ent then
						local offsetpos = realRoot().CFrame * skywars.FireOrigin
						for _, item in projectiles do
							if (FireDelays[item] or 0) < tick() then
								local projectile = skywars.ItemMeta[item.Ranged.ProjectileType]
								projectile = projectile and projectile.Projectile or {}
								rayCheck.FilterDescendantsInstances = {ent.Character, gameCamera}
								rayCheck.CollisionGroup = ent.RootPart.CollisionGroup
								local calc = prediction.SolveTrajectory(offsetpos.Position, projectile.Velocity or 200, math.abs(projectile.Acceleration and projectile.Acceleration.Y or skywars.Gravity), ent.RootPart.Position, ent.RootPart.Velocity, workspace.Gravity, ent.HipHeight, nil, rayCheck)

								if calc then
									targetinfo.Targets[ent] = tick() + 1
									FireDelays[item] = tick() + math.max(item.Ranged.Cooldown or 0, Delay.Value)
									equip(item)
									fireRemote('chargeBow', CFrame.new(offsetpos.Position, calc).LookVector, 1)
									equip(nil)
									break
								end
							end
						end
					end

					task.wait(0.03)
				until not ProjectileAura.Enabled
			end
		end,
		Tooltip = 'Shoots enemies around you'
	})
	Targets = ProjectileAura:CreateTargets({
		Players = true,
		Walls = true
	})
	List = ProjectileAura:CreateTextList({
		Name = 'Projectiles',
		Default = {'Arrow', 'Snowball', 'Capybara'}
	})
	Delay = ProjectileAura:CreateSlider({
		Name = 'Fire delay',
		Min = 0.05,
		Max = 1,
		Default = 0.25,
		Decimal = 100,
		Suffix = 's',
		Tooltip = 'Time between shots'
	})
	Range = ProjectileAura:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 50,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)
