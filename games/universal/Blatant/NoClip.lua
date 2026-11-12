run(function()
    local Mode
    local StudLimit = { Object = {} }
    local rayCheck = RaycastParams.new()
    rayCheck.RespectCanCollide = true
    local overlapCheck = OverlapParams.new()
    overlapCheck.MaxParts = 9e9
    local modified, fflag = {}
    local teleported
    local dirty, lastCharacter, lastCamera = true

    local function refreshFilter()
	if not (dirty or lastCharacter ~= lplr.Character or lastCamera ~= gameCamera) then return end
	dirty, lastCharacter, lastCamera = false, lplr.Character, gameCamera
	local chars = { gameCamera, lplr.Character }
	for _, v in entitylib.List do
		table.insert(chars, v.Character)
	end
	rayCheck.FilterDescendantsInstances = chars
	overlapCheck.FilterDescendantsInstances = chars
    end

    local function grabClosestNormal(ray)
	local partCF, mag, closest = ray.Instance.CFrame, 0, Enum.NormalId.Top
	for _, normal in Enum.NormalId:GetEnumItems() do
		local dot = partCF:VectorToWorldSpace(Vector3.fromNormalId(normal)):Dot(ray.Normal)
		if dot > mag then
			mag, closest = dot, normal
		end
	end
	return Vector3.fromNormalId(closest).X ~= 0 and 'X' or 'Z'
    end

    local characterParts = {List = {}}
    local Functions = {
	Part = function()
		refreshFilter()

		local parts = workspace:GetPartBoundsInBox(
			entitylib.character.RootPart.CFrame + Vector3.new(0, 1, 0),
			entitylib.character.RootPart.Size + Vector3.new(1, entitylib.character.HipHeight, 1),
			overlapCheck
		)
		for _, part in parts do
			if part.CanCollide and (not Spider.Enabled or SpiderShift) then
				modified[part] = true
				part.CanCollide = false
			end
		end

		for part in modified do
			if not table.find(parts, part) then
				modified[part] = nil
				part.CanCollide = true
			end
		end
	end,
	Character = function()
		local character = lplr.Character
		if characterParts.Owner ~= character or characterParts.Dirty then
			characterParts.Owner, characterParts.Dirty = character, false
			if characterParts.Added then characterParts.Added:Disconnect() end
			if characterParts.Removed then characterParts.Removed:Disconnect() end
			table.clear(characterParts.List)
			for _, part in character:GetDescendants() do
				if part:IsA('BasePart') then table.insert(characterParts.List, part) end
			end
			local function dirty() characterParts.Dirty = true end
			characterParts.Added = character.DescendantAdded:Connect(dirty)
			characterParts.Removed = character.DescendantRemoving:Connect(dirty)
		end
		for _, part in characterParts.List do
			if part.CanCollide and (not Spider.Enabled or SpiderShift) then
				modified[part] = true
				part.CanCollide = Spider.Enabled and not SpiderShift
			end
		end
	end,
	CFrame = function()
		refreshFilter()

		local ray = workspace:Raycast(
			entitylib.character.Head.CFrame.Position,
			entitylib.character.Humanoid.MoveDirection * 1.1,
			rayCheck
		)
		if ray and (not Spider.Enabled or SpiderShift) then
			local wallAxis = grabClosestNormal(ray)
			if ray.Instance.Size[wallAxis] <= StudLimit.Value then
				local root = entitylib.character.RootPart
				local dest = root.CFrame + (ray.Normal * (-ray.Instance.Size[wallAxis] - (root.Size.X / 1.5)))

				if #workspace:GetPartBoundsInBox(dest, Vector3.one, overlapCheck) <= 0 then
					if Mode.Value == 'Motor' then
						motorMove(root, dest)
					else
						root.CFrame = dest
					end
				end
			end
		end
	end,
	FFlag = function()
		if teleported or not setfflag then
			return
		end
		setfflag('AssemblyExtentsExpansionStudHundredth', '-10000')
		fflag = true
	end,
    }
    Functions.Motor = Functions.CFrame

    NoClip = vape.Categories.Blatant:CreateModule({
	Name = 'NoClip',
	Function = function(callback)
		if callback then
			dirty = true
			NoClip:Clean(entitylib.Events.EntityAdded:Connect(function() dirty = true end))
			NoClip:Clean(entitylib.Events.EntityRemoved:Connect(function() dirty = true end))
			NoClip:Clean(runService.Stepped:Connect(function()
				if entitylib.isAlive then
					Functions[Mode.Value]()
				end
			end))

			if Mode.Value == 'FFlag' then
				NoClip:Clean(lplr.OnTeleport:Connect(function()
					teleported = true
					if setfflag then setfflag('AssemblyExtentsExpansionStudHundredth', '30') end
				end))
			end
		else
			if fflag then
				setfflag('AssemblyExtentsExpansionStudHundredth', '30')
			end
			for part in modified do
				part.CanCollide = true
			end
			table.clear(modified)
			fflag = nil
			if characterParts.Added then characterParts.Added:Disconnect() end
			if characterParts.Removed then characterParts.Removed:Disconnect() end
			characterParts.Added, characterParts.Removed, characterParts.Owner = nil, nil, nil
			table.clear(characterParts.List)
		end
	end,
	Tooltip = 'Lets you walk through walls. Hold Shift to climb with Spider',
    })
    Mode = NoClip:CreateDropdown({
	Name = 'Mode',
	List = { 'Part', 'Character', 'CFrame', 'Motor', 'FFlag' },
	Function = function(val)
		StudLimit.Object.Visible = val == 'CFrame' or val == 'Motor'
		if fflag then
			setfflag('AssemblyExtentsExpansionStudHundredth', '30')
		end
		for part in modified do
			part.CanCollide = true
		end
		table.clear(modified)
		fflag = nil
	end,
	Tooltip = 'How it lets you through walls',
    })
    StudLimit = NoClip:CreateSlider({
	Name = 'Wall Size',
	Min = 1,
	Max = 20,
	Default = 5,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end,
	Darker = true,
	Visible = false,
    })
end)
