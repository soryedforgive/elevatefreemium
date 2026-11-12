
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local collectionService = cloneref(game:GetService('CollectionService'))
local lplr = playersService.LocalPlayer

local helpers = {
	Range = {
		Shop = 20,
		Chest = 20,
	},
	PollInterval = 0.1,
	WoolFamily = 'wool',
}

local function game_state()
	local value = getgenv().store
	return type(value) == 'table' and value or nil
end

local function game_api()
	local value = getgenv().bedwars
	return type(value) == 'table' and value or nil
end

local function entities()
	local vape = shared.vape
	return vape and vape.Libraries and vape.Libraries.entity or nil
end
function helpers.Studs(val)
	return val <= 1 and 'stud' or 'studs'
end
function helpers.Seconds(val)
	return val <= 1 and 'sec' or 'secs'
end
function helpers.Minutes(val)
	return val <= 1 and 'min' or 'mins'
end

helpers.Percent = '%'

local Utils = {}
helpers.Utils = Utils

function Utils.Notify(label, text, duration, kind)
	local vape = shared.vape
	if vape and type(vape.CreateNotification) == 'function' then
		pcall(vape.CreateNotification, vape, label, text, duration, kind)
	end
end

function Utils.Alive()
	local entitylib = entities()
	return entitylib ~= nil and entitylib.isAlive == true
end

function Utils.Root()
	local entitylib = entities()
	local character = entitylib and entitylib.character
	return character and character.RootPart or nil
end

function Utils.Position()
	local root = Utils.Root()
	return root and root.Position or nil
end

function Utils.Distance(position)
	local origin = Utils.Position()
	if not origin or not position then return nil end
	return (position - origin).Magnitude
end

function Utils.InRange(position, range)
	local distance = Utils.Distance(position)
	return distance ~= nil and distance <= range
end
function Utils.Restart(module)
	if module and module.Enabled then
		module:Toggle()
		module:Toggle()
	end
end
function Utils.Combat()
	return shared.AetherCombat or getgenv().AetherCombat
end

function Utils.InCombat()
	local combat = Utils.Combat()
	return (combat and combat:IsInCombat()) == true
end

local Queue = {Test = 'bedwars_test'}
helpers.Queue = Queue

function Queue.Name()
	local store = game_state()
	return store and store.queueType or Queue.Test
end

function Queue.Ready()
	return Queue.Name() ~= Queue.Test
end
function Queue.Await(module)
	local shouldStop = module
	if type(module) == 'table' then
		shouldStop = function()
			return module.Enabled ~= true
		end
	end
	repeat
		task.wait()
	until Queue.Ready() or (shouldStop and shouldStop())
	return Queue.Ready()
end

local Inventory = {}
helpers.Inventory = Inventory

function Inventory.Container()
	local store = game_state()
	local inventory = store and store.inventory and store.inventory.inventory
	return type(inventory) == 'table' and inventory or nil
end

function Inventory.Items()
	local inventory = Inventory.Container()
	return (inventory and inventory.items) or {}
end
function Inventory.Item(name, find)
	for slot, item in Inventory.Items() do
		local itemType = item and item.itemType
		if itemType and ((find and itemType:find(name, 1, true)) or itemType == name) then
			return item, slot
		end
	end
	return nil
end

function Inventory.Amount(name, find)
	local item = Inventory.Item(name, find)
	return item and tonumber(item.amount) or 0
end
function Inventory.Total(predicate)
	local total = 0
	for _, item in Inventory.Items() do
		if item and item.itemType and (not predicate or predicate(item.itemType, item)) then
			total += tonumber(item.amount) or 1
		end
	end
	return total
end

function Inventory.Meta(itemType)
	local bedwars = game_api()
	local meta = bedwars and bedwars.ItemMeta and bedwars.ItemMeta[itemType]
	return type(meta) == 'table' and meta or nil
end
function Inventory.StackCap(itemType)
	local meta = Inventory.Meta(itemType)
	local capacity = meta and meta.maxStackSize
	if type(capacity) == 'table' then
		capacity = tonumber(capacity.amount)
	end
	return capacity and capacity > 0 and capacity or nil
end

local Families = {}
helpers.Families = Families

function Families.Name(entry)
	entry = tostring(entry or ''):lower():gsub('%s+', '')
	if entry == '' then return nil end
	if entry:find(helpers.WoolFamily, 1, true) then return helpers.WoolFamily end
	return entry
end

function Families.Matches(itemType, family)
	itemType = tostring(itemType or ''):lower()
	if family == helpers.WoolFamily then
		return itemType:find(helpers.WoolFamily, 1, true) ~= nil
	end
	return itemType == family
end

function Families.Label(family)
	return family:sub(1, 1):upper()..family:sub(2)
end
function Families.ShopType(family)
	return family == helpers.WoolFamily and 'wool_white' or family
end
local Shop
local Refill = {}
helpers.Refill = Refill

local RESERVATION_TIMEOUT = 3
local reserved = {}

function Refill.Count(family)
	return Inventory.Total(function(itemType)
		return Families.Matches(itemType, family)
	end)
end

function Refill.Reserve(family, units)
	local record = reserved[family]
	if record then
		record.Units += units
		return
	end
	reserved[family] = {Baseline = Refill.Count(family), Units = units, Clock = os.clock()}
end
function Refill.Held(family)
	local observed = Refill.Count(family)
	local record = reserved[family]
	if not record then return observed end

	if observed >= record.Baseline + record.Units or os.clock() - record.Clock > RESERVATION_TIMEOUT then
		reserved[family] = nil
		return observed
	end
	return math.max(observed, record.Baseline + record.Units)
end

function Refill.Clear()
	table.clear(reserved)
end

function Refill.TopUp(family, target, shopId, currencytable, label)
	local item = Shop.Item(Families.ShopType(family))
	if not item or not shopId then return false end

	local amount = math.max(tonumber(item.amount) or 1, 1)
	local price = math.max(tonumber(item.price) or 0, 0)
	local current = Refill.Held(family)
	local needed = math.max(tonumber(target) or 0, 0) - current
	if needed <= 0 then return false end

	local purchases = math.ceil(needed / amount)
	local capacity = Inventory.StackCap(Families.ShopType(family))
	if capacity then
		purchases = math.min(purchases, math.max(math.ceil((capacity - current) / amount), 0))
	end
	if price > 0 then
		local wallet = currencytable[item.currency]
		if not wallet then
			wallet = Inventory.Amount(item.currency)
			currencytable[item.currency] = wallet
		end
		purchases = math.min(purchases, math.floor(wallet / price))
	end
	if purchases <= 0 or not Shop.CanBuy(item, currencytable, purchases) then return false end

	for _ = 1, purchases do
		Shop.Purchase(item, shopId, currencytable, {Label = label})
	end
	Refill.Reserve(family, purchases * amount)
	return true
end

local CLAIM_WINDOW = 1.5

local function priorityFile()
	return 'ElevateV4/refill-priority.txt'
end

function Refill.Priority()
	if helpers.refillPriority then return helpers.refillPriority end
	local ok, contents = pcall(readfile, priorityFile())
	if ok and type(contents) == 'string' then
		local value = contents:gsub('%s+', '')
		if value == 'AutoBuy' or value == 'AutoRefill' then
			helpers.refillPriority = value
			return value
		end
	end
	return nil
end

function Refill.SetPriority(module)
	helpers.refillPriority = module
	pcall(writefile, priorityFile(), tostring(module or ''))
end

function Refill.Claim(module)
	helpers.refillClaim = {Module = module, Clock = os.clock()}
end
function Refill.BlockedBy(module)
	local claim = helpers.refillClaim
	if not claim or os.clock() - claim.Clock > CLAIM_WINDOW then return nil end
	if claim.Module == module then return nil end
	if Refill.Priority() ~= claim.Module then return nil end
	return claim.Module
end

local conflictShown = false

function Refill.ResolveConflict(trigger)
	local getter = getgenv and getgenv().getAetherModule
	if type(getter) ~= 'function' then return end
	local autoBuy = getter('AutoBuy')
	local autoRefill = getter('AutoRefill')
	if not (autoBuy and autoRefill and autoBuy.Enabled and autoRefill.Enabled) then
		conflictShown = false
		return
	end
	if conflictShown then return end
	conflictShown = true

	local current = Refill.Priority()
	if current then return end
	Utils.Notify(trigger or 'Aether', 'AutoBuy and AutoRefill are both on. Only the prioritised one buys; pick which in the window.', 10, 'warning')

	local vape = shared.vape
	if not (vape and type(vape.CreateChoice) == 'function') then return end
	pcall(vape.CreateChoice, vape, {
		Title = 'AutoBuy and AutoRefill',
		Message = 'Both AutoBuy and AutoRefill have been activated. Which module would you like to prioritise? The other will only act when the prioritised one has nothing to do.',
		Options = {
			{Label = 'AutoRefill', Primary = current ~= 'AutoBuy', Function = function() Refill.SetPriority('AutoRefill') end},
			{Label = 'AutoBuy', Primary = current == 'AutoBuy', Function = function() Refill.SetPriority('AutoBuy') end},
		}
	})
end

local Health = {}
helpers.Health = Health

local function characterOf(character)
	return character or lplr.Character
end
function Health.Current(character)
	character = characterOf(character)
	if not character then return nil end
	local health = character:GetAttribute('Health')
	local humanoid = character:FindFirstChildOfClass('Humanoid')
	if type(health) ~= 'number' then health = humanoid and humanoid.Health end
	return type(health) == 'number' and health or nil
end

function Health.Maximum(character)
	character = characterOf(character)
	if not character then return nil end
	local maximum = character:GetAttribute('MaxHealth')
	local humanoid = character:FindFirstChildOfClass('Humanoid')
	if type(maximum) ~= 'number' or maximum <= 0 then maximum = humanoid and humanoid.MaxHealth end
	return type(maximum) == 'number' and maximum > 0 and maximum or nil
end

function Health.Percent(character)
	local health, maximum = Health.Current(character), Health.Maximum(character)
	if not health or not maximum then return nil end
	return math.clamp((health / maximum) * 100, 0, 100)
end

Shop = {}
helpers.Shop = Shop

Shop.Range = helpers.Range.Shop
Shop.ItemApp = 'BedwarsItemShopApp'
Shop.UpgradeApp = 'TeamUpgradeApp'
Shop.ChestApp = 'ChestApp'

function Shop.Entries()
	local store = game_state()
	local entries = store and store.shop
	return type(entries) == 'table' and entries or {}
end

local function matchesKind(entry, kind)
	if kind == nil then return entry.Shop == true or entry.Upgrades == true end
	if kind == 'item' then return entry.Shop == true end
	if kind == 'upgrade' then return entry.Upgrades == true end
	return true
end
function Shop.Nearby(kind, range)
	local origin = Utils.Position()
	if not origin then return nil end
	range = range or Shop.Range
	local closest, closestDistance
	for _, entry in Shop.Entries() do
		local part = entry.RootPart
		if part and part.Parent and matchesKind(entry, kind) then
			local distance = (part.Position - origin).Magnitude
			if distance <= range and (not closestDistance or distance < closestDistance) then
				closest, closestDistance = entry, distance
			end
		end
	end
	return closest
end
function Shop.Id(kind, range)
	local entry = Shop.Nearby(kind, range)
	return entry and entry.Id or nil
end

function Shop.ScreenOpen(appId)
	local bedwars = game_api()
	local app = bedwars and bedwars.AppController
	if not app or type(app.isAppOpen) ~= 'function' then return false end
	local ok, opened = pcall(app.isAppOpen, app, appId)
	return ok and opened == true
end

function Shop.ItemScreenOpen()
	return Shop.ScreenOpen(Shop.ItemApp)
end

function Shop.UpgradeScreenOpen()
	return Shop.ScreenOpen(Shop.UpgradeApp)
end
function Shop.BuyScreenOpen()
	return Shop.ItemScreenOpen() or Shop.UpgradeScreenOpen()
end

function Shop.ChestScreenOpen()
	return Shop.ScreenOpen(Shop.ChestApp)
end
local itemCache, itemCacheInventory, itemCacheAt = {}, nil, 0
local function itemCacheValid()
	local store = game_state()
	local inventory = store and store.inventory
	local now = os.clock()
	if inventory ~= itemCacheInventory or now - itemCacheAt > 2 then
		table.clear(itemCache)
		itemCacheInventory, itemCacheAt = inventory, now
	end
end

function Shop.ClearCache()
	table.clear(itemCache)
end

local fetchItem
function Shop.Item(itemType, shopId)
	itemCacheValid()
	local key = shopId and itemType..'|'..tostring(shopId) or itemType
	local cached = itemCache[key]
	if cached ~= nil then
		return cached or nil
	end
	local item = fetchItem(itemType, shopId)
	itemCache[key] = item or false
	return item
end

fetchItem = function(itemType, shopId)
	local runtime = shared.AetherBedWarsRuntime
	local capability = runtime and runtime.BedWarsAPI and runtime.BedWarsAPI.Shop
	if capability and type(capability.GetItem) == 'function' then
		local item = capability:GetItem(itemType, shopId)
		if item then return item end
	end
	local bedwars = game_api()
	if bedwars and bedwars.Shop and type(bedwars.Shop.getShopItem) == 'function' then
		local ok, item = pcall(bedwars.Shop.getShopItem, itemType, lplr, shopId and {shopId = shopId} or nil)
		if ok then return item end
	end
	return nil
end

function Shop.Owned(itemType)
	local bedwars = game_api()
	local shopController = bedwars and bedwars.BedwarsShopController
	local purchased = shopController and shopController.alreadyPurchasedMap
	return purchased ~= nil and purchased[itemType] ~= nil
end
function Shop.TeamUpgrades()
	local bedwars = game_api()
	local ok, state = pcall(function()
		return bedwars.Store:getState()
	end)
	local bedwarsState = ok and type(state) == 'table' and state.Bedwars or nil
	local upgrades = type(bedwarsState) == 'table' and bedwarsState.teamUpgrades or nil
	if type(upgrades) ~= 'table' then return {} end
	local team = upgrades[lplr:GetAttribute('Team')]
	return type(team) == 'table' and team or upgrades
end
function Shop.CanBuy(item, currencytable, amount)
	amount = amount or 1
	currencytable = currencytable or {}
	if not currencytable[item.currency] then
		currencytable[item.currency] = Inventory.Amount(item.currency)
	end
	local store = game_state()
	if item.ignoredByKit and table.find(item.ignoredByKit, store and store.equippedKit or '') then return false end
	if item.lockedByForge or item.disabled then return false end
	if item.disabledInQueue and store and table.find(item.disabledInQueue, store.queueType or '') then return false end
	if item.require and item.require.teamUpgrade then
		local required = item.require.teamUpgrade
		if (Shop.TeamUpgrades()[required.upgradeId] or -1) < required.lowestTierIndex then return false end
	end
	return currencytable[item.currency] >= (item.price * amount)
end
local pendingPurchases = {}
local boughtNotices = {}
local function reportPurchase(label, name)
	local key = label..'/'..name
	local notice = boughtNotices[key]
	if notice then
		notice.Count += 1
		return
	end
	notice = {Count = 1}
	boughtNotices[key] = notice
	task.delay(0.25, function()
		boughtNotices[key] = nil
		Utils.Notify(label, 'Bought '..name..(notice.Count > 1 and ' x'..notice.Count or ''), 3)
	end)
end
function Shop.Pending(itemType)
	local clock = pendingPurchases[itemType]
	return clock ~= nil and os.clock() < clock
end

function Shop.Purchase(item, shopId, currencytable, options)
	options = options or {}
	local bedwars = game_api()
	if not bedwars then return false end
	local meta = bedwars.ItemMeta and bedwars.ItemMeta[item.itemType]
	local name = meta and meta.displayName or item.itemType
	pendingPurchases[item.itemType] = os.clock() + 2
	table.clear(itemCache)

	local fired = pcall(function()
		bedwars.Handler:Get('BedwarsPurchaseItem'):Fire('CallServerAsync', {
			shopItem = item,
			shopId = shopId
		}):andThen(function(suc)
			pendingPurchases[item.itemType] = os.clock() + (suc and 0.5 or 1)
			if not suc then return end
			if options.Label then
				reportPurchase(options.Label, name)
			end
			bedwars.SoundManager:playSound(bedwars.SoundList.BEDWARS_PURCHASE_ITEM)
			bedwars.Store:dispatch({
				type = 'BedwarsAddItemPurchased',
				itemType = item.itemType
			})
			if not options.TieredOnly or item.tiered then
				bedwars.BedwarsShopController.alreadyPurchasedMap[item.itemType] = true
			end
		end)
	end)
	if not fired then
		pendingPurchases[item.itemType] = nil
		return false
	end

	if currencytable then
		currencytable[item.currency] = (currencytable[item.currency] or 0) - item.price
	end
	return true
end
function helpers.KitName()
	local store = game_state()
	local equipped = store and store.equippedKit
	if type(equipped) == 'string' and equipped ~= '' then return equipped end
	for _, attribute in {'PlayingAsKit', 'PlayingAsKits', 'SelectedKit', 'Kit'} do
		local value = lplr:GetAttribute(attribute)
		if value ~= nil then
			local text = tostring(value)
			if text ~= '' and text:lower() ~= 'none' then return text end
		end
	end
	return nil
end

function helpers.IsKit(...)
	local current = helpers.KitName()
	if not current then return false end
	current = current:lower()
	for index = 1, select('#', ...) do
		local wanted = select(index, ...)
		if wanted ~= nil and current == tostring(wanted):lower() then return true end
	end
	return false
end

local Ability = {}
helpers.Ability = Ability

function Ability.Controller()
	local bedwars = game_api()
	return bedwars and bedwars.AbilityController or nil
end
function Ability.Ready(id)
	local controller = Ability.Controller()
	if not controller or type(controller.canUseAbility) ~= 'function' then return false end
	local ok, ready = pcall(controller.canUseAbility, controller, id, {disableBlockedAbilityAlert = true})
	return ok and ready == true
end

function Ability.Use(id, ...)
	local controller = Ability.Controller()
	if not controller or type(controller.useAbility) ~= 'function' then return false end
	local ok, result = pcall(controller.useAbility, controller, id, ...)
	return ok and result ~= false
end

local Hook = {}
helpers.Hook = Hook
function Hook.Controller(module, controllerName, methodName, wrapper)
	local state = {controller = nil, original = nil, hooked = nil}

	local function uninstall()
		local controller = state.controller
		if controller and state.hooked and controller[methodName] == state.hooked then
			controller[methodName] = state.original
		end
		state.controller, state.original, state.hooked = nil, nil, nil
	end

	local function install()
		if state.hooked then
			if state.controller and state.controller[methodName] == state.hooked then return end
			uninstall()
		end
		local bedwars = game_api()
		local controller = bedwars and bedwars[controllerName]
		if type(controller) ~= 'table' or type(controller[methodName]) ~= 'function' then return end
		local original = controller[methodName]
		state.controller, state.original = controller, original
		state.hooked = function(...)
			return wrapper(original, ...)
		end
		controller[methodName] = state.hooked
	end

	install()
	local thread = task.spawn(function()
		while module.Enabled do
			install()
			task.wait(1)
		end
	end)
	module:Clean(function()
		pcall(task.cancel, thread)
		uninstall()
	end)
	return state
end
function helpers.FindVector(...)
	for index = 1, select('#', ...) do
		local value = select(index, ...)
		if typeof(value) == 'Vector3' then return value end
	end
	return nil
end

local Chest = {}
helpers.Chest = Chest

Chest.Tag = 'personal-chest'
Chest.Range = helpers.Range.Chest

function Chest.Remotes()
	local bedwars = game_api()
	local client = bedwars and bedwars.Client
	if not client or type(client.GetNamespace) ~= 'function' then return nil end
	local ok, remotes = pcall(function()
		return client:GetNamespace('Inventory')
	end)
	return ok and remotes or nil
end

function Chest.OwnFolder(plr)
	plr = plr or lplr
	local inventories = replicatedStorage:FindFirstChild('Inventories')
	return inventories and inventories:FindFirstChild(plr.Name..'_personal') or nil
end
function Chest.FolderOf(chest)
	if not chest then return nil end
	local value = chest:FindFirstChild('ChestFolderValue')
	return value and value.Value or nil
end

function Chest.Part(object)
	if not object then return nil end
	if object:IsA('Model') then return object.PrimaryPart end
	return object:IsA('BasePart') and object or nil
end

function Chest.Tagged()
	return collectionService:GetTagged(Chest.Tag)
end

function Chest.IsPersonal(chest)
	if not chest then return false end
	if collectionService:HasTag(chest, Chest.Tag) then return true end
	if tostring(chest.Name):lower():find('personal', 1, true) then return true end
	if chest:GetAttribute('PersonalChest') or chest:GetAttribute('IsPersonalChest') then return true end
	local folder = Chest.FolderOf(chest)
	if not folder then return false end
	local name = tostring(folder.Name):lower()
	return name:sub(-#'_personal') == '_personal' or name == 'personal'
end
function Chest.InRange(range, origin)
	origin = origin or Utils.Position()
	if not origin then return false end
	for _, chest in Chest.Tagged() do
		local part = Chest.Part(chest)
		if part and part.Parent and (part.Position - origin).Magnitude <= (range or Chest.Range) then
			return true
		end
	end
	return false
end
function Chest.Entries(folder)
	local entries = {}
	if not folder then return entries end
	for _, child in folder:GetChildren() do
		if child:IsA('Accessory') then
			table.insert(entries, child)
		end
	end
	return entries
end
function Chest.Totals(folder)
	local totals = {}
	for _, entry in Chest.Entries(folder) do
		totals[entry.Name] = (totals[entry.Name] or 0) + (entry:GetAttribute('Amount') or 1)
	end
	return totals
end
function Chest.Observe(folder, body)
	local remotes = Chest.Remotes()
	if not remotes then return false end
	pcall(function()
		remotes:Get('SetObservedChest'):SendToServer(folder)
	end)
	local results = table.pack(pcall(body, remotes))
	pcall(function()
		remotes:Get('SetObservedChest'):SendToServer(nil)
	end)
	return table.unpack(results, 1, results.n)
end
function Chest.Give(folder, tool)
	local remotes = Chest.Remotes()
	if not remotes or not tool then return false end
	local ok, given = pcall(function()
		return remotes:Get('ChestGiveItem'):CallServer(folder, tool)
	end)
	return ok and given == true
end

function Chest.Take(folder, entry)
	local remotes = Chest.Remotes()
	if not remotes or not entry then return false end
	local ok, taken = pcall(function()
		return remotes:Get('ChestGetItem'):CallServer(folder, entry)
	end)
	return ok and taken == true
end

return helpers
