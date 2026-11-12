run(function()
	local AntiBedBreak
	local Targets
	local Mode
	local Range
	local WoolOnly
	local lastHit = 0
	local pending = {}
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	local ORDER = {'Wool$', '^Wood Plank$', '^Stone Brick$', '^Blastproof Ceramic$', '^Obsidian$'}

	local function blockName(count)
		for i, pattern in ORDER do
			if WoolOnly.Enabled and i > 1 then break end
			for item, amount in store.inventory do
				if amount >= count and item:find(pattern) and bedfight.Blocks:FindFirstChild(item) then
					return item
				end
			end
		end
	end

	local function lodged(root, placed)
		overlap.FilterDescendantsInstances = {placed}
		return workspace:GetPartBoundsInBox(root.CFrame * CFrame.new(0, -0.4, 0), Vector3.new(1.6, 4.6, 1.6), overlap)
	end

	local function enemies(body)
		return store.targets({
			Origin = body,
			Range = Range.Value + 4,
			Players = Targets.Players.Enabled,
			NPCs = Targets.NPCs.Enabled,
			Limit = 6
		})
	end

	local function mine(body, placed)
		local from = body + Vector3.new(0, 1.5, 0)
		local best, bestDistance
		for _, ent in enemies(body) do
			for _, part in lodged(ent.RootPart, placed) do
				local object = part.Parent:IsA('Model') and part.Parent or part
				local kind = object.Parent and object.Parent.Name
				local distance = (part.Position - body).Magnitude
				if kind and distance <= Range.Value and (not bestDistance or distance < bestDistance) and getTool(kind) then
					best, bestDistance = {Object = object, Part = part, Kind = kind}, distance
				end
			end
		end
		if not best then return false end
		local tool = getTool(best.Kind)
		if tick() - lastHit < (bedfight.MiningData[tool].Cooldown or 0.3) then return true end
		lastHit = tick()
		equipServer(tool, 'AntiBedBreak')
		fireRemote('MineBlock', tool, best.Object, snap(best.Part.Position), from, (best.Part.Position - from).Unit)
		return true
	end

	local function suffocate(body, placed)
		local now = tick()
		for _, ent in enemies(body) do
			if #lodged(ent.RootPart, placed) == 0 then continue end
			local legs = snap(ent.RootPart.Position - Vector3.new(0, 1.5, 0))
			local cells = {}
			for _, cell in {legs, legs + Vector3.new(0, 3, 0)} do
				if (pending[cell] or 0) < now and (cell - body).Magnitude <= Range.Value then
					local _, info = store.buildable(cell)
					if info and not info.Collided and not info.InsideAntiBuild then
						table.insert(cells, cell)
					end
				end
			end
			local name = #cells > 0 and blockName(#cells)
			if name then
				equipServer(name, 'AntiBedBreak')
				for _, cell in cells do
					store.placeBlock(name, cell)
					pending[cell] = now + math.clamp(lplr:GetNetworkPing() * 2 + 0.3, 0.4, 1.2)
				end
				return true
			end
		end
		return false
	end

	AntiBedBreak = vape.Categories.World:CreateModule({
		Name = 'AntiBedBreak',
		Function = function(callback)
			if callback then
				local busy = false
				repeat
					local acted = false
					local placed = workspace:FindFirstChild('PlayersBlocksContainer')
					if placed and canFight() and inMatch() then
						local body = realRoot().Position
						if Mode.Value == 'Mine' then
							acted = mine(body, placed)
						else
							acted = suffocate(body, placed)
						end
					end
					for cell, untilAt in pending do
						if untilAt < tick() then
							pending[cell] = nil
						end
					end
					if busy and not acted then
						syncTool('AntiBedBreak')
					end
					busy = acted
					task.wait(0.05)
				until not AntiBedBreak.Enabled
			else
				table.clear(pending)
				syncTool('AntiBedBreak')
			end
		end,
		ExtraText = function()
			return Mode.Value
		end,
		Tooltip = 'Stops enemies hiding from your hits inside blocks'
	})
	Targets = AntiBedBreak:CreateTargets({Players = true})
	Mode = AntiBedBreak:CreateDropdown({
		Name = 'Mode',
		List = {'Mine', 'Suffocate'},
		Function = function(val)
			if WoolOnly then
				WoolOnly.Object.Visible = val == 'Suffocate'
			end
		end,
		Tooltip = 'Mine - mines the blocks they stand in\nSuffocate - fills the space they stand in'
	})
	Range = AntiBedBreak:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 18,
		Default = 18,
		Suffix = 'studs',
		Tooltip = 'How far away a block can be mined'
	})
	WoolOnly = AntiBedBreak:CreateToggle({
		Name = 'Wool only',
		Default = true,
		Darker = true,
		Visible = false,
		Tooltip = 'Only uses wool'
	})
end)
