run(function()
	local FirstPerson
	local Body

	FirstPerson = vape.Categories.Render:CreateModule({
		Name = 'FirstPerson',
		Function = function(callback)
			local flag = bedfight.PlayerConfig.InFirstPerson
			if callback then
				flag.Value = true
				FirstPerson:Clean(flag.Changed:Connect(function(val)
					if not val then
						task.defer(function()
							if FirstPerson.Enabled then
								flag.Value = true
							end
						end)
					end
				end))
				FirstPerson:Clean(runService.RenderStepped:Connect(function()
					if Body.Enabled and lplr.Character then
						for _, v in lplr.Character:GetChildren() do
							if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' and v.Name ~= 'Hitbox' then
								v.LocalTransparencyModifier = 0
							end
						end
					end
				end))
			else
				local root = lplr.Character and lplr.Character:FindFirstChild('HumanoidRootPart')
				flag.Value = root ~= nil and root.LocalTransparencyModifier > 0.9
			end
		end,
		Tooltip = 'Keeps your arms and held item on screen at any zoom'
	})
	Body = FirstPerson:CreateToggle({
		Name = 'Show body',
		Tooltip = 'Keeps your own character visible while zoomed all the way in'
	})
end)
