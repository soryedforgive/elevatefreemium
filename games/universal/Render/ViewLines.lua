run(function()
	local ViewLines
	local Targets
	local Color
	local Transparency
	local Length
	local Thickness
	local Walls
	local StopAtWalls
	local Priority
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Name = 'AetherViewLines'
	Folder.Parent = vape.gui

	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	rayCheck.RespectCanCollide = true

	local function isValid(ent)
		if not (ent.Character and ent.Character.Parent and ent.Head and ent.Head.Parent) then return false end
		if ent.Player and ent.Player == lplr then return false end
		if ent.Player and not Targets.Players.Enabled then return false end
		if ent.NPC and not Targets.NPCs.Enabled then return false end
		if Priority.Enabled and not ent.Targetable and not ent.Friend then return false end
		return true
	end

	local function lineColor(ent)
		return entitylib.getEntityColor(ent) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
	end

	local function remove(ent)
		local line = Reference[ent]
		if not line then return end
		Reference[ent] = nil
		if vape.ThreadFix then
			setthreadidentity(8)
		end
		line:Destroy()
	end

	local function add(ent)
		remove(ent)
		if not isValid(ent) then return end
		if vape.ThreadFix then
			setthreadidentity(8)
		end

		local line = Instance.new('LineHandleAdornment')
		line.Name = 'ViewLine'
		line.Adornee = ent.Head
		line.CFrame = CFrame.new(0, 0, -ent.Head.Size.Z / 2)
		line.Length = Length.Value
		line.Thickness = Thickness.Value
		line.Color3 = lineColor(ent)
		line.Transparency = Transparency.Value
		line.AlwaysOnTop = Walls.Enabled
		line.ZIndex = 1
		line.Parent = Folder
		Reference[ent] = line
	end

	local function refresh()
		if not ViewLines.Enabled then return end
		for ent in Reference do
			remove(ent)
		end
		for _, ent in entitylib.List do
			add(ent)
		end
	end

	local trimCursor = 0
	local function trim()
		local list = entitylib.List
		local count = #list
		if count == 0 then return end
		for _ = 1, math.min(count, 6) do
			trimCursor = trimCursor % count + 1
			local ent = list[trimCursor]
			local line = ent and Reference[ent]
			local head = ent and ent.Head
			if line and head and head.Parent then
				local length = Length.Value
				rayCheck.FilterDescendantsInstances = {ent.Character, gameCamera}
				local origin = head.Position
				local hit = workspace:Raycast(origin, head.CFrame.LookVector * (length + head.Size.Z / 2), rayCheck)
				if hit then
					length = math.max((hit.Position - origin).Magnitude - head.Size.Z / 2, 0)
				end
				if math.abs(line.Length - length) > 0.05 then
					line.Length = length
				end
			end
		end
	end

	ViewLines = vape.Categories.Render:CreateModule({
		Name = 'ViewLines',
		Function = function(callback)
			if callback then
				ViewLines:Clean(entitylib.Events.EntityAdded:Connect(add))
				ViewLines:Clean(entitylib.Events.EntityRemoved:Connect(remove))
				ViewLines:Clean(vape.Categories.Friends.ColorUpdate.Event:Connect(function()
					for ent, line in Reference do
						line.Color3 = lineColor(ent)
					end
				end))
				for _, ent in entitylib.List do
					add(ent)
				end
				ViewLines:Clean(runService.Heartbeat:Connect(function()
					if StopAtWalls.Enabled then
						trim()
					end
				end))
			else
				for ent in Reference do
					remove(ent)
				end
			end
		end,
		Tooltip = 'Shows which way each player is facing'
	})

	Targets = ViewLines:CreateTargets({
		Players = true,
		Function = refresh
	})
	Priority = ViewLines:CreateToggle({
		Name = 'Priority Only',
		Default = true,
		Function = refresh,
		Tooltip = 'Hides teammates and anyone you cannot target'
	})
	Color = ViewLines:CreateColorSlider({
		Name = 'Colour',
		Function = function()
			for ent, line in Reference do
				line.Color3 = lineColor(ent)
			end
		end,
		Tooltip = 'Colour for players without a team or friend colour'
	})
	Transparency = ViewLines:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Default = 0.2,
		Decimal = 10,
		Function = function(value)
			for _, line in Reference do
				line.Transparency = value
			end
		end
	})
	Length = ViewLines:CreateSlider({
		Name = 'Length',
		Min = 5,
		Max = 200,
		Default = 30,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Function = function(value)
			for _, line in Reference do
				line.Length = value
			end
		end
	})
	Thickness = ViewLines:CreateSlider({
		Name = 'Thickness',
		Min = 1,
		Max = 10,
		Default = 3,
		Function = function(value)
			for _, line in Reference do
				line.Thickness = value
			end
		end
	})
	StopAtWalls = ViewLines:CreateToggle({
		Name = 'Stop at walls',
		Default = true,
		Function = function(callback)
			if not callback then
				for _, line in Reference do
					line.Length = Length.Value
				end
			end
		end,
		Tooltip = 'Ends each line at the first wall or player it runs into'
	})
	Walls = ViewLines:CreateToggle({
		Name = 'Render Walls',
		Default = true,
		Function = function(callback)
			for _, line in Reference do
				line.AlwaysOnTop = callback
			end
		end,
		Tooltip = 'Shows the lines through walls'
	})
end)
