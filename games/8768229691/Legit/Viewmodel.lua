run(function()
	local Viewmodel
	local oldtool
	local swinging = false
	local stamp
	local lastTool, lastFirst
	local anims = vape.Libraries.auraanims

	local function clearTool()
		if oldtool and oldtool:FindFirstChild('Handle') then
			oldtool.Handle.LocalTransparencyModifier = 0
		end
		if ViewmodelTool then
			ViewmodelTool:Destroy()
		end
		ViewmodelTool = nil
		oldtool = nil
	end

	local function setTool(obj)
		local handle = obj:FindFirstChild('Handle') or obj:WaitForChild('Handle', 2)
		if not (handle and Viewmodel.Enabled) then return end
		clearTool()
		oldtool = obj
		ViewmodelTool = handle:Clone()
		ViewmodelTool.CanCollide = false
		ViewmodelTool.Massless = true
		ViewmodelTool.Anchored = true
		ViewmodelTool:ClearAllChildren()
		ViewmodelTool.Parent = gameCamera
		ViewmodelTool.LocalTransparencyModifier = 0
		handle.LocalTransparencyModifier = 1
	end

	local function swing()
		if swinging or store.auraSwing or not ViewmodelMotor then return end
		swinging = true
		local motor = ViewmodelMotor
		task.spawn(function()
			for _, v in anims.Normal do
				if ViewmodelMotor ~= motor or store.auraSwing then break end
				local tween = tweenService:Create(motor, TweenInfo.new(v.Time, Enum.EasingStyle.Linear), {
					C0 = v.CFrame
				})
				tween:Play()
				tween.Completed:Wait()
			end
			if ViewmodelMotor == motor and not store.auraSwing then
				tweenService:Create(motor, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {
					C0 = CFrame.identity
				}):Play()
			end
			swinging = false
		end)
	end

	local function newCharacter(char)
		Viewmodel:Clean(char.Character.ChildAdded:Connect(function(obj)
			if obj:IsA('Tool') then
				setTool(obj)
			end
		end))

		Viewmodel:Clean(char.Character.ChildRemoved:Connect(function(obj)
			if obj == oldtool then
				clearTool()
			end
		end))

		local tool = char.Character:FindFirstChildOfClass('Tool')
		if tool then
			setTool(tool)
		end
	end

	Viewmodel = vape.Legit:CreateModule({
		Name = 'Viewmodel',
		Function = function(callback)
			if callback then
				ViewmodelMotor = Instance.new('Motor6D')
				Viewmodel:Clean(ViewmodelMotor)
				Viewmodel:Clean(runService.RenderStepped:Connect(function()
					local melee = skywars.MeleeController
					local data = melee and melee.characterAnimationData and melee.characterAnimationData[lplr.Character]
					local swung = data and data.AnimationTime
					if swung ~= stamp then
						if stamp and swung then
							swing()
						end
						stamp = swung
					end
					if ViewmodelTool and ViewmodelMotor then
						local first = (gameCamera.CFrame.Position - gameCamera.Focus.Position).Magnitude < 1
						if ViewmodelTool ~= lastTool or first ~= lastFirst then
							lastTool, lastFirst = ViewmodelTool, first
							ViewmodelTool.LocalTransparencyModifier = first and 0 or 1
						end
						local handle = oldtool and oldtool:FindFirstChild('Handle')
						if handle then
							local hidden = first and 1 or 0
							if handle.LocalTransparencyModifier ~= hidden then
								handle.LocalTransparencyModifier = hidden
							end
						end
						if not first then return end
						local dcf = ((CFrame.new(2.06, -2.44, -2.24) * CFrame.new(0.6, -0.2, -0.6)) * CFrame.Angles(math.rad(99), math.rad(2), math.rad(-4))) * ViewmodelMotor.C0
						local offsetcf = (CFrame.new(0, -0.15, -1.56) * CFrame.Angles(math.rad(-90), math.rad(-90), 0))
						ViewmodelTool.CFrame = ((gameCamera.CFrame * dcf) * offsetcf)
					end
				end))
				Viewmodel:Clean(entitylib.Events.LocalAdded:Connect(newCharacter))
				if entitylib.isAlive then
					newCharacter(entitylib.character)
				end
			else
				clearTool()
				ViewmodelMotor = nil
			end
		end,
		Tooltip = 'Changes how the item you hold looks and moves'
	})
end)
