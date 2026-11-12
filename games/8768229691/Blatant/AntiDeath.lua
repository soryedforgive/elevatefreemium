run(function()
	local AntiDeath
	local Threshold
	local Height
	local MaxTime
	local PowerUps
	local BuyAdrenaline
	local VoidSave
	local Notify
	local platform
	local escape
	local lastGround
	local cooldown = 0
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Include

	local function health()
		return lplr:GetAttribute('Health') or 100
	end

	local function blockRay(origin, distance)
		local container = workspace:FindFirstChild('BlockContainer')
		if not container then return nil end
		rayCheck.FilterDescendantsInstances = {container}
		return workspace:Raycast(origin, Vector3.new(0, -distance, 0), rayCheck)
	end

	local function lowestBlock()
		return voidFloor() + 12
	end

	local function moveTo(position)
		local root = bodyRoot()
		root.CFrame = CFrame.new(position) * (root.CFrame - root.CFrame.Position)
		root.AssemblyLinearVelocity = Vector3.zero
	end

	local function usePowerUp(name)
		local meta = skywars.ItemMeta[name]
		local active = skywars.Store:getState().PowerUps
		if getItem(name) and meta and meta.PowerUp and not (active and active[meta.PowerUp.Type]) and not skywars.CooldownController:isOnCooldown(name) then
			fireRemote('updateActiveItem', name)
			fireRemote('usePowerUp')
			equip(nil)
			return true
		end
		return false
	end

	local function buyAdrenaline()
		local active = skywars.Store:getState().PowerUps
		if getItem('Adrenaline') or (active and active.Adrenaline) or skywars.CooldownController:isOnCooldown('Adrenaline') then return end
		local currency = skywars.Store:getState().GameCurrency
		for _, shopItem in skywars.Shop.Blacksmith.Items do
			if shopItem.ItemType == 'Adrenaline' then
				if currency and (currency.Quantities[shopItem.CurrencyType] or 0) >= shopItem.Price then
					fireRemote('purchaseItem', 'Blacksmith', shopItem.ItemIndex)
					local started = tick()
					repeat task.wait() until getItem('Adrenaline') or tick() - started > 1.5 or not AntiDeath.Enabled
					usePowerUp('Adrenaline')
				end
				break
			end
		end
	end

	local function usePowerUps()
		usePowerUp('Shield')
		if not usePowerUp('Adrenaline') and BuyAdrenaline.Enabled then
			task.spawn(buyAdrenaline)
		end
	end

	local function land()
		local state = escape
		escape = nil
		store.antiDeath = nil
		if platform then
			platform:Destroy()
			platform = nil
		end
		if not (state and entitylib.isAlive) then return end
		local root = bodyRoot()
		local hit = blockRay(root.Position, 500)
		if hit then
			moveTo(hit.Position + Vector3.new(0, entitylib.character.HipHeight + 0.2, 0))
		else
			moveTo(state.Origin)
		end
	end

	local function takeOff()
		local root = bodyRoot()
		local top = root.Position.Y + Height.Value
		escape = {
			Origin = lastGround or root.Position,
			Started = tick(),
			Y = top
		}
		store.antiDeath = true
		platform = Instance.new('Part')
		platform.Name = 'AetherAntiDeath'
		platform.Size = Vector3.new(16, 1, 16)
		platform.Anchored = true
		platform.CanQuery = false
		platform.Transparency = 0.7
		platform.Material = Enum.Material.ForceField
		platform.Color = Color3.fromRGB(99, 220, 130)
		platform.CFrame = CFrame.new(root.Position.X, top - entitylib.character.HipHeight - 0.5, root.Position.Z)
		platform.Parent = workspace
		moveTo(Vector3.new(root.Position.X, top, root.Position.Z))
		if PowerUps.Enabled then
			usePowerUps()
		end
		if Notify.Enabled then
			notif('AntiDeath', 'Low health, moved you '..Height.Value..' studs up.', 4, 'warning')
		end
	end

	AntiDeath = vape.Categories.Blatant:CreateModule({
		Name = 'AntiDeath',
		Function = function(callback)
			if callback then
				AntiDeath:Clean(entitylib.Events.LocalRemoved:Connect(function()
					escape = nil
					store.antiDeath = nil
					lastGround = nil
					if platform then
						platform:Destroy()
						platform = nil
					end
				end))
				AntiDeath:Clean(runService.Heartbeat:Connect(function()
					if not entitylib.isAlive or outranked('antiDeath') then return end
					local root = bodyRoot()
					local hum = entitylib.character.Humanoid

					if escape then
						if platform then
							platform.CFrame = CFrame.new(root.Position.X, platform.Position.Y, root.Position.Z)
						end
						if root.Position.Y < escape.Y - 12 then
							moveTo(Vector3.new(root.Position.X, escape.Y, root.Position.Z))
						end
						if tick() - escape.Started > MaxTime.Value or health() > math.min(Threshold.Value + 25, 99) then
							cooldown = tick() + 3
							land()
						end
						return
					end

					if hum.FloorMaterial ~= Enum.Material.Air and blockRay(root.Position, entitylib.character.HipHeight + 3) then
						lastGround = root.Position
					end

					if VoidSave.Enabled and lastGround and root.AssemblyLinearVelocity.Y < -10 then
						local low = lowestBlock()
						if low ~= math.huge and root.Position.Y < low - 12 and not blockRay(root.Position, 500) then
							moveTo(lastGround + Vector3.new(0, 1, 0))
							if Notify.Enabled then
								notif('AntiDeath', 'Saved you from the void.', 3, 'warning')
							end
							return
						end
					end

					if health() <= Threshold.Value and health() > 0 and cooldown < tick() then
						takeOff()
					end
				end))
			else
				land()
			end
		end,
		Tooltip = 'Moves you out of reach when low and saves you from the void'
	})
	Threshold = AntiDeath:CreateSlider({
		Name = 'HP Threshold',
		Min = 1,
		Max = 90,
		Default = 30,
		Suffix = 'hp'
	})
	Height = AntiDeath:CreateSlider({
		Name = 'Height',
		Min = 20,
		Max = 150,
		Default = 60,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	MaxTime = AntiDeath:CreateSlider({
		Name = 'Max time',
		Min = 2,
		Max = 30,
		Default = 10,
		Suffix = 's',
		Tooltip = 'How long you stay up before it brings you down'
	})
	PowerUps = AntiDeath:CreateGroup({
		Name = 'Use power-ups',
		Default = true,
		Tooltip = 'Uses shields and adrenaline right away'
	})
	BuyAdrenaline = PowerUps:CreateToggle({
		Name = 'Buy adrenaline',
		Default = true,
		Darker = true,
		Tooltip = 'Buys and uses an Adrenaline when you have none'
	})
	VoidSave = AntiDeath:CreateToggle({
		Name = 'Void save',
		Default = true,
		Tooltip = 'Teleports you back when you fall under the map'
	})
	Notify = AntiDeath:CreateToggle({
		Name = 'Notify',
		Default = true
	})
end)
