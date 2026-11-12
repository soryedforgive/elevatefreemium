run(function()
    local AutoRejoin
    local Sort

    AutoRejoin = vape.Categories.Utility:CreateModule({
	Name = 'AutoRejoin',
	Function = function(callback)
		if callback then
			local check
			AutoRejoin:Clean(guiService.ErrorMessageChanged:Connect(function(str)
				if
					(not check or guiService:GetErrorCode() ~= Enum.ConnectionError.DisconnectLuaKick)
					and guiService:GetErrorCode() ~= Enum.ConnectionError.DisconnectConnectionLost
					and not str:lower():find('ban')
				then
					check = true
					serverHop(nil, Sort.Value)
				end
			end))
		end
	end,
	Tooltip = 'Rejoins a new server if you get disconnected or kicked',
    })
    Sort = AutoRejoin:CreateDropdown({
	Name = 'Sort',
	List = { 'Descending', 'Ascending' },
	Tooltip = 'Descending - prefers full servers\nAscending - prefers empty servers',
    })
end)
