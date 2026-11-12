run(function()
	local Reach
	local Attack
	local AttackRange
	local Place
	local PlaceRange
	local Break
	local BreakRange
	local strikeHook, oldStrike
	local rayHook, oldRay
	local placeHook, oldPlace
	local hitHook, oldHit
	local patches = {}
	local hop
	local idleSince = 0

	local LEGIT = {Attack = 13.5, Place = 18, Break = 18}
	local SERVER = {Attack = 17, Place = 20, Break = 20}
	local hitBlocks = skywars.MeleeConstants.MAXIMUM_HIT_RANGE_BLOCKS

	local function setRay(name, func, length)
		local patch = patches[name]
		if not patch then
			local ok, constants = pcall(debug.getconstants, func)
			if not ok or type(constants) ~= 'table' then return end
			for index, value in constants do
				if value == 35 then
					patch = {Function = func, Index = index}
					patches[name] = patch
					break
				end
			end
		end
		if patch then
			pcall(debug.setconstant, patch.Function, patch.Index, length)
		end
	end

	local function applyAttack()
		local on = Reach.Enabled and Attack.Enabled
		skywars.MeleeConstants.MAXIMUM_HIT_RANGE_BLOCKS = on and AttackRange.Value / 3 or hitBlocks
		setRay('Attack', skywars.MeleeController.strikeDesktop, on and math.max(35, AttackRange.Value + 60) or 35)
	end

	local function applyBlocks()
		if not oldRay then return end
		local range = 0
		if Reach.Enabled then
			range = math.max(Place.Enabled and PlaceRange.Value or 0, Break.Enabled and BreakRange.Value or 0)
		end
		setRay('Blocks', oldRay, math.max(35, range + 60))
	end

	local function startHop(goal, seconds, target)
		local same = hop and hop.Target == target and target ~= nil
		hop = {
			Goal = goal,
			Until = tick() + seconds,
			Since = same and hop.Since or tick(),
			Target = target,
			Hit = target and target.LastHit or nil
		}
	end

	local function nearBlock(position)
		return position + Vector3.new(0, 9, 0)
	end

	local function stopHop()
		hop = nil
		if store.reach then
			store.reach = nil
			equip(nil)
		end
	end

	Reach = vape.Categories.Combat:CreateModule({
		Name = 'Reach',
		ExtraText = function()
			return tostring(AttackRange.Value)
		end,
		Tooltip = 'Lets you hit, place and mine from further away',
		Function = function(callback)
			applyAttack()
			if callback then
				local melee, raycast, blocks = skywars.MeleeController, skywars.BlockRaycastController, skywars.BlockController

				if not strikeHook then
					oldStrike = melee.attemptStrikeDesktop
					strikeHook = function(self, part, ...)
						if Reach.Enabled and Attack.Enabled and typeof(part) == 'Instance' then
							local model = part:FindFirstAncestorOfClass('Model')
							local player = model and playersService:GetPlayerFromCharacter(model)
							local ent = player and entitylib.getEntity(player)
							if ent and ent.Targetable and ent.RootPart and (ent.RootPart.Position - bodyRoot().Position).Magnitude <= AttackRange.Value and (ent.RootPart.Position - realRoot().Position).Magnitude > SERVER.Attack then
								startHop(function()
									return attachPosition(ent, 15)
								end, 0.8, ent)
							end
						end
						return oldStrike(self, part, ...)
					end
					melee.attemptStrikeDesktop = strikeHook
				end

				if not rayHook then
					oldRay = raycast.raycastBlockLocation
					rayHook = function(self, mouse, mode, ...)
						local range
						if Reach.Enabled then
							if mode == 1 and Place.Enabled then
								range = PlaceRange.Value
							elseif mode == 0 and Break.Enabled then
								range = BreakRange.Value
							end
						end
						if not range then
							return oldRay(self, mouse, mode, ...)
						end
						local constants = skywars.BlockConstants
						local saved = constants.MAXIMUM_PLACE_RANGE
						constants.MAXIMUM_PLACE_RANGE = range / 3
						local results = table.pack(pcall(oldRay, self, mouse, mode, ...))
						constants.MAXIMUM_PLACE_RANGE = saved
						if not results[1] then
							error(results[2], 0)
						end
						return table.unpack(results, 2, results.n)
					end
					raycast.raycastBlockLocation = rayHook
				end

				if not placeHook then
					oldPlace = blocks.placeBlock
					placeHook = function(self, position, ...)
						if Reach.Enabled and Place.Enabled and typeof(position) == 'Vector3' and entitylib.isAlive and (position - realRoot().Position).Magnitude > SERVER.Place then
							local arrived = hop and not hop.Target and (hop.Spot - position).Magnitude <= 12 and tick() - hop.Since or 0
							if arrived <= 0 then
								startHop(nearBlock(position), 0.8)
								hop.Spot = position
							else
								hop.Until = tick() + 0.5
							end
							local wait = math.max(0.3 - arrived, 0)
							if wait > 0 then
								local args = table.pack(...)
								task.delay(wait, function()
									if Reach.Enabled and entitylib.isAlive then
										oldPlace(self, position, table.unpack(args, 1, args.n))
									end
								end)
								return nil
							end
						end
						return oldPlace(self, position, ...)
					end
					blocks.placeBlock = placeHook
				end

				if not hitHook then
					oldHit = blocks.hitBlock
					hitHook = function(self, position, ...)
						if Reach.Enabled and Break.Enabled and typeof(position) == 'Vector3' and entitylib.isAlive and (position - realRoot().Position).Magnitude > SERVER.Break then
							if hop and not hop.Target and (hop.Spot - position).Magnitude <= 12 then
								hop.Until = tick() + 0.4
							else
								startHop(nearBlock(position), 0.4)
								hop.Spot = position
							end
						end
						return oldHit(self, position, ...)
					end
					blocks.hitBlock = hitHook
				end
				applyBlocks()

				Reach:Clean(runService.Heartbeat:Connect(function()
					if not (hop and hop.Until > tick() and entitylib.isAlive) or outranked('reach') then
						stopHop()
						if tick() - idleSince > 1 then
							mergeRoot('Reach')
						end
						return
					end
					local target = hop.Target
					if target and not (target.RootPart and target.RootPart.Parent and table.find(entitylib.List, target)) then
						stopHop()
						return
					end
					if not splitRoot('Reach') then return end
					store.reach = true
					idleSince = tick()
					sendRoot(type(hop.Goal) == 'function' and hop.Goal() or hop.Goal)
					if target then
						if target.LastHit ~= hop.Hit then
							stopHop()
							return
						end
						local sword = store.tools.sword
						if sword and strikeReady(target) then
							equip(sword)
							fireRemote('strike', target.Player)
						end
					end
				end))
			else
				stopHop()
				mergeRoot('Reach')
				local melee, raycast, blocks = skywars.MeleeController, skywars.BlockRaycastController, skywars.BlockController
				setRay('Blocks', oldRay, 35)
				if melee.attemptStrikeDesktop == strikeHook then
					melee.attemptStrikeDesktop = oldStrike
					strikeHook, oldStrike = nil, nil
				end
				if raycast.raycastBlockLocation == rayHook then
					raycast.raycastBlockLocation = oldRay
					rayHook, oldRay = nil, nil
				end
				if blocks.placeBlock == placeHook then
					blocks.placeBlock = oldPlace
					placeHook, oldPlace = nil, nil
				end
				if blocks.hitBlock == hitHook then
					blocks.hitBlock = oldHit
					hitHook, oldHit = nil, nil
				end
			end
		end
	})
	Attack = Reach:CreateGroup({
		Name = 'Attack',
		Default = true,
		Function = function(callback)
			if AttackRange then
				applyAttack()
			end
		end,
		Tooltip = 'How far away a target can be'
	})
	AttackRange = Attack:CreateSlider({
		Name = 'Attack range',
		Min = 1,
		Max = 1000,
		Default = LEGIT.Attack,
		Decimal = 2,
		Darker = true,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Function = function()
			applyAttack()
		end,
		Tooltip = 'How far away a target can be'
	})
	Place = Reach:CreateGroup({
		Name = 'Place',
		Function = function(callback)
			if PlaceRange then
				applyBlocks()
			end
		end,
		Tooltip = 'Lets you place blocks from further away'
	})
	PlaceRange = Place:CreateSlider({
		Name = 'Place range',
		Min = 1,
		Max = 1000,
		Default = LEGIT.Place,
		Darker = true,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Function = function()
			applyBlocks()
		end,
		Tooltip = 'How far away a block can be placed'
	})
	Break = Reach:CreateGroup({
		Name = 'Break',
		Function = function(callback)
			if BreakRange then
				applyBlocks()
			end
		end,
		Tooltip = 'Lets you mine from further away'
	})
	BreakRange = Break:CreateSlider({
		Name = 'Break range',
		Min = 1,
		Max = 1000,
		Default = LEGIT.Break,
		Darker = true,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Function = function()
			applyBlocks()
		end,
		Tooltip = 'How far away a block can be mined'
	})
	Reach:CreateButton({
		Name = 'Reset to default reach',
		Tooltip = 'Sets every range back to the game\'s default',
		Function = function()
			AttackRange:SetValue(LEGIT.Attack)
			PlaceRange:SetValue(LEGIT.Place)
			BreakRange:SetValue(LEGIT.Break)
		end
	})
end)
