run(function()
	local AutoQueue
	local Delay
	local Notification

	AutoQueue = vape.Categories.Utility:CreateModule({
		Name = 'AutoQueue',
		Function = function(callback)
			if callback then
				AutoQueue:Clean(vapeEvents.MatchEnded.Event:Connect(function()
					if Notification.Enabled and Delay.Value > 0 then
						notif('AutoQueue', string.format('Playing again in %.1f seconds', Delay.Value), Delay.Value)
					end
					task.delay(Delay.Value, function()
						if not AutoQueue.Enabled then return end
						local remote = replicatedStorage:FindFirstChild('Remotes') and replicatedStorage.Remotes:FindFirstChild('QueueAction')
						if remote then
							pcall(remote.InvokeServer, remote, 'PlayAgain')
						end
					end)
				end))
			end
		end,
		Tooltip = 'Queues for the next match when one ends'
	})
	Delay = AutoQueue:CreateSlider({
		Name = 'Delay',
		Min = 0,
		Max = 10,
		Default = 1,
		Decimal = 10,
		Suffix = 's'
	})
	Notification = AutoQueue:CreateToggle({
		Name = 'Notification',
		Default = true
	})
end)
