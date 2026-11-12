local run = function(func)
	local success, result = xpcall(func, debug and debug.traceback or tostring)
	if not success then
		warn('[ElevateV4] Skipped a module during startup: '..tostring(result))
	end
	return success
end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local runService = cloneref(game:GetService('RunService')) 
local httpService = cloneref(game:GetService('HttpService'))

local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local sessioninfo = vape.Libraries.sessioninfo
local bedwars = {}

local function notif(...)
	return vape:CreateNotification(...)
end

run(function()
	local function dumpRemote(tab)
		local ind = table.find(tab, 'Client')
		return ind and tab[ind + 1] or ''
	end
	local KnitInit, Knit
	local knitDeadline = tick() + 45
	repeat
		KnitInit, Knit = pcall(function()
			return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9)
		end)
		if KnitInit and Knit then break end
		task.wait(0.1)
	until tick() > knitDeadline
	if not (KnitInit and Knit) then
		error('Knit never became available - the game has not finished loading')
	end

	if not debug.getupvalue(Knit.Start, 1) then
		local upvalueDeadline = tick() + 15
		repeat task.wait(0.1) until debug.getupvalue(Knit.Start, 1) or tick() > upvalueDeadline
		if not debug.getupvalue(Knit.Start, 1) then
			error('debug.getupvalue is unavailable on this executor')
		end
	end

	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local igniteDeadline = tick() + 45
	repeat
		local ok, ignited = pcall(debug.getupvalue, Flamework.ignite, 1)
		if not ok or type(ignited) ~= 'boolean' or ignited then break end
		task.wait(0.1)
	until tick() > igniteDeadline
	local controllers = {Built = {}, Ids = {
		'@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController',
		'@easy-games/game-core:client/controllers/notification-controller@NotificationController',
		'@easy-games/lobby:client/controllers/party-controller@PartyController'
	}}
	local function findController(id, again)
		if again or not controllers.Scanned then
			controllers.Scanned = true
			local delta = false
			if identifyexecutor then
				local named, executor = pcall(identifyexecutor)
				delta = named and tostring(executor):lower():find('delta', 1, true) ~= nil
			end
			local ok, core = pcall(function()
				return require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out)
			end)
			local known = ok and type(core) == 'table' and type(core.Reflect) == 'table' and core.Reflect.idToObj or nil
			local singletons
			if delta and ok and type(core) == 'table' and type(core.Modding) == 'table' and type(core.Modding.getSingletons) == 'function' then
				local got, map = pcall(core.Modding.getSingletons)
				singletons = got and type(map) == 'table' and map or nil
			end
			local classes, left = {}, 0
			if type(known) == 'table' and (delta or getgc) then
				for _, wanted in again or controllers.Ids do
					local class = known[wanted]
					if type(class) == 'table' and not classes[class] then
						local built = singletons and rawget(singletons, class)
						if type(built) == 'table' and getmetatable(built) == class then
							controllers.Built[wanted] = built
						else
							classes[class] = wanted
							left += 1
						end
					end
				end
			end
			if left > 0 and not delta and getgc then
				for _, v in getgc(true) do
					if type(v) == 'table' then
						local meta = getmetatable(v)
						local wanted = meta ~= nil and classes[meta]
						if wanted then
							controllers.Built[wanted] = v
							classes[meta] = nil
							left -= 1
							if left == 0 then break end
						end
					end
				end
			end
		end
		return id and controllers.Built[id] or nil
	end
	local missingControllers = {}
	local function resolveController(id)
		local found = findController(id)
		if found then return found end
		local ok, result = pcall(Flamework.resolveDependency, id)
		if ok and result ~= nil then return result end
		local name = id:match('@(%w+)$') or id
		warn('[ElevateV4] '..name..' is not available in this place: '..tostring(result))
		local stub = setmetatable({}, {
			__index = function()
				return function() end
			end
		})
		missingControllers[name] = {Id = id, Stub = stub, Tries = 0}
		return stub
	end
	local InventoryUtil = require(replicatedStorage.TS.inventory['inventory-util']).InventoryUtil
	local Client = require(replicatedStorage.TS.remotes).default.Client
	local OldGet, OldBreak = Client.Get
	local function safeGetProto(func, index)
		if not func or not debug or type(debug.getproto) ~= 'function' then return nil end
		local success, proto = pcall(debug.getproto, func, index)
		if success then
			return proto
		else
			warn("function:", func, "index:", index) 
			return nil
		end
	end

	bedwars = setmetatable({
	 	MatchHistroyApp = require(lplr.PlayerScripts.TS.controllers.global["match-history"].ui["match-history-moderation-app"]).MatchHistoryModerationApp,
	 	MatchHistroyController = Knit.Controllers.MatchHistoryController,
		AbilityController = resolveController('@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController'),
		AnimationType = require(replicatedStorage.TS.animation['animation-type']).AnimationType,
		AnimationUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out['shared'].util['animation-util']).AnimationUtil,
		AppController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.controllers['app-controller']).AppController,
		BedBreakEffectMeta = require(replicatedStorage.TS.locker['bed-break-effect']['bed-break-effect-meta']).BedBreakEffectMeta,
		BedwarsKitMeta = require(replicatedStorage.TS.games.bedwars.kit['bedwars-kit-meta']).BedwarsKitMeta,
		ClickHold = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.ui.lib.util['click-hold']).ClickHold,
		Client = Client,
		ClientConstructor = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts'].net.out.client),
		MatchHistoryController = require(lplr.PlayerScripts.TS.controllers.global['match-history']['match-history-controller']),
		PlayerProfileUIController = require(lplr.PlayerScripts.TS.controllers.global['player-profile']['player-profile-ui-controller']),
		TitleTypes = require(game.ReplicatedStorage.TS.locker.title['title-type']).TitleType,
		TitleTypesMeta =  require(game.ReplicatedStorage.TS.locker.title['title-meta']).TitleMeta,
		EmoteType = require(replicatedStorage.TS.locker.emote['emote-type']).EmoteType,
		GameAnimationUtil = require(replicatedStorage.TS.animation['animation-util']).GameAnimationUtil,
		NotificationController = resolveController('@easy-games/game-core:client/controllers/notification-controller@NotificationController'),
		getIcon = function(item, showinv)
			local itemmeta = bedwars.ItemMeta[item.itemType]
			return itemmeta and showinv and itemmeta.image or ''
		end,
		getInventory = function(plr)
			local suc, res = pcall(function()
				return InventoryUtil.getInventory(plr)
			end)
			return suc and res or {
				items = {},
				armor = {}
			}
		end,
		HudAliveCount = require(lplr.PlayerScripts.TS.controllers.global['top-bar'].ui.game['hud-alive-player-counts']).HudAlivePlayerCounts,
		ItemMeta = debug.getupvalue(require(replicatedStorage.TS.item['item-meta']).getItemMeta, 1),
		Knit = Knit,
		KnockbackUtil = require(replicatedStorage.TS.damage['knockback-util']).KnockbackUtil,
		MageKitUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.mage['mage-kit-util']).MageKitUtil,
		MilestoneRewards = require(replicatedStorage.TS.milestones.milestones).MilestoneRewards,
		NametagController = Knit.Controllers.NametagController,
		PartyController = resolveController('@easy-games/lobby:client/controllers/party-controller@PartyController'),
		ProjectileMeta = require(replicatedStorage.TS.projectile['projectile-meta']).ProjectileMeta,
		QueryUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).GameQueryUtil,
		QueueCard = require(lplr.PlayerScripts.TS.controllers.global.queue.ui['queue-card']).QueueCard,
		QueueMeta = require(replicatedStorage.TS.game['queue-meta']).QueueMeta,
		Roact = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts']['roact'].src),
		RuntimeLib = require(replicatedStorage['rbxts_include'].RuntimeLib),
		SoundList = require(replicatedStorage.TS.sound['game-sound']).GameSound,
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore,
		TeamUpgradeMeta = debug.getupvalue(require(replicatedStorage.TS.games.bedwars['team-upgrade']['team-upgrade-meta']).getTeamUpgradeMetaForQueue, 6),
		UILayers = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).UILayers,
		VisualizerUtils = require(lplr.PlayerScripts.TS.lib.visualizer['visualizer-utils']).VisualizerUtils,
		WeldTable = require(replicatedStorage.TS.util['weld-util']).WeldUtil,
		WinEffectMeta = require(replicatedStorage.TS.locker['win-effect']['win-effect-meta']).WinEffectMeta,
		ZapNetworking = require(lplr.PlayerScripts.TS.lib.network),
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})
	for name, get in {
		GamePlayerUtil = function() return require(replicatedStorage.TS.player['player-util']).GamePlayerUtil end,
		EmoteDisplayMeta = function() return require(replicatedStorage.TS.locker.emote['emote-display-meta']).EmoteDisplayMeta end,
		EmoteMeta = function() return require(replicatedStorage.TS.locker.emote['emote-meta']).EmoteMeta end
	} do
		if rawget(bedwars, name) == nil then
			local ok, value = pcall(get)
			if ok then rawset(bedwars, name, value) end
		end
	end

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	vape:Clean(function()
		table.clear(bedwars)
	end)
end)

local function activeLobbyKit()
	local values = {
		lplr:GetAttribute('PlayingAsKit'),
		lplr:GetAttribute('PlayingAsKits'),
		lplr:GetAttribute('SelectedKit'),
		lplr:GetAttribute('Kit'),
		lplr:GetAttribute('kit')
	}
	local ready = bedwars.Store ~= nil
	if bedwars.Store then
		local ok, state = pcall(bedwars.Store.getState, bedwars.Store)
		ready = ok and type(state) == 'table'
		if ready then
			local kit = state.Kit or state.kit or {}
			local locker = state.Locker or state.locker or {}
			local bedwarsState = state.Bedwars or state.BedWars or {}
			table.insert(values, 1, kit.kit or kit.equippedKit or kit.selectedKit
				or locker.equippedKit or locker.selectedKit
				or bedwarsState.kit or bedwarsState.equippedKit)
		end
	end
	for _, value in values do
		if value ~= nil and value ~= '' and value ~= 'none' then return tostring(value), true end
	end
	return nil, ready
end

if type(vape.SetGameInfo) == 'function' then
	vape:SetGameInfo({Name = 'BedWars', GetKit = activeLobbyKit})
end


getgenv()._aeroTierReady = true
local function getAccountTier(player)
    return 0
end

getgenv().getAeroTier = function(player)
    return getAccountTier(player)
end  
do
	local remove = {}
	for i, v in vape.Modules do
		if v.Category == 'Combat' or v.Category == 'Render' then
			table.insert(remove, i)
		end
	end
	for _, i in remove do
		vape:Remove(i)
	end
	vape:Remove('AutoObby')
end
