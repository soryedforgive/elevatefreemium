run(function()
    local AimAssist
    local Targets
    local Part
    local FOV
    local Speed
    local CircleColor
    local CircleTransparency
    local CircleFilled
    local CircleThickness
    local CircleObject
    local RangeCircle
    local circleLibrary = vape.Libraries and vape.Libraries.fovcircle
    local RightClick
    local ShowTarget
    local moveConst = Vector2.new(1, 0.77) * math.rad(0.5)

    local function wrapAngle(num)
	num = num % math.pi
	num -= num >= (math.pi / 2) and math.pi or 0
	num += num < -(math.pi / 2) and math.pi or 0
	return num
    end

    AimAssist = vape.Categories.Combat:CreateModule({
	Name = 'AimAssist',    Function = function(callback)
		if callback then
			if type(mousemoverel) ~= 'function' then
				notif('AimAssist', 'Your executor has no mousemoverel, so AimAssist cannot move your aim here.', 6, 'warning')
				AimAssist:Toggle()
				return
			end
			local ent
			local rightClicked = not RightClick.Enabled or inputService:IsMouseButtonPressed(1)
			AimAssist:Clean(runService.RenderStepped:Connect(function(dt)
				if rightClicked and not vape.gui.ScaledGui.ClickGui.Visible then
					ent = entitylib.EntityMouse({
						Range = FOV.Value,
						Part = Part.Value,
						Players = Targets.Players.Enabled,
						Priority = Targets.Priority and Targets.Priority.Value,
						NPCs = Targets.NPCs.Enabled,
						Wallcheck = Targets.Walls.Enabled,
						Origin = gameCamera.CFrame.Position,
					})

					if ent then
						local facing = gameCamera.CFrame.LookVector
						local new = (ent[Part.Value].Position - gameCamera.CFrame.Position).Unit
						new = new == new and new or Vector3.zero

						if ShowTarget.Enabled then
							targetinfo.Targets[ent] = tick() + 1
						end

						if new ~= Vector3.zero then
							local diffYaw = wrapAngle(math.atan2(facing.X, facing.Z) - math.atan2(new.X, new.Z))
							local diffPitch = math.asin(facing.Y) - math.asin(new.Y)
							local angle = Vector2.new(diffYaw, diffPitch)
								// (moveConst * UserSettings():GetService('UserGameSettings').MouseSensitivity)

							angle *= math.min(Speed.Value * dt, 1)
							mousemoverel(angle.X, angle.Y)
						end
					end
				end
			end))

			if RightClick.Enabled then
				AimAssist:Clean(inputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton2 then
						ent = nil
						rightClicked = true
					end
				end))

				AimAssist:Clean(inputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton2 then
						rightClicked = false
					end
				end))
			end
		end
	end,
	Tooltip = 'Smoothly aims at the closest target',
    })
    Targets = AimAssist:CreateTargets({ Players = true })
    Part = AimAssist:CreateDropdown({
	Name = 'Part',
	List = { 'RootPart', 'Head' },
    })
    FOV = AimAssist:CreateSlider({
	Name = 'FOV',
	Min = 0,
	Max = 1000,
	Default = 100,
	Function = function(val)
		if CircleObject then
			CircleObject.Radius = val
		end
	end,
    })
    Speed = AimAssist:CreateSlider({
	Name = 'Speed',
	Min = 0,
	Max = 30,
	Default = 15,
    })    RangeCircle = AimAssist:CreateGroup({
		Name = 'Range Circle',
		Function = function(callback)
			if CircleObject then
				CircleObject:Destroy()
				CircleObject = nil
			end
			if callback and circleLibrary and circleLibrary.New then
				CircleObject = circleLibrary.New({
					Name = 'AimAssistFOV',
					Parent = vape.gui,
					Visible = function()
						return AimAssist.Enabled and RangeCircle.Enabled and not vape.gui.ScaledGui.ClickGui.Visible
					end,
					Radius = function()
						return FOV.Value
					end,
					Colour = function()
						return Color3.fromHSV(CircleColor.Hue, CircleColor.Sat, CircleColor.Value)
					end,
					Thickness = function()
						return CircleThickness.Value
					end,
					Transparency = function()
						return CircleTransparency.Value
					end,
					Filled = function()
						return CircleFilled.Enabled
					end
				})
			end
		end,
    })
    CircleColor = RangeCircle:CreateColorSlider({
		Name = 'Circle Colour',
		Function = function() end,
		Darker = true,
    })
    CircleTransparency = RangeCircle:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Decimal = 10,
		Default = 0.5,
		Darker = true,
    })
    CircleFilled = RangeCircle:CreateToggle({
		Name = 'Circle Filled',
		Darker = true,
    })
    CircleThickness = RangeCircle:CreateSlider({
		Name = 'Circle thickness',
		Min = 1,
		Max = 8,
		Default = 1,
		Darker = true,
		Tooltip = 'Width of the ring in pixels'
    })
    RightClick = AimAssist:CreateToggle({
	Name = 'Require right click',
	Function = function()
		if AimAssist.Enabled then
			AimAssist:Toggle()
			AimAssist:Toggle()
		end
	end,
    })
    ShowTarget = AimAssist:CreateToggle({
	Name = 'Show target info',
    })
end)
