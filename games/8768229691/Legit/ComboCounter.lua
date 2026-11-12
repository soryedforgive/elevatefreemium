run(function()
    local ComboCounter
    local Timeout
    local Melee
    local ResetOnHit
    local ShowBest
    local label

    ComboCounter = vape.Categories.Legit:CreateModule({
        Name = 'ComboCounter',
        Function = function(callback)
            if callback then
                local combo, best, last = 0, 0, 0
                local lastText
                local function show()
                    local text = combo..(combo == 1 and ' hit' or ' hits')
                    if ShowBest.Enabled and best > 0 then
                        text ..= ' | best '..best
                    end
                    if text ~= lastText then
                        lastText = text
                        label.Text = text
                    end
                end

                local event = remotes.damage and skywars.Remotes and skywars.Remotes[remotes.damage]
                if event then
                    ComboCounter:Clean(event:connect(function(victim, _, _, _, _, attacker)
                        local character = lplr.Character
                        if not character then return end
                        if victim == character then
                            if ResetOnHit.Enabled and attacker and attacker ~= lplr and combo > 0 then
                                combo = 0
                                show()
                            end
                        elseif attacker == lplr and (not Melee.Enabled or (typeof(victim) == 'Instance' and playersService:GetPlayerFromCharacter(victim) ~= nil)) then
                            combo += 1
                            best = math.max(best, combo)
                            last = tick()
                            show()
                        end
                    end))
                end

                show()
                repeat
                    if combo > 0 and tick() - last > Timeout.Value then
                        combo = 0
                        show()
                    end
                    task.wait(0.1)
                until not ComboCounter.Enabled
            end
        end,
        Size = UDim2.fromOffset(130, 41),
        Category = 'Hud',
        Tooltip = 'Counts the hits you land in a row'
    })
    ComboCounter:CreateFont({
        Name = 'Font',
        Blacklist = 'Gotham',
        Function = function(val)
            label.FontFace = val
        end
    })
    ComboCounter:CreateColorSlider({
        Name = 'Colour',
        DefaultValue = 0,
        DefaultOpacity = 0.5,
        Function = function(hue, sat, val, opacity)
            label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
            label.BackgroundTransparency = 1 - opacity
        end
    })
    Timeout = ComboCounter:CreateSlider({
        Name = 'Reset after',
        Min = 1,
        Max = 10,
        Default = 3,
        Decimal = 10,
        Suffix = function(val)
            return val == 1 and 'second' or 'seconds'
        end,
        Tooltip = 'The combo ends when this long passes without landing a hit'
    })
    Melee = ComboCounter:CreateToggle({
        Name = 'Players only',
        Default = true,
        Tooltip = 'Hits on eggs do not count'
    })
    ResetOnHit = ComboCounter:CreateToggle({
        Name = 'Reset when hit',
        Default = true,
        Tooltip = 'Taking damage from someone else ends the combo'
    })
    ShowBest = ComboCounter:CreateToggle({
        Name = 'Show best',
        Tooltip = 'Also shows the longest combo since the module was turned on'
    })
    label = Instance.new('TextLabel')
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 0.5
    label.TextSize = 15
    label.Font = Enum.Font.Gotham
    label.Text = '0 hits'
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundColor3 = Color3.new()
    label.Parent = ComboCounter.Children
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = label
end)
