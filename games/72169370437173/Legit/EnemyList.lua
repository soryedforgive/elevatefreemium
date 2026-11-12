run(function()
	local EnemyList
	local label

	EnemyList = vape.Categories.Legit:CreateModule({
		Name = 'EnemyList',
		Category = 'Hud',
		Function = function(callback)
			if callback then
				repeat
					local lines = {}
					for _, ent in entitylib.List do
						if ent.Targetable and ent.Character.Parent then
							local char = ent.Character
							local tool = char:FindFirstChildOfClass('Tool')
							local name = ent.Player and ent.Player.DisplayName or char.Name
							table.insert(lines, string.format('%s  %d hp  %d armour  %s', name, math.ceil(ent.Health), char:GetAttribute('Armor') or 0, tool and tool.Name or '-'))
						end
					end
					table.sort(lines)
					local text = #lines > 0 and table.concat(lines, '\n') or 'No enemies'
					if label.Text ~= text then
						label.Text = text
					end
					task.wait(0.25)
				until not EnemyList.Enabled
			end
		end,
		Size = UDim2.fromOffset(260, 66),
		Tooltip = 'Lists each enemy with their health, armour and weapon'
	})
	EnemyList:CreateFont({
		Name = 'Font',
		Blacklist = 'Gotham',
		Function = function(val)
			label.FontFace = val
		end
	})
	EnemyList:CreateColorSlider({
		Name = 'Colour',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			label.BackgroundTransparency = 1 - opacity
		end
	})
	label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.5
	label.TextSize = 14
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = 'No enemies'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = EnemyList.Children
	local padding = Instance.new('UIPadding')
	padding.PaddingLeft = UDim.new(0, 6)
	padding.Parent = label
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)
