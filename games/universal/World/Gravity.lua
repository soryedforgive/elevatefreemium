run(function()
    local Gravity
    local Mode
    local Value
    local old

    Gravity = vape.Categories.World:CreateModule({
	Name = 'Gravity',
	Function = function(callback)
		if callback then
			if Mode.Value == 'Workspace' then
				old = workspace.Gravity
				workspace.Gravity = Value.Value
				Gravity:Clean(workspace:GetPropertyChangedSignal('Gravity'):Connect(function()
					local current = workspace.Gravity
					if math.abs(current - Value.Value) < 0.01 then return end
					old = current
					workspace.Gravity = Value.Value
				end))
			else
				Gravity:Clean(runService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive and entitylib.character.Humanoid.FloorMaterial == Enum.Material.Air then
						local root = entitylib.character.RootPart
						if Mode.Value == 'Impulse' then
							root:ApplyImpulse(
								Vector3.new(0, dt * (workspace.Gravity - Value.Value), 0) * root.AssemblyMass
							)
						else
							root.AssemblyLinearVelocity += Vector3.new(0, dt * (workspace.Gravity - Value.Value), 0)
						end
					end
				end))
			end
		else
			if old then
				workspace.Gravity = old
				old = nil
			end
		end
	end,
	ExtraText = function()
		return Mode.Value
	end,
	Tooltip = 'Changes how fast you fall',
    })
    Mode = Gravity:CreateDropdown({
	Name = 'Mode',
	List = { 'Workspace', 'Velocity', 'Impulse' },
	Function = function()
		if Gravity.Enabled then
			Gravity:Toggle()
			Gravity:Toggle()
		end
	end,
	Tooltip = 'How your gravity is changed',
    })
    Value = Gravity:CreateSlider({
	Name = 'Gravity',
	Min = 0,
	Max = 200,
	Function = function(val)
		if Gravity.Enabled and Mode.Value == 'Workspace' then
			workspace.Gravity = val
		end
	end,
	Default = 192,
    })
    Gravity:CreateButton({
	Name = 'Reset to default gravity',
	Tooltip = 'Sets gravity back to the game\'s default',
	Function = function()
		Value:SetValue(old or 196.2)
	end,
    })
end)
