run(function()
	local BoxAura
	local Targets
	local Sort
	local Range
	local Prediction
	local Grounded
	local Notify
	local Suffocate
	local hop
	local tries = {}
	local SERVER = 20
	local SIDES = {Vector3.new(3, 0, 0), Vector3.new(-3, 0, 0), Vector3.new(0, 0, 3), Vector3.new(0, 0, -3)}
	local sorts = {
		Distance = function(a, b)
			return a.Magnitude < b.Magnitude
		end,
		['Lowest health'] = function(a, b)
			return a.Entity.Health < b.Entity.Health
		end,
		['Highest health'] = function(a, b)
			return a.Entity.Health > b.Entity.Health
		end,
		Cursor = function(a, b)
			local function off(ent)
				local pos, vis = gameCamera:WorldToViewportPoint(ent.RootPart.Position)
				return vis and (Vector2.new(pos.X, pos.Y) - gameCamera.ViewportSize / 2).Magnitude or math.huge
			end
			return off(a.Entity) < off(b.Entity)
		end
	}

	local function release()
		hop = nil
		if store.boxAura then
			store.boxAura = nil
		end
		mergeRoot('BoxAura')
	end

	local function standCells(ent)
		local root = ent.RootPart
		local position = root.Position
		if Prediction.Enabled then
			local lead = math.clamp(lplr:GetNetworkPing() * 1.5 + 0.05, 0.1, 0.5)
			local velocity = root.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
			if velocity.Magnitude > 30 then
				velocity = velocity.Unit * 30
			end
			position += velocity * lead
		end
		local legs = store.cell(position - Vector3.new(0, 1.5, 0))
		return legs, legs + Vector3.new(0, 3, 0)
	end

	local function boxCells(legs, head)
		local cells, extras = {}, {}
		local floor = legs - Vector3.new(0, 3, 0)
		table.insert(cells, floor)
		for _, side in SIDES do
			table.insert(cells, legs + side)
		end
		for _, side in SIDES do
			table.insert(cells, head + side)
		end
		local support
		for _, side in SIDES do
			if store.filled(head + side + Vector3.new(0, 3, 0)) then
				support = head + side + Vector3.new(0, 3, 0)
				break
			end
		end
		table.insert(cells, support or (head + SIDES[1] + Vector3.new(0, 3, 0)))
		table.insert(cells, head + Vector3.new(0, 3, 0))
		for x = -1, 1 do
			for z = -1, 1 do
				if x ~= 0 or z ~= 0 then
					table.insert(extras, floor + Vector3.new(x * 3, 0, z * 3))
				end
			end
		end
		return cells, extras
	end

	local function boxed(legs, head)
		if not store.filled(head + Vector3.new(0, 3, 0)) then return false end
		for _, side in SIDES do
			if not (store.filled(legs + side) and store.filled(head + side)) then return false end
		end
		return true
	end

	local function pickTarget()
		local origin = bodyRoot().Position
		local list = {}
		for _, ent in entitylib.List do
			if ent.Targetable and ent.RootPart and ent.RootPart.Parent and (ent.Health or 100) > 0 and ((ent.Player and Targets.Players.Enabled) or (ent.NPC and Targets.NPCs.Enabled)) and not fallen(ent) then
				local mag = (ent.RootPart.Position - origin).Magnitude
				if mag <= Range.Value and (tries[ent] or 0) < tick() then
					local legs, head = standCells(ent)
					local closed = boxed(legs, head)
					local inside = closed and Suffocate.Enabled and not (store.filled(legs) and store.filled(head))
					if (not closed or inside) and (not Grounded.Enabled or store.blocks[legs - Vector3.new(0, 3, 0)]) then
						table.insert(list, {Entity = ent, Magnitude = mag, Legs = legs, Head = head, Inside = inside})
					end
				end
			end
		end
		if #list > 1 then
			table.sort(list, sorts[Sort.Value] or sorts.Distance)
		end
		return list[1]
	end

	local function step()
		if not entitylib.isAlive or outranked('boxAura') then
			release()
			return
		end
		local pick = pickTarget()
		if not pick then
			if hop and tick() - hop.Since > 0.6 then
				release()
			end
			return
		end

		local cells, extras = boxCells(pick.Legs, pick.Head)
		local usable = {}
		if pick.Inside then
			usable, extras = {pick.Legs, pick.Head}, nil
		else
			for _, cell in cells do
				if store.filled(cell) or store.cellFree(cell) then
					table.insert(usable, cell)
				end
			end
		end
		local order = store.orderCells(usable, extras)
		if #order == 0 then
			tries[pick.Entity] = tick() + 0.3
			return
		end
		local item, amount = store.blockItem(#order)
		if not item then
			if Notify.Enabled and (tries.warned or 0) < tick() then
				tries.warned = tick() + 10
				notif('BoxAura', string.format('You need %d blocks to box %s.', #order, pick.Entity.Player and pick.Entity.Player.Name or 'them'), 4, 'warning')
			end
			tries[pick.Entity] = tick() + 1
			return
		end

		local far = false
		local origin = realRoot().Position
		for _, cell in order do
			if (cell - origin).Magnitude > SERVER then
				far = true
				break
			end
		end
		if far or hop then
			if not splitRoot('BoxAura') then return end
			store.boxAura = true
			local spot = pick.Head + Vector3.new(0, 14, 0)
			if not hop or hop.Entity ~= pick.Entity then
				hop = {Entity = pick.Entity, Since = tick()}
			end
			sendRoot(spot)
			if tick() - hop.Since < 0.35 then return end
		end

		store.placeCells(order, item)
		tries[pick.Entity] = tick() + (pick.Inside and 1 or 0.25)
	end

	BoxAura = vape.Categories.Blatant:CreateModule({
		Name = 'BoxAura',
		Function = function(callback)
			if callback then
				BoxAura:Clean(entitylib.Events.LocalRemoved:Connect(function()
					hop = nil
					store.boxAura = nil
				end))
				repeat
					step()
					task.wait(0.05)
				until not BoxAura.Enabled
			else
				release()
				table.clear(tries)
			end
		end,
		Tooltip = 'Traps nearby enemies in a box of blocks'
	})
	Targets = BoxAura:CreateTargets({Players = true})
	Sort = BoxAura:CreateDropdown({
		Name = 'Target Mode',
		List = {'Distance', 'Lowest health', 'Highest health', 'Cursor'},
		Tooltip = 'Which enemy is boxed first'
	})
	Range = BoxAura:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 200,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How far away a target can be'
	})
	Prediction = BoxAura:CreateToggle({
		Name = 'Prediction',
		Default = true,
		Tooltip = 'Builds where the enemy is heading'
	})
	Grounded = BoxAura:CreateToggle({
		Name = 'Only on blocks',
		Default = true,
		Tooltip = 'Only boxes enemies standing on a block'
	})
	Suffocate = BoxAura:CreateToggle({
		Name = 'Suffocate',
		Tooltip = 'Also fills the space the player is standing in'
	})
	Notify = BoxAura:CreateToggle({
		Name = 'Notify',
		Default = true,
		Tooltip = 'Tells you when you carry too few blocks'
	})
end)
