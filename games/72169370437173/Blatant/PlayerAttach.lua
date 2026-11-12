run(function()
	local PlayerAttach
	local Range
	local util, combat = tribes.Util, tribes.Combat
	local target
	local nextScan = 0

	local function closest(root)
		local selected, nearest = nil, Range.Value
		for _, model in util.Targets() do
			if gameapi.Enemy(model) then
				local part = model:FindFirstChild('HumanoidRootPart')
				local distance = part and (part.Position - root.Position).Magnitude
				if distance and distance <= nearest then
					nearest, selected = distance, model
				end
			end
		end
		return selected
	end

	local function active()
		return PlayerAttach.Enabled and target and gameapi.Enemy(target) and not gameapi.Options.AutoKilling
	end

	gameapi.Patch(util, 'GetAimRay', function(original)
		return function(...)
			local ray = original(...)
			if not (PlayerAttach and active()) then return ray end
			local _, _, kind = gameapi.Tool()
			local part = target:FindFirstChild('HumanoidRootPart')
			if not (kind and combat.IsMelee(kind) and part) then return ray end
			local direction = part.Position - ray.Origin
			return direction.Magnitude > 0.01 and Ray.new(ray.Origin, direction.Unit) or ray
		end
	end)
	gameapi.Patch(util, 'FaceCamera', function(original)
		return function(...)
			if PlayerAttach and active() then return end
			return original(...)
		end
	end)

	PlayerAttach = vape.Categories.Blatant:CreateModule({
		Name = 'PlayerAttach',
		Function = function(callback)
			if callback then
				PlayerAttach:Clean(runService.Heartbeat:Connect(function()
					if gameapi.Options.AutoKilling or not (entitylib.isAlive and util.CanAct()) then
						target = nil
						return
					end
					local root = entitylib.character.RootPart
					if target and not gameapi.Enemy(target) then
						target, nextScan = nil, 0
					end
					if not target and os.clock() >= nextScan then
						nextScan = os.clock() + 0.15
						target = closest(root)
					end
					local enemyRoot = target and target:FindFirstChild('HumanoidRootPart')
					if not enemyRoot then return end
					local flat = enemyRoot.CFrame.LookVector * Vector3.new(1, 0, 1)
					if flat.Magnitude <= 0.01 then return end
					local back = enemyRoot.Position - flat.Unit * 2.8
					local position = Vector3.new(back.X, enemyRoot.Position.Y, back.Z)
					root.CFrame = CFrame.lookAt(position, Vector3.new(enemyRoot.Position.X, position.Y, enemyRoot.Position.Z))
				end))
			else
				target, nextScan = nil, 0
			end
		end,
		Tooltip = 'Sticks you to the nearest target'
	})
	Range = PlayerAttach:CreateSlider({
		Name = 'Range',
		Min = 5,
		Max = 150,
		Default = 45,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)
