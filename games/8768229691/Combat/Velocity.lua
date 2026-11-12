run(function()
	local Velocity
	local Horizontal
	local Vertical
	local Chance
	local Targeting
	local connection
	local rand, old = Random.new()

	local function velocityFunction(...)
		if rand:NextNumber(0, 100) > Chance.Value then return old(...) end

		local args = table.pack(...)
		local check = (not Targeting.Enabled) or entitylib.EntityPosition({
			Range = 50,
			Part = 'RootPart',
			Players = true
		})

		if check and typeof(args[1]) == 'Vector3' then
			local hort, vert = (Horizontal.Value / 100), (Vertical.Value / 100)
			if hort == 0 and vert == 0 then return end
			args[1] = Vector3.new(args[1].X * hort, args[1].Y * vert, args[1].Z * hort)
		end

		return old(unpack(args, 1, args.n))
	end

	local function knockbackRemote()
		local event = remotes.knockback and skywars.Remotes[remotes.knockback]
		if not event then return nil end
		local ok, remote = pcall(function()
			return debug.getupvalue(debug.getupvalue(event.connect, 1).fireClient, 1)
		end)
		if ok and typeof(remote) == 'Instance' and remote:IsA('RemoteEvent') then
			return remote
		end
		remote = replicatedStorage:FindFirstChild(remotes.knockback, true)
		return remote and remote:IsA('RemoteEvent') and remote or nil
	end

	Velocity = vape.Categories.Combat:CreateModule({
		Name = 'Velocity',
		Function = function(callback)
			if callback then
				if not (hookfunction and getconnections) then
					notif('Velocity', 'Your executor has no hookfunction or getconnections.', 8, 'warning')
					return
				end
				local remote = knockbackRemote()
				connection = remote and getconnections(remote.OnClientEvent)[1]
				if not (connection and connection.Function) then
					connection = nil
					notif('Velocity', 'The knockback event was not found.', 8, 'warning')
					return
				end

				old = hookfunction(connection.Function, function(...)
					return velocityFunction(...)
				end)
			else
				if old and connection then
					hookfunction(connection.Function, old)
				end
				old = nil
				connection = nil
			end
		end,
		Tooltip = 'Reduces knockback taken'
	})
	Horizontal = Velocity:CreateSlider({
		Name = 'Horizontal',
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = '%'
	})
	Vertical = Velocity:CreateSlider({
		Name = 'Vertical',
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = '%'
	})
	Chance = Velocity:CreateSlider({
		Name = 'Chance',
		Min = 0,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
	Targeting = Velocity:CreateToggle({Name = 'Only when targeting'})
end)
