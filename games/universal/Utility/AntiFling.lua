run(function()
	local AntiFling
	local NoCollide
	local Range
	local Guard
	local Limit
	local NoRagdoll
	local IN_BEDWARS = game.GameId == 2619619496
	local RAGDOLL_STATES = {Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll}
	local changed = setmetatable({}, {__mode = 'k'})
	local partCache = setmetatable({}, {__mode = 'k'})
	local safe, safeAt, lastNotice = nil, 0, 0

	local function partsOf(character)
		local entry = partCache[character]
		local now = os.clock()
		if entry and now - entry.At < 1 then
			return entry.Parts
		end
		local parts = {}
		for _, part in character:GetDescendants() do
			if part:IsA('BasePart') then
				table.insert(parts, part)
			end
		end
		partCache[character] = {Parts = parts, At = now}
		return parts
	end

	local function restoreCollisions()
		for part in changed do
			pcall(function()
				part.CanCollide = true
			end)
		end
		table.clear(changed)
	end

	local function dropCollisions()
		if not entitylib.isAlive then return end
		local origin = entitylib.character.RootPart.Position
		local range = Range.Value
		for _, ent in entitylib.List do
			local root = ent.Player and ent.RootPart
			if root and root.Parent and ent.Character and (root.Position - origin).Magnitude <= range then
				for _, part in partsOf(ent.Character) do
					if part.CanCollide then
						part.CanCollide = false
						changed[part] = true
					end
				end
			end
		end
	end

	local function guard()
		if not entitylib.isAlive then
			safe = nil
			return
		end
		local root = entitylib.character.RootPart
		if not isnetworkowner(root) then return end
		local now = os.clock()
		local speed = root.AssemblyLinearVelocity.Magnitude
		local spin = root.AssemblyAngularVelocity.Magnitude
		local spinbot = vape.Modules.SpinBot
		local spinning = spin > 60 and not (spinbot and spinbot.Enabled)

		if speed > Limit.Value or spinning then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			if safe and now - safeAt < 3 then
				root.CFrame = safe
			end
			if now - lastNotice > 3 then
				lastNotice = now
				notif('AntiFling', 'Stopped a fling.', 3, 'warning')
			end
		elseif speed < Limit.Value * 0.5 and now - safeAt > 0.2 then
			safe, safeAt = root.CFrame, now
		end
	end

	local function setRagdoll(humanoid, enabled)
		if not humanoid then return end
		for _, state in RAGDOLL_STATES do
			pcall(humanoid.SetStateEnabled, humanoid, state, enabled)
		end
		if not enabled and table.find(RAGDOLL_STATES, humanoid:GetState()) then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end

	local function applyRagdoll()
		if entitylib.isAlive then
			setRagdoll(entitylib.character.Humanoid, not (AntiFling.Enabled and NoRagdoll.Enabled and not IN_BEDWARS))
		end
	end

	AntiFling = vape.Categories.Utility:CreateModule({
		Name = 'AntiFling',
		Function = function(callback)
			applyRagdoll()
			if callback then
				AntiFling:Clean(entitylib.Events.LocalAdded:Connect(function(char)
					if NoRagdoll.Enabled and not IN_BEDWARS then
						setRagdoll(char.Humanoid, false)
					end
				end))
				safe, safeAt = nil, 0
				AntiFling:Clean(runService.Stepped:Connect(function()
					if NoCollide.Enabled then
						dropCollisions()
					end
				end))
				AntiFling:Clean(runService.Heartbeat:Connect(function()
					if Guard.Enabled then
						guard()
					end
				end))
			else
				restoreCollisions()
				safe = nil
			end
		end,
		Tooltip = 'Stops other players flinging you and stops you being ragdolled'
	})
	NoRagdoll = AntiFling:CreateToggle({
		Name = 'Stop ragdoll',
		Default = true,
		Visible = not IN_BEDWARS,
		Function = function()
			if AntiFling and AntiFling.Enabled and NoRagdoll then
				applyRagdoll()
			end
		end,
		Tooltip = 'Stops you being ragdolled'
	})
	NoCollide = AntiFling:CreateGroup({
		Name = 'No player collisions',
		Default = true,
		Function = function(callback)
			if not callback then
				restoreCollisions()
			end
		end,
		Tooltip = 'Stops nearby players touching you'
	})
	Range = NoCollide:CreateSlider({
		Name = 'Range',
		Min = 5,
		Max = 60,
		Default = 20,
		Darker = true,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'How close a player has to be before their collisions are switched off'
	})
	Guard = AntiFling:CreateGroup({
		Name = 'Speed guard',
		Default = true,
		Tooltip = 'Stops you being thrown faster than normal'
	})
	Limit = Guard:CreateSlider({
		Name = 'Speed limit',
		Min = 100,
		Max = 1000,
		Default = 300,
		Darker = true,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Tooltip = 'Speed that counts as being flung'
	})

	vape:Clean(restoreCollisions)
end)
