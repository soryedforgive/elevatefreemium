run(function()
    local FFlag
    local Flags

    local function executorName()
	local ok, name = pcall(function()
		return identifyexecutor()
	end)
	return ok and type(name) == 'string' and name or 'this executor'
    end

    local function ChangeFFlag(suc)
	if not suc or not FFlag.Enabled then
		return
	end
	local success, json = pcall(function()
		return httpService:JSONDecode(Flags.Value)
	end)

	if not success or typeof(json) ~= 'table' then
		notif('ElevateV4', 'Invalid json format for fflag', 12, 'warning')
		return
	end

	local applied, failed = 0, 0
	for i, v in json do
		i = tostring(i):gsub('DFInt', '')
			:gsub('DFFlag', '')
			:gsub('FFlag', '')
			:gsub('FInt', '')
			:gsub('DFString', '')
			:gsub('FString', '')

		if pcall(setfflag, i, tostring(v)) then
			applied += 1
		else
			failed += 1
		end
	end

	if applied > 0 then
		notif('ElevateV4', applied..' FFlag'..(applied == 1 and '' or 's')..' applied'..(failed > 0 and ', '..failed..' refused' or '')..'. Go in a new game to take effect', 12, 'info')
	else
		notif('ElevateV4', 'None of the FFlags could be applied', 12, 'warning')
	end
    end

    FFlag = vape.Categories.Legit:CreateModule({
	Name = 'FFlagEditor',
	Function = function(call)
		if call then
			if type(setfflag) ~= 'function' then
				notif('FFlagEditor', 'This module needs setfflag, which '..executorName()..' does not have.', 8, 'warning')
				FFlag:Toggle()
				return
			end
			ChangeFFlag(true)
		elseif type(setfflag) == 'function' then
			notif('ElevateV4', 'Inorder to disable fflags you have applied, You need to restart roblox', 20, 'info')
		end
	end,
	Tooltip = 'Applies fast flags that you paste in as JSON',
    })

    Flags = FFlag:CreateTextBox({
	Name = 'FFlags',
	Placeholder = 'json format only',
	Function = ChangeFFlag,
    })
end)
