run(function()
	local InvMove
	local old

	InvMove = vape.Categories.Blatant:CreateModule({
		Name = 'InvMove',
		Function = function(callback)
			if callback then
				old = skywars.FocusedController.enableFocus
				skywars.FocusedController.enableFocus = function(self, screen, ...)
					return old(self, true, ...)
				end
			elseif old then
				skywars.FocusedController.enableFocus = old
				old = nil
			end
		end,
		Tooltip = 'Lets you move while menus are open'
	})
end)
