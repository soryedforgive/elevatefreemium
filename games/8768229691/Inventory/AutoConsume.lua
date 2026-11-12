run(function()
	local AutoConsume

	local function consumeCheck()
		if (lplr:GetAttribute('Shield') or 0) <= 0 and getItem('Shield') then
			fireRemote('updateActiveItem', 'Shield')
			fireRemote('usePowerUp')
			equip(nil)
		end
	end

	AutoConsume = vape.Categories.Inventory:CreateModule({
		Name = 'AutoConsume',
		Function = function(callback)
			if callback then
				AutoConsume:Clean(vapeEvents.InventoryAmountChanged.Event:Connect(consumeCheck))
				AutoConsume:Clean(lplr:GetAttributeChangedSignal('Shield'):Connect(consumeCheck))
				consumeCheck()
			end
		end,
		Tooltip = 'Uses shield potions for you'
	})
end)
