run(function()
	local SilentAim
	local Targets
	local Range
	local Fov
	local ShowFov
	local AutoShoot
	local Hold
	local Headshot
	local util, combat, controller = tribes.Util, tribes.Combat, tribes.Controller
	local guiService = game:GetService('GuiService')
	local holding, holdTool, holdKind, heldAt = false, nil, nil, 0
	local nextFire, nextCheck = 0, 0
	local chosenDirection, chosenAt = nil, 0
	local firing, canceling = false, false
	local THROWN = {Knives = true, Sling = true, Javelin = true, Bomb = true}
	local GUNS = {Crossbow = true, Musket = true, Pistol = true, Blunderbuss = true}
	local VISIBLE = {
		'Head', 'UpperTorso', 'Torso', 'LowerTorso', 'LeftUpperArm', 'RightUpperArm', 'LeftLowerArm', 'RightLowerArm',
		'Left Arm', 'Right Arm', 'LeftUpperLeg', 'RightUpperLeg', 'LeftLowerLeg', 'RightLowerLeg', 'Left Leg', 'Right Leg'
	}

	local overlay = Instance.new('ScreenGui')
	overlay.Name = 'AetherSilentAimFov'
	overlay.IgnoreGuiInset = true
	overlay.ResetOnSpawn = false
	overlay.DisplayOrder = 500
	overlay.Enabled = false
	overlay:SetAttribute('ElevateV4', true)
	overlay.Parent = lplr.PlayerGui
	vape:Clean(overlay)
	local circle = Instance.new('Frame')
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.BackgroundTransparency = 1
	circle.Parent = overlay
	Instance.new('UICorner', circle).CornerRadius = UDim.new(1, 0)
	local outline = Instance.new('UIStroke')
	outline.Color = Color3.new(1, 1, 1)
	outline.Parent = circle

	local function cursorPosition()
		if inputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
			return gameCamera.ViewportSize * 0.5
		end
		return gameapi.Cursor()
	end

	local function weapon()
		local tool, id, kind, tuning = gameapi.Tool()
		if tool and kind and combat.FiresProjectile(kind) then
			return tool, id, kind, tuning
		end
	end

	local function handler()
		local state = tribes.State
		local active = state and state.handler
		if type(active) ~= 'table' or type(active.Input) ~= 'function' then return nil end
		if active.ctx and active.ctx.tool and active.ctx.tool.Parent ~= lplr.Character then return nil end
		return active
	end

	local function inputPrimary(pressed, kind)
		local active = handler()
		if active then
			local previous = active.lastShot
			if not pcall(active.Input, active, 'Primary', pressed) then return false end
			if not pressed then return true end
			if combat.IsDrawn(kind) then return active.drawing == true end
			if kind == 'Javelin' or kind == 'Bomb' then return active.winding == true end
			return active.lastShot ~= previous or active.holding == true or active.m1Down == true
		end
		return gameapi.Dispatch('Primary', pressed)
	end

	local function targetVisible(origin, point, model)
		local delta = point - origin
		if delta.Magnitude < 0.1 or (combat.SmokeBlocks and combat.SmokeBlocks(origin, point)) then return false end
		if not Targets.Walls.Enabled then return true end
		local hit = workspace:Raycast(origin, delta, util.WorldParams())
		return hit == nil or hit.Instance:IsDescendantOf(model)
	end

	local function insideFov(cursor, part)
		local projected = gameCamera:WorldToViewportPoint(part.Position)
		if projected.Z <= 0 then return nil end
		local focal = gameCamera.ViewportSize.Y / (2 * math.tan(math.rad(gameCamera.FieldOfView) * 0.5))
		local radius = part.Size.Magnitude * 0.5 * focal / math.max(projected.Z, 0.1)
		local edge = math.max(0, (Vector2.new(projected.X, projected.Y) - cursor).Magnitude - radius)
		return edge <= Fov.Value and edge or nil
	end

	local function pick(origin, maxDistance, shot)
		if not SilentAim.Enabled or typeof(origin) ~= 'Vector3' then return nil end
		local cursor = cursorPosition()
		local limit = math.min(Range.Value, maxDistance or Range.Value)
		local ranked = {}
		for _, model in util.Targets() do
			if gameapi.Enemy(model, Targets) then
				local root = model:FindFirstChild('HumanoidRootPart')
				if root and (root.Position - origin).Magnitude <= limit + 5 then
					local edge
					for _, name in VISIBLE do
						local part = model:FindFirstChild(name)
						local score = part and part:IsA('BasePart') and insideFov(cursor, part)
						if score and (not edge or score < edge) then
							edge = score
						end
					end
					if edge then
						table.insert(ranked, {Model = model, Score = edge})
					end
				end
			end
		end
		table.sort(ranked, function(a, b)
			return a.Score < b.Score
		end)

		for _, entry in ranked do
			local model = entry.Model
			local head = model:FindFirstChild('Head')
			local torso = model:FindFirstChild('UpperTorso') or model:FindFirstChild('Torso') or model:FindFirstChild('LowerTorso') or model:FindFirstChild('HumanoidRootPart')
			local parts = {}
			if Headshot.Enabled then
				if head and head:IsA('BasePart') then
					table.insert(parts, head)
				end
			else
				if torso and torso:IsA('BasePart') then
					table.insert(parts, torso)
				end
				for _, name in VISIBLE do
					local part = model:FindFirstChild(name)
					if part and part:IsA('BasePart') and part ~= torso and part ~= head then
						table.insert(parts, part)
					end
				end
				if #parts == 0 and head then
					table.insert(parts, head)
				end
			end
			for _, part in parts do
				if (part.Position - origin).Magnitude <= limit then
					for _, point in {part.Position, part.Position + Vector3.new(0, part.Size.Y * 0.15, 0), part.Position - Vector3.new(0, part.Size.Y * 0.15, 0)} do
						if targetVisible(origin, point, model) then
							local delta = point - origin
							if delta.Magnitude > 0.1 then
								local ent = entitylib.getEntity(model)
								if ent then
									targetinfo.Targets[ent] = tick() + 1
								end
								if shot then
									local predicted = gameapi.Aim(origin, part, shot.speed, shot.gravity, false)
									if predicted then
										return predicted, model, part
									end
								end
								return delta.Unit, model, part
							end
						end
					end
				end
			end
		end
	end

	gameapi.Patch(util, 'AssistDirection', function(original)
		return function(origin, direction, flat)
			local normal = original(origin, direction, flat)
			if not SilentAim.Enabled then return normal end
			local tool, _, kind, tuning = weapon()
			if not tool or THROWN[kind] then return normal end
			local direct = pick(origin, tonumber(tuning and tuning.range), gameapi.ShotProfile(tool, kind, tuning))
			if direct then return direct end
			if firing and chosenDirection and os.clock() - chosenAt <= 0.2 then
				return chosenDirection
			end
			return normal
		end
	end)

	gameapi.Patch(tribes.Throw, 'Launch', function(original)
		return function(self, charge, assisted)
			local origin, direction, speed = original(self, charge, assisted)
			if not SilentAim.Enabled then return origin, direction, speed end
			local tuning = self.tuning
			local limit = tuning and tuning.returns and tonumber(tuning.returns.range) or nil
			local direct = pick(origin, limit, tuning and {speed = speed, gravity = tonumber(tuning.gravity) or 60} or nil)
			if direct then return origin, direct, speed end
			if firing and chosenDirection and os.clock() - chosenAt <= 0.2 then
				return origin, chosenDirection, speed
			end
			return origin, direction, speed
		end
	end)

	local function release(cancel)
		if cancel then
			chosenDirection = nil
		end
		if not holding then return end
		canceling, firing = cancel == true, not cancel
		inputPrimary(false, holdKind)
		firing, canceling, holding = false, false, false
		holdTool, holdKind = nil, nil
	end

	gameapi.Patch(tribes.Bow, 'Fire', function(original)
		return function(self, ...)
			if canceling and self.drawing then
				self:CancelDraw()
				return
			end
			return original(self, ...)
		end
	end)
	gameapi.Patch(tribes.Throw, 'Throw', function(original)
		return function(self, ...)
			if canceling and self.winding then
				self:Cancel()
				return
			end
			return original(self, ...)
		end
	end)

	local function ammoReady(tool, kind, tuning)
		if not tool or not tuning or tool:GetAttribute('Reloading') == true then return false end
		if tuning.ammo and util.AmmoLeft(lplr.Character, tuning.ammo) <= 0 then return false end
		local charges = tool:GetAttribute('Charges')
		if (tonumber(tuning.charges) or 0) > 0 and type(charges) == 'number' and charges <= 0 then return false end
		if GUNS[kind] then
			local magazine = tool:GetAttribute('Ammo')
			if type(magazine) == 'number' and magazine <= 0 then return false end
		end
		return true
	end

	local function autoUpdate()
		if not AutoShoot.Enabled or gameapi.Options.AutoKilling or not util.CanAct() or guiService.MenuIsOpen or lplr:GetAttribute('MenuOpen') == true or inputService:GetFocusedTextBox() or inputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			release(true)
			return
		end
		local tool, id, kind, tuning = weapon()
		if not tool or not ammoReady(tool, kind, tuning) then
			release(true)
			return
		end
		if holding and tool ~= holdTool then
			release(true)
			return
		end
		local thrown = THROWN[kind]
		local origin = util.ShotOrigin(tool, thrown and 'Tip' or 'Muzzle')
		if thrown and (kind == 'Sling' or id == 'bolas') and util.InFirstPerson() then
			origin = util.ShotOrigin(nil)
		end
		if typeof(origin) ~= 'Vector3' then return end

		local now = os.clock()
		local charged = combat.IsDrawn(kind) or kind == 'Javelin' or kind == 'Bomb'
		local precharge = id == 'longbow' and Hold.Enabled
		if precharge and not holding and now >= nextFire and inputPrimary(true, kind) then
			holding, holdTool, holdKind, heldAt = true, tool, kind, now
		end
		local direction = pick(origin, tonumber(tuning and tuning.range), gameapi.ShotProfile(tool, kind, tuning))
		if not direction then
			if not precharge and holding and now - heldAt > 1.2 then
				release(true)
			end
			return
		end
		chosenDirection, chosenAt = direction, now

		if charged then
			if not holding then
				if now >= nextFire and inputPrimary(true, kind) then
					holding, holdTool, holdKind, heldAt = true, tool, kind, now
				end
			else
				local duration = math.max(0.1, tonumber(tuning.drawTime) or 0.5)
				local required = duration * (Hold.Enabled and 1 or math.max(0.25, tonumber(tuning.minCharge) or 0.35))
				if now - heldAt >= required and now >= nextFire then
					nextFire = now + math.max(0.18, tonumber(tuning.cooldown) or 0.25)
					release(false)
				end
			end
		elseif now >= nextFire then
			firing = true
			local success = inputPrimary(true, kind)
			firing = false
			if success then
				nextFire = now + math.max(0.13, tonumber(tuning.fireInterval) or tonumber(tuning.cooldown) or 0.3)
				task.defer(inputPrimary, false, kind)
			else
				nextFire = now + 0.08
			end
		end
	end

	SilentAim = vape.Categories.Combat:CreateModule({
		Name = 'SilentAim',
		Function = function(callback)
			overlay.Enabled = callback and ShowFov.Enabled
			if callback then
				SilentAim:Clean(runService.Heartbeat:Connect(function()
					local now = os.clock()
					if now >= nextCheck then
						nextCheck = now + 0.04
						autoUpdate()
					end
				end))
				SilentAim:Clean(runService.RenderStepped:Connect(function()
					local visible = overlay.Enabled and weapon() ~= nil
					if circle.Visible ~= visible then
						circle.Visible = visible
					end
					if visible then
						local point = cursorPosition()
						circle.Position = UDim2.fromOffset(point.X, point.Y)
						circle.Size = UDim2.fromOffset(Fov.Value * 2, Fov.Value * 2)
					end
				end))
			else
				release(true)
			end
		end,
		Tooltip = 'Silently aims your shots at enemies'
	})
	Targets = SilentAim:CreateTargets({
		Players = true,
		NPCs = true,
		Walls = true
	})
	Range = SilentAim:CreateSlider({
		Name = 'Range',
		Min = 10,
		Max = 1000,
		Default = 300,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Fov = SilentAim:CreateSlider({
		Name = 'FOV',
		Min = 20,
		Max = 500,
		Default = 140,
		Suffix = 'px'
	})
	ShowFov = SilentAim:CreateToggle({
		Name = 'Show FOV',
		Default = true,
		Function = function(callback)
			overlay.Enabled = callback and SilentAim.Enabled
		end
	})
	Headshot = SilentAim:CreateToggle({
		Name = 'Headshot'
	})
	AutoShoot = SilentAim:CreateGroup({
		Name = 'Auto shoot',
		Function = function(callback)
			if not callback then
				release(true)
			end
		end,
		Tooltip = 'Fires by itself whenever a target is inside the circle'
	})
	Hold = AutoShoot:CreateToggle({
		Name = 'Hold',
		Default = true,
		Darker = true,
		Tooltip = 'Draws charged weapons fully before firing'
	})
end)
