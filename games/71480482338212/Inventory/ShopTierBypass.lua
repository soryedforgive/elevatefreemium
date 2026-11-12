run(function()
	local ShopTierBypass
	local hooked = setmetatable({}, {__mode = 'k'})

	local function handler()
		local gui = lplr.PlayerGui:FindFirstChild('ItemShopGui')
		local module = gui and gui:FindFirstChild('ItemShopHandler')
		if not module then return nil end
		local ok, result = pcall(require, module)
		return ok and type(result) == 'table' and result or nil
	end

	local function hook(module)
		if hooked[module] or type(module.GetBuyResult) ~= 'function' then return end
		local original = module.GetBuyResult
		hooked[module] = original
		module.GetBuyResult = function(name, data, ...)
			local result = original(name, data, ...)
			if result ~= 'Locked' or not ShopTierBypass.Enabled or type(data) ~= 'table' or not (bedfight.SwordsData and bedfight.SwordsData[name]) then
				return result
			end
			local copy = table.clone(data)
			copy.RequiredItems, copy.ExcludedFromItems, copy.ExcludedFromClasses = nil, nil, nil
			return original(name, copy, ...)
		end
	end

	local function unhook()
		for module, original in hooked do
			if module.GetBuyResult ~= original then
				module.GetBuyResult = original
			end
		end
		table.clear(hooked)
	end

	ShopTierBypass = vape.Categories.Inventory:CreateModule({
		Name = 'ShopTierBypass',
		Function = function(callback)
			if not callback then
				unhook()
				return
			end
			repeat
				local module = handler()
				if module then
					hook(module)
				end
				task.wait(1)
			until not ShopTierBypass.Enabled
		end,
		Tooltip = 'Lets you buy any sword without the tier before it'
	})
end)
