run(function()
	local ClickTP
	local Mode
	local Key
	local Range
	local Speed
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	rayCheck.RespectCanCollide = true
	local overlapCheck = OverlapParams.new()
	overlapCheck.FilterType = Enum.RaycastFilterType.Exclude
	overlapCheck.RespectCanCollide = true
	local active

	local keys = {
		['Left Control'] = Enum.KeyCode.LeftControl,
		['Left Alt'] = Enum.KeyCode.LeftAlt,
		['Left Shift'] = Enum.KeyCode.LeftShift
	}

	local function stop()
		if active then
			active:Cancel()
			active = nil
		end
	end

	local function landing(hit, character)
		local root = character.RootPart
		local height = character.HipHeight or (root.Size.Y * 0.5 + 2)
		if hit.Normal.Y > 0.5 then
			return hit.Position + Vector3.new(0, height, 0)
		end
		local out = math.max(root.Size.X, root.Size.Z) * 0.5 + 0.5
		return hit.Position + hit.Normal * out + Vector3.new(0, hit.Normal.Y < -0.5 and -height or 0, 0)
	end

	local function fits(position, character)
		local root = character.RootPart
		overlapCheck.FilterDescendantsInstances = {character.Character, gameCamera}
		local size = Vector3.new(math.max(root.Size.X * 0.8, 1), math.max(root.Size.Y * 0.9, 1.5), math.max(root.Size.Z * 0.8, 1))
		for _, part in workspace:GetPartBoundsInBox(CFrame.new(position), size, overlapCheck) do
			if part.CanCollide then
				return false
			end
		end
		return true
	end

	local function teleport()
		if not entitylib.isAlive then return end
		local character = entitylib.character
		local root = character.RootPart
		if not isnetworkowner(root) then return end

		local mouse = inputService:GetMouseLocation()
		local ray = gameCamera:ViewportPointToRay(mouse.X, mouse.Y)
		rayCheck.FilterDescendantsInstances = {character.Character, gameCamera}
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 5000, rayCheck)
		if not hit then
			notif('ClickTP', 'Nothing to land on there.', 3, 'warning')
			return
		end

		local target = landing(hit, character)
		local distance = (target - root.Position).Magnitude
		if distance > Range.Value then
			notif('ClickTP', 'That is '..math.floor(distance)..' studs away, further than the '..Range.Value..' stud range.', 3, 'warning')
			return
		end
		if not fits(target, character) then
			target += Vector3.new(0, 1.5, 0)
			if not fits(target, character) then
				notif('ClickTP', 'There is no room to stand there.', 3, 'warning')
				return
			end
		end

		stop()
		local goal = CFrame.new(target) * root.CFrame.Rotation
		if Mode.Value == 'Tween' then
			local played = tweenService:Create(root, TweenInfo.new(math.max(distance / Speed.Value, 0.05), Enum.EasingStyle.Linear), {
				CFrame = goal
			})
			active = played
			played.Completed:Once(function()
				if active == played then
					active = nil
				end
				if root.Parent then
					root.AssemblyLinearVelocity = Vector3.zero
				end
			end)
			played:Play()
		else
			root.CFrame = goal
			root.AssemblyLinearVelocity = Vector3.zero
		end
	end

	ClickTP = vape.Categories.Blatant:CreateModule({
		Name = 'ClickTP',
		Function = function(callback)
			if callback then
				ClickTP:Clean(inputService.InputBegan:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
					local key = keys[Key.Value]
					if key and not inputService:IsKeyDown(key) then return end
					if not canClick() then return end
					teleport()
				end))
				ClickTP:Clean(stop)
			else
				stop()
			end
		end,
		ExtraText = function()
			return Mode.Value
		end,
		Tooltip = 'Teleports you to where you click'
	})
	Mode = ClickTP:CreateDropdown({
		Name = 'Mode',
		List = {'Instant', 'Tween'},
		Function = function(value)
			if Speed and Speed.Object then
				Speed.Object.Visible = value == 'Tween'
			end
		end,
		Tooltip = 'Instant - you are there on the same frame\nTween - glides you there at the chosen speed'
	})
	Speed = ClickTP:CreateSlider({
		Name = 'Tween speed',
		Min = 10,
		Max = 500,
		Default = 100,
		Darker = true,
		Visible = false,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How fast Tween mode moves you'
	})
	Key = ClickTP:CreateDropdown({
		Name = 'Hold key',
		List = {'Left Control', 'Left Alt', 'Left Shift', 'None'},
		Tooltip = 'Key to hold while you click'
	})
	Range = ClickTP:CreateSlider({
		Name = 'Range',
		Min = 10,
		Max = 1000,
		Default = 300,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'Clicks further away than this are ignored'
	})
end)
