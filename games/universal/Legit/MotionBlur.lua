run(function()
	local MotionBlur
	local MotionBlurStrength
	local motionBlurEffect = nil
	local lastLookVector = gameCamera.CFrame.LookVector
	local motionBlurConn = nil

	MotionBlur = vape.Categories.Legit:CreateModule({
		Name = 'MotionBlur',
		Function = function(callback)
			if callback then
				motionBlurEffect = Instance.new('BlurEffect')
				motionBlurEffect.Size = 0
				motionBlurEffect.Parent = gameCamera
				lastLookVector = gameCamera.CFrame.LookVector
				motionBlurConn = runService.RenderStepped:Connect(function(dt)
					local currentLook = gameCamera.CFrame.LookVector
					local delta = (currentLook - lastLookVector).Magnitude
					lastLookVector = currentLook
					dt = math.clamp(dt, 1 / 1000, 0.1)
					local targetSize = math.clamp((delta / dt) * (MotionBlurStrength.Value / 3), 0, 24)
					local ease = 1 - 0.7 ^ (dt * 60)
					motionBlurEffect.Size = motionBlurEffect.Size + (targetSize - motionBlurEffect.Size) * ease
				end)
			else
				if motionBlurConn then
					motionBlurConn:Disconnect()
					motionBlurConn = nil
				end
				if motionBlurEffect then
					motionBlurEffect:Destroy()
					motionBlurEffect = nil
				end
			end
		end,
		Tooltip = 'Blurs the screen as you turn the camera'
	})

	MotionBlurStrength = MotionBlur:CreateSlider({
		Name = 'Strength',
		Min = 0,
		Max = 10,
		Default = 3,
		Decimal = 10,
	})
end)
