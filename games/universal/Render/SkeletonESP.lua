run(function()
	local SkeletonESP
	local Targets
	local Color
	local TeamColor
	local Thickness
	local Transparency
	local DistanceLimit
	local PriorityOnly
	local Reference = {}

	local R15 = {
		{'Head', 'UpperTorso'}, {'UpperTorso', 'LowerTorso'},
		{'UpperTorso', 'LeftUpperArm'}, {'LeftUpperArm', 'LeftLowerArm'}, {'LeftLowerArm', 'LeftHand'},
		{'UpperTorso', 'RightUpperArm'}, {'RightUpperArm', 'RightLowerArm'}, {'RightLowerArm', 'RightHand'},
		{'LowerTorso', 'LeftUpperLeg'}, {'LeftUpperLeg', 'LeftLowerLeg'}, {'LeftLowerLeg', 'LeftFoot'},
		{'LowerTorso', 'RightUpperLeg'}, {'RightUpperLeg', 'RightLowerLeg'}, {'RightLowerLeg', 'RightFoot'}
	}
	local R6 = {
		{'Head', Vector3.zero, 'Torso', Vector3.new(0, 1, 0)},
		{'Torso', Vector3.new(0, 1, 0), 'Torso', Vector3.new(0, -1, 0)},
		{'Torso', Vector3.new(-1, 1, 0), 'Left Arm', Vector3.new(0, -1, 0)},
		{'Torso', Vector3.new(1, 1, 0), 'Right Arm', Vector3.new(0, -1, 0)},
		{'Torso', Vector3.new(-0.5, -1, 0), 'Left Leg', Vector3.new(0, -1, 0)},
		{'Torso', Vector3.new(0.5, -1, 0), 'Right Leg', Vector3.new(0, -1, 0)}
	}

	local function lineColor(ent)
		if TeamColor.Enabled and ent.Player and ent.Player.Team then
			return ent.Player.TeamColor.Color
		end
		return entitylib.getEntityColor(ent) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
	end

	local function Removed(ent)
		local data = Reference[ent]
		if not data then return end
		Reference[ent] = nil
		if vape.ThreadFix then
			setthreadidentity(8)
		end
		for _, line in data.Lines do
			pcall(function()
				line.Visible = false
				line:Remove()
			end)
		end
	end

	local function Added(ent)
		if not Targets.Players.Enabled and ent.Player then return end
		if not Targets.NPCs.Enabled and ent.NPC then return end
		if PriorityOnly.Enabled and not ent.Targetable and not ent.Friend then return end
		if vape.ThreadFix then
			setthreadidentity(8)
		end
		local rig = ent.Humanoid and ent.Humanoid.RigType == Enum.HumanoidRigType.R6 and R6 or R15
		local data = {Rig = rig, Lines = {}, Parts = {}, Shown = false}
		local colour = lineColor(ent)
		for i = 1, #rig do
			local line = Drawing.new('Line')
			line.Thickness = Thickness.Value
			line.Transparency = 1 - Transparency.Value
			line.Color = colour
			line.Visible = false
			data.Lines[i] = line
		end
		Reference[ent] = data
	end

	local function part(ent, data, name)
		local cached = data.Parts[name]
		if cached and cached.Parent then
			return cached
		end
		cached = ent.Character and ent.Character:FindFirstChild(name)
		data.Parts[name] = cached
		return cached
	end

	local function hide(data)
		if data.Shown then
			data.Shown = false
			for _, line in data.Lines do
				line.Visible = false
			end
		end
	end

	local function Loop()
		local origin = entitylib.isAlive and entitylib.character.RootPart.Position
		local limit = DistanceLimit.Value
		for ent, data in Reference do
			local root = ent.RootPart
			if not root or not root.Parent or (limit > 0 and origin and (root.Position - origin).Magnitude > limit) then
				hide(data)
				continue
			end
			local _, onScreen = gameCamera:WorldToViewportPoint(root.Position)
			if not onScreen then
				hide(data)
				continue
			end
			data.Shown = true
			local rig = data.Rig
			for i, bone in rig do
				local line = data.Lines[i]
				local a, b, fromPos, toPos
				if rig == R6 then
					a, b = part(ent, data, bone[1]), part(ent, data, bone[3])
					fromPos = a and (a.CFrame * bone[2])
					toPos = b and (b.CFrame * bone[4])
				else
					a, b = part(ent, data, bone[1]), part(ent, data, bone[2])
					fromPos, toPos = a and a.Position, b and b.Position
				end
				if fromPos and toPos then
					local p1, v1 = gameCamera:WorldToViewportPoint(fromPos)
					local p2, v2 = gameCamera:WorldToViewportPoint(toPos)
					if v1 or v2 then
						line.From = Vector2.new(p1.X, p1.Y)
						line.To = Vector2.new(p2.X, p2.Y)
						if not line.Visible then line.Visible = true end
						continue
					end
				end
				if line.Visible then line.Visible = false end
			end
		end
	end

	local function restyle()
		for ent, data in Reference do
			local colour = lineColor(ent)
			for _, line in data.Lines do
				line.Color = colour
				line.Thickness = Thickness.Value
				line.Transparency = 1 - Transparency.Value
			end
		end
	end

	local function restart()
		if SkeletonESP.Enabled then
			SkeletonESP:Toggle()
			SkeletonESP:Toggle()
		end
	end

	SkeletonESP = vape.Categories.Render:CreateModule({
		Name = 'SkeletonESP',
		Function = function(callback)
			if callback then
				for _, v in entitylib.List do
					Added(v)
				end
				SkeletonESP:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
					Removed(ent)
					Added(ent)
				end))
				SkeletonESP:Clean(entitylib.Events.EntityRemoved:Connect(Removed))
				SkeletonESP:Clean(vape.Categories.Friends.ColorUpdate.Event:Connect(restyle))
				SkeletonESP:Clean(runService.RenderStepped:Connect(Loop))
			else
				for ent in Reference do
					Removed(ent)
				end
			end
		end,
		Tooltip = 'Shows player skeletons through walls'
	})
	Targets = SkeletonESP:CreateTargets({
		Players = true,
		Function = restart
	})
	Color = SkeletonESP:CreateColorSlider({
		Name = 'Colour',
		Function = function()
			if SkeletonESP.Enabled then restyle() end
		end
	})
	TeamColor = SkeletonESP:CreateToggle({
		Name = 'Team colour',
		Tooltip = 'Uses each player\'s team colour instead of the colour above',
		Function = function()
			if SkeletonESP.Enabled then restyle() end
		end
	})
	Thickness = SkeletonESP:CreateSlider({
		Name = 'Thickness',
		Min = 1,
		Max = 5,
		Default = 1.5,
		Decimal = 10,
		Function = function()
			if SkeletonESP.Enabled then restyle() end
		end
	})
	Transparency = SkeletonESP:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Function = function()
			if SkeletonESP.Enabled then restyle() end
		end
	})
	DistanceLimit = SkeletonESP:CreateSlider({
		Name = 'Distance limit',
		Min = 0,
		Max = 1000,
		Default = 0,
		Suffix = function(val)
			return val == 0 and 'off' or 'studs'
		end,
		Tooltip = 'Hides skeletons further away than this'
	})
	PriorityOnly = SkeletonESP:CreateToggle({
		Name = 'Priority Only',
		Function = restart,
		Tooltip = 'Hides teammates and anyone you cannot target'
	})
end)
