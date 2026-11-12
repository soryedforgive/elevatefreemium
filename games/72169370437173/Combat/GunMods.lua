run(function()
	local GunMods
	local util, combat = tribes.Util, tribes.Combat
	local cameraApi = (util and util.Camera and util.Camera()) or tribes.Camera
	local activeShot

	local Remove

	local function active(option)
		return GunMods and GunMods.Enabled and Remove and Remove:Has(option)
	end

	local function resetRecoil()
		if not active('Recoil') or type(cameraApi) ~= 'table' then return end
		local spring = cameraApi.SlowRecoil
		if type(spring) == 'table' and type(spring.Snap) == 'function' then
			pcall(spring.Snap, spring, Vector3.zero)
		end
		pcall(function()
			cameraApi.SlowRecoilStay = Vector3.zero
		end)
	end

	local function block(tab, key, option)
		gameapi.Patch(tab, key, function(original)
			return function(...)
				if active(option()) then return end
				return original(...)
			end
		end)
	end
	block(util, 'Recoil', function() return 'Recoil' end)
	block(util, 'RecoilSlow', function() return 'Recoil' end)
	block(util, 'Shake', function() return 'Shake' end)
	block(tribes.Hud, 'Kick', function() return 'Recoil' end)
	gameapi.Patch(tribes.Poses, 'Kick', function(original)
		return function(char, ...)
			if active('Recoil') and char == lplr.Character then return end
			return original(char, ...)
		end
	end)

	local function compensate(spread, goal, degrees, seed)
		if typeof(goal) ~= 'Vector3' or goal.Magnitude < 0.001 then return nil end
		goal = goal.Unit
		local candidate = goal
		for _ = 1, 14 do
			local result = spread(candidate, degrees, seed, 0)
			if typeof(result) ~= 'Vector3' then return nil end
			if result:Dot(goal) >= 0.9999999 then return candidate end
			local adjusted = candidate + (goal - result)
			if adjusted.Magnitude < 0.001 then return nil end
			candidate = adjusted.Unit
		end
		return nil
	end

	gameapi.Patch(combat, 'SpreadDir', function(original)
		return function(direction, degrees, seed, index)
			local shot = activeShot
			if shot and index == 0 and type(degrees) == 'number' and degrees > 0 and typeof(direction) == 'Vector3' then
				local corrected = compensate(original, direction, degrees, seed)
				if corrected then
					shot.Original, shot.Corrected, shot.Seed = direction, corrected, seed
					return original(corrected, degrees, seed, index)
				end
			end
			return original(direction, degrees, seed, index)
		end
	end)

	gameapi.Patch(tribes.Gun, 'Fire', function(original)
		return function(self, ...)
			local ctx = self and self.ctx
			if not active('Spread') or self.kind == 'Blunderbuss' or self.kind == 'Crossbow' or type(ctx) ~= 'table' or type(ctx.send) ~= 'function' then
				return original(self, ...)
			end
			local shot = {}
			local nativeSend = ctx.send
			local function send(action, packet, ...)
				if action == 'Shoot' and shot.Corrected and type(packet) == 'table' and type(packet.id) == 'number' and typeof(packet.dir) == 'Vector3' and packet.dir:Dot(shot.Original) >= 0.999999 then
					local nonce = ctx.char and ctx.char:GetAttribute('ShotNonce')
					if combat.SeedFor(packet.id, type(nonce) == 'number' and nonce or 0) == shot.Seed then
						local fixed = table.clone(packet)
						fixed.dir = shot.Corrected
						return nativeSend(action, fixed, ...)
					end
				end
				return nativeSend(action, packet, ...)
			end
			if not pcall(function()
				ctx.send = send
			end) or ctx.send ~= send then
				return original(self, ...)
			end
			local previous = activeShot
			activeShot = shot
			local result = table.pack(pcall(original, self, ...))
			activeShot = previous
			if ctx.send == send then
				ctx.send = nativeSend
			end
			if not result[1] then
				error(result[2], 0)
			end
			return table.unpack(result, 2, result.n)
		end
	end)

	GunMods = vape.Categories.Combat:CreateModule({
		Name = 'GunMods',
		Function = function(callback)
			if callback then
				resetRecoil()
			end
		end,
		Tooltip = 'Removes recoil, shake and spread from guns'
	})
	Remove = GunMods:CreateMultiDropdown({
		Name = 'Remove',
		List = {'Recoil', 'Shake', 'Spread'},
		Default = {'Recoil', 'Shake', 'Spread'},
		Function = function()
			resetRecoil()
		end,
		Tooltip = 'What it removes from guns'
	})
end)
