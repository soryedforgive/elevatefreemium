run(function()
    local Parkour
    local AutoJump

    local probe = RaycastParams.new()
    probe.FilterType = Enum.RaycastFilterType.Exclude
    probe.RespectCanCollide = true

    local BLOCK_STUDS = 3
    local MAX_STEP = BLOCK_STUDS * 2

    local function hasStepAhead(root, direction)
        probe.FilterDescendantsInstances = {lplr.Character}

        local floor = workspace:Raycast(root.Position + Vector3.new(0, 0.6, 0), Vector3.new(0, -(MAX_STEP + 12), 0), probe)
        if not floor then return false end
        local floorY = floor.Position.Y

        local radius = math.max(root.Size.X, root.Size.Z) * 0.5
        local ahead = workspace:Raycast(Vector3.new(root.Position.X, floorY + 0.5, root.Position.Z), direction * (radius + 2.4), probe)
        if not ahead then return false end

        local ceiling = MAX_STEP + 4
        local top = workspace:Raycast(ahead.Position + Vector3.new(0, ceiling, 0), Vector3.new(0, -ceiling * 2, 0), probe)
        if not top then return false end

        local stepHeight = top.Position.Y - floorY
        return stepHeight > 0.35 and stepHeight <= MAX_STEP
    end

    Parkour = vape.Categories.World:CreateModule({
        Name = 'Parkour',
        Function = function(callback)
            if callback then
                local oldfloor
                Parkour:Clean(runService.RenderStepped:Connect(function()
                    if entitylib.isAlive then
                        local humanoid = entitylib.character.Humanoid
                        local material = humanoid.FloorMaterial
                        if material == Enum.Material.Air and oldfloor ~= Enum.Material.Air then
                            humanoid.Jump = true
                        end
                        oldfloor = material

                        if AutoJump.Enabled and material ~= Enum.Material.Air then
                            local root = entitylib.character.RootPart
                            local direction = humanoid.MoveDirection
                            local state = humanoid:GetState()
                            if root and direction.Magnitude > 0.1
                                and state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall
                                and hasStepAhead(root, direction.Unit) then
                                humanoid.Jump = true
                            end
                        end
                    end
                end))
            end
        end,
        Tooltip = 'Jumps when you reach an edge',
    })
    AutoJump = Parkour:CreateToggle({
        Name = 'Auto jump',
        Tooltip = 'Jumps onto low obstacles you run into'
    })
end)
