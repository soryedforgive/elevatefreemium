run(function()
	local Legless
	local Side
	local RemoveAccessories
	local originals = {}
	local legAttachments = {
		LeftAnkleAttachment = 'Left', LeftFootAttachment = 'Left', LeftKneeAttachment = 'Left',
		RightAnkleAttachment = 'Right', RightFootAttachment = 'Right', RightKneeAttachment = 'Right'
	}

	local function selected(name)
		return Side.Value == 'Both' or name:sub(1, #Side.Value) == Side.Value
	end

	local function hide(obj)
		if originals[obj] == nil then
			originals[obj] = obj.Transparency
			Legless:Clean(obj:GetPropertyChangedSignal('Transparency'):Connect(function()
				if Legless.Enabled and originals[obj] ~= nil and obj.Transparency ~= 1 then
					obj.Transparency = 1
				end
			end))
		end
		if obj.Transparency ~= 1 then obj.Transparency = 1 end
	end

	local function isLeg(obj)
		return obj:IsA('BasePart') and selected(obj.Name) and (obj.Name:find('Leg') or obj.Name:find('Foot')) ~= nil
	end

	local applyAccessories
	local function applyLegless(char)
		if not char then return end
		for _, obj in char:GetDescendants() do
			if isLeg(obj) then
				hide(obj)
			end
		end
		applyAccessories(char)
	end

	applyAccessories = function(char)
		if RemoveAccessories.Enabled then
			for _, acc in char:GetChildren() do
				if acc:IsA('Accessory') then
					local handle = acc:FindFirstChild('Handle')
					if handle then
						for _, attachment in handle:GetChildren() do
							if attachment:IsA('Attachment') and legAttachments[attachment.Name] and selected(legAttachments[attachment.Name]) then
								hide(handle)
								for _, texture in handle:GetChildren() do
									if texture:IsA('Decal') or texture:IsA('Texture') then hide(texture) end
								end
								break
							end
						end
					end
				end
			end
		end
	end

	local function restoreLegs()
		local saved = table.clone(originals)
		table.clear(originals)
		for obj, value in saved do
			if obj.Parent then obj.Transparency = value end
		end
	end
	local function watchCharacter(char)
		applyLegless(char)
		if char then
			local pending = false
			Legless:Clean(char.DescendantAdded:Connect(function(obj)
				if isLeg(obj) then
					hide(obj)
				elseif RemoveAccessories.Enabled and (obj:IsA('Accessory') or obj:IsA('Attachment') or obj.Name == 'Handle') and not pending then
					pending = true
					task.defer(function()
						pending = false
						applyAccessories(char)
					end)
				end
			end))
		end
	end

	Legless = vape.Categories.Utility:CreateModule({
		PerformanceModeBlacklisted = true,
		Name = 'Legless',
		Tooltip = 'Hides either or both legs',
		Function = function(callback)
			if callback then
				watchCharacter(lplr.Character)
				Legless:Clean(lplr.CharacterAdded:Connect(watchCharacter))
			else
				restoreLegs()
			end
		end
	})
	Side = Legless:CreateDropdown({
		Name = 'Legs',
		List = {'Both', 'Left', 'Right'},
		Function = function()
			if Legless.Enabled then restoreLegs(); applyLegless(lplr.Character) end
		end
	})
	RemoveAccessories = Legless:CreateToggle({
		Name = 'Remove Accessories',
		Function = function()
			if Legless.Enabled then restoreLegs(); applyLegless(lplr.Character) end
		end
	})
end)
