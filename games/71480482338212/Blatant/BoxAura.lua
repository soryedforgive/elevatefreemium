run(function()
	local BoxAura
	local Targets
	local Sort
	local Range
	local Prediction
	local Size
	local Grounded
	local WoolOnly
	local Suffocate
	local Notify
	local boxed = setmetatable({}, {__mode = 'k'})
	local follow = setmetatable({}, {__mode = 'k'})
	local pending = {}
	local warnedAt = 0
	local SIDES = {Vector3.new(3, 0, 0), Vector3.new(-3, 0, 0), Vector3.new(0, 0, 3), Vector3.new(0, 0, -3)}
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

	local function landTime()
		return math.clamp(lplr:GetNetworkPing() * 1.5 + 0.1, 0.15, 0.7)
	end

	local function predicted(ent)
		local position = ent.RootPart.Position
		local velocity = store.motion(ent) * Vector3.new(1, 0, 1)
		if velocity.Magnitude > 40 then
			velocity = velocity.Unit * 40
		end
		if Prediction.Enabled then
			position += velocity * landTime()
		end
		return position, velocity.Magnitude
	end

	local function filled(cell)
		if (pending[cell] or 0) > tick() then return true end
		local _, info = store.buildable(cell)
		return info and info.Collided and true or false
	end

	local function insideCells(position, wide)
		local legsY = math.round((position.Y - 1.5) / 3) * 3
		local xs, zs
		if wide then
			local x, z = math.floor(position.X / 3) * 3, math.floor(position.Z / 3) * 3
			xs, zs = {x, x + 3}, {z, z + 3}
		else
			xs, zs = {math.round(position.X / 3) * 3}, {math.round(position.Z / 3) * 3}
		end
		local cells = {}
		for _, x in xs do
			for _, z in zs do
				table.insert(cells, Vector3.new(x, legsY, z))
			end
		end
		return cells
	end

	local function boxCells(inside)
		local set = {}
		for _, cell in inside do
			set[cell] = true
		end
		local cells, seen = {}, {}
		local function add(cell)
			if not seen[cell] and not set[cell] then
				seen[cell] = true
				if not filled(cell) then
					table.insert(cells, cell)
				end
			end
		end
		for _, cell in inside do
			add(cell - Vector3.new(0, 3, 0))
			for _, side in SIDES do
				if not set[cell + side] then
					add(cell + side)
					add(cell + side + Vector3.new(0, 3, 0))
				end
			end
			add(cell + Vector3.new(0, 6, 0))
		end
		return cells
	end

	local function grounded(inside)
		for _, cell in inside do
			if filled(cell - Vector3.new(0, 3, 0)) then return true end
		end
		return false
	end

	local function place(name, cells)
		local now = tick()
		local hold = math.clamp(lplr:GetNetworkPing() * 2 + 0.3, 0.4, 1.2)
		equipServer(name, 'BoxAura')
		for _, cell in cells do
			local _, info = store.buildable(cell)
			if info and not info.Collided and not info.InsideAntiBuild then
				store.placeBlock(name, cell)
				pending[cell] = now + hold
			end
		end
	end

	local function suffocate(now)
		for character, job in follow do
			if job.At > now then continue end
			follow[character] = nil
			local root = character.Parent and character:FindFirstChild('HumanoidRootPart')
			if not root then continue end
			local cells = {}
			for _, cell in job.Inside do
				local offset = root.Position - cell
				if math.abs(offset.X) <= 3 and math.abs(offset.Z) <= 3 then
					for _, inner in {cell, cell + Vector3.new(0, 3, 0)} do
						if not filled(inner) then
							table.insert(cells, inner)
						end
					end
				end
			end
			local name = #cells > 0 and blockName(#cells)
			if name then
				place(name, cells)
				return true
			end
		end
		return false
	end

	local function step()
		if not entitylib.isAlive then return end
		local now = tick()
		if suffocate(now) then return end
		local list = store.targets({
			Origin = realRoot().Position,
			Range = Range.Value,
			Players = Targets.Players.Enabled,
			NPCs = Targets.NPCs.Enabled,
			Sort = Sort.Value,
			Limit = 4
		})
		for _, ent in list do
			local character = ent.Character
			if not character or boxed[character] then continue end
			local position, speed = predicted(ent)
			local wide = Size.Value == '2x2' or (Size.Value == 'Auto' and speed > 3)
			local inside = insideCells(position, wide)
			if Grounded.Enabled and not grounded(inside) then continue end
			local cells = boxCells(inside)
			local name = blockName(#cells)
			if not name and wide and Size.Value == 'Auto' then
				inside = insideCells(position, false)
				cells = boxCells(inside)
				name = blockName(#cells)
			end
			if #cells == 0 then
				boxed[character] = true
				continue
			end
			if not name then
				if Notify.Enabled and now > warnedAt then
					warnedAt = now + 10
					notif('BoxAura', string.format('You need %d blocks to box %s.', #cells, ent.Player and ent.Player.Name or 'them'), 4, 'warning')
				end
				continue
			end
			place(name, cells)
			boxed[character] = true
			if Suffocate.Enabled then
				follow[character] = {At = now + math.clamp(lplr:GetNetworkPing() * 2 + 0.2, 0.35, 1.2), Inside = inside}
			end
			return
		end
		if not next(follow) then
			syncTool('BoxAura')
		end
	end

	BoxAura = vape.Categories.Blatant:CreateModule({
		Name = 'BoxAura',
		Function = function(callback)
			if callback then
				repeat
					step()
					for cell, untilAt in pending do
						if untilAt < tick() then
							pending[cell] = nil
						end
					end
					task.wait(0.05)
				until not BoxAura.Enabled
			else
				table.clear(boxed)
				table.clear(follow)
				table.clear(pending)
				syncTool('BoxAura')
			end
		end,
		Tooltip = 'Traps nearby enemies in a box of blocks'
	})
	Targets = BoxAura:CreateTargets({Players = true})
	Sort = BoxAura:CreateDropdown({
		Name = 'Target Mode',
		List = store.sortList,
		Tooltip = 'Which enemy is boxed first'
	})
	Range = BoxAura:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 60,
		Default = 20,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How far away a block can be placed'
	})
	Prediction = BoxAura:CreateToggle({
		Name = 'Prediction',
		Default = true,
		Tooltip = 'Builds where the enemy is heading'
	})
	Size = BoxAura:CreateDropdown({
		Name = 'Box size',
		List = {'Auto', '1x1', '2x2'},
		Tooltip = 'How wide the box is. Auto makes it wider around moving enemies'
	})
	Grounded = BoxAura:CreateToggle({
		Name = 'Only on ground',
		Default = true,
		Tooltip = 'Only boxes enemies standing on a block'
	})
	Suffocate = BoxAura:CreateToggle({
		Name = 'Suffocate',
		Tooltip = 'Also fills the space the player is standing in'
	})
	WoolOnly = BoxAura:CreateToggle({
		Name = 'Wool only',
		Default = true,
		Tooltip = 'Only uses wool'
	})
	Notify = BoxAura:CreateToggle({
		Name = 'Notify',
		Default = true,
		Tooltip = 'Tells you when you carry too few blocks'
	})
end)
