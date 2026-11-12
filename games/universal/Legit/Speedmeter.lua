run(function()
    local Speedmeter
    local label

    Speedmeter = vape.Categories.Legit:CreateModule({
	Name = 'Speedmeter',
	Category = 'Hud',
	Function = function(callback)
		if callback then
			local times, steps = {}, {}
			local head, tail = 1, 0
			local travelled, last, shown = 0, nil, 0
			Speedmeter:Clean(runService.Heartbeat:Connect(function(dt)
				local now = os.clock()
				local position = entitylib.isAlive and entitylib.character.RootPart.Position or nil
				local step = 0
				if position and last then
					step = Vector3.new(position.X - last.X, 0, position.Z - last.Z).Magnitude
					if step > math.max(dt, 1 / 240) * 400 then
						table.clear(times)
						table.clear(steps)
						head, tail, travelled, step = 1, 0, 0, 0
					end
				end
				last = position

				tail += 1
				times[tail], steps[tail] = now, step
				if tail > head then travelled += step end
				while head < tail and now - times[head] > 0.5 do
					times[head], steps[head] = nil, nil
					head += 1
					travelled -= steps[head]
				end

				if now - shown >= 0.1 then
					shown = now
					local span = now - times[head]
					local speed = (position and span > 0.05) and math.max(travelled, 0) / span or 0
					label.Text = (speed < 0.05 and '0' or string.format('%.1f', speed))..' sps'
				end
			end))
		end
	end,
	Size = UDim2.fromOffset(100, 41),
	Tooltip = 'Shows how fast you are moving',
    })
    Speedmeter:CreateFont({
	Name = 'Font',
	Blacklist = 'Gotham',
	Function = function(val)
		label.FontFace = val
	end,
    })
    Speedmeter:CreateColorSlider({
	Name = 'Colour',
	DefaultValue = 0,
	DefaultOpacity = 0.5,
	Function = function(hue, sat, val, opacity)
		label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
		label.BackgroundTransparency = 1 - opacity
	end,
    })
    label = Instance.new('TextLabel')
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.5
    label.TextSize = 15
    label.Font = Enum.Font.Gotham
    label.Text = '0 sps'
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundColor3 = Color3.new()
    label.Parent = Speedmeter.Children
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = label
end)
