run(function()
	local Breaker
	local Range
	local BreakerPart
	local BreakerBar
	local Teleport
	local Hover = {Object = {}, Value = 20}
	local trip, hop
	local skipped = setmetatable({}, {__mode = 'k'})
	local SERVER = 21

	local function endHop()
		if not hop then return end
		hop = nil
		if not trip then
			store.breakerTrip = nil
		end
		mergeRoot('Breaker')
	end

	local function hopTo(egg)
		if Teleport.Enabled or outranked('breakerTrip') or not splitRoot('Breaker') then
			endHop()
			return
		end
		hop = egg
		store.breakerTrip = true
		local height = store.hand.Pickaxe and Hover.Value or math.min(Hover.Value, 14)
		sendRoot(egg.PrimaryPart.Position + Vector3.new(0, height, 0))
	end

	local function endTrip(stay)
		local state = trip
		trip = nil
		store.breakerTrip = hop and true or nil
		if not state then return end
		if state.Switched then
			equip(nil)
		end
		if not stay and entitylib.isAlive and not store.split and not outranked('breakerTrip') then
			sendRoot(state.Home)
		end
	end

	local function nextEgg(eggs, origin)
		local best, bestDistance
		for _, v in eggs do
			if v.PrimaryPart and (v:GetAttribute('Health') or 0) > 0 and v:GetAttribute('TeamId') ~= lplr:GetAttribute('TeamId') and (skipped[v] or 0) < tick() then
				local distance = (v.PrimaryPart.Position - origin).Magnitude
				if not bestDistance or distance < bestDistance then
					best, bestDistance = v, distance
				end
			end
		end
		return best
	end

	local function teleportStep(eggs)
		if not Teleport.Enabled then
			endTrip()
			return
		end
		if not entitylib.isAlive or outranked('breakerTrip') then
			endTrip(true)
			return
		end
		local pick, sword = store.tools.pickaxe, store.tools.sword
		local tool = pick or sword
		if not tool then
			endTrip()
			return
		end
		local root = realRoot()
		if not trip then
			local egg = nextEgg(eggs, root.Position)
			if not egg then return end
			trip = {Home = bodyRoot().Position, Egg = egg, Started = tick(), Strike = 0}
			store.breakerTrip = true
		end

		local egg = trip.Egg
		if not (egg.Parent and egg.PrimaryPart) or (egg:GetAttribute('Health') or 0) <= 0 or tick() - trip.Started > 8 then
			if egg.Parent and (egg:GetAttribute('Health') or 0) > 0 then
				skipped[egg] = tick() + 20
			end
			egg = nextEgg(eggs, trip.Home)
			if not egg then
				endTrip()
				return
			end
			trip.Egg, trip.Started = egg, tick()
		end

		local position = egg.PrimaryPart.Position
		local height = pick and Hover.Value or math.min(Hover.Value, 14)
		sendRoot(position + Vector3.new(0, height, 0))
		store.noShoot = tick() + 1
		trip.Switched = true
		equip(tool)
		if pick then
			fireRemote('hitBlock', (position + Vector3.new(0, 1.5, 0)) // 1)
		elseif trip.Strike < tick() then
			trip.Strike = tick() + 0.1
			fireRemote('strikeEntity', egg)
		end
	end

	local function clean()
		if BreakerPart then
			BreakerPart:Destroy()
		end
		BreakerPart = nil
		BreakerBar = nil
	end

	local function customHealthbar(block, health, maxHealth, changeHealth)
		if not BreakerPart then
			local percent = math.clamp(health / maxHealth, 0, 1)
			local part = Instance.new('Part')
			part.Size = Vector3.one
			part.CFrame = block.PrimaryPart.CFrame
			part.Transparency = 1
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.Parent = workspace
			BreakerPart = part

			local billboard = Instance.new('BillboardGui')
			billboard.Size = UDim2.fromOffset(249, 102)
			billboard.StudsOffset = Vector3.new(0, 2.5, 0)
			billboard.Adornee = part
			billboard.MaxDistance = 40
			billboard.AlwaysOnTop = true
			billboard.Parent = part
			local frame = Instance.new('Frame')
			frame.Size = UDim2.fromOffset(160, 50)
			frame.Position = UDim2.fromOffset(44, 32)
			frame.BackgroundColor3 = Color3.new()
			frame.BackgroundTransparency = 0.5
			frame.Parent = billboard
			local corner = Instance.new('UICorner')
			corner.CornerRadius = UDim.new(0, 5)
			corner.Parent = frame
			local blur = Instance.new('ImageLabel')
			blur.Size = UDim2.new(1, 89, 1, 52)
			blur.Position = UDim2.fromOffset(-48, -31)
			blur.BackgroundTransparency = 1
			blur.Image = getcustomasset('ElevateV4/assets/new/blur.png')
			blur.ScaleType = Enum.ScaleType.Slice
			blur.SliceCenter = Rect.new(52, 31, 261, 502)
			blur.Parent = frame
			for i, textColor in {Color3.new(), color.Dark(uipallet.Text, 0.16)} do
				local label = Instance.new('TextLabel')
				label.Size = UDim2.fromOffset(145, 14)
				label.Position = UDim2.fromOffset(14 - i, 13 - i)
				label.BackgroundTransparency = 1
				label.Text = (block:GetAttribute('TeamId') or '')..' '..block.Name
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.TextYAlignment = Enum.TextYAlignment.Top
				label.TextColor3 = textColor
				label.TextScaled = true
				label.Font = Enum.Font.Arial
				label.Parent = frame
			end
			local back = Instance.new('Frame')
			back.Size = UDim2.fromOffset(138, 4)
			back.Position = UDim2.fromOffset(12, 32)
			back.BackgroundColor3 = uipallet.Main
			back.BorderSizePixel = 0
			back.Parent = frame
			local backCorner = Instance.new('UICorner')
			backCorner.CornerRadius = UDim.new(1, 0)
			backCorner.Parent = back
			local bar = Instance.new('Frame')
			bar.Size = UDim2.fromScale(percent, 1)
			bar.BackgroundColor3 = Color3.fromHSV(math.clamp(percent / 2.5, 0, 1), 0.89, 0.75)
			bar.BorderSizePixel = 0
			bar.Parent = back
			local barCorner = Instance.new('UICorner')
			barCorner.CornerRadius = UDim.new(1, 0)
			barCorner.Parent = bar
			BreakerBar = bar

			task.delay(5, function()
				if BreakerPart == part then
					clean()
				end
			end)
		end

		local progress = math.clamp((health - changeHealth) / maxHealth, 0, 1)
		if progress == 0 then
			clean()
			return
		end

		if BreakerBar then
			tweenService:Create(BreakerBar, TweenInfo.new(0.3), {
				Size = UDim2.fromScale(progress, 1),
				BackgroundColor3 = Color3.fromHSV(math.clamp(progress / 2.5, 0, 1), 0.89, 0.75)
			}):Play()
		end
	end

	Breaker = vape.Categories.World:CreateModule({
		Name = 'Breaker',
		Function = function(callback)
			if callback then
				local eggs = collection('egg', Breaker)
				local currentblock
				local oldblockhealth = 0
				Breaker:Clean(entitylib.Events.LocalRemoved:Connect(function()
					trip = nil
					hop = nil
					store.breakerTrip = nil
				end))
				Breaker:Clean(runService.Heartbeat:Connect(function()
					teleportStep(eggs)
				end))

				repeat
					if entitylib.isAlive and store.hand then
						local localPosition = realRoot().Position
						local bodyPosition = bodyRoot().Position
						local far, farDistance
						for _, v in eggs do
							if v.PrimaryPart and (bodyPosition - v.PrimaryPart.Position).Magnitude < Range.Value then
								local hp = v:GetAttribute('Health') or 0
								if v:GetAttribute('TeamId') == lplr:GetAttribute('TeamId') then continue end
								if (localPosition - v.PrimaryPart.Position).Magnitude > SERVER then
									local distance = (bodyPosition - v.PrimaryPart.Position).Magnitude
									if hp > 0 and (v == hop or not farDistance or distance < farDistance) then
										far, farDistance = v, v == hop and 0 or distance
									end
									continue
								end
								if currentblock ~= v then
									oldblockhealth = hp
									currentblock = v
								end

								if hp ~= oldblockhealth then
									customHealthbar(v, oldblockhealth, 100, oldblockhealth - hp)
									oldblockhealth = hp
								end

								store.noShoot = tick() + 1
								if hp <= 0 then continue end

								if store.hand.Melee then
									fireRemote('strikeEntity', v)
								elseif store.hand.Pickaxe then
									fireRemote('hitBlock', (v.PrimaryPart.Position + Vector3.new(0, 1.5, 0)) // 1)
								end
							end
						end

						local target = hop and hop.PrimaryPart and (hop:GetAttribute('Health') or 0) > 0 and (bodyPosition - hop.PrimaryPart.Position).Magnitude < Range.Value and hop or far
						if target and (store.hand.Melee or store.hand.Pickaxe) then
							hopTo(target)
						else
							endHop()
						end
					else
						endHop()
					end

					task.wait(0.016)
				until not Breaker.Enabled
			else
				endHop()
				endTrip()
				clean()
			end
		end,
		Tooltip = 'Breaks eggs around you'
	})
	Range = Breaker:CreateSlider({
		Name = 'Break range',
		Min = 1,
		Max = 1000,
		Default = SERVER,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How far away a block can be mined'
	})
	Breaker:CreateButton({
		Name = 'Reset to default range',
		Tooltip = 'Sets the range back to the game\'s default',
		Function = function()
			Range:SetValue(SERVER)
		end
	})
	Teleport = Breaker:CreateGroup({
		Name = 'Teleport',
		Tooltip = 'Goes to enemy eggs across the map to mine them'
	})
	Hover = Teleport:CreateSlider({
		Name = 'Hover height',
		Min = 8,
		Max = 22,
		Default = 20,
		Darker = true,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How far above an egg you stay'
	})
end)
