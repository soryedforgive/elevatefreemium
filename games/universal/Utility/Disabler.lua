run(function()
    local Disabler

    local function silence(signal)
	local ok, connections = pcall(getconnections, signal)
	if not ok or type(connections) ~= 'table' then return end
	for _, v in connections do
		local func = v.Function
		if type(func) == 'function' then
			local ours = type(isexecutorclosure) == 'function' and isexecutorclosure(func)
			if not ours then
				pcall(hookfunction, func, function() end)
			end
		end
	end
    end

    local function characterAdded(char)
	silence(char.RootPart:GetPropertyChangedSignal('CFrame'))
	silence(char.RootPart:GetPropertyChangedSignal('Velocity'))
    end

    Disabler = vape.Categories.Utility:CreateModule({
	Name = 'Disabler',
	Function = function(callback)
		if callback then
			if type(getconnections) ~= 'function' or type(hookfunction) ~= 'function' then
				notif('Disabler', 'Your executor is missing getconnections or hookfunction, so Disabler cannot work here.', 6, 'warning')
				Disabler:Toggle()
				return
			end
			Disabler:Clean(entitylib.Events.LocalAdded:Connect(characterAdded))
			if entitylib.isAlive then
				characterAdded(entitylib.character)
			end
		end
	end,
	Tooltip = 'Hides your movement from the game\'s checks until you respawn',
    })
end)
