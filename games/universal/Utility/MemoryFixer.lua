run(function()
	local MemoryFixer
	local Interval
	local Notify
	local signals = {'Heartbeat', 'PostSimulation', 'PreAnimation', 'PreRender', 'PreSimulation', 'RenderStepped', 'Stepped'}

	local hashes = setmetatable({}, {__mode = 'k'})
	local function hashOf(fn)
		local hash = hashes[fn]
		if not hash then
			hash = getfunctionhash(fn)
			hashes[fn] = hash
		end
		return hash
	end

	local function clean()
		if not getconnections or not getfunctionhash or not isexecutorclosure then
			return 0
		end
		local removed, seen = 0, {}
		local started = os.clock()
		for index, v in signals do
			if index > 1 then
				task.wait()
				started = os.clock()
			end
			local profiler = vape.Libraries.profiler
			local signal = profiler and profiler.RealSignal(v) or runService[v]
			for _, connection in getconnections(signal) do
				if os.clock() - started > 0.002 then
					task.wait()
					started = os.clock()
				end
				if connection.Function and not connection.ForeignState and isexecutorclosure(connection.Function) then
					local fn = profiler and profiler.Unwrap(connection.Function) or connection.Function
					local hash = v..hashOf(fn)
					if seen[hash] then
						connection:Disconnect()
						removed += 1
					else
						seen[hash] = true
					end
				end
			end
		end
		return removed
	end

	MemoryFixer = vape.Categories.Utility:CreateModule({
		Name = 'MemoryFixer',
		Function = function(callback)
			if callback then
				if not (getconnections and getfunctionhash and isexecutorclosure) then
					notif('MemoryFixer', 'Your executor cannot list or compare connections.', 6, 'warning')
				end
				MemoryFixer:Clean(task.spawn(function()
					repeat
						local removed = clean()
						if Notify.Enabled and removed > 0 then
							notif('MemoryFixer', `Dropped {removed} leftover connection{removed == 1 and '' or 's'}`, 5)
						end
						task.wait(Interval.Value)
					until not MemoryFixer.Enabled
				end))
			end
		end,
		Tooltip = 'Clears leftovers from earlier injections'
	})
	Interval = MemoryFixer:CreateSlider({
		Name = 'Interval',
		Min = 5,
		Max = 300,
		Default = 30,
		Suffix = 'seconds'
	})
	Notify = MemoryFixer:CreateToggle({
		Name = 'Notify',
		Default = true,
		Tooltip = 'Tells you how many it dropped'
	})
	MemoryFixer:CreateButton({
		Name = 'Clean now',
		Function = function()
			local removed = clean()
			notif('MemoryFixer', `Dropped {removed} leftover connection{removed == 1 and '' or 's'}`, 5)
		end
	})
end)
