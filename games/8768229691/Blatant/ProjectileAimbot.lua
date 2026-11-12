run(function()
	local ProjectileAimbot
	local TargetPart
	local FOV
	local old, oldMobile
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude

	local function aimFunction(original, ...)
		if store.hand and store.hand.Ranged and entitylib.isAlive then
			local plr = entitylib.EntityMouse({
				Range = FOV.Value,
				Part = 'RootPart',
				Players = true
			})

			if plr then
				local projectile = skywars.ItemMeta[store.hand.Ranged.ProjectileType]
				projectile = projectile and projectile.Projectile or {}
				rayCheck.FilterDescendantsInstances = {plr.Character, gameCamera}
				rayCheck.CollisionGroup = plr[TargetPart.Value].CollisionGroup
				local offsetpos = realRoot().CFrame * skywars.FireOrigin
				local calc = prediction.SolveTrajectory(offsetpos.Position, projectile.Velocity or 200, math.abs(projectile.Acceleration and projectile.Acceleration.Y or skywars.Gravity), plr[TargetPart.Value].Position, plr[TargetPart.Value].Velocity, workspace.Gravity, plr.HipHeight, nil, rayCheck)

				if calc then
					targetinfo.Targets[plr] = tick() + 1
					return CFrame.new(offsetpos.Position, calc).LookVector
				end
			end
		end

		return original(...)
	end

	ProjectileAimbot = vape.Categories.Blatant:CreateModule({
		Name = 'ProjectileAimbot',
		Function = function(callback)
			if callback then
				if not hookfunction then
					notif('ProjectileAimbot', 'Your executor has no hookfunction.', 8, 'warning')
					return
				end
				old = hookfunction(skywars.CameraUtil.getCursorDirection, function(...)
					return aimFunction(old, ...)
				end)

				oldMobile = hookfunction(skywars.CameraUtil.getDirection, function(...)
					return aimFunction(oldMobile, ...)
				end)
			elseif old then
				hookfunction(skywars.CameraUtil.getCursorDirection, old)
				hookfunction(skywars.CameraUtil.getDirection, oldMobile)
				old = nil
				oldMobile = nil
			end
		end,
		Tooltip = 'Silently aims your shots at enemies'
	})
	TargetPart = ProjectileAimbot:CreateDropdown({
		Name = 'Part',
		List = {'RootPart', 'Head'}
	})
	FOV = ProjectileAimbot:CreateSlider({
		Name = 'FOV',
		Min = 1,
		Max = 1000,
		Default = 1000
	})
end)
