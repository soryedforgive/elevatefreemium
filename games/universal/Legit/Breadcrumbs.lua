run(function()
    local Breadcrumbs
    local Texture
    local Lifetime
    local Thickness
    local FadeIn
    local FadeOut
    local trail, point, point2

    Breadcrumbs = vape.Categories.Legit:CreateModule({
	Name = 'Breadcrumbs',
	Function = function(callback)
		if callback then
			point = Instance.new('Attachment')
			point.Position = Vector3.new(0, Thickness.Value - 2.7, 0)
			point2 = Instance.new('Attachment')
			point2.Position = Vector3.new(0, -Thickness.Value - 2.7, 0)
			trail = Instance.new('Trail')
			trail.Texture = Texture.Value == '' and 'http://www.roblox.com/asset/?id=14166981368' or Texture.Value
			trail.TextureMode = Enum.TextureMode.Static
			trail.Color = ColorSequence.new(
				Color3.fromHSV(FadeIn.Hue, FadeIn.Sat, FadeIn.Value),
				Color3.fromHSV(FadeOut.Hue, FadeOut.Sat, FadeOut.Value)
			)
			trail.Lifetime = Lifetime.Value
			trail.Attachment0 = point
			trail.Attachment1 = point2
			trail.FaceCamera = true

			Breadcrumbs:Clean(trail)
			Breadcrumbs:Clean(point)
			Breadcrumbs:Clean(point2)
			local function attach(root)
				if not pcall(function()
					point.Parent = root
					point2.Parent = root
				end) then
					point = Instance.new('Attachment')
					point.Position = Vector3.new(0, Thickness.Value - 2.7, 0)
					point2 = Instance.new('Attachment')
					point2.Position = Vector3.new(0, -Thickness.Value - 2.7, 0)
					Breadcrumbs:Clean(point)
					Breadcrumbs:Clean(point2)
					trail.Attachment0 = point
					trail.Attachment1 = point2
					point.Parent = root
					point2.Parent = root
				end
				trail.Parent = gameCamera
			end
			Breadcrumbs:Clean(entitylib.Events.LocalAdded:Connect(function(ent)
				attach(ent.HumanoidRootPart)
			end))
			Breadcrumbs:Clean(entitylib.Events.LocalRemoved:Connect(function()
				pcall(function()
					point.Parent = nil
					point2.Parent = nil
				end)
			end))
			if entitylib.isAlive then
				attach(entitylib.character.RootPart)
			end
		else
			trail = nil
			point = nil
			point2 = nil
		end
	end,
	Tooltip = 'Shows a trail behind your character'
    })
    Texture = Breadcrumbs:CreateTextBox({
	Name = 'Texture',
	Placeholder = 'Texture Id',
	Function = function(enter)
		if enter and trail then
			trail.Texture = Texture.Value == '' and 'http://www.roblox.com/asset/?id=14166981368' or Texture.Value
		end
	end,
    })
    FadeIn = Breadcrumbs:CreateColorSlider({
	Name = 'Fade In',
	Function = function(hue, sat, val)
		if trail then
			trail.Color = ColorSequence.new(
				Color3.fromHSV(hue, sat, val),
				Color3.fromHSV(FadeOut.Hue, FadeOut.Sat, FadeOut.Value)
			)
		end
	end,
    })
    FadeOut = Breadcrumbs:CreateColorSlider({
	Name = 'Fade Out',
	Function = function(hue, sat, val)
		if trail then
			trail.Color =
				ColorSequence.new(Color3.fromHSV(FadeIn.Hue, FadeIn.Sat, FadeIn.Value), Color3.fromHSV(hue, sat, val))
		end
	end,
    })
    Lifetime = Breadcrumbs:CreateSlider({
	Name = 'Lifetime',
	Min = 1,
	Max = 5,
	Default = 3,
	Decimal = 10,
	Function = function(val)
		if trail then
			trail.Lifetime = val
		end
	end,
	Suffix = function(val)
		return val == 1 and 'second' or 'seconds'
	end,
    })
    Thickness = Breadcrumbs:CreateSlider({
	Name = 'Thickness',
	Min = 0,
	Max = 2,
	Default = 0.1,
	Decimal = 100,
	Function = function(val)
		if point then
			point.Position = Vector3.new(0, val - 2.7, 0)
		end
		if point2 then
			point2.Position = Vector3.new(0, -val - 2.7, 0)
		end
	end,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end,
    })
end)
