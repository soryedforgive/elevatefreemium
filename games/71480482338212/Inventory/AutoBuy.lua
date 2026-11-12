run(function()
	local AutoBuy
	local Buy
	local BlockAmount
	local ArrowAmount
	local GUI
	local SmartCheck
	local Upgrades
	local Custom, CustomPost = {}, {}
	local tried = {}
	local TIERED = {Swords = true, Armor = true, Pickaxes = true}

	local function prompt(tag)
		local best, dist = nil, 10
		for _, v in collectionService:GetTagged(tag) do
			if v:IsA('BasePart') and v:IsDescendantOf(workspace) then
				local mag = (v.Position - entitylib.character.RootPart.Position).Magnitude
				if mag <= dist then
					best, dist = v, mag
				end
			end
		end
		return best
	end

	local function buyResult(name, data)
		local gui = lplr.PlayerGui:FindFirstChild('ItemShopGui')
		local module = gui and gui:FindFirstChild('ItemShopHandler')
		if not module then return nil end
		local ok, handler = pcall(require, module)
		if not ok then return nil end
		local okr, result = pcall(handler.GetBuyResult, name, data)
		return okr and result or nil
	end

	local function count(pattern)
		local total = 0
		for name, amount in store.inventory do
			if name:find(pattern) then
				total += amount
			end
		end
		return total
	end

	local function screenOpen(name)
		local gui = lplr.PlayerGui:FindFirstChild(name)
		return gui ~= nil and gui:IsA('LayerCollector') and gui.Enabled
	end

	local function shop(stand)
		local kit = lplr:FindFirstChild('Kit')
		local list = bedfight.ItemShopData.GetItemShop(false, kit and kit.Value or '')
		local function try(category, name, data, want, have)
			local last = tried[name]
			if last and last.Until > tick() and not (have and last.Expect and have >= last.Expect) then return end
			if buyResult(name, data) ~= 'Buy' then return end
			local per = data.Amount or 1
			local n = want and have and math.ceil((want - have) / per) or 1
			for currency, price in data.Price or {} do
				if type(price) == 'number' and price > 0 then
					n = math.min(n, math.floor((getItem(currency) or 0) / price))
				end
			end
			n = math.clamp(n, 1, 4)
			tried[name] = {Until = tick() + 1.5, Expect = have and have + n * per}
			for _ = 1, n do
				fireRemote('PurchaseItemShopItem', stand, category, name)
			end
			return true
		end

		local function extras(entries)
			for _, want in entries do
				for _, entry in list do
					for _, data in entry.List do
						if data.Name:lower() == want.Name then
							local have = data.ReplaceName and count(data.Name..'$') or getItem(data.Name) or 0
							if have < want.Amount and try(entry.Category, data.Name, data, want.Amount, have) then return true end
						end
					end
				end
			end
			return false
		end
		if extras(Custom) then return true end

		local saving = {}

		local function blocked(data)
			for currency in data.Price or {} do
				if saving[currency] then return true end
			end
			return false
		end

		local function reserve(data)
			if SmartCheck.Enabled and data then
				for currency in data.Price or {} do
					saving[currency] = true
				end
			end
		end

		for _, key in Buy.List do
			if Buy:Has(key) then
				for _, entry in list do
					local category = entry.Category
					if TIERED[key] and category == key then
						local nextTier
						for _, data in entry.List do
							if data.Max == 1 and not data.Kit then
								local result = buyResult(data.Name, data)
								if result == 'Max' then
									nextTier = nil
								elseif result == 'Not Enough' and not nextTier then
									nextTier = data
								end
							end
						end
						for i = #entry.List, 1, -1 do
							local data = entry.List[i]
							if data.Max == 1 then
								if not data.Kit and buyResult(data.Name, data) == 'Max' then
									break
								end
								if not blocked(data) and try(category, data.Name, data) then return true end
							end
						end
						reserve(nextTier)
					elseif not TIERED[key] then
						for i = #entry.List, 1, -1 do
							local data = entry.List[i]
							if (key == 'Bow' or key == 'Crossbow') and category == 'Ranged' and data.Name == key and data.Max == 1 then
								if not blocked(data) and try(category, data.Name, data) then return true end
								if not getItem(key) and buyResult(data.Name, data) == 'Not Enough' then
									reserve(data)
								end
							elseif key == 'Wool' and data.Name == 'Wool' then
								local have = count('Wool$')
								if have < BlockAmount.Value and not blocked(data) and try(category, data.Name, data, BlockAmount.Value, have) then return true end
							elseif key == 'Arrows' and data.Name == 'Arrow' and (getItem('Bow') or getItem('Crossbow')) then
								local have = count('^Arrow$')
								if have < ArrowAmount.Value then
									if not blocked(data) and try(category, data.Name, data, ArrowAmount.Value, have) then return true end
									if buyResult(data.Name, data) == 'Not Enough' then
										reserve(data)
									end
								end
							end
						end
					end
				end
			end
		end
		return extras(CustomPost)
	end

	local function upgrade(stand)
		local folder = bedfight.TeamUpgrades:FindFirstChild(lplr.Team.Name)
		if not folder then return end
		for index, name in bedfight.TeamUpgradesData.UpgradesOrder do
			local value, meta = folder:FindFirstChild(name), bedfight.TeamUpgradesData.Upgrades[name]
			local price = Upgrades and Upgrades:Has(name) and value and meta and meta.Prices[value.Value + 1]
			if price then
				local afford = true
				for currency, amount in price do
					if (getItem(currency) or 0) < amount then
						afford = false
					end
				end
				if afford then
					fireRemote('TeamUpgrade', stand, index)
					return
				end
			end
		end
	end

	AutoBuy = vape.Categories.Inventory:CreateModule({
		Name = 'AutoBuy',
		Function = function(callback)
			if callback then
				repeat
					local bought = false
					if entitylib.isAlive and inMatch() then
						local stand = prompt('ItemShopPrompt')
						if stand and (not GUI.Enabled or screenOpen('ItemShopGui')) then
							bought = shop(stand)
						end
						stand = prompt('TeamUpgradePrompt')
						if stand and (not GUI.Enabled or screenOpen('TeamUpgradesGui')) then
							upgrade(stand)
						end
					end
					task.wait(bought and 0.1 or 0.35)
				until not AutoBuy.Enabled
			end
		end,
		Tooltip = 'Buys gear and upgrades as soon as you can afford them near a shop'
	})
	Buy = AutoBuy:CreateMultiDropdown({
		Name = 'Buy',
		List = {'Swords', 'Armor', 'Pickaxes', 'Bow', 'Crossbow', 'Arrows', 'Wool'},
		Default = {'Swords', 'Armor'},
		Tooltip = 'What it buys, in this order of priority'
	})
	ArrowAmount = AutoBuy:CreateSlider({
		Name = 'Keep arrows',
		Min = 8,
		Max = 64,
		Default = 16,
		Darker = true,
		Visible = function() return Buy:Has('Arrows') end
	})
	BlockAmount = AutoBuy:CreateSlider({
		Name = 'Keep wool',
		Min = 8,
		Max = 128,
		Default = 32,
		Darker = true,
		Visible = function() return Buy:Has('Wool') end
	})
	GUI = AutoBuy:CreateToggle({
		Name = 'GUI check',
		Tooltip = 'Only buys while a shop screen is open'
	})
	SmartCheck = AutoBuy:CreateToggle({
		Name = 'Smart check',
		Default = true,
		Tooltip = 'Saves resources for higher priority items instead of buying cheaper ones first'
	})
	AutoBuy:CreateTextList({
		Name = 'Item',
		Placeholder = 'priority/item/amount/after',
		Tooltip = 'Extra items to keep in stock, such as 1/Fireball/2',
		Function = function(list)
			table.clear(Custom)
			table.clear(CustomPost)
			for _, entry in list do
				local tab = entry:split('/')
				local priority, amount = tonumber(tab[1]), tonumber(tab[3])
				if priority and tab[2] and amount then
					table.insert(tab[4] and CustomPost or Custom, {Priority = priority, Name = tab[2]:lower(), Amount = amount})
				end
			end
			for _, tab in {Custom, CustomPost} do
				table.sort(tab, function(a, b)
					return a.Priority < b.Priority
				end)
			end
		end
	})
	Upgrades = AutoBuy:CreateMultiDropdown({
		Name = 'Team upgrades',
		List = table.clone(bedfight.TeamUpgradesData.UpgradesOrder),
		Default = {'Team Generator'},
		Tooltip = 'Team upgrades to buy'
	})
end)
