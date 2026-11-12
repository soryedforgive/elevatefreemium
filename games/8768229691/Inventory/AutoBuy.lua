run(function()
	local AutoBuy
	local Buy
	local Upgrades
	local BlockAmount = {Object = {}, Value = 16}
	local Functions = {}

	local function buyCheck(currencytable)
		for _, v in Functions do
			v(currencytable)
		end
	end

	local function buyUpgrade(name, upgrade, currencytable)
		if not (name and upgrade) then return end
		local currentitem
		for shopIndex, shopItem in upgrade.Items do
			if shopItem.ItemType == name then
				currentitem = shopIndex
			end
		end

		if not currentitem then return end

		for i = currentitem + 1, #upgrade.Items do
			local nextitem = upgrade.Items[i]
			if nextitem and (currencytable[nextitem.CurrencyType] or 0) >= nextitem.Price then
				fireRemote('purchaseItemUpgrade', 'Blacksmith', upgrade.ItemIndex)
				currencytable[nextitem.CurrencyType] -= nextitem.Price
			else
				break
			end
		end
	end

	local function buyTeamUpgrade(upgrade, currencytable)
		local owned = skywars.Store:getState().TeamUpgrades
		local currentitem = owned and owned[upgrade.Id] or 0
		for i = currentitem + 1, #upgrade.Tiers do
			local nextitem = upgrade.Tiers[i]
			if nextitem and (currencytable[nextitem.CurrencyType] or 0) >= nextitem.Price then
				fireRemote('purchaseTeamUpgrade', 'Merchant', upgrade.ItemIndex)
				currencytable[nextitem.CurrencyType] -= nextitem.Price
			else
				break
			end
		end
	end

	local function buyBlocks(currencytable)
		local owned = getItem('TeamConcrete')
		if owned and owned.Quantity >= BlockAmount.Value then return end
		for _, shopItem in skywars.Shop.Blacksmith.Items do
			if shopItem.ItemType == 'TeamConcrete' then
				if (currencytable[shopItem.CurrencyType] or 0) >= shopItem.Price then
					fireRemote('purchaseItem', 'Blacksmith', shopItem.ItemIndex)
					currencytable[shopItem.CurrencyType] -= shopItem.Price
				end
				break
			end
		end
	end

	local function chestplate()
		local worn = lplr:GetAttribute('Chestplate')
		if worn then return worn end
		if lplr.Character then
			for _, v in lplr.Character:GetChildren() do
				if v:GetAttribute('Armour') and v.Name:find('Chestplate') then
					return v.Name
				end
			end
		end
	end

	AutoBuy = vape.Categories.Inventory:CreateModule({
		Name = 'AutoBuy',
		Function = function(callback)
			if callback then
				AutoBuy:Clean(vapeEvents.CurrencyChange.Event:Connect(buyCheck))
				AutoBuy:Clean(vapeEvents.InventoryAmountChanged.Event:Connect(function()
					local state = skywars.Store:getState().GameCurrency
					if Buy and Buy:Has('Blocks') and state then
						buyBlocks(table.clone(state.Quantities))
					end
				end))
				local currency = skywars.Store:getState().GameCurrency
				if currency then
					buyCheck(table.clone(currency.Quantities))
				end
			end
		end,
		Tooltip = 'Buys gear and upgrades as soon as you can afford them'
	})
	local upgradeNames = {}
	for _, v in skywars.Shop.Merchant.TeamUpgrades do
		table.insert(upgradeNames, v.Name)
	end

	local function apply()
		local blacksmith = skywars.Shop.Blacksmith.ItemUpgrades
		Functions[1] = Buy:Has('Armor') and function(currencytable)
			buyUpgrade(chestplate(), blacksmith[1], currencytable)
		end or nil
		Functions[2] = Buy:Has('Sword') and function(currencytable)
			buyUpgrade(store.tools.sword and store.tools.sword.Name, blacksmith[2], currencytable)
		end or nil
		Functions[3] = Buy:Has('Pickaxe') and function(currencytable)
			buyUpgrade(store.tools.pickaxe and store.tools.pickaxe.Name, blacksmith[3], currencytable)
		end or nil
		Functions[4] = Buy:Has('Blocks') and buyBlocks or nil
		for i, v in skywars.Shop.Merchant.TeamUpgrades do
			Functions[4 + i] = Upgrades and Upgrades:Has(v.Name) and function(currencytable)
				buyTeamUpgrade(v, currencytable)
			end or nil
		end
	end

	Buy = AutoBuy:CreateMultiDropdown({
		Name = 'Buy',
		List = {'Sword', 'Armor', 'Pickaxe', 'Blocks'},
		Default = {'Sword', 'Armor', 'Pickaxe'},
		Function = apply,
		Tooltip = 'What it buys'
	})
	BlockAmount = AutoBuy:CreateSlider({
		Name = 'Keep blocks',
		Min = 1,
		Max = 64,
		Default = 16,
		Darker = true,
		Visible = function() return Buy:Has('Blocks') end
	})
	Upgrades = AutoBuy:CreateMultiDropdown({
		Name = 'Team upgrades',
		List = upgradeNames,
		Default = {'Generator', 'Vampyrism'},
		Function = apply,
		Tooltip = 'Team upgrades to buy'
	})
	apply()
end)
