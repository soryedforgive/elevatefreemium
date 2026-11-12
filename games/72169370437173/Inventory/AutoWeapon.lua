run(function()
	local AutoWeapon
	local MeleeRange
	local RangedRange
	local switchedAt = 0
	local RANGED = {Bow = true, Gun = true, Throw = true}

	local function first(want)
		for _, item in store.tools() do
			if want(item) then return item end
		end
	end

	AutoWeapon = vape.Categories.Inventory:CreateModule({
		Name = 'AutoWeapon',
		Function = function(callback)
			if callback then
				repeat
					local handler, class = store.handler()
					local busy = handler and (handler.drawing or handler.winding or handler.blocking)
					if handler and entitylib.isAlive and inMatch() and canAct() and not busy and tick() - switchedAt > 1 then
						local pos = store.body()
						local dist
						for _, ent in entitylib.List do
							if ent.Targetable and ent.Health > 0 then
								local d = (ent.RootPart.Position - pos).Magnitude
								dist = math.min(dist or d, d)
							end
						end
						local item
						if dist and dist <= MeleeRange.Value and class ~= 'Melee' then
							item = first(function(v) return v.Class == 'Melee' and v.Kind ~= 'Fists' end)
						elseif dist and dist > MeleeRange.Value and dist <= RangedRange.Value and class == 'Melee' then
							item = first(function(v) return RANGED[v.Class] end)
						end
						if item and not item.Held and store.equip(item.Tool) then
							switchedAt = tick()
						end
					end
					task.wait(0.2)
				until not AutoWeapon.Enabled
			end
		end,
		Tooltip = 'Picks melee for close enemies and ranged for far ones'
	})
	MeleeRange = AutoWeapon:CreateSlider({
		Name = 'Melee range',
		Min = 5,
		Max = 30,
		Default = 14,
		Suffix = 'studs',
		Tooltip = 'Uses your melee weapon within this range'
	})
	RangedRange = AutoWeapon:CreateSlider({
		Name = 'Ranged range',
		Min = 20,
		Max = 400,
		Default = 150,
		Suffix = 'studs',
		Tooltip = 'Between the melee range and this you hold your ranged weapon'
	})
end)
