run(function()
	local GameThemes
	local Theme
	local saved, stash
	local made = {}
	local scene
	local rayCheck = RaycastParams.new()
	local themes = {
		Morning = {
			Lighting = {Ambient = Color3.new(0, 0, 0), Brightness = 3, ColorShift_Bottom = Color3.new(1, 1, 1), ColorShift_Top = Color3.new(0.972549, 0.537255, 0.152941), OutdoorAmbient = Color3.new(0, 0, 0), FogColor = Color3.new(0.752941, 0.752941, 0.752941), FogEnd = 100000, FogStart = 0, GlobalShadows = true, GeographicLatitude = 40, ExposureCompensation = 0.7, EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1, ClockTime = 7, ShadowSoftness = 0.03},
			Children = {
				{'Sky', {CelestialBodiesShown = true, SunAngularSize = 5, MoonAngularSize = 1.5, SkyboxBk = 'rbxassetid://6973550206', SkyboxDn = 'rbxassetid://6973550815', SkyboxFt = 'rbxassetid://6973549125', SkyboxLf = 'rbxassetid://6973549670', SkyboxRt = 'rbxassetid://9089057892', SkyboxUp = 'rbxassetid://6973551204', StarCount = 5000, SunTextureId = 'rbxassetid://1084351190', MoonTextureId = 'rbxassetid://1075087760'}},
				{'Atmosphere', {Density = 0.325, Offset = 1, Color = Color3.new(0, 0, 0), Decay = Color3.new(0, 0, 0), Glare = 0, Haze = 0.05}},
				{'BloomEffect', {Enabled = true, Intensity = 1, Size = 56, Threshold = 2.9}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = 0, Contrast = 0.1, Saturation = 0.2, TintColor = Color3.new(1, 1, 1)}},
				{'SunRaysEffect', {Enabled = true, Intensity = 0.004, Spread = 0.04}},
			}
		},
		Sunset = {
			Lighting = {Ambient = Color3.new(0, 0, 0), Brightness = 1.5, ColorShift_Bottom = Color3.new(0, 0, 0), ColorShift_Top = Color3.new(0.666667, 0.533333, 0.321569), OutdoorAmbient = Color3.new(0, 0, 0), FogColor = Color3.new(0.752941, 0.752941, 0.752941), FogEnd = 100000, FogStart = 0, GlobalShadows = true, GeographicLatitude = 40, ExposureCompensation = 0.5, EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1, ClockTime = 17.6, ShadowSoftness = 0.03},
			Children = {
				{'Sky', {CelestialBodiesShown = true, SunAngularSize = 5, MoonAngularSize = 1.5, SkyboxBk = 'rbxassetid://6973550206', SkyboxDn = 'rbxassetid://6973550815', SkyboxFt = 'rbxassetid://6973549125', SkyboxLf = 'rbxassetid://6973549670', SkyboxRt = 'rbxassetid://9089057892', SkyboxUp = 'rbxassetid://6973551204', StarCount = 5000, SunTextureId = 'rbxassetid://1084351190', MoonTextureId = 'rbxassetid://1075087760'}},
				{'Atmosphere', {Density = 0.35, Offset = 1, Color = Color3.new(0.490196, 0.247059, 0.45098), Decay = Color3.new(0.411765, 0.643137, 0.705882), Glare = 0, Haze = 0.05}},
				{'BloomEffect', {Enabled = true, Intensity = 1, Size = 56, Threshold = 2.9}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = 0, Contrast = 0.05, Saturation = 0.1, TintColor = Color3.new(1, 0.921569, 0.796078)}},
				{'SunRaysEffect', {Enabled = true, Intensity = 0.004, Spread = 0.04}},
			}
		},
		GoldenHour = {
			Lighting = {Ambient = Color3.new(0.133333, 0.137255, 0.145098), Brightness = 2.2, ColorShift_Bottom = Color3.new(0.713726, 0.713726, 0.713726), ColorShift_Top = Color3.new(0.956863, 0.952941, 0.886275), OutdoorAmbient = Color3.new(0.4, 0.34902, 0.321569), FogColor = Color3.new(0.752941, 0.752941, 0.752941), FogEnd = 100000, FogStart = 0, GlobalShadows = true, GeographicLatitude = 55, ExposureCompensation = 0.6, EnvironmentDiffuseScale = 0.5, EnvironmentSpecularScale = 0.75, ClockTime = 16.65, ShadowSoftness = 0.1},
			Children = {
				{'Atmosphere', {Density = 0.33, Offset = 0, Color = Color3.new(0.7843, 0.6667, 0.4235), Decay = Color3.new(0.3608, 0.2353, 0.0549), Glare = 0, Haze = 0}},
				{'BloomEffect', {Enabled = true, Intensity = 0.05, Size = 38, Threshold = 2}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = -0.04, Contrast = 0.4, Saturation = 0.1, TintColor = Color3.new(1, 0.941176, 0.878431)}},
				{'DepthOfFieldEffect', {Enabled = true, FarIntensity = 0.1, FocusDistance = 100, InFocusRadius = 50, NearIntensity = 0}},
				{'SunRaysEffect', {Enabled = true, Intensity = 0.022, Spread = 0.4}},
				{'Sky', {CelestialBodiesShown = false, SunAngularSize = 21, MoonAngularSize = 11, SkyboxBk = 'rbxassetid://600830446', SkyboxDn = 'rbxassetid://600831635', SkyboxFt = 'rbxassetid://600832720', SkyboxLf = 'rbxassetid://600886090', SkyboxRt = 'rbxassetid://600833862', SkyboxUp = 'rbxassetid://600835177', StarCount = 3000}},
			}
		},
		CherryBlossom = {
			Lighting = {Ambient = Color3.new(0.627451, 0.580392, 0.631373), Brightness = 8, ColorShift_Bottom = Color3.new(0.713726, 0.713726, 0.713726), ColorShift_Top = Color3.new(0.956863, 0.952941, 0.886275), OutdoorAmbient = Color3.new(0.552941, 0.529412, 0.576471), FogColor = Color3.new(0.752941, 0.752941, 0.752941), FogEnd = 100000, FogStart = 0, GlobalShadows = true, GeographicLatitude = 25, ExposureCompensation = 0.1, EnvironmentDiffuseScale = 0, EnvironmentSpecularScale = 0.75, ClockTime = 16.7, ShadowSoftness = 0.1},
			Children = {
				{'Atmosphere', {Density = 0.33, Offset = 0, Color = Color3.new(0.580392, 0.462745, 0.552941), Decay = Color3.new(0.866667, 0.768627, 0.909804), Glare = 0.2, Haze = 0}},
				{'BloomEffect', {Enabled = true, Intensity = 0.05, Size = 38, Threshold = 2}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = -0.04, Contrast = 0.3, Saturation = 0.1, TintColor = Color3.new(1, 0.937255, 1)}},
				{'DepthOfFieldEffect', {Enabled = true, FarIntensity = 0.1, FocusDistance = 100, InFocusRadius = 50, NearIntensity = 0}},
				{'SunRaysEffect', {Enabled = true, Intensity = 0.022, Spread = 0.4}},
				{'Sky', {CelestialBodiesShown = true, SunAngularSize = 21, MoonAngularSize = 11, SkyboxBk = 'rbxassetid://11555017034', SkyboxDn = 'rbxassetid://11555013415', SkyboxFt = 'rbxassetid://11555010145', SkyboxLf = 'rbxassetid://11555006545', SkyboxRt = 'rbxassetid://11555000712', SkyboxUp = 'rbxassetid://11554996247', StarCount = 3000}},
			}
		},
		Haze = {
			Lighting = {Ambient = Color3.new(0.211765, 0.219608, 0.231373), Brightness = 2.1, ColorShift_Bottom = Color3.new(0.713726, 0.713726, 0.713726), ColorShift_Top = Color3.new(0.956863, 0.952941, 0.886275), OutdoorAmbient = Color3.new(0.490196, 0.482353, 0.458824), FogColor = Color3.new(0.752941, 0.752941, 0.752941), FogEnd = 100000, FogStart = 0, GlobalShadows = true, GeographicLatitude = 55, ExposureCompensation = 0.6, EnvironmentDiffuseScale = 0.5, EnvironmentSpecularScale = 0.75, ClockTime = 7.6, ShadowSoftness = 0.1},
			Children = {
				{'Atmosphere', {Density = 0.3, Offset = 0, Color = Color3.new(1, 0.964706, 0.827451), Decay = Color3.new(0.654902, 0.627451, 0.576471), Glare = 0.25, Haze = 0.15}},
				{'BloomEffect', {Enabled = true, Intensity = 0.05, Size = 38, Threshold = 2}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = -0.06, Contrast = 0.33, Saturation = 0.1, TintColor = Color3.new(1, 0.941176, 0.878431)}},
				{'DepthOfFieldEffect', {Enabled = true, FarIntensity = 0.1, FocusDistance = 100, InFocusRadius = 50, NearIntensity = 0}},
				{'SunRaysEffect', {Enabled = true, Intensity = 0.022, Spread = 0.4}},
				{'Sky', {CelestialBodiesShown = true, SunAngularSize = 11, MoonAngularSize = 11, SkyboxBk = 'http://www.roblox.com/asset/?id=252760981', SkyboxDn = 'http://www.roblox.com/asset/?id=252763035', SkyboxFt = 'http://www.roblox.com/asset/?id=252761439', SkyboxLf = 'http://www.roblox.com/asset/?id=252760980', SkyboxRt = 'http://www.roblox.com/asset/?id=252760986', SkyboxUp = 'http://www.roblox.com/asset/?id=252762652', StarCount = 3000, SunTextureId = 'rbxassetid://1345009717', MoonTextureId = 'rbxasset://sky/moon.jpg'}},
			}
		},
		Foggy = {
			Lighting = {Ambient = Color3.new(0, 0, 0), Brightness = 1, ColorShift_Bottom = Color3.new(0, 0, 0), ColorShift_Top = Color3.new(0, 0, 0), OutdoorAmbient = Color3.new(0.431373, 0.431373, 0.431373), FogColor = Color3.new(0.521569, 0.521569, 0.521569), FogEnd = 300, FogStart = 15, GlobalShadows = true, GeographicLatitude = 23.5, ExposureCompensation = 0, EnvironmentDiffuseScale = 0.4, EnvironmentSpecularScale = 0.6, ClockTime = 12, ShadowSoftness = 0.07},
			Children = {
				{'BloomEffect', {Enabled = true, Intensity = 0.2, Size = 100, Threshold = 0.8}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = 0, Contrast = 0, Saturation = 0.4, TintColor = Color3.new(1, 1, 1)}},
				{'Sky', {CelestialBodiesShown = false, SkyboxBk = 'http://www.roblox.com/asset/?id=4514139911', SkyboxDn = 'http://www.roblox.com/asset/?id=4514139911', SkyboxFt = 'http://www.roblox.com/asset/?id=4514139911', SkyboxLf = 'http://www.roblox.com/asset/?id=4514139911', SkyboxRt = 'http://www.roblox.com/asset/?id=4514139911', SkyboxUp = 'http://www.roblox.com/asset/?id=4514139911', StarCount = 3000}},
				{'Atmosphere', {Density = 0.675, Offset = 0, Color = Color3.new(0.780392, 0.780392, 0.780392), Decay = Color3.new(0.454902, 0.454902, 0.454902), Glare = 4.95, Haze = 2.62}},
			}
		},
		LightSnow = {
			Lighting = {Ambient = Color3.new(0.15, 0.15, 0.15), Brightness = 1.7, ColorShift_Bottom = Color3.new(0, 0, 0), ColorShift_Top = Color3.new(0, 0, 0), OutdoorAmbient = Color3.new(0.68, 0.72, 0.78), FogColor = Color3.new(0.76, 0.8, 0.86), FogEnd = 850, FogStart = 35, GlobalShadows = true, GeographicLatitude = 23.5, ExposureCompensation = 0, EnvironmentDiffuseScale = 0.5, EnvironmentSpecularScale = 0.65, ClockTime = 12.3, ShadowSoftness = 0.05},
			Children = {
				{'Sky', {CelestialBodiesShown = false, SkyboxBk = 'http://www.roblox.com/asset/?id=4514139911', SkyboxDn = 'http://www.roblox.com/asset/?id=4514139911', SkyboxFt = 'http://www.roblox.com/asset/?id=4514139911', SkyboxLf = 'http://www.roblox.com/asset/?id=4514139911', SkyboxRt = 'http://www.roblox.com/asset/?id=4514139911', SkyboxUp = 'http://www.roblox.com/asset/?id=4514139911', StarCount = 3000}},
				{'Atmosphere', {Density = 0.4, Offset = 0.12, Color = Color3.new(0.8, 0.84, 0.89), Decay = Color3.new(0.7, 0.74, 0.81), Glare = 0.7, Haze = 2.4}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = -0.01, Contrast = 0.04, Saturation = -0.1, TintColor = Color3.new(0.96, 0.98, 1)}},
			},
			Snow = {Rate = 450, Lifetime = NumberRange.new(7, 10), Speed = NumberRange.new(6, 14), Size = {{0, 0.45}, {0.7, 0.32}, {1, 0.18}}, Transparency = {{0, 0.35}, {0.8, 0.5}, {1, 1}}, Acceleration = Vector3.new(0, -1.2, 0)}
		},
		ChillMorning = {
			Lighting = {Ambient = Color3.new(0, 0, 0), Brightness = 2.2, ColorShift_Bottom = Color3.new(0.9, 0.95, 1), ColorShift_Top = Color3.new(0.972549, 0.537255, 0.152941), OutdoorAmbient = Color3.new(0.62, 0.66, 0.74), FogColor = Color3.new(0.82, 0.87, 0.93), FogEnd = 680, FogStart = 30, GlobalShadows = true, GeographicLatitude = 40, ExposureCompensation = 0.55, EnvironmentDiffuseScale = 0.6, EnvironmentSpecularScale = 0.75, ClockTime = 7.2, ShadowSoftness = 0.04},
			Children = {
				{'Sky', {CelestialBodiesShown = true, SunAngularSize = 5, MoonAngularSize = 1.5, SkyboxBk = 'rbxassetid://6973550206', SkyboxDn = 'rbxassetid://6973550815', SkyboxFt = 'rbxassetid://6973549125', SkyboxLf = 'rbxassetid://6973549670', SkyboxRt = 'rbxassetid://9089057892', SkyboxUp = 'rbxassetid://6973551204', StarCount = 2000, SunTextureId = 'rbxassetid://1084351190', MoonTextureId = 'rbxassetid://1075087760'}},
				{'Atmosphere', {Density = 0.38, Offset = 0.18, Color = Color3.new(0.78, 0.82, 0.88), Decay = Color3.new(0.68, 0.72, 0.80), Glare = 0.9, Haze = 2.0}},
				{'BloomEffect', {Enabled = true, Intensity = 0.85, Size = 48, Threshold = 2.7}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = 0.02, Contrast = 0.08, Saturation = 0.05, TintColor = Color3.new(0.96, 0.98, 1)}},
				{'SunRaysEffect', {Enabled = true, Intensity = 0.003, Spread = 0.035}},
			},
			Snow = {Rate = 320, Lifetime = NumberRange.new(8, 12), Speed = NumberRange.new(4, 10), Size = {{0, 0.4}, {0.7, 0.28}, {1, 0.14}}, Transparency = {{0, 0.28}, {0.8, 0.48}, {1, 1}}, Acceleration = Vector3.new(0, -0.9, 0)}
		},
		Blizzard = {
			Lighting = {Ambient = Color3.new(0, 0, 0), Brightness = 1, ColorShift_Bottom = Color3.new(0, 0, 0), ColorShift_Top = Color3.new(0, 0, 0), OutdoorAmbient = Color3.new(0.576471, 0.6, 0.760784), FogColor = Color3.new(0.576471, 0.6, 0.760784), FogEnd = 300, FogStart = 15, GlobalShadows = true, GeographicLatitude = 23.5, ExposureCompensation = 0, EnvironmentDiffuseScale = 0.4, EnvironmentSpecularScale = 0.6, ClockTime = 12, ShadowSoftness = 0.07},
			Children = {
				{'Sky', {CelestialBodiesShown = false, SkyboxBk = 'http://www.roblox.com/asset/?id=4514139911', SkyboxDn = 'http://www.roblox.com/asset/?id=4514139911', SkyboxFt = 'http://www.roblox.com/asset/?id=4514139911', SkyboxLf = 'http://www.roblox.com/asset/?id=4514139911', SkyboxRt = 'http://www.roblox.com/asset/?id=4514139911', SkyboxUp = 'http://www.roblox.com/asset/?id=4514139911', StarCount = 3000}},
				{'Atmosphere', {Density = 0.531, Offset = 0.281, Color = Color3.new(0.686275, 0.733333, 0.780392), Decay = Color3.new(0.619608, 0.666667, 0.784314), Glare = 2.69, Haze = 10}},
			},
			Snow = {Rate = 5000, Lifetime = NumberRange.new(6, 8), Speed = NumberRange.new(20, 50), Size = {{0, 1.875}, {0.375, 1.25}, {1, 0}}, Transparency = {{0, 1}, {0.5, 0.4375}, {1, 0}}, Acceleration = Vector3.new(0, -0.4, 0), Wall = true}
		},
		LightRain = {
			Lighting = {Ambient = Color3.new(0, 0, 0), Brightness = 1.4, ColorShift_Bottom = Color3.new(0, 0, 0), ColorShift_Top = Color3.new(0.6, 0.6, 0.6), OutdoorAmbient = Color3.new(0.3, 0.32, 0.36), FogColor = Color3.new(0.72, 0.74, 0.78), FogEnd = 800, FogStart = 40, GlobalShadows = true, GeographicLatitude = 40, ExposureCompensation = 0, EnvironmentDiffuseScale = 0.8, EnvironmentSpecularScale = 0.6, ClockTime = 13, ShadowSoftness = 0.05},
			Children = {
				{'Sky', {CelestialBodiesShown = false, SkyboxBk = 'http://www.roblox.com/asset/?id=4514139911', SkyboxDn = 'http://www.roblox.com/asset/?id=4514139911', SkyboxFt = 'http://www.roblox.com/asset/?id=4514139911', SkyboxLf = 'http://www.roblox.com/asset/?id=4514139911', SkyboxRt = 'http://www.roblox.com/asset/?id=4514139911', SkyboxUp = 'http://www.roblox.com/asset/?id=4514139911', StarCount = 0}},
				{'Atmosphere', {Density = 0.38, Offset = 0.08, Color = Color3.new(0.74, 0.76, 0.80), Decay = Color3.new(0.60, 0.62, 0.66), Glare = 0.3, Haze = 1.8}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = -0.02, Contrast = 0.03, Saturation = -0.15, TintColor = Color3.new(0.94, 0.96, 1)}},
			},
			Rain = {Rate = 28, Mist = 6, MistMin = 0.94, MistMax = 0.97}
		},
		HeavyRain = {
			Lighting = {Ambient = Color3.new(0.168627, 0.168627, 0.168627), Brightness = 1, ColorShift_Bottom = Color3.new(0, 0, 0), ColorShift_Top = Color3.new(0, 0, 0), OutdoorAmbient = Color3.new(0.168627, 0.168627, 0.168627), FogColor = Color3.new(0.752941, 0.752941, 0.752941), FogEnd = 100000, FogStart = 0, GlobalShadows = true, GeographicLatitude = 0, ExposureCompensation = 0, EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1, ClockTime = 0, ShadowSoftness = 0.2},
			Children = {
				{'Atmosphere', {Density = 0.6, Offset = 0, Color = Color3.new(0.780392, 0.780392, 0.780392), Decay = Color3.new(0.415686, 0.439216, 0.490196), Glare = 0, Haze = 0}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = 0, Contrast = 0, Saturation = 0.5, TintColor = Color3.new(1, 1, 1)}},
				{'Sky', {CelestialBodiesShown = true, SunAngularSize = 11, MoonAngularSize = 11, SkyboxBk = 'rbxassetid://6444884337', SkyboxDn = 'rbxassetid://6444884785', SkyboxFt = 'rbxassetid://6444884337', SkyboxLf = 'rbxassetid://6444884337', SkyboxRt = 'rbxassetid://6444884337', SkyboxUp = 'rbxassetid://6412503613', StarCount = 3000, SunTextureId = 'rbxassetid://6196665106', MoonTextureId = 'rbxassetid://5076043799'}},
				{'DepthOfFieldEffect', {Enabled = true, FarIntensity = 0.75, FocusDistance = 0.05, InFocusRadius = 75, NearIntensity = 0}},
			},
			Rain = {Rate = 82, Mist = 18, MistMin = 0.88, MistMax = 0.93}
		},
		Nighttime = {
			Lighting = {Ambient = Color3.new(0.168627, 0.168627, 0.168627), Brightness = 1, ColorShift_Bottom = Color3.new(0, 0, 0), ColorShift_Top = Color3.new(0, 0, 0), OutdoorAmbient = Color3.new(0.168627, 0.168627, 0.168627), FogColor = Color3.new(0.752941, 0.752941, 0.752941), FogEnd = 100000, FogStart = 0, GlobalShadows = true, GeographicLatitude = 0, ExposureCompensation = 0, EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1, ClockTime = 0, ShadowSoftness = 0.2},
			Children = {
				{'Sky', {CelestialBodiesShown = true, SunAngularSize = 11, MoonAngularSize = 11, SkyboxBk = 'rbxassetid://6444884337', SkyboxDn = 'rbxassetid://6444884785', SkyboxFt = 'rbxassetid://6444884337', SkyboxLf = 'rbxassetid://6444884337', SkyboxRt = 'rbxassetid://6444884337', SkyboxUp = 'rbxassetid://6412503613', StarCount = 3000, SunTextureId = 'rbxassetid://6196665106', MoonTextureId = 'rbxassetid://5076043799'}},
				{'DepthOfFieldEffect', {Enabled = false, FarIntensity = 0, FocusDistance = 0.05, InFocusRadius = 30, NearIntensity = 0}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1)}},
				{'Atmosphere', {Density = 0.6, Offset = 0, Color = Color3.new(0.780392, 0.780392, 0.780392), Decay = Color3.new(0.415686, 0.439216, 0.490196), Glare = 0, Haze = 0}},
			}
		},
		BloodMoon = {
			Lighting = {Ambient = Color3.new(0.0784314, 0.0784314, 0.0784314), Brightness = 0.5, ColorShift_Bottom = Color3.new(0, 0, 0), ColorShift_Top = Color3.new(0, 0, 0), OutdoorAmbient = Color3.new(0.423529, 0.160784, 0.164706), FogColor = Color3.new(0, 0, 0), FogEnd = 300, FogStart = 15, GlobalShadows = true, GeographicLatitude = 23.5, ExposureCompensation = 0, EnvironmentDiffuseScale = 0.4, EnvironmentSpecularScale = 0.6, ClockTime = 0, ShadowSoftness = 0.07},
			Children = {
				{'BloomEffect', {Enabled = true, Intensity = 0.2, Size = 100, Threshold = 0.8}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = 0, Contrast = 0, Saturation = 0.4, TintColor = Color3.new(1, 1, 1)}},
				{'Sky', {CelestialBodiesShown = false, SkyboxBk = 'http://www.roblox.com/asset/?id=4514139911', SkyboxDn = 'http://www.roblox.com/asset/?id=4514139911', SkyboxFt = 'http://www.roblox.com/asset/?id=4514139911', SkyboxLf = 'http://www.roblox.com/asset/?id=4514139911', SkyboxRt = 'http://www.roblox.com/asset/?id=4514139911', SkyboxUp = 'http://www.roblox.com/asset/?id=4514139911', StarCount = 3000}},
				{'Atmosphere', {Density = 0.58, Offset = 0, Color = Color3.new(0.254902, 0.14902, 0.152941), Decay = Color3.new(0.27451, 0.0431373, 0.0509804), Glare = 0, Haze = 4.47}},
			}
		},
		WasteLand = {
			Lighting = {Ambient = Color3.new(0, 0, 0), Brightness = 3.5, ColorShift_Bottom = Color3.new(0, 0, 0), ColorShift_Top = Color3.new(1, 0.752941, 0.572549), OutdoorAmbient = Color3.new(0.254902, 0.282353, 0.207843), FogColor = Color3.new(0.752941, 0.752941, 0.752941), FogEnd = 100000, FogStart = 0, GlobalShadows = true, GeographicLatitude = 53, ExposureCompensation = 0, EnvironmentDiffuseScale = 0.222, EnvironmentSpecularScale = 1, ClockTime = 7.8, ShadowSoftness = 0.15},
			Children = {
				{'BloomEffect', {Enabled = true, Intensity = 0.15, Size = 20, Threshold = 2}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = 0.1, Contrast = 0.2, Saturation = 0, TintColor = Color3.new(0.803922, 0.890196, 1)}},
				{'SunRaysEffect', {Enabled = true, Intensity = -0.01, Spread = 1}},
				{'Sky', {CelestialBodiesShown = true, SunAngularSize = 11, MoonAngularSize = 11, SkyboxBk = 'http://www.roblox.com/asset/?id=252760981', SkyboxDn = 'http://www.roblox.com/asset/?id=252763035', SkyboxFt = 'http://www.roblox.com/asset/?id=252761439', SkyboxLf = 'http://www.roblox.com/asset/?id=252760980', SkyboxRt = 'http://www.roblox.com/asset/?id=252760986', SkyboxUp = 'http://www.roblox.com/asset/?id=252762652', StarCount = 3000, SunTextureId = 'rbxassetid://1345009717', MoonTextureId = 'rbxasset://sky/moon.jpg'}},
				{'Atmosphere', {Density = 0.125, Offset = 0, Color = Color3.new(0.45098, 0.623529, 0.65098), Decay = Color3.new(0.160784, 0.239216, 0.247059), Glare = 0.5, Haze = 2.1}},
			}
		},
		Void = {
			Lighting = {Ambient = Color3.new(0.784314, 0.784314, 0.784314), Brightness = 1, ColorShift_Bottom = Color3.new(0, 0, 0), ColorShift_Top = Color3.new(0, 0, 0), OutdoorAmbient = Color3.new(0.588235, 0.588235, 0.588235), FogColor = Color3.new(0.431373, 0.258824, 0.666667), FogEnd = 2000, FogStart = 0, GlobalShadows = true, GeographicLatitude = 41.7333, ExposureCompensation = 0, EnvironmentDiffuseScale = 0, EnvironmentSpecularScale = 0, ClockTime = 14, ShadowSoftness = 0.5},
			Children = {
				{'SunRaysEffect', {Enabled = true, Intensity = 0, Spread = 1}},
				{'ColorCorrectionEffect', {Enabled = true, Brightness = 0, Contrast = 0.35, Saturation = 0, TintColor = Color3.new(1, 1, 1)}},
				{'BloomEffect', {Enabled = true, Intensity = 1, Size = 13, Threshold = 2}},
				{'Sky', {CelestialBodiesShown = false, SunAngularSize = 21, MoonAngularSize = 11, SkyboxBk = 'http://www.roblox.com/asset/?id=296908715', SkyboxDn = 'http://www.roblox.com/asset/?id=296908724', SkyboxFt = 'http://www.roblox.com/asset/?id=296908740', SkyboxLf = 'http://www.roblox.com/asset/?id=296908755', SkyboxRt = 'http://www.roblox.com/asset/?id=296908764', SkyboxUp = 'http://www.roblox.com/asset/?id=296908769', StarCount = 0}},
			}
		},
	}
	local cycle = {
		{Clock = 7, Brightness = 3, Exposure = 0.7, Top = Color3.new(0.97, 0.54, 0.15), Density = 0.325, Contrast = 0.1, Saturation = 0.2, Tint = Color3.new(1, 1, 1)},
		{Clock = 14, Brightness = 3, Exposure = 0.4, Top = Color3.new(1, 0.94, 0.8), Density = 0.3, Contrast = 0.05, Saturation = 0.1, Tint = Color3.new(1, 1, 1)},
		{Clock = 17.6, Brightness = 1.5, Exposure = 0.5, Top = Color3.new(0.67, 0.53, 0.32), Density = 0.35, Contrast = 0.05, Saturation = 0.1, Tint = Color3.new(1, 0.92, 0.8)},
		{Clock = 27, Brightness = 1, Exposure = 2.1, Top = Color3.new(1, 1, 1), Density = 0.35, Contrast = 0.05, Saturation = -0.1, Tint = Color3.new(1, 1, 1)}
	}

	local function sequence(points)
		local keys = {}
		for _, v in points do
			table.insert(keys, NumberSequenceKeypoint.new(v[1], v[2]))
		end
		return NumberSequence.new(keys)
	end

	local function emitter(part, props)
		local particles = Instance.new('ParticleEmitter')
		for prop, value in props do
			particles[prop] = value
		end
		particles.Parent = part
		return particles
	end

	local function weatherPart(size)
		local part = Instance.new('Part')
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
		part.Size = size
		part.Parent = scene
		return part
	end

	local function clear()
		for _, v in made do
			v:Destroy()
		end
		table.clear(made)
		if scene then
			scene:Destroy()
			scene = nil
		end
	end

	local function snapshot(theme)
		if saved then return end
		saved, stash = {}, {}
		for prop in theme.Lighting do
			saved[prop] = lightingService[prop]
		end
		for _, v in lightingService:GetChildren() do
			local keep = v.Name == 'DeathBarrierEffect' or v.Name == 'SmokeColorCorrection'
			if not keep and (v:IsA('Sky') or v:IsA('Atmosphere') or v:IsA('PostEffect')) then
				table.insert(stash, v)
				v.Parent = nil
			end
		end
	end

	local function restore()
		clear()
		if not saved then return end
		for prop, value in saved do
			pcall(function()
				lightingService[prop] = value
			end)
		end
		for _, v in stash do
			v.Parent = lightingService
		end
		saved, stash = nil, nil
	end

	local function snow(config)
		local part = weatherPart(config.Wall and Vector3.new(100, 80, 1) or Vector3.new(90, 55, 1))
		emitter(part, {
			Texture = 'rbxassetid://127302768524882',
			Rate = config.Rate,
			Lifetime = config.Lifetime,
			Speed = config.Speed,
			SpreadAngle = config.Wall and Vector2.new(5, 5) or Vector2.new(12, 12),
			LightInfluence = 1,
			Acceleration = config.Acceleration,
			EmissionDirection = Enum.NormalId.Front,
			Shape = Enum.ParticleEmitterShape.Box,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			Size = sequence(config.Size),
			Transparency = sequence(config.Transparency)
		})
		return function()
			local focus = gameCamera.Focus.Position
			if config.Wall then
				part.CFrame = CFrame.new(focus + Vector3.new(0, 0, 50))
			else
				part.CFrame = CFrame.lookAt(focus + Vector3.new(0, 5, 10), focus)
			end
		end
	end

	local function rain(config)
		local drops = {}
		for _, offset in {Vector3.new(0, 37, 0), Vector3.new(30, 25, -30), Vector3.new(-30, 25, 30)} do
			local part = weatherPart(Vector3.new(100, 1, 100))
			table.insert(drops, {Part = part, Offset = offset, Emitter = emitter(part, {
				Texture = 'rbxassetid://1822883048',
				Rate = config.Rate,
				Lifetime = NumberRange.new(3),
				Speed = NumberRange.new(100),
				SpreadAngle = Vector2.new(2, 2),
				LightInfluence = 0.38,
				LightEmission = 0.5,
				EmissionDirection = Enum.NormalId.Bottom,
				Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
				Shape = Enum.ParticleEmitterShape.Box,
				ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
				Color = ColorSequence.new(Color3.new(0.76, 0.82, 1)),
				Size = NumberSequence.new(11),
				Transparency = sequence({{0, 0.85}, {0.37, 0.89}, {0.4, 1}, {1, 1}})
			})})
		end
		local mistPart = weatherPart(Vector3.new(100, 1, 100))
		local mist = emitter(mistPart, {
			Texture = 'rbxassetid://135522315481814',
			Rate = config.Mist,
			Lifetime = NumberRange.new(6, 10),
			Speed = NumberRange.new(1, 4),
			Drag = 0.8,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-10, 10),
			SpreadAngle = Vector2.new(20, 20),
			LightInfluence = 1,
			EmissionDirection = Enum.NormalId.Top,
			Shape = Enum.ParticleEmitterShape.Box,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
			Color = ColorSequence.new(Color3.new(0.78, 0.81, 0.85)),
			Size = sequence({{0, 4}, {0.4, 8}, {1, 3}}),
			Transparency = sequence({{0, 1}, {0.1, config.MistMin}, {0.9, config.MistMax}, {1, 1}})
		})
		return function()
			local focus = gameCamera.Focus.Position
			rayCheck.FilterDescendantsInstances = {lplr.Character, scene, gameCamera}
			local roof = workspace:Raycast(focus, Vector3.new(0, 80, 0), rayCheck)
			local floor = workspace:Raycast(focus + Vector3.new(0, 5, 0), Vector3.new(0, -60, 0), rayCheck)
			for _, v in drops do
				v.Emitter.Enabled = not roof
				v.Part.CFrame = CFrame.new(focus + v.Offset)
			end
			mist.Enabled = not roof and floor ~= nil
			if floor then
				mistPart.CFrame = CFrame.new(focus.X, floor.Position.Y + 1, focus.Z)
			end
		end
	end

	local function apply(name)
		clear()
		local theme = themes[name]
		if name == 'TimeCycle' then
			theme = themes.Morning
		end
		if not theme then return end
		snapshot(theme)
		for prop, value in theme.Lighting do
			pcall(function()
				lightingService[prop] = value
			end)
		end
		for _, child in theme.Children do
			local obj = Instance.new(child[1])
			for prop, value in child[2] do
				obj[prop] = value
			end
			obj.Parent = lightingService
			table.insert(made, obj)
		end

		local update
		theme = themes[name] or {}
		if theme.Snow or theme.Rain then
			scene = Instance.new('Folder')
			scene.Parent = gameCamera
			update = theme.Snow and snow(theme.Snow) or rain(theme.Rain)
		elseif name == 'TimeCycle' then
			local atmosphere = lightingService:FindFirstChildOfClass('Atmosphere')
			local correction
			for _, v in made do
				if v:IsA('ColorCorrectionEffect') then
					correction = v
				end
			end
			local widths, started = {7 / 24, 3.6 / 24, 9.4 / 24, 4 / 24}, tick()
			update = function()
				local t = (tick() - started) % 300 / 300
				local index, start = 1, 0
				while index < 4 and t >= start + widths[index] do
					start += widths[index]
					index += 1
				end
				local a, b = cycle[index], cycle[index % 4 + 1]
				local alpha = math.clamp((t - start) / widths[index], 0, 1)
				local clock = index == 4 and cycle[1].Clock + 24 or b.Clock
				lightingService.ClockTime = (a.Clock + (clock - a.Clock) * alpha) % 24
				lightingService.Brightness = a.Brightness + (b.Brightness - a.Brightness) * alpha
				lightingService.ExposureCompensation = a.Exposure + (b.Exposure - a.Exposure) * alpha
				lightingService.ColorShift_Top = a.Top:Lerp(b.Top, alpha)
				if atmosphere then
					atmosphere.Density = a.Density + (b.Density - a.Density) * alpha
				end
				if correction then
					correction.Contrast = a.Contrast + (b.Contrast - a.Contrast) * alpha
					correction.Saturation = a.Saturation + (b.Saturation - a.Saturation) * alpha
					correction.TintColor = a.Tint:Lerp(b.Tint, alpha)
				end
			end
		end
		return update
	end

	GameThemes = vape.Categories.Render:CreateModule({
		Name = 'GameThemes',
		Function = function(callback)
			if callback then
				local current, update
				repeat
					if current ~= Theme.Value then
						current = Theme.Value
						update = apply(current)
					end
					if update then
						update()
					end
					task.wait()
				until not GameThemes.Enabled
			else
				restore()
			end
		end,
		ExtraText = function()
			return Theme.Value
		end,
		Tooltip = 'Changes the sky, lighting and weather on your screen'
	})
	Theme = GameThemes:CreateDropdown({
		Name = 'Theme',
		List = {'Morning', 'Sunset', 'GoldenHour', 'CherryBlossom', 'Haze', 'Foggy', 'LightSnow', 'ChillMorning', 'Blizzard', 'LightRain', 'HeavyRain', 'Nighttime', 'BloodMoon', 'WasteLand', 'Void', 'TimeCycle'}
	})
end)
