run(function()
    local InfiniteJump
    local Mode
    local MaxJumps
    local TP
    local rayCheck = RaycastParams.new()
    rayCheck.RespectCanCollide = true
    local jumps = 0
    local lastJump = 0
    local JUMP_DEBOUNCE = 0.09
    local groundTick, tpTick, tpToggle, oldy = tick(), tick(), true, nil

    local function isGrounded()
        local humanoid = entitylib.isAlive and entitylib.character and entitylib.character.Humanoid
        return humanoid ~= nil and humanoid.FloorMaterial ~= Enum.Material.Air
    end

    local function tpDownStep()
        local character = entitylib.character
        local root = character and character.RootPart
        if not root or not root.Parent then return end
        if isnetworkowner and not isnetworkowner(root) then return end

        rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
        rayCheck.CollisionGroup = root.CollisionGroup

        if tpToggle then
            if workspace:Raycast(root.Position, Vector3.new(0, -4.5, 0), rayCheck) then
                groundTick = tick()
            end
            if oldy or vape.FloatExempt or (tick() - groundTick) <= 2 then return end
            local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayCheck)
            if not ray then return end
            tpToggle = false
            oldy = root.Position.Y
            tpTick = tick() + 0.11
            root.CFrame = CFrame.lookAlong(
                Vector3.new(root.Position.X, ray.Position.Y + (character.HipHeight or 3), root.Position.Z),
                root.CFrame.LookVector
            )
        elseif oldy then
            if tpTick < tick() then
                root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, oldy, root.Position.Z), root.CFrame.LookVector)
                tpToggle = true
                oldy = nil
                groundTick = tick()
            else
                local velocity = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(velocity.X, 0, velocity.Z)
            end
        end
    end

    local function jumpHeld()
        if inputService:GetFocusedTextBox() then return false end
        if inputService:IsKeyDown(Enum.KeyCode.Space) or inputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA) then
            return true
        end
        local humanoid = entitylib.character and entitylib.character.Humanoid
        return humanoid ~= nil and humanoid.Jump == true
    end

    local function jumpVelocity(humanoid)
        if humanoid.UseJumpPower then
            return humanoid.JumpPower
        end
        return math.sqrt(2 * workspace.Gravity * humanoid.JumpHeight)
    end

    InfiniteJump = vape.Categories.Blatant:CreateModule({
	Name = 'InfiniteJump',
	Tooltip = 'Lets you jump again in mid-air',
	Function = function(callback: boolean)
		if callback then
			jumps = 0
			lastJump = 0
			groundTick, tpTick, tpToggle, oldy = tick(), tick(), true, nil

			InfiniteJump:Clean(runService.PreSimulation:Connect(function()
				if not entitylib.isAlive then return end
				if isGrounded() then jumps = 0 end
				if TP.Enabled then tpDownStep() end
				if Mode.Value == 'Hold' and not isGrounded() and jumpHeld() then
					local character = entitylib.character
					local humanoid, root = character.Humanoid, character.RootPart
					if humanoid and root then
						local velocity = root.AssemblyLinearVelocity
						root.AssemblyLinearVelocity = Vector3.new(velocity.X, jumpVelocity(humanoid), velocity.Z)
					end
				end
			end))

			InfiniteJump:Clean(inputService.JumpRequest:Connect(function()
				if not entitylib.isAlive then return end
				local character = entitylib.character
				local humanoid, root = character.Humanoid, character.RootPart
				if not humanoid or not root then return end

				if isGrounded() then
					jumps = 1
					lastJump = tick()
					return
				end

				if tick() - lastJump < JUMP_DEBOUNCE then return end
				if Mode.Value == 'Hold' then return end
				if jumps >= MaxJumps.Value then return end
				jumps += 1
				lastJump = tick()
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end))
		end
	end,
	ExtraText = function()
		if TP.Enabled then return 'TP Down' end
		if Mode.Value == 'Jump' then return jumps .. '/' .. tostring(MaxJumps.Value) end
		return Mode.Value
	end,
    })
    Mode = InfiniteJump:CreateDropdown({
	Name = 'Mode',
	List = { 'Jump', 'Hold' },
	Default = 'Jump',
	Function = function(value)
		if MaxJumps and MaxJumps.Object then
			MaxJumps.Object.Visible = value == 'Jump'
		end
	end,
	Tooltip = 'Jump - a set number of air jumps\nHold - rise while you hold jump',
    })
    MaxJumps = InfiniteJump:CreateSlider({
	Name = 'Max jumps',
	Min = 1,
	Max = 20,
	Default = 2,
	Tooltip = 'Air jumps you get before landing again',
	Visible = Mode.Value == 'Jump',
    })
    TP = InfiniteJump:CreateToggle({
	Name = 'TP Down',
	Tooltip = 'Touches the ground when you have been in the air too long',
    })
end)
