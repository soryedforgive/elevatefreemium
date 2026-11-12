run(function()
	local OriginalLevels: {[any]: number} = {}

	vape.Categories.Utility:CreateModule({
		Name = "LevelBypass",
		Function = function(Callback: boolean)
			if Callback then
				for _, Metadata: any in bedwars.QueueMeta do
					if type(Metadata.playerLevelReq) == "number" and Metadata.playerLevelReq > 0 then
						OriginalLevels[Metadata] = Metadata.playerLevelReq
						Metadata.playerLevelReq = 0
					end
				end
			else
				for Metadata: any, Level: number in OriginalLevels do
					if Metadata.playerLevelReq == 0 then
						Metadata.playerLevelReq = Level
					end
				end
				table.clear(OriginalLevels)
			end
		end,
		Tooltip = 'Removes level locks on lobby queues'
	})
end)
