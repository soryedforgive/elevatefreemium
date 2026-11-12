run(function()
	local AutoVoidDrop
	local PearlCheck
	local BalloonCheck
	local resources

	local orbRay = RaycastParams.new()
	orbRay.RespectCanCollide = true
	orbRay.FilterType = Enum.RaycastFilterType.Exclude

	local function voidItems()
		if not resources then
			resources = {}
			for name, data in bedfight.ItemsData do
				if type(data) == 'table' and data.Class == 'Resources' and data.CanDrop ~= false then
					table.insert(resources, name)
				end
			end
		end
		return resources
	end

	local function orbLands(shot, floor)
		local root = shot.ProjectileRoot
		local velocity = shot.UpdatedVelocity
		local gravity = shot.ProjectileData and shot.ProjectileData.Gravity
		if not (root and root.Parent and typeof(velocity) == 'Vector3' and typeof(gravity) == 'Vector3') then return false end
		local position = root.Position
		orbRay.FilterDescendantsInstances = {lplr.Character, gameCamera, workspace:FindFirstChild('PlayersContainer'), workspace:FindFirstChild('ProjectilesContainer')}
		local step = 0.05
		for _ = 1, 120 do
			local nextPosition = position + velocity * step
			local result = workspace:Raycast(position, nextPosition - position, orbRay)
			if result then
				return result.Position.Y > floor
			end
			if nextPosition.Y < floor then return false end
			position = nextPosition
			velocity += gravity * step
		end
		return false
	end

	local function orbWillSave(floor)
		local mine = '^'..lplr.UserId..'_'
		for key, shot in bedfight.ProjectilesController.PlayingProjectiles do
			if type(key) == 'string' and key:find(mine) and shot.ProjectileName == 'Teleorb' and orbLands(shot, floor) then
				return true
			end
		end
		return false
	end

	local function floating()
		local amount = lplr:FindFirstChild('BalloonsAmount')
		return (amount and amount.Value or 0) > 0 or (store.inventory.Balloon or 0) > 0 or (store.inventory['Skull Balloon'] or 0) > 0
	end

	AutoVoidDrop = vape.Categories.Utility:CreateModule({
		Name = 'AutoVoidDrop',
		Function = function(callback)
			if callback then
				local dropped = 0
				repeat
					local floor = inMatch() and store.voidFloor() or nil
					if floor and entitylib.isAlive and tick() - dropped > 1 then
						local root = bodyRoot()
						if store.inVoid(root, 0.2) and not workspace:Raycast(root.Position, Vector3.new(0, -500, 0), blockParams()) then
							local saved = (BalloonCheck.Enabled and floating()) or (PearlCheck.Enabled and orbWillSave(floor))
							if not saved then
								for _, name in voidItems() do
									if (store.inventory[name] or 0) > 0 then
										fireRemote('DropItem', name, 'All')
										dropped = tick()
									end
								end
							end
						end
					end
					task.wait(0.1)
				until not AutoVoidDrop.Enabled
			end
		end,
		Tooltip = 'Drops your resources when falling into the void'
	})
	PearlCheck = AutoVoidDrop:CreateToggle({
		Name = 'Pearl check',
		Default = true,
		Tooltip = 'Keeps your items while your thrown orb can save you'
	})
	BalloonCheck = AutoVoidDrop:CreateToggle({
		Name = 'Balloon check',
		Default = true,
		Tooltip = 'Keeps your items while you have a balloon'
	})
end)
