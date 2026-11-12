run(function()
	local Aimbot
	local Targets
	local Range
	local Fov
	local ShowFov
	local AimSpeed
	local Melee
	local Projectiles
	local PriorityMode
	local util, combat = tribes.Util, tribes.Combat
	local cameraApi = (util and util.Camera and util.Camera()) or tribes.Camera
	local locked
	local lookLocked = false
	local BIND = 'AetherTribesAimbot'

	local overlay = Instance.new('ScreenGui')
	overlay.Name = 'AetherAimbotFov'
	overlay.IgnoreGuiInset = true
	overlay.ResetOnSpawn = false
	overlay.DisplayOrder = 501
	overlay:SetAttribute('ElevateV4', true)
	overlay.Parent = lplr.PlayerGui
	vape:Clean(overlay)
	local circle = Instance.new('Frame')
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.BackgroundTransparency = 1
	circle.Visible = false
	circle.Parent = overlay
	Instance.new('UICorner', circle).CornerRadius = UDim.new(1, 0)
	Instance.new('UIStroke', circle).Color = Color3.new(1, 1, 1)

	local function eligible(model, root, center)
		if not gameapi.Enemy(model, Targets) then return nil end
		local head = model:FindFirstChild('Head')
		if not (head and head:IsA('BasePart')) or (head.Position - root.Position).Magnitude > Range.Value then return nil end
		local screen, visible = gameCamera:WorldToViewportPoint(head.Position)
		if not visible or screen.Z <= 0 then return nil end
		local pixels = (Vector2.new(screen.X, screen.Y) - center).Magnitude
		if pixels > Fov.Value then return nil end
		if Targets.Walls.Enabled and not gameapi.Clear(gameCamera.CFrame.Position, head.Position, model) then return nil end
		return head, pixels
	end

	local function releaseLook()
		if lookLocked then
			pcall(cameraApi.PopLookLock, BIND)
			lookLocked = false
		end
	end

	local function update(dt)
		local center = inputService.MouseBehavior == Enum.MouseBehavior.LockCenter and gameCamera.ViewportSize * 0.5 or gameapi.Cursor()
		circle.Visible = ShowFov.Enabled
		circle.Position = UDim2.fromOffset(center.X, center.Y)
		circle.Size = UDim2.fromOffset(Fov.Value * 2, Fov.Value * 2)
		local root = entitylib.isAlive and entitylib.character.RootPart
		local tool, _, kind, tuning = gameapi.Tool()
		local allowed = kind and ((Melee.Enabled and combat.IsMelee(kind)) or (Projectiles.Enabled and combat.FiresProjectile(kind)))
		if gameapi.Options.AutoKilling or not root or not allowed then
			locked = nil
			releaseLook()
			return
		end

		local head
		if PriorityMode.Enabled and locked then
			head = eligible(locked, root, center)
		end
		if not head then
			locked = nil
			local closest = Fov.Value
			for _, model in util.Targets() do
				local part, pixels = eligible(model, root, center)
				if part and pixels < closest then
					closest, locked, head = pixels, model, part
				end
			end
		end
		if not head then
			releaseLook()
			return
		end
		if not lookLocked then
			pcall(cameraApi.PushLookLock, BIND)
			lookLocked = true
		end
		local ent = entitylib.getEntity(locked)
		if ent then
			targetinfo.Targets[ent] = tick() + 1
		end

		local current = gameCamera.CFrame
		local aimPoint = head.Position
		if tool and combat.FiresProjectile(kind) then
			local origin = util.ShotOrigin(tool, 'Muzzle')
			local shot = gameapi.ShotProfile(tool, kind, tuning)
			local predicted = typeof(origin) == 'Vector3' and shot and gameapi.Aim(origin, head, shot.speed, shot.gravity, false)
			if predicted then
				aimPoint = origin + predicted * (head.Position - origin).Magnitude
			end
		end
		if (aimPoint - current.Position).Magnitude < 0.01 then return end
		local alpha = 1 - math.exp(-AimSpeed.Value * math.clamp(dt, 0, 0.1) * 4.5)
		local result = current:Lerp(CFrame.lookAt(current.Position, aimPoint), alpha)
		gameCamera.CFrame = result
		local direction = result.LookVector
		pcall(cameraApi.SetLook, math.atan2(-direction.X, -direction.Z), math.asin(math.clamp(direction.Y, -1, 1)))
	end

	Aimbot = vape.Categories.Combat:CreateModule({
		Name = 'Aimbot',
		Function = function(callback)
			runService:UnbindFromRenderStep(BIND)
			locked = nil
			releaseLook()
			circle.Visible = false
			if callback then
				if not cameraApi then
					notif('Aimbot', 'The game camera was not found.', 5, 'warning')
					return
				end
				runService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 2, update)
				Aimbot:Clean(function()
					runService:UnbindFromRenderStep(BIND)
					releaseLook()
					circle.Visible = false
				end)
			end
		end,
		Tooltip = 'Turns your aim onto enemy heads near the crosshair'
	})
	Targets = Aimbot:CreateTargets({
		Players = true,
		NPCs = true,
		Walls = true
	})
	Range = Aimbot:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 150,
		Default = 100,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Fov = Aimbot:CreateSlider({
		Name = 'FOV',
		Min = 10,
		Max = 500,
		Default = 120,
		Suffix = 'px'
	})
	AimSpeed = Aimbot:CreateSlider({
		Name = 'Aim speed',
		Min = 1,
		Max = 20,
		Default = 8
	})
	ShowFov = Aimbot:CreateToggle({
		Name = 'Show FOV',
		Default = true
	})
	PriorityMode = Aimbot:CreateToggle({
		Name = 'Priority mode',
		Function = function()
			locked = nil
		end,
		Tooltip = 'Stays on one enemy until they die or leave the circle'
	})
	Melee = Aimbot:CreateToggle({
		Name = 'Melee',
		Default = true
	})
	Projectiles = Aimbot:CreateToggle({
		Name = 'Projectiles',
		Default = true
	})
end)
