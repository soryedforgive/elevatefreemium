run(function()
	local NameTags
	local Targets
	local Color
	local Background
	local Stroke
	local DisplayName
	local Health
	local Distance
	local Equipment
	local DrawingToggle
	local Scale
	local FontOption
	local Teammates
	local DistanceCheck
	local DistanceLimit
	local getfontsize = vape.Libraries.getfontsize
	local Strings, Sizes, Reference = {}, {}, {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	vape:Clean(Folder)
	local methodused
	local weaponIcon, weaponRedraw

	local function removeTags(str)
		str = str:gsub('<br%s*/>', '\n')
		return (str:gsub('<[^<>]->', ''))
	end

	local function iconDrawer()
		if weaponIcon then return weaponIcon, weaponRedraw end
		pcall(function()
			local module = lplr.PlayerScripts.UI.WeaponIcon
			if getloadedmodules and not table.find(getloadedmodules(), module) then return end
			local init = require(module).Init
			weaponIcon = debug.getupvalue(init, 5)
			weaponRedraw = debug.getupvalue(debug.getupvalue(weaponIcon, 3), 8)
		end)
		return weaponIcon, weaponRedraw
	end

	local function getInventory(entity, match)
		local id = type(entity) == 'string' and entity or entity.Character:GetAttribute('CombatantId')
		match = match or (tribes.UIState and tribes.UIState.Match)
		if not (match and match.teams) then return nil end
		for _, team in match.teams do
			for _, member in team.members do
				if member.id == id and member.loadout then
					local items = table.clone(member.loadout.items or {})
					if member.loadout.armor then
						table.insert(items, 1, member.loadout.armor)
					end
					return items
				end
			end
		end
	end

	local function sameList(a, b)
		if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
		if #a ~= #b then return false end
		for i = 1, #a do
			if a[i] ~= b[i] then return false end
		end
		return true
	end

	local function nameOf(entity, rich)
		local text = entity.Player and whitelist:tag(entity.Player, true, rich)..(DisplayName.Enabled and entity.Player.DisplayName or entity.Player.Name) or entity.Character.Name
		if Health.Enabled then
			if rich then
				local healthColor = Color3.fromHSV(math.clamp(entity.Health / entity.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
				text ..= ' <font color="#'..healthColor:ToHex()..'">'..math.round(entity.Health)..'</font>'
			else
				text ..= ' '..math.round(entity.Health)
			end
		end
		if Distance.Enabled then
			text = (rich and '<font color="#55ff55">[</font><font color="#ffffff">%s</font><font color="#55ff55">]</font> ' or '[%s] ')..text
		end
		return text
	end

	local function skip(entity)
		if not Targets.Players.Enabled and entity.Player then return true end
		if not Targets.NPCs.Enabled and entity.NPC then return true end
		return Teammates.Enabled and not entity.Targetable and not entity.Friend
	end

	local Added = {
		Normal = function(entity)
			if skip(entity) then return end
			if vape.ThreadFix then
				setthreadidentity(8)
			end
			Strings[entity] = nameOf(entity, true)
			local nametag = Instance.new('TextLabel')
			nametag.TextSize = 14 * Scale.Value
			nametag.FontFace = FontOption.Value
			local size = getfontsize(removeTags(Strings[entity]), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
			nametag.Name = entity.Player and entity.Player.Name or entity.Character.Name
			nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
			nametag.AnchorPoint = Vector2.new(0.5, 1)
			nametag.BackgroundColor3 = Color3.new()
			nametag.BackgroundTransparency = Background.Value
			nametag.TextStrokeTransparency = Stroke.Value
			nametag.BorderSizePixel = 0
			nametag.Visible = false
			nametag.Text = Strings[entity]
			nametag.TextColor3 = entitylib.getEntityColor(entity) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			nametag.RichText = true
			nametag.Parent = Folder

			local inv = Equipment.Enabled and getInventory(entity)
			local drawer, redraw = iconDrawer()
			if inv and drawer and redraw then
				pcall(function()
					local old = debug.getupvalue(redraw, 1)
					debug.setupvalue(redraw, 1, {})
					local holder = Instance.new('Frame')
					holder.AnchorPoint = Vector2.new(0.5, 0)
					holder.BackgroundTransparency = 1
					holder.Position = UDim2.fromScale(0.5, 0)
					holder.Size = UDim2.fromOffset(#inv * 30, 0)
					holder.Parent = nametag
					for i, item in inv do
						local icon = Instance.new('Frame')
						icon.BackgroundTransparency = 1
						icon.Position = UDim2.fromOffset(-30 + i * 30, -30)
						icon.Size = UDim2.fromOffset(30, 30)
						icon.Parent = workspace
						drawer(icon, {id = item, opts = {glow = false, outline = false}})
						task.defer(function()
							icon.Parent = holder
						end)
					end
					debug.setupvalue(redraw, 1, old)
				end)
				if vape.ThreadFix then
					setthreadidentity(8)
				end
			end
			Reference[entity] = nametag
		end,
		Drawing = function(entity)
			if skip(entity) then return end
			local nametag = {}
			nametag.BG = Drawing.new('Square')
			nametag.BG.Filled = true
			nametag.BG.Transparency = 1 - Background.Value
			nametag.BG.Color = Color3.new()
			nametag.BG.ZIndex = 1
			nametag.Text = Drawing.new('Text')
			nametag.Text.Size = 15 * Scale.Value
			nametag.Text.Font = 0
			nametag.Text.ZIndex = 2
			Strings[entity] = nameOf(entity, false)
			nametag.Text.Text = Strings[entity]
			nametag.Text.Color = entitylib.getEntityColor(entity) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
			Reference[entity] = nametag
		end
	}

	local Removed = {
		Normal = function(entity)
			local v = Reference[entity]
			if v then
				Reference[entity], Strings[entity], Sizes[entity] = nil, nil, nil
				v:Destroy()
			end
		end,
		Drawing = function(entity)
			local v = Reference[entity]
			if v then
				Reference[entity], Strings[entity], Sizes[entity] = nil, nil, nil
				for _, obj in v do
					pcall(function()
						obj.Visible = false
						obj:Remove()
					end)
				end
			end
		end
	}

	local Updated = {
		Normal = function(entity)
			local nametag = Reference[entity]
			if not nametag then return end
			Sizes[entity] = nil
			Strings[entity] = nameOf(entity, true)
			local size = getfontsize(removeTags(Strings[entity]), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
			nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
			nametag.Text = Strings[entity]
		end,
		Drawing = function(entity)
			local nametag = Reference[entity]
			if not nametag then return end
			Sizes[entity] = nil
			Strings[entity] = nameOf(entity, false)
			nametag.Text.Text = Distance.Enabled and entitylib.isAlive and string.format(Strings[entity], math.floor((entitylib.character.RootPart.Position - entity.RootPart.Position).Magnitude)) or Strings[entity]
			nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
			nametag.Text.Color = entitylib.getEntityColor(entity) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		end
	}

	local ColorFunc = {
		Normal = function(hue, sat, val)
			local color = Color3.fromHSV(hue, sat, val)
			for entity, v in Reference do
				v.TextColor3 = entitylib.getEntityColor(entity) or color
			end
		end,
		Drawing = function(hue, sat, val)
			local color = Color3.fromHSV(hue, sat, val)
			for entity, v in Reference do
				v.Text.Color = entitylib.getEntityColor(entity) or color
			end
		end
	}

	local function outOfRange(entity)
		if not DistanceCheck.Enabled then return false end
		local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - entity.RootPart.Position).Magnitude or math.huge
		return distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax
	end

	local Loop = {
		Normal = function()
			for entity, nametag in Reference do
				local headPos, headVis = gameCamera:WorldToViewportPoint(entity.RootPart.Position + Vector3.new(0, entity.HipHeight + 1, 0))
				headVis = headVis and not outOfRange(entity)
				if nametag.Visible ~= headVis then
					nametag.Visible = headVis
				end
				if headVis then
					if Distance.Enabled then
						local mag = entitylib.isAlive and math.floor((entitylib.character.RootPart.Position - entity.RootPart.Position).Magnitude) or 0
						if Sizes[entity] ~= mag then
							nametag.Text = string.format(Strings[entity], mag)
							local size = getfontsize(removeTags(nametag.Text), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
							nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
							Sizes[entity] = mag
						end
					end
					nametag.Position = UDim2.fromOffset(headPos.X, headPos.Y)
				end
			end
		end,
		Drawing = function()
			for entity, nametag in Reference do
				local headPos, headVis = gameCamera:WorldToViewportPoint(entity.RootPart.Position + Vector3.new(0, entity.HipHeight + 1, 0))
				headVis = headVis and not outOfRange(entity)
				nametag.Text.Visible = headVis
				nametag.BG.Visible = headVis
				if headVis then
					if Distance.Enabled then
						local mag = entitylib.isAlive and math.floor((entitylib.character.RootPart.Position - entity.RootPart.Position).Magnitude) or 0
						if Sizes[entity] ~= mag then
							nametag.Text.Text = string.format(Strings[entity], mag)
							nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
							Sizes[entity] = mag
						end
					end
					nametag.BG.Position = Vector2.new(headPos.X - nametag.BG.Size.X / 2, headPos.Y - nametag.BG.Size.Y)
					nametag.Text.Position = nametag.BG.Position + Vector2.new(4, 3)
				end
			end
		end
	}

	local function rebuild()
		if NameTags.Enabled then
			NameTags:Toggle()
			NameTags:Toggle()
		end
	end

	NameTags = vape.Categories.Render:CreateModule({
		Name = 'NameTags',
		Function = function(callback)
			if callback then
				methodused = DrawingToggle.Enabled and 'Drawing' or 'Normal'
				NameTags:Clean(entitylib.Events.EntityRemoved:Connect(Removed[methodused]))
				local function add(entity)
					if Reference[entity] then
						Removed[methodused](entity)
					end
					Added[methodused](entity)
				end
				for _, entity in entitylib.List do
					add(entity)
				end
				NameTags:Clean(entitylib.Events.EntityAdded:Connect(add))

				local remote = Equipment.Enabled and replicatedStorage:FindFirstChild('Remotes') and replicatedStorage.Remotes:FindFirstChild('MatchState')
				if remote then
					local match = tribes.UIState and tribes.UIState.Match
					NameTags:Clean(remote.OnClientEvent:Connect(function(newMatch)
						if match and match.teams then
							for _, team in match.teams do
								for _, member in team.members do
									if not sameList(getInventory(member.id, match), getInventory(member.id, newMatch)) then
										for _, entity in entitylib.List do
											if entity.Character:GetAttribute('CombatantId') == member.id then
												add(entity)
												break
											end
										end
									end
								end
							end
						end
						match = newMatch
					end))
				end

				NameTags:Clean(entitylib.Events.EntityUpdated:Connect(Updated[methodused]))
				for _, entity in entitylib.List do
					Updated[methodused](entity)
				end
				NameTags:Clean(vape.Categories.Friends.ColorUpdate.Event:Connect(function()
					ColorFunc[methodused](Color.Hue, Color.Sat, Color.Value)
				end))
				NameTags:Clean(runService.RenderStepped:Connect(Loop[methodused]))
			elseif methodused then
				for entity in table.clone(Reference) do
					Removed[methodused](entity)
				end
			end
		end,
		Tooltip = 'Shows nametags through walls, with each player\'s loadout'
	})
	Targets = NameTags:CreateTargets({
		Players = true,
		Function = rebuild
	})
	FontOption = NameTags:CreateFont({
		Name = 'Font',
		Blacklist = 'Arial',
		Function = rebuild
	})
	Color = NameTags:CreateColorSlider({
		Name = 'Player Color',
		Function = function(hue, sat, val)
			if NameTags.Enabled and ColorFunc[methodused] then
				ColorFunc[methodused](hue, sat, val)
			end
		end
	})
	Scale = NameTags:CreateSlider({
		Name = 'Scale',
		Function = rebuild,
		Default = 1,
		Min = 0.1,
		Max = 1.5,
		Decimal = 10
	})
	Background = NameTags:CreateSlider({
		Name = 'Transparency',
		Function = rebuild,
		Default = 0.5,
		Min = 0,
		Max = 1,
		Decimal = 10
	})
	Stroke = NameTags:CreateSlider({
		Name = 'Stroke Transparency',
		Function = rebuild,
		Default = 1,
		Min = 0,
		Max = 1,
		Decimal = 10
	})
	Health = NameTags:CreateToggle({
		Name = 'Health',
		Function = rebuild
	})
	Distance = NameTags:CreateToggle({
		Name = 'Distance',
		Function = rebuild
	})
	Equipment = NameTags:CreateToggle({
		Name = 'Equipment',
		Function = rebuild,
		Tooltip = 'Shows the armour and weapons each player brought to the match'
	})
	DisplayName = NameTags:CreateToggle({
		Name = 'Use Displayname',
		Function = rebuild,
		Default = true
	})
	Teammates = NameTags:CreateToggle({
		Name = 'Priority Only',
		Function = rebuild,
		Default = true,
		Tooltip = 'Hides teammates and anyone you cannot target'
	})
	DrawingToggle = NameTags:CreateToggle({
		Name = 'Drawing',
		Function = rebuild
	})
	DistanceCheck = NameTags:CreateGroup({
		Name = 'Distance Check',
	})
	DistanceLimit = DistanceCheck:CreateTwoSlider({
		Name = 'Player Distance',
		Min = 0,
		Max = 256,
		DefaultMin = 0,
		DefaultMax = 64,
		Darker = true
	})
end)
