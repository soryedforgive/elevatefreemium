run(function()
	local Killaura
	local Targets
	local AttackRange
	local AngleCheck
	local Max
	local Mouse
	local Limit
	local Swing
	local SwingOnly
	local BoxAttackColor
	local ParticleTexture
	local ParticleColor1
	local ParticleColor2
	local ParticleSize
	local Animation
	local AnimationMode
	local AnimationSpeed
	local AnimationTween
	local AnimTween
	local Attacking
	local Particles, Boxes = {}, {}
	local anims, armC0 = vape.Libraries.auraanims

	local function getAttackData()
		if Mouse.Enabled then
			if not inputService:IsMouseButtonPressed(0) then return false end
		end
		if SwingOnly.Enabled then
			local melee = skywars.MeleeController
			local data = melee and melee.characterAnimationData and melee.characterAnimationData[lplr.Character]
			if not (data and os.clock() - data.AnimationTime < 0.45) then return false end
		end

		return (not Limit.Enabled) and store.tools.sword or store.hand
	end

	Killaura = vape.Categories.Blatant:CreateModule({
		Name = 'Killaura',
		Function = function(callback)
			if callback then
				if Animation.Enabled then
					task.spawn(function()
						local started = false
						local asked = false
						repeat
							if not ViewmodelMotor and not asked and vape.Loaded then
								asked = true
								local viewmodel = vape.Legit and vape.Legit.Modules.Viewmodel
								if viewmodel and not viewmodel.Enabled then
									viewmodel:Toggle()
								end
							end
							if ViewmodelMotor then
								if Attacking then
									armC0 = CFrame.identity
									local first = not started
									started = true
									store.auraSwing = true

									if AnimationMode.Value == 'Random' then
										anims.Random = {{CFrame = CFrame.Angles(math.rad(math.random(1, 360)), math.rad(math.random(1, 360)), math.rad(math.random(1, 360))), Time = 0.12}}
									end

									for _, v in anims[AnimationMode.Value] do
										AnimTween = tweenService:Create(ViewmodelMotor, TweenInfo.new(first and (AnimationTween.Enabled and 0.001 or 0.1) or v.Time / AnimationSpeed.Value, Enum.EasingStyle.Linear), {
											C0 = armC0 * v.CFrame
										})
										AnimTween:Play()
										AnimTween.Completed:Wait()
										first = false
										if (not Killaura.Enabled) or (not Attacking) then break end
									end
								elseif started then
									started = false
									store.auraSwing = nil
									AnimTween = tweenService:Create(ViewmodelMotor, TweenInfo.new(AnimationTween.Enabled and 0.001 or 0.3, Enum.EasingStyle.Exponential), {
										C0 = armC0
									})
									AnimTween:Play()
								end
							end

							if not started then
								task.wait(1 / 60)
							end
						until (not Killaura.Enabled) or (not Animation.Enabled)
						store.auraSwing = nil
					end)
				end

				repeat
					local attacked = {}
					local tool = getAttackData()
					if tool and tool.Melee and entitylib.isAlive then
						local plrs = entitylib.AllPosition({
							Origin = realRoot().Position,
							Range = AttackRange.Value,
							Wallcheck = Targets.Walls.Enabled or nil,
							Part = 'RootPart',
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Limit = Max.Value
						})
						local struck = false
						local swung = false
						local held = store.attached
						if held and held.Targetable and held.RootPart and held.RootPart.Parent and not table.find(plrs, held) then
							table.insert(plrs, 1, held)
						end

						if #plrs > 0 then
							local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
							store.noShoot = tick() + 1

							for _, v in plrs do
								local delta = (v.RootPart.Position - entitylib.character.RootPart.Position)
								local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
								if angle > (math.rad(AngleCheck.Value) / 2) then continue end
								table.insert(attacked, v)
								targetinfo.Targets[v] = tick() + 1
								if #attacked == 1 and targetinfo.Focus then
									targetinfo.Focus[v] = tick() + 1
								end

								if strikeReady(v) then
									if not struck then
										struck = true
										equip(tool)
									end

									if not swung and not Swing.Enabled and not SwingOnly.Enabled then
										swung = true
										skywars.MeleeController:playAnimation(lplr.Character, tool)
									end

									if v.Player then
										fireRemote('strike', v.Player)
									else
										fireRemote('strikeEntity', v.Character)
									end
								end
							end
						end

						if struck and not store.autoWin then
							equip(nil)
						end
					end

					Attacking = #attacked > 0
					if Attacking and vape.ThreadFix then
						setthreadidentity(8)
					end

					for i, v in Boxes do
						local adornee = attacked[i] and attacked[i].RootPart or nil
						if v.Adornee ~= adornee then
							v.Adornee = adornee
						end
						if adornee then
							local boxColour = Color3.fromHSV(BoxAttackColor.Hue, BoxAttackColor.Sat, BoxAttackColor.Value)
							if v.Color3 ~= boxColour then
								v.Color3 = boxColour
							end
							if v.Transparency ~= 1 - BoxAttackColor.Opacity then
								v.Transparency = 1 - BoxAttackColor.Opacity
							end
						end
					end

					for i, v in Particles do
						if attacked[i] then
							v.Position = attacked[i].RootPart.Position
							if v.Parent ~= gameCamera then
								v.Parent = gameCamera
							end
						elseif v.Parent then
							v.Position = Vector3.new(9e9, 9e9, 9e9)
							v.Parent = nil
						end
					end

					runService.Heartbeat:Wait()
				until not Killaura.Enabled
			else
				Attacking = false
				for _, v in Boxes do
					v.Adornee = nil
				end
				for _, v in Particles do
					v.Parent = nil
				end
				if armC0 and ViewmodelMotor then
					AnimTween = tweenService:Create(ViewmodelMotor, TweenInfo.new(AnimationTween.Enabled and 0.001 or 0.3, Enum.EasingStyle.Exponential), {
						C0 = armC0
					})
					AnimTween:Play()
				end
			end
		end,
		Tooltip = 'Attacks players around you without aiming'
	})
	Targets = Killaura:CreateTargets({Players = true})
	AttackRange = Killaura:CreateSlider({
		Name = 'Attack range',
		Min = 1,
		Max = 18,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AngleCheck = Killaura:CreateSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 360
	})
	Max = Killaura:CreateSlider({
		Name = 'Max targets',
		Min = 1,
		Max = 10,
		Default = 10
	})
	Mouse = Killaura:CreateToggle({Name = 'Require mouse down'})
	Swing = Killaura:CreateToggle({Name = 'No Swing'})
	SwingOnly = Killaura:CreateToggle({
		Name = 'Swing only',
		Tooltip = 'Only attacks while swinging manually'
	})
	local ShowTargetGroup = Killaura:CreateGroup({
		Name = 'Show target',
		Function = function(callback)
			if callback then
				for i = 1, 10 do
					local box = Instance.new('BoxHandleAdornment')
					box.Adornee = nil
					box.AlwaysOnTop = true
					box.Size = Vector3.new(3, 5, 3)
					box.CFrame = CFrame.new(0, -0.5, 0)
					box.ZIndex = 0
					box.Parent = vape.gui
					Boxes[i] = box
				end
			else
				for _, v in Boxes do
					v:Destroy()
				end
				table.clear(Boxes)
			end
		end
	})
	BoxAttackColor = ShowTargetGroup:CreateColorSlider({
		Name = 'Attack Color',
		Darker = true,
		DefaultOpacity = 0.5
	})
	local TargetParticlesGroup = Killaura:CreateGroup({
		Name = 'Target particles',
		Function = function(callback)
			if callback then
				for i = 1, 10 do
					local part = Instance.new('Part')
					part.Size = Vector3.new(2, 4, 2)
					part.Anchored = true
					part.CanCollide = false
					part.Transparency = 1
					part.CanQuery = false
					part.Parent = Killaura.Enabled and gameCamera or nil
					local particles = Instance.new('ParticleEmitter')
					particles.Brightness = 1.5
					particles.Size = NumberSequence.new(ParticleSize.Value)
					particles.Shape = Enum.ParticleEmitterShape.Sphere
					particles.Texture = ParticleTexture.Value
					particles.Transparency = NumberSequence.new(0)
					particles.Lifetime = NumberRange.new(0.4)
					particles.Speed = NumberRange.new(16)
					particles.Rate = 128
					particles.Drag = 16
					particles.ShapePartial = 1
					particles.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
					})
					particles.Parent = part
					Particles[i] = part
				end
			else
				for _, v in Particles do
					v:Destroy()
				end
				table.clear(Particles)
			end
		end
	})
	ParticleTexture = TargetParticlesGroup:CreateTextBox({
		Name = 'Texture',
		Default = 'rbxassetid://14736249347',
		Function = function()
			for _, v in Particles do
				v.ParticleEmitter.Texture = ParticleTexture.Value
			end
		end,
		Darker = true
	})
	ParticleColor1 = TargetParticlesGroup:CreateColorSlider({
		Name = 'Color Begin',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, sat, val)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
				})
			end
		end,
		Darker = true
	})
	ParticleColor2 = TargetParticlesGroup:CreateColorSlider({
		Name = 'Color End',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, sat, val))
				})
			end
		end,
		Darker = true
	})
	ParticleSize = TargetParticlesGroup:CreateSlider({
		Name = 'Size',
		Min = 0,
		Max = 1,
		Default = 0.14,
		Decimal = 100,
		Function = function(val)
			for _, v in Particles do
				v.ParticleEmitter.Size = NumberSequence.new(val)
			end
		end,
		Darker = true
	})
	Animation = Killaura:CreateGroup({
		Name = 'Custom Animation',
		Function = function(callback)
			if Killaura.Enabled then
				Killaura:Toggle()
				Killaura:Toggle()
			end
		end,
		Tooltip = 'Animates your first person arms while attacking'
	})
	local animnames = {}
	for i in anims do
		table.insert(animnames, i)
	end
	AnimationMode = Animation:CreateDropdown({
		Name = 'Animation Mode',
		List = animnames,
		Darker = true
	})
	AnimationSpeed = Animation:CreateSlider({
		Name = 'Animation Speed',
		Min = 0,
		Max = 2,
		Default = 1,
		Decimal = 10,
		Darker = true
	})
	AnimationTween = Animation:CreateToggle({
		Name = 'No Tween',
		Darker = true
	})
	Limit = Killaura:CreateToggle({
		Name = 'Limit to items',
		Tooltip = 'Only works while holding the item it uses'
	})
end)
