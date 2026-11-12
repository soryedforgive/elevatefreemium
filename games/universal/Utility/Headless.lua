run(function()
	local Headless
	local headlessLoop = nil

	local headAttachments = {HatAttachment=true,HairAttachment=true,FaceFrontAttachment=true,FaceCenterAttachment=true,FaceBackAttachment=true}
	local removeAccs = false

	local function applyHeadless(char)
		if not char then return end
		local head = char:FindFirstChild("Head")
		if not head then return end
		if head.Transparency ~= 1 then head.Transparency = 1 end
		local face = head:FindFirstChild('face')
		if face and face:IsA("Decal") and face.Transparency ~= 1 then
			face.Transparency = 1
		end
		if removeAccs then
			for _, acc in ipairs(char:GetChildren()) do
				if acc:IsA("Accessory") then
					local handle = acc:FindFirstChild("Handle")
					if handle then
						for _, att in ipairs(handle:GetChildren()) do
							if att:IsA("Attachment") and headAttachments[att.Name] then
								if handle.Transparency ~= 1 then handle.Transparency = 1 end
								for _, d in ipairs(handle:GetChildren()) do
									if (d:IsA("Decal") or d:IsA("Texture")) and d.Transparency ~= 1 then d.Transparency = 1 end
								end
								break
							end
						end
					end
				end
			end
		end
	end

	Headless = vape.Categories.Utility:CreateModule({
		PerformanceModeBlacklisted = true,
		Name = 'Headless',
		Tooltip = 'Hides your head',
		Function = function(callback)
			if callback then
				if headlessLoop then task.cancel(headlessLoop) end
				headlessLoop = task.spawn(function()
					while Headless.Enabled do
						applyHeadless(lplr.Character)
						task.wait(0.25)
					end
				end)
				Headless:Clean(lplr.CharacterAdded:Connect(function(char)
					applyHeadless(char)
				end))
			else
				if headlessLoop then
					task.cancel(headlessLoop)
					headlessLoop = nil
				end
				local char = lplr.Character
				if char then
					local head = char:FindFirstChild("Head")
					if head then
						head.Transparency = 0
						local face = head:FindFirstChild('face')
						if face and face:IsA("Decal") then
							face.Transparency = 0
						end
					end
					for _, acc in ipairs(char:GetChildren()) do
						if acc:IsA("Accessory") then
							local handle = acc:FindFirstChild("Handle")
							if handle then
								handle.Transparency = 0
								for _, d in ipairs(handle:GetChildren()) do
									if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 0 end
								end
							end
						end
					end
				end
			end
		end,
		Default = false
	})

	Headless:CreateToggle({
		Name = "Remove Accessories",
		Default = false,
		Function = function(state)
			removeAccs = state
			if Headless.Enabled then
				applyHeadless(lplr.Character)
			end
		end
	})
end)
