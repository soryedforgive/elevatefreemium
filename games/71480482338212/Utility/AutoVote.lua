run(function()
	local AutoVote
	local Maps
	local Anyway
	local rand = Random.new()

	local function choices()
		local list = {}
		local values = bedfight.GameInfo:FindFirstChild('MapVoteValues')
		for _, entry in values and values:GetChildren() or {} do
			local voter = entry:FindFirstChild('MapVoter')
			local pad = voter and voter.Value
			local vote = pad and pad:FindFirstChild('MapVote')
			local map = vote and vote.Value
			if map and map.Name ~= '' then
				table.insert(list, map)
			end
		end
		return list
	end

	local function pick()
		local list = choices()
		for _, wanted in Maps.ListEnabled do
			wanted = wanted:lower()
			for _, map in list do
				if map.Name:lower():find(wanted, 1, true) then
					return map
				end
			end
		end
		return Anyway.Enabled and list[1] or nil
	end

	AutoVote = vape.Categories.Utility:CreateModule({
		Name = 'AutoVote',
		Function = function(callback)
			if not callback then return end
			local status = bedfight.GameInfo:FindFirstChild('Status')
			if not status then
				notif('AutoVote', 'Map voting was not found.', 5, 'warning')
				return
			end
			local voted = false
			local function check()
				if status.Value ~= 'Voting' then
					voted = false
					return
				end
				if voted then return end
				voted = true
				task.delay(rand:NextNumber(0.6, 1.4), function()
					if not (AutoVote.Enabled and status.Value == 'Voting') then return end
					local map = pick()
					if map then
						fireRemote('VoteMap', map)
					else
						voted = false
					end
				end)
			end
			AutoVote:Clean(status:GetPropertyChangedSignal('Value'):Connect(check))
			check()
		end,
		Tooltip = 'Votes for your map when voting opens'
	})
	Maps = AutoVote:CreateTextList({
		Name = 'Maps',
		Placeholder = 'map name',
		Tooltip = 'Maps in order of preference'
	})
	Anyway = AutoVote:CreateToggle({
		Name = 'Vote anyway',
		Tooltip = 'Votes for the first map on offer when none of yours is'
	})
end)
