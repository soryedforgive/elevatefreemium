run(function()
	local function statSpoof(name, attribute, includeCharacter)
		local module, slider
		local saved = setmetatable({}, {__mode = 'k'})
		local watched = setmetatable({}, {__mode = 'k'})

		local function apply()
			if not (module and module.Enabled and slider) then return end
			for _, object in {lplr, includeCharacter and lplr.Character or nil} do
				if not saved[object] then
					saved[object] = {Value = object:GetAttribute(attribute)}
				end
				if object:GetAttribute(attribute) ~= slider.Value then
					object:SetAttribute(attribute, slider.Value)
				end
			end
		end

		local function watch(object)
			if not object or watched[object] then return end
			watched[object] = true
			module:Clean(object:GetAttributeChangedSignal(attribute):Connect(function()
				task.defer(apply)
			end))
		end

		module = vape.Categories.Render:CreateModule({
			Name = name,
			Function = function(callback)
				if callback then
					watch(lplr)
					if includeCharacter then
						watch(lplr.Character)
						module:Clean(lplr.CharacterAdded:Connect(function(char)
							watch(char)
							task.defer(apply)
						end))
					end
					apply()
				else
					table.clear(watched)
					for object, record in saved do
						pcall(function()
							if object.Parent and object:GetAttribute(attribute) == slider.Value then
								object:SetAttribute(attribute, record.Value)
							end
						end)
						saved[object] = nil
					end
				end
			end,
			Tooltip = 'Shows a different '..attribute:lower()..' on your own screen only'
		})
		slider = module:CreateSlider({
			Name = 'Value',
			Min = 0,
			Max = 9999,
			Default = 100,
			Function = apply
		})
	end

	statSpoof('StreakSpoof', 'Streak', false)
	statSpoof('LevelSpoof', 'Level', true)
end)
