run(function()
	local CoreGui = cloneref(game:GetService('CoreGui'))
	local LocalPlayer = lplr
	local Players = playersService
	local NickHider
	local Replacement
	local ChatTags
	local Level
	local HideOthers
	local Swapped: {[Instance]: string} = setmetatable({}, {__mode = "k"})
	local Watched: {[Instance]: RBXScriptConnection} = setmetatable({}, {__mode = "k"})
	local Patterns: {string} = {}
	local Plain: {string} = {}
	local Shortest: number = math.huge
	local TextClasses: {[string]: boolean} = {TextLabel = true, TextButton = true, TextBox = true}
	local FakeName: string = "hidden"
	local Writing: Instance?
	local OldUsername, OldDisplayName, OldClanTag, OldLevel

	local Refreshing: boolean = false

	local function QueueRefresh()
		if Refreshing or not NickHider or not NickHider.Enabled then
			return
		end
		Refreshing = true

		task.delay(0.35, function()
			Refreshing = false
			if NickHider.Enabled then
				NickHider:Toggle()
				NickHider:Toggle()
			end
		end)
	end

	local function ShouldHidePlayer(Player: Player?)
		return Player and (Player.UserId == LocalPlayer.UserId or HideOthers.Enabled)
	end

	local function AddPlayerNames(Player: Player)
		for _, v: string in {Player.Name, Player.DisplayName} do
			if v ~= "" then
				local LowerName: string = v:lower()
				if not table.find(Plain, LowerName) then
					table.insert(Plain, LowerName)
					Shortest = math.min(Shortest, #LowerName)
				end
			end
			for _, Variant: string in {v, v:lower(), v:upper()} do
				local Pattern: string = (Variant:gsub("%W", "%%%0"))
				if Variant ~= "" and not table.find(Patterns, Pattern) then
					table.insert(Patterns, Pattern)
				end
			end
		end
	end

	local function IsLocal(GamePlayer): boolean
		local Player: Player? = GamePlayer:getPlayer()
		return Player ~= nil and Player.UserId == LocalPlayer.UserId
	end

	local function GetGamePlayerClass()
		local GamePlayer = bedwars.GamePlayerUtil and bedwars.GamePlayerUtil.getGamePlayer(LocalPlayer)
		local Meta = GamePlayer and getmetatable(GamePlayer)
		return Meta and Meta.__index
	end

	local function HasPlayerName(Object: Instance)
		local Ancestor: Instance? = Object.Parent
		for _ = 1, 3 do
			if not Ancestor then
				return nil
			end
			local Label = Ancestor:FindFirstChild("PlayerName", true)
			if Label then
				return Label
			end
			Ancestor = Ancestor.Parent
		end
		return nil
	end

	local function HideLevelObject(Object: Instance)
		if not (Level.Enabled or HideOthers.Enabled) or not TextClasses[Object.ClassName] then
			return
		end
		if not Object.Name:lower():find("level", 1, true) then
			return
		end
		local PlayerName = HasPlayerName(Object)
		if not PlayerName or (not HideOthers.Enabled and not PlayerName.Text:find(FakeName, 1, true)) then
			return
		end

		local function Apply()
			if Writing == Object or not Object.Parent then
				return
			end
			local Text = Object.Text
			if type(Text) ~= "string" or Text == "" then
				return
			end

			Swapped[Object] = Swapped[Object] or Text
			Writing = Object
			Object.Text = ""
			Writing = nil
		end

		Apply()
		if not Watched[Object] then
			Watched[Object] = Object:GetPropertyChangedSignal("Text"):Connect(Apply)
		end
	end

	local function HideLevelSiblings(Object: Instance?)
		if not Object then
			return
		end
		for _, v: Instance in Object:GetDescendants() do
			HideLevelObject(v)
		end
	end

	local function ReplaceText(Object: Instance)
		if Writing == Object then
			return
		end

		local Text = Object.Text
		if type(Text) ~= "string" or #Text < Shortest then
			return
		end

		local Hit: boolean = false
		for _, v: string in Plain do
			if Text:find(v, 1, true) then
				Hit = true
				break
			end
		end
		if not Hit then
			local LowerText: string = Text:lower()
			for _, v: string in Plain do
				if LowerText:find(v, 1, true) then
					Hit = true
					break
				end
			end
		end
		if not Hit then
			return
		end

		local NewText: string = Text
		for _, v: string in Patterns do
			if NewText:find(v) then
				NewText = NewText:gsub(v, FakeName)
			end
		end
		if NewText == Text then
			return
		end

		Swapped[Object] = Text
		Object:SetAttribute("NickHiderOriginalText", Text)
		Writing = Object
		Object.Text = NewText
		Writing = nil
		HideLevelSiblings(Object.Parent)

		if not Watched[Object] then
			Watched[Object] = Object:GetPropertyChangedSignal("Text"):Connect(function()
				ReplaceText(Object)
			end)
		end
	end

	local function HideObject(Object: Instance)
		if TextClasses[Object.ClassName] then
			ReplaceText(Object)
		end
	end

	local function Watch(Root: Instance?)
		if not Root then
			return
		end

		if vape.ThreadFix then
			setthreadidentity(8)
		end
		NickHider:Clean(Root.DescendantAdded:Connect(function(Object: Instance)
			if NickHider.Enabled then
				HideObject(Object)
				HideLevelObject(Object)
			end
		end))

		local Clock: number = os.clock()
		for _, v: Instance in Root:GetDescendants() do
			HideObject(v)
			HideLevelObject(v)

			if os.clock() - Clock > 0.002 then
				task.wait()
				if not NickHider.Enabled then
					return
				end
				Clock = os.clock()

				if vape.ThreadFix then
					setthreadidentity(8)
				end
			end
		end
	end

	NickHider = vape.Categories.Utility:CreateModule({
		Name = "NickHider",
		ConfigName = "NameHider",
		Function = function(Callback: boolean)
			if Callback then
				table.clear(Patterns)
				table.clear(Plain)
				Shortest = math.huge
				for _, v: Player in Players:GetPlayers() do
					if v == LocalPlayer or HideOthers.Enabled then
						AddPlayerNames(v)
					end
				end

				FakeName = Replacement.Value ~= "" and Replacement.Value or "hidden"
				for _, v: string in Patterns do
					if FakeName:find(v) then
						FakeName = "hidden"
						break
					end
				end

				local GamePlayer = GetGamePlayerClass()
				if GamePlayer and not OldUsername then
					OldUsername, OldDisplayName = GamePlayer.getUsername, GamePlayer.getDisplayName
					OldClanTag, OldLevel = GamePlayer.getClanTag, GamePlayer.getLevel
					GamePlayer.getUsername = function(self, ...)
						local Player: Player? = self:getPlayer()
						return ShouldHidePlayer(Player) and FakeName or OldUsername(self, ...)
					end
					GamePlayer.getDisplayName = function(self, ...)
						local Player: Player? = self:getPlayer()
						return ShouldHidePlayer(Player) and FakeName or OldDisplayName(self, ...)
					end
					GamePlayer.getClanTag = function(self, ...)
						return IsLocal(self) and ChatTags.Enabled and "" or OldClanTag(self, ...)
					end
					GamePlayer.getLevel = function(self, ...)
						local Player: Player? = self:getPlayer()
						if Player and (HideOthers.Enabled or (Player.UserId == LocalPlayer.UserId and Level.Enabled)) then
							return -1
						end
						return OldLevel(self, ...)
					end
				end

				for _, v: Instance? in {LocalPlayer:FindFirstChildOfClass("PlayerGui"), CoreGui, gethui and gethui() or nil, LocalPlayer.Character} do
					Watch(v)
				end

				NickHider:Clean(LocalPlayer.CharacterAdded:Connect(function(Character: Model)
					if NickHider.Enabled then
						Watch(Character)
					end
				end))
				NickHider:Clean(Players.PlayerAdded:Connect(function()
					if HideOthers.Enabled then
						QueueRefresh()
					end
				end))
				NickHider:Clean(Players.PlayerRemoving:Connect(function()
					if HideOthers.Enabled then
						QueueRefresh()
					end
				end))
			else
				local GamePlayer = GetGamePlayerClass()
				if OldUsername and GamePlayer then
					GamePlayer.getUsername, GamePlayer.getDisplayName = OldUsername, OldDisplayName
					GamePlayer.getClanTag, GamePlayer.getLevel = OldClanTag, OldLevel
					OldUsername, OldDisplayName, OldClanTag, OldLevel = nil, nil, nil, nil
				end
				if vape.ThreadFix then
					setthreadidentity(8)
				end

				for _, v: RBXScriptConnection in Watched do
					v:Disconnect()
				end
				table.clear(Watched)

				for Object: Instance, v: string in Swapped do
					if Object.Parent then
						Writing = Object
						Object.Text = v
						Object:SetAttribute("NickHiderOriginalText", nil)
					end
				end
				Writing = nil
				table.clear(Swapped)
			end
		end,
		Tooltip = 'Replaces your name everywhere on your screen',
		ExtraText = function()
			return Replacement.Value ~= "" and Replacement.Value or "hidden"
		end
	})

	Replacement = NickHider:CreateTextBox({
		Name = "Name",
		Function = QueueRefresh,
		Default = "hidden"
	})
	local Hide = NickHider:CreateMultiDropdown({
		Name = "Hide",
		List = {"Others", "Chat tags", "Level"},
		Default = {},
		Function = QueueRefresh,
		Tooltip = 'What to hide on your screen'
	})
	local function flag(name)
		return setmetatable({}, {__index = function(_, key)
			if key == "Enabled" then
				return Hide:Has(name)
			end
		end})
	end
	HideOthers, ChatTags, Level = flag("Others"), flag("Chat tags"), flag("Level")
end)
