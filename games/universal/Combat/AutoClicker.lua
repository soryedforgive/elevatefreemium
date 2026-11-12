run(function()
    local AutoClicker
    local Mode
    local CPS
    local RequireHold

    local hold = {Held = false, Began = 0, Ended = 0, Expire = 0, Sent = 0, Seen = 0, Eventless = false}

    local function wantedButton()
	return Mode.Value == 'RightClick' and Enum.UserInputType.MouseButton2 or Enum.UserInputType.MouseButton1
    end

    local function buttonDown()
	return inputService:IsMouseButtonPressed(wantedButton())
    end

    local function resetHold()
	hold.Began, hold.Ended, hold.Expire, hold.Sent, hold.Seen = 0, 0, 0, 0, 0
	hold.Eventless = false
	hold.Held = buttonDown()
    end

    local function isHeld()
	if hold.Eventless then
		return buttonDown()
	end
	return hold.Held
    end

    local function sendClick(send)
	local now = os.clock()
	if now >= hold.Expire then
		hold.Began, hold.Ended = 0, 0
	end
	if not hold.Eventless and hold.Sent >= 3 and hold.Seen == 0 then
		hold.Eventless = true
	end
	hold.Began += 1
	hold.Ended += 1
	hold.Sent += 1
	hold.Expire = now + 0.25
	send()
    end

    AutoClicker = vape.Categories.Combat:CreateModule({
	Name = 'AutoClicker',
	ExtraText = function() return CPS.ValueMin..'-'..CPS.ValueMax end,
	Function = function(callback)
		if callback then
			resetHold()
			AutoClicker:Clean(inputService.InputBegan:Connect(function(input)
				if input.UserInputType ~= wantedButton() then return end
				if hold.Began > 0 and os.clock() < hold.Expire then
					hold.Began -= 1
					hold.Seen += 1
					return
				end
				hold.Held = true
			end))
			AutoClicker:Clean(inputService.InputEnded:Connect(function(input)
				if input.UserInputType ~= wantedButton() then return end
				if hold.Ended > 0 and os.clock() < hold.Expire then
					hold.Ended -= 1
					hold.Seen += 1
					return
				end
				hold.Held = false
			end))
			AutoClicker:Clean(inputService.WindowFocusReleased:Connect(function()
				hold.Held = false
			end))

			repeat
				if Mode.Value == 'Tool' then
					local tool = getTool()
					if tool and inputService:IsMouseButtonPressed(0) then
						tool:Activate()
					end
				else
					local send = Mode.Value == 'Click' and mouse1click or mouse2click
					if send and (isrbxactive or iswindowactive)() then
						if canClick() and (not RequireHold.Enabled or isHeld()) then
							sendClick(send)
						end
					end
				end

				task.wait(1 / CPS.GetRandomValue())
			until not AutoClicker.Enabled
		end
	end,
	Tooltip = 'Clicks for you while you hold the mouse button',
    })
    Mode = AutoClicker:CreateDropdown({
	Name = 'Mode',
	List = { 'Tool', 'Click', 'RightClick' },
	Function = function()
		if RequireHold then
			resetHold()
		end
	end,
	Tooltip = 'Tool - uses held tools\nClick - left click\nRightClick - right click',
    })
    CPS = AutoClicker:CreateTwoSlider({
	Name = 'CPS',
	Min = 1,
	Max = 20,
	DefaultMin = 8,
	DefaultMax = 12,
    })
    RequireHold = AutoClicker:CreateToggle({
	Name = 'Require mouse down',
	Default = true,
	Function = function()
		if Mode then
			resetHold()
		end
	end,
	Tooltip = 'Only clicks while you hold that mouse button',
    })
end)
