run(function()
	local AutoQueue
	local Join
	local Hop
	local Ranked
	local RankedDelay
	local TRIES, RETRY = 3, 5

	AutoQueue = vape.Categories.Utility:CreateModule({
		Name = 'AutoQueue',
		Function = function(callback)
			if callback then
				local sent = 0
				local endedAt, tries, queued
				AutoQueue:Clean(remotes.Queue.OnClientEvent:Connect(function(state)
					if state == true or state == 'Found' then
						queued = true
					end
				end))
				repeat
					local status, timer = bedfight.GameInfo:FindFirstChild('Status'), bedfight.GameInfo:FindFirstChild('Timer')
					local mode = bedfight.GameInfo:FindFirstChild('GameMode')
					if Ranked.Enabled and status and status.Value == 'Ended' and mode and tostring(mode.Value):find('Ranked', 1, true) then
						if not endedAt then
							endedAt, tries, queued = tick(), 0, false
						end
						if not queued and tries < TRIES and tick() - endedAt >= RankedDelay.Value + tries * RETRY then
							tries += 1
							fireRemote('Queue', 'Queue Again')
						end
					else
						endedAt = nil
					end
					if not inMatch() and status and timer and status.Value == 'Started' and tick() - sent > 8 then
						if timer.Value <= 180 then
							if Join.Enabled and lplr:GetAttribute('CanJoinGame') then
								sent = tick()
								fireRemote('Join')
							end
						elseif Hop.Enabled then
							sent = tick()
							fireRemote('QueueToOpenServer')
						end
					end
					task.wait(1)
				until not AutoQueue.Enabled
			end
		end,
		Tooltip = 'Queues for the next match from the lobby or while spectating'
	})
	Join = AutoQueue:CreateToggle({
		Name = 'Join running match',
		Default = true,
		Tooltip = 'Joins a running match if it has only just started'
	})
	Hop = AutoQueue:CreateToggle({
		Name = 'Find open server',
		Default = true,
		Tooltip = 'Finds a server with an open match when this one closes'
	})
	Ranked = AutoQueue:CreateGroup({
		Name = 'Play again after ranked',
		Default = true,
		Tooltip = 'Plays again after a ranked match'
	})
	RankedDelay = Ranked:CreateSlider({
		Name = 'Play again delay',
		Min = 0,
		Max = 15,
		Default = 1,
		Suffix = 's',
		Tooltip = 'How long to wait after the match'
	})
end)
