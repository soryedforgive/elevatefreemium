run(function()
    local Freecam
    local Speed, Sensitivity, TimeScale
    local Smoothing, SmoothAmount, Acceleration, Deceleration
    local Fov, FovSpeed, Zoom, ZoomFov, ZoomKey
    local Roll, RollSpeed, Tilt
    local Shake, ShakeAmount, ShakeSpeed
    local Dof, AutoFocus, FocusDistance, FocusRange, DofStrength
    local MotionBlur, MotionBlurAmount
    local Orbit, OrbitDirection, OrbitSpeed, OrbitDistance
    local Dolly, DollyDirection, DollySpeed
    local KeyframeTime, KeyframeEase, KeyframeLoop
    local PathName, PathTarget, PathAction, KeyframeIndex
    local HideHud
    local Collision

    local starterGui = cloneref(game:GetService('StarterGui'))
    local bindName = 'ElevateV4Freecam'..httpService:GenerateGUID(false)

    local active = false
    local restore = {}
    local dofEffect, blurEffect
    local hiddenGuis, disabledEffects = {}, {}

    local pos, yaw, pitch = Vector3.zero, 0, 0
    local smoothPos, smoothYaw, smoothPitch = Vector3.zero, 0, 0
    local velocity = Vector3.zero
    local roll, manualRoll, fov, focus, blurSize = 0, 0, 70, 25, 0
    local orbitPivot, orbitAngle
    local shakeClock, firstFrame = 0, true
    local lastPos, lastYaw
    local keyframes, playback = {}, nil
    local pathFolder = 'ElevateV4/profiles/camera-paths'

    local function safePathName()
        return tostring(PathName and PathName.Value or ''):gsub('[^%w%-%_ ]', ''):sub(1, 40)
    end

    local function encodeFrames()
        local out = {}
        for _, frame in keyframes do
            table.insert(out, {Position = {frame.Position.X, frame.Position.Y, frame.Position.Z}, Yaw = frame.Yaw, Pitch = frame.Pitch, Roll = frame.Roll, Fov = frame.Fov})
        end
        return out
    end

    local function decodeFrames(data)
        if type(data) ~= 'table' then return false end
        local out = {}
        for _, frame in data do
            if type(frame) ~= 'table' or type(frame.Position) ~= 'table' or #frame.Position ~= 3 then return false end
            table.insert(out, {Position = Vector3.new(tonumber(frame.Position[1]), tonumber(frame.Position[2]), tonumber(frame.Position[3])), Yaw = tonumber(frame.Yaw), Pitch = tonumber(frame.Pitch), Roll = tonumber(frame.Roll), Fov = tonumber(frame.Fov)})
            if not out[#out].Yaw or not out[#out].Pitch or not out[#out].Roll or not out[#out].Fov then return false end
        end
        keyframes = out
        return true
    end

    local function camera()
        gameCamera = workspace.CurrentCamera or gameCamera
        return gameCamera
    end

    local function approach(rate, dt)
        return 1 - math.exp(-math.max(rate, 0) * dt)
    end

    local function shortestAngle(from, to)
        return (to - from + math.pi) % (math.pi * 2) - math.pi
    end

    local function inputAllowed()
        local suc, menu = pcall(function()
            return vape.gui.ScaledGui.ClickGui.Visible
        end)
        return (not (suc and menu)) and (not inputService:GetFocusedTextBox())
    end

    local function keyDown(key)
        return inputService:IsKeyDown(key)
    end

    local function named(name)
        local suc, key = pcall(function()
            return Enum.KeyCode[name]
        end)
        return suc and key and inputService:IsKeyDown(key) or false
    end


    local function suspendEffects()
        for _, effect in lightingService:GetChildren() do
            if (effect:IsA('DepthOfFieldEffect') or effect:IsA('BlurEffect'))
                and effect ~= dofEffect and effect ~= blurEffect and effect.Enabled then
                table.insert(disabledEffects, effect)
                effect.Enabled = false
            end
        end
    end

    local function releaseEffects()
        for _, effect in disabledEffects do
            pcall(function()
                effect.Enabled = true
            end)
        end
        table.clear(disabledEffects)
    end

    local function updateDof(dt)
        if not Dof.Enabled then
            if dofEffect then
                dofEffect:Destroy()
                dofEffect = nil
                if not blurEffect then
                    releaseEffects()
                end
            end
            return
        end
        if not dofEffect then
            suspendEffects()
            dofEffect = Instance.new('DepthOfFieldEffect')
            dofEffect.Name = 'ElevateV4FreecamDOF'
            dofEffect.FarIntensity = 0
            dofEffect.NearIntensity = 0
            dofEffect.FocusDistance = focus
            dofEffect.Parent = lightingService
        end

        local target = FocusDistance.Value
        if AutoFocus.Enabled then
            local cam = camera()
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {cam, lplr.Character}
            local hit = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 2000, params)
            target = hit and (hit.Position - cam.CFrame.Position).Magnitude or FocusDistance.Value
        end
        focus += (target - focus) * approach(AutoFocus.Enabled and 4 or 8, dt)

        dofEffect.FocusDistance = focus
        dofEffect.InFocusRadius = FocusRange.Value
        dofEffect.FarIntensity = DofStrength.Value / 100
        dofEffect.NearIntensity = (DofStrength.Value / 100) * 0.6
    end

    local function updateMotionBlur(dt, moveSpeed, turnSpeed)
        if not MotionBlur.Enabled then
            if blurEffect then
                blurEffect:Destroy()
                blurEffect = nil
                if not dofEffect then
                    releaseEffects()
                end
            end
            return
        end
        if not blurEffect then
            suspendEffects()
            blurEffect = Instance.new('BlurEffect')
            blurEffect.Name = 'ElevateV4FreecamBlur'
            blurEffect.Size = 0
            blurEffect.Parent = lightingService
        end
        local target = math.clamp((moveSpeed / 90) + (turnSpeed / 2.2), 0, 1) * 24 * (MotionBlurAmount.Value / 100)
        blurSize += (target - blurSize) * approach(9, dt)
        blurEffect.Size = blurSize
    end


    local function showInterface()
        if restore.CoreGui ~= nil then
            pcall(function()
                starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, restore.CoreGui)
            end)
        end
        for _, screen in hiddenGuis do
            pcall(function()
                screen.Enabled = true
            end)
        end
        table.clear(hiddenGuis)
    end

    local function isOwnGui(screen)
        local suc, menu = pcall(function()
            return vape.gui
        end)
        if not suc or typeof(menu) ~= 'Instance' then return false end
        return screen == menu or screen:IsDescendantOf(menu) or menu:IsDescendantOf(screen)
    end

    local function hideInterface()
        if not HideHud.Enabled then return end
        pcall(function()
            starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
        end)
        local playerGui = lplr:FindFirstChildOfClass('PlayerGui')
        if playerGui then
            for _, screen in playerGui:GetChildren() do
                if screen:IsA('LayerCollector') and screen.Enabled and not isOwnGui(screen) then
                    table.insert(hiddenGuis, screen)
                    screen.Enabled = false
                end
            end
        end
    end

    local function refreshInterface()
        if not active then return end
        showInterface()
        hideInterface()
    end


    local function snapshot()
        return {Position = pos, Yaw = yaw, Pitch = pitch, Roll = roll, Fov = fov}
    end

    local function splinePoint(a, b, c, d, t)
        local t2, t3 = t * t, t * t * t
        return (b * 2 + (c - a) * t + (a * 2 - b * 5 + c * 4 - d) * t2 + (b * 3 - a - c * 3 + d) * t3) * 0.5
    end

    local function frameAt(index)
        local count = #keyframes
        if count == 0 then return nil end
        if KeyframeLoop.Enabled then
            return keyframes[((index - 1) % count) + 1]
        end
        return keyframes[math.clamp(index, 1, count)]
    end

    local function stopPlayback()
        if not playback then return end
        playback = nil
        pos, yaw, pitch = smoothPos, smoothYaw, smoothPitch
        manualRoll = roll
        velocity = Vector3.zero
    end

    local function startPlayback()
        if #keyframes < 2 then
            notif('Freecam', 'Save at least two keyframes first', 5, 'alert')
            return
        end
        playback = {Index = 1, Alpha = 0}
    end

    local function stepPlayback(dt)
        playback.Alpha += dt / math.max(KeyframeTime.Value, 0.05)

        while playback.Alpha >= 1 do
            playback.Alpha -= 1
            playback.Index += 1
            local lastSegment = KeyframeLoop.Enabled and #keyframes or (#keyframes - 1)
            if playback.Index > lastSegment then
                if KeyframeLoop.Enabled then
                    playback.Index = 1
                else
                    local last = keyframes[#keyframes]
                    pos, yaw, pitch, roll, fov = last.Position, last.Yaw, last.Pitch, last.Roll, last.Fov
                    smoothPos, smoothYaw, smoothPitch = pos, yaw, pitch
                    manualRoll = roll
                    playback = nil
                    return
                end
            end
        end

        local from, to = frameAt(playback.Index), frameAt(playback.Index + 1)
        if not (from and to) then
            playback = nil
            return
        end

        local t = playback.Alpha
        if KeyframeEase.Enabled then
            t = t * t * (3 - 2 * t)
        end

        if #keyframes > 2 then
            pos = splinePoint(frameAt(playback.Index - 1).Position, from.Position, to.Position, frameAt(playback.Index + 2).Position, t)
        else
            pos = from.Position:Lerp(to.Position, t)
        end
        yaw = from.Yaw + shortestAngle(from.Yaw, to.Yaw) * t
        pitch = from.Pitch + (to.Pitch - from.Pitch) * t
        roll = from.Roll + (to.Roll - from.Roll) * t
        fov = from.Fov + (to.Fov - from.Fov) * t
        smoothPos, smoothYaw, smoothPitch = pos, yaw, pitch
    end


    local function step(realDt)
        local cam = camera()
        if not cam then return end
        if cam.CameraType ~= Enum.CameraType.Scriptable then
            cam.CameraType = Enum.CameraType.Scriptable
        end

        local dt = math.min(realDt, 0.1) * (TimeScale.Value / 100)
        local allowed = inputAllowed()

        if allowed then
            inputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            inputService.MouseIconEnabled = false
        else
            inputService.MouseBehavior = restore.MouseBehavior or Enum.MouseBehavior.Default
            inputService.MouseIconEnabled = true
            firstFrame = true
        end

        if playback then
            if allowed and (keyDown(Enum.KeyCode.W) or keyDown(Enum.KeyCode.A) or keyDown(Enum.KeyCode.S) or keyDown(Enum.KeyCode.D)) then
                stopPlayback()
            else
                stepPlayback(dt)
            end
        end

        local facing = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)

        if not playback then
            if allowed and not firstFrame then
                local delta = inputService:GetMouseDelta()
                yaw -= delta.X * (Sensitivity.Value / 360)
                pitch = math.clamp(pitch - delta.Y * (Sensitivity.Value / 360), -1.5, 1.5)
                facing = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
            end
            firstFrame = false

            local forward = (allowed and keyDown(Enum.KeyCode.W) and 1 or 0) - (allowed and keyDown(Enum.KeyCode.S) and 1 or 0)
            local side = (allowed and keyDown(Enum.KeyCode.D) and 1 or 0) - (allowed and keyDown(Enum.KeyCode.A) and 1 or 0)
            local rise = (allowed and keyDown(Enum.KeyCode.E) and 1 or 0) - (allowed and keyDown(Enum.KeyCode.Q) and 1 or 0)

            local direction = (facing.RightVector * side) + (facing.UpVector * rise) + (facing.LookVector * forward)
            if direction.Magnitude > 0 then
                direction = direction.Unit
            end

            local target = direction * (Speed.Value * ((allowed and keyDown(Enum.KeyCode.LeftShift)) and 0.25 or 1))

            if Dolly.Enabled then
                target += facing.LookVector * (DollySpeed.Value * (DollyDirection.Value == 'Backward' and -1 or 1))
            end

            if Smoothing.Enabled then
                local speedingUp = target.Magnitude > velocity.Magnitude
                velocity = velocity:Lerp(target, approach(speedingUp and Acceleration.Value or Deceleration.Value, dt))
            else
                velocity = target
            end
            local nextPosition = pos + velocity * dt
            if Collision.Enabled then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {cam, lplr.Character}
                local hit = workspace:Raycast(pos, nextPosition - pos, params)
                if hit then
                    nextPosition = hit.Position + hit.Normal * 0.35
                    velocity -= hit.Normal * velocity:Dot(hit.Normal)
                end
            end
            pos = nextPosition

            if Orbit.Enabled then
                if not orbitPivot then
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = {cam, lplr.Character}
                    local hit = workspace:Raycast(pos, facing.LookVector * (OrbitDistance.Value * 4), params)
                    orbitPivot = hit and hit.Position or (pos + facing.LookVector * OrbitDistance.Value)
                    local offset = pos - orbitPivot
                    orbitAngle = math.atan2(offset.X, offset.Z)
                end
                orbitAngle += math.rad(OrbitSpeed.Value) * (OrbitDirection.Value == 'Anticlockwise' and -1 or 1) * dt
                local height = pos.Y - orbitPivot.Y
                pos = orbitPivot + Vector3.new(math.sin(orbitAngle) * OrbitDistance.Value, height, math.cos(orbitAngle) * OrbitDistance.Value)
                local toPivot = orbitPivot - pos
                if toPivot.Magnitude > 0.001 then
                    yaw = math.atan2(-toPivot.X, -toPivot.Z)
                    pitch = math.clamp(math.asin(math.clamp(toPivot.Unit.Y, -1, 1)), -1.5, 1.5)
                end
            elseif orbitPivot then
                orbitPivot, orbitAngle = nil, nil
            end

            if Roll.Enabled then
                if allowed then
                    manualRoll += math.rad(RollSpeed.Value) * ((named('C') and 1 or 0) - (named('Z') and 1 or 0)) * dt
                end
            else
                manualRoll = 0
            end
            local bank = (Roll.Enabled and allowed) and ((keyDown(Enum.KeyCode.D) and 1 or 0) - (keyDown(Enum.KeyCode.A) and 1 or 0)) or 0
            local rollTarget = manualRoll + math.rad(Roll.Enabled and Tilt.Value or 0) * bank
            roll += (rollTarget - roll) * approach(8, dt)

            local wantedFov = (Zoom.Enabled and allowed and named(ZoomKey.Value)) and ZoomFov.Value or Fov.Value
            fov += (wantedFov - fov) * approach(FovSpeed.Value / 10, dt)

            if Smoothing.Enabled then
                local alpha = approach(SmoothAmount.Value / 10, dt)
                smoothPos = smoothPos:Lerp(pos, alpha)
                smoothYaw += shortestAngle(smoothYaw, yaw) * alpha
                smoothPitch += (pitch - smoothPitch) * alpha
            else
                smoothPos, smoothYaw, smoothPitch = pos, yaw, pitch
            end
        end

        local moveSpeed = (smoothPos - (lastPos or smoothPos)).Magnitude / math.max(realDt, 0.001)
        local turnSpeed = math.abs(shortestAngle(lastYaw or smoothYaw, smoothYaw)) / math.max(realDt, 0.001)
        lastPos, lastYaw = smoothPos, smoothYaw

        local frame = CFrame.new(smoothPos) * CFrame.fromEulerAnglesYXZ(smoothPitch, smoothYaw, roll)

        if Shake.Enabled then
            shakeClock += dt * ShakeSpeed.Value
            local amp = ShakeAmount.Value / 100
            frame = frame
                * CFrame.new(math.noise(shakeClock, 0, 0) * amp * 0.35, math.noise(0, shakeClock, 0) * amp * 0.35, 0)
                * CFrame.Angles(
                    math.noise(shakeClock, 3.7, 0) * amp * 0.05,
                    math.noise(1.3, shakeClock, 0) * amp * 0.05,
                    math.noise(0, 5.1, shakeClock) * amp * 0.09
                )
        end

        cam.CFrame = frame
        cam.FieldOfView = math.clamp(fov, 1, 120)

        updateDof(dt)
        updateMotionBlur(dt, moveSpeed, turnSpeed)
    end


    local function enter()
        local cam = camera()
        if not cam then return false end

        restore.CameraType = cam.CameraType
        restore.FieldOfView = cam.FieldOfView
        restore.CameraSubject = cam.CameraSubject
        restore.MouseBehavior = inputService.MouseBehavior
        restore.MouseIcon = inputService.MouseIconEnabled
        pcall(function()
            restore.CoreGui = starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.All)
        end)

        pos = cam.CFrame.Position
        local look = cam.CFrame.LookVector
        yaw = math.atan2(-look.X, -look.Z)
        pitch = math.asin(math.clamp(look.Y, -1, 1))
        smoothPos, smoothYaw, smoothPitch = pos, yaw, pitch
        velocity = Vector3.zero
        roll, manualRoll = 0, 0
        fov = cam.FieldOfView
        focus = FocusDistance.Value
        blurSize = 0
        orbitPivot, orbitAngle, playback = nil, nil, nil
        firstFrame = true
        lastPos, lastYaw = nil, nil

        active = true
        cam.CameraType = Enum.CameraType.Scriptable
        hideInterface()
        pcall(function()
            runService:UnbindFromRenderStep(bindName)
        end)

        contextService:BindActionAtPriority(
            bindName,
            function()
                return Enum.ContextActionResult.Sink
            end,
            false,
            Enum.ContextActionPriority.High.Value,
            Enum.KeyCode.W,
            Enum.KeyCode.A,
            Enum.KeyCode.S,
            Enum.KeyCode.D,
            Enum.KeyCode.E,
            Enum.KeyCode.Q,
            Enum.KeyCode.Space,
            Enum.KeyCode.Up,
            Enum.KeyCode.Down,
            Enum.KeyCode.Left,
            Enum.KeyCode.Right
        )
        return true
    end

    local function leave()
        if not active then return end
        active = false

        pcall(function()
            contextService:UnbindAction(bindName)
        end)
        pcall(function()
            runService:UnbindFromRenderStep(bindName)
        end)

        if dofEffect then
            dofEffect:Destroy()
            dofEffect = nil
        end
        if blurEffect then
            blurEffect:Destroy()
            blurEffect = nil
        end
        releaseEffects()
        showInterface()

        local cam = camera()
        if cam then
            pcall(function()
                cam.FieldOfView = restore.FieldOfView or cam.FieldOfView
                if restore.CameraSubject then
                    cam.CameraSubject = restore.CameraSubject
                end
                cam.CameraType = restore.CameraType or Enum.CameraType.Custom
            end)
        end
        pcall(function()
            inputService.MouseBehavior = restore.MouseBehavior or Enum.MouseBehavior.Default
            inputService.MouseIconEnabled = restore.MouseIcon == nil and true or restore.MouseIcon
        end)
        playback = nil
        table.clear(restore)
    end

    Freecam = vape.Categories.World:CreateModule({
	Name = 'Freecam',
	Function = function(callback)
		if callback then
			if not enter() then
				return
			end
			runService:BindToRenderStep(bindName, Enum.RenderPriority.Camera.Value + 1, function(dt)
				if not Freecam.Enabled then return end
				local ok, err = pcall(step, dt)
				if not ok then
					warn('[ElevateV4] Freecam: '..tostring(err))
				end
			end)
			Freecam:Clean(leave)
		else
			leave()
		end
	end,
	Tooltip = 'Flies the camera freely and records camera moves',
    })

    Speed = Freecam:CreateSlider({
	Name = 'Speed',
	Min = 1,
	Max = 400,
	Default = 50,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end,
	Tooltip = 'Hold Shift for a quarter of the speed'
    })
    Sensitivity = Freecam:CreateSlider({
	Name = 'Sensitivity',
	Min = 0.05,
	Max = 3,
	Default = 0.9,
	Decimal = 100
    })
    TimeScale = Freecam:CreateSlider({
	Name = 'Slow motion',
	Min = 5,
	Max = 100,
	Default = 100,
	Suffix = '%',
	Tooltip = 'Slows every camera move at once'
    })

    Smoothing = Freecam:CreateToggle({
	Name = 'Smoothing',
	Default = true,
	Function = function(call)
		for _, option in {SmoothAmount, Acceleration, Deceleration} do
			if option and option.Object then
				option.Object.Visible = call
			end
		end
	end,
	Tooltip = 'Eases the camera\'s movement'
    })
    SmoothAmount = Freecam:CreateSlider({
	Name = 'Smooth amount',
	Min = 1,
	Max = 100,
	Default = 70,
	Darker = true,
	Tooltip = 'How strongly it smooths'
    })
    Acceleration = Freecam:CreateSlider({
	Name = 'Acceleration',
	Min = 1,
	Max = 40,
	Default = 10,
	Darker = true
    })
    Deceleration = Freecam:CreateSlider({
	Name = 'Deceleration',
	Min = 1,
	Max = 40,
	Default = 6,
	Darker = true
    })

    Fov = Freecam:CreateSlider({
	Name = 'Field of view',
	Min = 15,
	Max = 120,
	Default = 70
    })
    FovSpeed = Freecam:CreateSlider({
	Name = 'FOV transition',
	Min = 1,
	Max = 100,
	Default = 35,
	Tooltip = 'How fast your field of view changes'
    })
    Zoom = Freecam:CreateToggle({
	Name = 'Zoom',
	Function = function(call)
		for _, option in {ZoomFov, ZoomKey} do
			if option and option.Object then
				option.Object.Visible = call
			end
		end
	end,
	Tooltip = 'Hold a key to zoom in'
    })
    ZoomFov = Freecam:CreateSlider({
	Name = 'Zoom FOV',
	Min = 3,
	Max = 90,
	Default = 25,
	Darker = true,
	Visible = false
    })
    ZoomKey = Freecam:CreateDropdown({
	Name = 'Zoom key',
	List = {'X', 'C', 'V', 'F', 'G', 'R', 'T', 'LeftControl', 'LeftAlt'},
	Default = 'X',
	Darker = true,
	Visible = false
    })

    Roll = Freecam:CreateToggle({
	Name = 'Roll and tilt',
	Function = function(call)
		for _, option in {RollSpeed, Tilt} do
			if option and option.Object then
				option.Object.Visible = call
			end
		end
	end,
	Tooltip = 'Z and C roll the camera'
    })
    RollSpeed = Freecam:CreateSlider({
	Name = 'Roll speed',
	Min = 5,
	Max = 180,
	Default = 45,
	Suffix = 'deg/s',
	Darker = true,
	Visible = false
    })
    Tilt = Freecam:CreateSlider({
	Name = 'Strafe tilt',
	Min = 0,
	Max = 30,
	Default = 6,
	Suffix = 'deg',
	Darker = true,
	Visible = false,
	Tooltip = 'Banks into sideways moves'
    })

    Shake = Freecam:CreateToggle({
	Name = 'Camera shake',
	Function = function(call)
		for _, option in {ShakeAmount, ShakeSpeed} do
			if option and option.Object then
				option.Object.Visible = call
			end
		end
	end,
	Tooltip = 'Handheld wobble'
    })
    ShakeAmount = Freecam:CreateSlider({
	Name = 'Shake amount',
	Min = 1,
	Max = 100,
	Default = 25,
	Darker = true,
	Visible = false
    })
    ShakeSpeed = Freecam:CreateSlider({
	Name = 'Shake speed',
	Min = 0.1,
	Max = 10,
	Default = 1.5,
	Decimal = 10,
	Darker = true,
	Visible = false
    })

    Dof = Freecam:CreateToggle({
	Name = 'Depth of field',
	Function = function(call)
		for _, option in {AutoFocus, FocusDistance, FocusRange, DofStrength} do
			if option and option.Object then
				option.Object.Visible = call
			end
		end
	end
    })
    AutoFocus = Freecam:CreateToggle({
	Name = 'Auto focus',
	Default = true,
	Darker = true,
	Visible = false,
	Tooltip = 'Focuses on the centre of the frame'
    })
    FocusDistance = Freecam:CreateSlider({
	Name = 'Focus distance',
	Min = 1,
	Max = 500,
	Default = 25,
	Suffix = 'studs',
	Darker = true,
	Visible = false
    })
    FocusRange = Freecam:CreateSlider({
	Name = 'In focus range',
	Min = 1,
	Max = 200,
	Default = 20,
	Suffix = 'studs',
	Darker = true,
	Visible = false
    })
    DofStrength = Freecam:CreateSlider({
	Name = 'Blur strength',
	Min = 1,
	Max = 100,
	Default = 70,
	Darker = true,
	Visible = false
    })

    MotionBlur = Freecam:CreateGroup({
	Name = 'Motion blur',
	Tooltip = 'Blurs with the speed of the move'
    })
    MotionBlurAmount = MotionBlur:CreateSlider({
	Name = 'Motion blur amount',
	Min = 1,
	Max = 100,
	Default = 35,
	Darker = true
    })

    Orbit = Freecam:CreateToggle({
	Name = 'Orbit',
	Function = function(call)
		for _, option in {OrbitDirection, OrbitSpeed, OrbitDistance} do
			if option and option.Object then
				option.Object.Visible = call
			end
		end
	end,
	Tooltip = 'Circles whatever you were pointed at'
    })
    OrbitDirection = Freecam:CreateDropdown({
	Name = 'Orbit direction',
	List = {'Clockwise', 'Anticlockwise'},
	Default = 'Clockwise',
	Darker = true,
	Visible = false
    })
    OrbitSpeed = Freecam:CreateSlider({
	Name = 'Orbit speed',
	Min = 1,
	Max = 120,
	Default = 15,
	Suffix = 'deg/s',
	Darker = true,
	Visible = false
    })
    OrbitDistance = Freecam:CreateSlider({
	Name = 'Orbit distance',
	Min = 3,
	Max = 200,
	Default = 25,
	Suffix = 'studs',
	Darker = true,
	Visible = false
    })

    Dolly = Freecam:CreateToggle({
	Name = 'Dolly',
	Function = function(call)
		for _, option in {DollyDirection, DollySpeed} do
			if option and option.Object then
				option.Object.Visible = call
			end
		end
	end,
	Tooltip = 'Creeps along the camera axis on its own'
    })
    DollyDirection = Freecam:CreateDropdown({
	Name = 'Dolly direction',
	List = {'Forward', 'Backward'},
	Default = 'Forward',
	Darker = true,
	Visible = false
    })
    DollySpeed = Freecam:CreateSlider({
	Name = 'Dolly speed',
	Min = 0.5,
	Max = 60,
	Default = 4,
	Decimal = 10,
	Darker = true,
	Visible = false
    })

    Freecam:CreateButton({
	Name = 'Save keyframe',
	Function = function()
		if not Freecam.Enabled then
			notif('Freecam', 'Turn Freecam on first', 5, 'alert')
			return
		end
		table.insert(keyframes, snapshot())
		notif('Freecam', 'Keyframe '..#keyframes..' saved', 3, 'info')
	end,
	Tooltip = 'Saves the camera\'s position and direction'
    })
    Freecam:CreateButton({
	Name = 'Play keyframes',
	Function = function()
		if not Freecam.Enabled then
			notif('Freecam', 'Turn Freecam on first', 5, 'alert')
			return
		end
		if playback then
			stopPlayback()
		else
			startPlayback()
		end
	end,
	Tooltip = 'Runs the path, or stops one already running'
    })
    Freecam:CreateButton({
	Name = 'Clear keyframes',
	Function = function()
		stopPlayback()
		table.clear(keyframes)
		notif('Freecam', 'Keyframes cleared', 3, 'info')
	end
    })
    PathName = Freecam:CreateTextBox({Name = 'Path name', Placeholder = 'Camera path'})
    PathTarget = Freecam:CreateTextBox({Name = 'Path copy name', Placeholder = 'New name for rename or duplicate'})
    PathAction = Freecam:CreateDropdown({Name = 'Path action', List = {'Save', 'Load', 'Duplicate', 'Rename', 'Delete', 'Update keyframe', 'Delete keyframe'}})
    KeyframeIndex = Freecam:CreateSlider({Name = 'Keyframe', Min = 1, Max = 100, Default = 1, Darker = true})
    Freecam:CreateButton({
        Name = 'Apply path action',
        Function = function()
            local name, action = safePathName(), PathAction.Value
            if name == '' then notif('Freecam', 'Enter a path name', 4, 'alert'); return end
            if not isfolder(pathFolder) then makefolder(pathFolder) end
            local path = pathFolder..'/'..name..'.json'
            if action == 'Save' or action == 'Duplicate' then
                if #keyframes == 0 then notif('Freecam', 'Add a keyframe first', 4, 'alert'); return end
                local target = action == 'Duplicate' and tostring(PathTarget.Value):gsub('[^%w%-%_ ]', ''):sub(1, 40) or name
                if target == '' then notif('Freecam', 'Enter a copy name', 4, 'alert'); return end
                writefile(pathFolder..'/'..target..'.json', httpService:JSONEncode(encodeFrames()))
            elseif action == 'Load' then
                local ok, data = pcall(function() return httpService:JSONDecode(readfile(path)) end)
                if not ok or not decodeFrames(data) then notif('Freecam', 'Camera path is missing or corrupt', 5, 'alert'); return end
            elseif action == 'Rename' then
                if not isfile(path) then notif('Freecam', 'Camera path not found', 4, 'alert'); return end
                local renamed = tostring(PathTarget.Value):gsub('[^%w%-%_ ]', ''):sub(1, 40)
                if renamed == '' then notif('Freecam', 'Enter a new name', 4, 'alert'); return end
                writefile(pathFolder..'/'..renamed..'.json', readfile(path)); delfile(path)
            elseif action == 'Delete' then
                if isfile(path) then delfile(path) end
            elseif action == 'Update keyframe' then
                local index = math.clamp(KeyframeIndex.Value, 1, #keyframes)
                if not keyframes[index] then notif('Freecam', 'Keyframe not found', 4, 'alert'); return end
                keyframes[index] = snapshot()
            elseif action == 'Delete keyframe' then
                local index = math.clamp(KeyframeIndex.Value, 1, #keyframes)
                if keyframes[index] then table.remove(keyframes, index) end
            end
            notif('Freecam', action..' complete', 3, 'info')
        end
    })
    KeyframeTime = Freecam:CreateSlider({
	Name = 'Keyframe time',
	Min = 0.2,
	Max = 30,
	Default = 4,
	Decimal = 10,
	Suffix = 'sec',
	Darker = true,
	Tooltip = 'Seconds between keyframes'
    })
    KeyframeEase = Freecam:CreateToggle({
	Name = 'Ease keyframes',
	Default = true,
	Darker = true,
	Tooltip = 'Slows into and out of each one'
    })
    KeyframeLoop = Freecam:CreateToggle({
	Name = 'Loop keyframes',
	Darker = true
    })

    HideHud = Freecam:CreateToggle({
	Name = 'Hide HUD',
	Function = refreshInterface,
	Tooltip = 'Hides the game interface while filming'
    })
    Collision = Freecam:CreateToggle({Name = 'Camera collision', Default = true, Tooltip = 'Slides along solid geometry'})
end)
