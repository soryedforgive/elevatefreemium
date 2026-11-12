run(function()
	local HttpService = httpService
	local RegionLock
	local Regions

	RegionLock = vape.Categories.Utility:CreateModule({
		Name = "RegionLock",
		Function = function(Callback: boolean)
			writefile(`ElevateV4/profiles/regionlock.txt`, tostring(Callback))
			getgenv().regionLockActive = Callback
		end,
		Tooltip = 'Skips matches hosted outside your chosen regions'
	})

	Regions = RegionLock:CreateTextList({
		Name = "Regions",
		Placeholder = "NA / EU / SEA",
		Default = {"NA", "EU", "SEA"},
		Function = function()
			if not Regions then
				return
			end
			for i: number, v: string in Regions.List do
				Regions.List[i] = v:gsub("%s+", ""):upper()
			end
			for i: number, v: string in Regions.ListEnabled do
				Regions.ListEnabled[i] = v:gsub("%s+", ""):upper()
			end
		end,
		Tooltip = 'Regions to accept'
	})
end)
