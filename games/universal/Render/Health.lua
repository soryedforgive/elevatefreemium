run(function()
    local Health

    Health = vape.Categories.Render:CreateModule({
	Name = 'Health',
	Function = function(callback)
		if callback then
			local label = Instance.new('TextLabel')
			label.Size = UDim2.fromOffset(100, 20)
			label.Position = UDim2.new(0.5, 6, 0.5, 30)
			label.AnchorPoint = Vector2.new(0.5, 0)
			label.BackgroundTransparency = 1
			label.Text = '100 ❤️'
			label.TextSize = 18
			label.Font = Enum.Font.Arial
			label.Parent = vape.gui
			Health:Clean(label)

			local connections = {}
			local function update()
				local humanoid = entitylib.isAlive and entitylib.character.Humanoid
				if humanoid then
					label.Text = math.round(humanoid.Health) .. ' ❤️'
					label.TextColor3 = Color3.fromHSV(math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1) / 2.8, 0.86, 1)
				else
					label.Text = ''
				end
			end
			local function bind()
				for _, connection in connections do
					connection:Disconnect()
				end
				table.clear(connections)
				local humanoid = entitylib.isAlive and entitylib.character.Humanoid
				if humanoid then
					table.insert(connections, humanoid.HealthChanged:Connect(update))
					table.insert(connections, humanoid:GetPropertyChangedSignal('MaxHealth'):Connect(update))
				end
				update()
			end

			Health:Clean(entitylib.Events.LocalAdded:Connect(bind))
			Health:Clean(entitylib.Events.LocalRemoved:Connect(function()
				label.Text = ''
			end))
			Health:Clean(function()
				for _, connection in connections do
					connection:Disconnect()
				end
				table.clear(connections)
			end)
			bind()
		end
	end,
	Tooltip = 'Shows your health in the centre of your screen',
    })
end)
