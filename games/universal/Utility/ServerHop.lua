run(function()
    local ServerHop
    local Sort

    ServerHop = vape.Categories.Utility:CreateModule({
	Name = 'ServerHop',
	Function = function(callback)
		if callback then
			ServerHop:Toggle()
			serverHop(nil, Sort.Value)
		end
	end,
	Tooltip = 'Teleports you to a different server',
    })
    Sort = ServerHop:CreateDropdown({
	Name = 'Sort',
	List = { 'Descending', 'Ascending' },
	Tooltip = 'Descending - prefers full servers\nAscending - prefers empty servers',
    })
    ServerHop:CreateButton({
	Name = 'Rejoin Previous Server',
	Function = function()
		notif(
			'ServerHop',
			shared.vapeserverhopprevious and 'Rejoining previous server...' or 'Cannot find previous server',
			5
		)
		if shared.vapeserverhopprevious then
			teleportService:TeleportToPlaceInstance(game.PlaceId, shared.vapeserverhopprevious)
		end
	end,
    })
end)
