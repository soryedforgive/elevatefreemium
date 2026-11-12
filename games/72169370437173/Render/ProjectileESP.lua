run(function()
	local ProjectileESP
	local Color
	local Danger
	local pool, live = {}, {}
	local SEGMENTS = 12
	local STEP = 0.1

	local function line()
		local seg = table.remove(pool)
		if not seg then
			seg = Instance.new('LineHandleAdornment')
			seg.Thickness = 3
			seg.AlwaysOnTop = true
			seg.ZIndex = 0
			seg.Adornee = workspace.Terrain
		end
		seg.Parent = vape.gui
		return seg
	end

	local function free(shot)
		for _, seg in shot.Lines do
			seg.Parent = nil
			table.insert(pool, seg)
		end
		table.clear(shot.Lines)
	end

	ProjectileESP = vape.Categories.Render:CreateModule({
		Name = 'ProjectileESP',
		Function = function(callback)
			if callback then
				ProjectileESP:Clean(vapeEvents.EnemyShot.Event:Connect(function(shooter, origin, velocity, gravity)
					if not isEnemy(shooter) or #live >= 20 then return end
					local shot = {Lines = {}, Until = tick() + SEGMENTS * STEP}
					local close = false
					local body = entitylib.isAlive and store.body()
					local last = origin
					for i = 1, SEGMENTS do
						local t = i * STEP
						local point = origin + velocity * t - Vector3.new(0, 0.5 * gravity * t * t, 0)
						if body and (point - body).Magnitude < 5 then
							close = true
						end
						local seg = line()
						local dir = point - last
						seg.CFrame = CFrame.lookAt(last, point)
						seg.Length = dir.Magnitude
						table.insert(shot.Lines, seg)
						last = point
					end
					local hue = close and Danger or Color
					for _, seg in shot.Lines do
						seg.Color3 = Color3.fromHSV(hue.Hue, hue.Sat, hue.Value)
					end
					table.insert(live, shot)
				end))
				repeat
					local now = tick()
					for i = #live, 1, -1 do
						if now > live[i].Until then
							free(live[i])
							table.remove(live, i)
						end
					end
					task.wait(0.1)
				until not ProjectileESP.Enabled
			else
				for _, shot in live do
					free(shot)
				end
				table.clear(live)
			end
		end,
		Tooltip = 'Shows the path of enemy shots'
	})
	Color = ProjectileESP:CreateColorSlider({
		Name = 'Colour',
		DefaultHue = 0.12
	})
	Danger = ProjectileESP:CreateColorSlider({
		Name = 'Danger colour',
		DefaultHue = 0
	})
end)
