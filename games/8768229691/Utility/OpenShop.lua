run(function()
	local OpenShop
	local Shop
	local SCREENS = {
		Blacksmith = {'blacksmith-shop', 'blacksmith-shop-screen', 'BlacksmithShopScreen'},
		Wizard = {'wizard-shop', 'wizard-shop-screen', 'WizardShopScreen'}
	}

	local function getScreen(name)
		local path = SCREENS[name]
		local ok, screen = pcall(function()
			local module = lplr.PlayerScripts.TS.ui[path[1]][path[2]]
			if getloadedmodules and not table.find(getloadedmodules(), module) then return nil end
			return require(module)[path[3]]
		end)
		return ok and screen or nil
	end

	OpenShop = vape.Categories.Utility:CreateModule({
		Name = 'OpenShop',
		Function = function(callback)
			if callback then
				local controller = skywars.ScreenController
				local screen = getScreen(Shop.Value)
				if controller and screen then
					local ok, err = pcall(controller.open, controller, screen, {})
					if not ok then
						notif('OpenShop', 'The shop could not be opened: '..tostring(err), 6, 'warning')
					end
				else
					notif('OpenShop', 'The shop is only available during a match.', 5, 'warning')
				end
				task.defer(function()
					if OpenShop.Enabled then
						OpenShop:Toggle()
					end
				end)
			end
		end,
		Tooltip = 'Opens a shop from anywhere on the map'
	})
	Shop = OpenShop:CreateDropdown({
		Name = 'Shop',
		List = {'Blacksmith', 'Wizard'},
		Tooltip = 'Blacksmith - Blocks, gear and upgrades\nWizard - Team upgrades'
	})
end)
