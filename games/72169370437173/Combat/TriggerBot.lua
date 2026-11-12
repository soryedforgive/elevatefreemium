run(function()
	local TriggerBot
	local Targets
	local Range
	local Melees
	local Projectiles
	local Cps
	local util, combat = tribes.Util, tribes.Combat
	local releaseAt, firedAt = 0, 0
	local held, currentTool = false, nil

	local function stop()
		if held then
			gameapi.Primary('TriggerBot', false)
			held = false
		end
		currentTool, releaseAt = nil, 0
	end

	local function aimedTarget(maxDistance)
		local ok, ray = pcall(util.GetAimRay)
		if not ok or typeof(ray) ~= 'Ray' or ray.Direction.Magnitude < 0.001 then return nil end
		local hit = workspace:Raycast(ray.Origin, ray.Direction.Unit * maxDistance, util.WorldParams())
		if not hit then return nil end
		local model = hit.Instance:FindFirstAncestorOfClass('Model')
		while model and not model:FindFirstChildOfClass('Humanoid') do
			model = model.Parent and model.Parent:FindFirstAncestorOfClass('Model')
		end
		return model and gameapi.Enemy(model, Targets) and model or nil
	end

	TriggerBot = vape.Categories.Combat:CreateModule({
		Name = 'TriggerBot',
		Function = function(callback)
			stop()
			if callback then
				repeat
					local now = os.clock()
					local tool, _, kind, tuning = gameapi.Tool()
					local melee = kind and combat.IsMelee(kind)
					local compatible = kind and tuning and ((melee and Melees.Enabled) or (not melee and Projectiles.Enabled and combat.FiresProjectile(kind)))
					if held and (now >= releaseAt or tool ~= currentTool or not compatible or not util.CanAct()) then
						stop()
					end
					if compatible and util.CanAct() and not gameapi.Options.AutoKilling and not held and now >= firedAt and not inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and aimedTarget(Range.Value) then
						local waiting = math.max(1 / math.max(Cps.Value, 1), tonumber(tuning.cooldown) or tonumber(tuning.fireInterval) or 0.2)
						local duration = (combat.IsDrawn(kind) or kind == 'Javelin' or kind == 'Bomb') and math.max(0.12, tonumber(tuning.drawTime) or 0.5) + 0.04 or 0.055
						if gameapi.Primary('TriggerBot', true) then
							held, currentTool = true, tool
							releaseAt = now + duration
							firedAt = now + math.max(waiting, duration)
						end
					end
					task.wait(0.025)
				until not TriggerBot.Enabled
				stop()
			end
		end,
		Tooltip = 'Attacks or fires when your cursor is on an enemy'
	})
	Targets = TriggerBot:CreateTargets({
		Players = true,
		NPCs = true
	})
	Range = TriggerBot:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 300,
		Default = 80,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Melees = TriggerBot:CreateToggle({
		Name = 'Melee',
		Default = true
	})
	Projectiles = TriggerBot:CreateToggle({
		Name = 'Projectiles',
		Default = true
	})
	Cps = TriggerBot:CreateSlider({
		Name = 'CPS',
		Min = 1,
		Max = 15,
		Default = 5
	})
end)
