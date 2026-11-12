run(function()
	local NoSlowdown
	local simulation = tribes.Simulation
	local humanoid, attributeConnection
	local applying = false
	local INPUTS = {Aim = true, Charge = true, Block = true, Reload = true, Use = true}

	gameapi.Patch(tribes.Combat, 'MoveSpeed', function(original)
		return function(id, aiming, charging, blocking, reloading, using)
			if not NoSlowdown or not NoSlowdown.Enabled then
				return original(id, aiming, charging, blocking, reloading, using)
			end
			return math.max(1, tonumber((original(id, false, false, false, false, false))) or 1), false
		end
	end)

	gameapi.Patch(simulation, 'SetInput', function(original)
		return function(name, value, ...)
			if NoSlowdown and NoSlowdown.Enabled and INPUTS[name] then
				return original(name, false, ...)
			end
			return original(name, value, ...)
		end
	end)

	local function neutralize()
		if not (NoSlowdown.Enabled and humanoid and humanoid.Parent) or applying then return end
		applying = true
		for name, value in humanoid:GetAttributes() do
			if name:sub(1, 9) == 'SpeedMult' and type(value) == 'number' and value >= 0 and value < 1 then
				humanoid:SetAttribute(name, 1)
			end
		end
		applying = false
	end

	local function detach()
		if attributeConnection then
			attributeConnection:Disconnect()
			attributeConnection = nil
		end
		humanoid = nil
	end

	local function attach(ent)
		detach()
		humanoid = ent and ent.Humanoid
		if not humanoid then return end
		attributeConnection = humanoid.AttributeChanged:Connect(neutralize)
		neutralize()
	end

	NoSlowdown = vape.Categories.Blatant:CreateModule({
		Name = 'NoSlowdown',
		Function = function(callback)
			if callback then
				if simulation then
					for name in INPUTS do
						pcall(simulation.SetInput, name, false)
					end
				end
				NoSlowdown:Clean(entitylib.Events.LocalAdded:Connect(attach))
				if entitylib.isAlive then
					attach(entitylib.character)
				end
			else
				detach()
			end
		end,
		Tooltip = 'Stops items and weapons slowing you down'
	})
end)
