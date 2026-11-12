run(function()
	local ProjectileAura
	local Targets
	local Range
	local Charge
	local Walls
	local mine = false

	local function find(origin)
		local best, dist
		for _, ent in entitylib.List do
			if ent.Targetable and ent.Health > 0 and ((ent.Player and Targets.Players.Enabled) or (ent.NPC and Targets.NPCs.Enabled)) then
				local d = (ent.RootPart.Position - origin).Magnitude
				if d <= Range.Value and (not dist or d < dist) then
					if not Walls.Enabled or not workspace:Raycast(origin, ent.RootPart.Position - origin, store.worldParams()) then
						best, dist = ent, d
					end
				end
			end
		end
		return best
	end

	ProjectileAura = vape.Categories.Blatant:CreateModule({
		Name = 'ProjectileAura',
		Function = function(callback)
			if callback then
				ProjectileAura:Clean(runService.Heartbeat:Connect(function()
					local handler, class = store.handler()
					if not (handler and entitylib.isAlive and canAct()) or not (class == 'Bow' or class == 'Gun' or class == 'Throw') then
						mine = false
						return
					end
					local origin = store.body() + Vector3.new(0, 1.5, 0)
					local ent = find(origin)
					if not ent or not store.aimAt(origin, ent) then
						if mine and (handler.drawing or handler.winding) then
							pcall(handler.Input, handler, 'Primary', false)
						end
						mine = false
						return
					end
					if class == 'Gun' then
						if not handler.reloading and (handler.ammo or 0) > 0 then
							store.press(handler, true, ent)
							store.press(handler, false, ent)
						end
					elseif class == 'Bow' or (class == 'Throw' and handler.winds) then
						if handler.drawing or handler.winding then
							if handler:Charge() >= Charge.Value / 100 then
								store.press(handler, false, ent)
								mine = false
							end
						else
							store.press(handler, true)
							mine = handler.drawing or handler.winding
						end
					else
						store.press(handler, true, ent)
						store.press(handler, false, ent)
					end
				end))
			else
				local handler = store.handler()
				if mine and handler and (handler.drawing or handler.winding) then
					pcall(handler.Input, handler, 'Primary', false)
				end
				mine = false
			end
		end,
		Tooltip = 'Shoots enemies around you'
	})
	Targets = ProjectileAura:CreateTargets({
		Players = true,
		NPCs = true
	})
	Range = ProjectileAura:CreateSlider({
		Name = 'Range',
		Min = 10,
		Max = 400,
		Default = 120,
		Suffix = 'studs'
	})
	Charge = ProjectileAura:CreateSlider({
		Name = 'Charge',
		Min = 10,
		Max = 100,
		Default = 100,
		Suffix = '%',
		Tooltip = 'How far to charge before firing'
	})
	Walls = ProjectileAura:CreateToggle({
		Name = 'Wall check',
		Default = true,
		Tooltip = 'Skips enemies behind walls'
	})
end)
