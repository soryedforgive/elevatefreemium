run(function()
	local RingESP
	local Warn
	local holder, ring
	local outside = false

	local function arena()
		local arenas = workspace:FindFirstChild('Arenas')
		local id = lplr.Character and lplr.Character:GetAttribute('MatchId')
		return arenas and type(id) == 'string' and id ~= '' and arenas:FindFirstChild(id)
	end

	RingESP = vape.Categories.Render:CreateModule({
		Name = 'RingESP',
		Function = function(callback)
			if callback then
				holder = Instance.new('Part')
				holder.Anchored = true
				holder.CanCollide = false
				holder.CanQuery = false
				holder.CanTouch = false
				holder.Transparency = 1
				holder.Size = Vector3.one
				holder.Parent = gameCamera
				ring = Instance.new('CylinderHandleAdornment')
				ring.Height = 40
				ring.AlwaysOnTop = false
				ring.Transparency = 0.6
				ring.Adornee = holder
				ring.Parent = holder
				repeat
					local a = arena()
					local radius = a and a:GetAttribute('RingRadius')
					if type(radius) == 'number' and radius > 1 and entitylib.isAlive then
						local centre = Vector3.new(a:GetAttribute('RingCenterX') or 0, store.body().Y, a:GetAttribute('RingCenterZ') or 0)
						holder.CFrame = CFrame.new(centre) * CFrame.Angles(math.rad(90), 0, 0)
						if ring.Radius ~= radius then
							ring.Radius = radius
							ring.InnerRadius = math.max(0, radius - 0.6)
						end
						local flat = (store.body() - centre) * Vector3.new(1, 0, 1)
						local out = flat.Magnitude > radius
						ring.Color3 = out and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(255, 170, 60)
						ring.Visible = true
						if out and not outside and Warn.Enabled then
							notif('RingESP', 'You are outside the ring', 3, 'warning')
						end
						outside = out
					else
						ring.Visible = false
						outside = false
					end
					task.wait(0.2)
				until not RingESP.Enabled
			else
				if holder then
					holder:Destroy()
				end
				holder, ring, outside = nil, nil, false
			end
		end,
		Tooltip = 'Shows the ring of fire and warns you when outside it'
	})
	Warn = RingESP:CreateToggle({
		Name = 'Warn outside',
		Default = true
	})
end)
