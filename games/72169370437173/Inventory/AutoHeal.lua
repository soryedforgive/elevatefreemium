run(function()
	local AutoHeal
	local Health
	local Safe
	local SafeRange
	local SwitchBack
	local healingUntil = 0

	local function healer()
		for _, item in store.tools() do
			if item.Kind == 'Herbs' then return item end
		end
	end

	AutoHeal = vape.Categories.Inventory:CreateModule({
		Name = 'AutoHeal',
		Function = function(callback)
			if callback then
				repeat
					local hum = entitylib.isAlive and entitylib.character.Humanoid
					if hum and tick() > healingUntil and inMatch() and canAct() and hum.MaxHealth > 0 and hum.Health / hum.MaxHealth * 100 < Health.Value then
						local clear = true
						if Safe.Enabled then
							local pos = store.body()
							for _, ent in entitylib.List do
								if ent.Targetable and ent.Health > 0 and (ent.RootPart.Position - pos).Magnitude <= SafeRange.Value then
									clear = false
									break
								end
							end
						end
						local item = clear and healer()
						if item then
							local before = not item.Held and tribes.State.tool
							if not item.Held then
								store.equip(item.Tool)
							end
							local deadline = tick() + 1.5
							local handler, class, kind
							repeat
								task.wait(0.05)
								handler, class, kind = store.handler()
							until kind == 'Herbs' or tick() > deadline
							if kind == 'Herbs' then
								pcall(handler.Input, handler, 'Primary', true)
								pcall(handler.Input, handler, 'Primary', false)
								local time = (handler.tuning.healTime or 3) + 0.3
								healingUntil = tick() + time
								if SwitchBack.Enabled and before then
									task.delay(time, function()
										if before.Parent then
											store.equip(before)
										end
									end)
								end
							else
								healingUntil = tick() + 1
							end
						end
					end
					task.wait(0.25)
				until not AutoHeal.Enabled
			end
		end,
		Tooltip = 'Uses your herbs when your health drops'
	})
	Health = AutoHeal:CreateSlider({
		Name = 'Health',
		Min = 5,
		Max = 95,
		Default = 50,
		Suffix = '%',
		Tooltip = 'Heals below this much health'
	})
	Safe = AutoHeal:CreateGroup({
		Name = 'Only when safe',
		Default = true,
		Tooltip = 'Waits until no enemy is close',
	})
	SafeRange = Safe:CreateSlider({
		Name = 'Safe range',
		Min = 5,
		Max = 60,
		Default = 20,
		Suffix = 'studs',
		Darker = true
	})
	SwitchBack = AutoHeal:CreateToggle({
		Name = 'Switch back',
		Default = true,
		Tooltip = 'Switches back to your last item afterwards'
	})
end)
