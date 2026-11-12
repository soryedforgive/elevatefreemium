run(function()
	local PromptEditor
	local Mode
	local Range
	local Hold
	local Instant
	local ThroughWalls
	local environment = (getgenv and getgenv()) or _G
	local api = environment.AetherInteractExtender or {}

	local originals = environment.__AetherPromptEditorOriginals
	if type(originals) ~= 'table' then
		originals = setmetatable({}, {__mode = 'k'})
		environment.__AetherPromptEditorOriginals = originals
	end
	local applying = setmetatable({}, {__mode = 'k'})
	local MAX_DISTANCE = 1000

	local ATTR_DISTANCE = 'AetherPromptDistance'
	local ATTR_DURATION = 'AetherPromptDuration'
	local ATTR_SIGHT = 'AetherPromptSight'

	local function remember(prompt)
		if originals[prompt] then return true end
		local ok, state = pcall(function()
			local distance = prompt:GetAttribute(ATTR_DISTANCE)
			if type(distance) == 'number' then
				return {
					Distance = distance,
					Duration = prompt:GetAttribute(ATTR_DURATION) or prompt.HoldDuration,
					Sight = prompt:GetAttribute(ATTR_SIGHT)
				}
			end
			local real = {
				Distance = prompt.MaxActivationDistance,
				Duration = prompt.HoldDuration,
				Sight = prompt.RequiresLineOfSight
			}
			prompt:SetAttribute(ATTR_DISTANCE, real.Distance)
			prompt:SetAttribute(ATTR_DURATION, real.Duration)
			prompt:SetAttribute(ATTR_SIGHT, real.Sight)
			return real
		end)
		if ok then
			if type(state.Sight) ~= 'boolean' then state.Sight = true end
			originals[prompt] = state
		end
		return ok
	end

	local function applyPrompt(prompt)
		if not PromptEditor or not PromptEditor.Enabled then return end
		if typeof(prompt) ~= 'Instance' or not prompt:IsA('ProximityPrompt') or not remember(prompt) then return end
		local original = originals[prompt]
		local range = tonumber(Range and Range.Value) or original.Distance or 10
		local distance = (Mode and Mode.Value == 'Expand') and (original.Distance + range) or range
		applying[prompt] = true
		pcall(function()
			prompt.MaxActivationDistance = math.clamp(distance, 0, MAX_DISTANCE)
			prompt.HoldDuration = Instant.Enabled and 0 or Hold.Value
			prompt.RequiresLineOfSight = not ThroughWalls.Enabled
		end)
		applying[prompt] = nil
	end

	local function restorePrompt(prompt, original)
		if not prompt or not prompt.Parent or not original then return end
		applying[prompt] = true
		pcall(function()
			prompt.MaxActivationDistance = original.Distance
			prompt.HoldDuration = original.Duration
			prompt.RequiresLineOfSight = original.Sight
		end)
		applying[prompt] = nil
	end

	local function refresh()
		if not PromptEditor or not PromptEditor.Enabled then return end
		for prompt in originals do
			if prompt.Parent then applyPrompt(prompt) end
		end
	end


	api.IsEnabled = function()
		return PromptEditor and PromptEditor.Enabled == true
	end
	api.Activate = function(prompt)
		if not api.IsEnabled() then return false, 'PromptEditor is disabled' end
		if typeof(prompt) ~= 'Instance' or not prompt:IsA('ProximityPrompt') then return false, 'invalid prompt' end
		applyPrompt(prompt)
		if type(fireproximityprompt) ~= 'function' then return false, 'fireproximityprompt unavailable' end
		local ok, result = pcall(fireproximityprompt, prompt)
		return ok and result ~= false, ok and nil or tostring(result)
	end
	environment.AetherInteractExtender = api
	vape:Clean(function()
		if environment.AetherInteractExtender == api then environment.AetherInteractExtender = nil end
	end)

	PromptEditor = vape.Categories.World:CreateModule({
		Name = 'PromptEditor',
		Tooltip = 'Changes prompt range, hold time and line of sight',
		Function = function(callback)
			if callback then
				PromptEditor:Clean(workspace.DescendantAdded:Connect(applyPrompt))
				PromptEditor:Clean(proximityPromptService.PromptShown:Connect(applyPrompt))
				for _, prompt in workspace:GetDescendants() do applyPrompt(prompt) end
			else
				for prompt, original in originals do restorePrompt(prompt, original) end
				table.clear(applying)
			end
		end
	})
	Mode = PromptEditor:CreateDropdown({Name = 'Mode', List = {'Set', 'Expand'}, Function = refresh})
	Range = PromptEditor:CreateSlider({Name = 'Range', Min = 1, Max = 100, Default = 32, Suffix = ' studs', Function = refresh})
	Hold = PromptEditor:CreateSlider({Name = 'Hold duration', Min = 0, Max = 10, Default = 1, Decimal = 100, Suffix = 's', Function = refresh})
	Instant = PromptEditor:CreateToggle({Name = 'Instant', Tooltip = 'Sets prompt hold duration to zero', Function = refresh})
	ThroughWalls = PromptEditor:CreateToggle({Name = 'Through walls', Tooltip = 'Lets prompts work through walls', Function = refresh})
end)



