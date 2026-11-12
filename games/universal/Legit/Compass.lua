run(function()
	local UIPallet = vape.Libraries.uipallet
	local Camera = gameCamera
	local GetVapeAsset = getcustomasset
	local RunService = runService
	local Compass
	local Background
	local BackgroundColor
	local Slots = {}
	local Last = {}
	local Cardinals: {[number]: string} = {[0] = "N", [45] = "NE", [90] = "E", [135] = "SE", [180] = "S", [225] = "SW", [270] = "W", [315] = "NW"}
	local TickStep: number = (616 + 8) / 1400
	local DegreeStep: number = TickStep * 10
	local StripCentre: number = TickStep + 70 * DegreeStep
	local MajorSize: UDim2 = UDim2.fromOffset(2, 12)
	local MajorPosition: UDim2 = UDim2.fromOffset(0, 32)
	local MinorSize: UDim2 = UDim2.fromOffset(2, 4)
	local MinorPosition: UDim2 = UDim2.fromOffset(0, 36)
	local PlateColor: Color3 = Color3.fromRGB(230, 230, 230)
	local MutedColor: Color3 = Color3.fromRGB(163, 163, 163)
	local WhiteColor: Color3 = Color3.new(1, 1, 1)
	local Holder, Strip, HeadingLabel

	local function Update()
		if vape.ThreadFix then
			setthreadidentity(8)
		end

		local Look: Vector3 = Camera.CFrame.LookVector
		local Heading: number = math.deg(math.atan2(Look.X, -Look.Z)) % 360
		local Plain: boolean = not Background.Enabled
		if Heading == Last.heading and Plain == Last.plain then return end
		Last.heading = Heading
		local Index: number = 0
		local Degrees: number = math.floor(Heading)
		if Degrees ~= Last.degrees then
			Last.degrees = Degrees
			HeadingLabel.Text = tostring(Degrees)
		end

		for Value: number = math.ceil((Heading - 70) / 5) * 5, Heading + 70, 5 do
			Index += 1
			local Slot = Slots[Index]
			local Normalized: number = Value % 360
			local Major: boolean = Normalized % 45 == 0
			local Offset: number = TickStep + (Value - Heading + 70) * DegreeStep
			if Slot.Offset ~= Offset then
				Slot.Offset = Offset
				Slot.Object.Position = UDim2.fromOffset(Offset, 0)
			end

			if not Slot.Shown then
				Slot.Shown = true
				Slot.Object.Visible = true
			end

			if Slot.Major ~= Major then
				Slot.Major = Major
				Slot.Bar.Position = Major and MajorPosition or MinorPosition
				Slot.Bar.Size = Major and MajorSize or MinorSize
				Slot.Bar.BackgroundTransparency = Major and 0.6 or 0.624
			end

			local LabelShown: boolean = Major or Normalized % 15 == 0
			if Slot.LabelShown ~= LabelShown then
				Slot.LabelShown = LabelShown
				Slot.Label.Visible = LabelShown
			end

			if LabelShown and (Slot.Value ~= Normalized or Plain ~= Last.plain) then
				Slot.Value = Normalized
				Slot.Label.Text = Major and Cardinals[Normalized] or tostring(math.floor(Normalized))
				Slot.Label.FontFace = (Major or Plain) and UIPallet.FontSemiBold or UIPallet.Font
				Slot.Label.TextColor3 = Plain and PlateColor or (Major and WhiteColor or MutedColor)
			end
		end

		Last.plain = Plain

		for SlotIndex: number, v: any in Slots do
			if SlotIndex > Index and v.Shown then
				v.Shown = false
				v.Object.Visible = false
			end
		end
	end

	Compass = vape.Categories.Legit:CreateModule({
		Name = "Compass",
		Category = "Hud",
		Function = function(Callback: boolean)
			if Callback then
				Compass:Clean(RunService.RenderStepped:Connect(Update))
			end
		end,
		Size = UDim2.fromOffset(616, 60),
		Tooltip = "Shows a compass indicating your direction"
	})

	Background = Compass:CreateGroup({
		Name = "Render background",
		Function = function(Callback: boolean)
			if BackgroundColor then
				Holder.BackgroundTransparency = Callback and 1 - BackgroundColor.Opacity or 1
			end
		end,
		Default = true
	})
	BackgroundColor = Background:CreateColorSlider({
		Name = "Background Color",
		DefaultHue = 0.8333,
		DefaultSat = 0.0385,
		DefaultValue = 0.102,
		DefaultOpacity = 0.4,
		Function = function(Hue: number, Sat: number, Val: number, Opacity: number)
			if Holder then
				Holder.BackgroundColor3 = Color3.fromHSV(Hue, Sat, Val)
				Holder.BackgroundTransparency = Background.Enabled and 1 - Opacity or 1
			end
		end,
		Darker = true
	})
	Holder = Compass.Children
	Holder.BackgroundColor3 = Color3.fromRGB(26, 25, 26)
	Holder.BackgroundTransparency = 0.6
	local HolderCorner: UICorner = Instance.new("UICorner")
	HolderCorner.CornerRadius = UDim.new(0, 4)
	HolderCorner.Parent = Holder
	Strip = Instance.new("Frame")
	Strip.BackgroundTransparency = 1
	Strip.ClipsDescendants = true
	Strip.Name = "Strip"
	Strip.Position = UDim2.fromOffset(0, -20)
	Strip.Size = UDim2.fromOffset(616, 80)
	Strip.Parent = Holder
	HeadingLabel = Instance.new("TextLabel")
	HeadingLabel.AnchorPoint = Vector2.new(0.5, 0)
	HeadingLabel.BackgroundTransparency = 1
	HeadingLabel.FontFace = UIPallet.FontSemiBold
	HeadingLabel.Position = UDim2.fromOffset(StripCentre, 0)
	HeadingLabel.Size = UDim2.fromOffset(200, 16)
	HeadingLabel.TextColor3 = PlateColor
	HeadingLabel.TextSize = 12
	HeadingLabel.Parent = Strip
	local Arrow: ImageLabel = Instance.new("ImageLabel")
	Arrow.AnchorPoint = Vector2.new(0.5, 0)
	Arrow.BackgroundTransparency = 1
	Arrow.Image = GetVapeAsset(`ElevateV4/assets/new/compassarrow.png`)
	Arrow.Position = UDim2.fromOffset(StripCentre, 15)
	Arrow.Size = UDim2.fromOffset(19, 32)
	Arrow.Parent = Strip
	for i: number = 1, 29 do
		local Slot: Frame = Instance.new("Frame")
		Slot.BackgroundTransparency = 1
		Slot.Size = UDim2.new()
		Slot.Visible = false
		Slot.Parent = Strip
		local Bar: Frame = Instance.new("Frame")
		Bar.AnchorPoint = Vector2.new(0.5, 0)
		Bar.BackgroundColor3 = WhiteColor
		Bar.BorderSizePixel = 0
		Bar.Position = MajorPosition
		Bar.Size = MajorSize
		Bar.Parent = Slot
		local Label: TextLabel = Instance.new("TextLabel")
		Label.AnchorPoint = Vector2.new(0.5, 0)
		Label.BackgroundTransparency = 1
		Label.FontFace = UIPallet.FontSemiBold
		Label.Position = UDim2.fromOffset(0, 43)
		Label.Size = UDim2.fromOffset(60, 20)
		Label.TextColor3 = WhiteColor
		Label.TextSize = 11
		Label.Parent = Slot
		Slots[i] = {Object = Slot, Bar = Bar, Label = Label}
	end
end)
