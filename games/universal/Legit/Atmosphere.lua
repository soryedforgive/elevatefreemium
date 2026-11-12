run(function()
	local Lighting = lightingService
	local Atmosphere
	local Toggles = {}
	local NewObjects, OldObjects = {}, {}
	local ApiDump: {[string]: {[string]: string}} = {
		Sky = {
			SkyboxUp = "Text",
			SkyboxDn = "Text",
			SkyboxLf = "Text",
			SkyboxRt = "Text",
			SkyboxFt = "Text",
			SkyboxBk = "Text",
			SunTextureId = "Text",
			SunAngularSize = "Number",
			MoonTextureId = "Text",
			MoonAngularSize = "Number",
			StarCount = "Number"
		},
		Atmosphere = {
			Color = "Color",
			Decay = "Color",
			Density = "Number",
			Offset = "Number",
			Glare = "Number",
			Haze = "Number"
		},
		BloomEffect = {
			Intensity = "Number",
			Size = "Number",
			Threshold = "Number"
		},
		DepthOfFieldEffect = {
			FarIntensity = "Number",
			FocusDistance = "Number",
			InFocusRadius = "Number",
			NearIntensity = "Number"
		},
		SunRaysEffect = {
			Intensity = "Number",
			Spread = "Number"
		},
		ColorCorrectionEffect = {
			TintColor = "Color",
			Saturation = "Number",
			Contrast = "Number",
			Brightness = "Number"
		}
	}

	local function RemoveObject(Object: Instance)
		if not table.find(NewObjects, Object) then
			local ClassToggle = Toggles[Object.ClassName]
			if ClassToggle and ClassToggle.Toggle.Enabled then
				if Object.Parent then
					table.insert(OldObjects, Object)
					Object.Parent = game
				end
			end
		end
	end

	Atmosphere = vape.Categories.Legit:CreateModule({
		Name = "Atmosphere",
		Category = "Game",
		Function = function(Callback: boolean)
			if Callback then
				for _, v: Instance in Lighting:GetChildren() do
					RemoveObject(v)
				end

				Atmosphere:Clean(Lighting.ChildAdded:Connect(function(Child: Instance)
					task.defer(RemoveObject, Child)
				end))

				for ClassName: string, v: any in Toggles do
					if v.Toggle.Enabled then
						local Object: Instance = Instance.new(ClassName)
						for Property: string, Option: any in v.Objects do
							if Option.Type == "ColorSlider" then
								Object[Property] = Color3.fromHSV(Option.Hue, Option.Sat, Option.Value)
							else
								Object[Property] = ApiDump[ClassName][Property] ~= "Number" and Option.Value or tonumber(Option.Value) or 0
							end
						end
						Object.Parent = Lighting
						table.insert(NewObjects, Object)
					end
				end
			else
				for _, v: Instance in NewObjects do
					v:Destroy()
				end

				for _, v: Instance in OldObjects do
					v.Parent = Lighting
				end

				table.clear(NewObjects)
				table.clear(OldObjects)
			end
		end,
		Tooltip = 'Changes the sky and lighting'
	})

	for ClassName: string, Properties: {[string]: string} in ApiDump do
		Toggles[ClassName] = {Objects = {}}
		Toggles[ClassName].Toggle = Atmosphere:CreateToggle({
			Name = ClassName,
			Function = function(Callback: boolean)
				if Atmosphere.Enabled then
					Atmosphere:Toggle()
					Atmosphere:Toggle()
				end

				for _, v: any in Toggles[ClassName].Objects do
					v.Object.Visible = Callback
				end
			end
		})

		for Property: string, PropertyType: string in Properties do
			if PropertyType == "Text" or PropertyType == "Number" then
				Toggles[ClassName].Objects[Property] = Atmosphere:CreateTextBox({
					Name = Property,
					Function = function(Enter: boolean)
						if Atmosphere.Enabled and Enter then
							Atmosphere:Toggle()
							Atmosphere:Toggle()
						end
					end,
					Darker = true,
					Default = PropertyType == "Number" and "0" or nil,
					Visible = false
				})
			elseif PropertyType == "Color" then
				Toggles[ClassName].Objects[Property] = Atmosphere:CreateColorSlider({
					Name = Property,
					Function = function()
						if Atmosphere.Enabled then
							Atmosphere:Toggle()
							Atmosphere:Toggle()
						end
					end,
					Darker = true,
					Visible = false
				})
			end
		end
	end
end)
