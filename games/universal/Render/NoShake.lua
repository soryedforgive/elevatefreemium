run(function()
	local NoShake
	local Offset
	local Movement
	local Strength
	local Libraries
	local renderId = httpService:GenerateGUID(false)
	local renderNames = {
		First = 'ElevateV4NoShakeFirst'..renderId,
		Before = 'ElevateV4NoShakeBefore'..renderId,
		Capture = 'ElevateV4NoShakeCapture'..renderId,
		Last = 'ElevateV4NoShakeLast'..renderId
	}

	local SETTLE = 0.2
	local POSITION_SNAP = 6
	local ROTATION_SNAP = 0.35

	local cam = {Clean = nil, Written = nil, Applying = false, Last = 0, Dt = 1 / 60}
	local function newTrack()
		return {
			Sum = Vector3.zero, Total = 0, Age = 0,
			BaseSum = Vector3.zero, BaseTotal = 0, BaseAge = 0
		}
	end
	local tracks = {Position = newTrack(), Rotation = newTrack()}
	local offset = {Humanoid = nil, Steady = Vector3.zero, Wanted = Vector3.zero, Since = 0, Applying = false}
	local patched = {}
	local offsetConnection, cameraConnection

	local function memory()
		return 0.02 + (Strength and Strength.Value or 5) * 0.01
	end

	local function decayTrack(track, dt)
		local keep = math.exp(-dt / memory())
		track.BaseSum = track.Sum * keep
		track.BaseTotal = track.Total * keep
		track.BaseAge = track.Age * keep
		track.Sum, track.Total, track.Age = track.BaseSum, track.BaseTotal, track.BaseAge
	end

	local function resetTrack(track)
		track.Sum, track.Total, track.Age = Vector3.zero, 0, 0
		track.BaseSum, track.BaseTotal, track.BaseAge = Vector3.zero, 0, 0
	end

	local function steadiness(track, movement, epsilon, dt)
		local size = movement.Magnitude
		if size <= epsilon then
			track.Sum, track.Total, track.Age = track.BaseSum, track.BaseTotal, track.BaseAge
			return 1
		end
		track.Sum = track.BaseSum + movement
		track.Total = track.BaseTotal + size
		track.Age = track.BaseAge + dt
		local span = memory()
		local needed = math.max(span * 0.5, dt * (1 + math.exp(-dt / span)) * 0.999)
		if track.Age < needed or track.Total <= 0 then return 0 end
		return math.clamp((track.Sum.Magnitude / track.Total - 0.55) / 0.3, 0, 1)
	end

	local function sameOffset(a, b)
		return (a - b).Magnitude < 0.0001
	end

	local function writeOffset(value)
		local humanoid = offset.Humanoid
		if not humanoid or not humanoid.Parent then return end
		if sameOffset(humanoid.CameraOffset, value) then return end
		offset.Applying = true
		humanoid.CameraOffset = value
		offset.Applying = false
	end

	local function offsetActive()
		return NoShake.Enabled and Offset.Enabled and offset.Humanoid ~= nil
	end

	local function releaseOffset()
		if offsetConnection then
			offsetConnection:Disconnect()
			offsetConnection = nil
		end
		if offset.Humanoid then
			writeOffset(offset.Wanted)
		end
		offset.Humanoid = nil
	end

	local function holdOffset(humanoid)
		releaseOffset()
		if not humanoid or not NoShake.Enabled or not Offset.Enabled then return end
		offset.Humanoid = humanoid
		offset.Steady = humanoid.CameraOffset
		offset.Wanted = offset.Steady
		offset.Since = os.clock()
		offsetConnection = humanoid:GetPropertyChangedSignal('CameraOffset'):Connect(function()
			if offset.Applying or not offsetActive() then return end
			local value = humanoid.CameraOffset
			if not sameOffset(value, offset.Wanted) then
				offset.Wanted = value
				offset.Since = os.clock()
			end
			writeOffset(offset.Steady)
		end)
	end

	local function settleOffset()
		if not offsetActive() then return end
		if not sameOffset(offset.Wanted, offset.Steady) and os.clock() - offset.Since >= SETTLE then
			offset.Steady = offset.Wanted
		end
		writeOffset(offset.Steady)
	end

	local function enforceOffset()
		if offsetActive() then
			writeOffset(offset.Steady)
		end
	end

	local function localHumanoid()
		return entitylib.isAlive and entitylib.character.Humanoid or nil
	end

	local function movementActive()
		return NoShake.Enabled and Movement.Enabled
	end

	local function first()
		cam.Clean = nil
		cam.Written = nil
		settleOffset()
	end

	local function capture()
		cam.Clean = nil
		cam.Written = nil
		if not movementActive() then return end
		local camera = gameCamera
		if not camera or camera.CameraType ~= Enum.CameraType.Custom then return end

		local now = os.clock()
		cam.Dt = math.clamp(now - cam.Last, 1 / 500, 0.1)
		cam.Last = now
		decayTrack(tracks.Position, cam.Dt)
		decayTrack(tracks.Rotation, cam.Dt)
		cam.Clean = camera.CFrame
	end

	local function correct()
		local clean = cam.Clean
		if cam.Applying or not clean or not movementActive() then return end
		local camera = gameCamera
		if not camera or camera.CameraType ~= Enum.CameraType.Custom then return end

		local current = camera.CFrame
		if cam.Written and current:FuzzyEq(cam.Written, 0.0002) then return end

		local moved = clean:ToObjectSpace(current)
		local position = moved.Position
		local rx, ry, rz = moved:ToEulerAnglesYXZ()
		local rotation = Vector3.new(rx, ry, rz)

		if position.Magnitude > POSITION_SNAP or rotation.Magnitude > ROTATION_SNAP then
			resetTrack(tracks.Position)
			resetTrack(tracks.Rotation)
			cam.Written = current
			return
		end

		local keepPosition = steadiness(tracks.Position, position, 0.001, cam.Dt)
		local keepRotation = steadiness(tracks.Rotation, rotation, 0.0001, cam.Dt)
		local collision = vape.Modules.NoCameraCollision
		if collision and collision.Enabled then
			keepPosition = 1
		end
		if keepPosition >= 1 and keepRotation >= 1 then
			cam.Written = current
			return
		end

		local wanted = clean
			* CFrame.new(position * keepPosition)
			* CFrame.fromEulerAnglesYXZ(rx * keepRotation, ry * keepRotation, rz * keepRotation)
		cam.Written = wanted
		if not wanted:FuzzyEq(current, 0.0002) then
			cam.Applying = true
			camera.CFrame = wanted
			cam.Applying = false
		end
	end

	local function bindCamera()
		if cameraConnection then
			cameraConnection:Disconnect()
			cameraConnection = nil
		end
		if gameCamera then
			cameraConnection = gameCamera:GetPropertyChangedSignal('CFrame'):Connect(correct)
		end
	end

	local function unbindSteps()
		for _, name in renderNames do
			pcall(runService.UnbindFromRenderStep, runService, name)
		end
	end

	local function forgetMovement()
		cam.Clean, cam.Written = nil, nil
		resetTrack(tracks.Position)
		resetTrack(tracks.Rotation)
	end

	local function quiet()
		return NoShake.Enabled and Libraries.Enabled
	end

	local function patchLibrary(lib)
		if patched[lib] then return end
		local saved = {}
		patched[lib] = saved

		for _, name in {'ShakeOnce', 'StartShake'} do
			local old = rawget(lib, name)
			if type(old) == 'function' then
				local wrapper = function(self, magnitude, ...)
					if not quiet() then return old(self, magnitude, ...) end
					return old(self, 0, ...)
				end
				saved[name] = {Old = old, New = wrapper}
				lib[name] = wrapper
			end
		end

		for _, name in {'Shake', 'ShakeSustain'} do
			local old = rawget(lib, name)
			if type(old) == 'function' then
				local wrapper = function(self, instance, ...)
					if quiet() and type(instance) == 'table' then
						pcall(function()
							instance.Magnitude = 0
						end)
					end
					return old(self, instance, ...)
				end
				saved[name] = {Old = old, New = wrapper}
				lib[name] = wrapper
			end
		end
	end

	local function patchLibraries()
		if not quiet() or type(getloadedmodules) ~= 'function' then return end
		local ok, modules = pcall(getloadedmodules)
		if not ok or type(modules) ~= 'table' then return end
		for _, module in modules do
			local named, name = pcall(function()
				return module.Name
			end)
			if named and name == 'CameraShaker' then
				local good, lib = pcall(require, module)
				if good and type(lib) == 'table' and type(rawget(lib, 'ShakeOnce')) == 'function' then
					pcall(patchLibrary, lib)
				end
			end
		end
	end

	local function unpatchLibraries()
		for lib, saved in patched do
			local clear = true
			for name, entry in saved do
				if rawget(lib, name) == entry.New then
					lib[name] = entry.Old
				else
					clear = false
				end
			end
			if clear then
				patched[lib] = nil
			end
		end
	end

	NoShake = vape.Categories.Render:CreateModule({
		Name = 'NoShake',
		Function = function(callback)
			if callback then
				forgetMovement()
				cam.Last = os.clock()
				bindCamera()
				NoShake:Clean(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
					task.defer(bindCamera)
				end))
				NoShake:Clean(entitylib.Events.LocalAdded:Connect(function(ent)
					holdOffset(ent.Humanoid)
					task.delay(2, patchLibraries)
				end))
				NoShake:Clean(runService.RenderStepped:Connect(correct))
				runService:BindToRenderStep(renderNames.First, Enum.RenderPriority.First.Value, first)
				runService:BindToRenderStep(renderNames.Before, Enum.RenderPriority.Camera.Value - 1, enforceOffset)
				runService:BindToRenderStep(renderNames.Capture, Enum.RenderPriority.Camera.Value + 1, capture)
				runService:BindToRenderStep(renderNames.Last, Enum.RenderPriority.Last.Value, correct)
				NoShake:Clean(unbindSteps)
				holdOffset(localHumanoid())
				patchLibraries()
			else
				if cameraConnection then
					cameraConnection:Disconnect()
					cameraConnection = nil
				end
				releaseOffset()
				forgetMovement()
				unpatchLibraries()
			end
		end,
		Tooltip = 'Removes screen shake while keeping aim assist working'
	})

	Offset = NoShake:CreateToggle({
		Name = 'Camera offset',
		Default = true,
		Function = function()
			if NoShake.Enabled then
				holdOffset(localHumanoid())
			end
		end,
		Tooltip = 'Ignores camera bobbing'
	})
	Movement = NoShake:CreateGroup({
		Name = 'Camera movement',
		Default = true,
		Function = function(callback)
			forgetMovement()
		end,
		Tooltip = 'Removes camera jitter but keeps steady movement'
	})
	Strength = Movement:CreateSlider({
		Name = 'Strength',
		Min = 1,
		Max = 10,
		Default = 5,
		Darker = true,
		Tooltip = 'Higher removes slower shakes'
	})
	Libraries = NoShake:CreateToggle({
		Name = 'Shake libraries',
		Default = true,
		Function = function()
			if NoShake.Enabled then
				patchLibraries()
			end
		end,
		Tooltip = 'Mutes common camera shake scripts'
	})

	vape:Clean(function()
		if cameraConnection then cameraConnection:Disconnect() end
		unbindSteps()
		releaseOffset()
		unpatchLibraries()
	end)
end)
