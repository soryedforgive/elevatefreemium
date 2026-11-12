run(function()
	local AntiSuffocate
	local Mode
	local Notify
	local hintAt = 0
	local lastHit, lastMove = 0, 0
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include

	local function containers()
		local list = {}
		local placed = workspace:FindFirstChild('PlayersBlocksContainer')
		if placed then
			table.insert(list, placed)
		end
		local map = mapBlocks()
		if map then
			table.insert(list, map)
		end
		return list
	end

	local function inside(root, wide)
		overlap.FilterDescendantsInstances = containers()
		local size = wide and Vector3.new(1.6, 4.6, 1.6) or Vector3.new(1.2, 4.2, 1.2)
		local found = {}
		for _, part in workspace:GetPartBoundsInBox(root.CFrame * CFrame.new(0, -0.3, 0), size, overlap) do
			if part.CanCollide and part.Transparency < 1 then
				table.insert(found, part)
			end
		end
		return found
	end

	local function cellFull(cell)
		local _, info = store.buildable(cell)
		return info and info.Collided and true or false
	end

	local function climb(root)
		local cell = snap(root.Position - Vector3.new(0, 1.5, 0))
		for _ = 1, 20 do
			if not cellFull(cell) and not cellFull(cell + Vector3.new(0, 3, 0)) then
				return cell
			end
			cell += Vector3.new(0, 3, 0)
		end
		return nil
	end

	local function teleport(root)
		if tick() - lastMove < 0.5 then return end
		local cell = climb(root)
		if not cell then return end
		lastMove = tick()
		local goal = CFrame.new(root.Position.X, cell.Y + 1.5, root.Position.Z) * root.CFrame.Rotation
		local body = bodyRoot()
		body.CFrame = goal
		body.AssemblyLinearVelocity = Vector3.zero
		if store.split then
			sendRoot(goal)
		end
		if Notify.Enabled then
			notif('AntiSuffocate', string.format('Moved you %d studs up out of the blocks.', goal.Y - root.Position.Y), 2)
		end
	end

	local function mine(parts)
		local placed = workspace:FindFirstChild('PlayersBlocksContainer')
		local from = gameCamera.CFrame.Position
		for _, part in parts do
			if not (placed and part:IsDescendantOf(placed)) then continue end
			local object = part.Parent:IsA('Model') and part.Parent or part
			local kind = object.Parent and object.Parent.Name
			local tool = kind and getTool(kind)
			if not tool then continue end
			local cooldown = bedfight.MiningData[tool].Cooldown or 0.3
			if tick() - lastHit < cooldown then return end
			lastHit = tick()
			equipServer(tool, 'AntiSuffocate')
			fireRemote('MineBlock', tool, object, snap(part.Position), from, (part.Position - from).Unit)
			return true
		end
	end

	AntiSuffocate = vape.Categories.Utility:CreateModule({
		Name = 'AntiSuffocate',
		Function = function(callback)
			if callback then
				AntiSuffocate:Clean(remotes.DamageIndicator.OnClientEvent:Connect(function(victim, amount)
					if victim == lplr.Character and type(amount) == 'number' and math.abs(amount - 5) < 0.5 then
						hintAt = tick()
					end
				end))
				local mining = false
				repeat
					local busy = false
					if entitylib.isAlive and not store.flyOn then
						local root = realRoot()
						local parts = inside(root, tick() - hintAt < 1)
						if #parts > 0 then
							if Mode.Value == 'Blatant' then
								teleport(root)
							else
								busy = mine(parts) or mining
							end
						end
					end
					if mining and not busy then
						syncTool('AntiSuffocate')
					end
					mining = busy
					task.wait(0.1)
				until not AntiSuffocate.Enabled
			else
				syncTool('AntiSuffocate')
			end
		end,
		ExtraText = function()
			return Mode.Value
		end,
		Tooltip = 'Gets you out when you are stuck inside blocks'
	})
	Mode = AntiSuffocate:CreateDropdown({
		Name = 'Mode',
		List = {'Blatant', 'Legit'},
		Tooltip = 'Blatant - moves you on top of the blocks\nLegit - mines the blocks you are stuck in'
	})
	Notify = AntiSuffocate:CreateToggle({
		Name = 'Notify',
		Tooltip = 'Tells you when it moves you'
	})
end)
