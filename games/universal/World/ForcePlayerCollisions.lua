run(function()
	local ForcePlayerCollisions
	local Mode
	local ForceCollision
	local Targets

	local originals = setmetatable({}, {__mode = 'k'})
	local hitboxes = setmetatable({}, {__mode = 'k'})
	local sight = RaycastParams.new()
	sight.FilterType = Enum.RaycastFilterType.Exclude

	local bodyCache = setmetatable({}, {__mode = 'k'})
	local function getBodyParts(character)
		if not character then
			return {}
		end
		local cached = bodyCache[character]
		if cached and os.clock() - cached.At < 1 then
			return cached.Parts
		end
		local parts = {}
		bodyCache[character] = {Parts = parts, At = os.clock()}

		for _, part in ipairs(character:GetChildren()) do
			if part:IsA('BasePart')
				and part.Name ~= 'HumanoidRootPart'
				and part.Name ~= 'Humanoid' then
				table.insert(parts, part)
			end
		end

		return parts
	end

	local function applyReal(character, state)
		if not character then return end

		for _, part in ipairs(getBodyParts(character)) do
			if originals[part] == nil then
				originals[part] = part.CanCollide
			end

			if part.CanCollide ~= state then
				part.CanCollide = state
			end
		end
	end

	local function restoreReal()
		for part, state in pairs(originals) do
			if part and part.Parent then
				part.CanCollide = state
			end

			originals[part] = nil
		end
	end

	local function removeHitbox(character)
		local folder = hitboxes[character]

		if folder then
			folder:Destroy()
			hitboxes[character] = nil
		end
	end

	local function createHitbox(character)
		if not character or not character.Parent then
			return
		end

		removeHitbox(character)

		local folder = Instance.new('Folder')
		folder.Name = 'PlayerCollisionHitbox'
		folder.Parent = character

		hitboxes[character] = folder

		for _, original in ipairs(getBodyParts(character)) do
			local hitbox = Instance.new('Part')
			hitbox.Name = original.Name .. '_Collision'
			hitbox.Size = original.Size
			hitbox.CFrame = original.CFrame
			hitbox.Transparency = 1
			hitbox.CanCollide = true
			hitbox.CanTouch = false
			hitbox.CanQuery = false
			hitbox.CastShadow = false
			hitbox.Massless = true
			hitbox.Anchored = false
			hitbox.Parent = folder

			local weld = Instance.new('WeldConstraint')
			weld.Part0 = hitbox
			weld.Part1 = original
			weld.Parent = hitbox
		end
	end

	local function clearHitboxes()
		for character, folder in pairs(hitboxes) do
			if folder then
				folder:Destroy()
			end

			hitboxes[character] = nil
		end
	end

	local function invisible(character)
		local root = character:FindFirstChild('HumanoidRootPart')
		return root ~= nil and (root.Transparency >= 0.95 or root.LocalTransparencyModifier >= 0.95)
	end

	local function inSight(character, root)
		if not Targets.Walls.Enabled then return true end
		local camera = workspace.CurrentCamera
		if not camera then return true end
		sight.FilterDescendantsInstances = {lplr.Character, character}
		return workspace:Raycast(camera.CFrame.Position, root.Position - camera.CFrame.Position, sight) == nil
	end

	local function subjects()
		local candidates = {}

		if Targets.Players.Enabled then
			for _, player in ipairs(playersService:GetPlayers()) do
				if player ~= lplr and player.Character then
					table.insert(candidates, player.Character)
				end
			end
		end

		if Targets.NPCs.Enabled and entitylib and entitylib.List then
			for _, entity in ipairs(entitylib.List) do
				if not entity.Player and entity.Character then
					table.insert(candidates, entity.Character)
				end
			end
		end

		local wanted = {}
		for _, character in ipairs(candidates) do
			local root = character:FindFirstChild('HumanoidRootPart')
			if root and not (Targets.Invisible.Enabled and invisible(character)) and inSight(character, root) then
				table.insert(wanted, character)
			end
		end
		return wanted
	end

	local function update()
		restoreReal()
		clearHitboxes()

		if not ForcePlayerCollisions.Enabled then
			return
		end

		for _, character in ipairs(subjects()) do
			if Mode.Value == 'Real' then
				applyReal(character, true)
			elseif Mode.Value == 'Hitbox' then
				createHitbox(character)
			end
		end
	end

	ForcePlayerCollisions = vape.Categories.World:CreateModule({
		Name = 'ForcePlayerCollisions',

		Function = function(callback)
			if callback then
				ForcePlayerCollisions:Clean(
					playersService.PlayerAdded:Connect(function(player)
						ForcePlayerCollisions:Clean(
							player.CharacterAdded:Connect(function()
								task.wait()
								update()
							end)
						)
					end)
				)

				ForcePlayerCollisions:Clean(
					runService.PreSimulation:Connect(function()
						if Mode.Value == 'Real'
							and ForceCollision.Value == 'On' then

							for _, character in ipairs(subjects()) do
								applyReal(character, true)
							end
						end
					end)
				)

				update()
			else
				restoreReal()
				clearHitboxes()
			end
		end,

		ExtraText = function()
			return Mode.Value
		end,

		Tooltip = 'Makes other players physically collidable'
	})
	Targets = ForcePlayerCollisions:CreateTargets({
		Players = true,
		NPCs = false,
		Function = function()
			update()
		end,
		Tooltip = 'Who gets collisions'
	})

	Mode = ForcePlayerCollisions:CreateDropdown({
		Name = 'Mode',
		List = {'Real', 'Hitbox'},
		Default = 'Hitbox',
		Function = function(value)
			ForceCollision.Visible = value == 'Real'
			update()
		end
	})

	ForceCollision = ForcePlayerCollisions:CreateDropdown({
		Name = 'Force Collision',
		List = {'On', 'Off'},
		Default = 'On'
	})

	ForceCollision.Visible = Mode.Value == 'Real'

end)
