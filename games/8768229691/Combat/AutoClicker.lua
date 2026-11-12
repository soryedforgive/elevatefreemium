run(function()
	local AutoClicker
	local CPS
	local Blocks
	local BlocksCPS = {Object = {}}
	local Thread
	local click = {UserInputType = Enum.UserInputType.MouseButton1, KeyCode = Enum.KeyCode.Unknown}

	local function AutoClick()
		if Thread then
			task.cancel(Thread)
		end
		Thread = task.delay(1 / 8, function()
			repeat
				local held = store.hand
				if held then
					if held.Rewrite and Blocks.Enabled then
						local block = blockMeta(held)
						local ray = block and skywars.BlockRaycastController:executeRaycast(inputService:GetMouseLocation(), 1, 0, block)
						if ray and ray.BlockPosition then
							skywars.BlockController:placeBlock(ray.BlockPosition, held.Name, block, ray.Rotation)
						end
					elseif held.Melee then
						skywars.MeleeController:strike(click)
					end
				end

				task.wait(1 / (held and held.Rewrite and BlocksCPS or CPS).GetRandomValue())
			until not AutoClicker.Enabled
		end)
	end

	AutoClicker = vape.Categories.Combat:CreateModule({
		Name = 'AutoClicker',
		Function = function(callback)
			if callback then
				AutoClicker:Clean(inputService.InputBegan:Connect(function(input, gameProcessed)
					if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton1 then
						AutoClick()
					end
				end))

				AutoClicker:Clean(inputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and Thread then
						task.cancel(Thread)
						Thread = nil
					end
				end))
			elseif Thread then
				task.cancel(Thread)
				Thread = nil
			end
		end,
		Tooltip = 'Clicks for you while you hold the attack button'
	})
	CPS = AutoClicker:CreateTwoSlider({
		Name = 'CPS',
		Min = 1,
		Max = 9,
		DefaultMin = 9,
		DefaultMax = 9
	})
	Blocks = AutoClicker:CreateGroup({
		Name = 'Place Blocks',
		Default = true,
	})
	BlocksCPS = Blocks:CreateTwoSlider({
		Name = 'Block CPS',
		Min = 1,
		Max = 20,
		DefaultMin = 9,
		DefaultMax = 9,
		Darker = true
	})
end)
