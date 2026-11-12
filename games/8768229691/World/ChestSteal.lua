run(function()
	local ChestSteal
	local Range
	local Open
	local Delay = {}

	ChestSteal = vape.Categories.World:CreateModule({
		Name = 'ChestSteal',
		Function = function(callback)
			if callback then
				local chests = collection('block:chest', ChestSteal)
				local contents = remotes.chestContents and skywars.Remotes[remotes.chestContents]
				if not contents then
					notif('ChestSteal', 'The chest event was not found.', 8, 'warning')
					return
				end
				ChestSteal:Clean(contents:connect(function(chest, items)
					if Delay[chest] then return end

					for _, item in items do
						fireRemote('updateChest', chest, item.Type, -item.Quantity)
					end

					fireRemote('closeChest', chest)
					Delay[chest] = true
				end))

				repeat
					if entitylib.isAlive and not Open.Enabled then
						local localPosition = entitylib.character.RootPart.Position
						for _, v in chests do
							if v.PrimaryPart and (localPosition - v.PrimaryPart.Position).Magnitude <= Range.Value and not Delay[v] then
								fireRemote('openChest', v)
							end
						end
					end

					task.wait(0.1)
				until not ChestSteal.Enabled
			else
				table.clear(Delay)
			end
		end,
		Tooltip = 'Takes items from nearby chests'
	})
	Range = ChestSteal:CreateSlider({
		Name = 'Range',
		Min = 0,
		Max = 10,
		Default = 10,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Open = ChestSteal:CreateToggle({Name = 'GUI Check'})
end)
