local license = ... or {}
local accent = {Hue = 0.7559524, Sat = 0.5490196, Value = 1, Notch = 6}
local function installedVersionLabel()
	local ok, body = pcall(readfile, 'ElevateV4/profiles/version.txt')
	if ok and type(body) == 'string' then
		local value = body:match('version%s*=%s*([^\r\n]+)')
		if value and value ~= '' then return (value:gsub('%s+$', '')) end
	end
	return '3.2'
end

local mainapi = {
	Categories = {},
	GUIColor = {
		Hue = accent.Hue,
		Sat = accent.Sat,
		Value = accent.Value
	},
	GameInfo = {},
	GameInfoChanged = Instance.new('BindableEvent'),
	HeldKeybinds = {},
	Keybind = {'RightShift'},
	Loaded = false,
	Libraries = {},
	Modules = {},
	Place = game.PlaceId,
	Profile = 'default',
	Profiles = {},
	RainbowSpeed = {Value = 1},
	RainbowUpdateSpeed = {Value = 60},
	RainbowTable = {},
	Scale = {Value = 1},
	ThreadFix = setthreadidentity and true or false,
	ToggleNotifications = {},
	Version = installedVersionLabel(),
	ToggleMode = {Value = 'Toggle'},
	Windows = {}
}

local cloneref = cloneref or function(obj)
	return obj
end
local tweenService = cloneref(game:GetService('TweenService'))
local inputService = cloneref(game:GetService('UserInputService'))
local textService = cloneref(game:GetService('TextService'))
local guiService = cloneref(game:GetService('GuiService'))
local runService = shared.AetherProfiler and shared.AetherProfiler.RunService or cloneref(game:GetService('RunService'))
local lighting = cloneref(game:GetService('Lighting'))
local httpService = cloneref(game:GetService('HttpService'))

local fontsize = Instance.new('GetTextBoundsParams')
fontsize.Width = math.huge
local notifications
local assetfunctions = {}
local function addAssetFunction(candidate)
	if type(candidate) == 'function' and not table.find(assetfunctions, candidate) then
		table.insert(assetfunctions, candidate)
	end
end
addAssetFunction(getcustomasset)
addAssetFunction(getsynasset)
local executorEnvironment = getgenv and getgenv() or nil
if type(executorEnvironment) == 'table' then
	addAssetFunction(executorEnvironment.getcustomasset)
	addAssetFunction(executorEnvironment.getsynasset)
end
if type(syn) == 'table' then
	addAssetFunction(syn.getcustomasset)
	addAssetFunction(syn.getsynasset)
end
local assetfunction = assetfunctions[1]
local getcustomasset
local clickgui
local scaledgui
local toolblur
local tooltip
local scale
local gui
local mobileBlur

local color = {}
local tween = {
	tweens = {},
	tweenstwo = {}
}
local uipallet = {
	Main = Color3.fromRGB(0, 0, 0),
	Text = Color3.fromRGB(200, 200, 200),
	Font = Font.fromEnum(Enum.Font.Arial),
	FontSemiBold = Font.fromEnum(Enum.Font.Arial, Enum.FontWeight.SemiBold),
	Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
}
local unwindInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
function mainapi:SetGameInfo(info)
	if type(info) ~= 'table' then return end
	local merged = table.clone(self.GameInfo or {})
	for key, value in info do merged[key] = value end
	self.GameInfo = merged
	if self.GameInfoChanged then self.GameInfoChanged:Fire(merged) end
end

function mainapi:RefreshGameInfo()
	if self.GameInfoChanged then self.GameInfoChanged:Fire(self.GameInfo) end
end
local vapecolors = {
	Icon = Color3.fromRGB(122, 122, 122),
	IconHover = Color3.fromRGB(209, 209, 209)
}

local getcustomassets = {
	['ElevateV4/assets/new/aim.png'] = 'rbxassetid://122207028123421',
	['ElevateV4/assets/new/allowediconmini.png'] = 'rbxassetid://90142384730147',
	['ElevateV4/assets/new/backmini.png'] = 'rbxassetid://85859225495272',
	['ElevateV4/assets/new/blatant.png'] = 'rbxassetid://126929923309265',
	['ElevateV4/assets/new/blurnoti.png'] = 'rbxassetid://124705876663719',
	['ElevateV4/assets/new/cheat_switch.png'] = 'rbxassetid://99437817306124',
	['ElevateV4/assets/new/closetiny.png'] = 'rbxassetid://71393233149714',
	['ElevateV4/assets/new/combat.png'] = 'rbxassetid://94762732349053',
	['ElevateV4/assets/new/combo_display.png'] = 'rbxassetid://97746985576116',
	['ElevateV4/assets/new/compassarrow.png'] = 'rbxassetid://100463923923900',
	['ElevateV4/assets/new/customtheme.png'] = 'rbxassetid://91756736022800',
	['ElevateV4/assets/new/dislike.png'] = 'rbxassetid://135092704977606',
	['ElevateV4/assets/new/downexpand.png'] = 'rbxassetid://94197751291504',
	['ElevateV4/assets/new/downexpandslider.png'] = 'rbxassetid://90289944682645',
	['ElevateV4/assets/new/editlarge.png'] = 'rbxassetid://119233876755282',
	['ElevateV4/assets/new/empty.png'] = 'rbxassetid://89525157373515',
	['ElevateV4/assets/new/expandarrow.png'] = 'rbxassetid://86360332526471',
	['ElevateV4/assets/new/favoritesicon.png'] = 'rbxassetid://133471112203189',
	['ElevateV4/assets/new/friends.png'] = 'rbxassetid://92957214042038',
	['ElevateV4/assets/new/hide.png'] = 'rbxassetid://129675456133478',
	['ElevateV4/assets/new/inventory.png'] = 'rbxassetid://93264756888499',
	['ElevateV4/assets/new/legit_mode_icon.png'] = 'rbxassetid://102858626075156',
	['ElevateV4/assets/new/legit_switch.png'] = 'rbxassetid://127508881124779',
	['ElevateV4/assets/new/like.png'] = 'rbxassetid://80039972048538',
	['ElevateV4/assets/new/min.png'] = 'rbxassetid://82175054487146',
	['ElevateV4/assets/new/newhide.png'] = 'rbxassetid://74295679301920',
	['ElevateV4/assets/new/noti_alert.png'] = 'rbxassetid://82356478726846',
	['ElevateV4/assets/new/noti_info.png'] = 'rbxassetid://102614825645099',
	['ElevateV4/assets/new/noti_warning.png'] = 'rbxassetid://119631730212167',
	['ElevateV4/assets/new/npcs.png'] = 'rbxassetid://104434365485227',
	['ElevateV4/assets/new/overlaydots.png'] = 'rbxassetid://78012624671930',
	['ElevateV4/assets/new/overlays.png'] = 'rbxassetid://136535637407545',
	['ElevateV4/assets/new/overlayslarge.png'] = 'rbxassetid://127574141208160',
	['ElevateV4/assets/new/players.png'] = 'rbxassetid://105137446428129',
	['ElevateV4/assets/new/profiles.png'] = 'rbxassetid://126051451865127',
	['ElevateV4/assets/new/profileworld.png'] = 'rbxassetid://122650686344133',
	['ElevateV4/assets/new/radar.png'] = 'rbxassetid://97983828696086',
	['ElevateV4/assets/new/rangeindicator.png'] = 'rbxassetid://107038094175283',
	['ElevateV4/assets/new/render.png'] = 'rbxassetid://125472576898654',
	['ElevateV4/assets/new/settingdots.png'] = 'rbxassetid://130896840048276',
	['ElevateV4/assets/new/settings.png'] = 'rbxassetid://73820177347303',
	['ElevateV4/assets/new/settingsmini.png'] = 'rbxassetid://115732118290997',
	['ElevateV4/assets/new/show.png'] = 'rbxassetid://85547987939285',
	['ElevateV4/assets/new/star.png'] = 'rbxassetid://96102671351955',
	['ElevateV4/assets/new/sword_header.png'] = 'rbxassetid://121706791793204',
	['ElevateV4/assets/new/targetinfo.png'] = 'rbxassetid://121604266095276',
	['ElevateV4/assets/new/textgui.png'] = 'rbxassetid://99438663817412',
	['ElevateV4/assets/new/theme.png'] = 'rbxassetid://111525258317113',
	['ElevateV4/assets/new/triangle.png'] = 'rbxassetid://75441874213844',
	['ElevateV4/assets/new/utility.png'] = 'rbxassetid://108303206513893',
	['ElevateV4/assets/new/v4.png'] = 'rbxassetid://102549752760489',
	['ElevateV4/assets/new/v4mini.png'] = 'rbxassetid://115213099001611',
	['ElevateV4/assets/new/vapelogo.png'] = 'rbxassetid://126205920310261',
	['ElevateV4/assets/new/vapelogomini.png'] = 'rbxassetid://109041903452149',
	['ElevateV4/assets/new/world.png'] = 'rbxassetid://118917453153459',
	['ElevateV4/assets/new/add.png'] = 'rbxassetid://14368300605',
	['ElevateV4/assets/new/alert.png'] = 'rbxassetid://14368301329',
	['ElevateV4/assets/new/allowedicon.png'] = 'rbxassetid://14368302000',
	['ElevateV4/assets/new/allowedtab.png'] = 'rbxassetid://14368302875',
	['ElevateV4/assets/new/arrowmodule.png'] = 'rbxassetid://14473354880',
	['ElevateV4/assets/new/back.png'] = 'rbxassetid://14368303894',
	['ElevateV4/assets/new/bind.png'] = 'rbxassetid://14368304734',
	['ElevateV4/assets/new/bindbkg.png'] = 'rbxassetid://14368305655',
	['ElevateV4/assets/new/blatanticon.png'] = 'rbxassetid://14368306745',
	['ElevateV4/assets/new/blockedicon.png'] = 'rbxassetid://14385669108',
	['ElevateV4/assets/new/blockedtab.png'] = 'rbxassetid://14385672881',
	['ElevateV4/assets/new/blur.png'] = 'rbxassetid://14898786664',
	['ElevateV4/assets/new/blurnotif.png'] = 'rbxassetid://16738720137',
	['ElevateV4/assets/new/close.png'] = 'rbxassetid://14368309446',
	['ElevateV4/assets/new/closemini.png'] = 'rbxassetid://14368310467',
	['ElevateV4/assets/new/colorpreview.png'] = 'rbxassetid://14368311578',
	['ElevateV4/assets/new/combaticon.png'] = 'rbxassetid://14368312652',
	['ElevateV4/assets/new/customsettings.png'] = 'rbxassetid://14403726449',
	['ElevateV4/assets/new/discord.png'] = '',
	['ElevateV4/assets/new/dots.png'] = 'rbxassetid://14368314459',
	['ElevateV4/assets/new/edit.png'] = 'rbxassetid://14368315443',
	['ElevateV4/assets/new/expandicon.png'] = 'rbxassetid://14368353032',
	['ElevateV4/assets/new/expandright.png'] = 'rbxassetid://14368316544',
	['ElevateV4/assets/new/expandup.png'] = 'rbxassetid://14368317595',
	['ElevateV4/assets/new/friendstab.png'] = 'rbxassetid://14397462778',
	['ElevateV4/assets/new/guisettings.png'] = 'rbxassetid://14368318994',
	['ElevateV4/assets/new/guislider.png'] = 'rbxassetid://14368320020',
	['ElevateV4/assets/new/guisliderrain.png'] = 'rbxassetid://14368321228',
	['ElevateV4/assets/new/guiv4.png'] = 'rbxassetid://14368322199',
	['ElevateV4/assets/new/guivape.png'] = 'rbxassetid://14657521312',
	['ElevateV4/assets/new/info.png'] = 'rbxassetid://14368324807',
	['ElevateV4/assets/new/inventoryicon.png'] = 'rbxassetid://14928011633',
	['ElevateV4/assets/new/legit.png'] = 'rbxassetid://14425650534',
	['ElevateV4/assets/new/legittab.png'] = 'rbxassetid://14426740825',
	['ElevateV4/assets/new/loading.png'] = '',
	['ElevateV4/assets/new/miniicon.png'] = 'rbxassetid://14368326029',
	['ElevateV4/assets/new/notification.png'] = 'rbxassetid://16738721069',
	['ElevateV4/assets/new/overlaysicon.png'] = 'rbxassetid://14368339581',
	['ElevateV4/assets/new/overlaystab.png'] = 'rbxassetid://14397380433',
	['ElevateV4/assets/new/pin.png'] = 'rbxassetid://14368342301',
	['ElevateV4/assets/new/profilesicon.png'] = 'rbxassetid://14397465323',
	['ElevateV4/assets/new/radaricon.png'] = 'rbxassetid://14368343291',
	['ElevateV4/assets/new/rainbow_1.png'] = 'rbxassetid://14368344374',
	['ElevateV4/assets/new/rainbow_2.png'] = 'rbxassetid://14368345149',
	['ElevateV4/assets/new/rainbow_3.png'] = 'rbxassetid://14368345840',
	['ElevateV4/assets/new/rainbow_4.png'] = 'rbxassetid://14368346696',
	['ElevateV4/assets/new/range.png'] = 'rbxassetid://14368347435',
	['ElevateV4/assets/new/rangearrow.png'] = 'rbxassetid://14368348640',
	['ElevateV4/assets/new/rendericon.png'] = 'rbxassetid://14368350193',
	['ElevateV4/assets/new/rendertab.png'] = 'rbxassetid://14397373458',
	['ElevateV4/assets/new/search.png'] = 'rbxassetid://14425646684',
	['ElevateV4/assets/new/targetinfoicon.png'] = 'rbxassetid://14368354234',
	['ElevateV4/assets/new/targetnpc1.png'] = 'rbxassetid://14497400332',
	['ElevateV4/assets/new/targetnpc2.png'] = 'rbxassetid://14497402744',
	['ElevateV4/assets/new/targetplayers1.png'] = 'rbxassetid://14497396015',
	['ElevateV4/assets/new/targetplayers2.png'] = 'rbxassetid://14497397862',
	['ElevateV4/assets/new/targetstab.png'] = 'rbxassetid://14497393895',
	['ElevateV4/assets/new/textguiicon.png'] = 'rbxassetid://14368355456',
	['ElevateV4/assets/new/utilityicon.png'] = 'rbxassetid://14368359107',
	['ElevateV4/assets/new/vape.png'] = 'rbxassetid://14373395239',
	['ElevateV4/assets/new/warning.png'] = 'rbxassetid://14368361552',
	['ElevateV4/assets/new/worldicon.png'] = 'rbxassetid://14368362492'
}

local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end

local configapi = {}
configapi.Accents = {
	Path = 'ElevateV4/profiles/accent.txt',
	Stamp = table.concat({
		math.round(accent.Hue * 1000),
		math.round(accent.Sat * 1000),
		math.round(accent.Value * 1000)
	}, ','),
	Retired = {Hue = 0.46, Sat = 0.96, Value = 0.52, Notch = 4}
}
configapi.Accents.Done = isfile(configapi.Accents.Path) and (function()
	local suc, res = pcall(readfile, configapi.Accents.Path)
	return suc and type(res) == 'string' and res:gsub('%s+', '') == configapi.Accents.Stamp
end)() or false
configapi.Accents.Stamped = configapi.Accents.Done

function configapi.Accents.Mark()
	if configapi.Accents.Stamped then return end
	configapi.Accents.Stamped = true
	pcall(writefile, configapi.Accents.Path, configapi.Accents.Stamp)
end
function configapi.Accents.IsRetired(saved)
	local retired = configapi.Accents.Retired
	if type(saved) ~= 'table' or saved.Rainbow or saved.CustomColor then return false end
	if saved.Notch and saved.Notch ~= retired.Notch then return false end
	if type(saved.Hue) ~= 'number' or type(saved.Sat) ~= 'number' or type(saved.Value) ~= 'number' then
		return saved.Notch == retired.Notch
	end
	return math.abs(saved.Hue - retired.Hue) < 0.02
		and math.abs(saved.Sat - retired.Sat) < 0.02
		and math.abs(saved.Value - retired.Value) < 0.02
end
function configapi.Accents.Defaulted(optionsettings)
	return (optionsettings.DefaultHue or accent.Hue) == accent.Hue
		and (optionsettings.DefaultSat or accent.Sat) == accent.Sat
		and (optionsettings.DefaultValue or accent.Value) == accent.Value
end
function configapi.Accents.Apply(saved, defaulted)
	if configapi.Accents.Done or defaulted == false or not configapi.Accents.IsRetired(saved) then return saved end
	local migrated = table.clone(saved)
	migrated.Hue, migrated.Sat, migrated.Value = accent.Hue, accent.Sat, accent.Value
	if migrated.Notch then
		migrated.Notch = accent.Notch
	end
	return migrated
end
local fontsizeCache, fontsizeCacheCount = {}, 0
local getfontsize = function(text, size, font)
	if typeof(font) == 'Font' then
		fontsize.Font = font
	end
	local key = tostring(text)..'\0'..tostring(size)..'\0'..tostring(fontsize.Font)
	local cached = fontsizeCache[key]
	if cached then return cached end
	fontsize.Text = text
	fontsize.Size = size
	local bounds = textService:GetTextBoundsAsync(fontsize)
	if fontsizeCacheCount >= 4096 then
		table.clear(fontsizeCache)
		fontsizeCacheCount = 0
	end
	fontsizeCache[key] = bounds
	fontsizeCacheCount += 1
	return bounds
end

local function addBlur(parent, notif)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('ElevateV4/assets/new/'..(notif and 'blurnotif' or 'blur')..'.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent

	return blur
end

local function addCorner(parent, radius)
	local corner = Instance.new('UICorner')
	corner.CornerRadius = radius or UDim.new(0, 8)
	corner.Parent = parent

	return corner
end
local function addWindowStroke(parent, transparency)
	local stroke = Instance.new('UIStroke')
	stroke.Name = 'EdgeStroke'
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = transparency or 0.9
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addCloseButton(parent, offset)
	local close = Instance.new('ImageButton')
	close.Name = 'Close'
	close.Size = UDim2.fromOffset(24, 24)
	close.Position = UDim2.new(1, -35, 0, offset or 9)
	close.BackgroundColor3 = Color3.new(1, 1, 1)
	close.BackgroundTransparency = 1
	close.AutoButtonColor = false
	close.Image = getcustomasset('ElevateV4/assets/new/close.png')
	close.ImageColor3 = color.Light(uipallet.Text, 0.2)
	close.ImageTransparency = 0.5
	close.Parent = parent
	addCorner(close, UDim.new(1, 0))

	close.MouseEnter:Connect(function()
		close.ImageTransparency = 0.3
		tween:Tween(close, uipallet.Tween, {
			BackgroundTransparency = 0.6
		})
	end)
	close.MouseLeave:Connect(function()
		close.ImageTransparency = 0.5
		tween:Tween(close, uipallet.Tween, {
			BackgroundTransparency = 1
		})
	end)

	return close
end

local function addMaid(object)
	object.Connections = {}
	object.PendingTasks = {}
	object.Generation = object.Generation or 0
	function object:Clean(callback)
		if typeof(callback) == 'Instance' then
			table.insert(self.Connections, {
				Disconnect = function()
					callback:ClearAllChildren()
					callback:Destroy()
				end
			})
		elseif type(callback) == 'function' then
			table.insert(self.Connections, {
				Disconnect = function()
					pcall(callback)
				end
			})
		elseif type(callback) == 'thread' then
			table.insert(self.Connections, {
				Disconnect = function()
					pcall(task.cancel, callback)
				end
			})
		else
			table.insert(self.Connections, callback)
		end
	end
	function object:Cleanup()
		for _, connection in self.Connections do
			pcall(function()
				connection:Disconnect()
			end)
		end
		table.clear(self.Connections)
		for _, thread in self.PendingTasks do pcall(task.cancel, thread) end
		table.clear(self.PendingTasks)
	end
	function object:IsActive(generation)
		return self.Enabled and (generation == nil or self.Generation == generation)
	end
	function object:Delay(seconds, callback)
		local generation = self.Generation
		local thread
		thread = task.delay(seconds, function()
			local index = table.find(self.PendingTasks, thread)
			if index then table.remove(self.PendingTasks, index) end
			if self:IsActive(generation) then
				local ok, err = xpcall(callback, debug.traceback)
				if not ok and mainapi.RecordError then mainapi:RecordError(self.Name, err) end
			end
		end)
		table.insert(self.PendingTasks, thread)
		return thread
	end
	function object:Spawn(callback)
		local generation = self.Generation
		local thread
		thread = task.spawn(function()
			local index = table.find(self.PendingTasks, thread)
			if index then table.remove(self.PendingTasks, index) end
			if self:IsActive(generation) then
				local ok, err = xpcall(callback, debug.traceback)
				if not ok and mainapi.RecordError then mainapi:RecordError(self.Name, err) end
			end
		end)
		table.insert(self.PendingTasks, thread)
		return thread
	end
end
local tooltipOwner

local function addTooltip(gui, text, maxWidth)
	if not text then return end

	local owner = {}

	local function configManagerVisible()
		return mainapi.Categories
			and mainapi.Categories.Profiles
			and mainapi.Categories.Profiles.ConfigManager
			and mainapi.Categories.Profiles.ConfigManager.Visible
	end

	local function tooltipMoved(x, y)
		if configManagerVisible() then
			tooltip.Visible = false
			return
		end
		local right = x + 16 + tooltip.Size.X.Offset > (scale.Scale * 1920)
		tooltip.Position = UDim2.fromOffset(
			(right and x - (tooltip.Size.X.Offset * scale.Scale) - 16 or x + 16) / scale.Scale,
			((y + 11) - (tooltip.Size.Y.Offset / 2)) / scale.Scale
		)
		tooltip.Visible = toolblur.Visible
	end

	gui.MouseEnter:Connect(function(x, y)
		if configManagerVisible() then return end
		local tooltipSize = getfontsize(text, tooltip.TextSize, uipallet.Font)
		local contentWidth = tooltipSize.X
		tooltip.TextWrapped = false
		tooltip.TextXAlignment = Enum.TextXAlignment.Center
		tooltip.TextYAlignment = Enum.TextYAlignment.Center
		if maxWidth and tooltipSize.X + 12 > maxWidth then
			contentWidth = math.max(40, maxWidth - 12)
			fontsize.Width = contentWidth
			local success, wrappedSize = pcall(getfontsize, text, tooltip.TextSize, uipallet.Font)
			fontsize.Width = math.huge
			if success then tooltipSize = wrappedSize end
			tooltip.TextWrapped = true
			tooltip.TextXAlignment = Enum.TextXAlignment.Left
			tooltip.TextYAlignment = Enum.TextYAlignment.Top
		end
		tooltip.Size = UDim2.fromOffset(contentWidth + 12, tooltipSize.Y + 12)
		tooltip.Text = text
		tooltipOwner = owner
		tooltipMoved(x, y)
	end)
	gui.MouseMoved:Connect(tooltipMoved)
	gui.MouseLeave:Connect(function()
		if tooltipOwner ~= owner then return end
		tooltipOwner = nil
		tooltip.Visible = false
	end)
end

local function checkKeybinds(compare, target, key)
	if type(target) == 'table' then
		if table.find(target, key) then
			for i, v in target do
				if not table.find(compare, v) then
					return false
				end
			end
			return true
		end
	end

	return false
end

local function createDownloader(text)
	if mainapi.Loaded ~= true then
		local downloader = mainapi.Downloader
		if not downloader and not license.Closet then
			downloader = Instance.new('TextLabel')
			downloader.Size = UDim2.new(1, 0, 0, 40)
			downloader.BackgroundTransparency = 1
			downloader.TextStrokeTransparency = 0
			downloader.TextSize = 20
			downloader.TextColor3 = Color3.new(1, 1, 1)
			downloader.FontFace = uipallet.Font
			downloader.Parent = mainapi.gui
			mainapi.Downloader = downloader
		end
		pcall(function()
			downloader.Text = 'Downloading '..text
		end)
	end
end

local function createMobileButton(buttonapi, position)
	local heldbutton = false
	local button = Instance.new('TextButton')
	button.Size = UDim2.fromOffset(40, 40)
	button.Position = UDim2.fromOffset(position.X, position.Y)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = buttonapi.Enabled and Color3.new(0, 0.7, 0) or Color3.new()
	button.BackgroundTransparency = 0.5
	button.Text = buttonapi.Name
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.Gotham
	button.Parent = mainapi.gui
	local buttonconstraint = Instance.new('UITextSizeConstraint')
	buttonconstraint.MaxTextSize = 16
	buttonconstraint.Parent = button
	addCorner(button, UDim.new(1, 0))

	button.MouseButton1Down:Connect(function()
		heldbutton = true
		local holdtime, holdpos = tick(), inputService:GetMouseLocation()
		repeat
			heldbutton = (inputService:GetMouseLocation() - holdpos).Magnitude < 6
			task.wait()
		until (tick() - holdtime) > 1 or not heldbutton
		if heldbutton then
			buttonapi.Bind = {}
			button:Destroy()
		end
	end)
	button.MouseButton1Up:Connect(function()
		heldbutton = false
	end)
	button.MouseButton1Click:Connect(function()
		buttonapi:Toggle()
		button.BackgroundColor3 = buttonapi.Enabled and Color3.new(0, 0.7, 0) or Color3.new()
	end)

	buttonapi.Bind = {Button = button}
end

local function encodeRemoteSource(value)
	return tostring(value):gsub('([^%w%-%._~])', function(character)
		return string.format('%%%02X', string.byte(character))
	end)
end

local versionPinPath = 'ElevateV4/profiles/version-pin.txt'

local function sourceBranch()
	return 'main'
end

local function installedSourceRef()
	local sharedRef = type(shared.ElevateV4PublicRef) == 'string' and shared.ElevateV4PublicRef:gsub('%s+', '') or ''
	if sharedRef ~= '' then return sharedRef end
	local ref = isfile('ElevateV4/profiles/commit.txt') and readfile('ElevateV4/profiles/commit.txt'):gsub('%s+', '') or ''
	return ref ~= '' and ref or sourceBranch()
end

local function remoteSourceUrl(path, ref)
	local selectedRef = ref or installedSourceRef()
	return shared.ElevateV4Base..selectedRef..'/'..
		select(1, path:gsub('^ElevateV4/', ''))
end

local function remoteLoaderUrl()
	return shared.ElevateV4Base..'main/init.lua'
end

local function remoteCommitUrl(ref)
	return shared.ElevateV4Api..'commits/'..encodeRemoteSource(ref)
end

local function remoteHistoryUrl(limit)
	local requested = math.clamp(tonumber(limit) or 11, 1, 11)
	return shared.ElevateV4Api..'commits?sha=main&per_page='..tostring(requested)
end

local function validDownloadedFile(path, body)
	if type(body) ~= 'string' or #body < 8 then return false end
	local head = body:sub(1, 300):lower()
	if head:find('^%s*404') or head:find('^%s*429') or head:find('^%s*5%d%d:')
		or head:find('^%s*too many requests') or head:find('^%s*retry later')
		or head:find('<!doctype html') or head:find('<html') then
		return false
	end
	if path:lower():sub(-4) == '.png' then
		return body:sub(1, 8) == '\137PNG\r\n\26\n'
	end
	return true
end

local function ensureDownloadFolder(path)
	local parent = path:gsub('\\', '/'):match('^(.*)/[^/]+$')
	if not parent then return end
	local built = ''
	for segment in parent:gmatch('[^/]+') do
		built = built == '' and segment or built..'/'..segment
		if not isfolder(built) then pcall(makefolder, built) end
	end
end

local warnedInvalidAsset
local function downloadFile(path, func)
	if type(path) ~= 'string' or path == '' then
		if not warnedInvalidAsset then
			warnedInvalidAsset = true
			local trace = debug and debug.traceback and select(2, pcall(debug.traceback)) or ''
			warn('[ElevateV4] Asset path was '..tostring(path)..' (reported once)'..tostring(trace))
		end
		return ''
	end

	local exists = isfile(path)
	if exists then
		local ok, cached = pcall(readfile, path)
		if not ok or not validDownloadedFile(path, cached) then
			if delfile then pcall(delfile, path) else pcall(writefile, path, '') end
			exists = false
		end
	end

	if not exists then
		createDownloader(path)
		local suc, res = pcall(function()
			if type(shared.ElevateV4FetchSource) == 'function' then
				return shared.ElevateV4FetchSource(path, installedSourceRef())
			end
			return game:HttpGet(remoteSourceUrl(path), true)
		end)
		if not suc then error(res) end
		if not validDownloadedFile(path, res) then
			error('Invalid GitLab response while downloading '..path, 0)
		end
		if path:sub(-4) == '.lua' then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		ensureDownloadFolder(path)
		writefile(path, res)
		local readOk, cached = pcall(readfile, path)
		if not readOk or not validDownloadedFile(path, cached) then
			error('Cached asset/source verification failed for '..path, 0)
		end
	end

	return (func or readfile)(path)
end
local resolvedAssets = {}
getcustomasset = (function()
local releaseIndex
local function releaseHash(path)
	if releaseIndex == nil then
		releaseIndex = false
		pcall(function()
			local decoded = httpService:JSONDecode(readfile('ElevateV4/profiles/contents.index.json'))
			if type(decoded) == 'table' then releaseIndex = decoded end
		end)
	end
	local hash = releaseIndex and releaseIndex[path:sub(10)]
	return type(hash) == 'string' and #hash == 8 and hash or nil
end
return function(path)
	local resolved = resolvedAssets[path]
	if resolved then return resolved end
	if type(path) ~= 'string' or path == '' then
		if not warnedInvalidAsset then
			warnedInvalidAsset = true
			local trace = debug and debug.traceback and select(2, pcall(debug.traceback)) or ''
			warn('[ElevateV4] getcustomasset called with '..tostring(path)..' (reported once)'..tostring(trace))
		end
		return ''
	end

	local downloaded, downloadError = pcall(downloadFile, path)
	if downloaded then
		local registerPath = path
		if path:sub(1, 16) == 'ElevateV4/assets/' then
			local staged, stagedPath = pcall(function()
				local stem, extension = path:sub(17):gsub('[/\\]', '-'):match('^(.-)(%.[^%.]*)$')
				if not stem then return nil end
				local body
				local hash = releaseHash(path)
				if not hash then
					body = readfile(path)
					local value = 2166136261
					for index = 1, #body do
						value = bit32.bxor(value, body:byte(index))
						local low = value % 65536
						value = (low * 16777619 + ((value - low) / 65536 * 16777619 % 65536) * 65536) % 4294967296
					end
					hash = string.format('%08x', value)
				end
				local prefix = 'ElevateV4/assets/registered/ElevateV4-'..stem..'-'
				local target = prefix..hash..extension
				if not isfile(target) then
					body = body or readfile(path)
					ensureDownloadFolder(target)
					if listfiles and delfile then
						for _, old in listfiles('ElevateV4/assets/registered') do
							old = old:gsub('\\', '/')
							local name = old:match('[^/]+$') or ''
							if name ~= target:match('[^/]+$') and name:sub(1, #prefix - 27) == prefix:sub(28) then pcall(delfile, old) end
						end
					end
					writefile(target, body)
				end
				return target
			end)
			if staged and stagedPath then registerPath = stagedPath end
		end
		for _, registerAsset in assetfunctions do
			local success, result = pcall(registerAsset, registerPath)
			if success and type(result) == 'string' and result ~= '' then
				resolvedAssets[path] = result
				return result
			end
		end
	else
		warn('[ElevateV4] Failed to cache asset '..tostring(path)..': '..tostring(downloadError))
	end
	return getcustomassets[path] or ''
end
end)()

local function getTableSize(tab)
	local ind = 0
	for _ in tab do ind += 1 end
	return ind
end

local function loopClean(tab)
	for i, v in tab do
		if type(v) == 'table' then
			loopClean(v)
		end
		tab[i] = nil
	end
end

local function loadJson(path)
	local suc, res = pcall(function()
		return httpService:JSONDecode(readfile(path))
	end)
	return suc and type(res) == 'table' and res or nil
end

local configFolder = 'ElevateV4/configs'
local profileFolder = 'ElevateV4/profiles'

local function ensureFolder(path)
	if makefolder and (not isfolder or not isfolder(path)) then
		pcall(makefolder, path)
	end
end

local function ensureDataFolders()
	ensureFolder('ElevateV4')
	ensureFolder(profileFolder)
	ensureFolder(configFolder)
end
local saveCache = {}
local function writeProfileFile(path, body)
	if saveCache[path] == body and isfile(path) then return end
	writefile(path, body)
	saveCache[path] = body
end

local function getConfigPath(profile)
	return configFolder..'/'..profile..mainapi.Place..'.json'
end

local function getLegacyProfilePath(profile)
	return profileFolder..'/'..profile..mainapi.Place..'.txt'
end

local function refreshConfigProfiles()
	local profiles, seen = {}, {}
	local function addProfile(name, bind)
		name = type(name) == 'string' and name:gsub('^%s*(.-)%s*$', '%1') or ''
		if name ~= '' and not seen[name] then
			seen[name] = true
			table.insert(profiles, {Name = name, Bind = bind or {}})
		end
	end

	for _, profile in mainapi.Profiles do
		addProfile(profile.Name, profile.Bind)
	end

	if listfiles then
		local suffix = tostring(mainapi.Place)..'.json'
		local suc, files = pcall(listfiles, configFolder)
		if suc then
			for _, path in files do
				local file = tostring(path):gsub('\\', '/')
				local name = file:match('/([^/]+)'..suffix:gsub('%.', '%%.')..'$')
				if name then
					addProfile(name)
				end
			end
		end
	end

	addProfile('default')
	table.sort(profiles, function(a, b)
		if a.Name == 'default' then return true end
		if b.Name == 'default' then return false end
		return a.Name:lower() < b.Name:lower()
	end)
	mainapi.Profiles = profiles
	return profiles
end

ensureDataFolders()

mainapi.ModuleSearchRefreshers = {}

function mainapi:ModuleMatchesSearch(module, query)
	query = tostring(query or ''):lower()
	local name = tostring(module.Name or ''):lower()
	local compact = query:gsub('%s+', '')
	return name:find(query, 1, true) ~= nil
		or name:gsub('%s+', ''):find(compact, 1, true) ~= nil
end

function mainapi:RefreshModuleSearches()
	for _, refresh in self.ModuleSearchRefreshers do pcall(refresh) end
end

function mainapi:BindModuleTitle(module, title, onSingleClick, onRightClick)
	local hovered = false
	title.MouseEnter:Connect(function() hovered = true end)
	title.MouseLeave:Connect(function() hovered = false end)
	title.MouseButton1Click:Connect(function()
		if onSingleClick then onSingleClick() end
	end)
	title.MouseButton2Click:Connect(function()
		if onRightClick then onRightClick() end
	end)
	return function() return hovered end
end

local defaultConfigs = {}

local function installBundledConfig(name, force)
	table.clear(saveCache)
	local sourcePath = 'ElevateV4/configs/'..name..'.json'
	if force or not isfile(sourcePath) then
		local downloaded = pcall(downloadFile, sourcePath)
		if not downloaded then return false end
	end
	local wrapper = loadJson(sourcePath)
	if not wrapper then return false end
	local configName = wrapper.name or name
	local configPath = getConfigPath(configName)
	if force or not isfile(configPath) then
		writefile(configPath, wrapper.config or '{}')
	end
	if wrapper.gui then
		local guiPath = 'ElevateV4/profiles/'..game.GameId..'.gui.txt'
		local guidata = isfile(guiPath) and loadJson(guiPath) or nil
		local defaultGui = httpService:JSONDecode(wrapper.gui)
		guidata = guidata or defaultGui
		guidata.Profiles = guidata.Profiles or {}
		local exists = false
		for _, profile in guidata.Profiles do
			if profile.Name == configName then
				exists = true
				break
			end
		end
		if not exists then
			table.insert(guidata.Profiles, {Name = configName, Bind = {}})
			writefile(guiPath, httpService:JSONEncode(guidata))
		end
	end
	return true
end

local function applySavedConfig(name)
	name = type(name) == 'string' and name:gsub('^%s*(.-)%s*$', '%1') or ''
	if name == '' then return false end
	mainapi:Save()
	mainapi:Load(true, name)
	mainapi:Save(name)
	return true
end

local function decodeJsonText(text)
	if type(text) ~= 'string' or text:gsub('%s+', '') == '' then return nil end
	local suc, res = pcall(function()
		return httpService:JSONDecode(text)
	end)
	return suc and type(res) == 'table' and res or nil
end

local function importJsonConfig(text, requestedName)
	table.clear(saveCache)
	local imported = decodeJsonText(text)
	if not imported then
		return false, 'The imported JSON is invalid.'
	end

	local configText = imported.config
	local configData = type(configText) == 'string' and decodeJsonText(configText) or type(configText) == 'table' and configText or imported
	if not configData then
		return false, 'The imported config data is invalid.'
	end

	local rawName = requestedName or imported.name or imported.profile or imported.Profile or ('imported-'..os.date('%Y%m%d-%H%M%S'))
	local configName = tostring(rawName):gsub('[\\/:*?"<>|]', '-'):gsub('^%s*(.-)%s*$', '%1')
	if configName == '' then
		configName = 'imported-'..os.date('%Y%m%d-%H%M%S')
	end

	ensureDataFolders()
	writefile(getConfigPath(configName), httpService:JSONEncode(configData))

	local guiPath = 'ElevateV4/profiles/'..game.GameId..'.gui.txt'
	local guidata = isfile(guiPath) and loadJson(guiPath) or {Categories = {}, Profiles = mainapi.Profiles or {{Name = 'default', Bind = {}}}}
	if type(imported.gui) == 'string' then
		local importedGui = decodeJsonText(imported.gui)
		if importedGui then
			guidata.Categories = importedGui.Categories or guidata.Categories or {}
			guidata.Keybind = importedGui.Keybind or guidata.Keybind
		end
	end

	guidata.Profiles = guidata.Profiles or {}
	local found = false
	for _, profile in guidata.Profiles do
		if profile.Name == configName then
			found = true
			break
		end
	end
	if not found then
		table.insert(guidata.Profiles, {Name = configName, Bind = {}})
	end
	guidata.Profile = configName
	writefile(guiPath, httpService:JSONEncode(guidata))

	refreshConfigProfiles()
	mainapi:Load(true, configName)
	mainapi:Save(configName)
	return true, configName
end

local function installBundledConfigs(force)
	local installed = false
	for _, name in defaultConfigs do
		installed = installBundledConfig(name, force) or installed
	end
	refreshConfigProfiles()
	return installed
end

local function removeSavedConfig(name)
	table.clear(saveCache)
	name = type(name) == 'string' and name:gsub('^%s*(.-)%s*$', '%1') or ''
	if name == '' or name == 'default' then return false end
	if isfile(getConfigPath(name)) and delfile then
		delfile(getConfigPath(name))
	end
	for i = #mainapi.Profiles, 1, -1 do
		if mainapi.Profiles[i].Name == name then
			table.remove(mainapi.Profiles, i)
		end
	end
	if mainapi.Profile == name then
		mainapi.Profile = 'default'
	end
	mainapi:Save(mainapi.Profile)
	refreshConfigProfiles()
	return true
end

function configapi.ResetProfile()
	local profile = mainapi.Profile or 'default'

	mainapi.Loaded = false
	mainapi.Save = function() end

	ensureDataFolders()

	for _, path in {getConfigPath(profile), getLegacyProfilePath(profile)} do
		if isfile(path) and delfile then
			pcall(delfile, path)
		end
	end

	local profiles = {}
	for _, entry in mainapi.Profiles or {} do
		if type(entry) == 'table' and entry.Name then
			table.insert(profiles, {Name = entry.Name, Bind = {}})
		end
	end
	if #profiles == 0 then
		profiles = {{Name = 'default', Bind = {}}}
	end
	pcall(writefile, 'ElevateV4/profiles/'..game.GameId..'.gui.txt', httpService:JSONEncode({
		Categories = {},
		Profile = profile,
		Profiles = profiles,
		Keybind = {'RightShift'}
	}))

	for path, value in {
		['ElevateV4/profiles/forcegame.txt'] = 'false',
		['ElevateV4/profiles/forcegameid.txt'] = tostring(game.PlaceId),
		['ElevateV4/profiles/hide.txt'] = 'false',
		['ElevateV4/profiles/disableloading.txt'] = 'false',
		['ElevateV4/profiles/gui.txt'] = 'new'
	} do
		pcall(writefile, path, value)
	end

	if isfile(configapi.Accents.Path) and delfile then
		pcall(delfile, configapi.Accents.Path)
	end

	return profile
end

configapi.Presets = {
	Path = profileFolder..'/presetconfigs.json',
	ClientPath = profileFolder..'/communityclientid.txt',
	Api = (shared.ElevateV4Api:gsub('/$', ''))
}
configapi.Presets.Registry = (isfile(configapi.Presets.Path) and loadJson(configapi.Presets.Path)) or {}
function configapi.Presets.Base()
	return shared.ElevateV4Base..'main/configs/'
end

function configapi.Presets.ClientId()
	if configapi.Presets.InstallationId then return configapi.Presets.InstallationId end
	local stored = isfile(configapi.Presets.ClientPath) and tostring(readfile(configapi.Presets.ClientPath)):lower():match('^%s*([a-f0-9%-]+)%s*$') or nil
	if not stored or #stored < 32 or #stored > 64 then
		stored = httpService:GenerateGUID(false):lower()
		pcall(writefile, configapi.Presets.ClientPath, stored)
	end
	configapi.Presets.InstallationId = stored
	return stored
end

function configapi.Presets.Usable(response)
	return type(response) == 'string' and response:find('^%s*{') ~= nil
		and response:sub(1, 11) ~= '{"message":' and response:sub(1, 9) ~= '{"error":'
		and response:sub(1, 6) ~= '{"ok":'
end
function configapi.Presets.Link()
	local telemetry = shared.AetherTelemetry
	if type(telemetry) == 'table' and telemetry.GetLink then
		return tostring(telemetry.GetLink() or '')
	end
	local saved = isfile(profileFolder..'/telemetry.json') and loadJson(profileFolder..'/telemetry.json') or nil
	return type(saved) == 'table' and type(saved.Link) == 'string' and saved.Link or ''
end
function configapi.Presets.Request(method, route, body)
	local requestFunction = request or http_request or (syn and syn.request)
	if not requestFunction then return false, 'Your executor cannot send web requests.', 0 end
	local headers = {['Content-Type'] = 'application/json', ['X-Aether-Install'] = configapi.Presets.ClientId()}
	local link = configapi.Presets.Link()
	if link:match('^alk_[%w_%-]+$') then headers.Authorization = 'Link '..link end
	local ok, response = pcall(requestFunction, {
		Url = configapi.Presets.Api..route,
		Method = method,
		Headers = headers,
		Body = body and httpService:JSONEncode(body) or nil
	})
	if not ok or type(response) ~= 'table' then return false, 'The config backend could not be reached.', 0 end
	local status = tonumber(response.StatusCode or response.Status) or 0
	local raw = type(response.Body) == 'string' and response.Body or ''
	local decodedOk, decoded = pcall(httpService.JSONDecode, httpService, raw)
	if not decodedOk then decoded = nil end
	if status >= 200 and status < 300 then return true, decoded or raw, raw, type(response.Headers) == 'table' and response.Headers or {} end
	return false, type(decoded) == 'table' and tostring(decoded.message or decoded.error) or ('HTTP '..status), status
end
function configapi.Presets.FromApi(config)
	local votes = (tonumber(config.likes) or 0) + (tonumber(config.dislikes) or 0)
	return {
		id = tostring(config.id),
		file = tostring(config.id)..'.json',
		name = config.name,
		description = config.description,
		credits = config.creator,
		tags = type(config.tags) == 'table' and config.tags or {},
		game = config.game,
		version = config.version,
		downloads = config.downloads,
		likes = config.likes,
		dislikes = config.dislikes,
		ratingCount = votes,
		ratingPercentage = config.rating,
		userRating = config.myVote,
		updatedAt = config.updatedAt,
		owned = config.owned == true,
		fromApi = true
	}
end
function configapi.Presets.Fetch(file)
	local id = tostring(file):gsub('%.json$', '')
	local ok, _, raw, headers = configapi.Presets.Request('GET', '/api/configs/'..httpService:UrlEncode(id)..'/download')
	if ok and configapi.Presets.Usable(raw) then
		local version
		for key, value in headers do
			if tostring(key):lower() == 'x-config-version' then version = tonumber(value) end
		end
		return raw, version
	end
	for _, url in {configapi.Presets.Base()..tostring(file)} do
		local success, response = pcall(function()
			return game:HttpGet(url, true)
		end)
		if success and configapi.Presets.Usable(response) then
			return response
		end
	end
	error('Could not download '..tostring(file))
end
configapi.Presets.Games = {
	[6872265039] = 'bedwars',
	[6872274481] = 'bedwars',
	[8768229691] = 'skywars',
	[71480482338212] = 'bedfight',
	[72169370437173] = 'tribes'
}

function configapi.Presets.Game()
	return configapi.Presets.Games[tonumber(mainapi.Place) or 0] or 'universal'
end
function configapi.Presets.FetchList(sort)
	local ok, result = configapi.Presets.Request('GET', '/api/configs?limit=60&sort='..httpService:UrlEncode(tostring(sort or 'trending'))
		..'&game='..configapi.Presets.Game())
	if ok and type(result) == 'table' and type(result.configs) == 'table' then
		local presets = {}
		for _, config in result.configs do
			if type(config) == 'table' and config.id then
				table.insert(presets, configapi.Presets.FromApi(config))
			end
		end
		return httpService:JSONEncode({presets = presets, source = 'api'})
	end
	error(ok and 'The config list is malformed' or tostring(result))
end
function configapi.Presets.Remember(configName, preset, installed)
	if type(configName) ~= 'string' or configName == '' then return end
	if type(preset) ~= 'table' or type(preset.file) ~= 'string' or preset.file == '' then return end
	local entry = configapi.Presets.Registry[configName]
	local same = entry ~= nil and entry.file == preset.file and entry.name == preset.name
	local version = installed and tonumber(preset.version) or (same and tonumber(entry.version) or nil)
	if same and version == tonumber(entry.version) then return end
	configapi.Presets.Registry[configName] = {file = preset.file, name = preset.name or configName, version = version}
	pcall(writefile, configapi.Presets.Path, httpService:JSONEncode(configapi.Presets.Registry))
end

function configapi.Presets.Get(configName)
	local entry = type(configName) == 'string' and configapi.Presets.Registry[configName] or nil
	return type(entry) == 'table' and type(entry.file) == 'string' and entry or nil
end

local featureLists = {
	{Tag = 'new', Key = 'newModules'},
	{Tag = 'updated', Key = 'updatedModules'},
	{Tag = 'broken', Key = 'brokenModules'}
}
local BROKEN_TAG_COLOUR = Color3.fromRGB(255, 95, 87)
local featureTags = {}

local function moduleTagKey(name)
	return (tostring(name):lower():gsub('[^%a%d]', ''))
end

do
	local path = 'ElevateV4/profiles/features.json'
	local data
	pcall(function()
		local commit = readfile('ElevateV4/profiles/commit.txt')
		local prefetched = type(shared.ElevateV4Features) == 'table' and shared.ElevateV4Features or nil
		local body
		local ref = (tostring(commit):gsub('%s+', ''))
		if prefetched and (prefetched.Ref == ref or shared.ElevateV4Commit == ref) and type(prefetched.Body) == 'string'
			and type(prefetched.At) == 'number' and (os.clock() - prefetched.At) < 60 then
			body = prefetched.Body
		else
			body = game:HttpGet(shared.ElevateV4Base..ref..'/profiles/features.json', true)
		end
		local decoded = httpService:JSONDecode(body)
		if type(decoded) == 'table' then
			data = decoded
			writefile(path, body)
		end
	end)
	if not data then
		pcall(downloadFile, path)
		data = loadJson(path) or {}
	end
	if #data > 0 then
		data = {newModules = data}
	end
	local sections = type(data.games) == 'table' and data.games or {universal = data}
	for section, lists in sections do
		if type(section) == 'string' and type(lists) == 'table' then
			local tags = {}
			featureTags[section:lower()] = tags
			for _, list in featureLists do
				local names = lists[list.Key]
				if type(names) == 'table' then
					for _, name in names do
						if type(name) == 'string' and name ~= '' then
							local key = moduleTagKey(name)
							tags[key] = tags[key] or {}
							table.insert(tags[key], list.Tag)
						end
					end
				end
			end
		end
	end
end
local function applyFeatureTags(tags, name)
	local key = moduleTagKey(name)
	for _, section in {'universal', configapi.Presets.Games[tonumber(mainapi.Place) or 0]} do
		for _, tag in featureTags[section] and featureTags[section][key] or {} do
			local duplicate = false
			for _, existing in tags do
				if type(existing) == 'string' and existing:lower() == tag then
					duplicate = true
					break
				end
			end
			if not duplicate then
				table.insert(tags, tag)
			end
		end
	end
end
local function makeDraggable(gui, window)
	gui.InputBegan:Connect(function(inputObj)
		if window and not window.Visible then return end
		if
			(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
			and (inputObj.Position.Y - gui.AbsolutePosition.Y < 40 or window)
		then
			local dragPosition = Vector2.new(
				gui.AbsolutePosition.X - inputObj.Position.X,
				gui.AbsolutePosition.Y - inputObj.Position.Y + guiService:GetGuiInset().Y
			) / scale.Scale

			local changed = inputService.InputChanged:Connect(function(input)
				if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
					local position = input.Position
					if inputService:IsKeyDown(Enum.KeyCode.LeftShift) then
						dragPosition = (dragPosition // 3) * 3
						position = (position // 3) * 3
					end
					gui.Position = UDim2.fromOffset((position.X / scale.Scale) + dragPosition.X, (position.Y / scale.Scale) + dragPosition.Y)
				end
			end)

			local ended
			ended = inputObj.Changed:Connect(function()
				if inputObj.UserInputState == Enum.UserInputState.End or inputObj.UserInputState == Enum.UserInputState.Cancel then
					if changed then
						changed:Disconnect()
					end
					if ended then
						ended:Disconnect()
					end
					if mainapi.ScheduleSave then mainapi:ScheduleSave() end
				end
			end)
		end
	end)
end

local function randomString()
	local array = {}
	for i = 1, math.random(10, 100) do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return str:gsub('<[^<>]->', '')
end

local function escapeRichText(str)
	return tostring(str or '')
		:gsub('&', '&amp;')
		:gsub('<', '&lt;')
		:gsub('>', '&gt;')
end

do
	local res = isfile('ElevateV4/profiles/color.txt') and loadJson('ElevateV4/profiles/color.txt')
	if res then
		uipallet.Main = res.Main and Color3.fromRGB(unpack(res.Main)) or uipallet.Main
		uipallet.Text = res.Text and Color3.fromRGB(unpack(res.Text)) or uipallet.Text
		uipallet.Font = res.Font and Font.new(
			res.Font:find('rbxasset') and res.Font
			or string.format('rbxasset://fonts/families/%s.json', res.Font)
		) or uipallet.Font
		uipallet.FontSemiBold = Font.new(uipallet.Font.Family, Enum.FontWeight.SemiBold)
	end
	fontsize.Font = uipallet.Font
end

do
	function color.Dark(col, num)
		local h, s, v = col:ToHSV()
		return Color3.fromHSV(h, s, math.clamp(select(3, uipallet.Main:ToHSV()) > 0.5 and v + num or v - num, 0, 1))
	end

	function color.Light(col, num)
		local h, s, v = col:ToHSV()
		return Color3.fromHSV(h, s, math.clamp(select(3, uipallet.Main:ToHSV()) > 0.5 and v - num or v + num, 0, 1))
	end

	function mainapi:Color(h)
		local s = 0.75 + (0.15 * math.min(h / 0.03, 1))
		if h > 0.57 then
			s = 0.9 - (0.4 * math.min((h - 0.57) / 0.09, 1))
		end
		if h > 0.66 then
			s = 0.5 + (0.4 * math.min((h - 0.66) / 0.16, 1))
		end
		if h > 0.87 then
			s = 0.9 - (0.15 * math.min((h - 0.87) / 0.13, 1))
		end
		return h, s, 1
	end

	function mainapi:TextColor(h, s, v)
		if v >= 0.7 and (s < 0.6 or h > 0.04 and h < 0.56) then
			return Color3.new(0.19, 0.19, 0.19)
		end
		return Color3.new(1, 1, 1)
	end
end

do
	function tween:Tween(obj, tweeninfo, goal, tab)
		tab = tab or self.tweens
		if tab[obj] then
			tab[obj]:Cancel()
			tab[obj] = nil
		end

		if obj.Parent and obj.Visible then
			tab[obj] = tweenService:Create(obj, tweeninfo, goal)
			tab[obj].Completed:Once(function()
				if tab then
					tab[obj] = nil
					tab = nil
				end
			end)
			tab[obj]:Play()
		else
			for i, v in goal do
				obj[i] = v
			end
		end
	end

	function tween:Cancel(obj)
		if self.tweens[obj] then
			self.tweens[obj]:Cancel()
			self.tweens[obj] = nil
		end
	end
end

mainapi.Libraries = {
	color = color,
	getcustomasset = getcustomasset,
	getfontsize = getfontsize,
	tween = tween,
	uipallet = uipallet,
}

local components
components = {
	Button = function(optionsettings, children, api)
		local button = Instance.new('TextButton')
		button.Name = optionsettings.Name..'Button'
		button.Size = UDim2.new(1, 0, 0, 31)
		button.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Visible = optionsettings.Visible == nil or type(optionsettings.Visible) == 'function' or optionsettings.Visible
		button.Text = ''
		button.Parent = children
		addTooltip(button, optionsettings.Tooltip)
		local bkg = Instance.new('Frame')
		bkg.Size = UDim2.fromOffset(200, 27)
		bkg.Position = UDim2.fromOffset(10, 2)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.05)
		bkg.Parent = button
		addCorner(bkg)
		local label = Instance.new('TextLabel')
		label.Size = UDim2.new(1, -4, 1, -4)
		label.Position = UDim2.fromOffset(2, 2)
		label.BackgroundColor3 = uipallet.Main
		label.Text = optionsettings.Name
		label.TextColor3 = color.Dark(uipallet.Text, 0.16)
		label.TextSize = 14
		label.FontFace = uipallet.Font
		label.Parent = bkg
		addCorner(label, UDim.new(0, 4))
		optionsettings.Function = optionsettings.Function or function() end

		button.MouseEnter:Connect(function()
			tween:Tween(bkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.0875)
			})
		end)
		button.MouseLeave:Connect(function()
			tween:Tween(bkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.05)
			})
		end)
		button.MouseButton1Click:Connect(optionsettings.Function)

		return {Object = button, Label = label, Name = optionsettings.Name}
	end,
	ColorSlider = function(optionsettings, children, api)
		local optionapi = {
			Type = 'ColorSlider',
			Hue = optionsettings.DefaultHue or accent.Hue,
			Sat = optionsettings.DefaultSat or accent.Sat,
			Value = optionsettings.DefaultValue or accent.Value,
			Opacity = optionsettings.DefaultOpacity or 1,
			Rainbow = false,
			Index = 0
		}

		local function createSlider(name, gradientColor)
			local slider = Instance.new('TextButton')
			slider.Name = optionsettings.Name..'Slider'..name
			slider.Size = UDim2.new(1, 0, 0, 50)
			slider.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
			slider.BorderSizePixel = 0
			slider.AutoButtonColor = false
			slider.Visible = false
			slider.Text = ''
			slider.Parent = children
			local title = Instance.new('TextLabel')
			title.Name = 'Title'
			title.Size = UDim2.fromOffset(60, 30)
			title.Position = UDim2.fromOffset(10, 2)
			title.BackgroundTransparency = 1
			title.Text = name
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.TextColor3 = color.Dark(uipallet.Text, 0.16)
			title.TextSize = 11
			title.FontFace = uipallet.Font
			title.Parent = slider
			local bkg = Instance.new('Frame')
			bkg.Name = 'Slider'
			bkg.Size = UDim2.new(1, -20, 0, 2)
			bkg.Position = UDim2.fromOffset(10, 37)
			bkg.BackgroundColor3 = Color3.new(1, 1, 1)
			bkg.BorderSizePixel = 0
			bkg.Parent = slider
			local gradient = Instance.new('UIGradient')
			gradient.Color = gradientColor
			gradient.Parent = bkg
			local fill = bkg:Clone()
			fill.Name = 'Fill'
			fill.Size = UDim2.fromScale(math.clamp(name == 'Saturation' and optionapi.Sat or name == 'Vibrance' and optionapi.Value or optionapi.Opacity, 0.04, 0.96), 1)
			fill.Position = UDim2.new()
			fill.BackgroundTransparency = 1
			fill.Parent = bkg
			local knobholder = Instance.new('Frame')
			knobholder.Name = 'Knob'
			knobholder.Size = UDim2.fromOffset(24, 4)
			knobholder.Position = UDim2.fromScale(1, 0.5)
			knobholder.AnchorPoint = Vector2.new(0.5, 0.5)
			knobholder.BackgroundColor3 = slider.BackgroundColor3
			knobholder.BorderSizePixel = 0
			knobholder.Parent = fill
			local knob = Instance.new('Frame')
			knob.Name = 'Knob'
			knob.Size = UDim2.fromOffset(14, 14)
			knob.Position = UDim2.fromScale(0.5, 0.5)
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.BackgroundColor3 = uipallet.Text
			knob.Parent = knobholder
			addCorner(knob, UDim.new(1, 0))

			slider.InputBegan:Connect(function(inputObj)
				if
					(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
					and (inputObj.Position.Y - slider.AbsolutePosition.Y) > (20 * scale.Scale)
				then
					local changed = inputService.InputChanged:Connect(function(input)
						if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
							optionapi:SetValue(nil, name == 'Saturation' and math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1) or nil, name == 'Vibrance' and math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1) or nil, name == 'Opacity' and math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1) or nil)
						end
					end)

					local ended
					ended = inputObj.Changed:Connect(function()
						if inputObj.UserInputState == Enum.UserInputState.End then
							if changed then changed:Disconnect() end
							if ended then ended:Disconnect() end
						end
					end)
				end
			end)
			slider.MouseEnter:Connect(function()
				tween:Tween(knob, uipallet.Tween, {
					Size = UDim2.fromOffset(16, 16)
				})
			end)
			slider.MouseLeave:Connect(function()
				tween:Tween(knob, uipallet.Tween, {
					Size = UDim2.fromOffset(14, 14)
				})
			end)

			return slider
		end

		local slider = Instance.new('TextButton')
		slider.Name = optionsettings.Name..'Slider'
		slider.Size = UDim2.new(1, 0, 0, 50)
		slider.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		slider.BorderSizePixel = 0
		slider.AutoButtonColor = false
		slider.Visible = optionsettings.Visible == nil or type(optionsettings.Visible) == 'function' or optionsettings.Visible
		slider.Text = ''
		slider.Parent = children
		addTooltip(slider, optionsettings.Tooltip)
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.fromOffset(60, 30)
		title.Position = UDim2.fromOffset(10, 2)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = color.Dark(uipallet.Text, 0.16)
		title.TextSize = 11
		title.FontFace = uipallet.Font
		title.Parent = slider
		local valuebox = Instance.new('TextBox')
		valuebox.Name = 'Box'
		valuebox.Size = UDim2.fromOffset(60, 15)
		valuebox.Position = UDim2.new(1, -69, 0, 9)
		valuebox.BackgroundTransparency = 1
		valuebox.Visible = false
		valuebox.Text = ''
		valuebox.TextXAlignment = Enum.TextXAlignment.Right
		valuebox.TextColor3 = color.Dark(uipallet.Text, 0.16)
		valuebox.TextSize = 11
		valuebox.FontFace = uipallet.Font
		valuebox.ClearTextOnFocus = true
		valuebox.Parent = slider
		local bkg = Instance.new('Frame')
		bkg.Name = 'Slider'
		bkg.Size = UDim2.new(1, -20, 0, 2)
		bkg.Position = UDim2.fromOffset(10, 39)
		bkg.BackgroundColor3 = Color3.new(1, 1, 1)
		bkg.BorderSizePixel = 0
		bkg.Parent = slider
		local rainbowTable = {}
		for i = 0, 1, 0.1 do
			table.insert(rainbowTable, ColorSequenceKeypoint.new(i, Color3.fromHSV(i, 1, 1)))
		end
		local gradient = Instance.new('UIGradient')
		gradient.Color = ColorSequence.new(rainbowTable)
		gradient.Parent = bkg
		local fill = bkg:Clone()
		fill.Name = 'Fill'
		fill.Size = UDim2.fromScale(math.clamp(optionapi.Hue, 0.04, 0.96), 1)
		fill.Position = UDim2.new()
		fill.BackgroundTransparency = 1
		fill.Parent = bkg
		local preview = Instance.new('ImageButton')
		preview.Name = 'Preview'
		preview.Size = UDim2.fromOffset(12, 12)
		preview.Position = UDim2.new(1, -22, 0, 10)
		preview.BackgroundTransparency = 1
		preview.Image = getcustomasset('ElevateV4/assets/new/colorpreview.png')
		preview.ImageColor3 = Color3.fromHSV(optionapi.Hue, optionapi.Sat, optionapi.Value)
		preview.ImageTransparency = 1 - optionapi.Opacity
		preview.Parent = slider
		local expandbutton = Instance.new('TextButton')
		expandbutton.Name = 'Expand'
		expandbutton.Size = UDim2.fromOffset(17, 13)
		expandbutton.Position = UDim2.new(0, textService:GetTextSize(title.Text, title.TextSize, title.Font, Vector2.new(1000, 1000)).X + 11, 0, 7)
		expandbutton.BackgroundTransparency = 1
		expandbutton.Text = ''
		expandbutton.Parent = slider
		local expand = Instance.new('ImageLabel')
		expand.Name = 'Expand'
		expand.Size = UDim2.fromOffset(9, 5)
		expand.Position = UDim2.fromOffset(4, 4)
		expand.BackgroundTransparency = 1
		expand.Image = getcustomasset('ElevateV4/assets/new/expandicon.png')
		expand.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		expand.Parent = expandbutton
		local rainbow = Instance.new('TextButton')
		rainbow.Name = 'Rainbow'
		rainbow.Size = UDim2.fromOffset(12, 12)
		rainbow.Position = UDim2.new(1, -42, 0, 10)
		rainbow.BackgroundTransparency = 1
		rainbow.Text = ''
		rainbow.Parent = slider
		local rainbow1 = Instance.new('ImageLabel')
		rainbow1.Size = UDim2.fromOffset(12, 12)
		rainbow1.BackgroundTransparency = 1
		rainbow1.Image = getcustomasset('ElevateV4/assets/new/rainbow_1.png')
		rainbow1.ImageColor3 = color.Light(uipallet.Main, 0.37)
		rainbow1.Parent = rainbow
		local rainbow2 = rainbow1:Clone()
		rainbow2.Image = getcustomasset('ElevateV4/assets/new/rainbow_2.png')
		rainbow2.Parent = rainbow
		local rainbow3 = rainbow1:Clone()
		rainbow3.Image = getcustomasset('ElevateV4/assets/new/rainbow_3.png')
		rainbow3.Parent = rainbow
		local rainbow4 = rainbow1:Clone()
		rainbow4.Image = getcustomasset('ElevateV4/assets/new/rainbow_4.png')
		rainbow4.Parent = rainbow
		local knobholder = Instance.new('Frame')
		knobholder.Name = 'Knob'
		knobholder.Size = UDim2.fromOffset(24, 4)
		knobholder.Position = UDim2.fromScale(1, 0.5)
		knobholder.AnchorPoint = Vector2.new(0.5, 0.5)
		knobholder.BackgroundColor3 = slider.BackgroundColor3
		knobholder.BorderSizePixel = 0
		knobholder.Parent = fill
		local knob = Instance.new('Frame')
		knob.Name = 'Knob'
		knob.Size = UDim2.fromOffset(14, 14)
		knob.Position = UDim2.fromScale(0.5, 0.5)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.BackgroundColor3 = uipallet.Text
		knob.Parent = knobholder
		addCorner(knob, UDim.new(1, 0))
		optionsettings.Function = optionsettings.Function or function() end
		local satSlider = createSlider('Saturation', ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, optionapi.Value)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(optionapi.Hue, 1, optionapi.Value))
		}))
		local vibSlider = createSlider('Vibrance', ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(optionapi.Hue, optionapi.Sat, 1))
		}))
		local opSlider = createSlider('Opacity', ColorSequence.new({
			ColorSequenceKeypoint.new(0, color.Dark(uipallet.Main, 0.02)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(optionapi.Hue, optionapi.Sat, optionapi.Value))
		}))

		function optionapi:Save(tab)
			tab[optionsettings.Name] = {
				Hue = self.Hue,
				Sat = self.Sat,
				Value = self.Value,
				Opacity = self.Opacity,
				Rainbow = self.Rainbow
			}
		end

		function optionapi:Load(tab)
			tab = configapi.Accents.Apply(tab, configapi.Accents.Defaulted(optionsettings))
			if tab.Rainbow ~= self.Rainbow then
				self:Toggle()
			end
			if self.Hue ~= tab.Hue or self.Sat ~= tab.Sat or self.Value ~= tab.Value or self.Opacity ~= tab.Opacity then
				self:SetValue(tab.Hue, tab.Sat, tab.Value, tab.Opacity)
			end
		end

		function optionapi:SetValue(h, s, v, o)
			self.Hue = h or self.Hue
			self.Sat = s or self.Sat
			self.Value = v or self.Value
			self.Opacity = o or self.Opacity
			preview.ImageColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
			preview.ImageTransparency = 1 - self.Opacity
			satSlider.Slider.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, self.Value)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, 1, self.Value))
			})
			vibSlider.Slider.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, 1))
			})
			opSlider.Slider.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, color.Dark(uipallet.Main, 0.02)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, self.Value))
			})

			if self.Rainbow then
				fill.Size = UDim2.fromScale(math.clamp(self.Hue, 0.04, 0.96), 1)
			else
				tween:Tween(fill, uipallet.Tween, {
					Size = UDim2.fromScale(math.clamp(self.Hue, 0.04, 0.96), 1)
				})
			end

			if s then
				tween:Tween(satSlider.Slider.Fill, uipallet.Tween, {
					Size = UDim2.fromScale(math.clamp(self.Sat, 0.04, 0.96), 1)
				})
			end
			if v then
				tween:Tween(vibSlider.Slider.Fill, uipallet.Tween, {
					Size = UDim2.fromScale(math.clamp(self.Value, 0.04, 0.96), 1)
				})
			end
			if o then
				tween:Tween(opSlider.Slider.Fill, uipallet.Tween, {
					Size = UDim2.fromScale(math.clamp(self.Opacity, 0.04, 0.96), 1)
				})
			end

			optionsettings.Function(self.Hue, self.Sat, self.Value, self.Opacity)
		end

		function optionapi:Toggle()
			self.Rainbow = not self.Rainbow
			if self.Rainbow then
				table.insert(mainapi.RainbowTable, self)
				rainbow1.ImageColor3 = Color3.fromRGB(5, 127, 100)
				task.delay(0.1, function()
					if not self.Rainbow then return end
					rainbow2.ImageColor3 = Color3.fromRGB(228, 125, 43)
					task.delay(0.1, function()
						if not self.Rainbow then return end
						rainbow3.ImageColor3 = Color3.fromRGB(225, 46, 52)
					end)
				end)
			else
				local ind = table.find(mainapi.RainbowTable, self)
				if ind then
					table.remove(mainapi.RainbowTable, ind)
				end
				rainbow3.ImageColor3 = color.Light(uipallet.Main, 0.37)
				task.delay(0.1, function()
					if self.Rainbow then return end
					rainbow2.ImageColor3 = color.Light(uipallet.Main, 0.37)
					task.delay(0.1, function()
						if self.Rainbow then return end
						rainbow1.ImageColor3 = color.Light(uipallet.Main, 0.37)
					end)
				end)
			end
		end

		local doubleClick = tick()
		preview.MouseButton1Click:Connect(function()
			preview.Visible = false
			valuebox.Visible = true
			valuebox:CaptureFocus()
			local text = Color3.fromHSV(optionapi.Hue, optionapi.Sat, optionapi.Value)
			valuebox.Text = math.round(text.R * 255)..', '..math.round(text.G * 255)..', '..math.round(text.B * 255)
		end)
		slider.InputBegan:Connect(function(inputObj)
			if
				(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
				and (inputObj.Position.Y - slider.AbsolutePosition.Y) > (20 * scale.Scale)
			then
				if doubleClick > tick() then
					optionapi:Toggle()
				end
				doubleClick = tick() + 0.3
				local changed = inputService.InputChanged:Connect(function(input)
					if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
						optionapi:SetValue(math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1))
					end
				end)

				local ended
				ended = inputObj.Changed:Connect(function()
					if inputObj.UserInputState == Enum.UserInputState.End then
						if changed then
							changed:Disconnect()
						end
						if ended then
							ended:Disconnect()
						end
					end
				end)
			end
		end)
		slider.MouseEnter:Connect(function()
			tween:Tween(knob, uipallet.Tween, {
				Size = UDim2.fromOffset(16, 16)
			})
		end)
		slider.MouseLeave:Connect(function()
			tween:Tween(knob, uipallet.Tween, {
				Size = UDim2.fromOffset(14, 14)
			})
		end)
		slider:GetPropertyChangedSignal('Visible'):Connect(function()
			satSlider.Visible = expand.Rotation == 180 and slider.Visible
			vibSlider.Visible = satSlider.Visible
			opSlider.Visible = satSlider.Visible
		end)
		expandbutton.MouseEnter:Connect(function()
			expand.ImageColor3 = color.Dark(uipallet.Text, 0.16)
		end)
		expandbutton.MouseLeave:Connect(function()
			expand.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		end)
		expandbutton.MouseButton1Click:Connect(function()
			satSlider.Visible = not satSlider.Visible
			vibSlider.Visible = satSlider.Visible
			opSlider.Visible = satSlider.Visible
			expand.Rotation = satSlider.Visible and 180 or 0
		end)
		rainbow.MouseButton1Click:Connect(function()
			optionapi:Toggle()
		end)
		valuebox.FocusLost:Connect(function(enter)
			preview.Visible = true
			valuebox.Visible = false
			if enter then
				local commas = valuebox.Text:split(',')
				local suc, res = pcall(function()
					return tonumber(commas[1]) and Color3.fromRGB(tonumber(commas[1]), tonumber(commas[2]), tonumber(commas[3])) or Color3.fromHex(valuebox.Text)
				end)
				if suc then
					if optionapi.Rainbow then
						optionapi:Toggle()
					end
					optionapi:SetValue(res:ToHSV())
				end
			end
		end)

		optionapi.Object = slider
		api.Options[optionsettings.Name] = optionapi

		return optionapi
	end,
	Dropdown = function(optionsettings, children, api)
		local optionapi = {
			Type = 'Dropdown',
			Value = table.find(optionsettings.List, optionsettings.Default) and optionsettings.Default or optionsettings.List[1] or 'None',
			List = optionsettings.List,
			Index = 0
		}

		local dropdown = Instance.new('TextButton')
		dropdown.Name = optionsettings.Name..'Dropdown'
		dropdown.Size = UDim2.new(1, 0, 0, 40)
		dropdown.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		dropdown.BorderSizePixel = 0
		dropdown.AutoButtonColor = false
		dropdown.Visible = optionsettings.Visible == nil or type(optionsettings.Visible) == 'function' or optionsettings.Visible
		dropdown.Text = ''
		dropdown.Parent = children
		addTooltip(dropdown, optionsettings.Tooltip or optionsettings.Name)
		local bkg = Instance.new('Frame')
		bkg.Name = 'BKG'
		bkg.Size = UDim2.new(1, -20, 1, -9)
		bkg.Position = UDim2.fromOffset(10, 4)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		bkg.Parent = dropdown
		addCorner(bkg, UDim.new(0, 6))
		local button = Instance.new('TextButton')
		button.Name = 'Dropdown'
		button.Size = UDim2.new(1, -2, 1, -2)
		button.Position = UDim2.fromOffset(1, 1)
		button.BackgroundColor3 = uipallet.Main
		button.AutoButtonColor = false
		button.Text = ''
		button.Parent = bkg
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, 0, 0, 29)
		title.BackgroundTransparency = 1
		title.Text = '         '..optionsettings.Name..' - '..optionapi.Value
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = color.Dark(uipallet.Text, 0.16)
		title.TextSize = 13
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.FontFace = uipallet.Font
		title.Parent = button
		addCorner(button, UDim.new(0, 6))
		local arrow = Instance.new('ImageLabel')
		arrow.Name = 'Arrow'
		arrow.Size = UDim2.fromOffset(4, 8)
		arrow.Position = UDim2.new(1, -17, 0, 11)
		arrow.BackgroundTransparency = 1
		arrow.Image = getcustomasset('ElevateV4/assets/new/expandright.png')
		arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
		arrow.Rotation = 90
		arrow.Parent = button
		optionsettings.Function = optionsettings.Function or function() end
		local dropdownchildren

		function optionapi:Save(tab)
			tab[optionsettings.Name] = {Value = self.Value}
		end

		function optionapi:Load(tab)
			if self.Value ~= tab.Value then
				self:SetValue(tab.Value)
			end
		end

		function optionapi:Change(list)
			optionsettings.List = list or {}
			if not table.find(optionsettings.List, self.Value) then
				self:SetValue(self.Value)
			end
		end

		function optionapi:SetValue(val, mouse)
			self.Value = table.find(optionsettings.List, val) and val or optionsettings.List[1] or 'None'
			title.Text = '         '..optionsettings.Name..' - '..self.Value
			if dropdownchildren then
				arrow.Rotation = 90
				dropdownchildren:Destroy()
				dropdownchildren = nil
				dropdown.Size = UDim2.new(1, 0, 0, 40)
			end
			optionsettings.Function(self.Value, mouse)
			if mainapi.RefreshContextualOptions then
				task.defer(mainapi.RefreshContextualOptions, mainapi)
			end
		end

		button.MouseButton1Click:Connect(function()
			if not dropdownchildren then
				arrow.Rotation = 270
				dropdown.Size = UDim2.new(1, 0, 0, 40 + (#optionsettings.List - 1) * 26)
				dropdownchildren = Instance.new('Frame')
				dropdownchildren.Name = 'Children'
				dropdownchildren.Size = UDim2.new(1, 0, 0, (#optionsettings.List - 1) * 26)
				dropdownchildren.Position = UDim2.fromOffset(0, 27)
				dropdownchildren.BackgroundTransparency = 1
				dropdownchildren.Parent = button
				local ind = 0
				for _, v in optionsettings.List do
					if v == optionapi.Value then continue end
					local dropdownoption = Instance.new('TextButton')
					dropdownoption.Name = v..'Option'
					dropdownoption.Size = UDim2.new(1, 0, 0, 26)
					dropdownoption.Position = UDim2.fromOffset(0, ind * 26)
					dropdownoption.BackgroundColor3 = uipallet.Main
					dropdownoption.BorderSizePixel = 0
					dropdownoption.AutoButtonColor = false
					dropdownoption.Text = '         '..v
					dropdownoption.TextXAlignment = Enum.TextXAlignment.Left
					dropdownoption.TextColor3 = color.Dark(uipallet.Text, 0.16)
					dropdownoption.TextSize = 13
					dropdownoption.TextTruncate = Enum.TextTruncate.AtEnd
					dropdownoption.FontFace = uipallet.Font
					dropdownoption.Parent = dropdownchildren
					dropdownoption.MouseEnter:Connect(function()
						tween:Tween(dropdownoption, uipallet.Tween, {
							BackgroundColor3 = color.Light(uipallet.Main, 0.02)
						})
					end)
					dropdownoption.MouseLeave:Connect(function()
						tween:Tween(dropdownoption, uipallet.Tween, {
							BackgroundColor3 = uipallet.Main
						})
					end)
					dropdownoption.MouseButton1Click:Connect(function()
						optionapi:SetValue(v, true)
					end)
					ind += 1
				end
			else
				optionapi:SetValue(optionapi.Value, true)
			end
		end)
		dropdown.MouseEnter:Connect(function()
			tween:Tween(bkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.0875)
			})
		end)
		dropdown.MouseLeave:Connect(function()
			tween:Tween(bkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.034)
			})
		end)

		optionapi.Object = dropdown
		api.Options[optionsettings.Name] = optionapi

		return optionapi
	end,
	MultiDropdown = function(optionsettings, children, api)
		optionsettings.List = optionsettings.List or {}
		local optionapi = {
			Type = 'MultiDropdown',
			Value = {},
			List = optionsettings.List,
			Index = 0
		}
		for _, v in optionsettings.Default or {} do
			if table.find(optionsettings.List, v) and not table.find(optionapi.Value, v) then
				table.insert(optionapi.Value, v)
			end
		end
		optionapi.ListEnabled = optionapi.Value

		local ROW, MAXROWS = 24, 7
		local dropdown = Instance.new('TextButton')
		dropdown.Name = optionsettings.Name..'MultiDropdown'
		dropdown.Size = UDim2.new(1, 0, 0, 40)
		dropdown.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		dropdown.BorderSizePixel = 0
		dropdown.AutoButtonColor = false
		dropdown.Visible = optionsettings.Visible == nil or type(optionsettings.Visible) == 'function' or optionsettings.Visible
		dropdown.Text = ''
		dropdown.Parent = children
		addTooltip(dropdown, optionsettings.Tooltip or optionsettings.Name)
		local bkg = Instance.new('Frame')
		bkg.Name = 'BKG'
		bkg.Size = UDim2.new(1, -20, 1, -9)
		bkg.Position = UDim2.fromOffset(10, 4)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		bkg.Parent = dropdown
		addCorner(bkg, UDim.new(0, 6))
		local button = Instance.new('TextButton')
		button.Name = 'Dropdown'
		button.Size = UDim2.new(1, -2, 1, -2)
		button.Position = UDim2.fromOffset(1, 1)
		button.BackgroundColor3 = uipallet.Main
		button.AutoButtonColor = false
		button.ClipsDescendants = true
		button.Text = ''
		button.Parent = bkg
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -24, 0, 29)
		title.BackgroundTransparency = 1
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = color.Dark(uipallet.Text, 0.16)
		title.TextSize = 13
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.FontFace = uipallet.Font
		title.Parent = button
		addCorner(button, UDim.new(0, 6))
		local arrow = Instance.new('ImageLabel')
		arrow.Name = 'Arrow'
		arrow.Size = UDim2.fromOffset(4, 8)
		arrow.Position = UDim2.new(1, -17, 0, 11)
		arrow.BackgroundTransparency = 1
		arrow.Image = getcustomasset('ElevateV4/assets/new/expandright.png')
		arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
		arrow.Rotation = 90
		arrow.Parent = button
		optionsettings.Function = optionsettings.Function or function() end
		local listframe
		local ticks = {}
		local labelgen = 0

		local function accent()
			return Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		end

		local function display(v)
			v = tostring(v)
			if v:find('^[%l%d_]+$') then
				v = v:gsub('_', ' ')
				v = v:sub(1, 1):upper()..v:sub(2)
			end
			return v
		end

		local function summary(value)
			if #value == 0 then return 'None' end
			if #value == #optionsettings.List and #value > 1 then return 'All' end
			return #value..' selected'
		end

		local function relabel()
			local value = optionapi.Value
			title.Text = '         '..optionsettings.Name..' - '..(#value == 1 and display(value[1]) or summary(value))
			if #value < 2 or #value == #optionsettings.List then return end
			labelgen += 1
			local gen = labelgen
			task.spawn(function()
				local room = button.AbsoluteSize.X / (scale and scale.Scale > 0 and scale.Scale or 1) - 24
				if room <= 0 then room = 172 end
				local names = {}
				for _, v in value do
					table.insert(names, display(v))
				end
				local text = '         '..optionsettings.Name..' - '..table.concat(names, ', ')
				local ok, size = pcall(getfontsize, text, 13, uipallet.Font)
				if gen ~= labelgen then return end
				if ok and size.X <= room then
					title.Text = text
				end
			end)
		end

		local function paint()
			for name, tick in ticks do
				local on = table.find(optionapi.Value, name) ~= nil
				tick.Inner.BackgroundColor3 = on and accent() or uipallet.Main
				tick.Inner.BackgroundTransparency = on and 0 or 1
				tick.Label.TextColor3 = on and uipallet.Text or color.Dark(uipallet.Text, 0.3)
			end
		end

		local function close()
			if listframe then
				listframe:Destroy()
				listframe = nil
				table.clear(ticks)
			end
			arrow.Rotation = 90
			dropdown.Size = UDim2.new(1, 0, 0, 40)
		end

		function optionapi:Save(tab)
			tab[optionsettings.Name] = {Selected = table.clone(self.Value)}
		end

		function optionapi:Load(tab)
			if type(tab) == 'table' and type(tab.Selected) == 'table' then
				self:SetValue(tab.Selected)
			end
		end

		function optionapi:Has(name)
			return table.find(self.Value, name) ~= nil
		end

		function optionapi:SetValue(list, mouse)
			local new = {}
			for _, v in optionsettings.List do
				if type(list) == 'table' and table.find(list, v) then
					table.insert(new, v)
				end
			end
			self.Value = new
			self.ListEnabled = new
			relabel()
			paint()
			optionsettings.Function(self.Value, mouse)
			if mainapi.RefreshContextualOptions then
				task.defer(mainapi.RefreshContextualOptions, mainapi)
			end
		end

		function optionapi:Toggle(name, mouse)
			local list = table.clone(self.Value)
			local ind = table.find(list, name)
			if ind then
				table.remove(list, ind)
			else
				table.insert(list, name)
			end
			self:SetValue(list, mouse)
		end

		function optionapi:Change(list)
			optionsettings.List = list or {}
			self.List = optionsettings.List
			close()
			local kept = {}
			for _, v in self.Value do
				if table.find(optionsettings.List, v) then
					table.insert(kept, v)
				end
			end
			if #kept ~= #self.Value then
				self:SetValue(kept)
			else
				relabel()
			end
		end

		button.MouseButton1Click:Connect(function()
			if listframe then
				close()
				return
			end
			local count = #optionsettings.List
			local shown = math.min(count, MAXROWS)
			arrow.Rotation = 270
			dropdown.Size = UDim2.new(1, 0, 0, 40 + shown * ROW + 4)
			listframe = Instance.new('ScrollingFrame')
			listframe.Name = 'Children'
			listframe.Size = UDim2.new(1, 0, 0, shown * ROW)
			listframe.Position = UDim2.fromOffset(0, 29)
			listframe.BackgroundTransparency = 1
			listframe.BorderSizePixel = 0
			listframe.ScrollBarThickness = count > MAXROWS and 2 or 0
			listframe.ScrollBarImageTransparency = 0.5
			listframe.ScrollingDirection = Enum.ScrollingDirection.Y
			listframe.CanvasSize = UDim2.fromOffset(0, count * ROW)
			listframe.Parent = button
			for i, v in optionsettings.List do
				local row = Instance.new('TextButton')
				row.Name = v..'Option'
				row.Size = UDim2.new(1, count > MAXROWS and -4 or 0, 0, ROW)
				row.Position = UDim2.fromOffset(0, (i - 1) * ROW)
				row.BackgroundColor3 = uipallet.Main
				row.BorderSizePixel = 0
				row.AutoButtonColor = false
				row.Text = ''
				row.Parent = listframe
				local label = Instance.new('TextLabel')
				label.Name = 'Label'
				label.Size = UDim2.new(1, -46, 1, 0)
				label.BackgroundTransparency = 1
				label.Text = '         '..display(v)
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.TextSize = 13
				label.TextTruncate = Enum.TextTruncate.AtEnd
				label.FontFace = uipallet.Font
				label.Parent = row
				local box = Instance.new('Frame')
				box.Name = 'Tick'
				box.Size = UDim2.fromOffset(12, 12)
				box.Position = UDim2.new(1, -24, 0.5, -6)
				box.BackgroundColor3 = color.Light(uipallet.Main, 0.37)
				box.Parent = row
				addCorner(box, UDim.new(0, 3))
				local inner = Instance.new('Frame')
				inner.Name = 'Inner'
				inner.Size = UDim2.new(1, -2, 1, -2)
				inner.Position = UDim2.fromOffset(1, 1)
				inner.BorderSizePixel = 0
				inner.Parent = box
				addCorner(inner, UDim.new(0, 2))
				ticks[v] = {Inner = inner, Label = label}
				row.MouseEnter:Connect(function()
					tween:Tween(row, uipallet.Tween, {
						BackgroundColor3 = color.Light(uipallet.Main, 0.02)
					})
				end)
				row.MouseLeave:Connect(function()
					tween:Tween(row, uipallet.Tween, {
						BackgroundColor3 = uipallet.Main
					})
				end)
				row.MouseButton1Click:Connect(function()
					optionapi:Toggle(v, true)
				end)
			end
			paint()
		end)
		dropdown.MouseEnter:Connect(function()
			tween:Tween(bkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.0875)
			})
		end)
		dropdown.MouseLeave:Connect(function()
			tween:Tween(bkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.034)
			})
		end)

		relabel()
		optionapi.Object = dropdown
		api.Options[optionsettings.Name] = optionapi

		return optionapi
	end,
	ItemPicker = function(optionsettings, children, api)
		local optionapi = {
			Type = 'ItemPicker',
			Value = {},
			Items = optionsettings.Items or {},
			Window = {Visible = false},
			Index = 0
		}
		for _, v in optionsettings.Default or {} do
			if not table.find(optionapi.Value, v) then
				table.insert(optionapi.Value, v)
			end
		end
		if not optionsettings.Multi and #optionapi.Value > 1 then
			optionapi.Value = {optionapi.Value[1]}
		end
		optionapi.ListEnabled = optionapi.Value

		local picker = Instance.new('TextButton')
		picker.Name = optionsettings.Name..'ItemPicker'
		picker.Size = UDim2.new(1, 0, 0, 50)
		picker.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		picker.BorderSizePixel = 0
		picker.AutoButtonColor = false
		picker.Visible = optionsettings.Visible == nil or type(optionsettings.Visible) == 'function' or optionsettings.Visible
		picker.Text = ''
		picker.Parent = children
		addTooltip(picker, optionsettings.Tooltip or optionsettings.Name)
		local bkg = Instance.new('Frame')
		bkg.Name = 'BKG'
		bkg.Size = UDim2.new(1, -20, 1, -9)
		bkg.Position = UDim2.fromOffset(10, 4)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		bkg.Parent = picker
		addCorner(bkg, UDim.new(0, 4))
		local button = Instance.new('TextButton')
		button.Name = 'ItemPicker'
		button.Size = UDim2.new(1, -2, 1, -2)
		button.Position = UDim2.fromOffset(1, 1)
		button.BackgroundColor3 = uipallet.Main
		button.AutoButtonColor = false
		button.Text = ''
		button.Parent = bkg
		addCorner(button, UDim.new(0, 4))
		local buttontitle = Instance.new('TextLabel')
		buttontitle.Name = 'Title'
		buttontitle.Size = UDim2.new(1, -20, 0, 15)
		buttontitle.Position = UDim2.fromOffset(10, 4)
		buttontitle.BackgroundTransparency = 1
		buttontitle.Text = optionsettings.Name
		buttontitle.TextXAlignment = Enum.TextXAlignment.Left
		buttontitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
		buttontitle.TextSize = 15
		buttontitle.TextTruncate = Enum.TextTruncate.AtEnd
		buttontitle.FontFace = uipallet.Font
		buttontitle.Parent = button
		local summary = Instance.new('TextLabel')
		summary.Name = 'Summary'
		summary.Size = UDim2.new(1, -20, 0, 14)
		summary.Position = UDim2.fromOffset(10, 21)
		summary.BackgroundTransparency = 1
		summary.TextXAlignment = Enum.TextXAlignment.Left
		summary.TextColor3 = color.Dark(uipallet.Text, 0.43)
		summary.TextSize = 11
		summary.FontFace = uipallet.Font
		summary.Parent = button
		local strip = Instance.new('Frame')
		strip.Name = 'Icons'
		strip.Size = UDim2.new(1, -20, 0, 16)
		strip.Position = UDim2.fromOffset(10, 20)
		strip.BackgroundTransparency = 1
		strip.Parent = button
		local striplayout = Instance.new('UIListLayout')
		striplayout.FillDirection = Enum.FillDirection.Horizontal
		striplayout.Padding = UDim.new(0, 3)
		striplayout.SortOrder = Enum.SortOrder.LayoutOrder
		striplayout.Parent = strip

		local window = Instance.new('TextButton')
		window.Name = optionsettings.Name..'ItemWindow'
		window.Size = UDim2.fromOffset(262, 300)
		window.BackgroundColor3 = uipallet.Main
		window.BorderSizePixel = 0
		window.AutoButtonColor = false
		window.Visible = false
		window.Text = ''
		window.Parent = api.Panel or clickgui
		optionapi.Window = window
		addBlur(window)
		addCorner(window)
		local wintitle = Instance.new('TextLabel')
		wintitle.Name = 'Title'
		wintitle.Size = UDim2.new(1, -40, 0, 20)
		wintitle.Position = UDim2.fromOffset(12, 11)
		wintitle.BackgroundTransparency = 1
		wintitle.Text = optionsettings.Name
		wintitle.TextXAlignment = Enum.TextXAlignment.Left
		wintitle.TextColor3 = uipallet.Text
		wintitle.TextSize = 13
		wintitle.FontFace = uipallet.Font
		wintitle.Parent = window
		local closebutton = addCloseButton(window)
		local searchbkg = Instance.new('Frame')
		searchbkg.Name = 'Search'
		searchbkg.Size = UDim2.new(1, -20, 0, 31)
		searchbkg.Position = UDim2.fromOffset(10, 40)
		searchbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		searchbkg.Parent = window
		addCorner(searchbkg)
		local searchicon = Instance.new('ImageLabel')
		searchicon.Size = UDim2.fromOffset(14, 14)
		searchicon.Position = UDim2.fromOffset(9, 8)
		searchicon.BackgroundTransparency = 1
		searchicon.Image = getcustomasset('ElevateV4/assets/new/search.png')
		searchicon.ImageColor3 = color.Dark(uipallet.Text, 0.3)
		searchicon.Parent = searchbkg
		local searchbox = Instance.new('TextBox')
		searchbox.Size = UDim2.new(1, -36, 1, 0)
		searchbox.Position = UDim2.fromOffset(30, 0)
		searchbox.BackgroundTransparency = 1
		searchbox.Text = ''
		searchbox.PlaceholderText = 'Search items...'
		searchbox.TextXAlignment = Enum.TextXAlignment.Left
		searchbox.TextColor3 = uipallet.Text
		searchbox.TextSize = 14
		searchbox.FontFace = uipallet.Font
		searchbox.ClearTextOnFocus = false
		searchbox.Parent = searchbkg
		local grid = Instance.new('ScrollingFrame')
		grid.Name = 'Grid'
		grid.Size = UDim2.new(1, -20, 1, -86)
		grid.Position = UDim2.fromOffset(10, 78)
		grid.BackgroundTransparency = 1
		grid.BorderSizePixel = 0
		grid.ScrollBarThickness = 3
		grid.ScrollBarImageTransparency = 0.6
		grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
		grid.CanvasSize = UDim2.new()
		grid.Parent = window
		local gridlayout = Instance.new('UIGridLayout')
		gridlayout.CellSize = UDim2.fromOffset(36, 36)
		gridlayout.CellPadding = UDim2.fromOffset(4, 4)
		gridlayout.SortOrder = Enum.SortOrder.LayoutOrder
		gridlayout.Parent = grid
		optionsettings.Function = optionsettings.Function or function() end
		local cells = {}
		local built = false

		local function info(v)
			if type(v) == 'table' then
				return v.Name, v.Image, v.Label or v.Name
			end
			local image = optionsettings.Icon and optionsettings.Icon(v) or nil
			return v, image, v
		end

		local function iconOf(name)
			for _, v in optionapi.Items do
				local itemname, image = info(v)
				if itemname == name then
					return image
				end
			end
			return optionsettings.Icon and optionsettings.Icon(name) or nil
		end

		local function accent()
			return Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		end

		local function paint()
			for name, cell in cells do
				local on = table.find(optionapi.Value, name) ~= nil
				cell.Stroke.Color = on and accent() or color.Light(uipallet.Main, 0.1)
				cell.Stroke.Thickness = on and 2 or 1
				cell.Button.BackgroundColor3 = on and color.Light(uipallet.Main, 0.08) or color.Light(uipallet.Main, 0.02)
			end
		end

		local function refreshSummary()
			for _, v in strip:GetChildren() do
				if v:IsA('ImageLabel') or v:IsA('TextLabel') then
					v:Destroy()
				end
			end
			local count = #optionapi.Value
			if count == 0 then
				summary.Text = 'None'
				summary.Visible = true
				return
			end
			if count > 8 then
				summary.Text = count..' selected'
				summary.Visible = true
				return
			end
			summary.Visible = false
			for i, name in optionapi.Value do
				local image = iconOf(name)
				if image then
					local icon = Instance.new('ImageLabel')
					icon.Size = UDim2.fromOffset(16, 16)
					icon.BackgroundTransparency = 1
					icon.Image = image
					icon.LayoutOrder = i
					icon.Parent = strip
				else
					local label = Instance.new('TextLabel')
					label.AutomaticSize = Enum.AutomaticSize.X
					label.Size = UDim2.fromOffset(0, 16)
					label.BackgroundTransparency = 1
					label.Text = name
					label.TextColor3 = color.Dark(uipallet.Text, 0.43)
					label.TextSize = 11
					label.FontFace = uipallet.Font
					label.LayoutOrder = i
					label.Parent = strip
				end
			end
		end

		local function filter()
			local query = searchbox.Text:lower()
			for _, cell in cells do
				cell.Button.Visible = query == '' or cell.Search:find(query, 1, true) ~= nil
			end
		end

		local function build()
			for _, cell in cells do
				cell.Button:Destroy()
			end
			table.clear(cells)
			for i, v in optionapi.Items do
				local name, image, label = info(v)
				if not name or cells[name] then continue end
				local cell = Instance.new('ImageButton')
				cell.Name = name
				cell.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
				cell.AutoButtonColor = false
				cell.Image = ''
				cell.LayoutOrder = i
				cell.Parent = grid
				addCorner(cell, UDim.new(0, 5))
				local stroke = Instance.new('UIStroke')
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				stroke.Parent = cell
				if image then
					local icon = Instance.new('ImageLabel')
					icon.Size = UDim2.new(1, -8, 1, -8)
					icon.Position = UDim2.fromOffset(4, 4)
					icon.BackgroundTransparency = 1
					icon.Image = image
					icon.ScaleType = Enum.ScaleType.Fit
					icon.Parent = cell
				else
					local text = Instance.new('TextLabel')
					text.Size = UDim2.new(1, -4, 1, -4)
					text.Position = UDim2.fromOffset(2, 2)
					text.BackgroundTransparency = 1
					text.Text = label
					text.TextWrapped = true
					text.TextScaled = true
					text.TextColor3 = uipallet.Text
					text.FontFace = uipallet.Font
					text.Parent = cell
				end
				addTooltip(cell, label)
				cells[name] = {Button = cell, Stroke = stroke, Search = (name..' '..label):lower()}
				cell.MouseButton1Click:Connect(function()
					optionapi:Pick(name)
				end)
			end
			built = true
			paint()
			filter()
		end

		function optionapi:Save(tab)
			tab[optionsettings.Name] = {Items = table.clone(self.Value)}
		end

		function optionapi:Load(tab)
			if type(tab) == 'table' and type(tab.Items) == 'table' then
				self:SetValue(tab.Items)
			end
		end

		function optionapi:Has(name)
			return table.find(self.Value, name) ~= nil
		end

		function optionapi:SetValue(list)
			local new = {}
			for _, v in type(list) == 'table' and list or {} do
				if type(v) == 'string' and not table.find(new, v) then
					table.insert(new, v)
				end
			end
			if not optionsettings.Multi and #new > 1 then
				new = {new[1]}
			end
			self.Value = new
			self.ListEnabled = new
			paint()
			refreshSummary()
			optionsettings.Function(self.Value)
		end

		function optionapi:Pick(name)
			if optionsettings.Multi then
				local list = table.clone(self.Value)
				local ind = table.find(list, name)
				if ind then
					table.remove(list, ind)
				else
					table.insert(list, name)
				end
				self:SetValue(list)
			else
				self:SetValue(self.Value[1] == name and {} or {name})
				window.Visible = false
				bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
			end
		end

		function optionapi:Change(items)
			self.Items = items or {}
			if built then
				build()
			end
			refreshSummary()
		end

		closebutton.MouseButton1Click:Connect(function()
			window.Visible = false
			bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		end)
		button.MouseButton1Click:Connect(function()
			window.Visible = not window.Visible
			if window.Visible and not built then
				build()
			end
			tween:Cancel(bkg)
			bkg.BackgroundColor3 = window.Visible and accent() or color.Light(uipallet.Main, 0.034)
		end)
		searchbox:GetPropertyChangedSignal('Text'):Connect(filter)
		picker.MouseEnter:Connect(function()
			if not window.Visible then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.37)
				})
			end
		end)
		picker.MouseLeave:Connect(function()
			if not window.Visible then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.034)
				})
			end
		end)
		picker:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			local actualPosition = (picker.AbsolutePosition - (api.Panel and api.Panel.AbsolutePosition or -guiService:GetGuiInset())) / scale.Scale
			window.Position = UDim2.fromOffset(actualPosition.X + 220, actualPosition.Y)
		end)

		refreshSummary()
		optionapi.Object = picker
		api.Options[optionsettings.Name] = optionapi

		return optionapi
	end,
	Group = function(optionsettings, children, api)
		local groupapi, arrow
		local userFunction = optionsettings.Function

		local function refreshMembers()
			if not groupapi then return end
			for _, member in groupapi.Members do
				if member.RefreshVisibility then
					member:RefreshVisibility()
				end
			end
		end

		optionsettings.Function = function(open, ...)
			if arrow then
				arrow.Rotation = open and 270 or 90
			end
			refreshMembers()
			if userFunction then
				return userFunction(open, ...)
			end
		end
		groupapi = components.Toggle(optionsettings, children, api)
		groupapi.Type = 'Group'
		groupapi.Members = {}
		if optionsettings.Section then
			local knob = groupapi.Object:FindFirstChild('Knob')
			if knob then
				knob.Visible = false
			end
			arrow = Instance.new('ImageLabel')
			arrow.Name = 'Arrow'
			arrow.Size = UDim2.fromOffset(4, 8)
			arrow.Position = UDim2.new(1, -20, 0, 11)
			arrow.BackgroundTransparency = 1
			arrow.Image = getcustomasset('ElevateV4/assets/new/expandright.png')
			arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
			arrow.Rotation = groupapi.Enabled and 270 or 90
			arrow.Parent = groupapi.Object
		end
		groupapi.Object:GetPropertyChangedSignal('Visible'):Connect(refreshMembers)

		function groupapi:Shown()
			return self.Enabled and self.Object.Visible
		end

		for name, component in components do
			groupapi['Create'..name] = function(_, settings)
				settings = settings or {}
				if settings.Darker == nil then
					settings.Darker = true
				end
				local own = settings.Visible
				settings.Visible = function()
					if not groupapi:Shown() then
						return false
					end
					if type(own) == 'function' then
						return own()
					end
					return own ~= false
				end
				local member = mainapi:AttachContextualOption(component(settings, children, api), settings)
				table.insert(groupapi.Members, member)
				return member
			end
		end

		return groupapi
	end,
	SubModules = function(optionsettings, children, api)
		local names = optionsettings.Name or 'Modules'
		local subsapi = {Type = 'SubModules', Modules = {}}
		local holder = Instance.new('Frame')
		holder.Name = names..'Holder'
		holder.Size = UDim2.new(1, 0, 0, 0)
		holder.AutomaticSize = Enum.AutomaticSize.Y
		holder.BackgroundTransparency = 1
		holder.Parent = children
		local layout = Instance.new('UIListLayout')
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 3)
		layout.Parent = holder

		local function paint(sub)
			local on = sub.Enabled
			tween:Tween(sub.Knob, uipallet.Tween, {
				BackgroundColor3 = on and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or color.Light(uipallet.Main, 0.14)
			})
			tween:Tween(sub.KnobMain, uipallet.Tween, {
				Position = UDim2.fromOffset(on and 12 or 2, 2)
			})
			sub.Title.TextColor3 = on and color.Light(uipallet.Text, 0.2) or color.Dark(uipallet.Text, 0.16)
		end

		function subsapi:Create(def)
			def = def or {}
			local sub = {
				Name = def.Name,
				Enabled = false,
				Options = {},
				Members = {},
				Function = def.Function or function() end
			}
			local card = Instance.new('Frame')
			card.Name = tostring(def.Name)..'Card'
			card.Size = UDim2.new(1, 0, 0, 0)
			card.AutomaticSize = Enum.AutomaticSize.Y
			card.BackgroundTransparency = 1
			card.LayoutOrder = #subsapi.Modules + 1
			card.Parent = holder
			local cardlist = Instance.new('UIListLayout')
			cardlist.SortOrder = Enum.SortOrder.LayoutOrder
			cardlist.Parent = card

			local header = Instance.new('TextButton')
			header.Name = 'Header'
			header.Size = UDim2.new(1, 0, 0, 34)
			header.BackgroundColor3 = color.Dark(children.BackgroundColor3, 0.02)
			header.AutoButtonColor = false
			header.BorderSizePixel = 0
			header.Text = ''
			addCorner(header)
			addTooltip(header, def.Tooltip)
			header.Parent = card
			local title = Instance.new('TextLabel')
			title.Name = 'Title'
			title.Size = UDim2.new(1, -90, 1, 0)
			title.Position = UDim2.fromOffset(10, 0)
			title.BackgroundTransparency = 1
			title.Text = tostring(def.Name)
			title.TextTruncate = Enum.TextTruncate.AtEnd
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.TextColor3 = color.Dark(uipallet.Text, 0.16)
			title.TextSize = 13
			title.FontFace = uipallet.Font
			title.Parent = header
			local knobholder = Instance.new('Frame')
			knobholder.Name = 'Knob'
			knobholder.Size = UDim2.fromOffset(22, 12)
			knobholder.Position = UDim2.new(1, -58, 0, 11)
			knobholder.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
			knobholder.Parent = header
			addCorner(knobholder, UDim.new(1, 0))
			local knob = knobholder:Clone()
			knob.Size = UDim2.fromOffset(8, 8)
			knob.Position = UDim2.fromOffset(2, 2)
			knob.BackgroundColor3 = uipallet.Main
			knob.Parent = knobholder
			local arrowbutton = Instance.new('TextButton')
			arrowbutton.Name = 'Expand'
			arrowbutton.Size = UDim2.fromOffset(26, 34)
			arrowbutton.Position = UDim2.new(1, -26, 0, 0)
			arrowbutton.BackgroundTransparency = 1
			arrowbutton.Text = ''
			arrowbutton.Parent = header
			local arrow = Instance.new('ImageLabel')
			arrow.Name = 'Arrow'
			arrow.Size = UDim2.fromOffset(5, 9)
			arrow.Position = UDim2.fromOffset(10, 13)
			arrow.BackgroundTransparency = 1
			arrow.Image = getcustomasset('ElevateV4/assets/new/expandright.png')
			arrow.ImageColor3 = color.Light(uipallet.Main, 0.37)
			arrow.Rotation = 90
			arrow.Parent = arrowbutton

			local body = Instance.new('Frame')
			body.Name = 'Options'
			body.Size = UDim2.new(1, 0, 0, 0)
			body.AutomaticSize = Enum.AutomaticSize.Y
			body.BackgroundColor3 = children.BackgroundColor3
			body.BorderSizePixel = 0
			body.Visible = false
			body.Parent = card
			local bodylist = Instance.new('UIListLayout')
			bodylist.SortOrder = Enum.SortOrder.LayoutOrder
			bodylist.Parent = body

			sub.Title, sub.Knob, sub.KnobMain, sub.Body, sub.Object = title, knobholder, knob, body, card

			function sub:SetEnabled(value, silent)
				value = value and true or false
				if self.Enabled == value then return end
				self.Enabled = value
				paint(self)
				if not silent then
					local ok, err = pcall(self.Function, value)
					if not ok and shared.VapeDeveloper then
						mainapi:CreateNotification('ElevateV4', 'gui error: '..tostring(err), 15, 'warning')
					end
				end
			end
			function sub:Toggle()
				self:SetEnabled(not self.Enabled)
			end
			function sub:SetExpanded(value)
				body.Visible = value and true or false
				arrow.Rotation = value and 270 or 90
			end

			header.MouseButton1Click:Connect(function() sub:Toggle() end)
			arrowbutton.MouseButton1Click:Connect(function() sub:SetExpanded(not body.Visible) end)

			for name, component in components do
				sub['Create'..name] = function(_, settings)
					settings = settings or {}
					if settings.Darker == nil then settings.Darker = true end
					local option = mainapi:AttachContextualOption(component(settings, body, sub), settings)
					table.insert(sub.Members, option)
					return option
				end
			end
			if def.Default then sub:SetEnabled(true, true) end
			table.insert(subsapi.Modules, sub)
			return sub
		end

		function subsapi:Start()
			for _, sub in self.Modules do
				if sub.Enabled then pcall(sub.Function, true) end
			end
		end
		function subsapi:Stop()
			for _, sub in self.Modules do
				if sub.Enabled then pcall(sub.Function, false) end
			end
		end

		local serializer = {
			Type = 'SubModules',
			Save = function(_, tab)
				local data = {}
				for _, sub in subsapi.Modules do
					local opts = {}
					for _, option in sub.Options do
						if option.Save then pcall(option.Save, option, opts) end
					end
					data[sub.Name] = {Enabled = sub.Enabled, Options = opts}
				end
				tab[names] = data
			end,
			Load = function(_, tab)
				local data = type(tab) == 'table' and tab[names] or nil
				if type(data) ~= 'table' then return end
				for _, sub in subsapi.Modules do
					local entry = data[sub.Name]
					if type(entry) == 'table' then
						if type(entry.Enabled) == 'boolean' then sub:SetEnabled(entry.Enabled, true) end
						if type(entry.Options) == 'table' then
							for name, value in entry.Options do
								local option = sub.Options[name]
								if option and option.Load then pcall(option.Load, option, value) end
							end
						end
					end
				end
				if api.Enabled then subsapi:Start() end
			end,
			Color = function(_, hue, sat, val, rainbow)
				for _, sub in subsapi.Modules do
					for _, option in sub.Options do
						if option.Color then pcall(option.Color, option, hue, sat, val, rainbow) end
					end
				end
			end
		}
		api.Options[names] = serializer
		return subsapi
	end,
	Font = function(optionsettings, children, api)
		local fonts = {
			optionsettings.Blacklist,
			'Custom'
		}
		for _, v in Enum.Font:GetEnumItems() do
			if not table.find(fonts, v.Name) then
				table.insert(fonts, v.Name)
			end
		end

		local optionapi = {Value = Font.fromEnum(Enum.Font[fonts[1]])}
		local fontdropdown
		local fontbox
		optionsettings.Function = optionsettings.Function or function() end

		fontdropdown = components.Dropdown({
			Name = optionsettings.Name,
			List = fonts,
			Function = function(val)
				fontbox.Object.Visible = val == 'Custom' and fontdropdown.Object.Visible
				if val ~= 'Custom' then
					optionapi.Value = Font.fromEnum(Enum.Font[val])
					optionsettings.Function(optionapi.Value)
				else
					pcall(function()
						optionapi.Value = Font.fromId(tonumber(fontbox.Value))
					end)
					optionsettings.Function(optionapi.Value)
				end
			end,
			Darker = optionsettings.Darker,
			Visible = optionsettings.Visible
		}, children, api)
		optionapi.Object = fontdropdown.Object
		fontbox = components.TextBox({
			Name = optionsettings.Name..' Asset',
			Placeholder = 'font (rbxasset)',
			Function = function()
				if fontdropdown.Value == 'Custom' then
					pcall(function()
						optionapi.Value = Font.fromId(tonumber(fontbox.Value))
					end)
					optionsettings.Function(optionapi.Value)
				end
			end,
			Visible = false,
			Darker = true
		}, children, api)

		fontdropdown.Object:GetPropertyChangedSignal('Visible'):Connect(function()
			fontbox.Object.Visible = fontdropdown.Object.Visible and fontdropdown.Value == 'Custom'
		end)

		return optionapi
	end,
	Slider = function(optionsettings, children, api)
		local optionapi = {
			Type = 'Slider',
			Value = optionsettings.Default or optionsettings.Min,
			Min = optionsettings.Min,
			Max = optionsettings.Max,
			Index = getTableSize(api.Options)
		}

		local slider = Instance.new('TextButton')
		slider.Name = optionsettings.Name..'Slider'
		slider.Size = UDim2.new(1, 0, 0, 50)
		slider.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		slider.BorderSizePixel = 0
		slider.AutoButtonColor = false
		slider.Visible = optionsettings.Visible == nil or type(optionsettings.Visible) == 'function' or optionsettings.Visible
		slider.Text = ''
		slider.Parent = children
		addTooltip(slider, optionsettings.Tooltip)
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.fromOffset(60, 30)
		title.Position = UDim2.fromOffset(10, 2)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = color.Dark(uipallet.Text, 0.16)
		title.TextSize = 11
		title.FontFace = uipallet.Font
		title.Parent = slider
		local valuebutton = Instance.new('TextButton')
		valuebutton.Name = 'Value'
		valuebutton.Size = UDim2.fromOffset(60, 15)
		valuebutton.Position = UDim2.new(1, -69, 0, 9)
		valuebutton.BackgroundTransparency = 1
		valuebutton.Text = optionsettings.Format and optionsettings.Format(optionapi.Value) or optionapi.Value..(optionsettings.Suffix and ' '..(type(optionsettings.Suffix) == 'function' and optionsettings.Suffix(optionapi.Value) or optionsettings.Suffix) or '')
		valuebutton.TextXAlignment = Enum.TextXAlignment.Right
		valuebutton.TextColor3 = color.Dark(uipallet.Text, 0.16)
		valuebutton.TextSize = 11
		valuebutton.FontFace = uipallet.Font
		valuebutton.Parent = slider
		local valuebox = Instance.new('TextBox')
		valuebox.Name = 'Box'
		valuebox.Size = valuebutton.Size
		valuebox.Position = valuebutton.Position
		valuebox.BackgroundTransparency = 1
		valuebox.Visible = false
		valuebox.Text = optionapi.Value
		valuebox.TextXAlignment = Enum.TextXAlignment.Right
		valuebox.TextColor3 = color.Dark(uipallet.Text, 0.16)
		valuebox.TextSize = 11
		valuebox.FontFace = uipallet.Font
		valuebox.ClearTextOnFocus = false
		valuebox.Parent = slider
		local bkg = Instance.new('Frame')
		bkg.Name = 'Slider'
		bkg.Size = UDim2.new(1, -20, 0, 2)
		bkg.Position = UDim2.fromOffset(10, 37)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		bkg.BorderSizePixel = 0
		bkg.Parent = slider
		local fill = bkg:Clone()
		fill.Name = 'Fill'
		fill.Size = UDim2.fromScale(math.clamp((optionapi.Value - optionsettings.Min) / optionsettings.Max, 0.04, 0.96), 1)
		fill.Position = UDim2.new()
		fill.BackgroundColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		fill.Parent = bkg
		local knobholder = Instance.new('Frame')
		knobholder.Name = 'Knob'
		knobholder.Size = UDim2.fromOffset(24, 4)
		knobholder.Position = UDim2.fromScale(1, 0.5)
		knobholder.AnchorPoint = Vector2.new(0.5, 0.5)
		knobholder.BackgroundColor3 = slider.BackgroundColor3
		knobholder.BorderSizePixel = 0
		knobholder.Parent = fill
		local knob = Instance.new('Frame')
		knob.Name = 'Knob'
		knob.Size = UDim2.fromOffset(14, 14)
		knob.Position = UDim2.fromScale(0.5, 0.5)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.BackgroundColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		knob.Parent = knobholder
		addCorner(knob, UDim.new(1, 0))
		optionsettings.Function = optionsettings.Function or function() end
		optionsettings.Decimal = optionsettings.Decimal or 1

		function optionapi:Save(tab)
			tab[optionsettings.Name] = {
				Value = self.Value,
				Max = self.Max
			}
		end

		function optionapi:Load(tab)
			local newval = tab.Value == tab.Max and tab.Max ~= self.Max and self.Max or tab.Value
			if self.Value ~= newval then
				self:SetValue(newval, nil, true)
			end
		end

		function optionapi:Color(hue, sat, val, rainbowcheck)
			fill.BackgroundColor3 = rainbowcheck and Color3.fromHSV(mainapi:Color((hue - (self.Index * 0.075)) % 1)) or Color3.fromHSV(hue, sat, val)
			knob.BackgroundColor3 = fill.BackgroundColor3
		end

		function optionapi:SetValue(value, pos, final)
			if tonumber(value) == math.huge or value ~= value then return end
			local check = self.Value ~= value
			self.Value = value
			tween:Tween(fill, uipallet.Tween, {
				Size = UDim2.fromScale(math.clamp(pos or math.clamp(value / optionsettings.Max, 0, 1), 0.04, 0.96), 1)
			})
			valuebutton.Text = optionsettings.Format and optionsettings.Format(self.Value) or self.Value..(optionsettings.Suffix and ' '..(type(optionsettings.Suffix) == 'function' and optionsettings.Suffix(self.Value) or optionsettings.Suffix) or '')
			if check or final then
				optionsettings.Function(value, final)
			end
		end

		slider.InputBegan:Connect(function(inputObj)
			if
				(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
				and (inputObj.Position.Y - slider.AbsolutePosition.Y) > (20 * scale.Scale)
			then
				local newPosition = math.clamp((inputObj.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1)
				optionapi:SetValue(math.floor((optionsettings.Min + (optionsettings.Max - optionsettings.Min) * newPosition) * optionsettings.Decimal) / optionsettings.Decimal, newPosition)
				local lastValue = optionapi.Value
				local lastPosition = newPosition

				local changed = inputService.InputChanged:Connect(function(input)
					if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
						local newPosition = math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1)
						optionapi:SetValue(math.floor((optionsettings.Min + (optionsettings.Max - optionsettings.Min) * newPosition) * optionsettings.Decimal) / optionsettings.Decimal, newPosition)
						lastValue = optionapi.Value
						lastPosition = newPosition
					end
				end)

				local ended
				ended = inputObj.Changed:Connect(function()
					if inputObj.UserInputState == Enum.UserInputState.End then
						if changed then
							changed:Disconnect()
						end
						if ended then
							ended:Disconnect()
						end
						optionapi:SetValue(lastValue, lastPosition, true)
					end
				end)

			end
		end)
		slider.MouseEnter:Connect(function()
			tween:Tween(knob, uipallet.Tween, {
				Size = UDim2.fromOffset(16, 16)
			})
		end)
		slider.MouseLeave:Connect(function()
			tween:Tween(knob, uipallet.Tween, {
				Size = UDim2.fromOffset(14, 14)
			})
		end)
		valuebutton.MouseButton1Click:Connect(function()
			valuebutton.Visible = false
			valuebox.Visible = true
			valuebox.Text = optionapi.Value
			valuebox:CaptureFocus()
		end)
		valuebox.FocusLost:Connect(function(enter)
			valuebutton.Visible = true
			valuebox.Visible = false
			if enter and tonumber(valuebox.Text) then
				optionapi:SetValue(tonumber(valuebox.Text), nil, true)
			end
		end)

		optionapi.Object = slider
		api.Options[optionsettings.Name] = optionapi

		return optionapi
	end,
	Targets = function(optionsettings, children, api)
		local optionapi = {
			Type = 'Targets',
			Index = getTableSize(api.Options)
		}

		local textlist = Instance.new('TextButton')
		textlist.Name = 'Targets'
		textlist.Size = UDim2.new(1, 0, 0, 50)
		textlist.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		textlist.BorderSizePixel = 0
		textlist.AutoButtonColor = false
		textlist.Visible = optionsettings.Visible == nil or type(optionsettings.Visible) == 'function' or optionsettings.Visible
		textlist.Text = ''
		textlist.Parent = children
		addTooltip(textlist, optionsettings.Tooltip)
		local bkg = Instance.new('Frame')
		bkg.Name = 'BKG'
		bkg.Size = UDim2.new(1, -20, 1, -9)
		bkg.Position = UDim2.fromOffset(10, 4)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		bkg.Parent = textlist
		addCorner(bkg, UDim.new(0, 4))
		local button = Instance.new('TextButton')
		button.Name = 'TextList'
		button.Size = UDim2.new(1, -2, 1, -2)
		button.Position = UDim2.fromOffset(1, 1)
		button.BackgroundColor3 = uipallet.Main
		button.AutoButtonColor = false
		button.Text = ''
		button.Parent = bkg
		local buttontitle = Instance.new('TextLabel')
		buttontitle.Name = 'Title'
		buttontitle.Size = UDim2.new(1, -5, 0, 15)
		buttontitle.Position = UDim2.fromOffset(5, 6)
		buttontitle.BackgroundTransparency = 1
		buttontitle.Text = 'Target:'
		buttontitle.TextXAlignment = Enum.TextXAlignment.Left
		buttontitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
		buttontitle.TextSize = 15
		buttontitle.TextTruncate = Enum.TextTruncate.AtEnd
		buttontitle.FontFace = uipallet.Font
		buttontitle.Parent = button
		local items = buttontitle:Clone()
		items.Name = 'Items'
		items.Position = UDim2.fromOffset(5, 21)
		items.Text = 'Ignore none'
		items.TextColor3 = color.Dark(uipallet.Text, 0.16)
		items.TextSize = 11
		items.Parent = button
		addCorner(button, UDim.new(0, 4))
		local tool = Instance.new('Frame')
		tool.Size = UDim2.fromOffset(65, 12)
		tool.Position = UDim2.fromOffset(52, 8)
		tool.BackgroundTransparency = 1
		tool.Parent = button
		local toollist = Instance.new('UIListLayout')
		toollist.FillDirection = Enum.FillDirection.Horizontal
		toollist.Padding = UDim.new(0, 6)
		toollist.Parent = tool
		local window = Instance.new('TextButton')
		window.Name = 'TargetsTextWindow'
		window.Size = UDim2.fromOffset(220, 145)
		window.BackgroundColor3 = uipallet.Main
		window.BorderSizePixel = 0
		window.AutoButtonColor = false
		window.Visible = false
		window.Text = ''
		window.Parent = api.Panel or clickgui
		optionapi.Window = window
		addBlur(window)
		addCorner(window)
		local icon = Instance.new('ImageLabel')
		icon.Name = 'Icon'
		icon.Size = UDim2.fromOffset(18, 12)
		icon.Position = UDim2.fromOffset(10, 15)
		icon.BackgroundTransparency = 1
		icon.Image = getcustomasset('ElevateV4/assets/new/targetstab.png')
		icon.Parent = window
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -36, 0, 20)
		title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 11)
		title.BackgroundTransparency = 1
		title.Text = 'Target settings'
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 13
		title.FontFace = uipallet.Font
		title.Parent = window
		local close = addCloseButton(window)
		optionsettings.Function = optionsettings.Function or function() end

		function optionapi:Save(tab)
			tab.Targets = {
				Players = self.Players.Enabled,
				NPCs = self.NPCs.Enabled,
				Invisible = self.Invisible.Enabled,
				Walls = self.Walls.Enabled,
				Priority = self.Priority.Value
			}
		end

		function optionapi:Load(tab)
			if self.Players.Enabled ~= tab.Players then
				self.Players:Toggle()
			end
			if self.NPCs.Enabled ~= tab.NPCs then
				self.NPCs:Toggle()
			end
			if self.Invisible.Enabled ~= tab.Invisible then
				self.Invisible:Toggle()
			end
			if self.Walls.Enabled ~= tab.Walls then
				self.Walls:Toggle()
			end
			if tab.Priority and self.Priority.Value ~= tab.Priority then
				self.Priority:SetValue(tab.Priority)
			end
		end

		function optionapi:Color(hue, sat, val, rainbowcheck)
			bkg.BackgroundColor3 = rainbowcheck and Color3.fromHSV(mainapi:Color((hue - (self.Index * 0.075)) % 1)) or Color3.fromHSV(hue, sat, val)
			if self.Players.Enabled then
				tween:Cancel(self.Players.Object.Frame)
				self.Players.Object.Frame.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			end
			if self.NPCs.Enabled then
				tween:Cancel(self.NPCs.Object.Frame)
				self.NPCs.Object.Frame.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			end
			if self.Invisible.Enabled then
				tween:Cancel(self.Invisible.Object.Knob)
				self.Invisible.Object.Knob.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			end
			if self.Walls.Enabled then
				tween:Cancel(self.Walls.Object.Knob)
				self.Walls.Object.Knob.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			end
		end

		optionapi.Players = components.TargetsButton({
			Position = UDim2.fromOffset(11, 45),
			Icon = getcustomasset('ElevateV4/assets/new/targetplayers1.png'),
			IconSize = UDim2.fromOffset(15, 16),
			IconParent = tool,
			ToolIcon = getcustomasset('ElevateV4/assets/new/targetplayers2.png'),
			ToolSize = UDim2.fromOffset(11, 12),
			Tooltip = 'Players',
			Function = optionsettings.Function
		}, window, tool)
		optionapi.NPCs = components.TargetsButton({
			Position = UDim2.fromOffset(112, 45),
			Icon = getcustomasset('ElevateV4/assets/new/targetnpc1.png'),
			IconSize = UDim2.fromOffset(12, 16),
			IconParent = tool,
			ToolIcon = getcustomasset('ElevateV4/assets/new/targetnpc2.png'),
			ToolSize = UDim2.fromOffset(9, 12),
			Tooltip = 'NPCs',
			Function = optionsettings.Function
		}, window, tool)
		optionapi.Invisible = components.Toggle({
			Name = 'Ignore invisible',
			Function = function()
				local text = 'none'
				if optionapi.Invisible.Enabled then
					text = 'invisible'
				end
				if optionapi.Walls.Enabled then
					text = text == 'none' and 'behind walls' or text..', behind walls'
				end
				items.Text = 'Ignore '..text
				optionsettings.Function()
			end
		}, window, {Options = {}})
		optionapi.Invisible.Object.Position = UDim2.fromOffset(0, 81)
		optionapi.Walls = components.Toggle({
			Name = 'Ignore behind walls',
			Function = function()
				local text = 'none'
				if optionapi.Invisible.Enabled then
					text = 'invisible'
				end
				if optionapi.Walls.Enabled then
					text = text == 'none' and 'behind walls' or text..', behind walls'
				end
				items.Text = 'Ignore '..text
				optionsettings.Function()
			end
		}, window, {Options = {}})
		optionapi.Walls.Object.Position = UDim2.fromOffset(0, 111)
		optionapi.Priority = components.Dropdown({
			Name = 'Priority',
			List = {'Players', 'NPCs', 'None', 'Closest', 'Farthest', 'Lowest health', 'Highest health', 'Crosshair'},
			Default = 'Players',
			Function = optionsettings.Function,
			Tooltip = 'Which target gets picked first when more than one is in range\nPlayers / NPCs - that kind wins, the modules own sorting breaks the tie\nClosest / Farthest - by range\nLowest / Highest health - finish someone off, or go for the healthy one\nCrosshair - whoever is nearest the middle of your screen'
		}, window, {Options = {}})
		optionapi.Priority.Object.Position = UDim2.fromOffset(0, 141)
		window.Size = UDim2.fromOffset(220, 145 + optionapi.Priority.Object.Size.Y.Offset)
		optionapi.Priority.Object:GetPropertyChangedSignal('Size'):Connect(function()
			window.Size = UDim2.fromOffset(220, 145 + optionapi.Priority.Object.Size.Y.Offset)
		end)
		if optionsettings.Players then
			optionapi.Players:Toggle()
		end
		if optionsettings.NPCs then
			optionapi.NPCs:Toggle()
		end
		if optionsettings.Invisible then
			optionapi.Invisible:Toggle()
		end
		if optionsettings.Walls then
			optionapi.Walls:Toggle()
		end

		close.MouseButton1Click:Connect(function()
			window.Visible = false
		end)
		button.MouseButton1Click:Connect(function()
			window.Visible = not window.Visible
			tween:Cancel(bkg)
			bkg.BackgroundColor3 = window.Visible and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or color.Light(uipallet.Main, 0.37)
		end)
		textlist.MouseEnter:Connect(function()
			if not optionapi.Window.Visible then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.37)
				})
			end
		end)
		textlist.MouseLeave:Connect(function()
			if not optionapi.Window.Visible then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.034)
				})
			end
		end)
		textlist:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			local origin = api.Panel and api.Panel.AbsolutePosition or Vector2.zero
			local actualPosition = ((textlist.AbsolutePosition - origin) + Vector2.new(0, 60)) / scale.Scale
			window.Position = UDim2.fromOffset(actualPosition.X + 220, actualPosition.Y)
		end)

		optionapi.Object = textlist
		api.Options.Targets = optionapi

		return optionapi
	end,
	TargetsButton = function(optionsettings, children, api)
		local optionapi = {Enabled = false}

		local targetbutton = Instance.new('TextButton')
		targetbutton.Size = UDim2.fromOffset(98, 31)
		targetbutton.Position = optionsettings.Position
		targetbutton.BackgroundColor3 = color.Light(uipallet.Main, 0.05)
		targetbutton.AutoButtonColor = false
		targetbutton.Visible = optionsettings.Visible == nil or type(optionsettings.Visible) == 'function' or optionsettings.Visible
		targetbutton.Text = ''
		targetbutton.Parent = children
		addCorner(targetbutton)
		addTooltip(targetbutton, optionsettings.Tooltip)
		local bkg = Instance.new('Frame')
		bkg.Size = UDim2.new(1, -2, 1, -2)
		bkg.Position = UDim2.fromOffset(1, 1)
		bkg.BackgroundColor3 = uipallet.Main
		bkg.Parent = targetbutton
		addCorner(bkg)
		local icon = Instance.new('ImageLabel')
		icon.Size = optionsettings.IconSize
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.Image = optionsettings.Icon
		icon.ImageColor3 = color.Light(uipallet.Main, 0.37)
		icon.Parent = bkg
		optionsettings.Function = optionsettings.Function or function() end
		local tooltipicon

		function optionapi:Toggle()
			self.Enabled = not self.Enabled
			tween:Tween(bkg, uipallet.Tween, {
				BackgroundColor3 = self.Enabled and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or uipallet.Main
			})
			tween:Tween(icon, uipallet.Tween, {
				ImageColor3 = self.Enabled and Color3.new(1, 1, 1) or color.Light(uipallet.Main, 0.37)
			})
			if tooltipicon then
				tooltipicon:Destroy()
			end
			if self.Enabled then
				tooltipicon = Instance.new('ImageLabel')
				tooltipicon.Size = optionsettings.ToolSize
				tooltipicon.BackgroundTransparency = 1
				tooltipicon.Image = optionsettings.ToolIcon
				tooltipicon.ImageColor3 = uipallet.Text
				tooltipicon.Parent = optionsettings.IconParent
			end
			optionsettings.Function(self.Enabled)
		end

		targetbutton.MouseEnter:Connect(function()
			if not optionapi.Enabled then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value - 0.25)
				})
				tween:Tween(icon, uipallet.Tween, {
					ImageColor3 = Color3.new(1, 1, 1)
				})
			end
		end)
		targetbutton.MouseLeave:Connect(function()
			if not optionapi.Enabled then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = uipallet.Main
				})
				tween:Tween(icon, uipallet.Tween, {
					ImageColor3 = color.Light(uipallet.Main, 0.37)
				})
			end
		end)
		targetbutton.MouseButton1Click:Connect(function()
			optionapi:Toggle()
		end)

		optionapi.Object = targetbutton

		return optionapi
	end,
	TextBox = function(optionsettings, children, api)
		local optionapi = {
			Type = 'TextBox',
			Value = optionsettings.Default or '',
			Index = 0
		}

		local textbox = Instance.new('TextButton')
		textbox.Name = optionsettings.Name..'TextBox'
		textbox.Size = UDim2.new(1, 0, 0, 58)
		textbox.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		textbox.BorderSizePixel = 0
		textbox.AutoButtonColor = false
		textbox.Visible = optionsettings.Visible == nil or type(optionsettings.Visible) == 'function' or optionsettings.Visible
		textbox.Text = ''
		textbox.Parent = children
		addTooltip(textbox, optionsettings.Tooltip)
		local title = Instance.new('TextLabel')
		title.Size = UDim2.new(1, -10, 0, 20)
		title.Position = UDim2.fromOffset(10, 3)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 12
		title.FontFace = uipallet.Font
		title.Parent = textbox
		local bkg = Instance.new('Frame')
		bkg.Name = 'BKG'
		bkg.Size = UDim2.new(1, -20, 0, 29)
		bkg.Position = UDim2.fromOffset(10, 23)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		bkg.Parent = textbox
		addCorner(bkg, UDim.new(0, 4))
		local box = Instance.new('TextBox')
		box.Size = UDim2.new(1, -8, 1, 0)
		box.Position = UDim2.fromOffset(8, 0)
		box.BackgroundTransparency = 1
		box.Text = optionsettings.Default or ''
		box.PlaceholderText = optionsettings.Placeholder or 'Click to set'
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.TextColor3 = color.Dark(uipallet.Text, 0.16)
		box.PlaceholderColor3 = color.Dark(uipallet.Text, 0.31)
		box.TextSize = 12
		box.FontFace = uipallet.Font
		box.ClearTextOnFocus = false
		box.Parent = bkg
		optionsettings.Function = optionsettings.Function or function() end

		function optionapi:Save(tab)
			tab[optionsettings.Name] = {Value = self.Value}
		end

		function optionapi:Load(tab)
			if self.Value ~= tab.Value then
				self:SetValue(tab.Value)
			end
		end

		function optionapi:SetValue(val, enter)
			self.Value = val
			box.Text = val
			optionsettings.Function(enter)
		end

		textbox.MouseButton1Click:Connect(function()
			box:CaptureFocus()
		end)
		box.FocusLost:Connect(function(enter)
			optionapi:SetValue(box.Text, enter)
		end)
		box:GetPropertyChangedSignal('Text'):Connect(function()
			optionapi:SetValue(box.Text)
		end)

		optionapi.Object = textbox
		api.Options[optionsettings.Name] = optionapi

		return optionapi
	end,
	TextList = function(optionsettings, children, api)
		local optionapi = {
			Type = 'TextList',
			List = optionsettings.Default or {},
			ListEnabled = optionsettings.Default or {},
			Objects = {},
			Window = {Visible = false},
			Index = getTableSize(api.Options)
		}
		optionsettings.Color = optionsettings.Color or Color3.fromRGB(190, 115, 255)

		local textlist = Instance.new('TextButton')
		textlist.Name = optionsettings.Name..'TextList'
		textlist.Size = UDim2.new(1, 0, 0, 50)
		textlist.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		textlist.BorderSizePixel = 0
		textlist.AutoButtonColor = false
		textlist.Visible = optionsettings.Visible == nil or type(optionsettings.Visible) == 'function' or optionsettings.Visible
		textlist.Text = ''
		textlist.Parent = children
		addTooltip(textlist, optionsettings.Tooltip)
		local bkg = Instance.new('Frame')
		bkg.Name = 'BKG'
		bkg.Size = UDim2.new(1, -20, 1, -9)
		bkg.Position = UDim2.fromOffset(10, 4)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		bkg.Parent = textlist
		addCorner(bkg, UDim.new(0, 4))
		local button = Instance.new('TextButton')
		button.Name = 'TextList'
		button.Size = UDim2.new(1, -2, 1, -2)
		button.Position = UDim2.fromOffset(1, 1)
		button.BackgroundColor3 = uipallet.Main
		button.AutoButtonColor = false
		button.Text = ''
		button.Parent = bkg
		local buttonicon = Instance.new('ImageLabel')
		buttonicon.Name = 'Icon'
		buttonicon.Size = UDim2.fromOffset(14, 12)
		buttonicon.Position = UDim2.fromOffset(10, 14)
		buttonicon.BackgroundTransparency = 1
		buttonicon.Image = optionsettings.Icon or getcustomasset('ElevateV4/assets/new/allowedicon.png')
		buttonicon.Parent = button
		local buttontitle = Instance.new('TextLabel')
		buttontitle.Name = 'Title'
		buttontitle.Size = UDim2.new(1, -35, 0, 15)
		buttontitle.Position = UDim2.fromOffset(35, 6)
		buttontitle.BackgroundTransparency = 1
		buttontitle.Text = optionsettings.Name
		buttontitle.TextXAlignment = Enum.TextXAlignment.Left
		buttontitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
		buttontitle.TextSize = 15
		buttontitle.TextTruncate = Enum.TextTruncate.AtEnd
		buttontitle.FontFace = uipallet.Font
		buttontitle.Parent = button
		local amount = buttontitle:Clone()
		amount.Name = 'Amount'
		amount.Size = UDim2.new(1, -13, 0, 15)
		amount.Position = UDim2.fromOffset(0, 6)
		amount.Text = '0'
		amount.TextXAlignment = Enum.TextXAlignment.Right
		amount.Parent = button
		local items = buttontitle:Clone()
		items.Name = 'Items'
		items.Position = UDim2.fromOffset(35, 21)
		items.Text = 'None'
		items.TextColor3 = color.Dark(uipallet.Text, 0.43)
		items.TextSize = 11
		items.Parent = button
		addCorner(button, UDim.new(0, 4))
		local window = Instance.new('TextButton')
		window.Name = optionsettings.Name..'TextWindow'
		window.Size = UDim2.fromOffset(220, 85)
		window.BackgroundColor3 = uipallet.Main
		window.BorderSizePixel = 0
		window.AutoButtonColor = false
		window.Visible = false
		window.Text = ''
		window.Parent = api.Panel or clickgui
		optionapi.Window = window
		addBlur(window)
		addCorner(window)
		local icon = Instance.new('ImageLabel')
		icon.Name = 'Icon'
		icon.Size = optionsettings.TabSize or UDim2.fromOffset(19, 16)
		icon.Position = UDim2.fromOffset(10, 13)
		icon.BackgroundTransparency = 1
		icon.Image = optionsettings.Tab or getcustomasset('ElevateV4/assets/new/allowedtab.png')
		icon.Parent = window
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -36, 0, 20)
		title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 11)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 13
		title.FontFace = uipallet.Font
		title.Parent = window
		local close = addCloseButton(window)
		local addbkg = Instance.new('Frame')
		addbkg.Name = 'Add'
		addbkg.Size = UDim2.fromOffset(200, 31)
		addbkg.Position = UDim2.fromOffset(10, 45)
		addbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		addbkg.Parent = window
		addCorner(addbkg)
		local addbox = addbkg:Clone()
		addbox.Size = UDim2.new(1, -2, 1, -2)
		addbox.Position = UDim2.fromOffset(1, 1)
		addbox.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
		addbox.Parent = addbkg
		local addvalue = Instance.new('TextBox')
		addvalue.Size = UDim2.new(1, -35, 1, 0)
		addvalue.Position = UDim2.fromOffset(10, 0)
		addvalue.BackgroundTransparency = 1
		addvalue.Text = ''
		addvalue.PlaceholderText = optionsettings.Placeholder or 'Add entry...'
		addvalue.TextXAlignment = Enum.TextXAlignment.Left
		addvalue.TextColor3 = Color3.new(1, 1, 1)
		addvalue.TextSize = 15
		addvalue.FontFace = uipallet.Font
		addvalue.ClearTextOnFocus = false
		addvalue.Parent = addbkg
		local addbutton = Instance.new('ImageButton')
		addbutton.Name = 'AddButton'
		addbutton.Size = UDim2.fromOffset(16, 16)
		addbutton.Position = UDim2.new(1, -26, 0, 8)
		addbutton.BackgroundTransparency = 1
		addbutton.Image = getcustomasset('ElevateV4/assets/new/add.png')
		addbutton.ImageColor3 = optionsettings.Color
		addbutton.ImageTransparency = 0.3
		addbutton.Parent = addbkg
		optionsettings.Function = optionsettings.Function or function() end

		function optionapi:Save(tab)
			tab[optionsettings.Name] = {
				List = self.List,
				ListEnabled = self.ListEnabled
			}
		end

		function optionapi:Load(tab)
			self.List = tab.List or {}
			self.ListEnabled = tab.ListEnabled or {}
			self:ChangeValue()
		end

		function optionapi:Color(hue, sat, val, rainbowcheck)
			if window.Visible then
				bkg.BackgroundColor3 = rainbowcheck and Color3.fromHSV(mainapi:Color((hue - (self.Index * 0.075)) % 1)) or Color3.fromHSV(hue, sat, val)
			end
		end

		function optionapi:ChangeValue(val)
			if val then
				local ind = table.find(self.List, val)
				if ind then
					table.remove(self.List, ind)
					ind = table.find(self.ListEnabled, val)
					if ind then
						table.remove(self.ListEnabled, ind)
					end
				else
					table.insert(self.List, val)
					table.insert(self.ListEnabled, val)
				end
			end

			optionsettings.Function(self.List)
			for _, v in self.Objects do
				v:Destroy()
			end
			table.clear(self.Objects)
			window.Size = UDim2.fromOffset(220, 85 + (#self.List * 35))
			amount.Text = #self.List

			local enabledtext = 'None'
			for i, v in self.ListEnabled do
				if i == 1 then enabledtext = '' end
				enabledtext = enabledtext..(i == 1 and v or ', '..v)
			end
			items.Text = enabledtext

			for i, v in self.List do
				local enabled = table.find(self.ListEnabled, v)
				local object = Instance.new('TextButton')
				object.Name = v
				object.Size = UDim2.fromOffset(200, 32)
				object.Position = UDim2.fromOffset(10, 47 + (i * 35))
				object.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
				object.AutoButtonColor = false
				object.Text = ''
				object.Parent = window
				addCorner(object)
				local objectbkg = Instance.new('Frame')
				objectbkg.Name = 'BKG'
				objectbkg.Size = UDim2.new(1, -2, 1, -2)
				objectbkg.Position = UDim2.fromOffset(1, 1)
				objectbkg.BackgroundColor3 = uipallet.Main
				objectbkg.Visible = false
				objectbkg.Parent = object
				addCorner(objectbkg)
				local objectdot = Instance.new('Frame')
				objectdot.Name = 'Dot'
				objectdot.Size = UDim2.fromOffset(10, 11)
				objectdot.Position = UDim2.fromOffset(10, 12)
				objectdot.BackgroundColor3 = enabled and optionsettings.Color or color.Light(uipallet.Main, 0.37)
				objectdot.Parent = object
				addCorner(objectdot, UDim.new(1, 0))
				local objectdotin = objectdot:Clone()
				objectdotin.Size = UDim2.fromOffset(8, 9)
				objectdotin.Position = UDim2.fromOffset(1, 1)
				objectdotin.BackgroundColor3 = enabled and optionsettings.Color or color.Light(uipallet.Main, 0.02)
				objectdotin.Parent = objectdot
				local objecttitle = Instance.new('TextLabel')
				objecttitle.Name = 'Title'
				objecttitle.Size = UDim2.new(1, -30, 1, 0)
				objecttitle.Position = UDim2.fromOffset(30, 0)
				objecttitle.BackgroundTransparency = 1
				objecttitle.Text = v
				objecttitle.TextXAlignment = Enum.TextXAlignment.Left
				objecttitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
				objecttitle.TextSize = 15
				objecttitle.FontFace = uipallet.Font
				objecttitle.Parent = object
				local close = Instance.new('ImageButton')
				close.Name = 'Close'
				close.Size = UDim2.fromOffset(16, 16)
				close.Position = UDim2.new(1, -26, 0, 8)
				close.BackgroundColor3 = Color3.new(1, 1, 1)
				close.BackgroundTransparency = 1
				close.AutoButtonColor = false
				close.Image = getcustomasset('ElevateV4/assets/new/closemini.png')
				close.ImageColor3 = color.Light(uipallet.Text, 0.2)
				close.ImageTransparency = 0.5
				close.Parent = object
				addCorner(close, UDim.new(1, 0))

				close.MouseEnter:Connect(function()
					close.ImageTransparency = 0.3
					tween:Tween(close, uipallet.Tween, {
						BackgroundTransparency = 0.6
					})
				end)
				close.MouseLeave:Connect(function()
					close.ImageTransparency = 0.5
					tween:Tween(close, uipallet.Tween, {
						BackgroundTransparency = 1
					})
				end)
				close.MouseButton1Click:Connect(function()
					self:ChangeValue(v)
				end)
				object.MouseEnter:Connect(function()
					objectbkg.Visible = true
				end)
				object.MouseLeave:Connect(function()
					objectbkg.Visible = false
				end)
				object.MouseButton1Click:Connect(function()
					local ind = table.find(self.ListEnabled, v)
					if ind then
						table.remove(self.ListEnabled, ind)
						objectdot.BackgroundColor3 = color.Light(uipallet.Main, 0.37)
						objectdotin.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
					else
						table.insert(self.ListEnabled, v)
						objectdot.BackgroundColor3 = optionsettings.Color
						objectdotin.BackgroundColor3 = optionsettings.Color
					end

					local enabledtext = 'None'
					for i, v in self.ListEnabled do
						if i == 1 then enabledtext = '' end
						enabledtext = enabledtext..(i == 1 and v or ', '..v)
					end

					items.Text = enabledtext
					optionsettings.Function()
				end)

				table.insert(self.Objects, object)
			end
		end

		addbutton.MouseEnter:Connect(function()
			addbutton.ImageTransparency = 0
		end)
		addbutton.MouseLeave:Connect(function()
			addbutton.ImageTransparency = 0.3
		end)
		addbutton.MouseButton1Click:Connect(function()
			if not table.find(optionapi.List, addvalue.Text) then
				optionapi:ChangeValue(addvalue.Text)
				addvalue.Text = ''
			end
		end)
		addvalue.FocusLost:Connect(function(enter)
			if enter and not table.find(optionapi.List, addvalue.Text) then
				optionapi:ChangeValue(addvalue.Text)
				addvalue.Text = ''
			end
		end)
		addvalue.MouseEnter:Connect(function()
			tween:Tween(addbkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.14)
			})
		end)
		addvalue.MouseLeave:Connect(function()
			tween:Tween(addbkg, uipallet.Tween, {
				BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			})
		end)
		close.MouseButton1Click:Connect(function()
			window.Visible = false
		end)
		button.MouseButton1Click:Connect(function()
			window.Visible = not window.Visible
			tween:Cancel(bkg)
			bkg.BackgroundColor3 = window.Visible and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or color.Light(uipallet.Main, 0.37)
		end)
		textlist.MouseEnter:Connect(function()
			if not optionapi.Window.Visible then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.37)
				})
			end
		end)
		textlist.MouseLeave:Connect(function()
			if not optionapi.Window.Visible then
				tween:Tween(bkg, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.034)
				})
			end
		end)
		textlist:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			local actualPosition = (textlist.AbsolutePosition - (api.Panel and api.Panel.AbsolutePosition or -guiService:GetGuiInset())) / scale.Scale
			window.Position = UDim2.fromOffset(actualPosition.X + 220, actualPosition.Y)
		end)

		if optionsettings.Default then
			optionapi:ChangeValue()
		end
		optionapi.Object = textlist
		api.Options[optionsettings.Name] = optionapi

		return optionapi
	end,
	Toggle = function(optionsettings, children, api)
		local optionapi = {
			Type = 'Toggle',
			Enabled = false,
			Index = getTableSize(api.Options)
		}

		local hovered = false
		local toggle = Instance.new('TextButton')
		toggle.Name = optionsettings.Name..'Toggle'
		toggle.Size = UDim2.new(1, 0, 0, 30)
		toggle.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		toggle.BorderSizePixel = 0
		toggle.AutoButtonColor = false
		toggle.Visible = optionsettings.Visible == nil or type(optionsettings.Visible) == 'function' or optionsettings.Visible
		toggle.Text = '          '..optionsettings.Name
		toggle.TextXAlignment = Enum.TextXAlignment.Left
		toggle.TextColor3 = color.Dark(uipallet.Text, 0.16)
		toggle.TextSize = 14
		toggle.FontFace = uipallet.Font
		toggle.Parent = children
		addTooltip(toggle, optionsettings.Tooltip)
		local knobholder = Instance.new('Frame')
		knobholder.Name = 'Knob'
		knobholder.Size = UDim2.fromOffset(22, 12)
		knobholder.Position = UDim2.new(1, -30, 0, 9)
		knobholder.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
		knobholder.Parent = toggle
		addCorner(knobholder, UDim.new(1, 0))
		local knob = knobholder:Clone()
		knob.Size = UDim2.fromOffset(8, 8)
		knob.Position = UDim2.fromOffset(2, 2)
		knob.BackgroundColor3 = uipallet.Main
		knob.Parent = knobholder
		optionsettings.Function = optionsettings.Function or function() end

		function optionapi:Save(tab)
			tab[optionsettings.Name] = {Enabled = self.Enabled}
		end

		function optionapi:Load(tab)
			if self.Enabled ~= tab.Enabled then
				self:Toggle()
			end
		end

		function optionapi:Color(hue, sat, val, rainbowcheck)
			if self.Enabled then
				tween:Cancel(knobholder)
				knobholder.BackgroundColor3 = rainbowcheck and Color3.fromHSV(mainapi:Color((hue - (self.Index * 0.075)) % 1)) or Color3.fromHSV(hue, sat, val)
			end
		end

		function optionapi:Toggle()
			self.Enabled = not self.Enabled
			local rainbowcheck = mainapi.GUIColor.Rainbow and mainapi.RainbowMode.Value ~= 'Retro'
			tween:Tween(knobholder, uipallet.Tween, {
				BackgroundColor3 = self.Enabled and (rainbowcheck and Color3.fromHSV(mainapi:Color((mainapi.GUIColor.Hue - (self.Index * 0.075)) % 1)) or Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)) or (hovered and color.Light(uipallet.Main, 0.37) or color.Light(uipallet.Main, 0.14))
			})
			tween:Tween(knob, uipallet.Tween, {
				Position = UDim2.fromOffset(self.Enabled and 12 or 2, 2)
			})
			xpcall(function()
				optionsettings.Function(self.Enabled)
			end, function(err)
				if shared.VapeDeveloper then
					mainapi:CreateNotification('ElevateV4', 'gui error: '.. err, 15, 'warning')
					task.defer(error, err)
				end
			end)
			task.defer(mainapi.RefreshContextualOptions, mainapi)
		end

		toggle.MouseEnter:Connect(function()
			hovered = true
			if not optionapi.Enabled then
				tween:Tween(knobholder, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.37)
				})
			end
		end)
		toggle.MouseLeave:Connect(function()
			hovered = false
			if not optionapi.Enabled then
				tween:Tween(knobholder, uipallet.Tween, {
					BackgroundColor3 = color.Light(uipallet.Main, 0.14)
				})
			end
		end)
		toggle.MouseButton1Click:Connect(function()
			optionapi:Toggle()
		end)

		if optionsettings.Default then
			optionapi:Toggle()
		end
		optionapi.Object = toggle
		api.Options[optionsettings.Name] = optionapi

		return optionapi
	end,
	TwoSlider = function(optionsettings, children, api)
		local optionapi = {
			Type = 'TwoSlider',
			ValueMin = optionsettings.DefaultMin or optionsettings.Min,
			ValueMax = optionsettings.DefaultMax or 10,
			Max = optionsettings.Max,
			Index = getTableSize(api.Options)
		}

		local slider = Instance.new('TextButton')
		slider.Name = optionsettings.Name..'Slider'
		slider.Size = UDim2.new(1, 0, 0, 50)
		slider.BackgroundColor3 = color.Dark(children.BackgroundColor3, optionsettings.Darker and 0.02 or 0)
		slider.BorderSizePixel = 0
		slider.AutoButtonColor = false
		slider.Visible = optionsettings.Visible == nil or type(optionsettings.Visible) == 'function' or optionsettings.Visible
		slider.Text = ''
		slider.Parent = children
		addTooltip(slider, optionsettings.Tooltip)
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.fromOffset(60, 30)
		title.Position = UDim2.fromOffset(10, 2)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = color.Dark(uipallet.Text, 0.16)
		title.TextSize = 11
		title.FontFace = uipallet.Font
		title.Parent = slider
		local valuebutton = Instance.new('TextButton')
		valuebutton.Name = 'Value'
		valuebutton.Size = UDim2.fromOffset(60, 15)
		valuebutton.Position = UDim2.new(1, -69, 0, 9)
		valuebutton.BackgroundTransparency = 1
		valuebutton.Text = optionapi.ValueMax
		valuebutton.TextXAlignment = Enum.TextXAlignment.Right
		valuebutton.TextColor3 = color.Dark(uipallet.Text, 0.16)
		valuebutton.TextSize = 11
		valuebutton.FontFace = uipallet.Font
		valuebutton.Parent = slider
		local valuebutton2 = valuebutton:Clone()
		valuebutton2.Position = UDim2.new(1, -125, 0, 9)
		valuebutton2.Text = optionapi.ValueMin
		valuebutton2.Parent = slider
		local valuebox = Instance.new('TextBox')
		valuebox.Name = 'Box'
		valuebox.Size = valuebutton.Size
		valuebox.Position = valuebutton.Position
		valuebox.BackgroundTransparency = 1
		valuebox.Visible = false
		valuebox.Text = optionapi.ValueMin
		valuebox.TextXAlignment = Enum.TextXAlignment.Right
		valuebox.TextColor3 = color.Dark(uipallet.Text, 0.16)
		valuebox.TextSize = 11
		valuebox.FontFace = uipallet.Font
		valuebox.ClearTextOnFocus = false
		valuebox.Parent = slider
		local valuebox2 = valuebox:Clone()
		valuebox2.Position = valuebutton2.Position
		valuebox2.Parent = slider
		local bkg = Instance.new('Frame')
		bkg.Name = 'Slider'
		bkg.Size = UDim2.new(1, -20, 0, 2)
		bkg.Position = UDim2.fromOffset(10, 37)
		bkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		bkg.BorderSizePixel = 0
		bkg.Parent = slider
		local fill = bkg:Clone()
		fill.Name = 'Fill'
		fill.Position = UDim2.fromScale(math.clamp(optionapi.ValueMin / optionsettings.Max, 0.04, 0.96), 0)
		fill.Size = UDim2.fromScale(math.clamp(math.clamp(optionapi.ValueMax / optionsettings.Max, 0, 1), 0.04, 0.96) - fill.Position.X.Scale, 1)
		fill.BackgroundColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		fill.Parent = bkg
		local knobholder = Instance.new('Frame')
		knobholder.Name = 'Knob'
		knobholder.Size = UDim2.fromOffset(16, 4)
		knobholder.Position = UDim2.fromScale(0, 0.5)
		knobholder.AnchorPoint = Vector2.new(0.5, 0.5)
		knobholder.BackgroundColor3 = slider.BackgroundColor3
		knobholder.BorderSizePixel = 0
		knobholder.Parent = fill
		local knob = Instance.new('ImageLabel')
		knob.Name = 'Knob'
		knob.Size = UDim2.fromOffset(9, 16)
		knob.Position = UDim2.fromScale(0.5, 0.5)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.BackgroundTransparency = 1
		knob.Image = getcustomasset('ElevateV4/assets/new/range.png')
		knob.ImageColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		knob.Parent = knobholder
		local knobholdermax = knobholder:Clone()
		knobholdermax.Name = 'KnobMax'
		knobholdermax.Position = UDim2.fromScale(1, 0.5)
		knobholdermax.Parent = fill
		knobholdermax.Knob.Rotation = 180
		local arrow = Instance.new('ImageLabel')
		arrow.Name = 'Arrow'
		arrow.Size = UDim2.fromOffset(12, 6)
		arrow.Position = UDim2.new(1, -56, 0, 10)
		arrow.BackgroundTransparency = 1
		arrow.Image = getcustomasset('ElevateV4/assets/new/rangearrow.png')
		arrow.ImageColor3 = color.Light(uipallet.Main, 0.14)
		arrow.Parent = slider
		optionsettings.Function = optionsettings.Function or function() end
		optionsettings.Decimal = optionsettings.Decimal or 1
		local random = Random.new()

		function optionapi:Save(tab)
			tab[optionsettings.Name] = {ValueMin = self.ValueMin, ValueMax = self.ValueMax}
		end

		function optionapi:Load(tab)
			if self.ValueMin ~= tab.ValueMin then
				self:SetValue(false, tab.ValueMin)
			end
			if self.ValueMax ~= tab.ValueMax then
				self:SetValue(true, tab.ValueMax)
			end
		end

		function optionapi:Color(hue, sat, val, rainbowcheck)
			fill.BackgroundColor3 = rainbowcheck and Color3.fromHSV(mainapi:Color((hue - (self.Index * 0.075)) % 1)) or Color3.fromHSV(hue, sat, val)
			knob.ImageColor3 = fill.BackgroundColor3
			knobholdermax.Knob.ImageColor3 = fill.BackgroundColor3
		end

		function optionapi:GetRandomValue()
			return random:NextNumber(optionapi.ValueMin, optionapi.ValueMax)
		end

		function optionapi:SetValue(max, value)
			value = tonumber(value)
			if value == nil or value ~= value or value == math.huge or value == -math.huge then return end
			self[max and 'ValueMax' or 'ValueMin'] = value
			valuebutton.Text = self.ValueMax
			valuebutton2.Text = self.ValueMin
			local size = math.clamp(math.clamp(self.ValueMin / optionsettings.Max, 0, 1), 0.04, 0.96)
			tween:Tween(fill, TweenInfo.new(0.1), {
				Position = UDim2.fromScale(size, 0),
				Size = UDim2.fromScale(math.clamp(math.clamp(math.clamp(self.ValueMax / optionsettings.Max, 0.04, 0.96), 0.04, 0.96) - size, 0, 1), 1)
			})
		end

		knobholder.MouseEnter:Connect(function()
			tween:Tween(knob, uipallet.Tween, {
				Size = UDim2.fromOffset(11, 18)
			})
		end)
		knobholder.MouseLeave:Connect(function()
			tween:Tween(knob, uipallet.Tween, {
				Size = UDim2.fromOffset(9, 16)
			})
		end)
		knobholdermax.MouseEnter:Connect(function()
			tween:Tween(knobholdermax.Knob, uipallet.Tween, {
				Size = UDim2.fromOffset(11, 18)
			})
		end)
		knobholdermax.MouseLeave:Connect(function()
			tween:Tween(knobholdermax.Knob, uipallet.Tween, {
				Size = UDim2.fromOffset(9, 16)
			})
		end)
		slider.InputBegan:Connect(function(inputObj)
			if
				(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
				and (inputObj.Position.Y - slider.AbsolutePosition.Y) > (20 * scale.Scale)
			then
				local maxCheck = (inputObj.Position.X - knobholdermax.AbsolutePosition.X) > -10
				local newPosition = math.clamp((inputObj.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1)
				optionapi:SetValue(maxCheck, math.floor((optionsettings.Min + (optionsettings.Max - optionsettings.Min) * newPosition) * optionsettings.Decimal) / optionsettings.Decimal, newPosition)

				local changed = inputService.InputChanged:Connect(function(input)
					if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
						local newPosition = math.clamp((input.Position.X - bkg.AbsolutePosition.X) / bkg.AbsoluteSize.X, 0, 1)
						optionapi:SetValue(maxCheck, math.floor((optionsettings.Min + (optionsettings.Max - optionsettings.Min) * newPosition) * optionsettings.Decimal) / optionsettings.Decimal, newPosition)
					end
				end)

				local ended
				ended = inputObj.Changed:Connect(function()
					if inputObj.UserInputState == Enum.UserInputState.End then
						if changed then
							changed:Disconnect()
						end
						if ended then
							ended:Disconnect()
						end
					end
				end)
			end
		end)
		valuebutton.MouseButton1Click:Connect(function()
			valuebutton.Visible = false
			valuebox.Visible = true
			valuebox.Text = optionapi.ValueMax
			valuebox:CaptureFocus()
		end)
		valuebutton2.MouseButton1Click:Connect(function()
			valuebutton2.Visible = false
			valuebox2.Visible = true
			valuebox2.Text = optionapi.ValueMin
			valuebox2:CaptureFocus()
		end)
		valuebox.FocusLost:Connect(function(enter)
			valuebutton.Visible = true
			valuebox.Visible = false
			if enter and tonumber(valuebox.Text) then
				optionapi:SetValue(true, tonumber(valuebox.Text))
			end
		end)
		valuebox2.FocusLost:Connect(function(enter)
			valuebutton2.Visible = true
			valuebox2.Visible = false
			if enter and tonumber(valuebox2.Text) then
				optionapi:SetValue(false, tonumber(valuebox2.Text))
			end
		end)

		optionapi.Object = slider
		api.Options[optionsettings.Name] = optionapi

		return optionapi
	end,
	Divider = function(children, text)
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		divider.BorderSizePixel = 0
		divider.Parent = children
		if text then
			local label = Instance.new('TextLabel')
			label.Name = 'DividerLabel'
			label.Size = UDim2.fromOffset(218, 27)
			label.BackgroundTransparency = 1
			label.Text = '          '..text:upper()
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextColor3 = color.Dark(uipallet.Text, 0.43)
			label.TextSize = 9
			label.FontFace = uipallet.Font
			label.Parent = children
			divider.Position = UDim2.fromOffset(0, 26)
			divider.Parent = label
		end
	end
}

mainapi.Components = setmetatable(components, {
	__newindex = function(self, ind, func)
		for _, v in mainapi.Modules do
			rawset(v, 'Create'..ind, function(_, settings)
				return func(settings, v.Children, v)
			end)
		end

		for _, panel in {mainapi.Legit, mainapi.Kits} do
			for _, v in panel.Modules do
				rawset(v, 'Create'..ind, function(_, settings)
					return func(settings, v.Children, v)
				end)
			end
		end

		rawset(self, ind, func)
	end
})
local hookedCallbacks = setmetatable({}, {__mode = 'k'})
local function hookOptionCallback(callback)
	if type(callback) ~= 'function' then return callback end
	local existing = hookedCallbacks[callback]
	if existing then return existing end
	local hooked = function(...)
		mainapi:ScheduleSave()
		return callback(...)
	end
	hookedCallbacks[callback] = hooked
	hookedCallbacks[hooked] = hooked
	return hooked
end

mainapi.ContextualOptions = {}
function mainapi:AttachContextualOption(option, settings)
	if type(option) == 'table' and type(settings) == 'table' and getmetatable(option) == nil then
		setmetatable(option, {
			__newindex = function(self, key, value)
				if key == 'Function' then
					settings.Function = hookOptionCallback(value)
				else
					rawset(self, key, value)
				end
			end,
		})
	end
	if type(settings) == 'table' then
		settings.Function = hookOptionCallback(settings.Function)
	end
	if option and option.Object and type(settings) == 'table' and type(settings.Visible) == 'function' then
		option.VisibilityPredicate = settings.Visible
		function option:RefreshVisibility()
			local ok, visible = pcall(self.VisibilityPredicate)
			self.Object.Visible = ok and visible and true or false
		end
		table.insert(self.ContextualOptions, option)
		option:RefreshVisibility()
	end
	return option
end
function mainapi:RefreshContextualOptions()
	for _, option in self.ContextualOptions do
		if option.RefreshVisibility then option:RefreshVisibility() end
	end
end

task.spawn(function()
	repeat
		local hue = tick() * (0.2 * mainapi.RainbowSpeed.Value) % 1
		for _, v in mainapi.RainbowTable do
			if v.Type == 'GUISlider' then
				pcall(v.SetValue, v, mainapi:Color(hue))
			else
				pcall(v.SetValue, v, hue)
			end
		end
		task.wait(1 / mainapi.RainbowUpdateSpeed.Value)
	until mainapi.Loaded == nil
end)

function mainapi:BlurCheck()
	local enabled = clickgui and clickgui.Visible and self.Blur and self.Blur.Enabled
	if inputService.TouchEnabled then
		if enabled then
			if not mobileBlur or not mobileBlur.Parent then
				mobileBlur = Instance.new('BlurEffect')
				mobileBlur.Name = 'ElevateV4MobileBlur'
				mobileBlur.Parent = lighting
			end
			mobileBlur.Size = 24
		else
			if mobileBlur then mobileBlur:Destroy(); mobileBlur = nil end
		end
	elseif self.ThreadFix then
		setthreadidentity(8)
		runService:SetRobloxGuiFocused(enabled or guiService:GetErrorType() ~= Enum.ConnectionError.OK and self.Blur and self.Blur.Enabled)
	end
end

addMaid(mainapi)
mainapi:Clean(mainapi.GameInfoChanged)
mainapi:Clean(guiService.MenuOpened:Connect(function()
	if mainapi.Loaded then pcall(mainapi.Save, mainapi) end
end))
function mainapi:SortModules()
	local sorting = {}
	for _, v in self.Modules do
		sorting[v.Category] = sorting[v.Category] or {}
		table.insert(sorting[v.Category], v.Name)
	end

	for _, sort in sorting do
		table.sort(sort)
		for i, v in sort do
			local module = self.Modules[v]
			module.Index = i
			module.Object.LayoutOrder = i * 2
			local panel = module.OptionsChildren or module.Children
			if panel then
				panel.LayoutOrder = (i * 2) + 1
			end
		end
	end
end
local pendingLayout, layoutScheduled = {}, false
function mainapi:FlushModuleLayout()
	layoutScheduled = false
	if #pendingLayout == 0 then return end
	local queued = pendingLayout
	pendingLayout = {}
	local categories, parents = {}, {}
	for _, entry in queued do
		local moduleapi = entry[1]
		if moduleapi.Object and moduleapi.Object.Parent then
			moduleapi:RefreshHiddenState(mainapi.EditGUI == true)
			categories[entry[2]] = true
			parents[moduleapi.Object.Parent] = true
		end
	end
	for categoryapi in categories do
		if categoryapi.UpdateHidden then categoryapi:UpdateHidden() end
	end
	self:SortModules()
	for parent in parents do
		local layout = parent:FindFirstChildOfClass('UIListLayout')
		if parent:IsA('ScrollingFrame') and layout then
			parent.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y / scale.Scale)
		end
	end
end

function mainapi:QueueModuleLayout(moduleapi, categoryapi)
	table.insert(pendingLayout, {moduleapi, categoryapi})
	if not layoutScheduled then
		layoutScheduled = true
		task.defer(function()
			self:FlushModuleLayout()
		end)
	end
end

function mainapi:CreateGUI()
	local categoryapi = {
		Type = 'MainWindow',
		Buttons = {},
		Options = {}
	}

	local window = Instance.new('TextButton')
	window.Name = 'GUICategory'
	window.Position = UDim2.fromOffset(6, 60)
	window.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	window.AutoButtonColor = false
	window.Text = ''
	window.Parent = clickgui
	addBlur(window)
	addCorner(window)
	addWindowStroke(window)
	makeDraggable(window)
	window.Parent = clickgui
	addBlur(window)
	addCorner(window)
	addWindowStroke(window)
	makeDraggable(window)

	local logo = Instance.new('ImageLabel')
	logo.Name = 'VapeLogo'
	logo.Size = UDim2.fromOffset(55, 16)
	logo.Position = UDim2.fromOffset(12, 11)
	logo.BackgroundTransparency = 1
	logo.Image = getcustomasset('ElevateV4/assets/new/vapelogomini.png')
	logo.ImageColor3 = select(3, uipallet.Main:ToHSV()) > 0.5 and uipallet.Text or Color3.new(1, 1, 1)
	logo.Parent = window
	local logov4 = Instance.new('ImageLabel')
	logov4.Name = 'V4Logo'
	logov4.Size = UDim2.fromOffset(23, 16)
	logov4.Position = UDim2.new(1, -1, 0, 0)
	logov4.BackgroundTransparency = 1
	logov4.Image = getcustomasset('ElevateV4/assets/new/v4mini.png')
	logov4.Parent = logo

local children = Instance.new('Frame')			
	local children = Instance.new('Frame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -33)
	children.Position = UDim2.fromOffset(0, 37)
	children.BackgroundTransparency = 1
	children.Parent = window
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Parent = children
	local settingsbutton = Instance.new('TextButton')
	settingsbutton.Name = 'Settings'
	settingsbutton.Size = UDim2.fromOffset(40, 40)
	settingsbutton.Position = UDim2.new(1, -40, 0, 0)
	settingsbutton.BackgroundTransparency = 1
	settingsbutton.Text = ''
	settingsbutton.Parent = window
	addTooltip(settingsbutton, 'Open settings')
	local settingsicon = Instance.new('ImageLabel')
	settingsicon.Size = UDim2.fromOffset(14, 14)
	settingsicon.Position = UDim2.fromOffset(15, 12)
	settingsicon.BackgroundTransparency = 1
	settingsicon.Image = getcustomasset('ElevateV4/assets/new/guisettings.png')
	settingsicon.ImageColor3 = color.Light(uipallet.Main, 0.37)
	settingsicon.Parent = settingsbutton
	local discordbutton = Instance.new('ImageButton')
	discordbutton.Size = UDim2.fromOffset(16, 16)
	discordbutton.Position = UDim2.new(1, -56, 0, 11)
	discordbutton.BackgroundTransparency = 1
	discordbutton.Image = getcustomasset('ElevateV4/assets/new/discord.png')
	discordbutton.Parent = window
	addTooltip(discordbutton, 'Join discord')
	local settingspane = Instance.new('TextButton')
	settingspane.Size = UDim2.fromScale(1, 1)
	settingspane.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	settingspane.AutoButtonColor = false
	settingspane.Visible = false
	settingspane.Text = ''
	settingspane.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -36, 0, 20)
	title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 11)
	title.BackgroundTransparency = 1
	title.Text = 'Settings'
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.Parent = settingspane
	local close = addCloseButton(settingspane)
	local back = Instance.new('ImageButton')
	back.Name = 'Back'
	back.Size = UDim2.fromOffset(16, 16)
	back.Position = UDim2.fromOffset(11, 13)
	back.BackgroundTransparency = 1
	back.Image = getcustomasset('ElevateV4/assets/new/back.png')
	back.ImageColor3 = color.Light(uipallet.Main, 0.37)
	back.Parent = settingspane
	local settingsversion = Instance.new('TextLabel')
	settingsversion.Name = 'Version'
	settingsversion.Size = UDim2.new(1, 0, 0, 16)
	settingsversion.Position = UDim2.new(0, 0, 1, -16)
	settingsversion.BackgroundTransparency = 1
	settingsversion.Text = 'ElevateV4 '..mainapi.Version..' '..(
		isfile('ElevateV4/profiles/commit.txt') and readfile('ElevateV4/profiles/commit.txt'):sub(1, 6) or ''
	)..' '
	settingsversion.TextColor3 = color.Dark(uipallet.Text, 0.43)
	settingsversion.TextXAlignment = Enum.TextXAlignment.Right
	settingsversion.TextSize = 10
	settingsversion.FontFace = uipallet.Font
	settingsversion.Parent = settingspane
	addCorner(settingspane)
	local settingschildren = Instance.new('Frame')
	settingschildren.Name = 'Children'
	settingschildren.Size = UDim2.new(1, 0, 1, -57)
	settingschildren.Position = UDim2.fromOffset(0, 41)
	settingschildren.BackgroundColor3 = uipallet.Main
	settingschildren.BorderSizePixel = 0
	settingschildren.Parent = settingspane
	local settingswindowlist = Instance.new('UIListLayout')
	settingswindowlist.SortOrder = Enum.SortOrder.LayoutOrder
	settingswindowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	settingswindowlist.Parent = settingschildren
	categoryapi.Object = window

	function categoryapi:CreateBind()
		local optionapi = {Bind = {'RightShift'}}

		local button = Instance.new('TextButton')
		button.Size = UDim2.fromOffset(220, 40)
		button.BackgroundColor3 = uipallet.Main
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = '          Rebind GUI'
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.TextColor3 = color.Dark(uipallet.Text, 0.16)
		button.TextSize = 14
		button.FontFace = uipallet.Font
		button.Parent = settingschildren
		addTooltip(button, 'Change the bind of the GUI')
		local bind = Instance.new('TextButton')
		bind.Name = 'Bind'
		bind.Size = UDim2.fromOffset(20, 21)
		bind.Position = UDim2.new(1, -10, 0, 9)
		bind.AnchorPoint = Vector2.new(1, 0)
		bind.BackgroundColor3 = Color3.new(1, 1, 1)
		bind.BackgroundTransparency = 0.92
		bind.BorderSizePixel = 0
		bind.AutoButtonColor = false
		bind.Text = ''
		bind.Parent = button
		addTooltip(bind, 'Click to bind')
		addCorner(bind, UDim.new(0, 4))
		local icon = Instance.new('ImageLabel')
		icon.Name = 'Icon'
		icon.Size = UDim2.fromOffset(12, 12)
		icon.Position = UDim2.new(0.5, -6, 0, 5)
		icon.BackgroundTransparency = 1
		icon.Image = getcustomasset('ElevateV4/assets/new/bind.png')
		icon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		icon.Parent = bind
		local label = Instance.new('TextLabel')
		label.Name = 'Text'
		label.Size = UDim2.fromScale(1, 1)
		label.Position = UDim2.fromOffset(0, 1)
		label.BackgroundTransparency = 1
		label.Visible = false
		label.Text = ''
		label.TextColor3 = color.Dark(uipallet.Text, 0.43)
		label.TextSize = 12
		label.FontFace = uipallet.Font
		label.Parent = bind

		function optionapi:SetBind(tab)
			mainapi.Keybind = #tab <= 0 and mainapi.Keybind or table.clone(tab)
			self.Bind = mainapi.Keybind
			if mainapi.VapeButton then
				mainapi.VapeButton:Destroy()
				mainapi.VapeButton = nil
			end

			bind.Visible = true
			label.Visible = true
			icon.Visible = false
			label.Text = table.concat(mainapi.Keybind, ' + '):upper()
			bind.Size = UDim2.fromOffset(math.max(getfontsize(label.Text, label.TextSize, label.Font).X + 10, 20), 21)
		end

		bind.MouseEnter:Connect(function()
			label.Visible = false
			icon.Visible = not label.Visible
			icon.Image = getcustomasset('ElevateV4/assets/new/edit.png')
			icon.ImageColor3 = color.Dark(uipallet.Text, 0.16)
		end)
		bind.MouseLeave:Connect(function()
			label.Visible = true
			icon.Visible = not label.Visible
			icon.Image = getcustomasset('ElevateV4/assets/new/bind.png')
			icon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		end)
		bind.MouseButton1Click:Connect(function()
			mainapi.Binding = optionapi
		end)

		categoryapi.Options.Bind = optionapi

		return optionapi
	end

	function categoryapi:CreateButton(categorysettings)
		local optionapi = {
			Enabled = false,
			Index = getTableSize(categoryapi.Buttons)
		}

		local button = Instance.new('TextButton')
		button.Name = categorysettings.Name
		button.Size = UDim2.fromOffset(220, 40)
		button.BackgroundColor3 = uipallet.Main
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = (categorysettings.Icon and '                                 ' or '             ')..categorysettings.Name
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.TextColor3 = color.Dark(uipallet.Text, 0.16)
		button.TextSize = 14
		button.FontFace = uipallet.Font
		button.Parent = children
		local icon
		if categorysettings.Icon then
			icon = Instance.new('ImageLabel')
			icon.Name = 'Icon'
			icon.Size = categorysettings.Size
			icon.Position = UDim2.fromOffset(13, 13)
			icon.BackgroundTransparency = 1
			icon.Image = categorysettings.Icon
			icon.ImageColor3 = color.Dark(uipallet.Text, 0.16)
			icon.Parent = button
		end
		if categorysettings.Name == 'Profiles' then
			local label = Instance.new('TextLabel')
			label.Name = 'ProfileLabel'
			label.Size = UDim2.fromOffset(53, 24)
			label.Position = UDim2.new(1, -36, 0, 8)
			label.AnchorPoint = Vector2.new(1, 0)
			label.BackgroundColor3 = color.Light(uipallet.Main, 0.04)
			label.Text = 'default'
			label.TextColor3 = color.Dark(uipallet.Text, 0.29)
			label.TextSize = 12
			label.FontFace = uipallet.Font
			label.Parent = button
			addCorner(label)
			mainapi.ProfileLabel = label
		end
		local arrow = Instance.new('ImageLabel')
		arrow.Name = 'Arrow'
		arrow.Size = UDim2.fromOffset(4, 8)
		arrow.Position = UDim2.new(1, -20, 0, 16)
		arrow.BackgroundTransparency = 1
		arrow.Image = getcustomasset('ElevateV4/assets/new/expandright.png')
		arrow.ImageColor3 = color.Light(uipallet.Main, 0.37)
		arrow.Parent = button
		optionapi.Name = categorysettings.Name
		optionapi.Icon = icon
		optionapi.Object = button

		function optionapi:Toggle()
			self.Enabled = not self.Enabled
			tween:Tween(arrow, uipallet.Tween, {
				Position = UDim2.new(1, self.Enabled and -14 or -20, 0, 16)
			})
			button.TextColor3 = self.Enabled and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or uipallet.Text
			if icon then
				icon.ImageColor3 = button.TextColor3
			end
			button.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			categorysettings.Window.Visible = self.Enabled
		end

		button.MouseEnter:Connect(function()
			if not optionapi.Enabled then
				button.TextColor3 = uipallet.Text
				if icon then icon.ImageColor3 = uipallet.Text end
				button.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			end
		end)
		button.MouseLeave:Connect(function()
			if not optionapi.Enabled then
				button.TextColor3 = color.Dark(uipallet.Text, 0.16)
				if icon then icon.ImageColor3 = color.Dark(uipallet.Text, 0.16) end
				button.BackgroundColor3 = uipallet.Main
			end
		end)
		button.MouseButton1Click:Connect(function()
			optionapi:Toggle()
		end)

		categoryapi.Buttons[categorysettings.Name] = optionapi

		return optionapi
	end

	function categoryapi:CreateDivider(text)
		return components.Divider(children, text)
	end

	function categoryapi:CreateOverlayBar()
		local optionapi = {Toggles = {}}

		local bar = Instance.new('Frame')
		bar.Name = 'Overlays'
		bar.Size = UDim2.fromOffset(220, 36)
		bar.BackgroundColor3 = uipallet.Main
		bar.BorderSizePixel = 0
		bar.Parent = children
		components.Divider(bar)
		local button = Instance.new('ImageButton')
		button.Size = UDim2.fromOffset(24, 24)
		button.Position = UDim2.new(1, -29, 0, 7)
		button.BackgroundTransparency = 1
		button.AutoButtonColor = false
		button.Image = getcustomasset('ElevateV4/assets/new/overlaysicon.png')
		button.ImageColor3 = color.Light(uipallet.Main, 0.37)
		button.Parent = bar
		addCorner(button, UDim.new(1, 0))
		addTooltip(button, 'Open overlays menu')
		local homebutton = Instance.new('TextButton')
		homebutton.Name = 'ElevateV4Home'
		homebutton.Size = UDim2.fromOffset(42, 22)
		homebutton.Position = UDim2.fromOffset(8, 8)
		homebutton.BackgroundTransparency = 1
		homebutton.AutoButtonColor = false
		homebutton.Text = 'Home'
		homebutton.TextColor3 = color.Light(uipallet.Main, 0.37)
		homebutton.TextSize = 12
		homebutton.FontFace = uipallet.Font
		homebutton.Parent = bar
		addTooltip(homebutton, 'Home')
		homebutton.MouseButton1Click:Connect(function()
			if mainapi.Online then mainapi.Online:Open() end
		end)
		local shadow = Instance.new('TextButton')
		shadow.Name = 'Shadow'
		shadow.Size = UDim2.new(1, 0, 1, -5)
		shadow.BackgroundColor3 = Color3.new()
		shadow.BackgroundTransparency = 1
		shadow.AutoButtonColor = false
		shadow.ClipsDescendants = true
		shadow.Visible = false
		shadow.Text = ''
		shadow.Parent = window
		addCorner(shadow)
		local window = Instance.new('Frame')
		window.Size = UDim2.fromOffset(220, 42)
		window.Position = UDim2.fromScale(0, 1)
		window.BackgroundColor3 = uipallet.Main
		window.Parent = shadow
		addCorner(window)
		local icon = Instance.new('ImageLabel')
		icon.Name = 'Icon'
		icon.Size = UDim2.fromOffset(14, 12)
		icon.Position = UDim2.fromOffset(10, 13)
		icon.BackgroundTransparency = 1
		icon.Image = getcustomasset('ElevateV4/assets/new/overlaystab.png')
		icon.ImageColor3 = uipallet.Text
		icon.Parent = window
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -36, 0, 38)
		title.Position = UDim2.fromOffset(36, 0)
		title.BackgroundTransparency = 1
		title.Text = 'Overlays'
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 15
		title.FontFace = uipallet.Font
		title.Parent = window
		local close = addCloseButton(window, 7)
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.Position = UDim2.fromOffset(0, 37)
		divider.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		divider.BorderSizePixel = 0
		divider.Parent = window
		local childrentoggle = Instance.new('Frame')
		childrentoggle.Position = UDim2.fromOffset(0, 38)
		childrentoggle.BackgroundTransparency = 1
		childrentoggle.Parent = window
		local windowlist = Instance.new('UIListLayout')
		windowlist.SortOrder = Enum.SortOrder.LayoutOrder
		windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		windowlist.Parent = childrentoggle

		function optionapi:CreateToggle(togglesettings)
			local toggleapi = {
				Enabled = false,
				Index = getTableSize(optionapi.Toggles)
			}

			local hovered = false
			local toggle = Instance.new('TextButton')
			toggle.Name = togglesettings.Name..'Toggle'
			toggle.Size = UDim2.new(1, 0, 0, 40)
			toggle.BackgroundTransparency = 1
			toggle.AutoButtonColor = false
			toggle.Text = string.rep(' ', 33 * scale.Scale)..togglesettings.Name
			toggle.TextXAlignment = Enum.TextXAlignment.Left
			toggle.TextColor3 = color.Dark(uipallet.Text, 0.16)
			toggle.TextSize = 14
			toggle.FontFace = uipallet.Font
			toggle.Parent = childrentoggle
			local icon = Instance.new('ImageLabel')
			icon.Name = 'Icon'
			icon.Size = togglesettings.Size
			icon.Position = togglesettings.Position
			icon.BackgroundTransparency = 1
			icon.Image = togglesettings.Icon
			icon.ImageColor3 = uipallet.Text
			icon.Parent = toggle
			local knob = Instance.new('Frame')
			knob.Name = 'Knob'
			knob.Size = UDim2.fromOffset(22, 12)
			knob.Position = UDim2.new(1, -30, 0, 14)
			knob.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
			knob.Parent = toggle
			addCorner(knob, UDim.new(1, 0))
			local knobmain = knob:Clone()
			knobmain.Size = UDim2.fromOffset(8, 8)
			knobmain.Position = UDim2.fromOffset(2, 2)
			knobmain.BackgroundColor3 = uipallet.Main
			knobmain.Parent = knob
			toggleapi.Object = toggle

			function toggleapi:Toggle()
				self.Enabled = not self.Enabled
				tween:Tween(knob, uipallet.Tween, {
					BackgroundColor3 = self.Enabled and Color3.fromHSV(
						mainapi.GUIColor.Hue,
						mainapi.GUIColor.Sat,
						mainapi.GUIColor.Value
					) or (hovered and color.Light(uipallet.Main, 0.37) or color.Light(uipallet.Main, 0.14))
				})
				tween:Tween(knobmain, uipallet.Tween, {
					Position = UDim2.fromOffset(self.Enabled and 12 or 2, 2)
				})
				togglesettings.Function(self.Enabled)
			end

			scale:GetPropertyChangedSignal('Scale'):Connect(function()
				toggle.Text = string.rep(' ', 33 * scale.Scale)..togglesettings.Name
			end)
			toggle.MouseEnter:Connect(function()
				hovered = true
				if not toggleapi.Enabled then
					tween:Tween(knob, uipallet.Tween, {
						BackgroundColor3 = color.Light(uipallet.Main, 0.37)
					})
				end
			end)
			toggle.MouseLeave:Connect(function()
				hovered = false
				if not toggleapi.Enabled then
					tween:Tween(knob, uipallet.Tween, {
						BackgroundColor3 = color.Light(uipallet.Main, 0.14)
					})
				end
			end)
			toggle.MouseButton1Click:Connect(function()
				toggleapi:Toggle()
			end)

			table.insert(optionapi.Toggles, toggleapi)

			return toggleapi
		end

		button.MouseEnter:Connect(function()
			button.ImageColor3 = uipallet.Text
			tween:Tween(button, uipallet.Tween, {
				BackgroundTransparency = 0.9
			})
		end)
		button.MouseLeave:Connect(function()
			button.ImageColor3 = color.Light(uipallet.Main, 0.37)
			tween:Tween(button, uipallet.Tween, {
				BackgroundTransparency = 1
			})
		end)
		button.MouseButton1Click:Connect(function()
			shadow.Visible = true
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 0.5
			})
			tween:Tween(window, uipallet.Tween, {
				Position = UDim2.new(0, 0, 1, -(window.Size.Y.Offset))
			})
		end)
		close.MouseButton1Click:Connect(function()
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 1
			})
			tween:Tween(window, uipallet.Tween, {
				Position = UDim2.fromScale(0, 1)
			})
			task.wait(0.2)
			shadow.Visible = false
		end)
		shadow.MouseButton1Click:Connect(function()
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 1
			})
			tween:Tween(window, uipallet.Tween, {
				Position = UDim2.fromScale(0, 1)
			})
			task.wait(0.2)
			shadow.Visible = false
		end)
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			window.Size = UDim2.fromOffset(220, math.min(37 + windowlist.AbsoluteContentSize.Y / scale.Scale, 605))
			childrentoggle.Size = UDim2.fromOffset(220, window.Size.Y.Offset - 5)
		end)

		mainapi.Overlays = optionapi

		return optionapi
	end

	function categoryapi:CreateSettingsDivider()
		components.Divider(settingschildren)
	end

	function categoryapi:CreateSettingsPane(categorysettings)
		local optionapi = {}

		local button = Instance.new('TextButton')
		button.Name = categorysettings.Name
		button.Size = UDim2.fromOffset(220, 40)
		button.BackgroundColor3 = uipallet.Main
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = '          '..categorysettings.Name
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.TextColor3 = color.Dark(uipallet.Text, 0.16)
		button.TextSize = 14
		button.FontFace = uipallet.Font
		button.Parent = settingschildren
		local arrow = Instance.new('ImageLabel')
		arrow.Name = 'Arrow'
		arrow.Size = UDim2.fromOffset(4, 8)
		arrow.Position = UDim2.new(1, -20, 0, 16)
		arrow.BackgroundTransparency = 1
		arrow.Image = getcustomasset('ElevateV4/assets/new/expandright.png')
		arrow.ImageColor3 = color.Light(uipallet.Main, 0.37)
		arrow.Parent = button
		local settingspane = Instance.new('TextButton')
		settingspane.Size = UDim2.fromScale(1, 1)
		settingspane.BackgroundColor3 = uipallet.Main
		settingspane.AutoButtonColor = false
		settingspane.Visible = false
		settingspane.Text = ''
		settingspane.Parent = window
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -36, 0, 20)
		title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 11)
		title.BackgroundTransparency = 1
		title.Text = categorysettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 13
		title.FontFace = uipallet.Font
		title.Parent = settingspane
		local close = addCloseButton(settingspane)
		local back = Instance.new('ImageButton')
		back.Name = 'Back'
		back.Size = UDim2.fromOffset(16, 16)
		back.Position = UDim2.fromOffset(11, 13)
		back.BackgroundTransparency = 1
		back.Image = getcustomasset('ElevateV4/assets/new/back.png')
		back.ImageColor3 = color.Light(uipallet.Main, 0.37)
		back.Parent = settingspane
		addCorner(settingspane)
		local settingschildren = Instance.new('Frame')
		settingschildren.Name = 'Children'
		settingschildren.Size = UDim2.new(1, 0, 1, -57)
		settingschildren.Position = UDim2.fromOffset(0, 41)
		settingschildren.BackgroundColor3 = uipallet.Main
		settingschildren.BorderSizePixel = 0
		settingschildren.Parent = settingspane
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.BackgroundColor3 = Color3.new(1, 1, 1)
		divider.BackgroundTransparency = 0.928
		divider.BorderSizePixel = 0
		divider.Parent = settingschildren
		local settingswindowlist = Instance.new('UIListLayout')
		settingswindowlist.SortOrder = Enum.SortOrder.LayoutOrder
		settingswindowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		settingswindowlist.Parent = settingschildren

		for i, v in components do
			optionapi['Create'..i] = function(_, settings)
				return mainapi:AttachContextualOption(v(settings, settingschildren, categoryapi), settings)
			end
		end

		back.MouseEnter:Connect(function()
			back.ImageColor3 = uipallet.Text
		end)
		back.MouseLeave:Connect(function()
			back.ImageColor3 = color.Light(uipallet.Main, 0.37)
		end)
		back.MouseButton1Click:Connect(function()
			settingspane.Visible = false
		end)
		button.MouseEnter:Connect(function()
			button.TextColor3 = uipallet.Text
			button.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		end)
		button.MouseLeave:Connect(function()
			button.TextColor3 = color.Dark(uipallet.Text, 0.16)
			button.BackgroundColor3 = uipallet.Main
		end)
		button.MouseButton1Click:Connect(function()
			settingspane.Visible = true
		end)
		close.MouseButton1Click:Connect(function()
			settingspane.Visible = false
		end)
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			window.Size = UDim2.fromOffset(220, 45 + windowlist.AbsoluteContentSize.Y / scale.Scale)
			for _, v in categoryapi.Buttons do
				if v.Icon then
					v.Object.Text = string.rep(' ', 33 * scale.Scale)..v.Name
				end
			end
		end)

		return optionapi
	end

	function categoryapi:CreateGUISlider(optionsettings)
		local optionapi = {
			Type = 'GUISlider',
			Notch = accent.Notch,
			Hue = accent.Hue,
			Sat = accent.Sat,
			Value = accent.Value,
			Rainbow = false,
			CustomColor = false
		}
		local slidercolors = {
			Color3.fromRGB(250, 50, 56),
			Color3.fromRGB(242, 99, 33),
			Color3.fromRGB(252, 179, 22),
			Color3.fromRGB(5, 133, 104),
			Color3.fromRGB(47, 122, 229),
			Color3.fromRGB(190, 115, 255),
			Color3.fromRGB(232, 96, 152)
		}
		local slidercolorpos = {
			4,
			33,
			62,
			90,
			119,
			148,
			177
		}

		local function createSlider(name, gradientColor)
			local slider = Instance.new('TextButton')
			slider.Name = optionsettings.Name..'Slider'..name
			slider.Size = UDim2.fromOffset(220, 50)
			slider.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
			slider.BorderSizePixel = 0
			slider.AutoButtonColor = false
			slider.Visible = false
			slider.Text = ''
			slider.Parent = settingschildren
			local title = Instance.new('TextLabel')
			title.Name = 'Title'
			title.Size = UDim2.fromOffset(60, 30)
			title.Position = UDim2.fromOffset(10, 2)
			title.BackgroundTransparency = 1
			title.Text = name
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.TextColor3 = color.Dark(uipallet.Text, 0.16)
			title.TextSize = 11
			title.FontFace = uipallet.Font
			title.Parent = slider
			local holder = Instance.new('Frame')
			holder.Name = 'Slider'
			holder.Size = UDim2.fromOffset(200, 2)
			holder.Position = UDim2.fromOffset(10, 37)
			holder.BackgroundColor3 = Color3.new(1, 1, 1)
			holder.BorderSizePixel = 0
			holder.Parent = slider
			local uigradient = Instance.new('UIGradient')
			uigradient.Color = gradientColor
			uigradient.Parent = holder
			local fill = holder:Clone()
			fill.Name = 'Fill'
			fill.Size = UDim2.fromScale(math.clamp(1, 0.04, 0.96), 1)
			fill.Position = UDim2.new()
			fill.BackgroundTransparency = 1
			fill.Parent = holder
			local knobframe = Instance.new('Frame')
			knobframe.Name = 'Knob'
			knobframe.Size = UDim2.fromOffset(24, 4)
			knobframe.Position = UDim2.fromScale(1, 0.5)
			knobframe.AnchorPoint = Vector2.new(0.5, 0.5)
			knobframe.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
			knobframe.BorderSizePixel = 0
			knobframe.Parent = fill
			local knob = Instance.new('Frame')
			knob.Name = 'Knob'
			knob.Size = UDim2.fromOffset(14, 14)
			knob.Position = UDim2.fromScale(0.5, 0.5)
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.BackgroundColor3 = uipallet.Text
			knob.Parent = knobframe
			addCorner(knob, UDim.new(1, 0))
			if name == 'Custom color' then
				local reset = Instance.new('TextButton')
				reset.Size = UDim2.fromOffset(45, 20)
				reset.Position = UDim2.new(1, -52, 0, 5)
				reset.BackgroundTransparency = 1
				reset.Text = 'RESET'
				reset.TextColor3 = color.Dark(uipallet.Text, 0.16)
				reset.TextSize = 11
				reset.FontFace = uipallet.Font
				reset.Parent = slider
				reset.MouseButton1Click:Connect(function()
					optionapi:SetValue(nil, nil, nil, accent.Notch)
				end)
			end

			slider.InputBegan:Connect(function(inputObj)
				if
					(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
					and (inputObj.Position.Y - slider.AbsolutePosition.Y) > (20 * scale.Scale)
				then
					local changed = inputService.InputChanged:Connect(function(input)
						if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
							local value = math.clamp((input.Position.X - holder.AbsolutePosition.X) / holder.AbsoluteSize.X, 0, 1)
							optionapi:SetValue(
								name == 'Custom color' and value or nil,
								name == 'Saturation' and value or nil,
								name == 'Vibrance' and value or nil,
								name == 'Opacity' and value or nil
							)
						end
					end)

					local ended
					ended = inputObj.Changed:Connect(function()
						if inputObj.UserInputState == Enum.UserInputState.End then
							if changed then
								changed:Disconnect()
							end
							if ended then
								ended:Disconnect()
							end
						end
					end)
				end
			end)
			slider.MouseEnter:Connect(function()
				tween:Tween(knob, uipallet.Tween, {
					Size = UDim2.fromOffset(16, 16)
				})
			end)
			slider.MouseLeave:Connect(function()
				tween:Tween(knob, uipallet.Tween, {
					Size = UDim2.fromOffset(14, 14)
				})
			end)

			return slider
		end

		local slider = Instance.new('TextButton')
		slider.Name = optionsettings.Name..'Slider'
		slider.Size = UDim2.fromOffset(220, 50)
		slider.BackgroundTransparency = 1
		slider.AutoButtonColor = false
		slider.Text = ''
		slider.Parent = settingschildren
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.fromOffset(60, 30)
		title.Position = UDim2.fromOffset(10, 2)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = color.Dark(uipallet.Text, 0.16)
		title.TextSize = 11
		title.FontFace = uipallet.Font
		title.Parent = slider
		local holder = Instance.new('Frame')
		holder.Name = 'Slider'
		holder.Size = UDim2.fromOffset(200, 2)
		holder.Position = UDim2.fromOffset(10, 37)
		holder.BackgroundTransparency = 1
		holder.BorderSizePixel = 0
		holder.Parent = slider
		local colornum = 0
		for i, color in slidercolors do
			local colorframe = Instance.new('Frame')
			colorframe.Size = UDim2.fromOffset(27 + (((i + 1) % 2) == 0 and 1 or 0), 2)
			colorframe.Position = UDim2.fromOffset(colornum, 0)
			colorframe.BackgroundColor3 = color
			colorframe.BorderSizePixel = 0
			colorframe.Parent = holder
			colornum += (colorframe.Size.X.Offset + 1)
		end
		local preview = Instance.new('ImageButton')
		preview.Name = 'Preview'
		preview.Size = UDim2.fromOffset(12, 12)
		preview.Position = UDim2.new(1, -22, 0, 10)
		preview.BackgroundTransparency = 1
		preview.Image = getcustomasset('ElevateV4/assets/new/colorpreview.png')
		preview.ImageColor3 = Color3.fromHSV(optionapi.Hue, 1, 1)
		preview.Parent = slider
		local valuebox = Instance.new('TextBox')
		valuebox.Name = 'Box'
		valuebox.Size = UDim2.fromOffset(60, 15)
		valuebox.Position = UDim2.new(1, -69, 0, 9)
		valuebox.BackgroundTransparency = 1
		valuebox.Visible = false
		valuebox.Text = ''
		valuebox.TextXAlignment = Enum.TextXAlignment.Right
		valuebox.TextColor3 = color.Dark(uipallet.Text, 0.16)
		valuebox.TextSize = 11
		valuebox.FontFace = uipallet.Font
		valuebox.ClearTextOnFocus = true
		valuebox.Parent = slider
		local expandbutton = Instance.new('TextButton')
		expandbutton.Name = 'Expand'
		expandbutton.Size = UDim2.fromOffset(17, 13)
		expandbutton.Position = UDim2.new(0, getfontsize(title.Text, title.TextSize, title.Font).X + 11, 0, 7)
		expandbutton.BackgroundTransparency = 1
		expandbutton.Text = ''
		expandbutton.Parent = slider
		local expandicon = Instance.new('ImageLabel')
		expandicon.Name = 'Expand'
		expandicon.Size = UDim2.fromOffset(9, 5)
		expandicon.Position = UDim2.fromOffset(4, 4)
		expandicon.BackgroundTransparency = 1
		expandicon.Image = getcustomasset('ElevateV4/assets/new/expandicon.png')
		expandicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		expandicon.Parent = expandbutton
		local rainbow = Instance.new('TextButton')
		rainbow.Name = 'Rainbow'
		rainbow.Size = UDim2.fromOffset(12, 12)
		rainbow.Position = UDim2.new(1, -42, 0, 10)
		rainbow.BackgroundTransparency = 1
		rainbow.Text = ''
		rainbow.Parent = slider
		local rainbow1 = Instance.new('ImageLabel')
		rainbow1.Size = UDim2.fromOffset(12, 12)
		rainbow1.BackgroundTransparency = 1
		rainbow1.Image = getcustomasset('ElevateV4/assets/new/rainbow_1.png')
		rainbow1.ImageColor3 = color.Light(uipallet.Main, 0.37)
		rainbow1.Parent = rainbow
		local rainbow2 = rainbow1:Clone()
		rainbow2.Image = getcustomasset('ElevateV4/assets/new/rainbow_2.png')
		rainbow2.Parent = rainbow
		local rainbow3 = rainbow1:Clone()
		rainbow3.Image = getcustomasset('ElevateV4/assets/new/rainbow_3.png')
		rainbow3.Parent = rainbow
		local rainbow4 = rainbow1:Clone()
		rainbow4.Image = getcustomasset('ElevateV4/assets/new/rainbow_4.png')
		rainbow4.Parent = rainbow
		local knob = Instance.new('ImageLabel')
		knob.Name = 'Knob'
		knob.Size = UDim2.fromOffset(26, 12)
		knob.Position = UDim2.fromOffset(slidercolorpos[accent.Notch] - 3, -5)
		knob.BackgroundTransparency = 1
		knob.Image = getcustomasset('ElevateV4/assets/new/guislider.png')
		knob.ImageColor3 = slidercolors[accent.Notch]
		knob.Parent = holder
		optionsettings.Function = optionsettings.Function or function() end
		local rainbowTable = {}
		for i = 0, 1, 0.1 do
			table.insert(rainbowTable, ColorSequenceKeypoint.new(i, Color3.fromHSV(i, 1, 1)))
		end
		local colorSlider = createSlider('Custom color', ColorSequence.new(rainbowTable))
		local satSlider = createSlider('Saturation', ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, optionapi.Value)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(optionapi.Hue, 1, optionapi.Value))
		}))
		local vibSlider = createSlider('Vibrance', ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(optionapi.Hue, optionapi.Sat, 1))
		}))
		local normalknob = getcustomasset('ElevateV4/assets/new/guislider.png')
		local rainbowknob = getcustomasset('ElevateV4/assets/new/guisliderrain.png')
		local rainbowthread

		function optionapi:Save(tab)
			tab[optionsettings.Name] = {
				Hue = self.Hue,
				Sat = self.Sat,
				Value = self.Value,
				Notch = self.Notch,
				CustomColor = self.CustomColor,
				Rainbow = self.Rainbow
			}
		end

		function optionapi:Load(tab)
			tab = configapi.Accents.Apply(tab, true)
			if tab.Rainbow then
				self:Toggle()
			end
			if self.Rainbow or tab.CustomColor then
				self:SetValue(tab.Hue, tab.Sat, tab.Value)
			else
				local notchColor = tab.Notch and slidercolors[tab.Notch]
				if notchColor and tab.Hue and tab.Sat and tab.Value then
					local nh, ns, nv = notchColor:ToHSV()
					if math.abs(nh - tab.Hue) < 0.01 and math.abs(ns - tab.Sat) < 0.01 and math.abs(nv - tab.Value) < 0.01 then
						self:SetValue(nil, nil, nil, tab.Notch)
					else
						self:SetValue(tab.Hue, tab.Sat, tab.Value)
					end
				elseif tab.Hue and tab.Sat and tab.Value then
					self:SetValue(tab.Hue, tab.Sat, tab.Value)
				else
					self:SetValue(nil, nil, nil, tab.Notch)
				end
			end
		end

		function optionapi:SetValue(h, s, v, n)
			if n then
				if self.Rainbow then
					self:Toggle()
				end
				self.CustomColor = false
				h, s, v = slidercolors[n]:ToHSV()
			else
				self.CustomColor = true
			end

			self.Hue = h or self.Hue
			self.Sat = s or self.Sat
			self.Value = v or self.Value
			self.Notch = n
			preview.ImageColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
			satSlider.Slider.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, self.Value)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, 1, self.Value))
			})
			vibSlider.Slider.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, 1))
			})

			if self.Rainbow or self.CustomColor then
				knob.Image = rainbowknob
				knob.ImageColor3 = Color3.new(1, 1, 1)
				tween:Tween(knob, uipallet.Tween, {
					Position = UDim2.fromOffset(slidercolorpos[accent.Notch] - 3, -5)
				})
			else
				knob.Image = normalknob
				knob.ImageColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
				tween:Tween(knob, uipallet.Tween, {
					Position = UDim2.fromOffset(slidercolorpos[n or accent.Notch] - 3, -5)
				})
			end

			if self.Rainbow then
				if h then
					colorSlider.Slider.Fill.Size = UDim2.fromScale(math.clamp(self.Hue, 0.04, 0.96), 1)
				end
				if s then
					satSlider.Slider.Fill.Size = UDim2.fromScale(math.clamp(self.Sat, 0.04, 0.96), 1)
				end
				if v then
					vibSlider.Slider.Fill.Size = UDim2.fromScale(math.clamp(self.Value, 0.04, 0.96), 1)
				end
			else
				if h then
					tween:Tween(colorSlider.Slider.Fill, uipallet.Tween, {
						Size = UDim2.fromScale(math.clamp(self.Hue, 0.04, 0.96), 1)
					})
				end
				if s then
					tween:Tween(satSlider.Slider.Fill, uipallet.Tween, {
						Size = UDim2.fromScale(math.clamp(self.Sat, 0.04, 0.96), 1)
					})
				end
				if v then
					tween:Tween(vibSlider.Slider.Fill, uipallet.Tween, {
						Size = UDim2.fromScale(math.clamp(self.Value, 0.04, 0.96), 1)
					})
				end
			end
			optionsettings.Function(self.Hue, self.Sat, self.Value)
		end

		function optionapi:Toggle()
			self.Rainbow = not self.Rainbow
			if rainbowthread then
				task.cancel(rainbowthread)
			end

			if self.Rainbow then
				knob.Image = rainbowknob
				table.insert(mainapi.RainbowTable, self)

				rainbow1.ImageColor3 = Color3.fromRGB(5, 127, 100)
				rainbowthread = task.delay(0.1, function()
					rainbow2.ImageColor3 = Color3.fromRGB(228, 125, 43)
					rainbowthread = task.delay(0.1, function()
						rainbow3.ImageColor3 = Color3.fromRGB(225, 46, 52)
						rainbowthread = nil
					end)
				end)
			else
				self:SetValue(nil, nil, nil, accent.Notch)
				knob.Image = normalknob
				local ind = table.find(mainapi.RainbowTable, self)
				if ind then
					table.remove(mainapi.RainbowTable, ind)
				end

				rainbow3.ImageColor3 = color.Light(uipallet.Main, 0.37)
				rainbowthread = task.delay(0.1, function()
					rainbow2.ImageColor3 = color.Light(uipallet.Main, 0.37)
					rainbowthread = task.delay(0.1, function()
						rainbow1.ImageColor3 = color.Light(uipallet.Main, 0.37)
					end)
				end)
			end
		end

		expandbutton.MouseEnter:Connect(function()
			expandicon.ImageColor3 = color.Dark(uipallet.Text, 0.16)
		end)
		expandbutton.MouseLeave:Connect(function()
			expandicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		end)
		expandbutton.MouseButton1Click:Connect(function()
			colorSlider.Visible = not colorSlider.Visible
			satSlider.Visible = colorSlider.Visible
			vibSlider.Visible = satSlider.Visible
			expandicon.Rotation = satSlider.Visible and 180 or 0
		end)
		preview.MouseButton1Click:Connect(function()
			preview.Visible = false
			valuebox.Visible = true
			valuebox:CaptureFocus()
			local text = Color3.fromHSV(optionapi.Hue, optionapi.Sat, optionapi.Value)
			valuebox.Text = math.round(text.R * 255)..', '..math.round(text.G * 255)..', '..math.round(text.B * 255)
		end)
		slider.InputBegan:Connect(function(inputObj)
			if
				(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
				and (inputObj.Position.Y - slider.AbsolutePosition.Y) > (20 * scale.Scale)
			then
				local changed = inputService.InputChanged:Connect(function(input)
					if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
						optionapi:SetValue(nil, nil, nil, math.clamp(math.round((input.Position.X - holder.AbsolutePosition.X) / scale.Scale / 27), 1, 7))
					end
				end)

				local ended
				ended = inputObj.Changed:Connect(function()
					if inputObj.UserInputState == Enum.UserInputState.End then
						if changed then
							changed:Disconnect()
						end
						if ended then
							ended:Disconnect()
						end
					end
				end)
				optionapi:SetValue(nil, nil, nil, math.clamp(math.round((inputObj.Position.X - holder.AbsolutePosition.X) / scale.Scale / 27), 1, 7))
			end
		end)
		rainbow.MouseButton1Click:Connect(function()
			optionapi:Toggle()
		end)
		valuebox.FocusLost:Connect(function(enter)
			preview.Visible = true
			valuebox.Visible = false
			if enter then
				local commas = valuebox.Text:split(',')
				local suc, res = pcall(function()
					return tonumber(commas[1]) and Color3.fromRGB(
						tonumber(commas[1]),
						tonumber(commas[2]),
						tonumber(commas[3])
					) or Color3.fromHex(valuebox.Text)
				end)

				if suc then
					if optionapi.Rainbow then
						optionapi:Toggle()
					end
					optionapi:SetValue(res:ToHSV())
				end
			end
		end)

		optionapi.Object = slider
		categoryapi.Options[optionsettings.Name] = optionapi

		return optionapi
	end

	back.MouseEnter:Connect(function()
		back.ImageColor3 = uipallet.Text
	end)
	back.MouseLeave:Connect(function()
		back.ImageColor3 = color.Light(uipallet.Main, 0.37)
	end)
	back.MouseButton1Click:Connect(function()
		settingspane.Visible = false
	end)
	close.MouseButton1Click:Connect(function()
		settingspane.Visible = false
	end)
	discordbutton.MouseButton1Click:Connect(function()
		task.spawn(function()
			local body = httpService:JSONEncode({
				nonce = httpService:GenerateGUID(false),
				args = {
					invite = {code = 'ElevateV4'},
					code = 'ElevateV4'
				},
				cmd = 'INVITE_BROWSER'
			})

			for i = 1, 14 do
				task.defer(function()
					request({
						Method = 'POST',
						Url = 'http://127.0.0.1:64'..(53 + i)..'/rpc?v=1',
						Headers = {
							['Content-Type'] = 'application/json',
							Origin = 'https://discord.com'
						},
						Body = body
					})
				end)
			end
		end)

		task.spawn(function()
			tooltip.Text = 'Copied!'
			setclipboard('https://discord.gg/aYu5c9v9zv')
		end)
	end)
	settingsbutton.MouseEnter:Connect(function()
		settingsicon.ImageColor3 = uipallet.Text
	end)
	settingsbutton.MouseLeave:Connect(function()
		settingsicon.ImageColor3 = color.Light(uipallet.Main, 0.37)
	end)
	settingsbutton.MouseButton1Click:Connect(function()
		settingspane.Visible = true
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		window.Size = UDim2.fromOffset(220, 42 + windowlist.AbsoluteContentSize.Y / scale.Scale)
		for _, v in categoryapi.Buttons do
			if v.Icon then
				v.Object.Text = string.rep(' ', 36 * scale.Scale)..v.Name
			end
		end
	end)

	self.Categories.Main = categoryapi

	return categoryapi
end

function mainapi:CreateCategory(categorysettings)
	local categoryapi = {
		Type = 'Category',
		Expanded = false
	}
	local categoryHovered = false

	mainapi.CategorySlot = (mainapi.CategorySlot or 0) + 1
	local slot = mainapi.CategorySlot
	local defaultX = 6 + (slot % 8) * 230
	local defaultY = 60 + math.floor(slot / 8) * 360

	local window = Instance.new('TextButton')
	window.Name = categorysettings.Name..'Category'
	window.Size = UDim2.fromOffset(220, 41)
	window.Position = UDim2.fromOffset(defaultX, defaultY)
	window.BackgroundColor3 = uipallet.Main
	window.AutoButtonColor = false
	window.Visible = false
	window.Text = ''
	window.Parent = clickgui
	addBlur(window)
	addCorner(window)
	addWindowStroke(window)
	makeDraggable(window)
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = categorysettings.Size
	icon.Position = UDim2.fromOffset(12, (icon.Size.X.Offset > 20 and 14 or 13))
	icon.BackgroundTransparency = 1
	icon.Image = categorysettings.Icon
	icon.ImageColor3 = uipallet.Text
	icon.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -(categorysettings.Size.X.Offset > 18 and 40 or 33), 0, 41)
	title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 0)
	title.BackgroundTransparency = 1
	title.Text = categorysettings.Name
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.Parent = window
	local pencilbutton = Instance.new('TextButton')
	pencilbutton.Name = 'EditModules'
	pencilbutton.Size = UDim2.fromOffset(20, 40)
	pencilbutton.Position = UDim2.new(1, -60, 0, 0)
	pencilbutton.BackgroundTransparency = 1
	pencilbutton.Text = ''
	pencilbutton.Visible = false
	pencilbutton.Parent = window
	addTooltip(pencilbutton, 'Edit hidden modules')
	local pencil = Instance.new('ImageLabel')
	pencil.Size = UDim2.fromOffset(12, 12)
	pencil.Position = UDim2.fromOffset(4, 14)
	pencil.BackgroundTransparency = 1
	pencil.Image = getcustomasset('ElevateV4/assets/new/edit.png')
	pencil.ImageColor3 = Color3.fromRGB(140, 140, 140)
	pencil.Parent = pencilbutton
	local hiddenCount = Instance.new('TextLabel')
	hiddenCount.Name = 'HiddenCount'
	hiddenCount.Size = UDim2.fromOffset(24, 41)
	hiddenCount.Position = UDim2.new(1, -84, 0, 0)
	hiddenCount.BackgroundTransparency = 1
	hiddenCount.Text = ''
	hiddenCount.TextColor3 = color.Dark(uipallet.Text, 0.16)
	hiddenCount.TextSize = 12
	hiddenCount.TextXAlignment = Enum.TextXAlignment.Right
	hiddenCount.FontFace = uipallet.Font
	hiddenCount.Visible = false
	hiddenCount.Parent = window
	local done = Instance.new('TextButton')
	done.Name = 'DoneEditing'
	done.Size = UDim2.fromOffset(44, 40)
	done.Position = UDim2.new(1, -84, 0, 0)
	done.BackgroundTransparency = 1
	done.Text = 'DONE'
	done.TextColor3 = Color3.fromRGB(140, 140, 140)
	done.TextSize = 12
	done.FontFace = uipallet.Font
	done.Visible = false
	done.Parent = window
	local arrowbutton = Instance.new('TextButton')
	arrowbutton.Name = 'Arrow'
	arrowbutton.Size = UDim2.fromOffset(40, 40)
	arrowbutton.Position = UDim2.new(1, -40, 0, 0)
	arrowbutton.BackgroundTransparency = 1
	arrowbutton.Text = ''
	arrowbutton.Parent = window
	local arrow = Instance.new('ImageLabel')
	arrow.Name = 'Arrow'
	arrow.Size = UDim2.fromOffset(9, 4)
	arrow.Position = UDim2.fromOffset(20, 18)
	arrow.BackgroundTransparency = 1
	arrow.Image = getcustomasset('ElevateV4/assets/new/expandup.png')
	arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
	arrow.Rotation = 180
	arrow.Parent = arrowbutton
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -41)
	children.Position = UDim2.fromOffset(0, 37)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.Visible = false
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local divider = Instance.new('Frame')
	divider.Name = 'Divider'
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.fromOffset(0, 37)
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.928
	divider.BorderSizePixel = 0
	divider.Visible = false
	divider.Parent = window
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Parent = children

	function categoryapi:CreateModule(modulesettings)
		mainapi:Remove(modulesettings.Name)
		local moduleapi = {
			Enabled = false,
			Hidden = false,
			Options = {},
			Bind = {},
			Tags = {},
			Index = getTableSize(mainapi.Modules),
			ExtraText = modulesettings.ExtraText,
			Name = modulesettings.Name,
			DisplayName = modulesettings.Name,
			Tooltip = modulesettings.Tooltip,
			Category = categorysettings.Name
		}

		local hovered = false
		local modulebutton = Instance.new('TextButton')
		modulebutton.Name = modulesettings.Name
		modulebutton.Size = UDim2.fromOffset(220, 40)
		modulebutton.BackgroundColor3 = uipallet.Main
		modulebutton.BorderSizePixel = 0
		modulebutton.AutoButtonColor = false
		modulebutton.Text = ''
		modulebutton.TextXAlignment = Enum.TextXAlignment.Left
		modulebutton.TextColor3 = color.Dark(uipallet.Text, 0.16)
		modulebutton.TextSize = 14
		modulebutton.FontFace = uipallet.Font
		modulebutton.Parent = children
		local moduletitle = Instance.new('TextButton')
		moduletitle.Name = 'Title'
		moduletitle.Size = UDim2.fromOffset(130, 40)
		moduletitle.Position = UDim2.fromOffset(13, 0)
		moduletitle.BackgroundTransparency = 1
		moduletitle.AutoButtonColor = false
		moduletitle.Text = moduleapi.DisplayName
		moduletitle.TextTruncate = Enum.TextTruncate.AtEnd
		moduletitle.TextXAlignment = Enum.TextXAlignment.Left
		moduletitle.TextColor3 = modulebutton.TextColor3
		moduletitle.TextSize = modulebutton.TextSize
		moduletitle.FontFace = modulebutton.FontFace
		moduletitle.Parent = modulebutton
		local indicatorholder = Instance.new('Frame')
		indicatorholder.Parent = modulebutton
		indicatorholder.Size = UDim2.fromOffset(0, 21)
		indicatorholder.AnchorPoint = Vector2.new(0, 0.5)
		indicatorholder.Name = 'Indicators'
		indicatorholder.BackgroundTransparency = 1
		indicatorholder.Position = UDim2.fromScale(0.85, 0.5)

		do
			local layout = Instance.new('UIListLayout')
			layout.Parent = indicatorholder
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			layout.VerticalAlignment = Enum.VerticalAlignment.Center
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.Padding = UDim.new(0, 5)
		end

		modulesettings.Tags = modulesettings.Tags or {}
		pcall(function()
			applyFeatureTags(modulesettings.Tags, moduleapi.Name)
			for i, tag in modulesettings.Tags do
				tag = tag:upper()
				local broken = tag == 'BROKEN'
				local size = getfontsize(removeTags(tag), 12, uipallet.Font, Vector2.new(100000, 100000))
				local indicator = Instance.new('TextLabel')
				indicator.LayoutOrder = i - 1
				indicator.Size = UDim2.new(0, size.X + 4, 0, 21)
				indicator.BackgroundColor3 = broken and BROKEN_TAG_COLOUR or Color3.new(1, 1, 1)
				indicator.TextSize = 14
				indicator.TextTransparency = 1
				indicator.Text = tag
				indicator.Name = tag
				indicator.Position = UDim2.new()
				indicator.TextColor3 = Color3.new(0, 0, 0)
				indicator.FontFace = uipallet.Font
				indicator.Parent = indicatorholder
				addCorner(indicator, UDim.new(0, 5))
				local text = indicator:Clone()
				text.Position = UDim2.new()
				text.Size = UDim2.fromScale(1, 1)
				text.BackgroundTransparency = 1
				text.Name = 'Text'
				text.AnchorPoint = Vector2.new()
				text.TextSize = 12
				text.TextTransparency = 0
				text.TextColor3 = broken and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
				text.Parent = indicator
				table.insert(moduleapi.Tags, indicator)
				indicator.Visible = tag ~= 'MATCHED'
			end
		end)
		local gradient = Instance.new('UIGradient')
		gradient.Rotation = 90
		gradient.Enabled = false
		gradient.Parent = modulebutton
		local edit = Instance.new('TextButton')
		edit.Name = 'Edit'
		edit.Size = UDim2.fromOffset(40, 40)
		edit.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
		edit.BackgroundTransparency = 0
		edit.BorderSizePixel = 0
		edit.Text = ''
		edit.Visible = false
		edit.Parent = modulebutton
		local editbox = Instance.new('Frame')
		editbox.Size = UDim2.fromOffset(8, 8)
		editbox.Position = UDim2.fromOffset(16, 16)
		editbox.BorderSizePixel = 0
		editbox.BackgroundColor3 = uipallet.Main
		editbox.Parent = edit
		addCorner(editbox, UDim.new(0, 2))
		local editstroke = Instance.new('UIStroke')
		editstroke.Name = 'State'
		editstroke.Thickness = 1
		editstroke.Color = color.Dark(uipallet.Text, 0.43)
		editstroke.Parent = editbox
		local modulechildren = Instance.new('Frame')
		local bind = Instance.new('TextButton')
		addTooltip(modulebutton, modulesettings.Tooltip)
		addTooltip(bind, 'Click to bind')
		bind.Name = 'Bind'
		bind.Size = UDim2.fromOffset(20, 21)
		bind.Position = UDim2.new(1, -36, 0, 9)
		bind.AnchorPoint = Vector2.new(1, 0)
		bind.BackgroundColor3 = Color3.new(1, 1, 1)
		bind.BackgroundTransparency = 0.92
		bind.BorderSizePixel = 0
		bind.AutoButtonColor = false
		bind.Visible = false
		bind.Text = ''
		addCorner(bind, UDim.new(0, 4))
		local bindicon = Instance.new('ImageLabel')
		bindicon.Name = 'Icon'
		bindicon.Size = UDim2.fromOffset(12, 12)
		bindicon.Position = UDim2.new(0.5, -6, 0, 5)
		bindicon.BackgroundTransparency = 1
		bindicon.Image = getcustomasset('ElevateV4/assets/new/bind.png')
		bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		bindicon.Parent = bind
		local bindtext = Instance.new('TextLabel')
		bindtext.Size = UDim2.fromScale(1, 1)
		bindtext.Position = UDim2.fromOffset(0, 1)
		bindtext.BackgroundTransparency = 1
		bindtext.Visible = false
		bindtext.Text = ''
		bindtext.TextColor3 = color.Dark(uipallet.Text, 0.43)
		bindtext.TextSize = 12
		bindtext.FontFace = uipallet.Font
		bindtext.Parent = bind
		local bindcover = Instance.new('ImageLabel')
		bindcover.Name = 'Cover'
		bindcover.Size = UDim2.fromOffset(154, 40)
		bindcover.BackgroundTransparency = 1
		bindcover.Visible = false
		bindcover.Image = getcustomasset('ElevateV4/assets/new/bindbkg.png')
		bindcover.ScaleType = Enum.ScaleType.Slice
		bindcover.SliceCenter = Rect.new(0, 0, 141, 40)
		bindcover.Parent = modulebutton
		local bindcovertext = Instance.new('TextLabel')
		bindcovertext.Name = 'Text'
		bindcovertext.Size = UDim2.new(1, -10, 1, -3)
		bindcovertext.BackgroundTransparency = 1
		bindcovertext.Text = 'PRESS A KEY TO BIND'
		bindcovertext.TextColor3 = uipallet.Text
		bindcovertext.TextSize = 11
		bindcovertext.FontFace = uipallet.Font
		bindcovertext.Parent = bindcover
		bind.Parent = modulebutton
		local dotsbutton = Instance.new('TextButton')
		dotsbutton.Name = 'Dots'
		dotsbutton.Size = UDim2.fromOffset(25, 40)
		dotsbutton.Position = UDim2.new(1, -25, 0, 0)
		dotsbutton.BackgroundTransparency = 1
		dotsbutton.Text = ''
		dotsbutton.Parent = modulebutton
		local dots = Instance.new('ImageLabel')
		dots.Name = 'Dots'
		dots.Size = UDim2.fromOffset(3, 16)
		dots.Position = UDim2.fromOffset(4, 12)
		dots.BackgroundTransparency = 1
		dots.Image = getcustomasset('ElevateV4/assets/new/dots.png')
		dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
		dots.Parent = dotsbutton
		modulechildren.Name = modulesettings.Name..'Children'
		modulechildren.Size = UDim2.new(1, 0, 0, 0)
		modulechildren.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
		modulechildren.BorderSizePixel = 0
		modulechildren.Visible = false
		modulechildren.Active = true
		modulechildren.Parent = children
		moduleapi.OptionsChildren = modulechildren
		moduleapi.Children = modulechildren
		if modulesettings.Size then
			local hudchildren = Instance.new('Frame')
			hudchildren.Name = modulesettings.Name..'HUD'
			hudchildren.Size = modulesettings.Size
			hudchildren.BackgroundTransparency = 1
			hudchildren.Visible = false
			hudchildren.Parent = scaledgui
			makeDraggable(hudchildren)
			moduleapi.Children = hudchildren
		end
		local windowlist = Instance.new('UIListLayout')
		windowlist.SortOrder = Enum.SortOrder.LayoutOrder
		windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		windowlist.Parent = modulechildren
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.Position = UDim2.new(0, 0, 1, -1)
		divider.BackgroundColor3 = Color3.new(0.19, 0.19, 0.19)
		divider.BackgroundTransparency = 0.52
		divider.BorderSizePixel = 0
		divider.Visible = false
		divider.Parent = modulebutton
		modulesettings.Function = modulesettings.Function or function() end
		addMaid(moduleapi)

		function moduleapi:SetDisplayName(displayName)
			self.DisplayName = tostring(displayName or self.Name)
			local shown = mainapi.NoModuleSpacing and mainapi.NoModuleSpacing.Enabled and self.DisplayName:gsub(' ', '') or self.DisplayName
			moduletitle.Text = shown
			moduletitle.Size = UDim2.fromOffset(math.min(getfontsize(shown, moduletitle.TextSize, moduletitle.FontFace).X + 4, 130), 40)
			if self.Bind.Button then self.Bind.Button.Text = shown end
		end
		moduleapi:SetDisplayName(moduleapi.DisplayName)

		function moduleapi:SetBind(tab, mouse)
			if tab.Mobile then
				createMobileButton(moduleapi, Vector2.new(tab.X, tab.Y))
				return
			end

			self.Bind = table.clone(tab)
			if mouse then
				bindcovertext.Text = #tab <= 0 and 'BIND REMOVED' or 'BOUND TO'
				bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 40)
				task.delay(1, function()
					bindcover.Visible = false
				end)
			end

			if #tab <= 0 then
				bindtext.Visible = false
				bindicon.Visible = true
				bind.Size = UDim2.fromOffset(20, 21)
			else
				bind.Visible = true
				bindtext.Visible = true
				bindicon.Visible = false
				bindtext.Text = table.concat(tab, ' + '):upper()
				bind.Size = UDim2.fromOffset(math.max(getfontsize(bindtext.Text, bindtext.TextSize, bindtext.Font).X + 10, 20), 21)
			end
		end

		local function updateModuleButtonVisual()
			local rainbow = mainapi.GUIColor.Rainbow and mainapi.RainbowMode.Value ~= 'Retro'
			gradient.Enabled = false

			if moduleapi.Enabled then
				modulebutton.BackgroundColor3 = rainbow and Color3.fromHSV(mainapi:Color((mainapi.GUIColor.Hue - (moduleapi.Index * 0.025)) % 1)) or Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
				modulebutton.TextColor3 = mainapi.GUIColor.Rainbow and Color3.new(0.19, 0.19, 0.19) or mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
				gradient.Enabled = rainbow and mainapi.RainbowMode.Value == 'Gradient'
				if gradient.Enabled then
					modulebutton.BackgroundColor3 = Color3.new(1, 1, 1)
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(mainapi:Color((mainapi.GUIColor.Hue - (moduleapi.Index * 0.025)) % 1))),
						ColorSequenceKeypoint.new(1, Color3.fromHSV(mainapi:Color((mainapi.GUIColor.Hue - ((moduleapi.Index + 1) * 0.025)) % 1)))
					})
				end
				dots.ImageColor3 = modulebutton.TextColor3
				bindicon.ImageColor3 = modulebutton.TextColor3
				bindtext.TextColor3 = modulebutton.TextColor3
		else
				modulebutton.TextColor3 = (hovered or modulechildren.Visible) and uipallet.Text or color.Dark(uipallet.Text, 0.16)
				modulebutton.BackgroundColor3 = (hovered or modulechildren.Visible) and color.Light(uipallet.Main, 0.02) or uipallet.Main
				dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
				bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
				bindtext.TextColor3 = color.Dark(uipallet.Text, 0.43)
			end
			moduletitle.TextColor3 = modulebutton.TextColor3
		end
		function moduleapi:RefreshVisual()
			updateModuleButtonVisual()
			local accent = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
			editbox.BackgroundColor3 = self.Hidden and uipallet.Main or accent
			editstroke.Color = self.Hidden and color.Dark(uipallet.Text, 0.43) or accent
		end

		function moduleapi:RefreshHiddenState(editing)
			if editing == nil then editing = mainapi.EditGUI == true end
			modulebutton.Visible = editing or not self.Hidden
			edit.Visible = editing
			modulebutton.Text = ''
			moduletitle.Position = UDim2.fromOffset(editing and 50 or 13, 0)
			if self.Hidden then modulechildren.Visible = false end
			self:RefreshVisual()
		end

		function moduleapi:SetHidden(hidden)
			self.Hidden = hidden and true or false
			self:RefreshHiddenState()
			if categoryapi.UpdateHidden then categoryapi:UpdateHidden() end
		end

		function moduleapi:Toggle(multiple)
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			self.Generation += 1
			local generation = self.Generation
			self.Enabled = not self.Enabled
			if mainapi.ScheduleSave then mainapi:ScheduleSave() end
			divider.Visible = self.Enabled
			if modulesettings.Size and self.Children then
				self.Children.Visible = self.Enabled
			end
			updateModuleButtonVisual()
			if not self.Enabled then self:Cleanup() end
			if not multiple then
				if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
			end
			local enabled = self.Enabled
			local currentThread = coroutine.running()
			if moduleapi.LifecycleThread and moduleapi.LifecycleThread ~= currentThread then
				pcall(task.cancel, moduleapi.LifecycleThread)
			end
			local token = {}
			moduleapi.LifecycleToken = token
			local lifecycleThread = coroutine.create(function()
				local ok, err = xpcall(function()
					modulesettings.Function(enabled)
				end, function(message) return tostring(message) end)
				if not ok and mainapi.RecordError then
					mainapi:RecordError(moduleapi.Name, err)
				end
				if moduleapi.LifecycleToken == token then
					moduleapi.LifecycleThread = nil
				end
			end)
			moduleapi.LifecycleThread = lifecycleThread
			task.spawn(lifecycleThread)
		end

		for i, v in components do
			moduleapi['Create'..i] = function(_, optionsettings)
				return mainapi:AttachContextualOption(v(optionsettings, modulechildren, moduleapi), optionsettings)
			end
		end

		bind.MouseEnter:Connect(function()
			bindtext.Visible = false
			bindicon.Visible = not bindtext.Visible
			bindicon.Image = getcustomasset('ElevateV4/assets/new/edit.png')
			if not moduleapi.Enabled then bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.16) end
		end)
		bind.MouseLeave:Connect(function()
			bindtext.Visible = #moduleapi.Bind > 0
			bindicon.Visible = not bindtext.Visible
			bindicon.Image = getcustomasset('ElevateV4/assets/new/bind.png')
			if not moduleapi.Enabled then
				bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
			end
		end)
		bind.MouseButton1Click:Connect(function()
			bindcovertext.Text = 'PRESS A KEY TO BIND'
			bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 40)
			bindcover.Visible = true
			mainapi.Binding = moduleapi
		end)
		edit.MouseButton1Click:Connect(function()
			moduleapi:SetHidden(not moduleapi.Hidden)
			mainapi:Save()
		end)
		dotsbutton.MouseEnter:Connect(function()
			if not moduleapi.Enabled then
				dots.ImageColor3 = uipallet.Text
			end
		end)
		dotsbutton.MouseLeave:Connect(function()
			if not moduleapi.Enabled then
				dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
			end
		end)
		dotsbutton.MouseButton1Click:Connect(function()
			modulechildren.Visible = not modulechildren.Visible
		end)
		dotsbutton.MouseButton2Click:Connect(function()
			modulechildren.Visible = not modulechildren.Visible
		end)
		local titleActive = mainapi:BindModuleTitle(moduleapi, moduletitle, function()
			if mainapi.EditGUI then return end
			if mainapi.PushUndo then mainapi:PushUndo(moduleapi) end
			moduleapi:Toggle()
		end, function()
			modulechildren.Visible = not modulechildren.Visible
		end)
		modulebutton.MouseEnter:Connect(function()
			hovered = true
			updateModuleButtonVisual()
			bind.Visible = #moduleapi.Bind > 0 or hovered or modulechildren.Visible
		end)
		modulebutton.MouseLeave:Connect(function()
			hovered = false
			updateModuleButtonVisual()
			bind.Visible = #moduleapi.Bind > 0 or hovered or modulechildren.Visible
		end)
		modulebutton.MouseButton1Click:Connect(function()
			if titleActive() then return end
			if mainapi.EditGUI then return end
			if mainapi.PushUndo then mainapi:PushUndo(moduleapi) end
			moduleapi:Toggle()
		end)
		modulebutton.MouseButton2Click:Connect(function()
			if titleActive() then return end
			modulechildren.Visible = not modulechildren.Visible
		end)
		if inputService.TouchEnabled then
			local heldbutton = false
			modulebutton.MouseButton1Down:Connect(function()
				heldbutton = true
				local holdtime, holdpos = tick(), inputService:GetMouseLocation()
				repeat
					heldbutton = (inputService:GetMouseLocation() - holdpos).Magnitude < 3
					task.wait()
				until (tick() - holdtime) > 1 or not heldbutton or not clickgui.Visible
				if heldbutton and clickgui.Visible then
					if mainapi.ThreadFix then
						setthreadidentity(8)
					end
					clickgui.Visible = false
					tooltip.Visible = false
					mainapi:BlurCheck()
					for _, mobileButton in mainapi.Modules do
						if mobileButton.Bind.Button then
							mobileButton.Bind.Button.Visible = true
						end
					end

					local touchconnection
					touchconnection = inputService.InputBegan:Connect(function(inputType)
						if inputType.UserInputType == Enum.UserInputType.Touch then
							if mainapi.ThreadFix then
								setthreadidentity(8)
							end
							createMobileButton(moduleapi, inputType.Position + Vector3.new(0, guiService:GetGuiInset().Y, 0))
							clickgui.Visible = true
							mainapi:BlurCheck()
							for _, mobileButton in mainapi.Modules do
								if mobileButton.Bind.Button then
									mobileButton.Bind.Button.Visible = false
								end
							end
							touchconnection:Disconnect()
						end
					end)
				end
			end)
			modulebutton.MouseButton1Up:Connect(function()
				heldbutton = false
			end)
		end
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			modulechildren.Size = UDim2.new(1, 0, 0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		end)

		moduleapi.Object = modulebutton
		mainapi.Modules[modulesettings.Name] = moduleapi
		moduleapi:RefreshHiddenState(mainapi.EditGUI == true)
		if categoryapi.UpdateHidden then categoryapi:UpdateHidden() end

		mainapi:QueueModuleLayout(moduleapi, categoryapi)

		return moduleapi
	end

	function categoryapi:Expand()
		if categorysettings.Profiles then
			refreshConfigProfiles()
			self:ChangeValue()
		end
		self.Expanded = not self.Expanded
		if self.Expanded then children.Visible = true end
		tween:Tween(window, unwindInfo, {
			Size = UDim2.fromOffset(220, self.Expanded and math.min(41 + windowlist.AbsoluteContentSize.Y / scale.Scale, 601) or 41)
		})
		tween:Tween(arrow, unwindInfo, {
			Rotation = self.Expanded and 0 or 180
		})
		if not self.Expanded then
			task.delay(unwindInfo.Time, function()
				if categoryapi.Expanded then return end
				children.Visible = false
				divider.Visible = false
			end)
		end
		divider.Visible = self.Expanded and children.CanvasPosition.Y > 10
	end

	function categoryapi:UpdateHidden()
		local count = 0
		for _, module in mainapi.Modules do
			if module.Category == categorysettings.Name and module.Hidden then count += 1 end
		end
		hiddenCount.Text = count > 0 and tostring(count) or ''
		hiddenCount.Visible = count > 0 and pencilbutton.Visible
		pencil.Image = getcustomasset('ElevateV4/assets/new/edit.png')
		local guiColor = mainapi.GUIColor
		pencil.ImageColor3 = count > 0 and guiColor
			and Color3.fromHSV(guiColor.Hue, guiColor.Sat, guiColor.Value)
			or Color3.fromRGB(140, 140, 140)
	end

	function categoryapi:SetEditMode(enabled)
		enabled = enabled == true
		self.EditMode = enabled
		for _, module in mainapi.Modules do
			if module.Category == categorysettings.Name then
				if module.RefreshHiddenState then
					module:RefreshHiddenState(enabled)
				else
					module.Object.Visible = enabled or not module.Hidden
					local edit = module.Object:FindFirstChild('Edit')
					if edit then edit.Visible = enabled end
				end
			end
		end
		done.Visible = enabled
		pencilbutton.Visible = not enabled and categoryHovered
		self:UpdateHidden()
	end

	arrowbutton.MouseButton1Click:Connect(function()
		categoryapi:Expand()
	end)
	arrowbutton.MouseButton2Click:Connect(function()
		categoryapi:Expand()
	end)
	arrowbutton.MouseEnter:Connect(function()
		arrow.ImageColor3 = Color3.fromRGB(220, 220, 220)
	end)
	arrowbutton.MouseLeave:Connect(function()
		arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
	end)
	pencilbutton.MouseButton1Click:Connect(function()
		mainapi.EditGUI = true
		for _, category in mainapi.Categories do
			if category.Type == 'Category' and category.SetEditMode then category:SetEditMode(true) end
		end
	end)
	pencilbutton.MouseEnter:Connect(function() pencil.ImageColor3 = Color3.fromRGB(220, 220, 220) end)
	pencilbutton.MouseLeave:Connect(function() pencil.ImageColor3 = Color3.fromRGB(140, 140, 140) end)
	done.MouseButton1Click:Connect(function()
		mainapi.EditGUI = false
		for _, category in mainapi.Categories do
			if category.Type == 'Category' and category.SetEditMode then category:SetEditMode(false) end
		end
		mainapi:Save()
	end)
	done.MouseEnter:Connect(function() done.TextColor3 = Color3.fromRGB(220, 220, 220) end)
	done.MouseLeave:Connect(function() done.TextColor3 = Color3.fromRGB(140, 140, 140) end)
	window.MouseEnter:Connect(function()
		categoryHovered = true
		pencilbutton.Visible = not mainapi.EditGUI
		categoryapi:UpdateHidden()
	end)
	window.MouseLeave:Connect(function()
		categoryHovered = false
		if not mainapi.EditGUI then
			pencilbutton.Visible = false
			hiddenCount.Visible = false
		end
	end)
	clickgui:GetPropertyChangedSignal('Visible'):Connect(function()
		if not clickgui.Visible then
			if mainapi.EditGUI then
				mainapi.EditGUI = false
				for _, category in mainapi.Categories do
					if category.Type == 'Category' and category.SetEditMode then category:SetEditMode(false) end
				end
				pcall(mainapi.Save, mainapi)
			end
			categoryHovered = false
			pencilbutton.Visible = false
			hiddenCount.Visible = false
			return
		end
		task.defer(function()
			if not clickgui.Visible or not window.Visible then return end
			local mouse = inputService:GetMouseLocation()
			local position, size = window.AbsolutePosition, window.AbsoluteSize
			categoryHovered = mouse.X >= position.X and mouse.X <= position.X + size.X
				and mouse.Y >= position.Y and mouse.Y <= position.Y + size.Y
			pencilbutton.Visible = categoryHovered and not mainapi.EditGUI
			categoryapi:UpdateHidden()
		end)
	end)
	children:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		divider.Visible = children.CanvasPosition.Y > 10 and children.Visible
	end)
	window.InputBegan:Connect(function(inputObj)
		if inputObj.Position.Y < window.AbsolutePosition.Y + 41 and inputObj.UserInputType == Enum.UserInputType.MouseButton2 then
			categoryapi:Expand()
		end
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		if categoryapi.Expanded then
			tween:Tween(window, unwindInfo, {
				Size = UDim2.fromOffset(220, math.min(41 + windowlist.AbsoluteContentSize.Y / scale.Scale, 601))
			})
		end
	end)

	if categorysettings.NoButton then
		categoryapi.Standalone = false
	else
		categoryapi.Button = self.Categories.Main:CreateButton({
			Name = categorysettings.Name,
			Icon = categorysettings.Icon,
			Size = categorysettings.Size,
			Window = window
		})
	end

	categoryapi.Object = window
	categoryapi.DefaultPosition = UDim2.fromOffset(defaultX, defaultY)
	self.Categories[categorysettings.Name] = categoryapi

	return categoryapi
end

function mainapi:CreateOverlay(categorysettings)
	local window
	local categoryapi
	categoryapi = {
		Type = 'Overlay',
		Expanded = false,
		Button = self.Overlays:CreateToggle({
			Name = categorysettings.Name,
			Function = function(callback)
				window.Visible = callback and (clickgui.Visible or categoryapi.Pinned)
				if not callback then
					for _, v in categoryapi.Connections do
						v:Disconnect()
					end
					table.clear(categoryapi.Connections)
				end

				if categorysettings.Function then
					task.spawn(categorysettings.Function, callback)
				end
			end,
			Icon = categorysettings.Icon,
			Size = categorysettings.Size,
			Position = categorysettings.Position
		}),
		Pinned = false,
		Options = {}
	}

	window = Instance.new('TextButton')
	window.Name = categorysettings.Name..'Overlay'
	window.Size = UDim2.fromOffset(categorysettings.CategorySize or 220, 41)
	window.Position = UDim2.fromOffset(240, 46)
	window.BackgroundColor3 = uipallet.Main
	window.AutoButtonColor = false
	window.Visible = false
	window.Text = ''
	window.Parent = scaledgui
	local blur = addBlur(window)
	addCorner(window)
	makeDraggable(window)
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = categorysettings.Size
	icon.Position = UDim2.fromOffset(12, (icon.Size.X.Offset > 14 and 14 or 13))
	icon.BackgroundTransparency = 1
	icon.Image = categorysettings.Icon
	icon.ImageColor3 = uipallet.Text
	icon.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -32, 0, 41)
	title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 0)
	title.BackgroundTransparency = 1
	title.Text = categorysettings.Name
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.Parent = window
	local pin = Instance.new('ImageButton')
	pin.Name = 'Pin'
	pin.Size = UDim2.fromOffset(16, 16)
	pin.Position = UDim2.new(1, -47, 0, 12)
	pin.BackgroundTransparency = 1
	pin.AutoButtonColor = false
	pin.Image = getcustomasset('ElevateV4/assets/new/pin.png')
	pin.ImageColor3 = color.Dark(uipallet.Text, 0.43)
	pin.Parent = window
	local dotsbutton = Instance.new('TextButton')
	dotsbutton.Name = 'Dots'
	dotsbutton.Size = UDim2.fromOffset(17, 40)
	dotsbutton.Position = UDim2.new(1, -17, 0, 0)
	dotsbutton.BackgroundTransparency = 1
	dotsbutton.Text = ''
	dotsbutton.Parent = window
	local dots = Instance.new('ImageLabel')
	dots.Name = 'Dots'
	dots.Size = UDim2.fromOffset(3, 16)
	dots.Position = UDim2.fromOffset(4, 12)
	dots.BackgroundTransparency = 1
	dots.Image = getcustomasset('ElevateV4/assets/new/dots.png')
	dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
	dots.Parent = dotsbutton
	local customchildren = Instance.new('Frame')
	customchildren.Name = 'CustomChildren'
	customchildren.Size = UDim2.new(1, 0, 0, 200)
	customchildren.Position = UDim2.fromScale(0, 1)
	customchildren.BackgroundTransparency = 1
	customchildren.Parent = window
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -41)
	children.Position = UDim2.fromOffset(0, 37)
	children.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	children.BorderSizePixel = 0
	children.Visible = false
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Parent = children
	addMaid(categoryapi)

	function categoryapi:Expand(check)
		if check and not blur.Visible then return end
		self.Expanded = not self.Expanded
		children.Visible = self.Expanded
		dots.ImageColor3 = self.Expanded and uipallet.Text or color.Light(uipallet.Main, 0.37)
		if self.Expanded then
			window.Size = UDim2.fromOffset(window.Size.X.Offset, math.min(41 + windowlist.AbsoluteContentSize.Y / scale.Scale, 601))
		else
			window.Size = UDim2.fromOffset(window.Size.X.Offset, 41)
		end
	end

	function categoryapi:Pin()
		self.Pinned = not self.Pinned
		pin.ImageColor3 = self.Pinned and uipallet.Text or color.Dark(uipallet.Text, 0.43)
	end

	function categoryapi:Update()
		window.Visible = self.Button.Enabled and (clickgui.Visible or self.Pinned)
		if self.Expanded then
			self:Expand()
		end
		if clickgui.Visible then
			window.Size = UDim2.fromOffset(window.Size.X.Offset, 41)
			window.BackgroundTransparency = 0
			blur.Visible = true
			icon.Visible = true
			title.Visible = true
			pin.Visible = true
			dotsbutton.Visible = true
		else
			window.Size = UDim2.fromOffset(window.Size.X.Offset, 0)
			window.BackgroundTransparency = 1
			blur.Visible = false
			icon.Visible = false
			title.Visible = false
			pin.Visible = false
			dotsbutton.Visible = false
		end
	end

	for i, v in components do
		categoryapi['Create'..i] = function(self, optionsettings)
			return mainapi:AttachContextualOption(v(optionsettings, children, categoryapi), optionsettings)
		end
	end

	dotsbutton.MouseEnter:Connect(function()
		if not children.Visible then
			dots.ImageColor3 = uipallet.Text
		end
	end)
	dotsbutton.MouseLeave:Connect(function()
		if not children.Visible then
			dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
		end
	end)
	dotsbutton.MouseButton1Click:Connect(function()
		categoryapi:Expand(true)
	end)
	dotsbutton.MouseButton2Click:Connect(function()
		categoryapi:Expand(true)
	end)
	pin.MouseButton1Click:Connect(function()
		categoryapi:Pin()
	end)
	window.MouseButton2Click:Connect(function()
		categoryapi:Expand(true)
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		if categoryapi.Expanded then
			window.Size = UDim2.fromOffset(window.Size.X.Offset, math.min(41 + windowlist.AbsoluteContentSize.Y / scale.Scale, 601))
		end
	end)
	self:Clean(clickgui:GetPropertyChangedSignal('Visible'):Connect(function()
		categoryapi:Update()
	end))

	if categorysettings.Color then
		local overlayColor = uipallet.Text
		local colorOpt
		local function closeColor(a, b)
			return math.abs(a.R - b.R) < 0.06 and math.abs(a.G - b.G) < 0.06 and math.abs(a.B - b.B) < 0.06
		end
		local function applyTo(inst)
			if inst:IsA('TextLabel') or inst:IsA('TextButton') then
				inst.TextColor3 = overlayColor
			elseif inst:IsA('ImageLabel') or inst:IsA('ImageButton') then
				inst.ImageColor3 = overlayColor
			end
		end
		local function tag(inst)
			if inst:GetAttribute('OverlayColored') ~= nil then return end
			local primary = false
			if inst:IsA('TextLabel') or inst:IsA('TextButton') then
				primary = closeColor(inst.TextColor3, uipallet.Text)
			elseif inst:IsA('ImageLabel') or inst:IsA('ImageButton') then
				primary = closeColor(inst.ImageColor3, uipallet.Text)
			end
			if primary then
				inst:SetAttribute('OverlayColored', true)
				applyTo(inst)
			end
		end
		local function recolor()
			for _, inst in window:GetDescendants() do
				if inst:GetAttribute('OverlayColored') then applyTo(inst) end
			end
		end
		for _, inst in window:GetDescendants() do tag(inst) end
		window.DescendantAdded:Connect(function(inst)
			task.defer(tag, inst)
		end)
		colorOpt = categoryapi:CreateColorSlider({
			Name = 'Overlay Color',
			DefaultHue = 0,
			DefaultSat = 0,
			DefaultValue = 1,
			Darker = true,
			Function = function()
				if not colorOpt then return end
				overlayColor = Color3.fromHSV(colorOpt.Hue, colorOpt.Sat, colorOpt.Value)
				recolor()
			end
		})
		categoryapi.ColorOption = colorOpt
	end

	categoryapi:Update()
	categoryapi.Object = window
	categoryapi.Children = customchildren
	self.Categories[categorysettings.Name] = categoryapi

	return categoryapi
end

function mainapi:CreateCategoryList(categorysettings)
	local displayName = categorysettings.DisplayName or categorysettings.Name
	local categoryapi = {
		Type = 'CategoryList',
		Expanded = false,
		List = {},
		ListEnabled = {},
		Objects = {},
		Options = {}
	}
	categorysettings.Color = categorysettings.Color or Color3.fromRGB(190, 115, 255)

	mainapi.CategorySlot = (mainapi.CategorySlot or 0) + 1
	local slot = mainapi.CategorySlot
	local defaultX = 6 + (slot % 8) * 230
	local defaultY = 60 + math.floor(slot / 8) * 360

	local window = Instance.new('TextButton')
	window.Name = displayName..'CategoryList'
	window.Size = UDim2.fromOffset(220, 45)
	window.Position = UDim2.fromOffset(defaultX, defaultY)
	window.BackgroundColor3 = uipallet.Main
	window.AutoButtonColor = false
	window.Visible = false
	window.Text = ''
	window.Parent = clickgui
	addBlur(window)
	addCorner(window)
	addWindowStroke(window)
	makeDraggable(window)
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = categorysettings.Size
	icon.Position = categorysettings.Position or UDim2.fromOffset(12, (categorysettings.Size.X.Offset > 20 and 13 or 12))
	icon.BackgroundTransparency = 1
	icon.Image = categorysettings.Icon
	icon.ImageColor3 = uipallet.Text
	icon.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -(categorysettings.Size.X.Offset > 20 and 44 or 36), 0, 20)
	title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 12)
	title.BackgroundTransparency = 1
	title.Text = displayName
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.Parent = window
	local arrowbutton = Instance.new('TextButton')
	arrowbutton.Name = 'Arrow'
	arrowbutton.Size = UDim2.fromOffset(40, 40)
	arrowbutton.Position = UDim2.new(1, -40, 0, 0)
	arrowbutton.BackgroundTransparency = 1
	arrowbutton.Text = ''
	arrowbutton.Parent = window
	local arrow = Instance.new('ImageLabel')
	arrow.Name = 'Arrow'
	arrow.Size = UDim2.fromOffset(9, 4)
	arrow.Position = UDim2.fromOffset(20, 19)
	arrow.BackgroundTransparency = 1
	arrow.Image = getcustomasset('ElevateV4/assets/new/expandup.png')
	arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
	arrow.Rotation = 180
	arrow.Parent = arrowbutton
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -45)
	children.Position = UDim2.fromOffset(0, 45)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.Visible = false
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local childrentwo = Instance.new('Frame')
	childrentwo.BackgroundTransparency = 1
	childrentwo.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	childrentwo.Visible = false
	childrentwo.Parent = children
	local settings = Instance.new('ImageButton')
	settings.Name = 'Settings'
	settings.Size = UDim2.fromOffset(16, 16)
	settings.Position = UDim2.new(1, -52, 0, 13)
	settings.BackgroundTransparency = 1
	settings.AutoButtonColor = false
	settings.Image = getcustomasset('ElevateV4/assets/new/customsettings.png')
	settings.ImageColor3 = color.Dark(uipallet.Text, 0.43)
	settings.Parent = window

	if categorysettings.Profiles then
		local downloadbtn = Instance.new('ImageButton')
		downloadbtn.Name = 'PresetDownload'
		downloadbtn.Size = UDim2.fromOffset(16, 16)
		downloadbtn.Position = UDim2.new(1, -74, 0, 13)
		downloadbtn.BackgroundTransparency = 1
		downloadbtn.AutoButtonColor = false
		downloadbtn.Image = getcustomasset('ElevateV4/assets/new/worldicon.png')
		downloadbtn.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		downloadbtn.Parent = window
		addTooltip(downloadbtn, 'Browse the configs in the repo')
		downloadbtn.MouseEnter:Connect(function() downloadbtn.ImageColor3 = uipallet.Text end)
		downloadbtn.MouseLeave:Connect(function() downloadbtn.ImageColor3 = color.Dark(uipallet.Text, 0.43) end)

		local LAYER_LIST, LAYER_WINDOW, LAYER_INNER, LAYER_TOP = 1, 2, 3, 4
		local OWNED_COLOUR = Color3.fromRGB(70, 190, 112)
		local function layer(root, band)
			root.ZIndex = band
			for _, descendant in root:GetDescendants() do
				if descendant:IsA('GuiObject') then descendant.ZIndex = band end
			end
		end

		local dl = Instance.new('Frame')
		dl.Name = 'PresetDownloader'
		dl.Size = UDim2.fromOffset(520, 430)
		dl.Position = UDim2.new(0.5, -260, 0.5, -215)
		dl.BackgroundColor3 = uipallet.Main
		dl.Visible = false
		dl.Parent = scaledgui
		addBlur(dl)
		addCorner(dl)
		addWindowStroke(dl)
		makeDraggable(dl)
		local dlmodal = Instance.new('TextButton')
		dlmodal.BackgroundTransparency = 1
		dlmodal.Text = ''
		dlmodal.Modal = true
		dlmodal.Parent = dl
		local dltitle = Instance.new('TextLabel')
		dltitle.Size = UDim2.new(1, -20, 0, 20)
		dltitle.Position = UDim2.fromOffset(16, 12)
		dltitle.BackgroundTransparency = 1
		dltitle.Text = 'Public Configs'
		dltitle.TextXAlignment = Enum.TextXAlignment.Left
		dltitle.TextColor3 = uipallet.Text
		dltitle.TextSize = 14
		dltitle.FontFace = uipallet.FontSemiBold
		dltitle.Parent = dl
		local dlsubtitle = dltitle:Clone()
		dlsubtitle.Name = 'Subtitle'
		dlsubtitle.Position = UDim2.fromOffset(16, 30)
		dlsubtitle.Size = UDim2.new(1, -50, 0, 14)
		dlsubtitle.Text = 'Loads straight away, no rejoin'
		dlsubtitle.TextColor3 = color.Dark(uipallet.Text, 0.4)
		dlsubtitle.TextSize = 11
		dlsubtitle.FontFace = uipallet.Font
		dlsubtitle.Parent = dl
		local dlclose = addCloseButton(dl)
		local dlsearchbkg = Instance.new('Frame')
		dlsearchbkg.Name = 'SearchBkg'
		dlsearchbkg.Size = UDim2.fromOffset(280, 26)
		dlsearchbkg.Position = UDim2.fromOffset(10, 52)
		dlsearchbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.03)
		dlsearchbkg.BorderSizePixel = 0
		dlsearchbkg.Parent = dl
		addCorner(dlsearchbkg)
		local dlsearch = Instance.new('TextBox')
		dlsearch.Size = UDim2.new(1, -16, 1, 0)
		dlsearch.Position = UDim2.fromOffset(8, 0)
		dlsearch.BackgroundTransparency = 1
		dlsearch.Text = ''
		dlsearch.PlaceholderText = 'Search by name or tag'
		dlsearch.TextXAlignment = Enum.TextXAlignment.Left
		dlsearch.TextColor3 = uipallet.Text
		dlsearch.PlaceholderColor3 = color.Dark(uipallet.Text, 0.35)
		dlsearch.TextSize = 12
		dlsearch.FontFace = uipallet.Font
		dlsearch.ClearTextOnFocus = false
		dlsearch.Parent = dlsearchbkg
		local dlstatus = Instance.new('TextLabel')
		dlstatus.Name = 'Status'
		dlstatus.Size = UDim2.new(1, -20, 0, 30)
		dlstatus.Position = UDim2.fromOffset(10, 86)
		dlstatus.BackgroundTransparency = 1
		dlstatus.Text = ''
		dlstatus.TextColor3 = color.Dark(uipallet.Text, 0.35)
		dlstatus.TextSize = 12
		dlstatus.FontFace = uipallet.Font
		dlstatus.Parent = dl
		local dllist = Instance.new('ScrollingFrame')
		dllist.Name = 'List'
		dllist.Size = UDim2.new(1, -20, 1, -136)
		dllist.Position = UDim2.fromOffset(10, 86)
		dllist.BackgroundTransparency = 1
		dllist.BorderSizePixel = 0
		dllist.ScrollBarThickness = 2
		dllist.ScrollBarImageTransparency = 0.75
		dllist.CanvasSize = UDim2.new()
		dllist.Parent = dl
		local dllayout = Instance.new('UIListLayout')
		dllayout.SortOrder = Enum.SortOrder.LayoutOrder
		dllayout.Padding = UDim.new(0, 6)
		dllayout.Parent = dllist
		dllayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			dllist.CanvasSize = UDim2.fromOffset(0, dllayout.AbsoluteContentSize.Y / scale.Scale)
		end)
		table.insert(mainapi.Windows, dl)

		local footer = Instance.new('Frame')
		footer.Name = 'Footer'
		footer.Size, footer.Position, footer.BackgroundTransparency, footer.Parent = UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 1, -38), 1, dl
		local function submissionButton(name, text, position, width, parent)
			local button = Instance.new('TextButton')
			button.Name, button.Size, button.Position = name, UDim2.fromOffset(width, 28), position
			button.BackgroundColor3 = color.Light(uipallet.Main, 0.05)
			button.Text, button.TextColor3, button.TextSize, button.FontFace = text, uipallet.Text, 12, uipallet.Font
			button.AutoButtonColor = true
			button.Parent = parent or footer
			addCorner(button, UDim.new(0, 5))
			return button
		end
		local publishButton = submissionButton('Publish', 'Publish on the website', UDim2.fromOffset(0, 2), 170)
		local sourceLabel = Instance.new('TextLabel')
		sourceLabel.Name, sourceLabel.Size, sourceLabel.Position, sourceLabel.BackgroundTransparency = 'Source', UDim2.new(1, -180, 0, 28), UDim2.fromOffset(180, 2), 1
		sourceLabel.Text, sourceLabel.TextColor3, sourceLabel.TextSize, sourceLabel.FontFace = '', color.Dark(uipallet.Text, 0.4), 11, uipallet.Font
		sourceLabel.TextXAlignment, sourceLabel.TextTruncate, sourceLabel.Parent = Enum.TextXAlignment.Right, Enum.TextTruncate.AtEnd, footer
		local sortModes = {
			{Key = 'trending', Label = 'Trending'},
			{Key = 'downloads', Label = 'Most Downloaded'},
			{Key = 'rating', Label = 'Highest Rated'},
			{Key = 'new', Label = 'Newest'},
			{Key = 'updated', Label = 'Recently Updated'}
		}
		local sortIndex = 1
		local sortButton = submissionButton('Sort', 'Sort: '..sortModes[sortIndex].Label, UDim2.fromOffset(298, 52), 176, dl)
		local refreshButton = submissionButton('Refresh', '↻', UDim2.fromOffset(480, 52), 30, dl)
		layer(dl, LAYER_LIST)
		dlstatus.ZIndex = LAYER_WINDOW
		addTooltip(publishButton, 'Copies the dashboard link. Sign in with Discord there to publish or update a config')
		publishButton.MouseButton1Click:Connect(function()
			local url = configapi.Presets.Api..'/community'
			if setclipboard then
				pcall(setclipboard, url)
				mainapi:CreateNotification('Configs', 'Dashboard link copied. Open it in your browser to publish a config.', 7, 'info')
			else
				mainapi:CreateNotification('Configs', 'Publish configs at '..url, 10, 'info')
			end
		end)
		local refresh
		sortButton.MouseButton1Click:Connect(function()
			sortIndex = sortIndex % #sortModes + 1
			sortButton.Text = 'Sort: '..sortModes[sortIndex].Label
			if refresh then refresh() end
		end)
		addTooltip(sortButton, 'Choose how the Public Config catalogue is ranked')

		local refreshRows
		local downloading = {}
		local function download(preset)
			if downloading[preset.file] then return end
			downloading[preset.file] = true
			dlstatus.Text = 'Fetching '..tostring(preset.name)..'...'
			dlstatus.Visible = true
			task.spawn(function()
				local ok, res, version = pcall(function()
					return configapi.Presets.Fetch(preset.file)
				end)
				if version then preset.version = version end
				if not ok or not res or res == '404: Not Found' then
					downloading[preset.file] = nil
					dlstatus.Visible = false
					mainapi:CreateNotification('Configs', 'Could not download '..tostring(preset.name)..'.', 7, 'alert')
					return
				end
				local suc, result = importJsonConfig(res, preset.name)
				downloading[preset.file] = nil
				dlstatus.Visible = false
				if suc then
					configapi.Presets.Remember(tostring(result), preset, true)
					refreshConfigProfiles()
					categoryapi:ChangeValue()
					refreshRows()
					mainapi:CreateNotification('Configs', tostring(result)..' is loaded and active', 5, 'info')
				else
					mainapi:CreateNotification('Configs', tostring(result), 8, 'alert')
				end
			end)
		end

		local months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'}
		local function formatDate(value)
			if type(value) == 'number' then value = os.date('!%Y-%m-%d', math.floor(value / 1000)) end
			local year, month, day = tostring(value or ''):match('^(%d%d%d%d)%-(%d%d)%-(%d%d)')
			return year and (day..' '..(months[tonumber(month)] or month)..' '..year) or 'date unknown'
		end
		local function compactCount(value)
			local number = math.max(0, tonumber(value) or 0)
			local function rounded(divisor, suffix)
				return string.format('%.1f', number / divisor):gsub('%.0$', '')..suffix
			end
			if number >= 1000000 then return rounded(1000000, 'm') end
			if number >= 1000 then return rounded(1000, 'k') end
			return tostring(math.floor(number))
		end

		local detailsWindow = Instance.new('Frame')
		detailsWindow.Name, detailsWindow.Size, detailsWindow.Position = 'ConfigDetails', UDim2.fromOffset(520, 410), UDim2.new(0.5, -260, 0.5, -205)
		detailsWindow.BackgroundColor3, detailsWindow.Visible, detailsWindow.Parent = uipallet.Main, false, scaledgui
		addBlur(detailsWindow); addCorner(detailsWindow); addWindowStroke(detailsWindow); makeDraggable(detailsWindow)
		local detailsTitle = Instance.new('TextLabel')
		detailsTitle.Size, detailsTitle.Position, detailsTitle.BackgroundTransparency = UDim2.new(1, -52, 0, 28), UDim2.fromOffset(16, 8), 1
		detailsTitle.TextColor3, detailsTitle.TextSize, detailsTitle.FontFace = uipallet.Text, 16, uipallet.FontSemiBold
		detailsTitle.TextXAlignment, detailsTitle.Parent = Enum.TextXAlignment.Left, detailsWindow
		addCloseButton(detailsWindow).MouseButton1Click:Connect(function() detailsWindow.Visible = false end)
		local detailsSubtitle = detailsTitle:Clone()
		detailsSubtitle.Size, detailsSubtitle.Position = UDim2.new(1, -32, 0, 18), UDim2.fromOffset(16, 38)
		detailsSubtitle.TextColor3, detailsSubtitle.TextSize, detailsSubtitle.FontFace = color.Dark(uipallet.Text, 0.32), 11, uipallet.Font
		detailsSubtitle.Parent = detailsWindow
		local detailsScroll = Instance.new('ScrollingFrame')
		detailsScroll.Size, detailsScroll.Position = UDim2.new(1, -28, 1, -118), UDim2.fromOffset(14, 66)
		detailsScroll.BackgroundColor3, detailsScroll.BorderSizePixel = color.Light(uipallet.Main, 0.025), 0
		detailsScroll.ScrollBarThickness, detailsScroll.ScrollBarImageTransparency = 2, 0.7
		detailsScroll.CanvasSize, detailsScroll.AutomaticCanvasSize, detailsScroll.Parent = UDim2.new(), Enum.AutomaticSize.Y, detailsWindow
		addCorner(detailsScroll)
		local detailsBody = Instance.new('TextLabel')
		detailsBody.Size, detailsBody.Position, detailsBody.AutomaticSize = UDim2.new(1, -20, 0, 0), UDim2.fromOffset(10, 10), Enum.AutomaticSize.Y
		detailsBody.BackgroundTransparency, detailsBody.TextWrapped, detailsBody.TextXAlignment, detailsBody.TextYAlignment = 1, true, Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
		detailsBody.TextColor3, detailsBody.TextSize, detailsBody.FontFace, detailsBody.Parent = color.Dark(uipallet.Text, 0.12), 12, uipallet.Font, detailsScroll
		local detailsLike = submissionButton('Like', 'Like', UDim2.fromOffset(14, 370), 92, detailsWindow)
		local detailsDislike = submissionButton('Dislike', 'Dislike', UDim2.fromOffset(112, 370), 92, detailsWindow)
		local detailsDownload = submissionButton('DownloadConfig', 'Download', UDim2.new(1, -106, 0, 370), 92, detailsWindow)
		addTooltip(detailsLike, 'Needs a link code in GUI settings > General')
		layer(detailsWindow, LAYER_WINDOW)
		table.insert(mainapi.Windows, detailsWindow)

		local activeDetailsPreset
		local rate
		local function detailsText(preset, versions, loading)
			local ratingCount = tonumber(preset.ratingCount) or 0
			local rating = ratingCount > 0 and preset.ratingPercentage and (tostring(preset.ratingPercentage)..'% positive from '..tostring(ratingCount)..' votes') or 'Unrated'
			local lines = {
				tostring(preset.description or 'No description provided.'),
				'',
				'Tags: '..((preset.tags and #preset.tags > 0) and table.concat(preset.tags, ' • ') or 'None'),
				'Updated: '..formatDate(preset.updatedAt),
				'Rating: '..rating,
				'',
				'Version history'
			}
			if loading then
				table.insert(lines, 'Loading...')
			elseif type(versions) == 'table' and #versions > 0 then
				for index = 1, math.min(#versions, 8) do
					local version = versions[index]
					table.insert(lines, 'v'..tostring(version.version)..' • '..formatDate(version.createdAt)..(version.changelog and version.changelog ~= '' and ('\n'..tostring(version.changelog)) or ''))
				end
			else
				table.insert(lines, 'No version history available.')
			end
			return table.concat(lines, '\n')
		end
		local function paintDetailsRatings(preset)
			local accent = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
			local accentText = mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
			detailsLike.Text, detailsDislike.Text = 'Like '..compactCount(preset.likes), 'Dislike '..compactCount(preset.dislikes)
			detailsLike.BackgroundColor3 = tonumber(preset.userRating) == 1 and accent or color.Light(uipallet.Main, 0.05)
			detailsDislike.BackgroundColor3 = tonumber(preset.userRating) == -1 and accent or color.Light(uipallet.Main, 0.05)
			detailsLike.TextColor3 = tonumber(preset.userRating) == 1 and accentText or uipallet.Text
			detailsDislike.TextColor3 = tonumber(preset.userRating) == -1 and accentText or uipallet.Text
			detailsLike.Visible, detailsDislike.Visible = preset.fromApi == true and not preset.owned, preset.fromApi == true and not preset.owned
		end
		local function openDetails(preset)
			activeDetailsPreset = preset
			detailsTitle.Text = tostring(preset.name)..'  v'..tostring(preset.version or 1)
			detailsSubtitle.Text = 'By '..tostring(preset.credits or '?')..'  •  '..compactCount(preset.downloads)..' downloads'..(preset.owned and '  •  yours' or '')
			detailsBody.Text = detailsText(preset, nil, preset.fromApi == true)
			paintDetailsRatings(preset)
			detailsWindow.Visible = true
			if not preset.fromApi then return end
			task.spawn(function()
				local success, result = configapi.Presets.Request('GET', '/api/configs/'..httpService:UrlEncode(tostring(preset.id)))
				if activeDetailsPreset ~= preset then return end
				detailsBody.Text = detailsText(preset, success and type(result) == 'table' and result.versions or nil, false)
			end)
		end
		detailsLike.MouseButton1Click:Connect(function() if activeDetailsPreset and rate then rate(activeDetailsPreset, 1) end end)
		detailsDislike.MouseButton1Click:Connect(function() if activeDetailsPreset and rate then rate(activeDetailsPreset, -1) end end)
		detailsDownload.MouseButton1Click:Connect(function() if activeDetailsPreset then download(activeDetailsPreset) end end)

		local rowbuttons = {}
		function refreshRows()
			for _, entry in rowbuttons do
				local installed = isfile(getConfigPath(entry.Name))
				local recorded = installed and configapi.Presets.Get(entry.Name) or nil
				local published = tonumber(entry.Version)
				local behind = recorded and published and tonumber(recorded.version) and tonumber(recorded.version) < published
				entry.Button.Text = behind and ('Update to v'..published) or (installed and 'Redownload' or 'Download')
				entry.Button.BackgroundColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
				entry.Button.TextColor3 = mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
			end
		end

		local ratingInFlight = {}
		rate = function(preset, value)
			if ratingInFlight[preset.id] or not preset.fromApi then return end
			if not configapi.Presets.Link():match('^alk_') then
				mainapi:CreateNotification('Configs', 'Link your website account first: make a link code on the dashboard and paste it into GUI settings > General.', 9, 'alert')
				return
			end
			if tonumber(preset.userRating) == value then value = 0 end
			ratingInFlight[preset.id] = true
			task.spawn(function()
				local success, result = configapi.Presets.Request('POST', '/api/configs/'..httpService:UrlEncode(tostring(preset.id))..'/vote', {value = value})
				ratingInFlight[preset.id] = nil
				if success and type(result) == 'table' then
					preset.likes, preset.dislikes, preset.userRating = result.likes or preset.likes, result.dislikes or preset.dislikes, result.myVote
					local votes = (tonumber(preset.likes) or 0) + (tonumber(preset.dislikes) or 0)
					preset.ratingCount = votes
					preset.ratingPercentage = votes > 0 and math.floor((tonumber(preset.likes) or 0) / votes * 100 + 0.5) or nil
					if activeDetailsPreset == preset then
						paintDetailsRatings(preset)
						detailsBody.Text = detailsText(preset, nil, false)
					end
				else
					mainapi:CreateNotification('Configs', tostring(result or 'Could not save your vote.'), 7, 'alert')
				end
			end)
		end

		local function makeRow(preset)
			if isfile(getConfigPath(tostring(preset.name))) then
				configapi.Presets.Remember(tostring(preset.name), preset)
			end
			local row = Instance.new('Frame')
			row.Name = tostring(preset.name)
			row:SetAttribute('Tags', (preset.tags and table.concat(preset.tags, ' ') or '')..' '..tostring(preset.credits or '')..' '..tostring(preset.description or ''))
			row.Size = UDim2.new(1, 0, 0, 64)
			row.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			row.Parent = dllist
			addCorner(row)
			if preset.description then
				addTooltip(row, tostring(preset.description), 360)
			end
			local actionWidth = 100
			local openArea = Instance.new('TextButton')
			openArea.Name, openArea.Size, openArea.BackgroundTransparency, openArea.Text = 'OpenDetails', UDim2.new(1, -actionWidth, 1, 0), 1, ''
			openArea.AutoButtonColor, openArea.Parent = false, row
			openArea.MouseButton1Click:Connect(function() openDetails(preset) end)
			openArea.MouseEnter:Connect(function() row.BackgroundColor3 = color.Light(uipallet.Main, 0.04) end)
			openArea.MouseLeave:Connect(function() row.BackgroundColor3 = color.Light(uipallet.Main, 0.02) end)
			local name = Instance.new('TextLabel')
			name.Size = UDim2.new(1, -actionWidth - 8, 0, 18)
			name.Position = UDim2.fromOffset(12, 6)
			name.BackgroundTransparency = 1
			name.Text = tostring(preset.name)..'  v'..tostring(preset.version or 1)
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.TextTruncate = Enum.TextTruncate.AtEnd
			name.TextColor3 = uipallet.Text
			name.TextSize = 13
			name.FontFace = uipallet.Font
			name.Parent = row
			local tagline = name:Clone()
			tagline.Size = UDim2.new(1, -actionWidth - 8, 0, 14)
			tagline.Position = UDim2.fromOffset(12, 24)
			local ratingText = (tonumber(preset.ratingCount) or 0) > 0 and preset.ratingPercentage and (tostring(preset.ratingPercentage)..'% positive') or 'unrated'
			tagline.Text = compactCount(preset.downloads)..' downloads • '..ratingText..' • '..formatDate(preset.updatedAt)
			tagline.TextColor3 = color.Dark(uipallet.Text, 0.31)
			tagline.TextSize = 11
			tagline.Parent = row
			local tags = tagline:Clone()
			tags.Position = UDim2.fromOffset(12, 42)
			local listed = (preset.tags and #preset.tags > 0) and table.concat(preset.tags, ' • ') or ('By '..tostring(preset.credits or '?'))
			tags.Text = preset.owned and ('Yours  •  '..listed) or listed
			tags.TextColor3 = preset.owned and OWNED_COLOUR or tagline.TextColor3
			tags.TextTruncate = Enum.TextTruncate.AtEnd
			tags.Parent = row
			local downloadButton = Instance.new('TextButton')
			downloadButton.Size = UDim2.fromOffset(84, 26)
			downloadButton.Position = UDim2.new(1, -10, 0, 19)
			downloadButton.AnchorPoint = Vector2.new(1, 0)
			downloadButton.BackgroundColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
			downloadButton.Text = isfile(getConfigPath(tostring(preset.name))) and 'Redownload' or 'Download'
			downloadButton.TextColor3 = uipallet.Text
			downloadButton.TextSize = 12
			downloadButton.FontFace = uipallet.Font
			downloadButton.AutoButtonColor = true
			downloadButton.Parent = row
			addCorner(downloadButton, UDim.new(0, 5))
			downloadButton.MouseButton1Click:Connect(function() download(preset) end)
			layer(row, LAYER_LIST)
			rowbuttons[tostring(preset.file)] = {Name = tostring(preset.name), Button = downloadButton, Version = tonumber(preset.version)}
		end

		local function applyFilter()
			local query = dlsearch.Text:lower():gsub('%s+', '')
			for _, v in dllist:GetChildren() do
				if v:IsA('Frame') then
					local haystack = (v.Name..(v:GetAttribute('Tags') or '')):lower():gsub('%s+', '')
					v.Visible = query == '' or haystack:find(query, 1, true) ~= nil
				end
			end
		end
		dlsearch:GetPropertyChangedSignal('Text'):Connect(applyFilter)

		local refreshing = false
		function refresh()
			if refreshing then return end
			refreshing = true
			for _, v in dllist:GetChildren() do
				if v:IsA('Frame') then v:Destroy() end
			end
			table.clear(rowbuttons)
			dlstatus.Text = 'Loading configs...'
			dlstatus.Visible = true
			task.spawn(function()
				local ok, res = pcall(function()
					return configapi.Presets.FetchList(sortModes[sortIndex].Key)
				end)
				refreshing = false
				if not ok or not res or res == '404: Not Found' then
					dlstatus.Text = 'Could not reach the config backend. Check your connection and refresh'
					mainapi:CreateNotification('Configs', 'Could not fetch the config list.', 7, 'alert')
					return
				end
				local decoded = select(2, pcall(function() return httpService:JSONDecode(res) end))
				if type(decoded) ~= 'table' or type(decoded.presets) ~= 'table' then
					dlstatus.Text = 'The config list is malformed'
					return
				end
				sourceLabel.Text = 'Live from the ElevateV4 backend'
				if #decoded.presets == 0 then
					dlstatus.Text = 'No configs published for this game yet'
					return
				end
				dlstatus.Visible = false
				for _, preset in decoded.presets do
					pcall(makeRow, preset)
				end
				refreshRows()
				applyFilter()
			end)
		end

		refreshButton.MouseButton1Click:Connect(refresh)
		addTooltip(refreshButton, 'Fetch the latest Public Config catalogue')

		function mainapi.OpenRepoConfigs()
			clickgui.Visible = false
			dl.Visible = true
			dl.Position = UDim2.new(0.5, -260, 0.5, -215)
			refresh()
		end

		downloadbtn.MouseButton1Click:Connect(mainapi.OpenRepoConfigs)
		dlclose.MouseButton1Click:Connect(function()
			dl.Visible = false
			clickgui.Visible = true
		end)

		local sync = Instance.new('Frame')
		sync.Name = 'PresetSync'
		sync.LayoutOrder = 1000
		sync.Size = UDim2.fromOffset(200, 66)
		sync.BackgroundTransparency = 1
		sync.Visible = false
		sync.Parent = children
		local syncdivider = Instance.new('Frame')
		syncdivider.Name = 'Divider'
		syncdivider.Size = UDim2.new(1, 0, 0, 1)
		syncdivider.Position = UDim2.fromOffset(0, 6)
		syncdivider.BackgroundColor3 = Color3.new(1, 1, 1)
		syncdivider.BackgroundTransparency = 0.9
		syncdivider.BorderSizePixel = 0
		syncdivider.Parent = sync
		local synclabel = Instance.new('TextLabel')
		synclabel.Name = 'Label'
		synclabel.Size = UDim2.new(1, 0, 0, 14)
		synclabel.Position = UDim2.fromOffset(0, 14)
		synclabel.BackgroundTransparency = 1
		synclabel.Text = 'Preset config'
		synclabel.TextXAlignment = Enum.TextXAlignment.Left
		synclabel.TextColor3 = color.Dark(uipallet.Text, 0.4)
		synclabel.TextSize = 11
		synclabel.TextTruncate = Enum.TextTruncate.AtEnd
		synclabel.FontFace = uipallet.Font
		synclabel.Parent = sync
		local syncbutton = Instance.new('TextButton')
		syncbutton.Name = 'SyncButton'
		syncbutton.Size = UDim2.new(1, 0, 0, 28)
		syncbutton.Position = UDim2.fromOffset(0, 32)
		syncbutton.BackgroundColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		syncbutton.AutoButtonColor = true
		syncbutton.Text = 'Sync to Config'
		syncbutton.TextColor3 = uipallet.Text
		syncbutton.TextSize = 13
		syncbutton.FontFace = uipallet.Font
		syncbutton.Parent = sync
		addCorner(syncbutton, UDim.new(0, 5))
		addTooltip(syncbutton, 'Re-download this preset and apply it')
		mainapi.PresetSyncButton = syncbutton

		local syncing = false
		local function refreshSync()
			local entry = configapi.Presets.Get(mainapi.Profile)
			sync.Visible = entry ~= nil
			if not entry then return end
			synclabel.Text = 'Preset - '..tostring(entry.name or mainapi.Profile)
			if syncing then return end
			syncbutton.BackgroundColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
			syncbutton.TextColor3 = mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		end
		categoryapi.RefreshPresetSync = refreshSync

		syncbutton.MouseButton1Click:Connect(function()
			if syncing then return end
			local name = mainapi.Profile
			local entry = configapi.Presets.Get(name)
			if not entry then
				refreshSync()
				return
			end
			syncing = true
			syncbutton.Text = 'Syncing...'
			task.spawn(function()
				local ok, res, version = pcall(function()
					return configapi.Presets.Fetch(entry.file)
				end)
				local suc, result
				if ok and res and res ~= '404: Not Found' then
					suc, result = importJsonConfig(res, name)
				end
				syncing = false
				syncbutton.Text = 'Sync to Config'
				if suc then
					configapi.Presets.Remember(tostring(result), {file = entry.file, name = entry.name, version = version or entry.version}, true)
					refreshConfigProfiles()
					categoryapi:ChangeValue()
					if refreshRows then refreshRows() end
					mainapi:CreateNotification('Configs', tostring(result)..' is back in sync with the published version', 5, 'info')
				else
					refreshSync()
					mainapi:CreateNotification('Configs', result and tostring(result) or ('Could not re-download '..name..'.'), 7, 'alert')
				end
			end)
		end)
	end

	local divider = Instance.new('Frame')
	divider.Name = 'Divider'
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.fromOffset(0, 41)
	divider.BorderSizePixel = 0
	divider.Visible = false
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.928
	divider.Parent = window
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Padding = UDim.new(0, 3)
	windowlist.Parent = children
	local windowlisttwo = Instance.new('UIListLayout')
	windowlisttwo.SortOrder = Enum.SortOrder.LayoutOrder
	windowlisttwo.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlisttwo.Padding = UDim.new(0, 4)
	windowlisttwo.Parent = childrentwo
	local childrentwopadding = Instance.new('UIPadding')
	childrentwopadding.PaddingTop = UDim.new(0, 6)
	childrentwopadding.PaddingBottom = UDim.new(0, 6)
	childrentwopadding.Parent = childrentwo
	local addbkg = Instance.new('Frame')
	addbkg.Name = 'Add'
	addbkg.Size = UDim2.fromOffset(200, 31)
	addbkg.Position = UDim2.fromOffset(10, 45)
	addbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
	addbkg.Parent = children
	addCorner(addbkg)
	local addbox = addbkg:Clone()
	addbox.Size = UDim2.new(1, -2, 1, -2)
	addbox.Position = UDim2.fromOffset(1, 1)
	addbox.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	addbox.Parent = addbkg
	local addvalue = Instance.new('TextBox')
	addvalue.Size = UDim2.new(1, -35, 1, 0)
	addvalue.Position = UDim2.fromOffset(10, 0)
	addvalue.BackgroundTransparency = 1
	addvalue.Text = ''
	addvalue.PlaceholderText = categorysettings.Placeholder or 'Add entry...'
	addvalue.TextXAlignment = Enum.TextXAlignment.Left
	addvalue.TextColor3 = Color3.new(1, 1, 1)
	addvalue.TextSize = 15
	addvalue.FontFace = uipallet.Font
	addvalue.ClearTextOnFocus = false
	addvalue.Parent = addbkg
	local addbutton = Instance.new('ImageButton')
	addbutton.Name = 'AddButton'
	addbutton.Size = UDim2.fromOffset(16, 16)
	addbutton.Position = UDim2.new(1, -26, 0, 8)
	addbutton.BackgroundTransparency = 1
	addbutton.Image = getcustomasset('ElevateV4/assets/new/add.png')
	addbutton.ImageColor3 = categorysettings.Color
	addbutton.ImageTransparency = 0.3
	addbutton.Parent = addbkg
	local cursedpadding = Instance.new('Frame')
	cursedpadding.Size = UDim2.fromOffset()
	cursedpadding.BackgroundTransparency = 1
	cursedpadding.Parent = children
	categorysettings.Function = categorysettings.Function or function() end

	function categoryapi:ChangeValue(val)
		if val then
			if categorysettings.Profiles then
				val = val:gsub('^%s*(.-)%s*$', '%1')
				if val == '' then return end
				local ind = self:GetValue(val)
				if ind then
					if val ~= 'default' then
						table.remove(mainapi.Profiles, ind)
						if isfile(getConfigPath(val)) and delfile then
							delfile(getConfigPath(val))
						end
						if mainapi.Profile == val then
							mainapi.Profile = 'default'
						end
						mainapi:Save(mainapi.Profile)
					end
				else
					table.insert(mainapi.Profiles, {Name = val, Bind = {}})
					mainapi:Save(val)
					mainapi:Load(true, val)
					mainapi:Save(val)
				end
			else
				local ind = table.find(self.List, val)
				if ind then
					table.remove(self.List, ind)
					ind = table.find(self.ListEnabled, val)
					if ind then
						table.remove(self.ListEnabled, ind)
					end
				else
					table.insert(self.List, val)
					table.insert(self.ListEnabled, val)
				end
			end
		end

		categorysettings.Function()
		for _, v in self.Objects do
			v:Destroy()
		end
		table.clear(self.Objects)
		self.Selected = nil

		for i, v in (categorysettings.Profiles and mainapi.Profiles or self.List) do
			if categorysettings.Profiles then
				local object = Instance.new('TextButton')
				object.Name = v.Name
				object.Size = UDim2.fromOffset(200, 33)
				object.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
				object.AutoButtonColor = false
				object.Text = ''
				object.Parent = children
				addCorner(object)
				local objectstroke = Instance.new('UIStroke')
				objectstroke.Color = color.Light(uipallet.Main, 0.1)
				objectstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				objectstroke.Enabled = false
				objectstroke.Parent = object
				local objecttitle = Instance.new('TextLabel')
				objecttitle.Name = 'Title'
				objecttitle.Size = UDim2.new(1, -10, 1, 0)
				objecttitle.Position = UDim2.fromOffset(10, 0)
				objecttitle.BackgroundTransparency = 1
				objecttitle.Text = v.Name
				objecttitle.TextXAlignment = Enum.TextXAlignment.Left
				objecttitle.TextColor3 = color.Dark(uipallet.Text, 0.4)
				objecttitle.TextSize = 15
				objecttitle.FontFace = uipallet.Font
				objecttitle.Parent = object
				local dotsbutton = Instance.new('TextButton')
				dotsbutton.Name = 'Dots'
				dotsbutton.Size = UDim2.fromOffset(25, 33)
				dotsbutton.Position = UDim2.new(1, -25, 0, 0)
				dotsbutton.BackgroundTransparency = 1
				dotsbutton.Text = ''
				dotsbutton.Parent = object
				local dots = Instance.new('ImageLabel')
				dots.Name = 'Dots'
				dots.Size = UDim2.fromOffset(3, 16)
				dots.Position = UDim2.fromOffset(10, 9)
				dots.BackgroundTransparency = 1
				dots.Image = getcustomasset('ElevateV4/assets/new/dots.png')
				dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
				dots.Parent = dotsbutton
				local bind = Instance.new('TextButton')
				addTooltip(bind, 'Click to bind')
				bind.Name = 'Bind'
				bind.Size = UDim2.fromOffset(20, 21)
				bind.Position = UDim2.new(1, -30, 0, 6)
				bind.AnchorPoint = Vector2.new(1, 0)
				bind.BackgroundColor3 = Color3.new(1, 1, 1)
				bind.BackgroundTransparency = 0.92
				bind.BorderSizePixel = 0
				bind.AutoButtonColor = false
				bind.Visible = false
				bind.Text = ''
				addCorner(bind, UDim.new(0, 4))
				local bindicon = Instance.new('ImageLabel')
				bindicon.Name = 'Icon'
				bindicon.Size = UDim2.fromOffset(12, 12)
				bindicon.Position = UDim2.new(0.5, -6, 0, 5)
				bindicon.BackgroundTransparency = 1
				bindicon.Image = getcustomasset('ElevateV4/assets/new/bind.png')
				bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
				bindicon.Parent = bind
				local bindtext = Instance.new('TextLabel')
				bindtext.Size = UDim2.fromScale(1, 1)
				bindtext.Position = UDim2.fromOffset(0, 1)
				bindtext.BackgroundTransparency = 1
				bindtext.Visible = false
				bindtext.Text = ''
				bindtext.TextColor3 = color.Dark(uipallet.Text, 0.43)
				bindtext.TextSize = 12
				bindtext.FontFace = uipallet.Font
				bindtext.Parent = bind
				bind.MouseEnter:Connect(function()
					bindtext.Visible = false
					bindicon.Visible = not bindtext.Visible
					bindicon.Image = getcustomasset('ElevateV4/assets/new/edit.png')
					if v.Name ~= mainapi.Profile then
						bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.16)
					end
				end)
				bind.MouseLeave:Connect(function()
					bindtext.Visible = #v.Bind > 0
					bindicon.Visible = not bindtext.Visible
					bindicon.Image = getcustomasset('ElevateV4/assets/new/bind.png')
					if v.Name ~= mainapi.Profile then
						bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
					end
				end)
				local bindcover = Instance.new('ImageLabel')
				bindcover.Name = 'Cover'
				bindcover.Size = UDim2.fromOffset(154, 33)
				bindcover.BackgroundTransparency = 1
				bindcover.Visible = false
				bindcover.Image = getcustomasset('ElevateV4/assets/new/bindbkg.png')
				bindcover.ScaleType = Enum.ScaleType.Slice
				bindcover.SliceCenter = Rect.new(0, 0, 141, 40)
				bindcover.Parent = object
				local bindcovertext = Instance.new('TextLabel')
				bindcovertext.Name = 'Text'
				bindcovertext.Size = UDim2.new(1, -10, 1, -3)
				bindcovertext.BackgroundTransparency = 1
				bindcovertext.Text = 'PRESS A KEY TO BIND'
				bindcovertext.TextColor3 = uipallet.Text
				bindcovertext.TextSize = 11
				bindcovertext.FontFace = uipallet.Font
				bindcovertext.Parent = bindcover
				bind.Parent = object
				dotsbutton.MouseEnter:Connect(function()
					if v.Name ~= mainapi.Profile then
						dots.ImageColor3 = uipallet.Text
					end
				end)
				dotsbutton.MouseLeave:Connect(function()
					if v.Name ~= mainapi.Profile then
						dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
					end
				end)
				dotsbutton.MouseButton1Click:Connect(function()
					if v.Name ~= mainapi.Profile then
						categoryapi:ChangeValue(v.Name)
					end
				end)
				object.MouseButton1Click:Connect(function()
					mainapi:Save()
					mainapi:Load(true, v.Name)
					mainapi:Save()
				end)
				object.MouseEnter:Connect(function()
					bind.Visible = true
					if v.Name ~= mainapi.Profile then
						objectstroke.Enabled = true
						objecttitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
					end
				end)
				object.MouseLeave:Connect(function()
					bind.Visible = #v.Bind > 0
					if v.Name ~= mainapi.Profile then
						objectstroke.Enabled = false
						objecttitle.TextColor3 = color.Dark(uipallet.Text, 0.4)
					end
				end)

				local function bindFunction(self, tab, mouse)
					v.Bind = table.clone(tab)
					if mouse then
						bindcovertext.Text = #tab <= 0 and 'BIND REMOVED' or 'BOUND TO '..table.concat(tab, ' + '):upper()
						bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 40)
						task.delay(1, function()
							bindcover.Visible = false
						end)
					end

					if #tab <= 0 then
						bindtext.Visible = false
						bindicon.Visible = true
						bind.Size = UDim2.fromOffset(20, 21)
					else
						bind.Visible = true
						bindtext.Visible = true
						bindicon.Visible = false
						bindtext.Text = table.concat(tab, ' + '):upper()
						bind.Size = UDim2.fromOffset(math.max(getfontsize(bindtext.Text, bindtext.TextSize, bindtext.Font).X + 10, 20), 21)
					end
				end

				bindFunction({}, v.Bind)
				bind.MouseButton1Click:Connect(function()
					bindcovertext.Text = 'PRESS A KEY TO BIND'
					bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 40)
					bindcover.Visible = true
					mainapi.Binding = {SetBind = bindFunction, Bind = v.Bind}
				end)
				if v.Name == mainapi.Profile then
					self.Selected = object
				end
				table.insert(self.Objects, object)
			else
				local enabled = table.find(self.ListEnabled, v)
				local object = Instance.new('TextButton')
				object.Name = v
				object.Size = UDim2.fromOffset(200, 32)
				object.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
				object.AutoButtonColor = false
				object.Text = ''
				object.Parent = children
				addCorner(object)
				local objectbkg = Instance.new('Frame')
				objectbkg.Name = 'BKG'
				objectbkg.Size = UDim2.new(1, -2, 1, -2)
				objectbkg.Position = UDim2.fromOffset(1, 1)
				objectbkg.BackgroundColor3 = uipallet.Main
				objectbkg.Visible = false
				objectbkg.Parent = object
				addCorner(objectbkg)
				local objectdot = Instance.new('Frame')
				objectdot.Name = 'Dot'
				objectdot.Size = UDim2.fromOffset(10, 11)
				objectdot.Position = UDim2.fromOffset(10, 12)
				objectdot.BackgroundColor3 = enabled and categorysettings.Color or color.Light(uipallet.Main, 0.37)
				objectdot.Parent = object
				addCorner(objectdot, UDim.new(1, 0))
				local objectdotin = objectdot:Clone()
				objectdotin.Size = UDim2.fromOffset(8, 9)
				objectdotin.Position = UDim2.fromOffset(1, 1)
				objectdotin.BackgroundColor3 = enabled and categorysettings.Color or color.Light(uipallet.Main, 0.02)
				objectdotin.Parent = objectdot
				local objecttitle = Instance.new('TextLabel')
				objecttitle.Name = 'Title'
				objecttitle.Size = UDim2.new(1, -30, 1, 0)
				objecttitle.Position = UDim2.fromOffset(30, 0)
				objecttitle.BackgroundTransparency = 1
				objecttitle.Text = v
				objecttitle.TextXAlignment = Enum.TextXAlignment.Left
				objecttitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
				objecttitle.TextSize = 15
				objecttitle.FontFace = uipallet.Font
				objecttitle.Parent = object
				if mainapi.ThreadFix then
					setthreadidentity(8)
				end
				local close = Instance.new('ImageButton')
				close.Name = 'Close'
				close.Size = UDim2.fromOffset(16, 16)
				close.Position = UDim2.new(1, -23, 0, 8)
				close.BackgroundColor3 = Color3.new(1, 1, 1)
				close.BackgroundTransparency = 1
				close.AutoButtonColor = false
				close.Image = getcustomasset('ElevateV4/assets/new/closemini.png')
				close.ImageColor3 = color.Light(uipallet.Text, 0.2)
				close.ImageTransparency = 0.5
				close.Parent = object
				addCorner(close, UDim.new(1, 0))
				close.MouseEnter:Connect(function()
					close.ImageTransparency = 0.3
					tween:Tween(close, uipallet.Tween, {
						BackgroundTransparency = 0.6
					})
				end)
				close.MouseLeave:Connect(function()
					close.ImageTransparency = 0.5
					tween:Tween(close, uipallet.Tween, {
						BackgroundTransparency = 1
					})
				end)
				close.MouseButton1Click:Connect(function()
					categoryapi:ChangeValue(v)
				end)
				object.MouseEnter:Connect(function()
					objectbkg.Visible = true
				end)
				object.MouseLeave:Connect(function()
					objectbkg.Visible = false
				end)
				object.MouseButton1Click:Connect(function()
					local ind = table.find(self.ListEnabled, v)
					if ind then
						table.remove(self.ListEnabled, ind)
						objectdot.BackgroundColor3 = color.Light(uipallet.Main, 0.37)
						objectdotin.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
					else
						table.insert(self.ListEnabled, v)
						objectdot.BackgroundColor3 = categorysettings.Color
						objectdotin.BackgroundColor3 = categorysettings.Color
					end
					categorysettings.Function()
				end)
				table.insert(self.Objects, object)
			end
		end
		if self.RefreshPresetSync then
			self.RefreshPresetSync()
		end
		mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	end

	function categoryapi:Expand()
		if categorysettings.Profiles then
			refreshConfigProfiles()
			self:ChangeValue()
		end
		self.Expanded = not self.Expanded
		if self.Expanded then children.Visible = true end
		tween:Tween(window, unwindInfo, {
			Size = UDim2.fromOffset(220, self.Expanded and math.min(51 + windowlist.AbsoluteContentSize.Y / scale.Scale, 611) or 45)
		})
		tween:Tween(arrow, unwindInfo, {
			Rotation = self.Expanded and 0 or 180
		})
		if not self.Expanded then
			task.delay(unwindInfo.Time, function()
				if categoryapi.Expanded then return end
				children.Visible = false
				divider.Visible = false
			end)
		end
		divider.Visible = self.Expanded and children.CanvasPosition.Y > 10
	end

	function categoryapi:GetValue(name)
		for i, v in mainapi.Profiles do
			if v.Name == name then
				return i
			end
		end
	end

	for i, v in components do
		categoryapi['Create'..i] = function(self, optionsettings)
			return mainapi:AttachContextualOption(v(optionsettings, childrentwo, categoryapi), optionsettings)
		end
	end

	addbutton.MouseEnter:Connect(function()
		addbutton.ImageTransparency = 0
	end)
	addbutton.MouseLeave:Connect(function()
		addbutton.ImageTransparency = 0.3
	end)
	addbutton.MouseButton1Click:Connect(function()
		local value = addvalue.Text:gsub('^%s*(.-)%s*$', '%1')
		if value ~= '' and (categorysettings.Profiles and not categoryapi:GetValue(value) or not table.find(categoryapi.List, value)) then
			categoryapi:ChangeValue(value)
			addvalue.Text = ''
		end
	end)
	arrowbutton.MouseEnter:Connect(function()
		arrow.ImageColor3 = Color3.fromRGB(220, 220, 220)
	end)
	arrowbutton.MouseLeave:Connect(function()
		arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
	end)
	arrowbutton.MouseButton1Click:Connect(function()
		categoryapi:Expand()
	end)
	arrowbutton.MouseButton2Click:Connect(function()
		categoryapi:Expand()
	end)
	addvalue.FocusLost:Connect(function(enter)
		local value = addvalue.Text:gsub('^%s*(.-)%s*$', '%1')
		if enter and value ~= '' and (categorysettings.Profiles and not categoryapi:GetValue(value) or not table.find(categoryapi.List, value)) then
			categoryapi:ChangeValue(value)
			addvalue.Text = ''
		end
	end)
	addvalue.MouseEnter:Connect(function()
		tween:Tween(addbkg, uipallet.Tween, {
			BackgroundColor3 = color.Light(uipallet.Main, 0.14)
		})
	end)
	addvalue.MouseLeave:Connect(function()
		tween:Tween(addbkg, uipallet.Tween, {
			BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		})
	end)
	children:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
		divider.Visible = children.CanvasPosition.Y > 10 and children.Visible
	end)
	settings.MouseEnter:Connect(function()
		settings.ImageColor3 = uipallet.Text
	end)
	settings.MouseLeave:Connect(function()
		settings.ImageColor3 = color.Light(uipallet.Main, 0.37)
	end)
	settings.MouseButton1Click:Connect(function()
		childrentwo.Visible = not childrentwo.Visible
	end)
	window.InputBegan:Connect(function(inputObj)
		if inputObj.Position.Y < window.AbsolutePosition.Y + 41 and inputObj.UserInputType == Enum.UserInputType.MouseButton2 then
			categoryapi:Expand()
		end
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		if categoryapi.Expanded then
			tween:Tween(window, unwindInfo, {
				Size = UDim2.fromOffset(220, math.min(51 + windowlist.AbsoluteContentSize.Y / scale.Scale, 611))
			})
		end
	end)
	windowlisttwo:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		childrentwo.Size = UDim2.fromOffset(220, (windowlisttwo.AbsoluteContentSize.Y / scale.Scale) + 12)
	end)

	categoryapi.Button = self.Categories.Main:CreateButton({
		Name = displayName,
		Icon = categorysettings.CategoryIcon,
		Size = categorysettings.CategorySize,
		Window = window
	})

	categoryapi.Object = window
	categoryapi.DefaultPosition = UDim2.fromOffset(defaultX, defaultY)
	self.Categories[categorysettings.Name] = categoryapi

	return categoryapi
end

function mainapi:CreateWelcome()
	local seenpath = 'ElevateV4/profiles/welcome.txt'
	if isfile(seenpath) then return end

	local shortHeight, tallHeight = 314, 452
	local cardHeight = shortHeight

	local card = Instance.new('Frame')
	card.Name = 'Welcome'
	card.Size = UDim2.fromOffset(430, cardHeight)
	card.Position = UDim2.new(0.5, -215, 0.5, -cardHeight / 2)
	card.BackgroundColor3 = uipallet.Main
	card.Visible = false
	card.Parent = scaledgui
	addBlur(card)
	addCorner(card)
	addWindowStroke(card)
	makeDraggable(card)
	local cardmodal = Instance.new('TextButton')
	cardmodal.BackgroundTransparency = 1
	cardmodal.Text = ''
	cardmodal.Modal = true
	cardmodal.Parent = card

	local logo = Instance.new('ImageLabel')
	logo.Name = 'Logo'
	logo.Size = UDim2.fromOffset(26, 26)
	logo.Position = UDim2.fromOffset(22, 22)
	logo.BackgroundTransparency = 1
	logo.Image = getcustomasset('ElevateV4/assets/new/vape.png')
	logo.Parent = card

	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -110, 0, 22)
	title.Position = UDim2.fromOffset(58, 22)
	title.BackgroundTransparency = 1
	title.Text = 'Welcome to ElevateV4'
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 18
	title.FontFace = uipallet.FontSemiBold
	title.Parent = card

	local subtitle = title:Clone()
	subtitle.Name = 'Subtitle'
	subtitle.Size = UDim2.new(1, -110, 0, 16)
	subtitle.Position = UDim2.fromOffset(58, 42)
	subtitle.Text = 'A few things worth knowing before you start'
	subtitle.TextColor3 = color.Dark(uipallet.Text, 0.4)
	subtitle.TextSize = 12
	subtitle.FontFace = uipallet.Font
	subtitle.Parent = card

	local rows = Instance.new('Frame')
	rows.Name = 'Rows'
	rows.Size = UDim2.new(1, -44, 0, 108)
	rows.Position = UDim2.fromOffset(22, 84)
	rows.BackgroundTransparency = 1
	rows.Parent = card
	local rowlist = Instance.new('UIListLayout')
	rowlist.SortOrder = Enum.SortOrder.LayoutOrder
	rowlist.Padding = UDim.new(0, 6)
	rowlist.Parent = rows

	for index, entry in {
		{Heading = 'Open and close the menu', Body = 'Press '..table.concat(mainapi.Keybind, ' + '):upper()..'. Rebind it from the key next to the logo'},
		{Heading = 'Configs live in the repo', Body = 'Configs has a globe button that lists them, and loading one applies it right away'},
		{Heading = 'Anything broken or missing', Body = 'discord.gg/aYu5c9v9zv, copied to your clipboard by the button below'}
	} do
		local row = Instance.new('Frame')
		row.Name = 'Row'..index
		row.LayoutOrder = index
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		row.Parent = rows
		addCorner(row)
		local heading = Instance.new('TextLabel')
		heading.Size = UDim2.new(1, -20, 0, 14)
		heading.Position = UDim2.fromOffset(10, 3)
		heading.BackgroundTransparency = 1
		heading.Text = entry.Heading
		heading.TextXAlignment = Enum.TextXAlignment.Left
		heading.TextColor3 = uipallet.Text
		heading.TextSize = 12
		heading.FontFace = uipallet.Font
		heading.Parent = row
		local body = heading:Clone()
		body.Position = UDim2.fromOffset(10, 16)
		body.Text = entry.Body
		body.TextColor3 = color.Dark(uipallet.Text, 0.36)
		body.TextSize = 11
		body.Parent = row
	end

	local function makeButton(text, order, primary, fn)
		local button = Instance.new('TextButton')
		button.Name = text
		button.LayoutOrder = order
		button.Size = UDim2.fromOffset(126, 30)
		button.BackgroundColor3 = primary and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or color.Light(uipallet.Main, 0.04)
		button.AutoButtonColor = true
		button.Text = text
		button.TextColor3 = primary and mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or uipallet.Text
		button.TextSize = 13
		button.FontFace = uipallet.Font
		button.Parent = card
		addCorner(button, UDim.new(0, 5))
		button.MouseButton1Click:Connect(fn)
		return button
	end

	local question = Instance.new('Frame')
	question.Name = 'PresetQuestion'
	question.Size = UDim2.new(1, -44, 0, 46)
	question.Position = UDim2.fromOffset(22, 200)
	question.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
	question.Parent = card
	addCorner(question)
	local questiontitle = Instance.new('TextLabel')
	questiontitle.Size = UDim2.new(1, -140, 0, 16)
	questiontitle.Position = UDim2.fromOffset(10, 7)
	questiontitle.BackgroundTransparency = 1
	questiontitle.Text = 'Download a preset config?'
	questiontitle.TextXAlignment = Enum.TextXAlignment.Left
	questiontitle.TextColor3 = uipallet.Text
	questiontitle.TextSize = 13
	questiontitle.FontFace = uipallet.Font
	questiontitle.Parent = question
	local questionbody = questiontitle:Clone()
	questionbody.Size = UDim2.new(1, -140, 0, 14)
	questionbody.Position = UDim2.fromOffset(10, 24)
	questionbody.Text = 'Starts you on a ready-made setup instead of nothing'
	questionbody.TextColor3 = color.Dark(uipallet.Text, 0.36)
	questionbody.TextSize = 11
	questionbody.Parent = question

	local picker = Instance.new('ScrollingFrame')
	picker.Name = 'PresetPicker'
	picker.Size = UDim2.new(1, -44, 0, 116)
	picker.Position = UDim2.fromOffset(22, 254)
	picker.BackgroundTransparency = 1
	picker.BorderSizePixel = 0
	picker.ScrollBarThickness = 2
	picker.ScrollBarImageTransparency = 0.75
	picker.CanvasSize = UDim2.new()
	picker.Visible = false
	picker.Parent = card
	local pickerlist = Instance.new('UIListLayout')
	pickerlist.SortOrder = Enum.SortOrder.LayoutOrder
	pickerlist.Padding = UDim.new(0, 6)
	pickerlist.Parent = picker
	pickerlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		picker.CanvasSize = UDim2.fromOffset(0, pickerlist.AbsoluteContentSize.Y / scale.Scale)
	end)
	local pickerstatus = Instance.new('TextLabel')
	pickerstatus.Name = 'Status'
	pickerstatus.Size = UDim2.new(1, -44, 0, 16)
	pickerstatus.Position = UDim2.fromOffset(22, 374)
	pickerstatus.BackgroundTransparency = 1
	pickerstatus.Text = ''
	pickerstatus.TextXAlignment = Enum.TextXAlignment.Left
	pickerstatus.TextColor3 = color.Dark(uipallet.Text, 0.4)
	pickerstatus.TextSize = 11
	pickerstatus.FontFace = uipallet.Font
	pickerstatus.Visible = false
	pickerstatus.Parent = card

	local buttons = Instance.new('Frame')
	buttons.Name = 'Buttons'
	buttons.Size = UDim2.new(1, -44, 0, 30)
	buttons.Position = UDim2.fromOffset(22, 258)
	buttons.BackgroundTransparency = 1
	buttons.Parent = card
	local buttonlist = Instance.new('UIListLayout')
	buttonlist.FillDirection = Enum.FillDirection.Horizontal
	buttonlist.SortOrder = Enum.SortOrder.LayoutOrder
	buttonlist.Padding = UDim.new(0, 8)
	buttonlist.Parent = buttons

	local function dismiss()
		card.Visible = false
		clickgui.Visible = true
		pcall(writefile, seenpath, 'true')
	end

	makeButton('Browse configs', 1, false, function()
		dismiss()
		if mainapi.OpenRepoConfigs then
			mainapi.OpenRepoConfigs()
		end
	end).Parent = buttons
	makeButton('Copy discord', 2, false, function()
		if setclipboard then
			setclipboard('https://discord.gg/aYu5c9v9zv')
		end
		mainapi:CreateNotification('ElevateV4', 'Discord invite copied to your clipboard', 5, 'info')
	end).Parent = buttons
	makeButton('Start', 3, true, dismiss).Parent = buttons

	local footer = Instance.new('TextLabel')
	footer.Name = 'Footer'
	footer.Size = UDim2.new(1, -44, 0, 14)
	footer.Position = UDim2.fromOffset(22, 294)
	footer.BackgroundTransparency = 1
	footer.Text = 'Shown once. Everything here lives in the menu if you need it later'
	footer.TextXAlignment = Enum.TextXAlignment.Left
	footer.TextColor3 = color.Dark(uipallet.Text, 0.5)
	footer.TextSize = 11
	footer.FontFace = uipallet.Font
	footer.Parent = card

	local picking = false
	local yesbutton, nobutton
	local function layout()
		picker.Visible = picking
		pickerstatus.Visible = picking and pickerstatus.Text ~= ''
		buttons.Position = UDim2.fromOffset(22, picking and 396 or 258)
		footer.Position = UDim2.fromOffset(22, picking and 432 or 294)
		cardHeight = picking and tallHeight or shortHeight
		card.Size = UDim2.fromOffset(430, cardHeight)
		for _, entry in {{Button = yesbutton, On = picking}, {Button = nobutton, On = not picking}} do
			if entry.Button then
				entry.Button.BackgroundColor3 = entry.On and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or color.Light(uipallet.Main, 0.05)
				entry.Button.TextColor3 = entry.On and mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or color.Dark(uipallet.Text, 0.3)
			end
		end
	end

	local function makeAnswer(text, xoff)
		local button = Instance.new('TextButton')
		button.Name = text
		button.Size = UDim2.fromOffset(56, 26)
		button.Position = UDim2.new(1, xoff, 0.5, -13)
		button.AnchorPoint = Vector2.new(1, 0)
		button.BackgroundColor3 = color.Light(uipallet.Main, 0.05)
		button.AutoButtonColor = true
		button.Text = text
		button.TextColor3 = color.Dark(uipallet.Text, 0.3)
		button.TextSize = 12
		button.FontFace = uipallet.Font
		button.Parent = question
		addCorner(button, UDim.new(0, 5))
		return button
	end
	nobutton = makeAnswer('No', -10)
	yesbutton = makeAnswer('Yes', -72)

	local loading, loaded = false, nil
	local function makePresetRow(preset, order)
		local row = Instance.new('Frame')
		row.Name = tostring(preset.name)
		row.LayoutOrder = order
		row.Size = UDim2.new(1, 0, 0, 42)
		row.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		row.Parent = picker
		addCorner(row)
		local name = Instance.new('TextLabel')
		name.Size = UDim2.new(1, -100, 0, 16)
		name.Position = UDim2.fromOffset(10, 5)
		name.BackgroundTransparency = 1
		name.Text = tostring(preset.name)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = uipallet.Text
		name.TextSize = 12
		name.FontFace = uipallet.Font
		name.Parent = row
		local body = name:Clone()
		body.Size = UDim2.new(1, -100, 0, 14)
		body.Position = UDim2.fromOffset(10, 22)
		body.Text = preset.description and tostring(preset.description)
			or ((preset.tags and #preset.tags > 0) and table.concat(preset.tags, ' • ') or '')
		body.TextColor3 = color.Dark(uipallet.Text, 0.36)
		body.TextSize = 11
		body.TextTruncate = Enum.TextTruncate.AtEnd
		body.Parent = row
		local get = Instance.new('TextButton')
		get.Size = UDim2.fromOffset(66, 24)
		get.Position = UDim2.new(1, -10, 0.5, -12)
		get.AnchorPoint = Vector2.new(1, 0)
		get.BackgroundColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		get.AutoButtonColor = true
		get.Text = 'Download'
		get.TextColor3 = mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
		get.TextSize = 11
		get.FontFace = uipallet.Font
		get.Parent = row
		addCorner(get, UDim.new(0, 5))
		get.MouseButton1Click:Connect(function()
			if loading then return end
			loading = true
			get.Text = '...'
			task.spawn(function()
				local ok, res, version = pcall(function()
					return configapi.Presets.Fetch(tostring(preset.file))
				end)
				if version then preset.version = version end
				local suc, result
				if ok and res and res ~= '404: Not Found' then
					suc, result = importJsonConfig(res, preset.name)
				end
				loading = false
				get.Text = suc and 'Loaded' or 'Download'
				if not suc then
					pickerstatus.Text = 'Could not download '..tostring(preset.name)..'.'
					pickerstatus.Visible = true
					return
				end
				configapi.Presets.Remember(tostring(result), preset, true)
				refreshConfigProfiles()
				if mainapi.Categories.Profiles then
					mainapi.Categories.Profiles:ChangeValue()
				end
				if loaded and loaded ~= get then
					loaded.Text = 'Download'
				end
				loaded = get
				pickerstatus.Text = tostring(result)..' is loaded and active'
				pickerstatus.Visible = true
			end)
		end)
	end

	local fetched = false
	local function fetchPresets()
		if fetched then return end
		fetched = true
		pickerstatus.Text = 'Loading configs...'
		layout()
		task.spawn(function()
			local ok, res = pcall(function()
				return configapi.Presets.FetchList('trending')
			end)
			local decoded = ok and res and res ~= '404: Not Found'
				and select(2, pcall(function() return httpService:JSONDecode(res) end))
				or nil
			if type(decoded) ~= 'table' or type(decoded.presets) ~= 'table' or #decoded.presets == 0 then
				fetched = false
				pickerstatus.Text = 'Community configs could not be loaded right now'
				layout()
				return
			end
			pickerstatus.Text = ''
			for index, preset in decoded.presets do
				pcall(makePresetRow, preset, index)
			end
			layout()
		end)
	end

	yesbutton.MouseButton1Click:Connect(function()
		picking = true
		layout()
		fetchPresets()
	end)
	nobutton.MouseButton1Click:Connect(function()
		picking = false
		layout()
	end)
	layout()

	addCloseButton(card).MouseButton1Click:Connect(dismiss)
	table.insert(mainapi.Windows, card)
	mainapi.WelcomeCard = card

	local watcher
	watcher = clickgui:GetPropertyChangedSignal('Visible'):Connect(function()
		if not clickgui.Visible then return end
		watcher:Disconnect()
		if isfile(seenpath) then return end
		clickgui.Visible = false
		card.Visible = true
		card.Position = UDim2.new(0.5, -215, 0.5, -cardHeight / 2)
	end)
	mainapi:Clean(watcher)
end

function mainapi:CreateSearch()
	local normalWidth = 220
	local function mobileActive()
		return inputService.TouchEnabled or shared.AetherMobileMode == true
	end
	local xscale = mobileActive() and 0.1 or 0.5
	local searchbkg = Instance.new('Frame')
	searchbkg.Name = 'Search'
	searchbkg.Size = UDim2.fromOffset(mobileActive() and 300 or normalWidth, 37)
	searchbkg.Position = UDim2.new(xscale, 0, 0, 13)
	searchbkg.AnchorPoint = Vector2.new(xscale, 0)
	searchbkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	searchbkg.Parent = clickgui
	local searchicon = Instance.new('ImageLabel')
	searchicon.Name = 'Icon'
	searchicon.Size = UDim2.fromOffset(14, 14)
	searchicon.Position = UDim2.new(1, -23, 0, 11)
	searchicon.BackgroundTransparency = 1
	searchicon.Image = getcustomasset('ElevateV4/assets/new/search.png')
	searchicon.ImageColor3 = color.Light(uipallet.Main, 0.37)
	searchicon.Parent = searchbkg
	local legiticon = Instance.new('ImageButton')
	legiticon.Name = 'Legit'
	legiticon.Size = UDim2.fromOffset(29, 16)
	legiticon.Position = UDim2.fromOffset(8, 11)
	legiticon.BackgroundTransparency = 1
	legiticon.Image = getcustomasset('ElevateV4/assets/new/legit.png')
	legiticon.Parent = searchbkg
	local legitdivider = Instance.new('Frame')
	legitdivider.Name = 'LegitDivider'
	legitdivider.Size = UDim2.fromOffset(2, 12)
	legitdivider.Position = UDim2.fromOffset(43, 13)
	legitdivider.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
	legitdivider.BorderSizePixel = 0
	legitdivider.Parent = searchbkg
	local kitsicon = Instance.new('ImageButton')
	kitsicon.Name = 'Kits'
	kitsicon.Size = UDim2.fromOffset(29, 16)
	kitsicon.Position = UDim2.fromOffset(51, 11)
	kitsicon.BackgroundTransparency = 1
	kitsicon.Image = getcustomasset('ElevateV4/assets/new/friendstab.png')
	kitsicon.ScaleType = Enum.ScaleType.Fit
	kitsicon.Parent = searchbkg
	local kitsdivider = Instance.new('Frame')
	kitsdivider.Name = 'KitsDivider'
	kitsdivider.Size = UDim2.fromOffset(2, 12)
	kitsdivider.Position = UDim2.fromOffset(86, 13)
	kitsdivider.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
	kitsdivider.BorderSizePixel = 0
	kitsdivider.Parent = searchbkg
	addBlur(searchbkg)
	addCorner(searchbkg)
	local search = Instance.new('TextBox')
	search.Size = UDim2.new(1, -50, 0, 37)
	search.Position = UDim2.fromOffset(50, 0)
	search.BackgroundTransparency = 1
	search.Text = ''
	search.PlaceholderText = ''
	search.TextXAlignment = Enum.TextXAlignment.Left
	search.TextColor3 = uipallet.Text
	search.TextSize = 12
	search.FontFace = uipallet.Font
	search.ClearTextOnFocus = false
	search.Parent = searchbkg
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -37)
	children.Position = UDim2.fromOffset(0, 34)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = searchbkg
	local divider = Instance.new('Frame')
	divider.Name = 'Divider'
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.fromOffset(0, 33)
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.928
	divider.BorderSizePixel = 0
	divider.Visible = false
	divider.Parent = searchbkg
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Parent = children

	children:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
		divider.Visible = children.CanvasPosition.Y > 10 and children.Visible
	end)
	local function updateSearchLayout()
		local x = 8
		for _, entry in {{Button = legiticon, Divider = legitdivider}, {Button = kitsicon, Divider = kitsdivider}} do
			if entry.Button.Visible then
				entry.Button.Position = UDim2.fromOffset(x, 11)
				entry.Divider.Position = UDim2.fromOffset(x + 35, 13)
				entry.Divider.Visible = true
				x = x + 43
			else
				entry.Divider.Visible = false
			end
		end
		local offset = x == 8 and 10 or x
		search.Position = UDim2.fromOffset(offset, 0)
		search.Size = UDim2.new(1, -offset, 0, 37)
	end
	self.UpdateSearchLayout = updateSearchLayout
	updateSearchLayout()

	kitsicon.MouseButton1Click:Connect(function()
		clickgui.Visible = false
		self.Kits.Window.Visible = true
		self.Kits.Window.Position = UDim2.new(0.5, -350, 0.5, -194)
	end)
	legiticon.MouseButton1Click:Connect(function()
		clickgui.Visible = false
		self.Legit.Window.Visible = true
		self.Legit.Window.Position = UDim2.new(0.5, -350, 0.5, -194)
	end)
	local searchGeneration = 0
	local searchResults = {}
	local selectedResult = 0
	local function selectResult(index)
		if #searchResults == 0 then selectedResult = 0 return end
		selectedResult = ((index - 1) % #searchResults) + 1
		for resultIndex, result in searchResults do
			local stroke = result.Button:FindFirstChild('SearchSelection')
			if not stroke then
				stroke = Instance.new('UIStroke')
				stroke.Name = 'SearchSelection'
				stroke.Thickness = 1
				stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				stroke.Parent = result.Button
			end
			stroke.Color = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
			stroke.Transparency = (resultIndex == selectedResult and search:IsFocused()) and 0.2 or 1
		end
		local selected = searchResults[selectedResult]
		if selected and selected.Button.Parent then
			local top = selected.Button.AbsolutePosition.Y - children.AbsolutePosition.Y + children.CanvasPosition.Y
			local bottom = top + selected.Button.AbsoluteSize.Y
			if top < children.CanvasPosition.Y then
				children.CanvasPosition = Vector2.new(0, math.max(top, 0))
			elseif bottom > children.CanvasPosition.Y + children.AbsoluteSize.Y then
				children.CanvasPosition = Vector2.new(0, math.max(bottom - children.AbsoluteSize.Y, 0))
			end
		end
	end
	local function centerModuleRow(module)
		local frame = module.Object and module.Object.Parent
		if not frame or not frame:IsA('ScrollingFrame') or not module.Object.Parent then return true end
		local rowTop = module.Object.AbsolutePosition.Y - frame.AbsolutePosition.Y + frame.CanvasPosition.Y
		local rowHeight = module.Object.AbsoluteSize.Y
		local view = frame.AbsoluteSize.Y
		local maximum = math.max(frame.CanvasSize.Y.Offset - view, 0)
		local targetY = math.clamp(rowTop - math.max((view - rowHeight) * 0.5, 0), 0, maximum)
		frame.CanvasPosition = Vector2.new(0, targetY)
		local top = module.Object.AbsolutePosition.Y - frame.AbsolutePosition.Y
		return top >= -1 and (top + rowHeight) <= (view + 1)
	end
	local function locateModule(module)
		if not module or not module.Object then return end
		local category = self.Categories[module.Category]
		if not category or category.Type ~= 'Category' or not category.Object then return end
		category.Object.Visible = true
		if not category.Expanded then category:Expand() end
		if module.Hidden and category.SetEditMode then
			mainapi.EditGUI = true
			category:SetEditMode(true)
		end
		if module.OptionsChildren then module.OptionsChildren.Visible = true end
		task.defer(function()
			local frame = module.Object and module.Object.Parent
			if not frame or not frame:IsA('ScrollingFrame') or not module.Object.Parent then return end
			local highlight = Instance.new('Frame')
			highlight.Name = 'SearchLocateHighlight'
			highlight.Size = UDim2.fromScale(1, 1)
			highlight.BackgroundColor3 = Color3.new(1, 1, 1)
			highlight.BackgroundTransparency = 0.6
			highlight.BorderSizePixel = 0
			highlight.ZIndex = module.Object.ZIndex + 2
			highlight.Parent = module.Object
			tween:Tween(highlight, TweenInfo.new(0.5), {BackgroundTransparency = 1})
			task.delay(0.5, function() if highlight.Parent then highlight:Destroy() end end)

			local attempts = 0
			local function attempt()
				attempts += 1
				if not module.Object or not module.Object.Parent then return end
				if centerModuleRow(module) or attempts >= 5 then return end
				task.delay(0.08, attempt)
			end
			attempt()
		end)
	end
	local function clearSearchResults()
		for _, v in children:GetChildren() do
			if v:IsA('TextButton') then
				v:Destroy()
			end
		end
		table.clear(searchResults)
		selectedResult = 0
	end
	local function updateSearch(query, generation)
		if generation ~= searchGeneration then return end
		clearSearchResults()
		if query == '' then return end

		for _, v in self.Modules do
			if generation ~= searchGeneration then return end
			if self:ModuleMatchesSearch(v, query) then
				local button = v.Object:Clone()
				local bind = button:FindFirstChild('Bind')
				if bind then bind:Destroy() end
				local function toggle()
					v:Toggle()
				end
				local function locate()
					locateModule(v)
					search.Text = ''
					pcall(function() search:ReleaseFocus() end)
				end
				for _, part in button:GetDescendants() do
					if part:IsA('GuiButton') then
						part.MouseButton1Click:Connect(toggle)
						part.MouseButton2Click:Connect(locate)
					end
				end
				button.MouseButton1Click:Connect(toggle)
				button.MouseButton2Click:Connect(locate)

				button.Parent = children
				table.insert(searchResults, {Button = button, Source = v.Object, Module = v})
			end
		end
		selectResult(1)
	end
	table.insert(self.ModuleSearchRefreshers, function()
		searchGeneration += 1
		updateSearch(search.Text:lower(), searchGeneration)
	end)
	search:GetPropertyChangedSignal('Text'):Connect(function()
		searchGeneration += 1
		local generation = searchGeneration
		local query = search.Text:lower()
		task.delay(0.05, function()
			updateSearch(query, generation)
		end)
	end)
	search.FocusLost:Connect(function()
		for _, result in searchResults do
			local stroke = result.Button:FindFirstChild('SearchSelection')
			if stroke then stroke.Transparency = 1 end
		end
	end)
	search.Focused:Connect(function()
		selectResult(selectedResult > 0 and selectedResult or 1)
	end)
	self:Clean(inputService.InputBegan:Connect(function(input)
		if not search:IsFocused() then return end
		if input.KeyCode == Enum.KeyCode.Down then
			selectResult(selectedResult + 1)
		elseif input.KeyCode == Enum.KeyCode.Up then
			selectResult(selectedResult - 1)
		elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
			local result = searchResults[selectedResult]
			if result then result.Module:Toggle() end
		elseif input.KeyCode == Enum.KeyCode.Escape then
			search.Text = ''
			search:ReleaseFocus()
		end
	end))
	task.spawn(function()
		while searchbkg.Parent do
			for _, result in searchResults do
				local button, source = result.Button, result.Source
				if button.Parent and source.Parent then
					pcall(function()
						local buttonTitle, sourceTitle = button:FindFirstChild('Title'), source:FindFirstChild('Title')
						if buttonTitle and sourceTitle then
							buttonTitle.Text = sourceTitle.Text
							buttonTitle.TextColor3 = sourceTitle.TextColor3
							buttonTitle.Size = sourceTitle.Size
						end
						button.TextColor3 = source.TextColor3
						button.BackgroundColor3 = source.BackgroundColor3
						button.UIGradient.Color = source.UIGradient.Color
						button.UIGradient.Enabled = source.UIGradient.Enabled
						button.Dots.Dots.ImageColor3 = source.Dots.Dots.ImageColor3
						local buttonDivider, sourceDivider = button:FindFirstChild('Divider'), source:FindFirstChild('Divider')
						if buttonDivider and sourceDivider then
							buttonDivider.Visible = sourceDivider.Visible
						end
					end)
				end
			end
			task.wait(0.1)
		end
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		searchbkg.Size = UDim2.fromOffset(mobileActive() and 300 or normalWidth, math.min(37 + windowlist.AbsoluteContentSize.Y / scale.Scale, 437))
	end)

	function self:SetMobileMode(enabled)
		shared.AetherMobileMode = enabled and true or false
		local mobile = mobileActive()
		local position = mobile and 0.1 or 0.5
		searchbkg.Size = UDim2.fromOffset(mobile and 300 or normalWidth, searchbkg.Size.Y.Offset)
		searchbkg.Position, searchbkg.AnchorPoint = UDim2.new(position, 0, 0, 13), Vector2.new(position, 0)
		search.TextSize = mobile and 14 or 12
	end
	self:SetMobileMode(shared.AetherMobileMode == true)
	self.Legit.Icon = legiticon
	self.Kits.Icon = kitsicon
end

local function createPanel(config)
	local self = mainapi
	local legitapi = {Modules = {}, Categories = {}}

	local window = Instance.new('Frame')
	window.Name = config.Window
	window.Size = UDim2.fromOffset(700, 389)
	window.Position = UDim2.new(0.5, -350, 0.5, -194)
	window.BackgroundColor3 = uipallet.Main
	window.Visible = false
	window.Parent = scaledgui
	addBlur(window)
	addCorner(window)
	addWindowStroke(window)
	makeDraggable(window)
	local modal = Instance.new('TextButton')
	modal.BackgroundTransparency = 1
	modal.Text = ''
	modal.Modal = true
	modal.Parent = window
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = UDim2.fromOffset(16, 16)
	icon.Position = UDim2.fromOffset(18, 13)
	icon.BackgroundTransparency = 1
	icon.Image = getcustomasset(config.Icon)
	icon.ImageColor3 = uipallet.Text
	icon.Parent = window
	local close = addCloseButton(window)
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.fromOffset(684, 300)
	children.Position = UDim2.fromOffset(14, 80)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local windowlist = Instance.new('UIGridLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.FillDirectionMaxCells = 4
	windowlist.CellSize = UDim2.fromOffset(163, 114)
	windowlist.CellPadding = UDim2.fromOffset(6, 5)
	windowlist.Parent = children
	local search = Instance.new('Frame')
	search.Position = UDim2.fromOffset(449, 42)
	search.Name = 'Search'
	search.Size = UDim2.fromOffset(240, 31)
	search.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
	search.Parent = window
	addCorner(search, UDim.new(0, 5))
	local searchbox = search:Clone()
	searchbox.Size = UDim2.new(1, -2, 1, -2)
	searchbox.Position = UDim2.fromOffset(1, 1)
	searchbox.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	searchbox.Parent = search
	local searchvalue = Instance.new('TextBox')
	searchvalue.Size = UDim2.new(1, -35, 1, 0)
	searchvalue.Position = UDim2.fromOffset(10, 0)
	searchvalue.BackgroundTransparency = 1
	searchvalue.Text = ''
	searchvalue.PlaceholderText = 'Search mods'
	searchvalue.TextXAlignment = Enum.TextXAlignment.Left
	searchvalue.PlaceholderColor3 = color.Dark(uipallet.Text, 0.11)
	searchvalue.TextColor3 = color.Dark(uipallet.Text, 0.11)
	searchvalue.TextSize = 14
	searchvalue.FontFace = uipallet.Font
	searchvalue.ClearTextOnFocus = false
	searchvalue.Parent = search
	local searchicon = Instance.new('ImageLabel')
	searchicon.BackgroundTransparency = 1
	searchicon.Position = UDim2.new(1, -28, 0, 8)
	searchicon.Size = UDim2.fromOffset(12, 12)
	searchicon.Image = getcustomasset('ElevateV4/assets/new/search.png')
	searchicon.ImageColor3 = color.Light(uipallet.Main, 0.37)
	searchicon.Parent = searchbox
	local categorylist = Instance.new('Frame')
	categorylist.BackgroundTransparency = 1
	categorylist.Position = UDim2.fromOffset(22, 42)
	categorylist.Size = UDim2.fromOffset(1, 31)
	categorylist.Parent = window
	local categorylayout = Instance.new('UIListLayout')
	categorylayout.FillDirection = Enum.FillDirection.Horizontal
	categorylayout.Parent = categorylist
	categorylayout.SortOrder = Enum.SortOrder.LayoutOrder
	local categoryhighlight = Instance.new('Frame')
	categoryhighlight.BackgroundColor3 = color.Dark(uipallet.Text, 0.31)
	categoryhighlight.BorderSizePixel = 0
	categoryhighlight.Position = UDim2.fromOffset(0, 23)
	categoryhighlight.Size = UDim2.new()
	legitapi.Window = window
	table.insert(mainapi.Windows, window)

	local function updateCheck()
		local FocusedCategory = ''
		for _, v in legitapi.Categories do
			if v.Focused then
				FocusedCategory = v.Name
				break
			end
		end
		for _, v in legitapi.Modules do
			v.Object.Visible = (FocusedCategory == 'All' or v.ApiCategory == FocusedCategory) and mainapi:ModuleMatchesSearch(v, searchvalue.Text)
		end
	end
	table.insert(mainapi.ModuleSearchRefreshers, updateCheck)

	function legitapi:CreateCategory(categoryname)
		local category = {
			Name = categoryname,
			Focused = #self.Categories <= 0 and true or false
		}

		local children = Instance.new('TextButton')
		children.Name = category.Name
		children.LayoutOrder = #self.Categories + 1
		children.BackgroundTransparency = 1
		children.Size = UDim2.new(0, 80, 1, 0)
		children.FontFace = uipallet.Font
		children.TextColor3 = color.Dark(uipallet.Text, 0.31)
		children.Text = category.Name
		children.TextSize = 14
		children.TextXAlignment = Enum.TextXAlignment.Left
		children.Parent = categorylist
		children.MouseButton1Click:Connect(function()
			category:SetVisible()
		end)

		local sizex = textService:GetTextSize(children.Text, children.TextSize, children.Font, Vector2.new(1000, 1000)).X
		children.Size = UDim2.new(0, sizex + 30, 1, 0)

		function category:SetVisible(focused)
			focused = focused or focused == nil and true
			children.TextColor3 = focused and color.Light(uipallet.Text, 0.2) or color.Dark(uipallet.Text, 0.31)
			categoryhighlight.Parent = focused and children or categoryhighlight.Parent
			categoryhighlight.Size = focused and UDim2.fromOffset(sizex, 1) or categoryhighlight.Size
			category.Focused = focused

			if focused then
				for _, v in legitapi.Categories do
					if v.Name ~= category.Name and v.Focused then
						v:SetVisible(false)
					end
				end
				updateCheck()
			end
		end

		if category.Focused then
			category:SetVisible(true)
			updateCheck()
		end

		category.Window = children
		table.insert(legitapi.Categories, category)
		return category
	end

	function legitapi:CreateModule(modulesettings)
		mainapi:Remove(modulesettings.Name)
		local moduleapi = {
			Enabled = false,
			ApiCategory = modulesettings.Category or config.Default,
			Options = {},
			Bind = {},
			Name = modulesettings.Name,
			DisplayName = modulesettings.Name,
			Tooltip = modulesettings.Tooltip,
			Panel = window,
			Legit = config.Field == 'Legit'
		}

		local module = Instance.new('TextButton')
		module.Name = modulesettings.Name
		module.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		module.Text = ''
		module.AutoButtonColor = false
		module.Parent = children
		addTooltip(module, modulesettings.Tooltip)
		addCorner(module)
		local title = Instance.new('TextButton')
		title.Name = 'Title'
		title.Size = UDim2.fromOffset(130, 20)
		title.Position = UDim2.fromOffset(16, 81)
		title.BackgroundTransparency = 1
		title.AutoButtonColor = false
		title.Text = moduleapi.DisplayName
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = color.Dark(uipallet.Text, 0.31)
		title.TextSize = 13
		title.FontFace = uipallet.Font
		title.Parent = module
		local knob = Instance.new('Frame')
		knob.Name = 'Knob'
		knob.Size = UDim2.fromOffset(22, 12)
		knob.Position = UDim2.new(1, -57, 0, 14)
		knob.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
		knob.Parent = module
		addCorner(knob, UDim.new(1, 0))
		local knobmain = knob:Clone()
		knobmain.Size = UDim2.fromOffset(8, 8)
		knobmain.Position = UDim2.fromOffset(2, 2)
		knobmain.BackgroundColor3 = uipallet.Main
		knobmain.Parent = knob
		local bind = Instance.new('TextButton')
		bind.Name = 'Bind'
		bind.Size = UDim2.fromOffset(20, 21)
		bind.Position = UDim2.new(1, -14, 1, -12)
		bind.AnchorPoint = Vector2.new(1, 1)
		bind.BackgroundColor3 = Color3.new(1, 1, 1)
		bind.BackgroundTransparency = 0.92
		bind.BorderSizePixel = 0
		bind.AutoButtonColor = false
		bind.Text = ''
		bind.Parent = module
		addCorner(bind, UDim.new(0, 4))
		addTooltip(bind, 'Click to bind')
		local bindicon = Instance.new('ImageLabel')
		bindicon.Name = 'Icon'
		bindicon.Size = UDim2.fromOffset(12, 12)
		bindicon.Position = UDim2.new(0.5, -6, 0, 5)
		bindicon.BackgroundTransparency = 1
		bindicon.Image = getcustomasset('ElevateV4/assets/new/bind.png')
		bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		bindicon.Parent = bind
		local bindtext = Instance.new('TextLabel')
		bindtext.Name = 'TextLabel'
		bindtext.Size = UDim2.fromScale(1, 1)
		bindtext.Position = UDim2.fromOffset(0, 1)
		bindtext.BackgroundTransparency = 1
		bindtext.Visible = false
		bindtext.Text = ''
		bindtext.TextColor3 = color.Dark(uipallet.Text, 0.43)
		bindtext.TextSize = 12
		bindtext.FontFace = uipallet.Font
		bindtext.Parent = bind
		local bindcover = Instance.new('ImageLabel')
		bindcover.Name = 'Cover'
		bindcover.Size = UDim2.fromOffset(154, 32)
		bindcover.Position = UDim2.new(0, 0, 1, -32)
		bindcover.BackgroundTransparency = 1
		bindcover.Visible = false
		bindcover.Image = getcustomasset('ElevateV4/assets/new/bindbkg.png')
		bindcover.ScaleType = Enum.ScaleType.Slice
		bindcover.SliceCenter = Rect.new(0, 0, 141, 40)
		bindcover.Parent = module
		local bindcovertext = Instance.new('TextLabel')
		bindcovertext.Name = 'Text'
		bindcovertext.Size = UDim2.new(1, -10, 1, -3)
		bindcovertext.BackgroundTransparency = 1
		bindcovertext.Text = 'PRESS A KEY TO BIND'
		bindcovertext.TextColor3 = uipallet.Text
		bindcovertext.TextSize = 11
		bindcovertext.FontFace = uipallet.Font
		bindcovertext.Parent = bindcover
		local dotsbutton = Instance.new('TextButton')
		dotsbutton.Name = 'Dots'
		dotsbutton.Size = UDim2.fromOffset(14, 24)
		dotsbutton.Position = UDim2.new(1, -27, 0, 8)
		dotsbutton.BackgroundTransparency = 1
		dotsbutton.Text = ''
		dotsbutton.Parent = module
		local dots = Instance.new('ImageLabel')
		dots.Name = 'Dots'
		dots.Size = UDim2.fromOffset(2, 12)
		dots.Position = UDim2.fromOffset(6, 6)
		dots.BackgroundTransparency = 1
		dots.Image = getcustomasset('ElevateV4/assets/new/dots.png')
		dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
		dots.Parent = dotsbutton
		local shadow = Instance.new('TextButton')
		shadow.Name = 'Shadow'
		shadow.Size = UDim2.new(1, 0, 1, -5)
		shadow.BackgroundColor3 = Color3.new()
		shadow.BackgroundTransparency = 1
		shadow.AutoButtonColor = false
		shadow.ClipsDescendants = true
		shadow.Visible = false
		shadow.Text = ''
		shadow.Parent = window
		addCorner(shadow)
		local settingspane = Instance.new('TextButton')
		settingspane.Size = UDim2.new(0, 220, 1, 0)
		settingspane.Position = UDim2.fromScale(1, 0)
		settingspane.BackgroundColor3 = uipallet.Main
		settingspane.AutoButtonColor = false
		settingspane.Text = ''
		settingspane.Parent = shadow
		local settingstitle = Instance.new('TextLabel')
		settingstitle.Name = 'Title'
		settingstitle.Size = UDim2.new(1, -36, 0, 20)
		settingstitle.Position = UDim2.fromOffset(36, 12)
		settingstitle.BackgroundTransparency = 1
		settingstitle.Text = modulesettings.Name
		settingstitle.TextXAlignment = Enum.TextXAlignment.Left
		settingstitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
		settingstitle.TextSize = 13
		settingstitle.FontFace = uipallet.Font
		settingstitle.Parent = settingspane
		local back = Instance.new('ImageButton')
		back.Name = 'Back'
		back.Size = UDim2.fromOffset(16, 16)
		back.Position = UDim2.fromOffset(11, 13)
		back.BackgroundTransparency = 1
		back.Image = getcustomasset('ElevateV4/assets/new/back.png')
		back.ImageColor3 = color.Light(uipallet.Main, 0.37)
		back.Parent = settingspane
		addCorner(settingspane)
		local settingschildren = Instance.new('ScrollingFrame')
		settingschildren.Name = 'Children'
		settingschildren.Size = UDim2.new(1, 0, 1, -45)
		settingschildren.Position = UDim2.fromOffset(0, 41)
		settingschildren.BackgroundColor3 = uipallet.Main
		settingschildren.BorderSizePixel = 0
		settingschildren.ScrollBarThickness = 2
		settingschildren.ScrollBarImageTransparency = 0.75
		settingschildren.CanvasSize = UDim2.new()
		settingschildren.Parent = settingspane
		local settingswindowlist = Instance.new('UIListLayout')
		settingswindowlist.SortOrder = Enum.SortOrder.LayoutOrder
		settingswindowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		settingswindowlist.Parent = settingschildren
		if modulesettings.Size or moduleapi.ApiCategory == 'Hud' then
			local modulechildren = Instance.new('Frame')
			modulechildren.Size = modulesettings.Size or UDim2.fromOffset(120, 28)
			modulechildren.BackgroundTransparency = 1
			modulechildren.Visible = false
			modulechildren.Parent = scaledgui
			makeDraggable(modulechildren, window)
			local objectstroke = Instance.new('UIStroke')
			objectstroke.Color = Color3.fromRGB(190, 115, 255)
			objectstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			objectstroke.Thickness = 0
			objectstroke.Parent = modulechildren
			moduleapi.Children = modulechildren
		end
		modulesettings.Function = modulesettings.Function or function() end
		addMaid(moduleapi)

		function moduleapi:SetDisplayName(displayName)
			self.DisplayName = tostring(displayName or self.Name)
			title.Text = self.DisplayName
			title.Size = UDim2.fromOffset(math.min(getfontsize(self.DisplayName, title.TextSize, title.FontFace).X + 4, 130), 20)
			settingstitle.Text = self.DisplayName
		end
		moduleapi:SetDisplayName(moduleapi.DisplayName)

		function moduleapi:SetBind(tab, mouse)
			if tab.Mobile then
				self.Bind = {}
				tab = self.Bind
			else
				self.Bind = table.clone(tab)
			end

			if mouse then
				bindcovertext.Text = #tab <= 0 and 'BIND REMOVED' or 'BOUND TO'
				bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 32)
				task.delay(1, function()
					bindcover.Visible = false
				end)
			end

			if #tab <= 0 then
				bindtext.Visible = false
				bindicon.Visible = true
				bind.Size = UDim2.fromOffset(20, 21)
			else
				bindtext.Visible = true
				bindicon.Visible = false
				bindtext.Text = table.concat(tab, ' + '):upper()
				bind.Size = UDim2.fromOffset(math.max(getfontsize(bindtext.Text, bindtext.TextSize, bindtext.Font).X + 10, 20), 21)
			end
		end

		function moduleapi:Toggle()
			moduleapi.Generation += 1
			local generation = moduleapi.Generation
			moduleapi.Enabled = not moduleapi.Enabled
			if mainapi.ScheduleSave then mainapi:ScheduleSave() end
			if moduleapi.Children then
				moduleapi.Children.Visible = moduleapi.Enabled
			end
			title.TextColor3 = moduleapi.Enabled and color.Light(uipallet.Text, 0.2) or color.Dark(uipallet.Text, 0.31)
			module.BackgroundColor3 = moduleapi.Enabled and color.Light(uipallet.Main, 0.05) or module.BackgroundColor3
			bindicon.ImageColor3 = moduleapi.Enabled and color.Light(uipallet.Text, 0.2) or color.Dark(uipallet.Text, 0.43)
			bindtext.TextColor3 = bindicon.ImageColor3
			tween:Tween(knob, uipallet.Tween, {
				BackgroundColor3 = moduleapi.Enabled and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or color.Light(uipallet.Main, 0.14)
			})
			tween:Tween(knobmain, uipallet.Tween, {
				Position = UDim2.fromOffset(moduleapi.Enabled and 12 or 2, 2)
			})
			if not moduleapi.Enabled then moduleapi:Cleanup() end
			local enabled = moduleapi.Enabled
			local currentThread = coroutine.running()
			if moduleapi.LifecycleThread and moduleapi.LifecycleThread ~= currentThread then
				pcall(task.cancel, moduleapi.LifecycleThread)
			end
			local token = {}
			moduleapi.LifecycleToken = token
			local lifecycleThread = coroutine.create(function()
				local ok, err = xpcall(function()
					modulesettings.Function(enabled)
				end, function(message) return tostring(message) end)
				if not ok and mainapi.RecordError then
					mainapi:RecordError(moduleapi.Name, err)
				end
				if moduleapi.LifecycleToken == token then
					moduleapi.LifecycleThread = nil
				end
			end)
			moduleapi.LifecycleThread = lifecycleThread
			task.spawn(lifecycleThread)
		end


		back.MouseEnter:Connect(function()
			back.ImageColor3 = uipallet.Text
		end)
		back.MouseLeave:Connect(function()
			back.ImageColor3 = color.Light(uipallet.Main, 0.37)
		end)
		back.MouseButton1Click:Connect(function()
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 1
			})
			tween:Tween(settingspane, uipallet.Tween, {
				Position = UDim2.fromScale(1, 0)
			})
			task.wait(0.2)
			shadow.Visible = false
		end)
		dotsbutton.MouseButton1Click:Connect(function()
			shadow.Visible = true
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 0.5
			})
			tween:Tween(settingspane, uipallet.Tween, {
				Position = UDim2.new(1, -220, 0, 0)
			})
		end)
		dotsbutton.MouseEnter:Connect(function()
			dots.ImageColor3 = uipallet.Text
		end)
		dotsbutton.MouseLeave:Connect(function()
			dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
		end)
		bind.MouseEnter:Connect(function()
			bindtext.Visible = false
			bindicon.Visible = true
			bindicon.Image = getcustomasset('ElevateV4/assets/new/edit.png')
			if not moduleapi.Enabled then bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.16) end
		end)
		bind.MouseLeave:Connect(function()
			bindtext.Visible = #moduleapi.Bind > 0
			bindicon.Visible = not bindtext.Visible
			bindicon.Image = getcustomasset('ElevateV4/assets/new/bind.png')
			if not moduleapi.Enabled then bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43) end
		end)
		bind.MouseButton1Click:Connect(function()
			bindcovertext.Text = 'PRESS A KEY TO BIND'
			bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 32)
			bindcover.Visible = true
			mainapi.Binding = moduleapi
		end)
		local function openSettings()
			shadow.Visible = true
			if tooltip then
				tooltipOwner = nil
				tooltip.Visible = false
			end
			tween:Tween(shadow, uipallet.Tween, {BackgroundTransparency = 0.5})
			tween:Tween(settingspane, uipallet.Tween, {Position = UDim2.new(1, -220, 0, 0)})
		end
		local titleActive = mainapi:BindModuleTitle(moduleapi, title, function()
			moduleapi:Toggle()
		end, openSettings)
		module.MouseEnter:Connect(function()
			if not moduleapi.Enabled then
				module.BackgroundColor3 = color.Light(uipallet.Main, 0.05)
			end
		end)
		module.MouseLeave:Connect(function()
			if not moduleapi.Enabled then
				module.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			end
		end)
		module.MouseButton1Click:Connect(function()
			if titleActive() then return end
			moduleapi:Toggle()
		end)
		module.MouseButton2Click:Connect(function()
			if titleActive() then return end
			openSettings()
		end)
		shadow.MouseButton1Click:Connect(function()
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 1
			})
			tween:Tween(settingspane, uipallet.Tween, {
				Position = UDim2.fromScale(1, 0)
			})
			task.wait(0.2)
			shadow.Visible = false
		end)
		settingswindowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			settingschildren.CanvasSize = UDim2.fromOffset(0, settingswindowlist.AbsoluteContentSize.Y / scale.Scale)
		end)

		for i, v in components do
			moduleapi['Create'..i] = function(_, optionsettings)
				return mainapi:AttachContextualOption(v(optionsettings, settingschildren, moduleapi), optionsettings)
			end
		end

		moduleapi.Object = module
		legitapi.Modules[modulesettings.Name] = moduleapi

		local sorting = {}
		for _, v in legitapi.Modules do
			table.insert(sorting, v.Name)
		end
		table.sort(sorting)

		for i, v in sorting do
			legitapi.Modules[v].Object.LayoutOrder = i
		end

		return moduleapi
	end
	mainapi:Clean(searchvalue:GetPropertyChangedSignal('Text'):Connect(updateCheck))

	local function visibleCheck()
		for _, v in legitapi.Modules do
			if v.Children then
				local visible = clickgui.Visible
				for _, v2 in self.Windows do
					visible = visible or v2.Visible
				end
				v.Children.Visible = (not visible or window.Visible) and v.Enabled
			end
		end
	end

	close.MouseButton1Click:Connect(function()
		window.Visible = false
		clickgui.Visible = true
	end)
	self:Clean(clickgui:GetPropertyChangedSignal('Visible'):Connect(visibleCheck))
	window:GetPropertyChangedSignal('Visible'):Connect(function()
		self:UpdateGUI(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
		visibleCheck()
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
	end)

	self[config.Field] = legitapi

	for _, tab in config.Tabs do
		legitapi:CreateCategory(tab)
	end

	return legitapi
end

function mainapi:CreateLegit()
	return createPanel({
		Field = 'Legit',
		Window = 'LegitGUI',
		Icon = 'ElevateV4/assets/new/legittab.png',
		Tabs = {'All', 'Hud', 'Game', 'Visuals'},
		Default = 'Game'
	})
end
function mainapi:CreateKits()

-- Wire kit modules (vape.Categories.Kits) to the Kits panel + category
pcall(function()
	if mainapi.Kits then
		mainapi.Categories.Kits = mainapi.Kits
	end
end)

	return createPanel({
		Field = 'Kits',
		Window = 'KitsGUI',
		Icon = 'ElevateV4/assets/new/friendstab.png',
		Tabs = {'All', 'Auto', 'Ability', 'Aim', 'Visual'},
		Default = 'Auto'
	})
end

function mainapi:CreateOnline()
	local api = {}
	local window = Instance.new('Frame')
	window.Name = 'ElevateV4Home'
	window.Size = UDim2.fromOffset(208, 382)
	window.Position = UDim2.new(0.5, -104, 0.5, -191)
	window.BackgroundColor3 = uipallet.Main
	window.Visible, window.Parent = false, scaledgui
	addBlur(window); addCorner(window); addWindowStroke(window); makeDraggable(window)
	local logo = Instance.new('ImageLabel')
	logo.Name = 'Icon'; logo.Size = UDim2.fromOffset(16, 16); logo.Position = UDim2.fromOffset(10, 10)
	logo.BackgroundTransparency = 1; logo.Image = getcustomasset('ElevateV4/assets/new/aetherlogo.png')
	logo.ImageColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value); logo.Parent = window
	local title = Instance.new('TextLabel')
	title.Size, title.Position = UDim2.fromOffset(140, 38), UDim2.fromOffset(36, 0)
	title.BackgroundTransparency, title.Text = 1, 'ElevateV4 Home'
	title.TextColor3, title.TextSize, title.FontFace = uipallet.Text, 14, uipallet.Font
	title.TextXAlignment, title.Parent = Enum.TextXAlignment.Left, window
	local close = addCloseButton(window)
	local divider = Instance.new('Frame')
	divider.Size, divider.Position = UDim2.new(1, 0, 0, 1), UDim2.fromOffset(0, 38)
	divider.BorderSizePixel, divider.BackgroundColor3, divider.BackgroundTransparency, divider.Parent = 0, color.Light(uipallet.Main, 0.15), 0.5, window
	local avatar = Instance.new('ImageLabel')
	avatar.Size, avatar.Position = UDim2.fromOffset(52, 52), UDim2.fromOffset(78, 52)
	avatar.BackgroundColor3, avatar.BorderSizePixel = color.Light(uipallet.Main, 0.05), 0
	avatar.Image, avatar.ScaleType, avatar.Parent = getcustomasset('ElevateV4/assets/new/aetherlogo.png'), Enum.ScaleType.Fit, window
	addCorner(avatar, UDim.new(1, 0))
	local welcome = Instance.new('TextLabel')
	welcome.Size, welcome.Position = UDim2.new(1, -16, 0, 24), UDim2.fromOffset(8, 116)
	welcome.BackgroundTransparency, welcome.Text = 1, 'Welcome to ElevateV4'
	welcome.TextColor3, welcome.TextSize, welcome.FontFace, welcome.Parent = uipallet.Text, 16, uipallet.FontSemiBold, window
	local function row(y, heading, value)
		local frame = Instance.new('Frame'); frame.Size, frame.Position = UDim2.fromOffset(192, 46), UDim2.fromOffset(8, y)
		frame.BackgroundColor3, frame.BorderSizePixel, frame.Parent = color.Light(uipallet.Main, 0.035), 0, window; addCorner(frame)
		local label = Instance.new('TextLabel'); label.Size, label.Position = UDim2.new(1, -20, 0, 18), UDim2.fromOffset(10, 5)
		label.BackgroundTransparency, label.Text, label.TextColor3, label.TextSize, label.FontFace = 1, heading, uipallet.Text, 12, uipallet.FontSemiBold
		label.TextXAlignment, label.Parent = Enum.TextXAlignment.Left, frame
		local detail = label:Clone(); detail.Name, detail.Position, detail.Text, detail.TextColor3, detail.TextSize, detail.FontFace = 'Detail', UDim2.fromOffset(10, 23), value, color.Dark(uipallet.Text, 0.32), 11, uipallet.Font; detail.Parent = frame
		return frame
	end
	local executorName = 'Unknown executor'
	pcall(function()
		executorName = identifyexecutor and select(1, identifyexecutor()) or executorName
	end)
	local gameRow = row(146, 'Current game', 'Detecting…')
	local kitRow = row(194, 'Detected kit', 'Checking…')
	local profileRow = row(242, 'Current profile', tostring(mainapi.Profile))
	local sessionRow = row(290, 'ElevateV4', 'v'..tostring(mainapi.Version)..' • 0m')
	local status = Instance.new('TextLabel')
	status.Size, status.Position = UDim2.fromOffset(192, 28), UDim2.fromOffset(8, 342)
	status.BackgroundColor3, status.Text = color.Light(uipallet.Main, 0.035), '●  LOCAL CLIENT'
	status.TextColor3, status.TextSize, status.FontFace, status.Parent = Color3.fromRGB(99, 220, 130), 11, uipallet.FontSemiBold, window
	addCorner(status)
	function api:Open() window.Visible = true end
	function api:Close() window.Visible = false end
	close.MouseButton1Click:Connect(function() api:Close() end)
	local function detectedGameName()
		if game.GameId == 2619619496 or table.find({6872265039, 6872274481}, tonumber(mainapi.Place) or game.PlaceId) then
			return 'BedWars'
		end
		local info = mainapi.GameInfo
		return type(info) == 'table' and type(info.Name) == 'string' and info.Name ~= '' and info.Name
			or tostring(game.Name)
	end
	local function detectedKit(player)
		if detectedGameName() ~= 'BedWars' then return 'Not applicable' end
		local info = mainapi.GameInfo
		if type(info) == 'table' and type(info.GetKit) == 'function' then
			local ok, kit, ready = pcall(info.GetKit)
			if ok and kit ~= nil and tostring(kit) ~= '' and tostring(kit):lower() ~= 'none' then
				return tostring(kit)
			end
			if ok and ready == true then return 'No kit equipped' end
		end
		for _, attribute in {'PlayingAsKit', 'PlayingAsKits', 'SelectedKit', 'Kit', 'kit'} do
			local kit = player:GetAttribute(attribute)
			if kit ~= nil and tostring(kit) ~= '' and tostring(kit):lower() ~= 'none' then return tostring(kit) end
		end
		return 'Detecting…'
	end
	local function refreshIdentityRows()
		gameRow.Detail.Text = detectedGameName():sub(1, 32)
		kitRow.Detail.Text = detectedKit(cloneref(game:GetService('Players')).LocalPlayer):sub(1, 30)
	end
	mainapi:Clean(mainapi.GameInfoChanged.Event:Connect(refreshIdentityRows))
	for _, attribute in {'PlayingAsKit', 'PlayingAsKits', 'SelectedKit', 'Kit', 'kit'} do
		mainapi:Clean(cloneref(game:GetService('Players')).LocalPlayer:GetAttributeChangedSignal(attribute):Connect(refreshIdentityRows))
	end
	refreshIdentityRows()
	task.spawn(function()
		local players = cloneref(game:GetService('Players'))
		local player = players.LocalPlayer
		local ok, image = pcall(players.GetUserThumbnailAsync, players, player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		if ok and avatar.Parent then avatar.Image = image end
		while window.Parent do
			if window.Visible then
				refreshIdentityRows()
				profileRow.Detail.Text = tostring(mainapi.Profile)
				sessionRow.Detail.Text = 'v'..tostring(mainapi.Version)..' • '..math.floor((os.clock() - (mainapi.StartedAt or os.clock())) / 60)..'m'
			end
			task.wait(1)
		end
	end)
	mainapi:Clean(window); self.Online = api
	return api
end
local refreshVersionHistory
local versionHistoryLoadedAt = nil

function mainapi:CreateChangelogs()
	local api = {}
	local window = Instance.new('Frame')
	window.Name, window.Size, window.Position = 'ChangelogsGUI', UDim2.fromOffset(700, 389), UDim2.new(0.5, -350, 0.5, -194)
	window.BackgroundColor3, window.Visible, window.Parent = uipallet.Main, false, scaledgui
	addBlur(window); addCorner(window); makeDraggable(window)
	local title = Instance.new('TextLabel')
	title.Size, title.Position, title.BackgroundTransparency = UDim2.new(1, -47, 0, 40), UDim2.fromOffset(12, 0), 1
	title.Text, title.TextColor3, title.TextSize, title.FontFace = 'ElevateV4 Update Center', uipallet.Text, 14, uipallet.Font
	title.TextXAlignment, title.Parent = Enum.TextXAlignment.Left, window
	local close = addCloseButton(window)
	local status = Instance.new('TextLabel')
	status.Size, status.Position, status.BackgroundTransparency = UDim2.new(1, -166, 0, 16), UDim2.fromOffset(14, 34), 1
	status.TextXAlignment, status.TextColor3, status.TextSize, status.FontFace = Enum.TextXAlignment.Left, color.Dark(uipallet.Text, 0.38), 10, uipallet.Font
	status.Text = 'Installed: v'..tostring(mainapi.Version)..'  •  Latest source: checking…'
	status.Parent = window
	local update = Instance.new('TextButton')
	update.Size, update.Position = UDim2.fromOffset(128, 24), UDim2.new(1, -138, 0, 31)
	update.BackgroundColor3, update.Text, update.TextColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value), 'Update / Reinject', mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	update.TextSize, update.FontFace, update.Parent = 10, uipallet.Font, window
	addCorner(update, UDim.new(0, 4))
	update.MouseButton1Click:Connect(function() if mainapi.ReloadAether then mainapi.ReloadAether() end end)
	local notes = Instance.new('ScrollingFrame')
	notes.Size, notes.Position = UDim2.new(1, -20, 1, -74), UDim2.fromOffset(10, 64)
	notes.BackgroundColor3, notes.BorderSizePixel, notes.ScrollBarThickness = color.Dark(uipallet.Main, 0.025), 0, 2
	notes.AutomaticCanvasSize, notes.CanvasSize, notes.Parent = Enum.AutomaticSize.Y, UDim2.new(), window
	addCorner(notes)
	local body = Instance.new('TextLabel')
	body.Size, body.Position, body.AutomaticSize = UDim2.new(1, -28, 0, 0), UDim2.fromOffset(14, 12), Enum.AutomaticSize.Y
	body.BackgroundTransparency, body.RichText = 1, true
	body.Text = [=[<b><font color="#d378ff">v3.19.5 - Booster kit, LobbyExploit and ChestSteal</font></b>
<b><font color="#d378ff">BedFight</font></b>
<font color="#63dc82">[+]</font> Booster (Experimental) runs the Booster kit jetpack through five sub-modules you can use together
<font color="#63dc82">[+]</font> Booster InfiniteFuel keeps your jetpack fuel full
<font color="#63dc82">[+]</font> Booster FloatBypass taps the jetpack on and off over the void so you hover almost level without being pulled back
<font color="#63dc82">[+]</font> Booster NoFallDamage taps the jetpack once just before you land from a fall that would hurt
<font color="#63dc82">[+]</font> Booster AntiVoid flies you back up when you fall into the void and hovers until there is ground under you
<font color="#63dc82">[+]</font> Booster AntiHit lifts your hitbox out of sword reach and keeps it up with the jetpack instead of touching the ground
<font color="#63dc82">[+]</font> LobbyExploit (Experimental) carries your lobby Arrows and Fireballs into the match through your team chest
<font color="#63dc82">[+]</font> ChestSteal takes items from team chests you are standing next to
<font color="#6aa9ff">[^]</font> AutoBank has a While rubberbanding option that banks everything the chest takes while the server pulls you back
<font color="#6aa9ff">[^]</font> AutoBank Whitelist only lists items the team chest takes
<font color="#6aa9ff">[^]</font> Fly has a Disable without ground toggle, so it can keep flying when there is no ground to touch
<font color="#ff6b6b">[!]</font> AutoBank While falling, AutoPearl and AutoVoidDrop no longer mistake an ordinary fall for falling into the void
<font color="#ff9f43">[-]</font> Removed ChestManager, whose looting is now ChestSteal and whose banking is part of AutoBank
<font color="#ff9f43">[-]</font> Removed InfJetpack, which Booster InfiniteFuel replaces
<b><font color="#d378ff">General</font></b>
<font color="#ff6b6b">[!]</font> Running ElevateV4 again no longer switches the owner panel off
<font color="#ff6b6b">[!]</font> Usage data keeps one session across a reinject and reports the game you are in from the start
<b><font color="#d378ff">GUI</font></b>
<font color="#63dc82">[+]</font> Modules can show sub-modules as collapsible cards, each with its own switch and settings

<b><font color="#d378ff">v3.19.4 - TPGlide, AutoWin, AutoObby and every tooltip</font></b>
<b><font color="#d378ff">Universal</font></b>
<font color="#63dc82">[+]</font> AutoObby teleports you to every checkpoint of an obby in order until none are left, and is removed in BedWars, BedFight, SkyWars and Tribes 3v3
<font color="#63dc82">[+]</font> AutoObby finds checkpoints by tag, spawn point and name, can skip stages you have finished, and waits its Delay at each one
<font color="#63dc82">[+]</font> NoSlide stops you sliding on ice and other slippery floors without changing your walk speed
<font color="#63dc82">[+]</font> ForceShiftLock forces shift lock on or off and toggles with Ctrl or Left Shift
<font color="#6aa9ff">[^]</font> MotionBlur, TimeChanger, TransparentCharacter, PlayerOutline, Legless, Headless, AntiVision, GameThemes, NearbyWarn, MemoryFixer and MP3Player now work in every game, and the BedWars and BedFight copies are gone
<font color="#6aa9ff">[^]</font> AntiFling has a Stop ragdoll toggle, which replaces AntiRagdoll
<font color="#ff9f43">[-]</font> Removed Desync and Blink
<font color="#ff6b6b">[!]</font> StaffDetector no longer checks you, its automatic Role no longer counts every member as staff when the staff role shares the lowest rank, and one detection starts one Uninject
<b><font color="#d378ff">BedWars</font></b>
<font color="#6aa9ff">[^]</font> InfiniteFlyV2 turns NoFallDamage on only near the ground while you fly and puts its state back afterwards
<font color="#6aa9ff">[^]</font> InfiniteFlyV2 keeps falling until there is ground, puts you down on it and restores your view, and waits over the void
<font color="#ff6b6b">[!]</font> StaffDetector starts one Uninject per detection, and AutoConfig no longer stops at the first module it reaches
<font color="#ff6b6b">[!]</font> InfiniteFlyV2 no longer leaves your character invisible until you respawn, it only restores the parts it hid and only if they are still hidden
<b><font color="#d378ff">SkyWars</font></b>
<font color="#6aa9ff">[^]</font> Killaura plays one swing a frame however many targets it hits, and only updates its boxes and particles when they change
<font color="#6aa9ff">[^]</font> InfiniteAura, PlayerAttach, ProjectileAura, Viewmodel and EggESP do less work each frame
<font color="#6aa9ff">[^]</font> The void height check no longer walks every block in the map, and the ping is read once a frame
<b><font color="#d378ff">BedFight</font></b>
<font color="#63dc82">[+]</font> TPGlide replaces LongGlide and moves your hidden hitbox ahead in hops of up to 100 studs, resting on ground or a single placed block between hops
<font color="#63dc82">[+]</font> TPGlide follows your camera or the nearest enemy bed, and Stop near enemy bed turns it off and brings you to the hitbox once you are in Bed range
<font color="#6aa9ff">[^]</font> TPGlide picks the hop length itself and uses a block only over a gap, and its hops go over or around walls instead of through them
<font color="#6aa9ff">[^]</font> AutoWin now travels with TPGlide hops, lands beside the bed instead of above it and stops 12 studs away so Breaker can reach
<font color="#6aa9ff">[^]</font> AutoWin restocks only when out of blocks, and Blocks to keep sets how many it holds, defaulting to 6
<font color="#6aa9ff">[^]</font> AutoWin goes home at low Health until Recover health, avoids groups of three or more enemies, eats when hurt, and buys better swords and armour while at home
<font color="#6aa9ff">[^]</font> AutoWin switches on Killaura, AntiVoid, AntiHit, AntiSuffocate and Breaker while it runs, and puts them back when it stops
<font color="#ff6b6b">[!]</font> AutoWin no longer buys dozens of wool at once, hangs high above a bed, crosses blocks and takes suffocation damage, or keeps heading for gear you already beat
<font color="#6aa9ff">[^]</font> AntiHit and Killaura keep the hitbox at most 9 studs above the target while striking and lower it further when hits stop landing, so Killaura no longer only hits jumping players
<font color="#6aa9ff">[^]</font> AutoBank Whitelist now offers Swords, Armour, Pickaxes, Ranged, Emerald, Diamond, Iron, Telepearl, Arrow and Wool, and Custom Whitelist takes exact item names
<font color="#6aa9ff">[^]</font> AutoBuy buys in the order of its Buy list (Swords, Armor, Pickaxes, Bow, Crossbow, Arrows, Wool) and saves for a higher item before buying a lower one that uses the same resource
<font color="#6aa9ff">[^]</font> AutoWin buys only the wool a trip needs, working out the stones from the shop to the goal, and Extra blocks adds more on top
<font color="#6aa9ff">[^]</font> AutoWin no longer goes shopping for blocks it does not need, such as at the start of a ranked match with none
<font color="#6aa9ff">[^]</font> TPGlide finds its way through a one block opening, down out of a building and around a roof, and stops placing stones above a bed once it is within reach
<font color="#6aa9ff">[^]</font> TPGlide ends up inside a walled base when AutoWin fights an enemy there, instead of outside it
<font color="#ff6b6b">[!]</font> CheatDetector works again, and only counts players in a live match, with kit, spawn, damage and Teleorb allowances
<font color="#6aa9ff">[^]</font> CheatDetector flags speed above 28 studs a second, floating, teleports, a drop into the void and straight back, and a hitbox bouncing up and down
<font color="#63dc82">[+]</font> StaffDetector has its own BedFight version that checks for group rank 200, with Uninject, Leave, Profile, AutoConfig and Notify modes
<font color="#63dc82">[+]</font> AutoQueue presses Play Again after a ranked match, with Play again after ranked and Play again delay
<b><font color="#d378ff">General</font></b>
<font color="#6aa9ff">[^]</font> Every module and option tooltip in every game is rewritten to be shorter, clearer and worded the same where options match
<font color="#6aa9ff">[^]</font> CheatDetector describes what it flags in plain words
<b><font color="#d378ff">GUI</font></b>
<font color="#6aa9ff">[^]</font> The menu button only appears on touch devices, starts somewhere free, can be dragged, and stays where you put it until you leave
<font color="#6aa9ff">[^]</font> The start notice says to press the ElevateV4 button
<font color="#ff6b6b">[!]</font> The Panel category now shows for the owner account after a reinject, which used to stop it
<b><font color="#d378ff">v3.19.3 - Tick lists, Trajectories rework and a Delta fix</font></b>
<b><font color="#d378ff">Universal</font></b>
<font color="#6aa9ff">[^]</font> Keystrokes picks which keys to show (Spacebar, each mouse button, CPS) from one tick list, so its settings reset once
<b><font color="#d378ff">BedWars</font></b>
<font color="#6aa9ff">[^]</font> Trajectories now follows the game's own aim, so it works for every projectile the game aims, fireballs and telepearls included, and lines up with the game's line
<font color="#6aa9ff">[^]</font> Trajectories follows the shot to the first block, player or mob it hits and marks that spot
<font color="#63dc82">[+]</font> Trajectories highlights the player or mob the shot will hit
<font color="#63dc82">[+]</font> Trajectories hides the game's own aim line and hit marker while it is on, and they come back when it is off
<font color="#ff6b6b">[!]</font> Trajectories no longer goes missing, draws in the wrong place or passes straight through players
<font color="#6aa9ff">[^]</font> AutoBuy, Breaker, NoFallDamage, EntityAnalyser, AutoConsume, AutoAdetunde, AutoPyro, AutoUma, ReplayMod and InfoEditor pick from tick lists instead of rows of toggles, so those settings reset once
<font color="#6aa9ff">[^]</font> Killaura, KillauraOLD and AutoShoot put their kit weapons in one Also use list
<font color="#6aa9ff">[^]</font> NickHider in the lobby picks what to hide from one list
<font color="#ff6b6b">[!]</font> GeneratorESP's generator list shows again and is the filter itself, the separate whitelist toggle is gone
<font color="#ff6b6b">[!]</font> AutoConsume's forest mushroom and buff list settings show whenever those entries are ticked
<b><font color="#d378ff">SkyWars</font></b>
<font color="#6aa9ff">[^]</font> AutoBuy picks blacksmith upgrades and team upgrades from two tick lists, so its settings reset once
<b><font color="#d378ff">BedFight</font></b>
<font color="#6aa9ff">[^]</font> AutoBuy picks gear and team upgrades from two tick lists, so its settings reset once
<b><font color="#d378ff">Tribes 3v3</font></b>
<font color="#6aa9ff">[^]</font> GunMods picks what to remove, recoil, shake or spread, from one list
<b><font color="#d378ff">General</font></b>
<font color="#ff6b6b">[!]</font> On Delta, starting in BedWars no longer scans the whole game memory, the likely cause of crashes on execute
<font color="#6aa9ff">[^]</font> On Delta, a launch that did not finish is reported by the next one, which records each step so the cause can be found
<b><font color="#d378ff">GUI</font></b>
<font color="#6aa9ff">[^]</font> Tick lists show up to seven entries and scroll, show readable names and fit their title to the space
<b><font color="#d378ff">v3.19.2 - Groups, pickers and seven new modules</font></b>
<b><font color="#d378ff">Universal</font></b>
<font color="#63dc82">[+]</font> Added SkeletonESP, which draws a line skeleton on players through walls, for both R15 and R6 characters
<font color="#63dc82">[+]</font> SkeletonESP can use team colours and has Thickness, Transparency, a Distance limit and Priority Only
<font color="#63dc82">[+]</font> Added Glide, which caps how fast you fall while you hold Space
<font color="#63dc82">[+]</font> Glide only kicks in when the ground is further below than your jump height, so normal jumps are never slowed
<font color="#63dc82">[+]</font> Glide's fall speed can be set, and Only when holding Space can be turned off to glide whenever you fall further than a jump
<font color="#63dc82">[+]</font> Added AntiKillParts, which stops kill bricks and lava from touching you, on your screen only
<font color="#63dc82">[+]</font> AntiKillParts finds kill parts by their names, picks up new ones as they appear and can learn any part that hurts you on touch
<font color="#63dc82">[+]</font> AntiKillParts has a whitelist and puts every part back exactly when you turn it off
<font color="#63dc82">[+]</font> Added MapCleaner, which hides trees, foliage, props, particles and decals on your screen only
<font color="#63dc82">[+]</font> MapCleaner keeps hidden objects solid by default, never hides BedWars blocks and restores everything exactly when turned off
<font color="#63dc82">[+]</font> Added BetterChat, a chat window you can move and make see-through, for both the new and the legacy chat
<font color="#63dc82">[+]</font> BetterChat shows timestamps, names in team colours and a scrollable history, and has its own message box
<font color="#63dc82">[+]</font> BetterChat can hide the game's own chat, opens with / while it does, and remembers where you put it
<b><font color="#d378ff">BedWars</font></b>
<font color="#63dc82">[+]</font> Added AutoHalloween, which plays Marrow's Madness and Arachne's Lair for you
<font color="#63dc82">[+]</font> AutoHalloween picks your Arachne's Lair class, takes Damage or Health upgrades and runs Killaura and ProjectileAura for the fights, then gives your own settings back
<font color="#63dc82">[+]</font> Added LegitAutoWin, which plays the match like a person: it only walks, turns at a human speed and clicks at a human rate
<font color="#63dc82">[+]</font> LegitAutoWin weighs shopping, farming, covering your bed, raiding beds and fighting as the match changes, with Aggressive, Defensive and Balanced styles
<font color="#63dc82">[+]</font> Added Trajectories, which draws the arc of your bow, crossbow or headhunter shot while you draw it
<font color="#63dc82">[+]</font> Trajectories uses how long you have been drawing, stops at the first thing the shot would hit and marks the landing spot, red over a player
<font color="#63dc82">[+]</font> Added CustomKillFeed, a kill feed with team coloured names, the killer's weapon icon, a FINAL tag on final kills and bed breaks
<font color="#63dc82">[+]</font> CustomKillFeed highlights your own kills and deaths, can show only your or your team's kills, and can hide the game's own feed
<font color="#6aa9ff">[^]</font> AutoConsume can eat the forest mushrooms near you without walking up to them, with a choice of Speed, Heal, Shield or Dizzy
<font color="#6aa9ff">[^]</font> AutoConsume eats Heal mushrooms only below your Health Percent
<font color="#6aa9ff">[^]</font> AutoConsume's buff items and NameTags' inventory items are picked from a grid of item icons, so those lists reset once
<font color="#6aa9ff">[^]</font> GeneratorESP, AutoCyber and AutoChestSplit pick iron, diamond and emerald from a tick list, so those lists reset once
<font color="#6aa9ff">[^]</font> AutoEnchant lists every enchant in the game to tick, so its list resets once
<font color="#ff9f43">[-]</font> Removed ProjectileLanding, Trajectories replaces it
<font color="#ff6b6b">[!]</font> Speed and Fly measure how fast the game already moves you and only add the rest, so they no longer go over the speed you set
<font color="#ff6b6b">[!]</font> Turning Speed off no longer leaves you moving faster than normal
<font color="#ff6b6b">[!]</font> BeehiveESP, CollectableESP, CrateESP, CropESP, GeneratorESP, InventoryESP, LootESP, PotESP, StorageESP and TrapESP options no longer show while the module is off
<font color="#ff6b6b">[!]</font> Universal Combat and Render modules are no longer listed in the BedWars lobby
<b><font color="#d378ff">SkyWars</font></b>
<font color="#6aa9ff">[^]</font> ItemCollector picks its drops from a tick list instead of a typed list, so it resets once
<b><font color="#d378ff">BedFight</font></b>
<font color="#6aa9ff">[^]</font> AutoBank picks Iron, Diamond and Emerald from a tick list, so its whitelist resets once
<font color="#6aa9ff">[^]</font> ProjectileAura picks Bow, Crossbow, Fireball, Teleorb and Hotdog from a tick list, so its weapon list resets once
<b><font color="#d378ff">General</font></b>
<font color="#ff6b6b">[!]</font> The loading screen goes away by itself after a minute if a game takes too long to load
<b><font color="#d378ff">GUI</font></b>
<font color="#63dc82">[+]</font> Added tick lists: pick several choices from one list that stays open, and the closed row shows what is picked
<font color="#63dc82">[+]</font> Added item grids: search for items by name, see their icons, and the closed row shows the icons you picked
<font color="#63dc82">[+]</font> Added groups: options that belong to a toggle sit under it and only show while it is on
<font color="#6aa9ff">[^]</font> About 100 modules now use groups, so their extra options fold away with the toggle they belong to
<font color="#ff6b6b">[!]</font> Options under a toggle no longer show or hide wrongly depending on the order your config loads in

<b><font color="#d378ff">v3.19.1 - Loading screen and MelodyExploit</font></b>
<b><font color="#d378ff">General</font></b>
<font color="#63dc82">[+]</font> ElevateV4 shows its logo in the middle of the screen while it loads, over a darker, blurred background
<font color="#6aa9ff">[^]</font> The mobile menu button shows the ElevateV4 logo and moves itself so it never covers the game's own buttons
<font color="#6aa9ff">[^]</font> NEW and UPDATED tags only show on modules in the game they were changed for
<font color="#6aa9ff">[^]</font> Every code comment was removed, so the script is smaller to download and load
<font color="#ff6b6b">[!]</font> Fixed many settings that failed silently while the menu was built, so options show and hide with their toggles again
<font color="#ff6b6b">[!]</font> Fixed the Text GUI settings, Keystrokes and the ReachDisplay font erroring when ElevateV4 loads
<b><font color="#d378ff">BedWars</font></b>
<font color="#63dc82">[+]</font> Added MelodyExploit, which heals you with the guitar while keeping your sword in hand and buys a guitar when you have none
<font color="#6aa9ff">[^]</font> AutoBank now uses your personal chest: it banks your whitelist there and takes it back out while a shop is open
<font color="#ff9f43">[-]</font> Removed AutoBank's Skybox mode
<font color="#ff6b6b">[!]</font> Speed and Fly use the original speed maths again, so they move at the speed you set
<font color="#ff6b6b">[!]</font> Interface's hotbar, health bar and queue card options work again

<b><font color="#d378ff">v3.19.0 - The Panel</font></b>
<b><font color="#d378ff">General</font></b>
<font color="#63dc82">[+]</font> Added the Panel, an owner-only tab that lists every ElevateV4 user in your server with their headshot and name and sends them a command
<font color="#6aa9ff">[^]</font> Click one or more users in the Panel to pick who its modules act on
<font color="#ff6b6b">[!]</font> Panel Kill, Uninject, Reveal and Unhittable now take effect on the target instead of doing nothing
<b><font color="#d378ff">BedFight</font></b>
<font color="#63dc82">[+]</font> Added AutoBank, which puts your resources in the team chest when you drop low or fall into the void, and takes them back after
<font color="#63dc82">[+]</font> Added AntiSuffocate, which gets you out when you are stuck inside blocks
<font color="#63dc82">[+]</font> Added AntiBedBreak, which deals with enemies who hide their head in a block so your hits cannot reach them
<font color="#63dc82">[+]</font> Added BedAssist, which uses TNT and fireballs on enemy beds without touching your hotbar
<font color="#63dc82">[+]</font> Added Desync, which keeps you standing in place for everyone else while you move freely
<font color="#6aa9ff">[^]</font> AntiVoid has a Hitbox mode that keeps your hitbox on the ground so you can float over the void
<font color="#6aa9ff">[^]</font> BoxAura boxes each enemy once a life where they will be, with an Auto box size
<font color="#6aa9ff">[^]</font> AutoBuy buys stacks of wool and arrows several at a time
<font color="#6aa9ff">[^]</font> AutoWin can cross gaps with InfiniteFly or LongJump
<font color="#6aa9ff">[^]</font> InfiniteFly lands faster
<font color="#ff9f43">[-]</font> Removed Break Blocks Around Players from Breaker, it is now the separate AntiBedBreak
<b><font color="#d378ff">SkyWars</font></b>
<font color="#6aa9ff">[^]</font> SpawnTrap builds a tall sealed funnel over each enemy spawn whose egg is alive
<font color="#6aa9ff">[^]</font> ItemCollector takes a list of drop names instead of the currency-only toggle
<font color="#6aa9ff">[^]</font> The SkyWars pack now runs in the lobby as well

<b><font color="#d378ff">v3.18.0 - BoxAura and the Tribes rework</font></b>
<b><font color="#d378ff">SkyWars</font></b>
<font color="#63dc82">[+]</font> Added BoxAura, which walls nearby enemies into a box of blocks, with Suffocate to fill the inside once it is closed
<font color="#63dc82">[+]</font> Added SpawnTrap, which builds a well where a dead enemy respawns and roofs it once they drop in
<font color="#63dc82">[+]</font> Added AutoClutch, which places blocks under you when you fall toward the void
<font color="#63dc82">[+]</font> Added VoidPush, which hits enemies near an edge from the far side so the knockback throws them off
<font color="#63dc82">[+]</font> Added AutoChargeProj, which fires your bow shots at a set charge however long you hold
<font color="#63dc82">[+]</font> Added EggESP, ChestESP and DropESP
<font color="#63dc82">[+]</font> Added OpenShop, which opens the Blacksmith or Wizard shop from anywhere on the map
<font color="#ff9f43">[-]</font> Removed Nuker
<b><font color="#d378ff">BedWars</font></b>
<font color="#ff6b6b">[!]</font> Speed now moves you at the speed you set in both Legit and Blatant
<b><font color="#d378ff">Tribes 3v3</font></b>
<font color="#6aa9ff">[^]</font> Killaura swings straight from your weapon on its own cooldown, with new Guard check and AutoBlock for swings and shots
<font color="#6aa9ff">[^]</font> AutoWin now sticks behind the nearest enemy and fights with your best melee, then queues again
<font color="#6aa9ff">[^]</font> SilentAim has an aim circle, headshots, auto shoot and better prediction for every ranged weapon
<font color="#6aa9ff">[^]</font> NoSlowdown also stops the slowdown from aiming, charging, blocking, reloading and being hit
<font color="#6aa9ff">[^]</font> TriggerBot works with melee and projectiles and has a CPS limit
<font color="#6aa9ff">[^]</font> AutoUpgrade tries the next upgrade when one does not go through
<font color="#6aa9ff">[^]</font> Velocity also removes the game's other knockback at 0%
<font color="#6aa9ff">[^]</font> AutoQueue can tell you when it is about to queue
<font color="#63dc82">[+]</font> Added Aimbot, GunMods, Speed, PlayerAttach, AntiSmoke, FreeCursor, StreakSpoof and LevelSpoof
<font color="#63dc82">[+]</font> Added NameTags with each player's loadout, and TrapESP
<b><font color="#d378ff">BedFight</font></b>
<font color="#63dc82">[+]</font> Added BoxAura, which walls nearby enemies into a box of wool, with Suffocate to fill the inside once it is closed
<font color="#63dc82">[+]</font> Added Break Blocks Around Players to Breaker, which mines blocks an enemy is lodged in
<font color="#ff6b6b">[!]</font> Scaffold works with the blocks you get in the lobby

<b><font color="#d378ff">v3.17.1 - ElevateV4.xyz</font></b>
<b><font color="#d378ff">General</font></b>
<font color="#6aa9ff">[^]</font> ElevateV4 now loads from its own address. Switch your loader to api.ElevateV4.xyz/init.lua, the old GitLab loader no longer gets updates
<font color="#6aa9ff">[^]</font> The website moved to ElevateV4.xyz
<font color="#ff6b6b">[!]</font> FPS drops from the Performance Monitor are no longer reported as errors
<font color="#ff6b6b">[!]</font> Usage data keeps reports you had not sent yet when you re-execute, and Uninject now ends your session
<b><font color="#d378ff">Configs</font></b>
<font color="#6aa9ff">[^]</font> The config browser only lists configs for the game you are in, plus universal ones
<font color="#63dc82">[+]</font> Share a config by pasting Export JSON on the website dashboard under Community
<font color="#ff6b6b">[!]</font> Syncing a config no longer keeps offering the same update afterwards
<font color="#ff9f43">[-]</font> Removed the Blatant, Closet and Silent default buttons
<b><font color="#d378ff">BedWars</font></b>
<font color="#63dc82">[+]</font> Added KrystalDisabler in Kits, which keeps Krystal momentum topped up while you move
<font color="#6aa9ff">[^]</font> Killaura, KillauraOLD, SilentAura and AutoClicker play the swing sound at most every 0.3s, which cuts lag while fighting
<font color="#6aa9ff">[^]</font> Finished swing animations no longer pile up in memory while you hold the same item
<font color="#ff6b6b">[!]</font> InfiniteKrystal no longer errors when the Krystal controller is missing

<b><font color="#d378ff">v3.17.0 - Accounts and GitLab</font></b>
<b><font color="#d378ff">General</font></b>
<font color="#63dc82">[+]</font> Added Send usage data in GUI settings > General, on by default. It sends your Roblox name, session times, version, game and errors to the ElevateV4 backend, never your IP or files
<font color="#63dc82">[+]</font> Added Link code, Check link and Unlink account in GUI settings > General, which tie the game to your Discord account on the website
<font color="#63dc82">[+]</font> Announcements from the ElevateV4 team now show as a notification after loading
<font color="#6aa9ff">[^]</font> ElevateV4 now updates from GitLab. The new loader is gitlab.com/plutoxqq1/ElevateV4/-/raw/main/init.lua
<font color="#6aa9ff">[^]</font> Updates download every file from the exact release being installed, with a fallback when the host refuses one
<b><font color="#d378ff">Configs</font></b>
<font color="#6aa9ff">[^]</font> Public Configs now come from the new backend, with likes and dislikes once your account is linked
<font color="#6aa9ff">[^]</font> Publishing and updating configs moved to the website dashboard
<font color="#ff9f43">[-]</font> Removed the in-game config submission, review queue and maintainer tools

<b><font color="#d378ff">v3.16.0 - Tribes 3v3 and AutoToxic rework</font></b>
<b><font color="#d378ff">Tribes 3v3</font></b>
<font color="#63dc82">[+]</font> Added support for Tribes 3v3, in the lobby and in matches
<font color="#63dc82">[+]</font> Added Killaura with the BedWars Killaura's settings (swing and attack range, air hit chance, swing time, target mode, show target, particles and more) plus AutoBlock
<font color="#63dc82">[+]</font> Added SilentAim (bows, guns and throwing weapons)
<font color="#63dc82">[+]</font> Added Velocity, NoSlowdown, AutoUpgrade, AutoQueue and AutoToxic
<font color="#63dc82">[+]</font> Added AutoWin (goes to each enemy in turn and stays above them, dropping in for each of your hits so they land while theirs do not)
<font color="#63dc82">[+]</font> Added AntiHit (moves only your hitbox above nearby melee enemies and over incoming shots, and brings it down for your own hits)
<font color="#63dc82">[+]</font> Added ProjectileAura (fires your bow, gun or throwing weapon at the nearest enemy)
<font color="#63dc82">[+]</font> Added TriggerBot, AutoRelease and AutoReload
<font color="#63dc82">[+]</font> Added AutoWeapon (melee for close enemies, ranged for far ones) and AutoHeal (uses your bandage when low)
<font color="#63dc82">[+]</font> Added RingESP (draws the ring of fire) and ProjectileESP (draws enemy shots, red when coming at you)
<font color="#63dc82">[+]</font> Added MatchInfo and EnemyList HUDs
<font color="#63dc82">[+]</font> Added StaffDetector (warns when a Tribes moderator, admin or developer joins)
<font color="#63dc82">[+]</font> Added AutoSkip (presses the skip buttons when your chests open at the end of a match)
<b><font color="#d378ff">Everything else</font></b>
<font color="#6aa9ff">[^]</font> Performance: AutoBuy no longer stalls the game near a shop (shop lookups are cached, it used to cost up to 120ms a pass)
<font color="#6aa9ff">[^]</font> Performance: BedESP, ESP and Target Info only redraw what changed
<font color="#6aa9ff">[^]</font> Performance: AutoBank, Legless, Headless, FastClimb, Speed, AutoClicker and Ping do less work every frame
<font color="#6aa9ff">[^]</font> Performance: the Performance Monitor itself costs less while it runs
<font color="#6aa9ff">[^]</font> Performance: Killaura does much less work for each target every frame
<font color="#6aa9ff">[^]</font> Performance: NameTags, Tracers, Arrows, Compass, NoClip and ForcePlayerCollisions only update what changed
<font color="#6aa9ff">[^]</font> Performance: AntiMagma and OreESP skip most new world objects without looking at them
<font color="#6aa9ff">[^]</font> Faster loading: images are no longer read and hashed again the first time each one is used
<font color="#ff6b6b">[!]</font> Running ElevateV4 again while it is loaded, or stuck loading, now replaces the old copy instead of being ignored
<font color="#6aa9ff">[^]</font> AutoToxic: every event has an Action (Message, Emote or Both) with one shared emote and message list
<font color="#63dc82">[+]</font> AutoToxic: added Final Kill, which only fires when the player you killed has no bed (no egg in SkyWars)
<font color="#6aa9ff">[^]</font> AutoToxic: AutoGG now says gg at the end of every match, won or lost, after its own delay
<font color="#6aa9ff">[^]</font> AutoToxic: Bed is now Bed Break (Egg Break and Egg Destroyed in SkyWars)
<font color="#ff6b6b">[!]</font> BedWars AutoToxic: Kill now fires on every kill, not only final kills, and Death works again
<font color="#6aa9ff">[^]</font> BedWars AutoClicker: placing while held is tried every frame and only waits after a block actually goes out
<font color="#63dc82">[+]</font> BedWars AutoClicker: Debug log option, which writes what happens while you hold the button to profiles/autoclickerlog.txt (press J to mark a moment)
<font color="#ff6b6b">[!]</font> BedFight AutoBuy: buys armour again (it kept trying to buy sword tiers below the one you own)
<font color="#ff6b6b">[!]</font> BedFight Breaker: Blatant sticks to the fewest-hits route and only switches for a strictly faster one
<font color="#ff6b6b">[!]</font> BedFight Breaker: Legit keeps its block and line instead of jumping to whatever is nearest
<font color="#ff9f43">[-]</font> BedFight: removed FastBreak

<b><font color="#d378ff">v3.15.0 - BedFight AutoWin, BedFight ports and BedWars cleanup</font></b>
<b><font color="#d378ff">BedFight</font></b>
<font color="#63dc82">[+]</font> Added AutoWin (automatically plays the game for you, BETA)
<font color="#63dc82">[+]</font> Added AutoPearl (throws a teleorb onto the nearest ground when falling into the void)
<font color="#63dc82">[+]</font> Added AutoPearlAggro (throws a teleorb to where an enemy's teleorb will land)
<font color="#63dc82">[+]</font> Added KnockbackDelay (delays incoming knockback, works alongside Velocity)
<font color="#63dc82">[+]</font> Added ShopTierBypass (allows you to purchase SWORDS without tier checks)
<font color="#63dc82">[+]</font> Added NoFallDamage (places blocks beneath you to prevent fall damage)
<font color="#63dc82">[+]</font> Added a new mode to AntiVoid (places blocks beneath you to prevent you falling into the void)
<font color="#63dc82">[+]</font> Added AutoVote (automatically votes when map voting opens)
<font color="#63dc82">[+]</font> Added CheatDetector (flags flying, excessive speed and suspicious movement)
<font color="#63dc82">[+]</font> Added MP3Player (plays local MP3 files)
<font color="#63dc82">[+]</font> Added ProjectileDodger (sidesteps arrows and fireballs)
<font color="#63dc82">[+]</font> Added AutoRelease (automatically releases charged bows, crossbows and teleorbs)
<font color="#63dc82">[+]</font> Added MemoryFixer (removes duplicate loops left behind by older injections)
<font color="#63dc82">[+]</font> Added InfiniteBedDefence (places blocks around your bed from anywhere)
<font color="#63dc82">[+]</font> Added AutoBalloon (automatically inflates balloons when falling into the void)
<font color="#6aa9ff">[^]</font> Renamed AntiCheatBypass to AntiBanwave
<font color="#6aa9ff">[^]</font> AntiVoid now takes you back to the nearest safe spot you stood on
<font color="#6aa9ff">[^]</font> Breaker Blatant mode keeps looking for a faster path while mining and remembers block health between sessions
<font color="#6aa9ff">[^]</font> Fly now touches down by itself again
<font color="#6aa9ff">[^]</font> Cleaned up InfiniteFly and its settings
<font color="#ff6b6b">[!]</font> Fixed AntiHit not dodging most projectiles
<font color="#ff6b6b">[!]</font> Fixed AntiVoid
<font color="#ff6b6b">[!]</font> Fixed Breaker having line-of-sight checks despite being on Blatant mode
<font color="#ff6b6b">[!]</font> Fixed Breaker not mining while attacking
<font color="#ff9f43">[-]</font> Removed Prevent Lagback from AntiBanwave
<b><font color="#d378ff">BedWars</font></b>
<font color="#63dc82">[+]</font> Added InfoEditor (combines NickHider, NameTagSpoofer, SetPlayerLevel and RemovePlayerLevelUI)
<font color="#63dc82">[+]</font> Added StreamDisabler (shows real names and levels of streamer mode players)
<font color="#63dc82">[+]</font> Added Pickup Delay to PickupRange (basically FastPickup)
<font color="#63dc82">[+]</font> Added Balloon mode to AntiVoid, with an option to pop balloons above land
<font color="#63dc82">[+]</font> Added a Buff list to AutoConsume (what AutoUse did)
<font color="#63dc82">[+]</font> Added item highlighting to Viewmodel
<font color="#63dc82">[+]</font> Added No Red Flash to HitColour
<font color="#63dc82">[+]</font> Added Clean Up UI to Interface
<font color="#63dc82">[+]</font> Added loot icons for iron, diamonds and emeralds to ItemESP
<font color="#63dc82">[+]</font> Added Song Beats to MP3Player (pulses FOV to the music)
<font color="#6aa9ff">[^]</font> Uncluttered the Kits window by merging similar modules into FalconAura, CryptAura, RavenAura, VulcanAssist, InfiniteSigrid, InfiniteKrystal, TritonClutch, CannonAssist, JadeInstantKill, VoidRegentAssist, GrimReaperAssist, TrixieDisabler, ZephyrDisabler, OwlAura, WhimAura, DeathAdderAimbot, TerraAimbot, HarvestAura and AutoFortify
<font color="#6aa9ff">[^]</font> BedProtector's Bed Patcher mode remembers and rebuilds broken bed defences
<font color="#6aa9ff">[^]</font> Moved BedGodmode into the Kits window
<font color="#6aa9ff">[^]</font> Expanded FPSBoost with Potato mode, No Textures, Remove Neon and No Shadows
<font color="#6aa9ff">[^]</font> Optimised TritonClutch
<font color="#6aa9ff">[^]</font> Optimised InfiniteKrystal's Freeze Bed Defence
<font color="#ff6b6b">[!]</font> Fixed kit abilities not working in some matches
<font color="#ff6b6b">[!]</font> Fixed Killaura freezing the game for a moment before hits at low FPS
<font color="#ff9f43">[-]</font> Removed BoostAirJump, OG4v4v4v4, InviteSpam, InvisibleCursor, FakeLag and EquipKit
<font color="#ff9f43">[-]</font> Removed PromptAura from BedWars
<font color="#ff9f43">[-]</font> Removed modules that were merged into others (FastPickup, AutoBalloon, AutoUse, BedPatcher, PotatoMode, NoTextures, RemoveNeon, ShadowRemover, ViewmodelVisuals, NoBob, WhiteHits, UICleanup, LootESP, NickHider, NameTagSpoofer, SetPlayerLevel, RemovePlayerLevelUI, SongBeats, and StreamRemover)
<b><font color="#d378ff">Universal</font></b>
<font color="#6aa9ff">[^]</font> Optimised AirWalk while disabled
<font color="#ff6b6b">[!]</font> Fixed PromptAura running twice after a quick toggle
<font color="#ff9f43">[-]</font> Removed the BROKEN tag from all modules
<b><font color="#d378ff">General</font></b>
<font color="#63dc82">[+]</font> Added emotes to every AutoToxic event in BedWars, SkyWars and BedFight
<font color="#6aa9ff">[^]</font> Rewrote lots of tooltips to make them more concise and formal
<font color="#ff6b6b">[!]</font> Fixed the script crashing on Delta
<font color="#ff6b6b">[!]</font> Fixed some minor issues with the searchbar
<font color="#ff9f43">[-]</font> Removed Spotlight Search

<b><font color="#d378ff">v3.14.0 - BedWars catch-up</font></b>
<font color="#63dc82">[+]</font> BedWars: AutoWin plays the match for you. It keeps weighing beds, kills, resources, upgrades and retreating against each other and commits to the best one as the match changes: it buys gear, bridges or flies to beds, breaks them, covers your own bed and fights from above. A status panel shows what it is going for, and it can queue the next match, carry on from the lobby and keep Anti-AFK on. Smooth, on by default, eases every move it makes instead of jumping you from spot to spot and turns you toward where you are going instead of snapping. Landings and long moves stay exact.
<font color="#6aa9ff">[^]</font> BedWars: AutoDodge lifts and lowers you smoothly instead of snapping up and down, follows the ground under you and stays on one enemy unless another is clearly closer, so it no longer jitters.
<font color="#6aa9ff">[^]</font> BedWars: Killaura judges reach against where the server has you and your target instead of where they look on your screen, so hits land from further out and fewer are refused.
<font color="#6aa9ff">[^]</font> BedWars: Killaura paces its hits by the limit the game enforces, so fast weapons are no longer held to the stock sword pace.
<font color="#6aa9ff">[^]</font> BedWars: Killaura swings in every Hephaestus mech, and Fast Hits follows each projectile it fires to register the hit. Every setting is where it was, Use fireball and Use gloop included.
<font color="#63dc82">[+]</font> BedWars: BedGodmode plants Spirit Gardener flowers on both halves of your bed so it cannot be broken, then switches itself off. It needs the Spirit Gardener kit.
<font color="#6aa9ff">[^]</font> BedWars: InfiniteKrystal has a Mode setting: Method 1 is how it worked before, Method 2 sets your momentum to full every frame.
<font color="#ff6b6b">[!]</font> BedWars: AutoMatchDodge holds the match back before it loads now. Nothing held it before, so its checks never ran.
<font color="#ff6b6b">[!]</font> BedWars: AutoTaliyah errored whenever you stood near a shop and never traded. It works again, and stays quiet when you are not playing Taliyah.
<font color="#63dc82">[+]</font> BedWars: AutoPearlAggro works out where an enemy pearl will land the moment it is thrown and pearls you to the same spot. It skips pearls that go into the void, land closer to you than the thrower stood or that yours cannot reach, and has a distance limit, a minimum health and a cooldown.
<font color="#63dc82">[+]</font> BedWars: BedPatcher remembers the blocks around your bed and puts back the ones an enemy breaks, with a block list, a wool only option, a place range and a defence radius.
<font color="#63dc82">[+]</font> BedWars: AutoTrap throws Trapper traps ahead of enemies or in a ring around your bed or an enemy bed, picks snap, venom or explosive traps, and sets off armed explosives when an enemy is in the blast.
<font color="#63dc82">[+]</font> BedWars: TeamUpgrades shows every team's upgrades over their generator, and whether their bed is shielded or alarmed.
<font color="#63dc82">[+]</font> BedWars: Bed Defense is an overlay that shows an enemy bed's defence layer by layer. It follows the nearest bed, the one you are looking at or one you pick, and can rotate by itself.
<font color="#63dc82">[+]</font> BedWars: AutoReset resets you once you are past the void line so you respawn sooner, unless a pearl, an owl or a lasso can still save you.
<font color="#63dc82">[+]</font> BedWars: AutoVote casts your map vote as soon as the vote opens.
<font color="#63dc82">[+]</font> BedWars: AutoCollect picks up kit collectables near you without walking into them, with a range, a delay and a list of what to take.
<font color="#63dc82">[+]</font> BedWars: AutoUse drinks and eats the buff items you list as soon as their effect runs out, always or only in combat.
<font color="#63dc82">[+]</font> BedWars: RegionLock stays out of matches hosted outside the regions you pick, and can queue again by itself. It is in the lobby too, so you can set it before queueing.
<font color="#63dc82">[+]</font> BedWars: NickHider replaces your name everywhere it shows on your screen and can hide other players' names, chat tags, levels and kits. It is in the lobby too.
<font color="#63dc82">[+]</font> BedWars: ItemPlates shows which blocks cover the items on your list, beehives by default.
<font color="#63dc82">[+]</font> BedWars: Clouds changes the size and colour of the clouds, NoTextures strips materials, decals and meshes from the map, and SetEmote plays an emote other players can see.
<font color="#6aa9ff">[^]</font> BedWars: BedESP draws a 2D or 3D box on each bed with your choice of team or custom colour, fill, health bar, name, background, a distance limit and an option to hide your own bed. It used to draw the bed's shape and had no settings.
<font color="#6aa9ff">[^]</font> BedWars: TrapDisabler also stops landmines, teleport blocks and void portals, each with its own toggle. It only covered snap traps.
<font color="#6aa9ff">[^]</font> BedWars: AutoWhisper can send the owl to a teammate you pick as soon as it is ready, with an FOV check and a range circle you can style.
<font color="#6aa9ff">[^]</font> BedWars: AutoWhisper's Fly only lifts the player your owl is on once they have fallen well below where they stood over the void, so it no longer goes off on jumps or while bridging.
<font color="#6aa9ff">[^]</font> BedWars: PotionStatus was redrawn: each effect has a ring that drains and changes colour as it runs out. Good and bad effects can be shown separately, and the background has a colour setting.
<font color="#6aa9ff">[^]</font> BedWars: AutoPearl has a Clutch range for how far away the ground it saves you onto can be, and a Cooldown between throws.
<font color="#6aa9ff">[^]</font> BedWars: AutoPearl skips ground its pearl cannot reach, and a throw the server refuses no longer uses up the cooldown.
<font color="#6aa9ff">[^]</font> BedWars: AutoPickpocket waits until the pickpocket is ready and only tries players it can be used on, once every half second each, instead of asking for everyone nearby ten times a second.
<font color="#6aa9ff">[^]</font> BedWars: AutoTriton has a Fall speed that sets how fast you must be falling before it throws, and a Search range for the ground it looks for.
<font color="#6aa9ff">[^]</font> BedWars: AutoSigrid has Charge attack, which charges at whoever is in Charge range while you ride the elk.
<font color="#6aa9ff">[^]</font> BedWars: AutoCaitlyn has a Target Mode for who gets your contract, and Drop Contract to let one go after 60 seconds so you can take a new one.
<font color="#6aa9ff">[^]</font> BedWars: AutoGingerbreadMan has Place pads, which drops a bounce pad under you whenever the spot is empty, with a Place delay.
<font color="#6aa9ff">[^]</font> BedWars: AutoAdetunde has Last upgrade, which saves one upgrade for last so your crystals go into the others first.
<font color="#6aa9ff">[^]</font> BedWars: AutoChargeProj has an Items list, so it can charge only the items or projectiles you name.
<font color="#6aa9ff">[^]</font> BedWars: UICleanup puts the game's own layout back when you switch one of its options off.
<font color="#63dc82">[+]</font> Lobby: LevelBypass removes the level locks the lobby shows on queues. The server's own level limits still apply.
<font color="#63dc82">[+]</font> Lobby: SetEmote plays an emote other players can see.
<font color="#63dc82">[+]</font> Universal: Compass shows which way you are facing.
<font color="#63dc82">[+]</font> Universal: Atmosphere replaces the sky and lighting effects with your own.
<font color="#6aa9ff">[^]</font> Menu: The Vape V4 logo is at the top left of the menu in place of the ElevateV4 logo and the V2 badge, and the V4 takes your GUI colour.
<font color="#63dc82">[+]</font> Configs: Three default configs, Blatant, Closet and Silent, sit at the top of the config browser and the first-run picker and load in one click. Silent is not out yet and tells you to wait for an update.
<font color="#ff6b6b">[!]</font> Configs: The config browser showed an old copy of the config list. It reads the current one now, and still opens when the config server is down.

<b><font color="#d378ff">v3.13.3 - BedFight InfiniteFly Safe</font></b>
<font color="#6aa9ff">[^]</font> BedFight: InfiniteFly Safe was reworked for short flights. Your hitbox stays where you took off, and the moment you switch off you stand on the ground and can walk. Nothing holds you in place any more while the hitbox comes after you.
<font color="#6aa9ff">[^]</font> BedFight: InfiniteFly Safe: the hitbox follows in one jump of at most 100 studs, the jump the server let through 16 times out of 17. About 55 studs or less goes straight away and the full 96 two seconds after take-off. It used to walk to you at 22 studs a second. Until it is with you, you cannot hit and players can still hit you where it stands.
<font color="#6aa9ff">[^]</font> BedFight: InfiniteFly Safe: you can take off again before the hitbox has arrived. Pressing the key during a landing used to do nothing.
<font color="#6aa9ff">[^]</font> BedFight: InfiniteFly Safe only lands on firm ground that is not more than 18 studs below the hitbox, so a landing costs no fall damage. Anywhere else you land on the nearest such ground back towards the hitbox, the notice says why, and the module text shows "no landing" while you are over a spot like that.
<font color="#6aa9ff">[^]</font> BedFight: InfiniteFly Safe: if you fall off something before the hitbox has reached you, you are brought back to it. If the server refuses a jump you are put back where the hitbox stood, and landings wait the full two seconds for the rest of the session.
<font color="#6aa9ff">[^]</font> BedFight: InfiniteFly: Leash is hidden while Safe is on, because the hitbox does not follow you there. With Safe off nothing changed.

<b><font color="#d378ff">v3.13.2 - BedFight Killaura reach and hit timing</font></b>
<font color="#ff6b6b">[!]</font> BedFight: Killaura judged reach by where a player is on your screen, which is a ping behind where the server has them. Someone running at you is now hit as soon as the server has them in reach: at 320 ms, hits sent while the player still looked 19 studs away were counted.
<font color="#ff6b6b">[!]</font> BedFight: Killaura sent one hit per sword cooldown on a fixed beat, so a hit that reached the server a moment early was refused and the next one came a whole cooldown later. A hit now goes out every frame and the server counts the first one it can: measured 0.27 to 0.36 seconds apart with a 0.3 second sword, about 32 hits in ten seconds.
<font color="#ff6b6b">[!]</font> BedFight: Killaura waited for the server to show the sword before its first hit, a full ping every time you were holding anything else. The switch and the hit now go out together.
<font color="#ff6b6b">[!]</font> BedFight: An item switch sent before the last one had shown could leave the server holding the wrong item for up to a second, with every hit, shot or block refused meanwhile (Killaura, ProjectileAura, Scaffold, Breaker).
<font color="#6aa9ff">[^]</font> BedFight: Killaura uses the sword you own that deals the most damage over time. It used to take the most damage per hit, which picked a spear or battle axe over a sword that hits far more often.
<font color="#6aa9ff">[^]</font> BedFight: Killaura keeps the sword in the server's hand for a quarter of a second after the last target, so someone stepping in and out of reach does not cost a switch each time.
<font color="#6aa9ff">[^]</font> BedFight: Killaura Air hit chance is rolled once per sword cooldown, and with several targets they take turns frame by frame. Custom Attack Speed is now only for hitting slower: off is the fastest the server allows.
<font color="#6aa9ff">[^]</font> BedFight: Killaura measures reach from your hitbox, not your body, when another module has moved it. With AntiHit every frame of the moment the hitbox is down gets a hit.

<b><font color="#d378ff">v3.13.1 - BedFight InfiniteFly and AntiHit rebuilt</font></b>
<font color="#ff6b6b">[!]</font> BedFight: the game shortened its float check. A hitbox that has been off the ground for one second is now taken by the server and left on the ground for four; it used to take two to three seconds. AntiHit, Fly and Prevent lagback were timed for the old limit, which is why AntiHit let every hit through. All three keep to the new one.
<font color="#6aa9ff">[^]</font> BedFight: AntiHit was written again from nothing. The hitbox waits 17 studs above you, further than any sword reaches, and touches the ground for an eighth of a second every three quarters of a second, sooner whenever nobody is close enough to use the moment.
<font color="#6aa9ff">[^]</font> BedFight: AntiHit with Killaura: the hitbox drops into reach just before each of your hits is sent and goes straight back up, so your hits land while it is out of reach the rest of the time. Keep your hits replaces Stay in sword reach, and Hover height (12 to 18) replaces Height.
<font color="#63dc82">[+]</font> BedFight: AntiHit has Dodge projectiles. It works out where an arrow or fireball passes you and has the hitbox at a height the shot misses. Shots that arrive faster than your ping cannot be dodged.
<font color="#6aa9ff">[^]</font> BedFight: AntiHit comes down a ledge in two short stands instead of one long drop, which is what cost fall damage when you walked off one.
<font color="#6aa9ff">[^]</font> BedFight: InfiniteFly was rebuilt for long flights. The server now puts back the 100 stud jumps the hitbox used to follow you with, so it walks along the ground under you at 22 studs a second, the fastest the server lets a character go for long, and only jumps where the ground ends.
<font color="#6aa9ff">[^]</font> BedFight: InfiniteFly crosses gaps between islands: up to 100 studs once the hitbox has stood still for two seconds, up to 136 after six. Two 118 stud gaps were crossed in a match this way.
<font color="#63dc82">[+]</font> BedFight: InfiniteFly has Leash. Further ahead of your hitbox than that you fly at its pace, so a landing waits a few seconds at most. 500 switches it off.
<font color="#63dc82">[+]</font> BedFight: InfiniteFly has Safe. With it on you cannot get further from your hitbox than one 100 stud jump, the jump the server let through 16 times out of 17, and the longer jump of up to 136 studs is not tried. It is off by default, because the islands on the two maps that were measured are 118 and 129 studs apart.
<font color="#ff6b6b">[!]</font> BedFight: InfiniteFly: when the hitbox could not get to your landing spot it was thrown across to you, which over the void meant falling. You now come back to where the hitbox stands.
<font color="#ff6b6b">[!]</font> BedFight: InfiniteFly: the hitbox could stop on the last stud of a ledge, where the server took it and let it fall. It stops three studs short of an edge.
<font color="#6aa9ff">[^]</font> BedFight: Fly: Air time goes up to 0.9 seconds (default 0.8) to match the new float check.
<font color="#ff6b6b">[!]</font> BedFight: Unloading or reinjecting ElevateV4 while your hitbox was away from you (AntiHit, InfiniteFly, Prevent lagback) left the character without its root until the next respawn. It gets the root back first.

<b><font color="#d378ff">v3.13.0 - Keybinds, InfiniteFly and BedFight ports</font></b>
<font color="#63dc82">[+]</font> Keybinds overlay: lists every module, config and the menu key you have bound, so you can look a key up without opening the menu. It has the Font, Blacklist, Background Colour, Border, Text Size, Title and custom text settings of Session Info, plus Sort, Only enabled, Dim disabled, Menu key and Config keys.
<font color="#63dc82">[+]</font> Wallhop has Auto Disable: it switches itself off after the number of wallhops set in Disable After, and Notify tells you when it did.
<font color="#6aa9ff">[^]</font> Disguise was replaced. It takes a user ID or a username, keeps your own body size, shows a notice when a user or avatar cannot be loaded, and gives your own look back when you turn it off. Press enter in the box to apply a new one.
<font color="#ff9f43">[-]</font> Removed the AI Assistant, its window, its sidebar button and its settings.
<font color="#63dc82">[+]</font> BedFight: InfiniteFly in Blatant. You fly for as long as you like on your screen while your hitbox follows on the ground below, from one piece of ground to the next, as fast as the server lets a character move, so nothing pulls you back in the air or after a long flight. Switch it off over ground to land. If you flew faster than the hitbox can follow, the landing waits for it and tells you how long, and the number next to its name is how far behind it is. While you fly, players can still hit you where the hitbox stands and you cannot hit, mine or pick things up.
<font color="#63dc82">[+]</font> BedFight: ShopClicker in Utility, from BedWars. Hold the mouse on an item in the shop to keep buying it.
<font color="#63dc82">[+]</font> BedFight: PearlTP in Utility, from BedWars. Throws a teleorb to the spot under your mouse on the fastest arc that reaches it, without touching your hotbar.
<font color="#63dc82">[+]</font> BedFight: AutoChargeProj in Blatant, from BedWars. Bows, teleorbs and hotdogs are charged to the percentage you set the moment you start drawing.
<font color="#63dc82">[+]</font> BedFight: AutoVoidDrop in Utility, from BedWars. Drops your iron, diamonds and emeralds when you fall under the map, unless a teleorb you threw is about to land or you have a balloon.
<font color="#6aa9ff">[^]</font> BedFight: Reach has Place and Break, each with its own range slider. BlockRange was removed, this is where it lives now.
<font color="#ff6b6b">[!]</font> BedFight: AntiHit: your own hits did not count while the hitbox was up, which is why you could not hit anyone while jumping. With Stay in sword reach (on by default) the hitbox only goes as high as still reaches whoever Killaura is hitting.
<font color="#6aa9ff">[^]</font> BedFight: AntiHit gets you hit less: the hitbox stays up for 1.3 seconds instead of 1, and it takes its short stand on the ground at a moment when nobody is close enough to reach it, whenever there is one.
<font color="#ff6b6b">[!]</font> BedFight: Breaker in Blatant mined the block nearest to you. It now works out the way to the bed that takes the fewest hits from any side, starts on that block wherever it is, and hits a bed whose open side is not the one facing you.
<font color="#ff6b6b">[!]</font> BedFight: Breaker in Legit stays on the block it started until that block is gone, also when you look away for a moment.
<font color="#ff9f43">[-]</font> BedFight: Breaker: Break covering blocks was removed. Digging through the cover is what it always does.
<font color="#ff6b6b">[!]</font> BedFight: Killaura: Custom Attack Speed now changes how fast you swing. The server counts one hit per sword cooldown (0.3s for most swords) however many are sent, so a lower time does not deal damage faster.
<font color="#ff6b6b">[!]</font> BedFight: Killaura, ProjectileAura, Scaffold and Breaker no longer take the item the server holds away from each other. With Killaura on, ProjectileAura could barely get a shot out.
<font color="#6aa9ff">[^]</font> BedFight: LongFly is now called LongJump and travels exactly Speed x Duration. It used to go almost twice as far as set, at almost twice the speed, which is what the server sometimes pulled back. Raise Duration to reach the same place. Its settings and keybind start from the defaults.
<font color="#ff6b6b">[!]</font> BedFight: LongJump: Void check let you end over the void. It now decides before the dash: it stops over the last ground on the way, and does not start when there is none.
<font color="#63dc82">[+]</font> SkyWars: ShopClicker in Utility, from BedWars. Hold the mouse on a blacksmith item to keep buying or upgrading it.
<font color="#ff9f43">[-]</font> SkyWars: GodMode is back to how it worked before v3.12.8. Your hitbox hangs above the closest enemy again, out of reach, and the Distance slider is back. The version that hid it inside the ground is gone.

<b><font color="#d378ff">v3.12.8 - Buried GodMode and install fix</font></b>
<font color="#6aa9ff">[^]</font> SkyWars: GodMode now hides your hitbox inside the ground, 5 studs under the closest enemy, instead of lifting it above them. It only ever goes into a block: when that enemy has no ground under them it goes under the next one, and otherwise under you.
<font color="#ff9f43">[-]</font> SkyWars: GodMode no longer has the Distance slider, because the depth is always 5 studs.
<font color="#6aa9ff">[^]</font> SkyWars: Every match place of the game loads the SkyWars modules, including places the game adds later. The lobby keeps the universal modules.
<font color="#ff9f43">[-]</font> BedFight: AntiHit is back to how it worked before v3.12.7. The hitbox waits Height (11 by default) above the ground for a second and then stands for a moment. Stay in sword reach, the early stand and the 17 stud lift are gone.
<font color="#6aa9ff">[^]</font> BedFight: AntiHit keeps two things from that update: it still works while you jump, and it only leaves the hitbox on you while you are drawing a bow instead of whenever you hold one.
<font color="#ff6b6b">[!]</font> A first install or a full repair stopped part way. GitLab only allows 500 downloads a minute, so the universal modules, the menu and the libraries were refused and the console filled with "could not update". The loader now gets whatever is refused from a second GitLab address, tries once more before giving up, and downloads what the launch needs first.
<font color="#ff6b6b">[!]</font> Update Modules failed with "no module list" in a place that has no game pack, such as the SkyWars lobby. It now updates the universal modules there and says the place has no pack.
<font color="#ff6b6b">[!]</font> A download GitLab refused could be saved as if it were a module or library file.

<b><font color="#d378ff">v3.12.7 - BedFight toolkit</font></b>
<font color="#ff6b6b">[!]</font> BedFight: Breaker kept moving to another block while the bed could already be hit. It now looks at several points of the bed, hits the bed as soon as any of them is open, and otherwise stays on one block until it is gone.
<font color="#63dc82">[+]</font> BedFight: Breaker has the Breaker Type from BedWars. Blatant takes the way in with the fewest hits, through walls and at any angle. Legit only mines what your camera can see, the nearest block first and one at a time, with Break Chance, Only while in combat and Max angle.
<font color="#63dc82">[+]</font> BedFight: Breaker also has Update rate, a Custom list of blocks to mine, Break Bed, Animation, Self Break, Auto Tool and Limit to items.
<font color="#63dc82">[+]</font> BedFight: Scaffold has Diagonal, Require mouse down, Visual with a fill and an outline colour, and Block Count.
<font color="#63dc82">[+]</font> BedFight: Killaura has Swing range, Sync to legit ranges, Air hit chance, Max targets, Target Mode, Continue swing, AFK check, GUI check, a Target Color with box animations, and Target particles.
<font color="#63dc82">[+]</font> BedFight: AutoBuy has Buy Crossbow, GUI check, Smart check and the Item list for extras such as fireballs, TNT or obsidian.
<font color="#63dc82">[+]</font> BedFight: ProjectileAimbot has Targets, Target mode, Range, an FOV Circle, Horizontal and Vertical prediction, Auto Charge, Other Projectiles and a Blacklist. Teleorbs are no longer bent onto players.
<font color="#63dc82">[+]</font> BedFight: ProjectileAura has Target mode, Part and an FOV Circle that limits who it shoots at.
<font color="#63dc82">[+]</font> BedFight: SilentAim in Combat, built for the game. Your shot flies where you aimed on your screen while the one the server gets is sent at the player inside the FOV.
<font color="#6aa9ff">[^]</font> BedFight: AntiHit now also works while you jump, waits 17 studs above the ground under you, and only stands on the ground early when nobody is close enough to hit it. While you are hitting someone it stays within reach of your own sword, and it reads the ground ahead of you, so walking off a ledge with the hitbox up no longer costs health.
<font color="#ff6b6b">[!]</font> BedFight: The modules did not load in ranked matches, which run in another place of the game. Every BedFight place now loads them.

<b><font color="#d378ff">v3.12.6 - Clicks and swings</font></b>
<font color="#63dc82">[+]</font> BedFight: AntiVoid in Blatant, built for the game. Falling with nothing below you, it puts you back where you last stood.
<font color="#63dc82">[+]</font> BedFight: BedPlates in Render, from BedWars. Shows over every bed which blocks are built around it.
<font color="#63dc82">[+]</font> SkyWars: ComboCounter in Legit, from BedWars. Counts the hits you land in a row.
<font color="#ff6b6b">[!]</font> BedFight: ProjectileAimbot aimed with prediction tuned for BedWars and missed anyone moving. It now uses the game's own flight maths, leads by your ping and goes by how the target has really been moving.
<font color="#ff6b6b">[!]</font> BedFight: with Wall check on, ProjectileAimbot failed to find a target every frame, which first removed the aim line and then left it on the cursor.
<font color="#ff6b6b">[!]</font> BedFight: AntiHit made your own arrows and fireballs do nothing, because the server launches them from the lifted hitbox. It now keeps the hitbox on you while a bow, crossbow or fireball is in your hand, and ProjectileAura shoots from where the hitbox is.
<font color="#63dc82">[+]</font> BedFight: AntiHit in Blatant. While an enemy is close it lifts the hitbox other players see out of sword reach, and you and your camera stay where they are. It comes down for a moment about once a second.
<font color="#63dc82">[+]</font> BedFight: AntiCheatBypass has Prevent lagback. When you are off the ground for too long, only your hidden hitbox touches down, so you are not pulled back and Fly no longer drops you to the floor and back. It works within 18 studs of the ground and cannot cover moving too fast.
<font color="#63dc82">[+]</font> AutoToxic in SkyWars and BedFight, with the same options as BedWars: kills, deaths, eggs or beds, wins, AutoGG and troll replies.
<font color="#ff6b6b">[!]</font> SkyWars: the first person sword from Viewmodel stayed on screen when you zoomed out, and it did not swing on your own clicks.
<font color="#63dc82">[+]</font> BedFight: AutoClicker in Combat, built for the game. Hold attack with a sword out to swing at your CPS, and Place Blocks does the same with blocks.
<font color="#63dc82">[+]</font> SkyWars and BedFight Killaura: Swing only, which only attacks while you are swinging yourself, by hand or through AutoClicker.
<font color="#63dc82">[+]</font> BedFight Killaura: Custom Animation, with the same animations, speed and No Tween options as BedWars.
<font color="#6aa9ff">[^]</font> SkyWars Killaura: Custom Animation switches the Viewmodel module on by itself. Before, it did nothing unless you knew to turn that on.
<font color="#ff6b6b">[!]</font> SkyWars: AutoWin no longer shakes your view while it fights. Your character now glides after the target and only the hidden hitbox does the jumping about.
<font color="#6aa9ff">[^]</font> SkyWars: Killaura, InfiniteAura, Reach and AutoWin no longer send the same strike at one player more than once a frame, and they hand your held item back once a frame between them instead of once each.
<font color="#6aa9ff">[^]</font> BedWars: finding the game's controllers at startup now reads memory once instead of once for each controller, so the freeze as a match loads is shorter and the rechecks in the first minute are lighter.
<font color="#6aa9ff">[^]</font> BedWars: Spider only rebuilds its list of characters when someone joins or leaves, not every frame.
<font color="#ff6b6b">[!]</font> Targets that Killaura and other modules reported were never cleared while the Target Info card was switched off, so the list kept growing all match.
<font color="#6aa9ff">[^]</font> BedFight: AntiCheatBypass now replaces the anticheat's Catch straight on the game's loaded ClientModule instead of searching memory for it, so it is found faster and on more executors.

<b><font color="#d378ff">v3.12.5 - BedWars startup</font></b>
<font color="#ff6b6b">[!]</font> BedWars: the game no longer builds its ability controller in matches, and asking for it failed and took the whole match pack down with it. The pack now takes the controller the game already has, carries on without it when there is none, and picks it up if it appears later.

<b><font color="#d378ff">v3.12.4 - BedFight</font></b>
<font color="#63dc82">[+]</font> BedFight is now supported: joining it loads its own set of modules, in the lobby and in every mode.
<font color="#63dc82">[+]</font> AntiCheatBypass in Utility. BedFight hides a check on your side that swaps every remote for a dead copy and reports you (that is what "SwordHit is not a valid member of ItemsRemotes" means). It is switched off as soon as ElevateV4 loads, turns itself on each launch and tells you what it stopped.
<font color="#63dc82">[+]</font> BedFight Killaura in Blatant. It only tells the server to hold your sword, so your hotbar stays free: you can hold and switch items while it fights.
<font color="#63dc82">[+]</font> BedFight Reach, Velocity (horizontal and vertical percent) and Sprint in Combat.
<font color="#63dc82">[+]</font> BedFight ProjectileAimbot (bends bow, crossbow and fireball shots and shows the real aim line) and ProjectileAura in Blatant.
<font color="#63dc82">[+]</font> BedFight Speed (Velocity and CFrame), Fly with an air time bar and Touch ground, LongFly, Knockback and NoSlowdown in Blatant.
<font color="#63dc82">[+]</font> BedFight AutoBuy (weapons for your kit, armor, pickaxes, bow, arrows, wool and team upgrades) and ChestManager (loot team chests, keep your items when you die) in Inventory.
<font color="#63dc82">[+]</font> BedFight Scaffold, AutoQueue, BlockRange, FastBreak, InfJetpack, PlayEmote, NearbyWarn and GhostDetector (warns about hidden staff spectators) in Utility, and Breaker in World.
<font color="#63dc82">[+]</font> BedFight BedESP, ItemESP, TNTDetector with fuse timers, CapeChanger, FirstPerson, AntiVision, StreamerMode and GameThemes (15 skies and weathers plus a day cycle) in Render.
<font color="#63dc82">[+]</font> BedFight ArmorHUD and UICleanup in Legit.
<font color="#ff9f43">[-]</font> In BedFight the universal Killaura, Reach, Speed and Fly make way for the BedFight versions, and HitBoxes, SilentAim and Disabler are hidden because the game checks for them or they do nothing there.
<font color="#6aa9ff">[^]</font> BedFight Killaura sends a hit exactly once per sword cooldown, the most the game counts. Custom Attack Speed sets the time between hits yourself (0 to 1 second) and has a reset button, and every hit plays its swing, on the first person arms too.
<font color="#6aa9ff">[^]</font> BedFight sliders stop where the server does: Speed and Fly go to 30 (24 ran clean, 32 was pulled back after five seconds), Fly touches the ground every 1.3 seconds, and AutoBuy and ChestManager use the game's own 10 and 24 studs instead of a range option.
<font color="#ff6b6b">[!]</font> BedWars: the match and lobby packs asked the game for its ability controller before the game had started. That broke the controller for the whole session and left nearly every module dead. They now wait for the game to start first.

<b><font color="#d378ff">v3.12.2 - SkyWars EggProtector</font></b>
<font color="#63dc82">[+]</font> SkyWars EggProtector in World: whenever a side or the top of your egg is open, it covers it with the toughest block you carry, and it waits for blocks when you have none.
<font color="#63dc82">[+]</font> EggProtector's Place range goes up to 1,000 studs. Past what the server accepts, only your hitbox goes to the egg while your character and camera stay put.
<font color="#6aa9ff">[^]</font> SkyWars Breaker's Break range now goes up to 1,000 studs. Past the 21 the server accepts, only your hitbox goes to the egg, the same way Reach does it.
<font color="#63dc82">[+]</font> Reset to default range buttons on Breaker and EggProtector.

<b><font color="#d378ff">v3.12.1 - SkyWars Reach</font></b>
<font color="#63dc82">[+]</font> SkyWars Reach in Combat, with Attack, Place and Break toggles that each have their own range. They start at what the game allows (13.5 studs to attack, 18 to place and to break) and go up to 1,000.
<font color="#63dc82">[+]</font> Reach works past what the server accepts as well: beyond 18 studs for a hit and 21 for a block, only your hitbox goes to whatever you clicked while your character and camera stay put.
<font color="#ff6b6b">[!]</font> SkyWars Breaker's range slider went up to 40 studs, further than eggs can be hit from. It now stops at 21, and its Teleport option covers anything further.

<b><font color="#d378ff">v3.12.0 - SkyWars</font></b>
<font color="#63dc82">[+]</font> SkyWars is now supported: a SkyWars match (solo, duos, egg squad or bridge) loads its own set of modules.
<font color="#63dc82">[+]</font> AutoWin in Utility: hangs above every enemy egg in turn and mines it, then stays above each enemy, out of their reach, hitting them and anyone beside them until nobody is left. It holds the pickaxe for eggs and the sword for players.
<font color="#63dc82">[+]</font> GodMode in Blatant: while an enemy is close, the hitbox the server uses hangs out of every enemy's reach and still inside yours, and lifts further when a shot is heading for it. Your character and camera stay exactly where you put them.
<font color="#63dc82">[+]</font> InfiniteAura in Blatant: hits enemies up to 1,000 studs away by sending that hitbox above them, weakest first, while your character and camera never move.
<font color="#63dc82">[+]</font> GameStaller in Utility: parks the hitbox far above the map from the start of the game until it ends, so nobody can reach you. Keep my view leaves your character and camera on the map.
<font color="#63dc82">[+]</font> AntiDeath in Blatant: at low health it moves you onto a platform high above the fight, uses a Shield or Adrenaline, buying an Adrenaline on the spot when you have none, and brings you back down once your health recovers or the timer runs out. Void save returns you to the last block you stood on when you fall under the map.
<font color="#63dc82">[+]</font> ItemCollector in World: picks up dropped coins and items from anywhere on the map. Only the hitbox travels, so your character and camera stay put, and a whole pile is taken in one 0.2 second stop.
<font color="#63dc82">[+]</font> PlayerAttach in Blatant: sticks you to the weakest target in range, with a Height slider to stay above them.
<font color="#63dc82">[+]</font> Killaura in Blatant, with range, angle, max targets, target box, target particles and custom swing settings. It lands a hit every 0.4 seconds, the fastest the game allows.
<font color="#63dc82">[+]</font> Nuker in World: breaks blocks other teams placed around you without aiming at them.
<font color="#63dc82">[+]</font> Breaker in World breaks eggs around you, and its Teleport option goes to every enemy egg on the map, hangs above it and mines it, then brings you back.
<font color="#63dc82">[+]</font> ProjectileAimbot and ProjectileAura in Blatant: both aim with the speed and drop of the projectile you are using, and ProjectileAura fires fully drawn shots with a Fire delay you choose, down to 20 a second.
<font color="#63dc82">[+]</font> AntiFall, NoFall, NoSlowdown and InvMove in Blatant.
<font color="#63dc82">[+]</font> AutoClicker, Sprint and Velocity in Combat.
<font color="#63dc82">[+]</font> AutoBuy and AutoConsume in Inventory: AutoBuy upgrades your sword, armour and pickaxe and buys the team upgrades you tick from wherever you are, and Buy Blocks keeps team concrete in stock.
<font color="#63dc82">[+]</font> Scaffold in Utility, ChestSteal in World and Viewmodel in the Legit window.
<font color="#6aa9ff">[^]</font> Since v3.11.0, Killaura and AutoWin strike every frame the target can be hurt again and lead a target as each hit knocks it away, which takes the time between hits from about 0.5 seconds down to 0.4.
<font color="#6aa9ff">[^]</font> Since v3.11.0, ItemCollector is several times faster and no longer moves your character or camera, and it works through the whole map without coming back between items.
<font color="#6aa9ff">[^]</font> Since v3.11.0, AutoWin hits everyone standing in reach of its target, skips anyone who has already fallen off the map and never follows a target into the void.
<font color="#ff6b6b">[!]</font> A SkyWars match could hang on its loading screen when ElevateV4 loaded before the game had. The modules now wait for the game to finish starting.
<font color="#ff6b6b">[!]</font> AutoWin did not have the sword in hand when it went from eggs to players, most of all with Killaura on. It now really selects the pickaxe and then the sword.
<font color="#ff6b6b">[!]</font> SkyWars modules undid each other's tool switches. Placing, mining, shooting and striking now each tell the server what to hold only when it differs.
<font color="#ff9f43">[-]</font> AntiHit from v3.11.0 is replaced by GodMode.
<font color="#ff9f43">[-]</font> In SkyWars, Reach, TriggerBot, SilentAim, Disabler, AutoRejoin, Rejoin and ServerHop are hidden because they do nothing there, and the universal Killaura, AutoClicker, AntiVoid and NoFallDamage make way for the SkyWars versions.

<b><font color="#d378ff">v3.10.0 - New modules, NoShake and fixes</font></b>
<font color="#63dc82">[+]</font> New ViewLines module in Render: a line out of each player's head shows which way they are facing. It has length, thickness, colour and transparency settings, can stop at walls and can show through them.
<font color="#63dc82">[+]</font> New NoShake module in Render: removes screen shake in any game. It tells a shake from camera movement that is meant by how it moves, so aim modules, leaning and camera offsets keep working. A Strength slider sets how slow a shake it still removes.
<font color="#63dc82">[+]</font> New Spectate module in World: moves your camera onto another player while your character stays put. Type a name, use the Next and Previous buttons, or press ] and [.
<font color="#63dc82">[+]</font> AutoShoot and Killaura Fast Hits have Use fireball and Use gloop toggles.
<font color="#63dc82">[+]</font> Projectile lists in AutoShoot, Killaura Fast Hits and ProjectileAura now accept gloop and gloop_projectile as names for gloop.
<font color="#63dc82">[+]</font> New ClickTP module in Blatant: hold a key (Left Control by default) and click to teleport to that spot, at once or as a glide. It refuses spots that are out of range or have no room to stand in.
<font color="#63dc82">[+]</font> New AntiFling module in Utility: players near you can no longer collide with your character, and anything that still throws you faster than a set speed is stopped and you are put back where you stood.
<font color="#63dc82">[+]</font> New ServerInfo module in the Legit window: shows how many players are in the server and how long it has been running, with a button to copy the server ID.
<font color="#63dc82">[+]</font> New ComboCounter module in the Legit window (BedWars): counts the hits you land in a row.
<font color="#63dc82">[+]</font> BoostAirJump has a Max rise slider.
<font color="#63dc82">[+]</font> Xray has a Transparency slider.
<font color="#63dc82">[+]</font> Radar has a Range slider that sets how far its edge reaches.
<font color="#63dc82">[+]</font> ItemESP reworked: a see-through box around each item drop with its count above it, a Colour picker whose opacity sets how solid the box is, a Resource colours toggle that gives iron, gold, diamonds and emeralds their own colours, and a Show name toggle. Its settings now apply straight away instead of after turning it off and on.
<font color="#63dc82">[+]</font> 21 more modules show their main setting next to their name in the module list, like AutoClicker's CPS, Reach, HitBoxes, Velocity, AimAssist, ProjectileAura, Scaffold and TPAura.
<font color="#6aa9ff">[^]</font> AutoClicker outside BedWars: Click and RightClick now only click while you hold that mouse button, and never while a menu is open or the cursor is over a button. A new Require mouse down toggle turns the old always clicking behaviour back on.
<font color="#6aa9ff">[^]</font> Timer shows its speed next to its name.
<font color="#6aa9ff">[^]</font> WhiteHits, ReachDisplay, ShadowRemover, AntiVoidFlag, TexturePack, MotionBlur and FFlagEditor now have tooltips.
<font color="#6aa9ff">[^]</font> Xray no longer freezes the game for a moment when it is turned on in a big map, and it no longer fades your own character.
<font color="#6aa9ff">[^]</font> KeepSprint, HitFix and Crosshair now check the game code they patch before changing it. After a game update they tell you instead of changing something unrelated.
<font color="#6aa9ff">[^]</font> Crosshair accepts a bare image number as well as a full asset address.
<font color="#6aa9ff">[^]</font> Disabler leaves ElevateV4's own listeners alone on executors that can tell them apart.
<font color="#6aa9ff">[^]</font> AimAssist, Disabler, AutoRelease and Reach outside BedWars now tell you when your executor is missing the function they need.
<font color="#6aa9ff">[^]</font> Health outside BedWars updates when your health changes instead of redrawing every frame.
<font color="#6aa9ff">[^]</font> ArmorSwitch, KnockbackDelay, Radar, Fullbright and Xray have clearer tooltips.
<font color="#6aa9ff">[^]</font> Spider and NoClip no longer rebuild their list of players every frame.
<font color="#6aa9ff">[^]</font> AutoBalloon and AutoVoidDrop no longer freeze the game for a moment at the start of a match while they look for the lowest point of the map.
<font color="#6aa9ff">[^]</font> The NEW, UPDATED and BROKEN tags now use the list the loader has already checked instead of downloading it a second time at every launch.
<font color="#6aa9ff">[^]</font> ProjectileAimbot now aims a part-charged shot for the speed it really leaves at when Aim change is on.
<font color="#6aa9ff">[^]</font> SilentAim, Cape, AntiVoid and Arrows outside BedWars had small internal tidy-ups, and AntiVoid's tooltip was rewritten.
<font color="#ff6b6b">[!]</font> StateSpoofer no longer shows the raknet warning at every launch on executors without raknet.
<font color="#ff6b6b">[!]</font> StateSpoofer: the Mode list now shows the mode that is really in use, and changing the mode while the module is on switches to it straight away.
<font color="#ff6b6b">[!]</font> StateSpoofer in RakNet mode now skips packets it does not recognise instead of risking a disconnect.
<font color="#ff6b6b">[!]</font> BoostAirJump no longer keeps getting faster for as long as jump is held. It stops at the Max rise speed.
<font color="#ff6b6b">[!]</font> HighJump with Auto Disable off no longer starts a new jump on every frame you hold space. It jumps once each time you are on the ground.
<font color="#ff6b6b">[!]</font> Panic now also turns off the modules in the Legit and Kits windows.
<font color="#ff6b6b">[!]</font> Timer can no longer freeze the game when its extra physics step fails.
<font color="#ff6b6b">[!]</font> HitBoxes outside BedWars puts a hitbox back to normal as soon as it stops being a target, not only when the module is turned off.
<font color="#ff6b6b">[!]</font> MotionBlur now blurs the same amount at every framerate.
<font color="#ff6b6b">[!]</font> PlayerOutline no longer destroys highlights it did not create when it is turned off.
<font color="#ff6b6b">[!]</font> AutoPlay no longer errors when no party leader is recorded or Random finds no mode to queue.
<font color="#ff6b6b">[!]</font> FFlagEditor now tells you when your executor cannot set fast flags, and says how many flags were applied or refused.
<font color="#ff6b6b">[!]</font> Gravity now gives the game's own gravity back when it is turned off, and changing its Mode while it is on takes effect straight away.
<font color="#ff6b6b">[!]</font> Fullbright no longer starts a new waiting task on every lighting change, which was every frame in a game with a day and night cycle.
<font color="#ff6b6b">[!]</font> AntiRagdoll now also blocks the Ragdoll state, not only falling down.
<font color="#ff6b6b">[!]</font> ArmorSwitch no longer gets stuck when a slot has nothing to put on.
<font color="#ff6b6b">[!]</font> Velocity and KnockbackDelay can be turned off in either order without breaking each other.
<font color="#ff6b6b">[!]</font> RemovePlayerLevelUI keeps hiding the level of players who join later, and turning it off shows the levels again.
<font color="#ff6b6b">[!]</font> SetPlayerLevel keeps your chosen level when the game refreshes it.
<font color="#ff6b6b">[!]</font> ShadowRemover stops straight away when it is turned off part way through the map.
<font color="#ff6b6b">[!]</font> AutoSuffocate no longer asks for the same block several times over.
<font color="#ff6b6b">[!]</font> PlayerAttach no longer moves your body while you are dead or the server has control of it.
<font color="#ff6b6b">[!]</font> AutoRelease no longer errors on a throw that has no charge, and only clicks inside the game.
<font color="#ff6b6b">[!]</font> Health in BedWars no longer errors when your health has not been sent yet.
<font color="#ff6b6b">[!]</font> NoSlowdown no longer misses some of the slowdowns already on you when it is turned on.
<font color="#ff6b6b">[!]</font> Reach outside BedWars puts a resized tool back exactly as it was.
<font color="#ff6b6b">[!]</font> InfiniteKrystal is back in the Kits window. Its file had been renamed without the module list being updated, so it was never loaded.
<font color="#ff6b6b">[!]</font> TargetStrafe and SafeWalk no longer leave your movement broken when they are turned off in a different order than they were turned on.
<font color="#ff6b6b">[!]</font> Fly and FastFly no longer make your balloons impossible to pop after both have been used.
<font color="#ff6b6b">[!]</font> A module that gets removed while it is on is now switched off first instead of carrying on in the background.
<font color="#ff6b6b">[!]</font> Rainbow colours no longer freeze for the rest of the session when one of them fails.
<font color="#ff6b6b">[!]</font> Breadcrumbs keeps working after you respawn.
<font color="#ff6b6b">[!]</font> HighJump no longer freezes the game when gravity is 0, and its hold mode now works with the mobile jump button and a gamepad.
<font color="#ff6b6b">[!]</font> Scaffold's Tower now works with the mobile jump button and a gamepad.
<font color="#ff6b6b">[!]</font> Dragging a window on mobile no longer gets stuck when the touch is interrupted.
<font color="#ff6b6b">[!]</font> Turning CleanKit off brings the Zephyr orbs and indicator back.
<font color="#ff6b6b">[!]</font> Blink turns itself off when a teleport fails instead of staying on while doing nothing.
<font color="#ff6b6b">[!]</font> AutoEmber now sends the saber itself to the server, and its Limit to item toggle works.
<font color="#ff6b6b">[!]</font> AutoUma works again with Limit to item off.
<font color="#ff6b6b">[!]</font> AutoMarcel, AutoFortify, AutoEvelynn, AutoGompy, OG4v4v4v4, CheatDetector and MemoryFixer no longer leave a second copy running after a quick off and on.
<font color="#ff6b6b">[!]</font> AutoToxic's Troll reply now waits before it is sent (1.5 seconds by default, with a new Troll Delay slider), so it shows up after the message it answers instead of before it.
<font color="#ff6b6b">[!]</font> ProjectileAimbot no longer sends a shot at full speed while telling the server it was only part charged. The server throws such a shot away, which showed as a hit that did no damage.
<font color="#ff6b6b">[!]</font> SilentAim's AutoCharge now sends the charge it claims together with the speed. The charge was being written under a name the game does not read, so a part-drawn shot went out at full speed and could be thrown away.
<font color="#ff6b6b">[!]</font> ProjectileAimbot and SilentAim no longer claim a charge for crossbows and headhunters. Those have no charge, and the time being claimed was their multishot hold.
<font color="#ff9f43">[-]</font> Fly outside BedWars: the Krystal, Sigrid, Grim Reaper and Zephyr speed settings are gone. Fly now always uses the Speed slider.
<font color="#ff9f43">[-]</font> ItemESP's Item transparency slider is gone. The Colour picker's opacity does the same job.
<font color="#ff9f43">[-]</font> ProjectileAimbot's Max accuracy toggle is gone. It aimed for a slower shot than the one that was fired.

<b><font color="#d378ff">v3.9.0 - Breaker and aim rework</font></b>
<font color="#6aa9ff">[^]</font> Breaker reworked: Breaker Type is now the first setting, and the Break mode dropdown and Closest break toggle are gone because each type decides that itself.
<font color="#6aa9ff">[^]</font> Breaker Blatant always takes the route with the fewest hits and the quickest of the targets in range, ignoring walls, people and where you are facing.
<font color="#6aa9ff">[^]</font> Breaker Legit only mines blocks you could really reach: in view, within 18 studs, the nearest one first, and it stays on that block until it breaks.
<font color="#63dc82">[+]</font> Breaker Legit has a Break Chance slider (1 to 100%) that skips some hits like a missed swing, and an Only while in combat toggle that applies it only during a fight.
<font color="#63dc82">[+]</font> Breaker has a Reset to legit range button that sets Break range to 18 studs. In Legit the slider cannot go above 18.
<font color="#6aa9ff">[^]</font> Breaker Limit to items now mines only with the tool in your hand and never swaps to a better one unless Auto Tool is on. Legit works the same way.
<font color="#6aa9ff">[^]</font> Breaker Auto Tool now switches for the block being mined instead of the target behind it.
<font color="#ff6b6b">[!]</font> Breaker Legit no longer gives up on a target covered by more than one layer of blocks.
<font color="#6aa9ff">[^]</font> Every Target mode list now offers Cursor, Distance, Damage, Angle, Lowest Health, Highest Health, Threat and Hit chance. Cursor is the old Mouse, and Health is split in two. A saved Mouse or Health choice goes back to the first mode in the list.
<font color="#63dc82">[+]</font> New Hit chance target mode: picks whoever is easiest to hit, meaning close, slow and on the ground.
<font color="#63dc82">[+]</font> ProjectileAura has a Target mode setting.
<font color="#ff6b6b">[!]</font> ProjectileAimbot and SilentAim now aim at the part you chose on a running target. Before, every part was aimed at the same height once the target moved.
<font color="#ff6b6b">[!]</font> ProjectileAura no longer treats a standing target as falling when it aims above the root, which made Head shots land low.
<font color="#6aa9ff">[^]</font> Dynamic part: ProjectileAura also goes for the head when the weapon it fires is a headhunter that is not in your hand.
<font color="#6aa9ff">[^]</font> BowAssist in third person now moves your cursor onto the target instead of turning your camera. First person is unchanged.
<font color="#ff6b6b">[!]</font> Head shots no longer land below the head on a moving target whose rig reports the wrong height. Training dummies were being aimed up to a stud low.
<font color="#ff6b6b">[!]</font> Aiming at the head now always goes for the middle of the head. It is no longer lifted above it to cover a jump.
<font color="#6aa9ff">[^]</font> ProjectileAimbot stays on the target it picked and only changes when another one has been the top pick for 0.4 seconds, so it no longer flickers between entities.
<font color="#6aa9ff">[^]</font> ProjectileAimbot keeps its last aim for up to 0.3 seconds when a frame finds no solution, instead of snapping to your cursor.
<font color="#6aa9ff">[^]</font> ProjectileAimbot and SilentAim fall back to a straight-line lead, then a direct shot at the part, when the full prediction finds nothing.

<b><font color="#d378ff">v3.8.3 - Dodge modules</font></b>
<font color="#6aa9ff">[^]</font> AntiHit and AutoDodge swapped names. AntiHit is now the one that floats your hitbox out of sword reach, and AutoDodge is the one that lifts your whole character. Saved settings stay under the old names, so check which of the two is switched on.
<font color="#63dc82">[+]</font> AntiDeath has an HP Threshold slider: it only acts while your health is at or below that share of your max health. 100% keeps it always active.
<font color="#6aa9ff">[^]</font> AntiDeath keeps your hitbox under the map for 1.8 seconds at a time and comes up for 0.15 seconds, instead of being up a third of the time.
<font color="#6aa9ff">[^]</font> AntiDeath hides at least 26 studs below you, so a thin floor or bridge no longer leaves your hitbox inside sword reach.
<font color="#6aa9ff">[^]</font> AntiHit starts at 18 studs instead of 8: your hitbox lifts out of reach while the enemy is still walking up to you, and stays inside your own reach on the way.
<font color="#6aa9ff">[^]</font> AntiHit touches the ground every 1.7 seconds instead of every 0.8, so there are half as many moments you can be hit.
<font color="#6aa9ff">[^]</font> AutoDodge rewritten: it lifts you just past the enemy's sword reach instead of 25 studs and holds you there, coming down for a moment every 1.7 seconds. With Killaura on you stay inside your own attack range while lifted.
<font color="#ff6b6b">[!]</font> AutoDodge no longer deals fall damage when it brings you down.

<b><font color="#d378ff">v3.8.2 - Settings polish</font></b>
<font color="#63dc82">[+]</font> Speed has a Speed Effect toggle: while a speed potion or speed mushroom is active, Blatant mode moves you at 34.5 studs. Without the effect your normal Speed value is used.
<font color="#63dc82">[+]</font> SilentAim and ProjectileAimbot have a Range slider (30 to 1000 studs). Anyone further away than that is not targeted.
<font color="#ff6b6b">[!]</font> AutoTool no longer stops you from mining when the right tool is already in your hand.
<font color="#ff6b6b">[!]</font> AutoBuy: the Arrow amount slider now hides together with Buy Bows.
<font color="#ff6b6b">[!]</font> Speed outside BedWars: Jump Power now hides together with AutoJump.
<font color="#ff6b6b">[!]</font> AutoEnchant shows Legit mode while Repair tables is on.
<font color="#ff6b6b">[!]</font> Speedmeter now measures how far you actually moved, so it also counts Speed and other modules that move you directly, and it shows one decimal.
<font color="#6aa9ff">[^]</font> The target list is now the first setting in AimAssist, AutoDrill, AutoMarrow, AutoSigrid, DeathAdderAimbot and ForcePlayerCollisions.
<font color="#6aa9ff">[^]</font> Sub-settings now sit directly under the toggle or mode they belong to in AutoDrill, AutoGingerbreadMan, AutoLani, AutoNazar, AutoPearl, FakeLag, SilentAura and StaffDetector.

<b><font color="#d378ff">v3.8.1 - Fixes</font></b>
<font color="#63dc82">[+]</font> New FlyingBackpackDisabler module in Blatant: with a Flying Backpack on your back it keeps the server float check off while you are in the air, so Fly, TPDown and InfiniteJump stop needing TP Down. It stops jump presses from draining the backpack and hands back to TP Down when the server refuses flaps (very high up or out of energy).
<font color="#63dc82">[+]</font> Fly has its own Show UI bar (with Air Only) that fills up until its TP Down pulls you to the ground. Only one of the Fly and TPDown bars can be on: turning one on turns the other off.
<font color="#ff6b6b">[!]</font> Modules made by the AI Assistant load again instead of failing with an error at startup.
<font color="#ff6b6b">[!]</font> Running ElevateV4 while it is still loading (for example auto-execute plus a manual run) no longer leaves two copies running. The extra run is ignored.
<font color="#ff6b6b">[!]</font> Config saving is more reliable: switching a Kits or Visuals module and moving a window now save straight away, and the config is also saved when you open the Roblox menu.
<font color="#ff6b6b">[!]</font> One module or window that cannot be saved or restored no longer stops the rest of your config from saving or loading. If a config cannot be loaded at all, you are told that nothing will be saved.
<font color="#ff6b6b">[!]</font> AutoBuy buys again when the upgrade shopkeeper is standing closer to you than the item shopkeeper, which is what stopped armour from being bought.
<font color="#ff6b6b">[!]</font> AutoBuy no longer buys or announces the same item twice while the first purchase is still on its way.
<font color="#ff6b6b">[!]</font> AutoBuy, AutoRefill and AutoUpgrade only say "Bought" once the server confirms the purchase, and several of the same item show as one notification.
<font color="#ff6b6b">[!]</font> AutoUpgrade works again and shows a toggle for every team upgrade.
<font color="#ff6b6b">[!]</font> SkinChanger works again and lists its skins.
<font color="#ff6b6b">[!]</font> InfiniteSigrid works again. It stopped the moment it was switched on.
<font color="#ff6b6b">[!]</font> OreESP marks every ore again instead of stopping after the first one.
<font color="#ff6b6b">[!]</font> ProjectileAimbot aims again with Auto Charge switched off.
<font color="#ff6b6b">[!]</font> Interface refreshes the health bar when your health bar changes.
<font color="#ff6b6b">[!]</font> InventoryESP applies its background colour as you move the slider.
<font color="#ff6b6b">[!]</font> AutoBank no longer warns that the server will not hold your items when a stack was only out of your control for a moment.
<font color="#ff6b6b">[!]</font> AutoCounter no longer errors when a TNT block it was tracking is removed.
<font color="#ff6b6b">[!]</font> Landing from InfiniteFly with NoFallDamage on no longer takes fall damage.
<font color="#ff6b6b">[!]</font> The TPDown bar no longer disappears while Fly or InfiniteJump is handling TP Down. It follows their timer instead.
<font color="#ff6b6b">[!]</font> Bow and projectile modules (Killaura, AutoShoot, BowAssist, ProjectileLanding and others) use the game's real bow offsets again instead of zero.
<font color="#ff6b6b">[!]</font> The Reset to default movement button in the universal Speed module works.
<font color="#ff6b6b">[!]</font> Blink, FakeLag and NoClip's FFlag mode tell you when your executor cannot run them instead of failing silently.
<font color="#6aa9ff">[^]</font> LongJump now follows a low arch that comes back to the height you launched from, instead of climbing higher the further you go.
<font color="#6aa9ff">[^]</font> NoFallDamage's Blatant mode is back to how it worked before v3.5.0.

<b><font color="#d378ff">v3.8.0 - Killaura and AutoBank update</font></b>
<font color="#63dc82">[+]</font> New KillauraOLD module in Blatant: the old KillauraV3 from before v3.5.0, with all of its original settings.
<font color="#6aa9ff">[^]</font> Killaura is updated to the newest catvape version, with tighter hit timing that backs off by itself when hits start ghosting.
<font color="#6aa9ff">[^]</font> Killaura's High hitreg is now on by default. Configs that already saved it keep their choice.
<font color="#6aa9ff">[^]</font> Killaura's Attack range now also covers targets above and below you, replacing Horizontal range and Vertical range.
<font color="#6aa9ff">[^]</font> Killaura's Custom Animation keeps working after you respawn.
<font color="#6aa9ff">[^]</font> Killaura and KillauraOLD switch each other off, so only one aura attacks at a time.
<font color="#ff9f43">[-]</font> Removed Killaura's Fury speed, Dynamic delay and Delay step, since the new timing handles them by itself.
<font color="#6aa9ff">[^]</font> AutoDodge is replaced with catvape's AntiHit: your hitbox hovers just outside the enemy's sword reach and inside yours, touching the ground briefly every 0.8 seconds, never faster than you walk and only over solid ground.
<font color="#ff9f43">[-]</font> Removed AutoDodge's settings (Priority, Enemy reach, Margin, Engage, Hitbox speed, Vertical escape, Show hitbox, Notifications), since the new AutoDodge tunes itself.
<font color="#63dc82">[+]</font> AutoBank hands your items back as soon as you walk up to a shop, not only when you open it.
<font color="#63dc82">[+]</font> Buying something while AutoBank holds your items hands back just what that purchase needs, and the shop shows items you can afford with what is held.
<font color="#63dc82">[+]</font> New AutoBank Bank mode: Always, Clear area (only while nobody is near you) or Manual, plus a Bank now button.
<font color="#63dc82">[+]</font> AutoBank's Before death can also predict a lethal hit from your last hit and your ping (Predict lethal hits).
<font color="#6aa9ff">[^]</font> AutoBank's While falling reacts earlier by predicting where you will be, allowing for your ping.
<font color="#6aa9ff">[^]</font> AutoBank's Spectator check is now Pause when Spectating: it gives everything back and carries on by itself once the spectator leaves.
<b><font color="#d378ff">AI Assistant expansion</font></b>
<font color="#63dc82">[+]</font> The AI Assistant has an Effort slider: Instant, Balance, Thinking and Max. Instant is the fastest, Balance picks a quick or careful answer by itself, and Max uses the strongest AI.
<font color="#63dc82">[+]</font> Simple commands like "turn on Killaura", "bind Fly to F" or "load ranked" now happen instantly without waiting for the AI.
<font color="#63dc82">[+]</font> The AI Assistant looks things up before it answers: every setting of a module, the players and the server, your FPS and ping, your error log, which modules a config turns on and what is inside the game.
<font color="#63dc82">[+]</font> The AI Assistant controls much more: many modules or a whole category at once, every kind of setting including colours, lists and ranges, key combos, renaming and hiding modules, buttons inside settings, and creating, exporting or deleting configs.
<font color="#63dc82">[+]</font> The AI Assistant can control your character and camera: walk speed, jump power, jumping, equipping items, walking to players or saved waypoints, looking at someone, field of view, zoom and your FPS cap.
<font color="#63dc82">[+]</font> An Undo button under the AI's answer puts back everything it changed. Typing /undo does the same.
<font color="#63dc82">[+]</font> New Assistant control setting: Full control, or Read only so the AI can answer but never change anything. There is also a new Expert style.
<font color="#63dc82">[+]</font> The AI Assistant can run code in your game, make its own modules that appear in the menu, and set up automations (for example "when my health is low, turn on Speed").
<font color="#63dc82">[+]</font> The AI Assistant can read web pages and files, chat for you, teleport you and follow players.
<font color="#63dc82">[+]</font> The first time it needs these extra powers it asks you once. Your answer is kept until you press Forget assistant memory.
<font color="#6aa9ff">[^]</font> The AI Assistant answers simple questions faster and fixes its own mistakes when a change does not work.
<font color="#6aa9ff">[^]</font> Each answer shows which effort it used and which AI answered.
<b><font color="#d378ff">v3.7.1 - Faster AI and Target Info fix</font></b>
<font color="#ff6b6b">[!]</font> The AI Assistant answers in a few seconds instead of timing out. It uses a faster AI and automatically switches to another one if the first is busy.
<font color="#ff6b6b">[!]</font> Target Info always shows the player Killaura is fighting, or the one you are hitting yourself, instead of jumping between everyone other modules aim at.
<b><font color="#d378ff">v3.7.0 - Real AI Assistant</font></b>
<font color="#63dc82">[+]</font> The AI Assistant is now a real AI. Ask it anything in your own words and it answers from what it can see in your menu, game and server.
<font color="#63dc82">[+]</font> The AI Assistant still does things for you: switching modules on or off, changing settings, binding keys, loading configs, changing your accent and more. It shows whether each change worked.
<font color="#63dc82">[+]</font> The AI Assistant remembers notes about you between chats and suggests follow-up questions you can press.
<font color="#63dc82">[+]</font> Each player can send 10 messages a minute. The window shows how many you have left and when the limit resets.
<font color="#63dc82">[+]</font> While the AI is thinking you see how long it has been waiting, and the send button becomes a stop button.
<font color="#6aa9ff">[^]</font> The AI Assistant window is smaller and uses its space better, with bigger, easier to read text.
<font color="#ff6b6b">[!]</font> Fixed some images (like the Aether logo) not loading when another script used an image with the same file name.
<font color="#ff9f43">[-]</font> Removed the old assistant's taught phrases, routines, win/loss record, join/leave and low health alerts, and sending chat messages for you.
<b><font color="#d378ff">v3.6.2 - Startup fix</font></b>
<font color="#ff6b6b">[!]</font> Fixed ElevateV4 failing to start with "attempt to call a nil value" when the cached GUI file was damaged; it is now downloaded again automatically.
<b><font color="#d378ff">v3.6.1 - AutoDodge rewrite and FOV circles</font></b>
<font color="#6aa9ff">[^]</font> AutoDodge rewritten: your hitbox now stays further from every enemy than they can hit, instead of dropping right next to them every 0.8 seconds.
<font color="#6aa9ff">[^]</font> AutoDodge predicts where enemies will be by the time the server sees you, starts earlier, and walks your hitbox only over safe ground, never faster than you can walk.
<font color="#63dc82">[+]</font> AutoDodge learns enemies who hit from further than they should and keeps more distance from them, and lifts out of reach for short moments when boxed in.
<font color="#63dc82">[+]</font> AutoDodge Fight priority keeps you inside your own Killaura reach while staying out of theirs, and Show hitbox marks where the server sees you.
<font color="#ff6b6b">[!]</font> AutoDodge: Speed and Fly no longer drag your hitbox toward the enemy, and a lagback no longer leaves it fighting the server.
<font color="#ff6b6b">[!]</font> ProjectileAimbot only aims at people inside the FOV circle. Its FOV was read as a distance in studs, so it snapped onto anyone that close.
<font color="#ff6b6b">[!]</font> SilentAim only redirects arrows to people inside the FOV circle you see. It measured from the middle of the screen while the circle followed your cursor.
<font color="#ff6b6b">[!]</font> ProjectileAura and OwlAura check the FOV circle the same way, and ProjectileAura checks it again before every shot.
<b><font color="#d378ff">v3.6.0 - AI Assistant and TrixieDisabler</font></b>
<font color="#63dc82">[+]</font> AI Assistant: a new window under Configs. Ask it in plain words to turn modules on or off, change their settings, bind keys, load configs or change your accent, and it does it for you.
<font color="#63dc82">[+]</font> AI Assistant explains any module and its settings, finds and recommends modules, and lists what is on, your binds and your configs.
<font color="#63dc82">[+]</font> AI Assistant knows the game and server: players, closest player, player info, kit, FPS, ping, memory, server age and ElevateV4 errors.
<font color="#63dc82">[+]</font> AI Assistant can rejoin, server hop, spectate players, manage friends and targets, warn you when someone joins or leaves or your health is low, and send chat messages.
<font color="#63dc82">[+]</font> AI Assistant is personal: it remembers your name and notes, learns which module you meant, tracks your most used modules and win/loss record, and runs routines (several requests saved under one name).
<font color="#63dc82">[+]</font> AI Assistant tools: reminders and timers, a stopwatch, a calculator, unit conversions, dice and coin flips. Chats are saved in its history.
<font color="#63dc82">[+]</font> The assistant's message bubbles, chips and icons follow your GUI accent. Assistant style and memory reset are in the GUI settings.
<font color="#63dc82">[+]</font> AI Assistant follow-ups work like a chat: "and speed", "what about reach", "turn it off", "tell me more", "simpler" and "again".
<font color="#63dc82">[+]</font> Copy, retry or rate any reply, click your own message to edit and resend it, and press Tab to accept the suggestion as you type.
<font color="#63dc82">[+]</font> Slash commands (/help, /new, /history, /search, /title, /export, /summary), chat search in the history, and "summarise this chat".
<font color="#63dc82">[+]</font> Teach the AI Assistant your own phrases: "when I say gg, reply Good game!" or "when I say fight, do enable killaura and velocity".
<font color="#63dc82">[+]</font> The AI Assistant answers common ElevateV4 questions (updating, configs, public configs, Ctrl + K, lag, errors) and gives game tips.
<font color="#ff6b6b">[!]</font> TrixieDisabler: an unanswered warp or rewind now holds your real body for 3 seconds instead of 10.
<font color="#63dc82">[+]</font> TrixieDisabler Keep close (on by default): your clone slows down as it gets ahead of your real body (never below 35% speed), so your body and camera stay close together.
<font color="#ff6b6b">[!]</font> ZephyrDisabler: with 0 wind stacks you now move at Base Speed, not the 1 stack speed.
<font color="#ff6b6b">[!]</font> ZephyrDisabler and NoFallDamage read your wind stacks correctly after a reinject (they stayed at 0 until you rejoined).
<font color="#6aa9ff">[^]</font> The TP Down bar sits lower on the screen, out of the way.
<b><font color="#d378ff">v3.5.3 - BedWars loading hotfix</font></b>
<font color="#ff6b6b">[!]</font> BedWars (including the 8560631822 match servers) loaded as "Universal only": v3.5.1 read the GUI before it was defined at the very top of the BedWars pack, which stopped the whole pack from starting.
<font color="#6aa9ff">[^]</font> When a game pack fails to start, the message now says so and shows the error, instead of claiming there is no game pack.
<b><font color="#d378ff">v3.5.2 - AutoBank polish</font></b>
<font color="#ff6b6b">[!]</font> AutoBank: a stack handed back because Before death or While falling stopped applying could never be picked up (it kept being moved back above the map) and was retried forever.
<font color="#ff6b6b">[!]</font> AutoBank Legit mode only banks and withdraws the whitelist. It used to put away your blocks, bow, arrows and consumables, and empty everything out of the chest at a shop.
<font color="#ff6b6b">[!]</font> AutoBank: switching it off while dead now waits for the respawn to hand items back instead of leaving them above the map.
<font color="#ff6b6b">[!]</font> AutoBank: no more false "server will not let items be held" warning while dead, no skipped stacks, and the Before death toggle no longer drops items in Legit mode.
<font color="#63dc82">[+]</font> AutoBank shows its mode and how many stacks it is holding in the module list, and dims counters with nothing held.
<font color="#6aa9ff">[^]</font> AutoBank: the whitelist applies to both modes and sits at the top, clearer tooltips, internal cleanup.
<b><font color="#d378ff">v3.5.1 - Frame drops and the Performance Monitor</font></b>
<font color="#ff6b6b">[!]</font> FastPickup sent a server request for every dropped item on the map 20 times a second (thousands a second at busy generators). It now asks only for nearby items, one request each at a time.
<font color="#ff6b6b">[!]</font> PickupRange re-requested every item in range until the server answered; it now waits for the answer.
<font color="#ff6b6b">[!]</font> Breaker recalculated its route into a bed up to 60 times a second (its cache was never read); routes are reused until a nearby block changes.
<font color="#ff6b6b">[!]</font> AutoBank read every block on the map every 2 seconds even with While falling off.
<font color="#63dc82">[+]</font> Performance Monitor measures how long each ElevateV4 file runs per frame and how much it allocates, and detects garbage-collection pauses, object and GUI bursts, physics, rendering, network and asset spikes, and freezes.
<font color="#63dc82">[+]</font> The debug report explains each drop: ranked causes with the numbers behind them, what you were doing, the ElevateV4 code that ran, slow single runs and engine timers.
<font color="#6aa9ff">[^]</font> The overlay shows ElevateV4 time per frame and the three busiest files.
<b><font color="#d378ff">v3.5.0 - Ports, Trixie and performance</font></b>
<font color="#63dc82">[+]</font> InfiniteTrixie (removes Rift Warp's clientside cooldown) and TrixieDisabler (keeps control of your clone while repeating Warp and Rewind).
<font color="#63dc82">[+]</font> Zoom: hold a letter key to zoom in like a telescope, with adjustable zoom and smoothing.
<font color="#6aa9ff">[^]</font> Killaura and KitDisplay replaced with newer builds; Killaura's hit tracking no longer errors on every hit.
<font color="#ff6b6b">[!]</font> NoFallDamage no longer takes small hits on the way down from high places, and keeps working after a respawn.
<font color="#ff6b6b">[!]</font> AutoRefill and AutoBuy arrow refills no longer error on every pass.
<font color="#6aa9ff">[^]</font> FPSBoost no longer stutters while the map loads or in fights; StreamRemover, MemoryFixer, Legless, NameTagSpoofer, EntityAnalyser and MineThrough do far less work per frame.
<font color="#6aa9ff">[^]</font> InfiniteJump Hold keeps pushing you up at jump speed while the key is held.
<font color="#6aa9ff">[^]</font> Performance Monitor cut down to six settings. InfiniteFlyV2 is now InfiniteFly.
<font color="#ff9f43">[-]</font> Removed AutoReportV2, FalseBan, TrixieExploit and ProjectileHitbox, and DeathSpawn from BedWars (it stays in other games).
<b><font color="#d378ff">v3.4.0 - Fixes and new modules</font></b>
<font color="#ff6b6b">[!]</font> Beds (and chests, generators, crops, pots...) no longer vanish on your screen: turning an ESP off destroyed the real objects.
<font color="#ff6b6b">[!]</font> The block outline and legit placing/mining no longer break when Reach, MineThrough or AutoTool are switched off in the wrong order.
<font color="#ff6b6b">[!]</font> KitExtender actually extends abilities now; PromptEditor no longer makes prompts fire from far away; the AutoBuy/AutoRefill priority window stops reappearing.
<font color="#ff6b6b">[!]</font> The SilentAim FOV circle shows, and its ProjectileAimbot notification is gone.
<font color="#63dc82">[+]</font> TPDown, AutoZephyr, and Show Inventory for Target Info.
<font color="#63dc82">[+]</font> FOV Circle for ProjectileAura and OwlAura; JadeInstantKill follows the target until you land.
<font color="#6aa9ff">[^]</font> Kits: every kit module is its own entry with its own toggle, sorted into Auto/Ability/Aim/Visual tabs.
<font color="#6aa9ff">[^]</font> Reach is one module (ReachCE replaced it and did nothing); AutoBank gained AutoBankV2's owl check; the performance overlay is called Performance Monitor.
<font color="#ff9f43">[-]</font> Removed Killaura and KillauraV2 (KillauraV3 became Killaura), AutoBankV2, ReachCE, InfiniteFly [BETA] and Fly's kit speed modes.]=]
	body.TextColor3, body.TextSize, body.LineHeight = Color3.fromRGB(170, 170, 170), 13, 1.25
	body.FontFace, body.TextXAlignment, body.TextYAlignment, body.TextWrapped, body.Parent = Font.fromEnum(Enum.Font.Roboto), Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, true, notes
	close.MouseButton1Click:Connect(function() window.Visible = false end)
	function api:Open()
		window.Position = UDim2.new(0.5, -350, 0.5, -194); window.Visible = true; notes.CanvasPosition = Vector2.zero
		if refreshVersionHistory then refreshVersionHistory() end
		task.spawn(function()
			local ref = sourceBranch()
			local ok, body = pcall(game.HttpGet, game, remoteSourceUrl('ElevateV4/version.txt', ref), true)
			local latest = ok and type(body) == 'string' and (body:match('version%s*=%s*([^\r\n]+)') or 'unavailable') or 'unavailable'
			local available = latest ~= 'unavailable' and tostring(latest) ~= tostring(mainapi.Version)
			local pinned = isfile(versionPinPath) and readfile(versionPinPath):gsub('%s+', '') or ''
			if window.Parent then
				status.Text = 'Installed: v'..tostring(mainapi.Version)..'  •  Latest source: v'..latest..
					'  •  '..(pinned ~= '' and 'Pinned previous version' or (available and 'Update available' or 'Up to date'))
			end
		end)
	end
	api.Window = window; self.Changelogs = api; return api
end

function mainapi:CreateNotification(title, text, duration, type)
	if not self.Notifications.Enabled then return end
	local color = type == 'alert' and Color3.fromRGB(250, 50, 56) or type == 'warning' and Color3.fromRGB(236, 129, 43) or Color3.fromRGB(220, 220, 220)
	if license.Closet or license.Webhook then
		if license.Webhook then
			request({
				Url = license.Webhook,
				Method = 'POST',
				Headers = {
					['Content-Type'] = 'application/json'
				},
				Body = httpService:JSONEncode({
					content = '',
					embeds = {{
						title = title or "ElevateV4",
						description = removeTags(text or "None"),
						color = tonumber(color:ToHex(), 16),
						timestamp = os.date('%Y-%m-%dT%X.000Z'),
						fields = {}
					}},
					components = {}
				})
			})
		end
		return
	end
	task.delay(0, function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		local i = #notifications:GetChildren() + 1
		local notification = Instance.new('ImageLabel')
		notification.Name = 'Notification'
		notification.Size = UDim2.fromOffset(math.max(getfontsize(removeTags(text), 14, uipallet.Font).X + 80, 266), 75)
		notification.Position = UDim2.new(1, 0, 1, -(29 + (78 * i)))
		notification.ZIndex = 5
		notification.BackgroundTransparency = 1
		notification.Image = getcustomasset('ElevateV4/assets/new/notification.png')
		notification.ScaleType = Enum.ScaleType.Slice
		notification.SliceCenter = Rect.new(7, 7, 9, 9)
		notification.Parent = notifications
		addBlur(notification, true)
		local iconshadow = Instance.new('ImageLabel')
		iconshadow.Name = 'Icon'
		iconshadow.Size = UDim2.fromOffset(60, 60)
		iconshadow.Position = UDim2.fromOffset(-5, -8)
		iconshadow.ZIndex = 5
		iconshadow.BackgroundTransparency = 1
		iconshadow.Image = getcustomasset('ElevateV4/assets/new/'..(type or 'info')..'.png')
		iconshadow.ImageColor3 = Color3.new()
		iconshadow.ImageTransparency = 0.5
		iconshadow.Parent = notification
		local icon = iconshadow:Clone()
		icon.Position = UDim2.fromOffset(-1, -1)
		icon.ImageColor3 = Color3.new(1, 1, 1)
		icon.ImageTransparency = 0
		icon.Parent = iconshadow
		local titlelabel = Instance.new('TextLabel')
		titlelabel.Name = 'Title'
		titlelabel.Size = UDim2.new(1, -56, 0, 20)
		titlelabel.Position = UDim2.fromOffset(46, 16)
		titlelabel.ZIndex = 5
		titlelabel.BackgroundTransparency = 1
		titlelabel.Text = "<stroke color='#FFFFFF' joins='round' thickness='0.3' transparency='0.5'>"..title..'</stroke>'
		titlelabel.TextXAlignment = Enum.TextXAlignment.Left
		titlelabel.TextYAlignment = Enum.TextYAlignment.Top
		titlelabel.TextColor3 = Color3.fromRGB(209, 209, 209)
		titlelabel.TextSize = 14
		titlelabel.RichText = true
		titlelabel.FontFace = uipallet.FontSemiBold
		titlelabel.Parent = notification
		local textshadow = titlelabel:Clone()
		textshadow.Name = 'Text'
		textshadow.Position = UDim2.fromOffset(47, 44)
		textshadow.Text = removeTags(text)
		textshadow.TextColor3 = Color3.new()
		textshadow.TextTransparency = 0.5
		textshadow.RichText = false
		textshadow.FontFace = uipallet.Font
		textshadow.Parent = notification
		local textlabel = textshadow:Clone()
		textlabel.Position = UDim2.fromOffset(-1, -1)
		textlabel.Text = text
		textlabel.TextColor3 = Color3.fromRGB(170, 170, 170)
		textlabel.TextTransparency = 0
		textlabel.RichText = true
		textlabel.Parent = textshadow
		local progress = Instance.new('Frame')
		progress.Name = 'Progress'
		progress.Size = UDim2.new(1, -13, 0, 2)
		progress.Position = UDim2.new(0, 3, 1, -4)
		progress.ZIndex = 5
		progress.BackgroundColor3 =
			color
		progress.BorderSizePixel = 0
		progress.Parent = notification
		if tween.Tween then
			tween:Tween(notification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
				AnchorPoint = Vector2.new(1, 0)
			}, tween.tweenstwo)
			tween:Tween(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
				Size = UDim2.fromOffset(0, 2)
			})
		end
		task.delay(duration, function()
			if tween.Tween then
				tween:Tween(notification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
					AnchorPoint = Vector2.new(0, 0)
				}, tween.tweenstwo)
			end
			task.wait(0.2)
			notification:ClearAllChildren()
			notification:Destroy()
		end)
	end)
end

local guipane
function mainapi:Load(skipgui, profile)
	table.clear(saveCache)
	mainapi:FlushModuleLayout()
	if not skipgui then
		self.GUIColor:SetValue(nil, nil, nil, accent.Notch)
	end
	local guidata = {}
	local savecheck = true
	local function guarded(what, name, fn)
		local trail = shared.AetherStartup
		if trail and trail.Detail then trail.Mark('config '..what..' '..tostring(name)) end
		local ok, err = pcall(fn)
		if not ok then
			warn('[ElevateV4] could not restore '..what..' '..tostring(name)..': '..tostring(err))
		end
	end

	local usedPositions = {}
	local function restorePosition(object, pos)
		if not (object and object.Object) then return end
		local default = object.DefaultPosition
		if not pos or pos.X == nil or pos.Y == nil then
			if default then object.Object.Position = default end
			return
		end
		local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
		local uiscale = (scale and scale.Scale or 1)
		uiscale = uiscale > 0 and uiscale or 1
		local maxX, maxY = (viewport.X / uiscale) - 60, (viewport.Y / uiscale) - 40
		local offscreen = pos.X < -40 or pos.Y < -40 or pos.X > maxX or pos.Y > maxY
		local key = pos.X..','..pos.Y
		if default and (usedPositions[key] or offscreen) then
			object.Object.Position = default
			usedPositions[default.X.Offset..','..default.Y.Offset] = true
			return
		end
		usedPositions[key] = true
		object.Object.Position = UDim2.fromOffset(pos.X, pos.Y)
	end

	if isfile('ElevateV4/profiles/'..game.GameId..'.gui.txt') then
		guidata = loadJson('ElevateV4/profiles/'..game.GameId..'.gui.txt')
		if not guidata then
			guidata = {Categories = {}}
			self:CreateNotification('ElevateV4', 'Failed to load GUI settings, Try rejoining ur game', 10, 'alert')
		end

		if not skipgui then
			self.Keybind = guidata.Keybind
			for i, v in guidata.Categories do
				local object = self.Categories[i]
				if not object then continue end
				guarded('window', i, function()
					if object.Options and v.Options then
						self:LoadOptions(object, v.Options)
					end
					if v.Enabled and object.Button and object.Button.Toggle then
						object.Button:Toggle()
					elseif v.Enabled and object.Object then
						object.Object.Visible = true
					end
					if v.Standalone and object.Standalone ~= nil then
						object.Standalone = true
						object.Object.Visible = true
					end
					if v.Pinned then
						object:Pin()
					end
					if v.Expanded and object.Expand then
						object:Expand()
					end
					if v.List and (#object.List > 0 or #v.List > 0) then
						object.List = v.List or {}
						object.ListEnabled = v.ListEnabled or {}
						object:ChangeValue()
					end
					restorePosition(object, v.Position)
				end)
			end
		end
	end

	self.Profile = profile or guidata.Profile or 'default'
	self.Profiles = guidata.Profiles or {{
		Name = 'default', Bind = {}
	}}
	refreshConfigProfiles()
	self.Categories.Profiles:ChangeValue()
	if self.ProfileLabel then
		self.ProfileLabel.Text = #self.Profile > 10 and self.Profile:sub(1, 10)..'...' or self.Profile
		self.ProfileLabel.Size = UDim2.fromOffset(getfontsize(self.ProfileLabel.Text, self.ProfileLabel.TextSize, self.ProfileLabel.Font).X + 16, 24)
	end

	local configPath = getConfigPath(self.Profile)
	local legacyConfigPath = getLegacyProfilePath(self.Profile)
	if not isfile(configPath) and isfile(legacyConfigPath) then
		configPath = legacyConfigPath
	end

	if isfile(configPath) then
		local savedata = loadJson(configPath)
		if not savedata then
			savedata = {Categories = {}, Modules = {}, Legit = {}, Kits = {}}
			self:CreateNotification('ElevateV4', 'Failed to load '..self.Profile..' config.', 10, 'alert')
		end

		savedata.Categories = savedata.Categories or {}
		savedata.Modules = savedata.Modules or {}
		savedata.Legit = savedata.Legit or {}
		savedata.Kits = savedata.Kits or {}
		savedata.Modules.BreakerLegit = nil
		savedata.Legit.BreakerLegit = nil
		savedata.Kits.BreakerLegit = nil
		local function mergeModuleConfig(target, aliases)
			local merged = savedata.Modules[target]
			for _, alias in aliases do
				local old = savedata.Modules[alias]
				if old then
					merged = merged or {Enabled = old.Enabled, Bind = old.Bind, Options = {}}
					merged.Options = merged.Options or {}
					for name, value in old.Options or {} do
						if merged.Options[name] == nil then merged.Options[name] = value end
					end
				end
				savedata.Modules[alias] = nil
			end
			if merged then savedata.Modules[target] = merged end
		end
		mergeModuleConfig('AutoClicker', {'AutoClickerV2'})
		mergeModuleConfig('BlockIn', {'Block-In', 'BlockInV2'})
		mergeModuleConfig('RecoveryTP', {'DeathTP'})
		mergeModuleConfig('MineThrough', {'IgnorePlaceHitboxes'})

		local mouseTP = savedata.Modules.MouseTP
		if mouseTP and type(mouseTP.Options) == 'table' then
			local oldTarget = mouseTP.Options.Mode and mouseTP.Options.Mode.Value
			if table.find({'Mouse', 'Player', 'Waypoint'}, oldTarget) then
				mouseTP.Options.Target = mouseTP.Options.Target or {Value = oldTarget}
				mouseTP.Options.Mode = {Value = 'TP'}
			end
			mouseTP.Options.Movement = nil
			mouseTP.Options.Length = nil
			mouseTP.Options.Delay = nil
		end

		local autoEnchant = savedata.Modules.AutoEnchant
		if autoEnchant and type(autoEnchant.Options) == 'table' and not autoEnchant.Options['Desired enchant'] then
			local priority = autoEnchant.Options['Priority order']
			local previous = autoEnchant.Options['Desired enchants'] or autoEnchant.Options['Preferred enchant']
			local desired = priority and priority.Value
				or previous and ((previous.ListEnabled and previous.ListEnabled[1]) or (previous.List and previous.List[1]))
			if desired then autoEnchant.Options['Desired enchant'] = {Value = desired} end
			autoEnchant.Options['Priority order'] = nil
			autoEnchant.Options['Desired enchants'] = nil
			autoEnchant.Options['Preferred enchant'] = nil
		end

		for i, v in savedata.Categories do
			local object = self.Categories[i]
			if not object then continue end
			guarded('window', i, function()
				if object.Options and v.Options then
					self:LoadOptions(object, v.Options)
				end
				if v.Pinned ~= object.Pinned then
					object:Pin()
				end
				if v.Expanded ~= nil and v.Expanded ~= object.Expanded then
					object:Expand()
				end
				if object.Button and object.Button.Toggle and (v.Enabled or false) ~= object.Button.Enabled then
					object.Button:Toggle()
				end
				if v.List and (#object.List > 0 or #v.List > 0) then
					object.List = v.List or {}
					object.ListEnabled = v.ListEnabled or {}
					object:ChangeValue()
				end
				restorePosition(object, v.Position)
			end)
		end

		local modulesSnapshot = table.clone(self.Modules)
		for i, object in modulesSnapshot do
			guarded('module', i, function()
				local v = savedata.Modules[i]
				if not v then
					if object.Enabled then
						if skipgui and self.ToggleNotifications.Enabled then self:CreateNotification('Module Toggled', object.Name.."<font color='#FFFFFF'> has been </font><font color='#FF5A5A'>Disabled</font><font color='#FFFFFF'>!</font>", 0.75) end
						object:Toggle(true)
					end
					return
				end
				if object.Options and v.Options then
					self:LoadOptions(object, v.Options)
				end
				if (v.Enabled or false) ~= object.Enabled then
					if skipgui then
						if self.ToggleNotifications.Enabled then self:CreateNotification('Module Toggled', object.Name.."<font color='#FFFFFF'> has been </font>"..(v.Enabled and "<font color='#5AFF5A'>Enabled</font>" or "<font color='#FF5A5A'>Disabled</font>").."<font color='#FFFFFF'>!</font>", 0.75) end
					end
					object:Toggle(true)
				end
				object:SetBind(v.Bind or {})
				object.Object.Bind.Visible = #(v.Bind or {}) > 0
				if object.SetHidden then
					object:SetHidden(v.Hidden)
				end
			end)
		end
		for _, panel in {{Api = self.Legit, Data = savedata.Legit, Migrate = true}, {Api = self.Kits, Data = savedata.Kits, Migrate = true}} do
			local snapshot = table.clone(panel.Api.Modules)
			for i, object in snapshot do
				guarded('module', i, function()
					local v = panel.Data[i] or (panel.Migrate and savedata.Modules[i]) or nil
					if not v then
						if object.Enabled then
							object:Toggle()
						end
						if object.SetBind then
							object:SetBind({})
						end
						return
					end
					if object.Options and v.Options then
						self:LoadOptions(object, v.Options)
					end
					if object.Enabled ~= (v.Enabled or false) then
						object:Toggle()
					end
					if object.SetBind then
						object:SetBind(v.Bind or {})
					end
					if v.Position and object.Children then
						object.Children.Position = UDim2.fromOffset(v.Position.X, v.Position.Y)
					end
				end)
			end
		end

		if savedata.Keybind then
			self.Keybind = savedata.Keybind
		end
		if self.GUIColor and self.GUIColor.Load then
			pcall(function()
				if savedata.GUIColor then
					self.GUIColor:Load(savedata.GUIColor)
				else
					self.GUIColor:SetValue(nil, nil, nil, accent.Notch)
				end
				self:UpdateGUI(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
			end)
		end

		self:UpdateTextGUI(true)
	else
		local previousLoaded = self.Loaded
		self.Loaded = true
		self:Save()
		self.Loaded = previousLoaded
	end

	if self.Downloader then
		self.Downloader:Destroy()
		self.Downloader = nil
	end
	self.Loaded = savecheck
	self.Categories.Main.Options.Bind:SetBind(self.Keybind)
	if savecheck and not configapi.Accents.Done then
		self:Save()
		configapi.Accents.Mark()
	end

	if not inputService.KeyboardEnabled then
		local hide = isfile('ElevateV4/profiles/hide.txt') and readfile('ElevateV4/profiles/hide.txt') or nil
		if hide ~= nil then
			hide = hide == 'true' and true or false
		end
		local button = Instance.new('TextButton')
		button.LayoutOrder = -1
		button.Size = UDim2.fromOffset(32, 32)
		button.Position = UDim2.new(1, -90, 0, 4)
		button.BackgroundColor3 = Color3.new()
		button.BackgroundTransparency = hide and 1 or 0.35
		button.Text = ''
		button.Parent = game.GameId == 2619619496 and cloneref(game:GetService('Players')).LocalPlayer.PlayerGui.TopBarAppGui.TopBarApp or gui
		local image = Instance.new('ImageLabel')
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Size = UDim2.fromOffset(24, 24)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.BackgroundTransparency = 1
		image.ScaleType = Enum.ScaleType.Fit
		image.Image = getcustomasset('ElevateV4/assets/new/loading.png')
		image.ImageTransparency = hide and 1 or 0
		image.Parent = button
		local buttoncorner = Instance.new('UICorner')
		buttoncorner.Parent = button
		self.VapeButton = button
		mainapi:Clean(button)
		local dragged = false
		local function clampButton()
			if not dragged then return end
			local view = gui.AbsoluteSize
			button.Position = UDim2.fromOffset(
				math.clamp(button.Position.X.Offset, 0, math.max(view.X - 32, 0)),
				math.clamp(button.Position.Y.Offset, 0, math.max(view.Y - 32, 0))
			)
		end
		local suppressClick = false
		button.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			suppressClick = false
			local startPoint, startPos = input.Position, button.AbsolutePosition - gui.AbsolutePosition
			local changed, ended
			changed = inputService.InputChanged:Connect(function(move)
				if move ~= input and not (input.UserInputType == Enum.UserInputType.MouseButton1 and move.UserInputType == Enum.UserInputType.MouseMovement) then return end
				local delta = move.Position - startPoint
				if not suppressClick and Vector2.new(delta.X, delta.Y).Magnitude < 8 then return end
				suppressClick = true
				dragged = true
				if button.Parent ~= gui then
					button.Parent = gui
				end
				button.Position = UDim2.fromOffset(startPos.X + delta.X, startPos.Y + delta.Y)
				clampButton()
				mainapi.ButtonSpot = button.Position
			end)
			ended = inputService.InputEnded:Connect(function(finish)
				if finish ~= input and not (input.UserInputType == Enum.UserInputType.MouseButton1 and finish.UserInputType == input.UserInputType) then return end
				changed:Disconnect()
				ended:Disconnect()
			end)
		end)
		mainapi:Clean(gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(clampButton))
		if button.Parent == gui then
			local players = cloneref(game:GetService('Players'))
			local function occupied(x, y)
				local playerGui = players.LocalPlayer and players.LocalPlayer:FindFirstChildOfClass('PlayerGui')
				if not playerGui then return false end
				local view = gui.AbsoluteSize
				local inset = guiService:GetGuiInset().Y
				for _, point in {{x + 16, y + 16}, {x + 2, y + 2}, {x + 30, y + 2}, {x + 2, y + 30}, {x + 30, y + 30}} do
					local ok, hits = pcall(playerGui.GetGuiObjectsAtPosition, playerGui, point[1], point[2] - inset)
					for _, obj in ok and hits or {} do
						if obj == button or obj:IsDescendantOf(gui) then continue end
						local root = obj:FindFirstAncestorOfClass('ScreenGui')
						if root and root:GetAttribute('ElevateV4') then continue end
						local size = obj.AbsoluteSize
						if size.X > view.X * 0.6 and size.Y > view.Y * 0.6 then continue end
						if obj.BackgroundTransparency < 0.95
							or (obj:IsA('ImageLabel') or obj:IsA('ImageButton')) and obj.Image ~= '' and obj.ImageTransparency < 0.95
							or (obj:IsA('TextLabel') or obj:IsA('TextButton') or obj:IsA('TextBox')) and obj.Text ~= '' and obj.TextTransparency < 0.95 then
							return true
						end
					end
				end
				return false
			end
			local function spots()
				local view = gui.AbsoluteSize
				local inset = guiService:GetGuiInset().Y
				local right, left = view.X - 8, 8
				local ok, bar = pcall(function() return guiService.TopbarInset end)
				if ok and typeof(bar) == 'Rect' and bar.Width > 40 then
					right, left = bar.Max.X - 4, bar.Min.X + 4
				end
				local list = {}
				for x = right - 32, view.X / 2, -40 do
					table.insert(list, Vector2.new(x, 4))
				end
				for x = left, view.X / 2 - 32, 40 do
					table.insert(list, Vector2.new(x, 4))
				end
				for y = inset + 8, view.Y / 2, 40 do
					table.insert(list, Vector2.new(view.X - 40, y))
				end
				for y = inset + 8, view.Y / 2, 40 do
					table.insert(list, Vector2.new(8, y))
				end
				return list
			end
			local current
			local function place()
				if dragged or current and not occupied(current.X, current.Y) then return end
				local list = spots()
				local pick = list[1]
				for _, spot in list do
					if not occupied(spot.X, spot.Y) then
						pick = spot
						break
					end
				end
				if pick and pick ~= current then
					current = pick
					button.Position = UDim2.fromOffset(pick.X, pick.Y)
				end
			end
			button.Position = UDim2.fromOffset(spots()[1].X, 4)
			mainapi:Clean(gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
				current = nil
				place()
			end))
			task.spawn(function()
				repeat
					pcall(place)
					task.wait(2)
				until not button.Parent
			end)
		end
		if mainapi.ButtonSpot then
			dragged = true
			button.Parent = gui
			button.Position = mainapi.ButtonSpot
			clampButton()
		end
		button.MouseButton1Click:Connect(function()
			if suppressClick then
				suppressClick = false
				return
			end
			if self.ThreadFix then
				setthreadidentity(8)
			end
			for _, v in self.Windows do
				v.Visible = false
			end
			for _, mobileButton in self.Modules do
				if mobileButton.Bind.Button then
					mobileButton.Bind.Button.Visible = clickgui.Visible
				end
			end
			clickgui.Visible = not clickgui.Visible
			tooltip.Visible = false
			self:BlurCheck()
		end)

		if guipane then
			guipane:CreateToggle({
				Name = 'Hide ElevateV4 button',
				Default = hide or false,
				Function = function(call)
					button.BackgroundTransparency = call and 1 or 0.35
					image.ImageTransparency = call and 1 or 0
					writefile('ElevateV4/profiles/hide.txt', tostring(call))
				end
			})
		end
	end
end

function mainapi:LoadOptions(object, savedoptions)
	for i, v in savedoptions do
		local option = object.Options[i]
		if not option then continue end
		pcall(option.Load, option, v)
	end
end

function mainapi:Remove(obj)
	local tab = (self.Modules[obj] and self.Modules
		or self.Legit and self.Legit.Modules and self.Legit.Modules[obj] and self.Legit.Modules
		or self.Kits and self.Kits.Modules and self.Kits.Modules[obj] and self.Kits.Modules
		or self.Categories)
	if tab and tab[obj] then
		local newobj = tab[obj]
		if self.ThreadFix then
			setthreadidentity(8)
		end

		if tab ~= self.Categories and newobj.Enabled == true and type(newobj.Toggle) == 'function' then
			pcall(newobj.Toggle, newobj, true)
		end

		for _, v in {'Object', 'Children', 'Toggle', 'Button'} do
			local childobj = typeof(newobj[v]) == 'table' and newobj[v].Object or newobj[v]
			if typeof(childobj) == 'Instance' then
				childobj:Destroy()
				childobj:ClearAllChildren()
			end
		end

		loopClean(newobj)
		tab[obj] = nil
	end
end

function mainapi:Save(newprofile)
	if not self.Loaded then return end
	local guidata = {
		Categories = {},
		Profile = newprofile or self.Profile,
		Profiles = self.Profiles,
		Keybind = self.Keybind
	}
	local savedata = {
		Modules = {},
		Categories = {},
		Legit = {},
		Kits = {}
	}

	savedata.Keybind = self.Keybind
	if self.GUIColor then
		savedata.GUIColor = {
			Hue = self.GUIColor.Hue,
			Sat = self.GUIColor.Sat,
			Value = self.GUIColor.Value,
			Notch = self.GUIColor.Notch,
			CustomColor = self.GUIColor.CustomColor,
			Rainbow = self.GUIColor.Rainbow
		}
	end

	local skipped = false
	local function record(target, key, build)
		local ok, entry = pcall(build)
		if ok then
			target[key] = entry
		else
			skipped = true
			warn('[ElevateV4] could not save '..tostring(key)..': '..tostring(entry))
		end
	end

	for i, v in self.Categories do
		record((v.Type ~= 'Category' and i ~= 'Main' and savedata or guidata).Categories, i, function()
			return {
				Enabled = i ~= 'Main' and v.Button and v.Button.Enabled or nil,
				Standalone = v.Standalone or nil,
				Expanded = v.Type ~= 'Overlay' and v.Expanded or nil,
				Pinned = v.Pinned,
				Position = {X = v.Object.Position.X.Offset, Y = v.Object.Position.Y.Offset},
				Options = mainapi:SaveOptions(v, v.Options),
				List = v.List,
				ListEnabled = v.ListEnabled
			}
		end)
	end

	for i, v in self.Modules do
		record(savedata.Modules, i, function()
			return {
				Enabled = v.Enabled,
				Hidden = v.Hidden or nil,
				Bind = v.Bind.Button and {Mobile = true, X = v.Bind.Button.Position.X.Offset, Y = v.Bind.Button.Position.Y.Offset} or v.Bind,
				Options = mainapi:SaveOptions(v, true)
			}
		end)
	end

	for i, v in self.Legit.Modules do
		record(savedata.Legit, i, function()
			return {
				Enabled = v.Enabled,
				Bind = v.Bind,
				Position = v.Children and {X = v.Children.Position.X.Offset, Y = v.Children.Position.Y.Offset} or nil,
				Options = mainapi:SaveOptions(v, v.Options)
			}
		end)
	end

	for i, v in self.Kits.Modules do
		record(savedata.Kits, i, function()
			return {
				Enabled = v.Enabled,
				Bind = v.Bind,
				Position = v.Children and {X = v.Children.Position.X.Offset, Y = v.Children.Position.Y.Offset} or nil,
				Options = mainapi:SaveOptions(v, v.Options)
			}
		end)
	end

	ensureDataFolders()
	local existingPath = getConfigPath(self.Profile)
	if isfile(existingPath) then
		local existing = loadJson(existingPath)
		if type(existing) == 'table' and type(existing.Modules) == 'table'
			and (skipped or getTableSize(self.Modules) < getTableSize(existing.Modules)) then
			for key, value in existing.Modules do
				if savedata.Modules[key] == nil then savedata.Modules[key] = value end
			end
			for panel, source in {Categories = existing.Categories, Legit = existing.Legit, Kits = existing.Kits} do
				if type(source) == 'table' then
					for key, value in source do
						if savedata[panel][key] == nil then savedata[panel][key] = value end
					end
				end
			end
		end
	end
	local encodedSave = httpService:JSONEncode(savedata)
	writeProfileFile('ElevateV4/profiles/'..game.GameId..'.gui.txt', httpService:JSONEncode(guidata))
	writeProfileFile(getConfigPath(self.Profile), encodedSave)
	writeProfileFile(getLegacyProfilePath(self.Profile), encodedSave)
end

function mainapi:SaveOptions(object, savedoptions)
	if not savedoptions then return end
	savedoptions = {}
	for _, v in object.Options do
		if not v.Save then continue end
		pcall(v.Save, v, savedoptions)
	end
	return savedoptions
end
mainapi.SaveDebounce = 1.5
mainapi.SaveDeadline = 8
function mainapi:ScheduleSave()
	if not self.Loaded then return end
	local now = os.clock()
	self.SaveDirty = true
	self.SaveRequestedAt = now
	self.SaveFirstDirtyAt = self.SaveFirstDirtyAt or now
	if self.SaveLoop then return end
	self.SaveLoop = task.spawn(function()
		repeat
			task.wait(0.25)
			if not self.SaveDirty then break end
			local current = os.clock()
			local settled = current - (self.SaveRequestedAt or current) >= mainapi.SaveDebounce
			local overdue = current - (self.SaveFirstDirtyAt or current) >= mainapi.SaveDeadline
			if settled or overdue then
				self.SaveDirty, self.SaveFirstDirtyAt, self.SaveFlushedAt = false, nil, current
				pcall(function()
					mainapi:Save()
				end)
			end
		until not self.SaveDirty
		self.SaveLoop = nil
	end)
end
function mainapi:FlushPendingSave()
	if not self.SaveDirty then return end
	self.SaveDirty, self.SaveFirstDirtyAt = false, nil
	mainapi:Save()
end
local claimedGlobals = {
	'vape',
	'vapeEvents',
	'store',
	'bedwars',
	'remotes',
	'getPlacedBlock',
	'getSpeed',
	'getHotbar',
	'hotbarSwitch',
	'switchItem',
	'RealLifeBedWars',
	'Backtrack',
	'FakeLag',
	'EntityAnalyser',
	'texturepack',
	'used_init',
	'_aeroTierReady',
	'getAeroTier',
	'IsLongJumping',
	'LongJumpFireballThrown',
	'ProjectileAuraFiringLock',
	'ItemOwner',
	'ElevateV4LoadingScreen',
	'ElevateV4SetLoadingStatus',
	'ElevateV4CloseLoadingScreen'
}
local claimedShared = {
	'vape',
	'vapereload',
	'VapeIndependent',
	'bindable',
	'gg',
	'ACMODVIEWENABLED',
	'RealLifeBedWars',
	'vapeserverhoplist',
	'vapeserverhopprevious',
	'vapesessioninfo',
	'MATCH_CONTROLLER_GETPLAYERPARTY_REVERT',
	'PERMISSION_CONTROLLER_HASANYPERMISSIONS_REVERT'
}
local function destroyOwnedScreens()
	local roots = {}
	if gethui then
		local ok, res = pcall(gethui)
		if ok and res then table.insert(roots, res) end
	end
	pcall(function()
		table.insert(roots, cloneref(game:GetService('CoreGui')))
	end)
	pcall(function()
		table.insert(roots, cloneref(game:GetService('Players')).LocalPlayer:FindFirstChildOfClass('PlayerGui'))
	end)
	for _, root in roots do
		if not root then continue end
		pcall(function()
			for _, child in root:GetChildren() do
				if child:IsA('ScreenGui') and (child:GetAttribute('ElevateV4') or child.Name == 'ElevateV4Loading') then
					child:Destroy()
				end
			end
		end)
	end
end

local function releaseGlobals()
	local genv = getgenv and getgenv() or nil
	for _, name in claimedGlobals do
		if genv then
			pcall(function()
				genv[name] = nil
			end)
		end
		pcall(function()
			_G[name] = nil
		end)
	end
	for _, name in claimedShared do
		pcall(function()
			shared[name] = nil
		end)
	end
	destroyOwnedScreens()
end

function mainapi:Uninject()
	mainapi:Save()
	mainapi.Loaded = nil
	if mainapi.Telemetry then pcall(mainapi.Telemetry.Stop, 'uninject') end
	if mainapi.Panel then pcall(mainapi.Panel.Stop) end
	if mobileBlur then mobileBlur:Destroy(); mobileBlur = nil end
	for _, v in self.Modules do
		if v.Enabled then
			v:Toggle()
		end
	end
	for _, panel in {self.Legit, self.Kits} do
		for _, v in panel.Modules do
			if v.Enabled then
				v:Toggle()
			end
		end
	end
	for _, v in self.Categories do
		if v.Type == 'Overlay' and v.Button.Enabled then
			v.Button:Toggle()
		end
	end
	for _, v in mainapi.Connections do
		pcall(function()
			v:Disconnect()
		end)
	end
	if mainapi.ThreadFix then
		setthreadidentity(8)
		clickgui.Visible = false
		mainapi:BlurCheck()
	end
	mainapi.gui:ClearAllChildren()
	mainapi.gui:Destroy()
	table.clear(mainapi.Libraries)
	loopClean(mainapi)
	shared.vape = nil
	shared.vapereload = nil
	shared.VapeIndependent = nil
	releaseGlobals()
end

gui = Instance.new('ScreenGui')
gui.Name = randomString()
gui:SetAttribute('ElevateV4', true)
gui.DisplayOrder = 9999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.IgnoreGuiInset = true
gui.OnTopOfCoreBlur = true
if false then
	gui.Parent = cloneref(game:GetService('CoreGui'))
else
	gui.Parent = cloneref(game:GetService('Players')).LocalPlayer.PlayerGui
	gui.ResetOnSpawn = false
end
mainapi.gui = gui
scaledgui = Instance.new('Frame')
scaledgui.Name = 'ScaledGui'
scaledgui.Size = UDim2.fromScale(1, 1)
scaledgui.BackgroundTransparency = 1
scaledgui.Parent = gui
clickgui = Instance.new('Frame')
clickgui.Name = 'ClickGui'
clickgui.Size = UDim2.fromScale(1, 1)
clickgui.BackgroundTransparency = 1
clickgui.Visible = false
clickgui.Parent = scaledgui
local scarcitybanner = Instance.new('TextLabel')
scarcitybanner.Size = UDim2.fromScale(1, 0.02)
scarcitybanner.Position = UDim2.fromScale(0, 0.97)
scarcitybanner.BackgroundTransparency = 1
scarcitybanner.Text = 'Thank you for choosing ElevateV4! Join https://discord.gg/aYu5c9v9zv or click the Discord button to join.'
scarcitybanner.TextScaled = true
scarcitybanner.TextColor3 = Color3.new(1, 1, 1)
scarcitybanner.TextStrokeTransparency = 0.5
scarcitybanner.FontFace = uipallet.Font
scarcitybanner.Parent = clickgui
local modal = Instance.new('TextButton')
modal.BackgroundTransparency = 1
modal.Modal = true
modal.Text = ''
modal.Parent = clickgui
local cursor = Instance.new('ImageLabel')
cursor.Size = UDim2.fromOffset(64, 64)
cursor.BackgroundTransparency = 1
cursor.Visible = false
cursor.Image = 'rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png'
cursor.Parent = gui
notifications = Instance.new('Folder')
notifications.Name = 'Notifications'
notifications.Parent = scaledgui

function mainapi:CreateChoice(settings)
	settings = settings or {}
	local width, height = tonumber(settings.Width) or 420, tonumber(settings.Height) or 186
	local window = Instance.new('Frame')
	window.Name = 'Choice'
	window.Size, window.Position = UDim2.fromOffset(width, height), UDim2.new(0.5, -width / 2, 0.5, -height / 2)
	window.BackgroundColor3, window.Visible, window.Parent = uipallet.Main, true, scaledgui
	window.ZIndex = 20
	addBlur(window); addCorner(window); addWindowStroke(window); makeDraggable(window)
	table.insert(mainapi.Windows, window)

	local title = Instance.new('TextLabel')
	title.Size, title.Position, title.BackgroundTransparency = UDim2.new(1, -56, 0, 24), UDim2.fromOffset(16, 12), 1
	title.Text, title.TextColor3, title.TextSize, title.FontFace = tostring(settings.Title or 'Choose'), uipallet.Text, 14, uipallet.FontSemiBold
	title.TextXAlignment, title.ZIndex, title.Parent = Enum.TextXAlignment.Left, 21, window

	local body = title:Clone()
	body.Size, body.Position = UDim2.new(1, -32, 0, height - 74), UDim2.fromOffset(16, 44)
	body.Text, body.TextSize, body.FontFace = tostring(settings.Message or ''), 12, uipallet.Font
	body.TextColor3, body.TextWrapped, body.TextYAlignment = color.Dark(uipallet.Text, 0.15), true, Enum.TextYAlignment.Top
	body.ZIndex, body.Parent = 21, window

	local entry = {Window = window}
	local function close()
		pcall(function()
			if settings.OnClose then settings.OnClose() end
		end)
		local index = table.find(mainapi.Windows, window)
		if index then table.remove(mainapi.Windows, index) end
		window:Destroy()
	end
	entry.Close = close

	local options = settings.Options or {}
	local count = math.max(#options, 1)
	local buttonWidth = math.floor((width - 32 - (12 * (count - 1))) / count)
	for index, option in options do
		local button = Instance.new('TextButton')
		button.Name = tostring(option.Label or index)
		button.Size, button.Position = UDim2.fromOffset(buttonWidth, 34), UDim2.fromOffset(16 + (index - 1) * (buttonWidth + 12), height - 50)
		button.BackgroundColor3 = option.Primary and color.Light(uipallet.Main, 0.14) or color.Light(uipallet.Main, 0.05)
		button.Text, button.TextColor3, button.TextSize, button.FontFace = tostring(option.Label or ''), uipallet.Text, 13, uipallet.FontSemiBold
		button.AutoButtonColor, button.BorderSizePixel, button.ZIndex, button.Parent = true, 0, 21, window
		addCorner(button)
		button.MouseButton1Click:Connect(function()
			close()
			if option.Function then task.spawn(option.Function) end
		end)
	end
	return entry
end
tooltip = Instance.new('TextLabel')
tooltip.Name = 'Tooltip'
tooltip.Position = UDim2.fromScale(-1, -1)
tooltip.ZIndex = 5
tooltip.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
tooltip.Visible = false
tooltip.Text = ''
tooltip.TextColor3 = color.Dark(uipallet.Text, 0.16)
tooltip.TextSize = 12
tooltip.FontFace = uipallet.Font
tooltip.Parent = scaledgui
toolblur = addBlur(tooltip)
addCorner(tooltip)
local toolstrokebkg = Instance.new('Frame')
toolstrokebkg.Size = UDim2.new(1, -2, 1, -2)
toolstrokebkg.Position = UDim2.fromOffset(1, 1)
toolstrokebkg.ZIndex = 6
toolstrokebkg.BackgroundTransparency = 1
toolstrokebkg.Parent = tooltip
local toolstroke = Instance.new('UIStroke')
toolstroke.Color = color.Light(uipallet.Main, 0.02)
toolstroke.Parent = toolstrokebkg
addCorner(toolstrokebkg, UDim.new(0, 4))
scale = Instance.new('UIScale')
scale.Scale = math.max(gui.AbsoluteSize.X / 1920, 0.6)
scale.Parent = scaledgui
mainapi.guiscale = scale
scaledgui.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)

mainapi:Clean(gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
	if mainapi.Scale.Enabled then
		scale.Scale = math.max(gui.AbsoluteSize.X / 1920, 0.6)
	end
end))

mainapi:Clean(scale:GetPropertyChangedSignal('Scale'):Connect(function()
	scaledgui.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)
	for _, v in scaledgui:GetDescendants() do
		if v:IsA('GuiObject') and v.Visible then
			v.Visible = false
			v.Visible = true
		end
	end
end))

mainapi:Clean(clickgui:GetPropertyChangedSignal('Visible'):Connect(function()
	mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value, true)
	if clickgui.Visible and inputService.MouseEnabled then
		repeat
			local visibleCheck = clickgui.Visible
			for _, v in mainapi.Windows do
				visibleCheck = visibleCheck or v.Visible
			end
			if not visibleCheck then break end

			cursor.Visible = not inputService.MouseIconEnabled
			if cursor.Visible then
				local mouseLocation = inputService:GetMouseLocation()
				cursor.Position = UDim2.fromOffset(mouseLocation.X - 31, mouseLocation.Y - 32)
			end

			task.wait()
		until mainapi.Loaded == nil
		cursor.Visible = false
	end
end))

mainapi:CreateGUI()
mainapi.Categories.Main:CreateDivider()
mainapi:CreateCategory({
	Name = 'Combat',
	Icon = getcustomasset('ElevateV4/assets/new/combaticon.png'),
	Size = UDim2.fromOffset(13, 14)
})
mainapi:CreateCategory({
	Name = 'Blatant',
	Icon = getcustomasset('ElevateV4/assets/new/blatanticon.png'),
	Size = UDim2.fromOffset(14, 14)
})
mainapi:CreateCategory({
	Name = 'Render',
	Icon = getcustomasset('ElevateV4/assets/new/rendericon.png'),
	Size = UDim2.fromOffset(15, 14)
})
mainapi:CreateCategory({
	Name = 'Utility',
	Icon = getcustomasset('ElevateV4/assets/new/utilityicon.png'),
	Size = UDim2.fromOffset(15, 14)
})
mainapi:CreateCategory({
	Name = 'World',
	Icon = getcustomasset('ElevateV4/assets/new/worldicon.png'),
	Size = UDim2.fromOffset(14, 14)
})
mainapi:CreateCategory({
	Name = 'Inventory',
	Icon = getcustomasset('ElevateV4/assets/new/inventoryicon.png'),
	Size = UDim2.fromOffset(15, 14)
})

mainapi:CreateCategory({
	Name = 'Minigames',
	Icon = getcustomasset('ElevateV4/assets/new/worldicon.png'),
	Size = UDim2.fromOffset(14, 14)
})

mainapi:CreateCategory({
	Name = 'Kits',
	Icon = getcustomasset('ElevateV4/assets/new/friendstab.png'),
	Size = UDim2.fromOffset(17, 16)
})


mainapi.Categories.Main:CreateDivider('misc')

local friends
local friendscolor = {
	Hue = 1,
	Sat = 1,
	Value = 1
}
local friendssettings = {
	Name = 'Friends',
	Icon = getcustomasset('ElevateV4/assets/new/friendstab.png'),
	Size = UDim2.fromOffset(17, 16),
	Placeholder = 'Roblox username',
	Color = Color3.fromRGB(190, 115, 255),
	Function = function()
		friends.Update:Fire()
		friends.ColorUpdate:Fire(friendscolor.Hue, friendscolor.Sat, friendscolor.Value)
	end
}
friends = mainapi:CreateCategoryList(friendssettings)
friends.Update = Instance.new('BindableEvent')
friends.ColorUpdate = Instance.new('BindableEvent')
friends:CreateToggle({
	Name = 'Recolor visuals',
	Darker = true,
	Default = true,
	Function = function()
		friends.Update:Fire()
		friends.ColorUpdate:Fire(friendscolor.Hue, friendscolor.Sat, friendscolor.Value)
	end
})
friendscolor = friends:CreateColorSlider({
	Name = 'Friends color',
	Darker = true,
	Function = function(hue, sat, val)
		for _, v in friends.Object.Children:GetChildren() do
			local dot = v:FindFirstChild('Dot')
			if dot and dot.BackgroundColor3 ~= color.Light(uipallet.Main, 0.37) then
				dot.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				dot.Dot.BackgroundColor3 = dot.BackgroundColor3
			end
		end
		friendssettings.Color = Color3.fromHSV(hue, sat, val)
		friends.ColorUpdate:Fire(hue, sat, val)
	end
})
friends:CreateToggle({
	Name = 'Use friends',
	Darker = true,
	Default = true,
	Function = function()
		friends.Update:Fire()
		friends.ColorUpdate:Fire(friendscolor.Hue, friendscolor.Sat, friendscolor.Value)
	end
})
mainapi:Clean(friends.Update)
mainapi:Clean(friends.ColorUpdate)

local reloadInProgress = false
local function reloadAether(forceBootstrap)
	if forceBootstrap == nil then forceBootstrap = true end
	if reloadInProgress then
		mainapi:CreateNotification('ElevateV4', 'A reinject is already in progress.', 4, 'warning')
		return
	end
	reloadInProgress = true
	task.spawn(function()
		shared.vapereload = true
		local ok, err = xpcall(function()
			local chunkName = forceBootstrap and 'init' or 'main'
			local source
			if shared.VapeDeveloper then
				source = readfile(forceBootstrap and 'ElevateV4/init.lua' or 'ElevateV4/main.lua')
			else
				source = game:HttpGet(forceBootstrap and remoteLoaderUrl() or remoteSourceUrl('ElevateV4/main.lua'), true)
			end
			local chunk, compileError = loadstring(source, chunkName)
			if not chunk then error('main.lua failed to compile: '..tostring(compileError), 0) end
			chunk(license)
		end, debug and debug.traceback or tostring)
		reloadInProgress = false
		if not ok then warn('[ElevateV4] reload failed:', err) end
	end)
end
mainapi.ReloadAether = reloadAether

local profiles = mainapi:CreateCategoryList({
	Name = 'Profiles',
	DisplayName = 'Configs',
	Icon = getcustomasset('ElevateV4/assets/new/profilesicon.png'),
	Size = UDim2.fromOffset(17, 10),
	Position = UDim2.fromOffset(12, 16),
	Placeholder = 'Type name',
	Profiles = true
})

local importNameBox
local importJsonBox = profiles:CreateTextBox({
	Name = 'Import JSON',
	Placeholder = 'Paste config JSON here',
	Tooltip = 'Paste config JSON, then click Import JSON to create a new config'
})
importNameBox = profiles:CreateTextBox({
	Name = 'Import Name',
	Placeholder = 'Optional config name',
	Tooltip = 'Optional name for the imported config. Invalid file characters are replaced automatically'
})
profiles:CreateButton({
	Name = 'Import JSON',
	Function = function()
		local text = importJsonBox.Value
		if (not text or text:gsub('%s+', '') == '') and getclipboard then
			local suc, clipboard = pcall(getclipboard)
			if suc then text = clipboard end
		end
		local suc, result = importJsonConfig(text, importNameBox.Value ~= '' and importNameBox.Value or nil)
		if suc then
			importJsonBox:SetValue('', false)
			importNameBox:SetValue('', false)
			profiles:ChangeValue()
			mainapi:CreateNotification('ElevateV4', 'Imported config '..result..'.', 5, 'info')
		else
			mainapi:CreateNotification('ElevateV4', result, 8, 'alert')
		end
	end,	Tooltip = 'Imports a JSON config from the text box, or from your clipboard if the text box is empty'
})
profiles:CreateButton({
	Name = 'Export JSON',
	Function = function()
		local profile = mainapi.Profile or 'default'
		mainapi:Save()
		local path = getConfigPath(profile)
		local raw = isfile(path) and select(2, pcall(readfile, path)) or nil
		local config = type(raw) == 'string' and decodeJsonText(raw) or nil
		if not config then
			mainapi:CreateNotification('ElevateV4', 'There is no saved config for '..profile..' to export.', 8, 'alert')
			return
		end
		local export = {name = profile, config = httpService:JSONEncode(config)}
		local guiPath = 'ElevateV4/profiles/'..game.GameId..'.gui.txt'
		local guiData = isfile(guiPath) and loadJson(guiPath) or nil
		if guiData then export.gui = httpService:JSONEncode(guiData) end
		local text = httpService:JSONEncode(export)
		local copied = setclipboard and pcall(setclipboard, text)
		if not copied then
			importJsonBox:SetValue(text, false)
			importNameBox:SetValue(profile, false)
			mainapi:CreateNotification('ElevateV4', 'No clipboard access, so '..profile..' was put in the import box instead.', 10, 'alert')
			return
		end
		mainapi:CreateNotification('ElevateV4', 'Exported '..profile..' to your clipboard.', 6, 'info')
	end,
	Tooltip = 'Copies the current config as JSON, ready to paste back into Import JSON or share'
})
profiles:CreateButton({
		Name = 'Reset current config',
	Function = function()
		configapi.ResetProfile()
		reloadAether()
	end,
	Tooltip = 'Clears the current config and reloads its defaults'
})

local targets
targets = mainapi:CreateCategoryList({
	Name = 'Targets',
	Icon = getcustomasset('ElevateV4/assets/new/friendstab.png'),
	Size = UDim2.fromOffset(17, 16),
	Placeholder = 'Roblox username',
	Function = function()
		targets.Update:Fire()
	end
})
targets.Update = Instance.new('BindableEvent')
mainapi:Clean(targets.Update)

;(function()
	local panelapi = shared.AetherPanel
	mainapi.Panel = type(panelapi) == 'table' and panelapi or nil
	if type(panelapi) ~= 'table' or not panelapi.IsOwner then return end

	local panel = mainapi:CreateCategory({
		Name = 'Panel',
		Icon = getcustomasset('ElevateV4/assets/new/targetinfoicon.png'),
		Size = UDim2.fromOffset(14, 14)
	})

	local rowsFrame = panel.Object and panel.Object:FindFirstChild('Children')
	if not rowsFrame then return end

	local players = cloneref(game:GetService('Players'))
	local selected = {}
	local rows = {}
	local render

	local function detectedList()
		local list = {}
		for _, entry in panelapi.Detected do
			if entry.Player and entry.Player.Parent == players then
				table.insert(list, entry)
			end
		end
		table.sort(list, function(a, b)
			return tostring(a.Name):lower() < tostring(b.Name):lower()
		end)
		return list
	end

	local holder = Instance.new('Frame')
	holder.Name = 'PanelTargets'
	holder.Size = UDim2.fromOffset(220, 0)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.BackgroundTransparency = 1
	holder.LayoutOrder = -1000
	holder.Parent = rowsFrame

	local holderLayout = Instance.new('UIListLayout')
	holderLayout.SortOrder = Enum.SortOrder.LayoutOrder
	holderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	holderLayout.Parent = holder

	local header = Instance.new('TextLabel')
	header.Name = 'Header'
	header.Size = UDim2.fromOffset(196, 26)
	header.Position = UDim2.fromOffset(12, 0)
	header.BackgroundTransparency = 1
	header.Text = 'ElevateV4 users in this server'
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextTruncate = Enum.TextTruncate.AtEnd
	header.TextColor3 = color.Dark(uipallet.Text, 0.3)
	header.TextSize = 11
	header.FontFace = uipallet.Font
	header.LayoutOrder = -2
	header.Parent = holder

	local empty = Instance.new('TextLabel')
	empty.Name = 'Empty'
	empty.Size = UDim2.fromOffset(196, 26)
	empty.Position = UDim2.fromOffset(12, 0)
	empty.BackgroundTransparency = 1
	empty.Text = 'Nobody else in this server runs ElevateV4'
	empty.TextXAlignment = Enum.TextXAlignment.Left
	empty.TextTruncate = Enum.TextTruncate.AtEnd
	empty.TextColor3 = color.Dark(uipallet.Text, 0.45)
	empty.TextSize = 12
	empty.FontFace = uipallet.Font
	empty.LayoutOrder = -1
	empty.Visible = false
	empty.Parent = holder

	local divider = Instance.new('Frame')
	divider.Name = 'Divider'
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.92
	divider.BorderSizePixel = 0
	divider.LayoutOrder = 100000
	divider.Parent = holder

	local function makeRow(entry, index)
		local chosen = selected[entry.UserId] == true
		local row = Instance.new('TextButton')
		row.Name = 'User' .. tostring(entry.UserId)
		row.Size = UDim2.fromOffset(220, 40)
		row.BackgroundColor3 = chosen and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or uipallet.Main
		row.AutoButtonColor = false
		row.BorderSizePixel = 0
		row.Text = ''
		row.LayoutOrder = index
		row.Parent = holder

		local avatar = Instance.new('ImageLabel')
		avatar.Name = 'Avatar'
		avatar.Size = UDim2.fromOffset(26, 26)
		avatar.Position = UDim2.fromOffset(9, 7)
		avatar.BackgroundColor3 = color.Light(uipallet.Main, 0.05)
		avatar.BackgroundTransparency = 0.15
		avatar.BorderSizePixel = 0
		avatar.Image = 'rbxthumb://type=AvatarHeadShot&id=' .. tostring(entry.UserId) .. '&w=150&h=150'
		avatar.Parent = row
		addCorner(avatar, UDim.new(0, 5))

		local name = Instance.new('TextLabel')
		name.Name = 'Username'
		name.Size = UDim2.fromOffset(136, 40)
		name.Position = UDim2.fromOffset(43, 0)
		name.BackgroundTransparency = 1
		name.Text = tostring(entry.Name)
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = chosen and mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or color.Dark(uipallet.Text, 0.16)
		name.TextSize = 13
		name.FontFace = uipallet.Font
		name.Parent = row

		local tick = Instance.new('Frame')
		tick.Name = 'Picked'
		tick.Size = UDim2.fromOffset(12, 12)
		tick.Position = UDim2.new(1, -25, 0.5, -6)
		tick.BackgroundColor3 = chosen and name.TextColor3 or uipallet.Main
		tick.BackgroundTransparency = chosen and 0 or 1
		tick.BorderSizePixel = 0
		tick.Parent = row
		addCorner(tick, UDim.new(0, 3))
		local stroke = Instance.new('UIStroke')
		stroke.Thickness = 1
		stroke.Color = chosen and name.TextColor3 or color.Dark(uipallet.Text, 0.5)
		stroke.Parent = tick

		addTooltip(row, 'Click to pick this user for the modules below')

		row.MouseEnter:Connect(function()
			if not selected[entry.UserId] then
				row.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
				name.TextColor3 = uipallet.Text
			end
		end)
		row.MouseLeave:Connect(function()
			if not selected[entry.UserId] then
				row.BackgroundColor3 = uipallet.Main
				name.TextColor3 = color.Dark(uipallet.Text, 0.16)
			end
		end)
		row.MouseButton1Click:Connect(function()
			selected[entry.UserId] = (not selected[entry.UserId]) or nil
			task.defer(render)
		end)
		return row
	end

	function render()
		for _, row in rows do
			pcall(function() row:Destroy() end)
		end
		table.clear(rows)
		local list = detectedList()
		local present = {}
		for _, entry in list do present[entry.UserId] = true end
		for userId in selected do
			if not present[userId] then selected[userId] = nil end
		end
		local picked = 0
		for _, entry in list do
			if selected[entry.UserId] then picked += 1 end
		end
		header.Text = 'ElevateV4 users in this server (' .. tostring(#list) .. ')'
		if picked > 0 then
			header.Text ..= ' - ' .. tostring(picked) .. ' picked'
		end
		empty.Visible = #list == 0
		for index, entry in list do
			rows[index] = makeRow(entry, index)
		end
	end

	local function selectedList()
		local list = {}
		for _, entry in detectedList() do
			if selected[entry.UserId] then
				table.insert(list, entry)
			end
		end
		return list
	end

	local function act(verb)
		if not panelapi.IsOwner then return end
		local targets = selectedList()
		if #targets == 0 then
			panelapi.Refresh()
			if #detectedList() == 0 then
				mainapi:CreateNotification('Panel', 'No other ElevateV4 users are in this server right now', 8, 'alert')
			else
				mainapi:CreateNotification('Panel', 'Pick the user this should act on in the list above', 8, 'alert')
			end
			return
		end
		local text
		if verb == 'reveal' then
			text = 'I am exploiting in ' .. panelapi.GameName() .. ' with ElevateV4'
		end
		local sent, failed, reason, names = 0, 0, nil, {}
		for _, entry in targets do
			local ok, err = panelapi.Send(entry.UserId, verb, text)
			if ok then
				sent += 1
				table.insert(names, tostring(entry.Name))
			else
				failed += 1
				reason = err
			end
		end
		if sent == 0 then
			mainapi:CreateNotification('Panel', tostring(reason or 'Nothing was sent'), 8, 'alert')
			return
		end
		local summary = verb:sub(1, 1):upper() .. verb:sub(2) .. ' sent to ' .. table.concat(names, ', ')
		if failed > 0 then summary ..= ' (' .. tostring(failed) .. ' failed)' end
		summary ..= ', takes effect within seconds'
		mainapi:CreateNotification('Panel', summary, 8, 'info')
	end

	local function action(name, verb, tooltip)
		local module
		module = panel:CreateModule({
			Name = name,
			Tooltip = tooltip,
			Function = function(enabled)
				if not enabled then return end
				pcall(act, verb)
				if module and module.Enabled then module:Toggle() end
			end
		})
		return module
	end

	action('Kick', 'kick', 'Leaves the game on the picked users with the owner message')
	action('Kill', 'kill', 'Kills the picked users through their own clients')
	action('Uninject', 'uninject', 'Unloads ElevateV4 inside the picked clients')
	action('Reveal', 'reveal', 'Has the picked clients admit to using ElevateV4 in this game')
	action('Unhittable', 'unhittable', 'Stops the picked clients from attacking anyone')

	render()
	local changed = panelapi.Changed
	if typeof(changed) == 'Instance' then
		mainapi:Clean(changed)
		mainapi:Clean(changed.Event:Connect(function() task.defer(render) end))
	end
	mainapi:Clean(players.PlayerRemoving:Connect(function() task.defer(render) end))
	mainapi:Clean(panel.Object:GetPropertyChangedSignal('Visible'):Connect(function()
		if panel.Object.Visible then panelapi.Refresh() end
	end))
	panelapi.Refresh()
end)()

mainapi:CreateLegit()
mainapi:CreateKits()
mainapi:CreateOnline()
mainapi:CreateChangelogs()
local visualsproxy
local function visualsCategory()
	visualsproxy = visualsproxy or setmetatable({
		CreateModule = function(_, modulesettings)
			modulesettings.Category = modulesettings.Category or 'Visuals'
			return mainapi.Legit:CreateModule(modulesettings)
		end
	}, {__index = mainapi.Legit})
	return visualsproxy
end
setmetatable(mainapi.Categories, {
	__index = function(_, key)
		if key == 'Legit' then
			return mainapi.Legit
		elseif key == 'Kits' then
			return mainapi.Kits
		elseif key == 'Visuals' then
			return visualsCategory()
		end
	end
})
mainapi:CreateSearch()
mainapi.Categories.Main:CreateOverlayBar()
mainapi.Categories.Main:CreateSettingsDivider()
mainapi:CreateWelcome()


local general = mainapi.Categories.Main:CreateSettingsPane({Name = 'General'})
mainapi.MultiKeybind = general:CreateToggle({
	Name = 'Enable Multi-Keybinding',
	Tooltip = 'Allows multiple keys to be bound to a module (eg. G + H)'
})
mainapi.AutoExecute = general:CreateToggle({
	Name = 'Auto-execute',
	Default = true,
	Function = function(enabled)
		shared.AetherAutoExecute = enabled and true or false
	end,
	Tooltip = 'Runs ElevateV4 automatically after teleporting to another server. Turn off to only run it yourself from your executor'
})
local downgradeEntries = {}
local versionPicker
versionPicker = general:CreateDropdown({
	Name = 'Previous version',
	List = {'Loading previous versions…'},
	Default = 'Loading previous versions…',
	Function = function(value, mouse)
		if not mouse then return end
		local entry = downgradeEntries[value]
		if not entry then return end
		writefile(versionPinPath, entry.Sha)
		mainapi:CreateNotification('ElevateV4', 'Pinned v'..entry.Version..' ('..entry.Sha:sub(1, 7)..'). Reinjecting…', 6, 'info')
		reloadAether(true)
	end,
	Tooltip = 'Select one of the ten most recent previous script versions'
})
general:CreateButton({
	Name = 'Use latest version',
	Function = function()
		if isfile(versionPinPath) then delfile(versionPinPath) end
		mainapi:CreateNotification('ElevateV4', 'Latest version selected. Reinjecting…', 6, 'info')
		reloadAether(true)
	end,
	Tooltip = 'Clears the previous-version pin and reloads the latest source'
})
function refreshVersionHistory(force)
	if not force and versionHistoryLoadedAt and (os.clock() - versionHistoryLoadedAt) < 300 then return end
	versionHistoryLoadedAt = os.clock()
	task.spawn(function()
		local ok, body = pcall(game.HttpGet, game, remoteHistoryUrl(11), true)
		local decoded
		if ok and type(body) == 'string' then
			local decodedOk, result = pcall(httpService.JSONDecode, httpService, body)
			if decodedOk then decoded = result end
		end
		local entries = type(decoded) == 'table' and (decoded.versions or decoded) or nil
		if type(entries) ~= 'table' then versionHistoryLoadedAt = nil end
		local list = {}
		table.clear(downgradeEntries)
		if type(entries) == 'table' then
			local current = isfile('ElevateV4/profiles/commit.txt') and readfile('ElevateV4/profiles/commit.txt'):gsub('%s+', '') or ''
			for _, entry in entries do
				local sha = type(entry) == 'table' and (entry.sha or entry.Sha or entry.id) or nil
				if type(sha) == 'string' and #sha >= 40 and sha ~= current then
					local version = type(entry) == 'table' and (entry.version or entry.Version) or nil
					if not version or version == '' or version == 'unavailable' then
						local versionOk, versionBody = pcall(game.HttpGet, game, remoteSourceUrl('ElevateV4/version.txt', sha), true)
						if versionOk and type(versionBody) == 'string' then
							version = versionBody:match('version%s*=%s*([^\r\n]+)')
						end
					end
					version = tostring(version or 'unavailable'):gsub('%s+$', '')
					local label = 'v'..version..' • '..sha:sub(1, 7)
					downgradeEntries[label] = {Sha = sha, Version = version}
					table.insert(list, label)
					if #list >= 10 then break end
				end
			end
		end
		if #list == 0 then
			list = {type(entries) == 'table' and 'No previous versions available' or 'Could not load previous versions'}
		end
		if versionPicker and versionPicker.Object and versionPicker.Object.Parent then
			versionPicker:Change(list)
		end
	end)
end
task.delay(6, refreshVersionHistory)

mainapi.MobileMode = general:CreateToggle({
	Name = 'Mobile Mode',
	Function = function(enabled)
		if mainapi.SetMobileMode then mainapi:SetMobileMode(enabled) else shared.AetherMobileMode = enabled end
	end,
	Tooltip = 'Keeps mobile quick-toggle controls and larger touch affordances enabled'
})
mainapi.DebugMode = general:CreateToggle({
	Name = 'Debug Mode',
	Function = function(enabled)
		if mainapi.SetDebugMode then mainapi:SetDebugMode(enabled) end
	end,
	Tooltip = 'Shows runtime capability, controller, connection, and performance information'
})
general:CreateButton({
	Name = 'Open diagnostics',
	Function = function() if mainapi.Diagnostics then mainapi.Diagnostics:Open() end end,
	Tooltip = 'Opens Aether runtime diagnostics'
})
general:CreateButton({
	Name = 'Error Logs',
	Function = function() if mainapi.ErrorLogWindow then mainapi.ErrorLogWindow:Open() end end,
	Tooltip = 'Shows recent errors raised by Aether modules'
})
general:CreateButton({
	Name = 'Update Center',
	Function = function() if mainapi.Changelogs then mainapi.Changelogs:Open() end end,
	Tooltip = 'Shows versions, release notes, and update controls'
})
general:CreateButton({
	Name = 'Self destruct',
	Function = function()
		mainapi:Uninject()
	end,
	Tooltip = 'Removes Aether from the current game'
})
general:CreateButton({
	Name = 'Reinject',
	Function = reloadAether,
	Tooltip = 'Reloads Aether for debugging purposes'
})
;(function()
	local telemetry = shared.AetherTelemetry
	mainapi.Telemetry = telemetry
	if type(telemetry) ~= 'table' then return end
	mainapi.UsageData = general:CreateToggle({
		Name = 'Send usage data',
		Default = telemetry.Enabled ~= false,
		Function = function(enabled)
			pcall(telemetry.SetEnabled, enabled)
		end,
		Tooltip = 'Sends your Roblox name, session times, version, game and errors to the ElevateV4 backend. Never your IP or files'
	})
	mainapi.UsageData.Save = nil
	mainapi.UsageData.Load = function() end
	local function linked(ok, info)
		if not ok then
			mainapi:CreateNotification('Account', tostring(info), 8, 'alert')
		elseif type(info) == 'table' and info.linked and type(info.user) == 'table' then
			mainapi:CreateNotification('Account', 'Linked to @'..tostring(info.user.username)..'.', 6, 'info')
		elseif type(info) == 'table' and info.linked == false and telemetry.GetLink() ~= '' then
			mainapi:CreateNotification('Account', 'That link code is not valid any more. Make a new one on the dashboard.', 8, 'alert')
		else
			mainapi:CreateNotification('Account', 'Not linked to a website account.', 5, 'info')
		end
	end
	local linkBox
	linkBox = general:CreateTextBox({
		Name = 'Link code',
		Placeholder = telemetry.GetLink() ~= '' and 'Linked (paste a new code to replace it)' or 'Paste a link code from the dashboard',
		Function = function(enter)
			if enter == nil then return end
			local code = tostring(linkBox.Value or ''):match('^%s*(.-)%s*$')
			if code == '' then return end
			linkBox:SetValue('')
			telemetry.SetLink(code, linked)
		end,
		Tooltip = 'Ties this game to your Discord account on the website, for Community Config likes and your own stats'
	})
	linkBox.Save = nil
	linkBox.Load = function() end
	general:CreateButton({
		Name = 'Check link',
		Function = function()
			telemetry.Me(linked)
		end,
		Tooltip = 'Shows which Discord account this game is linked to'
	})
	general:CreateButton({
		Name = 'Unlink account',
		Function = function()
			telemetry.SetLink('', function()
				mainapi:CreateNotification('Account', 'Unlinked. Remove the code on the dashboard too if you will not use it again.', 7, 'info')
			end)
		end,
		Tooltip = 'Forgets the link code on this device'
	})
end)()
local UPDATE_PLACE_ALIAS = {
	[6872265039] = 6872265039,
	[16008862571] = 6872265039,
	[6872274481] = 6872274481,
	[8444591321] = 6872274481,
	[8560631822] = 6872274481,
	[132768098780837] = 6872274481,
	[8768229691] = 8768229691,
	[8542275097] = 8768229691,
	[8592115909] = 8768229691,
	[8951451142] = 8768229691,
	[13246639586] = 8768229691,
	[8542259458] = 8768229691,
	[71480482338212] = 71480482338212,
	[71657866091528] = 71480482338212,
	[74441430126650] = 71480482338212,
	[72169370437173] = 72169370437173,
}
local UPDATE_BEDWARS_UNIVERSE = 2619619496

local function resolveUpdatePlace()
	local id = game.PlaceId
	if UPDATE_PLACE_ALIAS[id] then
		return UPDATE_PLACE_ALIAS[id]
	end
	if game.GameId == UPDATE_BEDWARS_UNIVERSE then
		if id == 6872265039 or id == 16008862571 then
			return 6872265039
		end
		return 6872274481
	end
	if game.GameId == 7534782259 then
		return 71480482338212
	end
	if game.GameId == 10768498581 then
		return 72169370437173
	end
	if game.GameId == 3258873704 then
		return 8768229691
	end
	return id
end

local updatingModules = false
local function updateGameModules()
	if updatingModules then
		mainapi:CreateNotification('ElevateV4', 'A module update is already in progress.', 4, 'warning')
		return
	end
	updatingModules = true
	task.spawn(function()
		local function finish(message, kind)
			updatingModules = false
			mainapi:CreateNotification('ElevateV4', message, 6, kind)
		end
		local ok, result, count = pcall(function()
			local previousVersion = ''
			if isfile('ElevateV4/profiles/version.txt') then
				local cachedBody = readfile('ElevateV4/profiles/version.txt')
				previousVersion = (cachedBody:match('version%s*=%s*([^\r\n]+)') or ''):gsub('%s+$', '')
			end
			local commitBody = game:HttpGet(remoteCommitUrl(sourceBranch()), true)
			local commit = commitBody:match('"sha"%s*:%s*"(%x+)"') or commitBody:match('"id"%s*:%s*"(%x+)"') or commitBody:match('^%s*(%x+)')
			if not commit or #commit < 40 then error('could not resolve the latest source commit') end
			commit = commit:sub(1, 40)

			local place = resolveUpdatePlace()
			local entries = {}
			local placePack = true
			for _, folder in ipairs({'universal', tostring(place)}) do
				local listOk, listBody = pcall(game.HttpGet, game, remoteSourceUrl('games/'..folder..'/files.txt', commit), true)
				local loweredList = tostring(listBody):sub(1, 300):lower()
				if not listOk or type(listBody) ~= 'string' or not validDownloadedFile('files.txt', listBody) or loweredList:find('404', 1, true) then
					if folder ~= 'universal' and not isfile('ElevateV4/games/'..folder..'/files.txt') then
						placePack = false
						break
					end
					error('no module list for '..folder)
				end
				ensureDownloadFolder('ElevateV4/games/'..folder..'/files.txt')
				writefile('ElevateV4/games/'..folder..'/files.txt', listBody)
				for line in tostring(listBody):gmatch('[^\r\n]+') do
					local name = line:gsub('^%s+', ''):gsub('%s+$', '')
					if name ~= '' and name:sub(1, 1) ~= '#' then
						table.insert(entries, {Folder = folder, Name = name})
					end
				end
			end
			if #entries == 0 then error('no modules listed for PlaceId '..tostring(place)) end

			local bodies = table.create(#entries)
			local done, cursor = 0, 0
			while cursor < #entries do
				cursor += 1
				local index = cursor
				local entry = entries[index]
				task.spawn(function()
					local downloadOk, body = pcall(game.HttpGet, game, remoteSourceUrl('games/'..entry.Folder..'/'..entry.Name, commit), true)
					if downloadOk then bodies[index] = body end
					done += 1
				end)
				if cursor % 24 == 0 then
					repeat task.wait() until done >= cursor or (cursor - done) < 24
				end
			end
			repeat task.wait() until done >= #entries

			local watermark = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'
			for index, entry in ipairs(entries) do
				local path = 'games/'..entry.Folder..'/'..entry.Name
				local body = bodies[index]
				local lowered = type(body) == 'string' and body:sub(1, 300):lower() or ''
				if type(body) ~= 'string' or not validDownloadedFile(path, body) or lowered:find('404', 1, true) then
					error(path..' failed to download')
				end
				local chunk, compileError = loadstring(body, '@ElevateV4/'..path)
				if not chunk then error(path..' failed validation: '..tostring(compileError)) end
				ensureDownloadFolder('ElevateV4/'..path)
				writefile('ElevateV4/'..path, watermark..body)
			end

			pcall(delfile, 'ElevateV4/games/universal/pack.lua')
			if placePack then pcall(delfile, 'ElevateV4/games/'..tostring(place)..'/pack.lua') end
			if isfile(versionPinPath) then delfile(versionPinPath) end
			writefile('ElevateV4/profiles/commit.txt', commit)

			local versionBody = game:HttpGet(remoteSourceUrl('version.txt', commit), true)
			local nextVersion = ''
			if type(versionBody) == 'string' and #versionBody > 3 and not versionBody:find('^404') then
				nextVersion = (versionBody:match('version%s*=%s*([^\r\n]+)') or ''):gsub('%s+$', '')
				writefile('ElevateV4/profiles/version.txt', versionBody:gsub('%s+$', ''))
			end
			if previousVersion ~= '' and nextVersion ~= '' and previousVersion ~= nextVersion then
				shared.updated = {From = previousVersion, To = nextVersion, Files = #entries}
			end
			return placePack and place or nil, #entries
		end)
		if ok and not result then
			finish('Updated '..tostring(count)..' universal modules. This place has no game pack. Reinject to load the latest source.', 'info')
		elseif ok then
			finish('Updated '..tostring(count)..' universal and PlaceId '..tostring(result)..' modules. Reinject to load the latest source.', 'info')
		else
			finish('Module update failed: '..tostring(result):gsub('^.-:%d+:%s*', ''), 'alert')
		end
	end)
end
mainapi.UpdateGameModules = updateGameModules
general:CreateButton({
	Name = 'Update Modules',
	Function = updateGameModules,
	Tooltip = 'Downloads fresh universal and current PlaceId modules from the latest source commit'
})


local modules = mainapi.Categories.Main:CreateSettingsPane({Name = 'Modules'})
local supportedGameFiles = {
	'142823291', '155615604', '606849621', '893973440', '5938036553', '6872265039',
	'6872274481', '8444591321', '8542259458', '8542275097', '8560631822', '8592115909',
	'8768229691', '8951451142', '11156779721', '13246639586', '71480482338212',
	'77790193039862', '80041634734121', '123804558118054', '131465939650733',
	'132768098780837', '135564683255158', '139566161526375'
}
local savedForcedGame = isfile('ElevateV4/profiles/forcegameid.txt') and readfile('ElevateV4/profiles/forcegameid.txt') or ''
local forcedGameFile = modules:CreateDropdown({
	Name = 'Game file',
	List = supportedGameFiles,
	Default = table.find(supportedGameFiles, savedForcedGame) and savedForcedGame or tostring(game.PlaceId),
	Function = function(value)
		writefile('ElevateV4/profiles/forcegameid.txt', tostring(value))
	end,
	Tooltip = 'Select one of the currently supported games/ files'
})
modules:CreateButton({
	Name = 'Force game file',
	Function = function()
		local selected = tostring(forcedGameFile.Value or ''):match('^%s*(%d+)%s*$')
		if not selected then
			mainapi:CreateNotification('ElevateV4', 'Pick a game file above first.', 6, 'alert')
			return
		end
		writefile('ElevateV4/profiles/forcegameid.txt', selected)
		writefile('ElevateV4/profiles/forcegame.txt', 'true')
		mainapi:CreateNotification('ElevateV4', 'Reinjecting with the '..selected..' game file...', 5, 'info')
		reloadAether()
	end,
	Tooltip = 'Reinjects now using the game file above'
})
modules:CreateToggle({
	Name = 'Teams by server',
	Tooltip = 'Ignore players on your team designated by the server',
	Default = true,
	Function = function()
		if mainapi.Libraries.entity and mainapi.Libraries.entity.Running then
			mainapi.Libraries.entity.refresh()
		end
	end
})
modules:CreateToggle({
	Name = 'Use team color',
	Tooltip = 'Uses the TeamColor property on players for render modules',
	Default = true,
	Function = function()
		if mainapi.Libraries.entity and mainapi.Libraries.entity.Running then
			mainapi.Libraries.entity.refresh()
		end
	end
})


guipane = mainapi.Categories.Main:CreateSettingsPane({Name = 'GUI'})
mainapi.Blur = guipane:CreateToggle({
	Name = 'Blur background',
	Function = function()
		mainapi:BlurCheck()
	end,
	Default = true,
	Tooltip = 'Blur the background of the GUI'
})
guipane:CreateToggle({
	Name = 'GUI bind indicator',
	Default = true,
	Tooltip = "Displays a message indicating your GUI upon injecting\nI.E. 'Press RSHIFT to open GUI'"
})
mainapi.NoModuleSpacing = guipane:CreateToggle({
	Name = 'No module spacing',
	Tooltip = 'Removes module\'s text spacing',
	Function = function(callback)
		for _, v in mainapi.Modules do
			if v.SetDisplayName then v:SetDisplayName(v.Name) end
		end
	end
})
guipane:CreateToggle({
	Name = 'Show tooltips',
	Function = function(enabled)
		tooltip.Visible = false
		toolblur.Visible = enabled
	end,
	Default = true,
	Tooltip = 'Toggles visibility of these'
})
guipane:CreateToggle({
	Name = 'Hide Vape Button',
	Default = isfile('ElevateV4/profiles/hide.txt') and readfile('ElevateV4/profiles/hide.txt') == 'true' or false,
	Function = function(enabled)
		if mainapi.VapeButton then mainapi.VapeButton.Visible = not enabled end
		writefile('ElevateV4/profiles/hide.txt', tostring(enabled))
	end,
	Tooltip = 'Hides only the launcher button that opens the GUI'
})
guipane:CreateToggle({
	Name = 'Show legit mode',
	Function = function(enabled)
		clickgui.Search.Legit.Visible = enabled
		if mainapi.UpdateSearchLayout then mainapi.UpdateSearchLayout() end
	end,
	Default = true,
	Tooltip = 'Shows the button to change to Legit Mode'
})
guipane:CreateToggle({
	Name = 'Show kits mode',
	Function = function(enabled)
		clickgui.Search.Kits.Visible = enabled
		if mainapi.UpdateSearchLayout then mainapi.UpdateSearchLayout() end
	end,
	Default = true,
	Tooltip = 'Shows the button that opens the Kits window'
})
local scaleslider = {Object = {}, Value = 1}
mainapi.Scale = guipane:CreateToggle({
	Name = 'Auto rescale',
	Default = true,
	Function = function(callback)
		scaleslider.Object.Visible = not callback
		if callback then
			scale.Scale = math.max(gui.AbsoluteSize.X / 1920, 0.45)
		else
			scale.Scale = scaleslider.Value
		end
	end,
	Tooltip = 'Automatically rescales the gui using the screens resolution'
})
scaleslider = guipane:CreateSlider({
	Name = 'Scale',
	Min = 0.1,
	Max = 2,
	Decimal = 10,
	Function = function(val, final)
		if final and not mainapi.Scale.Enabled then
			scale.Scale = val
		end
	end,
	Default = 1,
	Darker = true,
	Visible = false
})
guipane:CreateDropdown({
	Name = 'GUI Theme',
	List = inputService.TouchEnabled and {'new', 'old'} or {'new', 'old', 'rise'},
	Function = function(val, mouse)
		if mouse then
			pcall(function()
				mainapi:Save(mainapi.Profile)
			end)
			writefile('ElevateV4/profiles/gui.txt', val)
			reloadAether()
		end
	end,
	Tooltip = 'new - The current Aether theme\nold - The pre-v4.05 theme\nrise - Rise 6.0'
})
mainapi.ToggleMode = guipane:CreateDropdown({
	Name = 'Keybind mode',
	List = {'Toggle', 'Held'},
	Tooltip = 'Toggle - Keybind always activates when input starts or end\nHeld - Activates when input starts, Deactivate when input ends',
	Default = 'Toggle'
})
mainapi.RainbowMode = guipane:CreateDropdown({
	Name = 'Rainbow Mode',
	List = {'Normal', 'Gradient', 'Retro'},
	Tooltip = 'Normal - Smooth color fade\nGradient - Gradient color fade\nRetro - Static color'
})
mainapi.RainbowSpeed = guipane:CreateSlider({
	Name = 'Rainbow speed',
	Min = 0.1,
	Max = 10,
	Decimal = 10,
	Default = 1,
	Tooltip = 'Adjusts the speed of rainbow values'
})
mainapi.RainbowUpdateSpeed = guipane:CreateSlider({
	Name = 'Rainbow update rate',
	Min = 1,
	Max = 144,
	Default = 60,
	Tooltip = 'Adjusts the update rate of rainbow values',
	Suffix = 'hz'
})
guipane:CreateButton({
	Name = 'Reset GUI positions',
	Function = function()
		for _, v in mainapi.Categories do
			v.Object.Position = UDim2.fromOffset(6, 42)
		end
	end,
	Tooltip = 'This will reset your GUI back to default'
})
guipane:CreateButton({
	Name = 'Sort GUI',
	Function = function()
		local priority = {
			GUICategory = 1,
			CombatCategory = 2,
			BlatantCategory = 3,
			RenderCategory = 4,
			LegitCategory = 5,
			UtilityCategory = 6,
			WorldCategory = 7,
			InventoryCategory = 8,
			MinigamesCategory = 10,
			KitsCategory = 9,
			FriendsCategory = 10,
			ProfilesCategory = 11
		}
		local categories = {}
		for _, v in mainapi.Categories do
			if v.Type ~= 'Overlay' then
				table.insert(categories, v)
			end
		end
		table.sort(categories, function(a, b)
			return (priority[a.Object.Name] or 99) < (priority[b.Object.Name] or 99)
		end)

		local ind = 0
		for _, v in categories do
			if v.Object.Visible then
				v.Object.Position = UDim2.fromOffset(6 + (ind % 8 * 230), 60 + (ind > 7 and 360 or 0))
				ind += 1
			end
		end
	end,
	Tooltip = 'Sorts GUI'
})


local notifpane = mainapi.Categories.Main:CreateSettingsPane({Name = 'Notifications'})
mainapi.Notifications = notifpane:CreateToggle({
	Name = 'Notifications',
	Function = function(enabled)
		if mainapi.ToggleNotifications.Object then
			mainapi.ToggleNotifications.Object.Visible = enabled
		end
	end,
	Tooltip = 'Shows notifications',
	Default = true
})
mainapi.ToggleNotifications = notifpane:CreateToggle({
	Name = 'Toggle alert',
	Tooltip = 'Notifies you if a module is enabled/disabled',
	Default = true,
	Darker = true
})

mainapi.GUIColor = mainapi.Categories.Main:CreateGUISlider({
	Name = 'GUI Theme',
	Function = function(h, s, v)
		mainapi:UpdateGUI(h, s, v, true)
	end
})
mainapi.Categories.Main:CreateBind()




local textgui = mainapi:CreateOverlay({
	Name = 'Text GUI',
	Icon = getcustomasset('ElevateV4/assets/new/textguiicon.png'),
	Size = UDim2.fromOffset(16, 12),
	Position = UDim2.fromOffset(12, 14),
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
local VapeLabelSorter
local textguisort = textgui:CreateDropdown({
	Name = 'Sort',
	List = {'Alphabetical', 'Length'},
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
local textguifont = textgui:CreateFont({
	Name = 'Font',
	Blacklist = 'Arial',
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
local textguicolor
local textguicolordrop = textgui:CreateDropdown({
	Name = 'Color Mode',
	List = {'Match GUI color', 'Custom color'},
	Function = function(val)
		textguicolor.Object.Visible = val == 'Custom color'
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
textguicolor = textgui:CreateColorSlider({
	Name = 'Text GUI color',
	Function = function()
		mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	end,
	Darker = true,
	Visible = false
})
local VapeTextScale = Instance.new('UIScale')
VapeTextScale.Parent = textgui.Children
local textguiscale = textgui:CreateSlider({
	Name = 'Scale',
	Min = 0,
	Max = 2,
	Decimal = 10,
	Default = 1,
	Function = function(val)
		VapeTextScale.Scale = val
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
local textguisize = textgui:CreateSlider({
	Name = 'Text size',
	Min = 11,
	Max = 22,
	Default = 15,
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
local textguispacing = textgui:CreateSlider({
	Name = 'Row spacing',
	Min = 0,
	Max = 8,
	Default = 0,
	Suffix = 'px',
	Function = function(value)
		if VapeLabelSorter then VapeLabelSorter.Padding = UDim.new(0, value) end
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
local textguialignment = textgui:CreateDropdown({
	Name = 'Alignment',
	List = {'Auto', 'Left', 'Right'},
	Default = 'Auto',
	Tooltip = 'Auto aligns toward the closest screen edge',
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
local textguiextratext = textgui:CreateToggle({
	Name = 'Show module details',
	Default = true,
	Tooltip = 'Shows mode and status text supplied by modules',
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
local textguishadow = textgui:CreateToggle({
	Name = 'Shadow',
	Tooltip = 'Renders shadowed text',
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
local textguigradientv4
local textguigradient = textgui:CreateToggle({
	Name = 'Gradient',
	Tooltip = 'Renders a gradient',
	Function = function(callback)
		textguigradientv4.Object.Visible = callback
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
textguigradientv4 = textgui:CreateToggle({
	Name = 'V4 Gradient',
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end,
	Darker = true,
	Visible = false
})
local textguianimations = textgui:CreateToggle({
	Name = 'Animations',
	Tooltip = 'Use animations on text gui',
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
local textguiwatermark = textgui:CreateToggle({
	Name = 'Watermark',
	Tooltip = 'Renders a vape watermark',
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
local textguibackgroundtransparency = {
	Value = 0.5,
	Object = {Visible = {}}
}
local textguibackgroundtint = {Enabled = false}
local textguiaccentline = {Enabled = true, Object = {Visible = false}}
local textguibackground = textgui:CreateToggle({
	Name = 'Render background',
	Function = function(callback)
		textguibackgroundtransparency.Object.Visible = callback
		textguibackgroundtint.Object.Visible = callback
		textguiaccentline.Object.Visible = callback
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
textguibackgroundtransparency = textgui:CreateSlider({
	Name = 'Transparency',
	Min = 0,
	Max = 1,
	Default = 0.5,
	Decimal = 10,
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end,
	Darker = true,
	Visible = false
})
textguibackgroundtint = textgui:CreateToggle({
	Name = 'Tint',
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end,
	Darker = true,
	Visible = false
})
textguiaccentline = textgui:CreateToggle({
	Name = 'Accent line',
	Default = true,
	Tooltip = 'Shows the thin GUI-coloured edge beside each module',
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end,
	Darker = true,
	Visible = false
})
local textguimoduleslist
local textguimodules
mainapi.HiddenModules = {}
function mainapi:IsModuleHidden(name)
	return textguimodules.Enabled and (self.HiddenModules[name] == true or table.find(textguimoduleslist.ListEnabled or {}, name) ~= nil)
end
textguimodules = textgui:CreateToggle({
	Name = 'Hide modules',
	Tooltip = 'Allows you to blacklist certain modules from being shown',
	Function = function(enabled)
		textguimoduleslist.Object.Visible = enabled
		table.clear(mainapi.HiddenModules)
		for _, name in (textguimoduleslist.ListEnabled or {}) do
			mainapi.HiddenModules[name] = true
		end
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
textguimoduleslist = textgui:CreateTextList({
	Name = 'Blacklist',
	Tooltip = 'Name of module to hide',
	Icon = getcustomasset('ElevateV4/assets/new/blockedicon.png'),
	Tab = getcustomasset('ElevateV4/assets/new/blockedtab.png'),
	TabSize = UDim2.fromOffset(21, 16),
	Color = Color3.fromRGB(250, 50, 56),
	Function = function()
		table.clear(mainapi.HiddenModules)
		for _, name in (textguimoduleslist.ListEnabled or {}) do
			mainapi.HiddenModules[name] = true
		end
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end,
	Visible = false,
	Darker = true
})
local textguirender = textgui:CreateToggle({
	Name = 'Hide render',
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
local textguibox
local textguifontcustom
local textguicolorcustomtoggle
local textguicolorcustom
local textguitext = textgui:CreateToggle({
	Name = 'Add custom text',
	Function = function(enabled)
		textguibox.Object.Visible = enabled
		textguifontcustom.Object.Visible = enabled
		textguicolorcustomtoggle.Object.Visible = enabled
		textguicolorcustom.Object.Visible = textguicolorcustomtoggle.Enabled and enabled
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
})
textguibox = textgui:CreateTextBox({
	Name = 'Custom text',
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end,
	Darker = true,
	Visible = false
})
textguifontcustom = textgui:CreateFont({
	Name = 'Custom Font',
	Blacklist = 'Arial',
	Function = function()
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end,
	Darker = true,
	Visible = false
})
textguicolorcustomtoggle = textgui:CreateToggle({
	Name = 'Set custom text color',
	Function = function(enabled)
		textguicolorcustom.Object.Visible = enabled
		mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	end,
	Darker = true,
	Visible = false
})
textguicolorcustom = textgui:CreateColorSlider({
	Name = 'Color of custom text',
	Function = function()
		mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	end,
	Darker = true,
	Visible = false
})


local VapeLabels = {}
local VapeLogo = Instance.new('ImageLabel')
VapeLogo.Name = 'Logo'
VapeLogo.Size = UDim2.fromOffset(80, 21)
VapeLogo.Position = UDim2.new(1, -142, 0, 3)
VapeLogo.BackgroundTransparency = 1
VapeLogo.BorderSizePixel = 0
VapeLogo.Visible = false
VapeLogo.BackgroundColor3 = Color3.new()
VapeLogo.Image = getcustomasset('ElevateV4/assets/new/guivape.png')
VapeLogo.Parent = textgui.Children

local lastside = textgui.Children.AbsolutePosition.X > (gui.AbsoluteSize.X / 2)
mainapi:Clean(textgui.Children:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
	if mainapi.ThreadFix then
		setthreadidentity(8)
	end
	local newside = textgui.Children.AbsolutePosition.X > (gui.AbsoluteSize.X / 2)
	if lastside ~= newside then
		lastside = newside
		if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
	end
end))

local VapeLogoV4 = Instance.new('ImageLabel')
VapeLogoV4.Name = 'Logo2'
VapeLogoV4.Size = UDim2.fromOffset(33, 18)
VapeLogoV4.Position = UDim2.new(1, 1, 0, 1)
VapeLogoV4.BackgroundColor3 = Color3.new()
VapeLogoV4.BackgroundTransparency = 1
VapeLogoV4.BorderSizePixel = 0
VapeLogoV4.Image = getcustomasset('ElevateV4/assets/new/guiv4.png')
VapeLogoV4.Parent = VapeLogo
local VapeLogoShadow = VapeLogo:Clone()
VapeLogoShadow.Position = UDim2.fromOffset(1, 1)
VapeLogoShadow.ZIndex = 0
VapeLogoShadow.Visible = true
VapeLogoShadow.ImageColor3 = Color3.new()
VapeLogoShadow.ImageTransparency = 0.65
VapeLogoShadow.Parent = VapeLogo
VapeLogoShadow.Logo2.ZIndex = 0
VapeLogoShadow.Logo2.ImageColor3 = Color3.new()
VapeLogoShadow.Logo2.ImageTransparency = 0.65
local VapeLogoGradient = Instance.new('UIGradient')
VapeLogoGradient.Rotation = 90
VapeLogoGradient.Parent = VapeLogo
local VapeLogoGradient2 = Instance.new('UIGradient')
VapeLogoGradient2.Rotation = 90
VapeLogoGradient2.Parent = VapeLogoV4
local VapeLabelCustom = Instance.new('TextLabel')
VapeLabelCustom.Position = UDim2.fromOffset(5, 2)
VapeLabelCustom.BackgroundTransparency = 1
VapeLabelCustom.BorderSizePixel = 0
VapeLabelCustom.Visible = false
VapeLabelCustom.Text = ''
VapeLabelCustom.TextSize = 25
VapeLabelCustom.FontFace = textguifontcustom.Value
VapeLabelCustom.RichText = true
local VapeLabelCustomShadow = VapeLabelCustom:Clone()
VapeLabelCustom:GetPropertyChangedSignal('Position'):Connect(function()
	VapeLabelCustomShadow.Position = UDim2.new(
		VapeLabelCustom.Position.X.Scale,
		VapeLabelCustom.Position.X.Offset + 1,
		0,
		VapeLabelCustom.Position.Y.Offset + 1
	)
end)
VapeLabelCustom:GetPropertyChangedSignal('FontFace'):Connect(function()
	VapeLabelCustomShadow.FontFace = VapeLabelCustom.FontFace
end)
VapeLabelCustom:GetPropertyChangedSignal('Text'):Connect(function()
	VapeLabelCustomShadow.Text = removeTags(VapeLabelCustom.Text)
end)
VapeLabelCustom:GetPropertyChangedSignal('Size'):Connect(function()
	VapeLabelCustomShadow.Size = VapeLabelCustom.Size
end)
VapeLabelCustomShadow.TextColor3 = Color3.new()
VapeLabelCustomShadow.TextTransparency = 0.65
VapeLabelCustomShadow.Parent = textgui.Children
VapeLabelCustom.Parent = textgui.Children
local VapeLabelHolder = Instance.new('Frame')
VapeLabelHolder.Name = 'Holder'
VapeLabelHolder.Size = UDim2.fromScale(1, 1)
VapeLabelHolder.Position = UDim2.fromOffset(5, 37)
VapeLabelHolder.BackgroundTransparency = 1
VapeLabelHolder.Parent = textgui.Children
VapeLabelSorter = Instance.new('UIListLayout')
VapeLabelSorter.HorizontalAlignment = Enum.HorizontalAlignment.Right
VapeLabelSorter.VerticalAlignment = Enum.VerticalAlignment.Top
VapeLabelSorter.SortOrder = Enum.SortOrder.LayoutOrder
VapeLabelSorter.Parent = VapeLabelHolder


local targetinfo
local targetinfoobj
local targetinfobcolor
targetinfoobj = mainapi:CreateOverlay({
	Name = 'Target Info',
	Icon = getcustomasset('ElevateV4/assets/new/targetinfoicon.png'),
	Size = UDim2.fromOffset(14, 14),
	Position = UDim2.fromOffset(12, 14),
	CategorySize = 240,
	Function = function(callback)
		if callback then
			task.spawn(function()
				repeat
					targetinfo:UpdateInfo()
					task.wait()
				until not targetinfoobj.Button or not targetinfoobj.Button.Enabled
			end)
		end
	end
})

local targetinfobkg = Instance.new('Frame')
targetinfobkg.Size = UDim2.fromOffset(240, 89)
targetinfobkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.1)
targetinfobkg.BackgroundTransparency = 0.5
targetinfobkg.Parent = targetinfoobj.Children
local targetinfoblurobj = addBlur(targetinfobkg)
targetinfoblurobj.Visible = false
addCorner(targetinfobkg)
local targetinfoshot = Instance.new('ImageLabel')
targetinfoshot.Size = UDim2.fromOffset(26, 27)
targetinfoshot.Position = UDim2.fromOffset(19, 17)
targetinfoshot.BackgroundColor3 = uipallet.Main
targetinfoshot.Image = 'rbxthumb://type=AvatarHeadShot&id=1&w=420&h=420'
targetinfoshot.Parent = targetinfobkg
local targetinfoshotflash = Instance.new('Frame')
targetinfoshotflash.Size = UDim2.fromScale(1, 1)
targetinfoshotflash.BackgroundTransparency = 1
targetinfoshotflash.BackgroundColor3 = Color3.new(1, 0, 0)
targetinfoshotflash.Parent = targetinfoshot
addCorner(targetinfoshotflash)
local targetinfoshotblur = addBlur(targetinfoshot)
targetinfoshotblur.Visible = false
addCorner(targetinfoshot)
local targetinfoname = Instance.new('TextLabel')
targetinfoname.Size = UDim2.fromOffset(145, 20)
targetinfoname.Position = UDim2.fromOffset(54, 20)
targetinfoname.BackgroundTransparency = 1
targetinfoname.Text = 'Target name'
targetinfoname.TextXAlignment = Enum.TextXAlignment.Left
targetinfoname.TextYAlignment = Enum.TextYAlignment.Top
targetinfoname.TextScaled = true
targetinfoname.TextColor3 = color.Light(uipallet.Text, 0.4)
targetinfoname.TextStrokeTransparency = 1
targetinfoname.FontFace = uipallet.Font
local targetinfoshadow = targetinfoname:Clone()
targetinfoshadow.Position = UDim2.fromOffset(55, 21)
targetinfoshadow.TextColor3 = Color3.new()
targetinfoshadow.TextTransparency = 0.65
targetinfoshadow.Visible = false
targetinfoshadow.Parent = targetinfobkg
targetinfoname:GetPropertyChangedSignal('Size'):Connect(function()
	targetinfoshadow.Size = targetinfoname.Size
end)
targetinfoname:GetPropertyChangedSignal('Text'):Connect(function()
	targetinfoshadow.Text = targetinfoname.Text
end)
targetinfoname:GetPropertyChangedSignal('FontFace'):Connect(function()
	targetinfoshadow.FontFace = targetinfoname.FontFace
end)
targetinfoname.Parent = targetinfobkg
local targetinfohealthbkg = Instance.new('Frame')
targetinfohealthbkg.Name = 'HealthBKG'
targetinfohealthbkg.Size = UDim2.fromOffset(200, 9)
targetinfohealthbkg.Position = UDim2.fromOffset(20, 56)
targetinfohealthbkg.BackgroundColor3 = uipallet.Main
targetinfohealthbkg.BorderSizePixel = 0
targetinfohealthbkg.Parent = targetinfobkg
addCorner(targetinfohealthbkg, UDim.new(1, 0))
local targetinfohealth = targetinfohealthbkg:Clone()
targetinfohealth.Size = UDim2.fromScale(0.8, 1)
targetinfohealth.Position = UDim2.new()
targetinfohealth.BackgroundColor3 = Color3.fromHSV(1 / 2.5, 0.89, 0.75)
targetinfohealth.Parent = targetinfohealthbkg
targetinfohealth:GetPropertyChangedSignal('Size'):Connect(function()
	targetinfohealth.Visible = targetinfohealth.Size.X.Scale > 0.01
end)
local targetinfohealthextra = targetinfohealth:Clone()
targetinfohealthextra.Size = UDim2.new()
targetinfohealthextra.Position = UDim2.fromScale(1, 0)
targetinfohealthextra.AnchorPoint = Vector2.new(1, 0)
targetinfohealthextra.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
targetinfohealthextra.Visible = false
targetinfohealthextra.Parent = targetinfohealthbkg
targetinfohealthextra:GetPropertyChangedSignal('Size'):Connect(function()
	targetinfohealthextra.Visible = targetinfohealthextra.Size.X.Scale > 0.01
end)
local targetinfohealthblur = addBlur(targetinfohealthbkg)
targetinfohealthblur.SliceCenter = Rect.new(52, 31, 261, 510)
targetinfohealthblur.ImageColor3 = Color3.new()
targetinfohealthblur.Visible = false
local targetinfob = Instance.new('UIStroke')
targetinfob.Enabled = false
targetinfob.Color = Color3.fromHSV(0.44, 1, 1)
targetinfob.Parent = targetinfobkg

targetinfoobj:CreateFont({
	Name = 'Font',
	Blacklist = 'Arial',
	Function = function(val)
		targetinfoname.FontFace = val
	end
})
local targetinfobackgroundtransparency = {
	Value = 0.5,
	Object = {Visible = {}}
}
local targetinfodisplay = targetinfoobj:CreateToggle({
	Name = 'Use Displayname',
	Default = true
})
targetinfoobj:CreateToggle({
	Name = 'Render Background',
	Function = function(callback)
		targetinfobkg.BackgroundTransparency = callback and targetinfobackgroundtransparency.Value or 1
		targetinfoshadow.Visible = not callback
		targetinfoblurobj.Visible = callback
		targetinfohealthblur.Visible = not callback
		targetinfoshotblur.Visible = not callback
		targetinfobackgroundtransparency.Object.Visible = callback
	end,
	Default = true
})
targetinfobackgroundtransparency = targetinfoobj:CreateSlider({
	Name = 'Transparency',
	Min = 0,
	Max = 1,
	Default = 0.5,
	Decimal = 10,
	Function = function(val)
		targetinfobkg.BackgroundTransparency = val
	end,
	Darker = true
})
local targetinfocolor
local targetinfocolortoggle = targetinfoobj:CreateToggle({
	Name = 'Custom Color',
	Function = function(callback)
		targetinfocolor.Object.Visible = callback
		if callback then
			targetinfobkg.BackgroundColor3 = Color3.fromHSV(targetinfocolor.Hue, targetinfocolor.Sat, targetinfocolor.Value)
			targetinfoshot.BackgroundColor3 = Color3.fromHSV(targetinfocolor.Hue, targetinfocolor.Sat, math.max(targetinfocolor.Value - 0.1, 0.075))
			targetinfohealthbkg.BackgroundColor3 = targetinfoshot.BackgroundColor3
		else
			targetinfobkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.1)
			targetinfoshot.BackgroundColor3 = uipallet.Main
			targetinfohealthbkg.BackgroundColor3 = uipallet.Main
		end
	end
})
targetinfocolor = targetinfoobj:CreateColorSlider({
	Name = 'Color',
	Function = function(hue, sat, val)
		if targetinfocolortoggle.Enabled then
			targetinfobkg.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			targetinfoshot.BackgroundColor3 = Color3.fromHSV(hue, sat, math.max(val - 0.1, 0))
			targetinfohealthbkg.BackgroundColor3 = targetinfoshot.BackgroundColor3
		end
	end,
	Darker = true,
	Visible = false
})
targetinfoobj:CreateToggle({
	Name = 'Border',
	Function = function(callback)
		targetinfob.Enabled = callback
		targetinfobcolor.Object.Visible = callback
	end
})
targetinfobcolor = targetinfoobj:CreateColorSlider({
	Name = 'Border Color',
	Function = function(hue, sat, val, opacity)
		targetinfob.Color = Color3.fromHSV(hue, sat, val)
		targetinfob.Transparency = 1 - opacity
	end,
	Darker = true,
	Visible = false
})

local targetinfofollow = targetinfoobj:CreateToggle({
	Name = 'Follow player',
	Tooltip = 'Moves the HUD beside the entity currently being attacked while keeping both players visible',
	Function = function(callback)
		if not callback then
			targetinfobkg.Position = UDim2.new()
		end
	end
})
local targetinfoelements = targetinfoobj:CreateTargets({
	Players = true,
	NPCs = true
})

local followCenter, followTarget, followSide
local function updateTargetInfoPosition(target)
	if not targetinfofollow.Enabled or not target or not target.RootPart then
		followCenter, followTarget, followSide = nil, nil, nil
		if targetinfofollow.Enabled then targetinfobkg.Position = UDim2.new() end
		return true
	end

	local camera = workspace.CurrentCamera
	if not camera then return false end
	local targetPoint, visible = camera:WorldToViewportPoint(target.RootPart.Position + Vector3.new(0, 2.5, 0))
	if not visible or targetPoint.Z <= 0 then
		targetinfobkg.Position = UDim2.new()
		return true
	end

	local viewport = camera.ViewportSize
	local margin, half = 18, Vector2.new(120, 44.5)
	if viewport.X < (half.X + margin) * 2 or viewport.Y < (half.Y + margin) * 2 then return false end

	local localPoint = Vector2.new(viewport.X / 2, viewport.Y * 0.72)
	local entitylib = mainapi.Libraries and mainapi.Libraries.entity
	if entitylib and entitylib.character and entitylib.character.RootPart then
		local projected, onScreen = camera:WorldToViewportPoint(entitylib.character.RootPart.Position + Vector3.new(0, 2.5, 0))
		if onScreen and projected.Z > 0 then localPoint = Vector2.new(projected.X, projected.Y) end
	end

	local target2d = Vector2.new(targetPoint.X, targetPoint.Y)
	local offsets = {
		Vector2.new(half.X + 42, 0), Vector2.new(-half.X - 42, 0),
		Vector2.new(0, half.Y + 58), Vector2.new(0, -half.Y - 58),
		Vector2.new(half.X + 42, half.Y + 58), Vector2.new(half.X + 42, -half.Y - 58),
		Vector2.new(-half.X - 42, half.Y + 58), Vector2.new(-half.X - 42, -half.Y - 58)
	}
	local function covers(center, point)
		return math.abs(center.X - point.X) <= half.X + margin and math.abs(center.Y - point.Y) <= half.Y + margin
	end
	local best, bestScore, bestSide
	for side, offset in offsets do
		local desired = target2d + offset
		local center = Vector2.new(
			math.clamp(desired.X, half.X + margin, viewport.X - half.X - margin),
			math.clamp(desired.Y, half.Y + margin, viewport.Y - half.Y - margin)
		)
		if not covers(center, target2d) and not covers(center, localPoint) then
			local score = math.min((center - target2d).Magnitude, (center - localPoint).Magnitude) - ((center - desired).Magnitude * 2)
			if not bestScore or score > bestScore then best, bestScore, bestSide = center, score, side end
		end
	end
	if not best then return false end

	if followTarget == target and followSide then
		local desired = target2d + offsets[followSide]
		local held = Vector2.new(math.clamp(desired.X, half.X + margin, viewport.X - half.X - margin), math.clamp(desired.Y, half.Y + margin, viewport.Y - half.Y - margin))
		if not covers(held, target2d) and not covers(held, localPoint) then best, bestSide = held, followSide end
	end
	if followTarget ~= target then followCenter = best end
	followTarget, followSide = target, bestSide
	followCenter = followCenter and followCenter:Lerp(best, 0.04) or best
	best = followCenter

	local parentPosition = targetinfoobj.Children.AbsolutePosition
	local guiScale = scale and scale.Scale or 1
	targetinfobkg.Position = UDim2.fromOffset(
		(best.X - half.X - parentPosition.X) / guiScale,
		(best.Y - half.Y - parentPosition.Y) / guiScale
	)
	return true
end

local lasthealth = 0
local lastmaxhealth = 0
local targetChangedHandlers = {}
targetinfo = {
	Targets = {},
	Focus = {},
	Object = targetinfobkg,
	TargetChanged = {
		Connect = function(_, callback)
			table.insert(targetChangedHandlers, callback)
			return {
				Disconnect = function()
					local index = table.find(targetChangedHandlers, callback)
					if index then table.remove(targetChangedHandlers, index) end
				end
			}
		end,
		Fire = function(_, ...)
			for _, callback in table.clone(targetChangedHandlers) do
				task.spawn(callback, ...)
			end
		end
	},
	UpdateInfo = function(self)
		local entitylib = mainapi.Libraries
		if not entitylib then return end

		local now = tick()
		for i, v in self.Targets do
			if v < now then
				self.Targets[i] = nil
			end
		end
		for i, v in self.Focus do
			if v < now then
				self.Focus[i] = nil
			end
		end

		local v, highest = nil, now
		for i, check in self.Focus do
			local allowed = i.Player and targetinfoelements.Players.Enabled or targetinfoelements.NPCs.Enabled
			if allowed and check > highest then
				v = i
				highest = check
			end
		end
		local last = self.LastTarget
		if not v and last and (self.Targets[last] or 0) > now and (last.Player and targetinfoelements.Players.Enabled or targetinfoelements.NPCs.Enabled) then
			v = last
		end
		if not v then
			for i, check in self.Targets do
				local allowed = i.Player and targetinfoelements.Players.Enabled or targetinfoelements.NPCs.Enabled
				if allowed and check > highest then
					v = i
					highest = check
				end
			end
		end

		local shouldDisplay = v ~= nil or mainapi.gui.ScaledGui.ClickGui.Visible
		local visible = shouldDisplay and updateTargetInfoPosition(v) or false
		if self.ShownVisible ~= visible then
			self.ShownVisible = visible
			targetinfobkg.Visible = visible
		end
		if v then
			local name = v.Player and (targetinfodisplay.Enabled and v.Player.DisplayName or v.Player.Name) or v.Character and v.Character.Name or self.ShownName
			if name and self.ShownName ~= name then
				self.ShownName = name
				targetinfoname.Text = name
			end
			local userId = v.Player and v.Player.UserId or 1
			if self.ShownShot ~= userId then
				self.ShownShot = userId
				targetinfoshot.Image = 'rbxthumb://type=AvatarHeadShot&id='..userId..'&w=420&h=420'
			end

			if not v.Character then
				v.Health = v.Health or 0
				v.MaxHealth = v.MaxHealth or 100
			end

			if v.Health ~= lasthealth or v.MaxHealth ~= lastmaxhealth then
				local percent = math.max(v.Health / v.MaxHealth, 0)
				tween:Tween(targetinfohealth, TweenInfo.new(0.3), {
					Size = UDim2.fromScale(math.min(percent, 1), 1), BackgroundColor3 = Color3.fromHSV(math.clamp(percent / 2.5, 0, 1), 0.89, 0.75)
				})
				tween:Tween(targetinfohealthextra, TweenInfo.new(0.3), {
					Size = UDim2.fromScale(math.clamp(percent - 1, 0, 0.8), 1)
				})
				if lasthealth > v.Health and self.LastTarget == v then
					tween:Cancel(targetinfoshotflash)
					targetinfoshotflash.BackgroundTransparency = 0.3
					tween:Tween(targetinfoshotflash, TweenInfo.new(0.5), {
						BackgroundTransparency = 1
					})
				end
				lasthealth = v.Health
				lastmaxhealth = v.MaxHealth
			end

			if not v.Character then table.clear(v) end
			if self.LastTarget ~= v then
				self.TargetChanged:Fire(v)
			end
			self.LastTarget = v
		end
		return v
	end
}
mainapi.Libraries.targetinfo = targetinfo
task.spawn(function()
	repeat
		task.wait(5)
		if not (targetinfoobj.Button and targetinfoobj.Button.Enabled) then
			local now = tick()
			for i, v in targetinfo.Targets do
				if v < now then
					targetinfo.Targets[i] = nil
				end
			end
			for i, v in targetinfo.Focus do
				if v < now then
					targetinfo.Focus[i] = nil
				end
			end
		end
	until mainapi.Loaded == nil
end)

function mainapi:UpdateTextGUI(afterload)
	if not afterload and not mainapi.Loaded then return end
	if textgui.Button.Enabled then
		local right = textguialignment.Value == 'Right' or (textguialignment.Value == 'Auto' and textgui.Children.AbsolutePosition.X > (gui.AbsoluteSize.X / 2))
		VapeLabelSorter.Padding = UDim.new(0, textguispacing.Value)
		VapeLogo.Visible = textguiwatermark.Enabled
		VapeLogo.Position = right and UDim2.new(1 / VapeTextScale.Scale, -113, 0, 6) or UDim2.fromOffset(0, 6)
		VapeLogoShadow.Visible = textguishadow.Enabled
		VapeLabelCustom.Text = textguibox.Value
		VapeLabelCustom.FontFace = textguifontcustom.Value
		VapeLabelCustom.Visible = VapeLabelCustom.Text ~= '' and textguitext.Enabled
		VapeLabelCustomShadow.Visible = VapeLabelCustom.Visible and textguishadow.Enabled
		VapeLabelSorter.HorizontalAlignment = right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
		VapeLabelHolder.Size = UDim2.fromScale(1 / VapeTextScale.Scale, 1)
		VapeLabelHolder.Position = UDim2.fromOffset(right and 3 or 0, 11 + (VapeLogo.Visible and VapeLogo.Size.Y.Offset or 0) + (VapeLabelCustom.Visible and 28 or 0) + (textguibackground.Enabled and 3 or 0))
		if VapeLabelCustom.Visible then
			local size = getfontsize(removeTags(VapeLabelCustom.Text), VapeLabelCustom.TextSize, VapeLabelCustom.FontFace)
			VapeLabelCustom.Size = UDim2.fromOffset(size.X, size.Y)
			VapeLabelCustom.Position = UDim2.new(right and 1 / VapeTextScale.Scale or 0, right and -size.X or 0, 0, (VapeLogo.Visible and 32 or 8))
		end

		local found = {}
		for _, v in VapeLabels do
			if v.Enabled then
				table.insert(found, v.Object.Name)
			end
			v.Object:Destroy()
		end
		table.clear(VapeLabels)

		local info = TweenInfo.new(0.3, Enum.EasingStyle.Exponential)
		for i, v in mainapi.Modules do
			if mainapi:IsModuleHidden(i) then continue end
			if textguirender.Enabled and v.Category == 'Render' then continue end
			if v.Enabled or table.find(found, i) then
				local holder = Instance.new('Frame')
				holder.Name = i
				holder.Size = UDim2.fromOffset()
				holder.BackgroundTransparency = 1
				holder.ClipsDescendants = true
				holder.Parent = VapeLabelHolder
				local holderbackground
				local holdercolorline
				if textguibackground.Enabled then
					holderbackground = Instance.new('Frame')
					holderbackground.Size = UDim2.new(1, 3, 1, 0)
					holderbackground.BackgroundColor3 = color.Dark(uipallet.Main, 0.15)
					holderbackground.BackgroundTransparency = textguibackgroundtransparency.Value
					holderbackground.BorderSizePixel = 0
					holderbackground.Parent = holder
					local holderline = Instance.new('Frame')
					holderline.Size = UDim2.new(1, 0, 0, 1)
					holderline.Position = UDim2.new(0, 0, 1, -1)
					holderline.BackgroundColor3 = Color3.new()
					holderline.BackgroundTransparency = 0.928 + (0.072 * math.clamp((textguibackgroundtransparency.Value - 0.5) / 0.5, 0, 1))
					holderline.BorderSizePixel = 0
					holderline.Parent = holderbackground
					local holderline2 = holderline:Clone()
					holderline2.Name = 'Line'
					holderline2.Position = UDim2.new()
					holderline2.Parent = holderbackground
					holdercolorline = Instance.new('Frame')
					holdercolorline.Size = UDim2.new(0, 2, 1, 0)
					holdercolorline.Position = right and UDim2.new(1, -5, 0, 0) or UDim2.new()
					holdercolorline.BorderSizePixel = 0
				holdercolorline.Visible = textguiaccentline.Enabled
				holdercolorline.Parent = holderbackground
			end
				local holdertext = Instance.new('TextLabel')
				holdertext.Position = UDim2.fromOffset(right and 3 or 6, 2)
				holdertext.BackgroundTransparency = 1
				holdertext.BorderSizePixel = 0
				holdertext.Text = ({v.Name:gsub(' ', '')})[1]..(textguiextratext.Enabled and v.ExtraText and " <font color='#A8A8A8'>"..v.ExtraText()..'</font>' or '')
				holdertext.TextSize = textguisize.Value
				holdertext.FontFace = textguifont.Value
				holdertext.RichText = true
				local size = getfontsize(removeTags(holdertext.Text), holdertext.TextSize, holdertext.FontFace)
				holdertext.Size = UDim2.fromOffset(size.X, size.Y)
				if textguishadow.Enabled then
					local holderdrop = holdertext:Clone()
					holderdrop.Position = UDim2.fromOffset(holdertext.Position.X.Offset + 1, holdertext.Position.Y.Offset + 1)
					holderdrop.Text = removeTags(holdertext.Text)
					holderdrop.TextColor3 = Color3.new()
					holderdrop.Parent = holder
				end
				holdertext.Parent = holder
				local holdersize = UDim2.fromOffset(size.X + 10, size.Y + (textguibackground.Enabled and 5 or 3))
				if textguianimations.Enabled then
					if not table.find(found, i) then
						tween:Tween(holder, info, {
							Size = holdersize
						})
					else
						holder.Size = holdersize
						if not v.Enabled then
							tween:Tween(holder, info, {
								Size = UDim2.fromOffset()
							})
						end
					end
				else
					holder.Size = v.Enabled and holdersize or UDim2.fromOffset()
				end
				table.insert(VapeLabels, {
					Object = holder,
					Text = holdertext,
					Background = holderbackground,
					Color = holdercolorline,
					Enabled = v.Enabled
				})
			end
		end

		if textguisort.Value == 'Alphabetical' then
			table.sort(VapeLabels, function(a, b)
				return a.Text.Text < b.Text.Text
			end)
		else
			table.sort(VapeLabels, function(a, b)
				return a.Text.Size.X.Offset > b.Text.Size.X.Offset
			end)
		end

		for i, v in VapeLabels do
			if v.Color then
				v.Color.Parent.Line.Visible = i ~= 1
			end
			v.Object.LayoutOrder = i
		end
	end

	mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value, true)
end

function mainapi:UpdateGUI(hue, sat, val, default)
	if mainapi.Loaded == nil then return end
	if not default and mainapi.GUIColor.Rainbow then return end
	if textgui.Button.Enabled then
		VapeLogoGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, sat, val)),
			ColorSequenceKeypoint.new(1, textguigradient.Enabled and Color3.fromHSV(mainapi:Color((hue - 0.075) % 1)) or Color3.fromHSV(hue, sat, val))
		})
		VapeLogoGradient2.Color = textguigradient.Enabled and textguigradientv4.Enabled and VapeLogoGradient.Color or ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
		})
		VapeLabelCustom.TextColor3 = textguicolorcustomtoggle.Enabled and Color3.fromHSV(textguicolorcustom.Hue, textguicolorcustom.Sat, textguicolorcustom.Value) or VapeLogoGradient.Color.Keypoints[2].Value

		local customcolor = textguicolordrop.Value == 'Custom color' and Color3.fromHSV(textguicolor.Hue, textguicolor.Sat, textguicolor.Value) or nil
		for i, v in VapeLabels do
			v.Text.TextColor3 = customcolor or (mainapi.GUIColor.Rainbow and Color3.fromHSV(mainapi:Color((hue - ((textguigradient and i + 2 or i) * 0.025)) % 1)) or VapeLogoGradient.Color.Keypoints[2].Value)
			if v.Color then
				v.Color.BackgroundColor3 = v.Text.TextColor3
			end
			if textguibackgroundtint.Enabled and v.Background then
				v.Background.BackgroundColor3 = color.Dark(v.Text.TextColor3, 0.75)
			end
		end
	end

	local rainbow = mainapi.GUIColor.Rainbow and mainapi.RainbowMode.Value ~= 'Retro'
	if mainapi.PresetSyncButton and mainapi.PresetSyncButton.Parent then
		mainapi.PresetSyncButton.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
		mainapi.PresetSyncButton.TextColor3 = mainapi:TextColor(hue, sat, val)
	end

	for i, v in mainapi.Categories do
		if i == 'Main' then
			local mainLogo = v.Object and v.Object:FindFirstChild('VapeLogo', true)
			if mainLogo then
				local v4Logo = mainLogo:FindFirstChild('V4Logo', true)
				if v4Logo then
					v4Logo.ImageColor3 = Color3.fromHSV(hue, sat, val)
				end
			end
			for _, button in v.Buttons do
				if button.Enabled then
					button.Object.TextColor3 = rainbow and Color3.fromHSV(mainapi:Color((hue - (button.Index * 0.025)) % 1)) or Color3.fromHSV(hue, sat, val)
					if button.Icon then
						button.Icon.ImageColor3 = button.Object.TextColor3
					end
				end
			end
		end

		if v.Options then
			for _, option in v.Options do
				if option.Color then
					option:Color(hue, sat, val, rainbow)
				end
			end
		end

		if v.Type == 'CategoryList' then
			v.Object.Children.Add.AddButton.ImageColor3 = rainbow and Color3.fromHSV(mainapi:Color(hue % 1)) or Color3.fromHSV(hue, sat, val)
			if v.Selected then
				v.Selected.BackgroundColor3 = rainbow and Color3.fromHSV(mainapi:Color(hue % 1)) or Color3.fromHSV(hue, sat, val)
				v.Selected.Title.TextColor3 = mainapi.GUIColor.Rainbow and Color3.new(0.19, 0.19, 0.19) or mainapi:TextColor(hue, sat, val)
				v.Selected.Dots.Dots.ImageColor3 = v.Selected.Title.TextColor3
				v.Selected.Bind.Icon.ImageColor3 = v.Selected.Title.TextColor3
				v.Selected.Bind.TextLabel.TextColor3 = v.Selected.Title.TextColor3
			end
		end
	end

	for _, button in mainapi.Modules do
		if button.RefreshVisual then
			button:RefreshVisual()
		elseif button.Enabled then
			button.Object.BackgroundColor3 = rainbow and Color3.fromHSV(mainapi:Color((hue - (button.Index * 0.025)) % 1)) or Color3.fromHSV(hue, sat, val)
			button.Object.TextColor3 = mainapi.GUIColor.Rainbow and Color3.new(0.19, 0.19, 0.19) or mainapi:TextColor(hue, sat, val)
			button.Object.UIGradient.Enabled = rainbow and mainapi.RainbowMode.Value == 'Gradient'
			if button.Object.UIGradient.Enabled then
				button.Object.BackgroundColor3 = Color3.new(1, 1, 1)
				button.Object.UIGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(mainapi:Color((hue - (button.Index * 0.025)) % 1))),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(mainapi:Color((hue - ((button.Index + 1) * 0.025)) % 1)))
				})
			end
			button.Object.Bind.Icon.ImageColor3 = button.Object.TextColor3
			button.Object.Bind.TextLabel.TextColor3 = button.Object.TextColor3
			button.Object.Dots.Dots.ImageColor3 = button.Object.TextColor3
		end

		for _, option in button.Options do
			if option.Color then
				option:Color(hue, sat, val, rainbow)
			end
		end

		for _, v in button.Tags do
			if v.Name == 'BROKEN' then
				v.BackgroundColor3 = BROKEN_TAG_COLOUR
				v.BackgroundTransparency = 0
				local label = v:FindFirstChild('Text')
				if label then
					label.TextColor3 = Color3.new(1, 1, 1)
				end
				continue
			end

			v.BackgroundColor3 = rainbow and Color3.fromHSV(mainapi:Color((hue - (button.Index * 0.025)) % 1)) or button.Enabled and Color3.new(1, 1, 1) or Color3.fromHSV(hue, sat, val)
			v.BackgroundTransparency = (rainbow or not button.Enabled) and 0 or 0.85
			v:FindFirstChild('Text').TextColor3 = mainapi.GUIColor.Rainbow and Color3.new(0.19, 0.19, 0.19) or mainapi:TextColor(hue, sat, val)
		end
	end

	for i, v in mainapi.Overlays.Toggles do
		if v.Enabled then
			tween:Cancel(v.Object.Knob)
			v.Object.Knob.BackgroundColor3 = rainbow and Color3.fromHSV(mainapi:Color((hue - (i * 0.075)) % 1)) or Color3.fromHSV(hue, sat, val)
		end
	end

	for _, panel in {mainapi.Legit, mainapi.Kits} do
		if panel.Icon then
			panel.Icon.ImageColor3 = Color3.fromHSV(hue, sat, val)
		end

		if panel.Window.Visible then
			for _, v in panel.Modules do
				if v.Enabled then
					tween:Cancel(v.Object.Knob)
					v.Object.Knob.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				end

				for _, option in v.Options do
					if option.Color then
						option:Color(hue, sat, val, rainbow)
					end
				end
			end
		end
	end
end

mainapi:Clean(notifications.ChildRemoved:Connect(function()
	for i, v in notifications:GetChildren() do
		if tween.Tween then
			tween:Tween(v, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
				Position = UDim2.new(1, 0, 1, -(29 + (78 * i)))
			})
		end
	end
end))
;(function()
local whitelist = {Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3}
local function convert(input)
	return {KeyCode = {Name = input == Enum.UserInputType.MouseButton2 and 'MB2' or input == Enum.UserInputType.MouseButton1 and 'MB1' or 'MB3'}}
end
mainapi.UndoStack = {}
mainapi.RedoStack = {}
function mainapi:PushUndo(module)
	if not module then return end
	table.insert(self.UndoStack, module)
	while #self.UndoStack > 50 do
		table.remove(self.UndoStack, 1)
	end
	table.clear(self.RedoStack)
end
function mainapi:Undo()
	local module = table.remove(self.UndoStack)
	if not module then return end
	module:Toggle()
	table.insert(self.RedoStack, module)
	if self.ToggleNotifications and self.ToggleNotifications.Enabled then
		self:CreateNotification('Undo', module.Name..' toggle reverted', 0.75)
	end
end
function mainapi:Redo()
	local module = table.remove(self.RedoStack)
	if not module then return end
	module:Toggle()
	table.insert(self.UndoStack, module)
	if self.ToggleNotifications and self.ToggleNotifications.Enabled then
		self:CreateNotification('Redo', module.Name..' toggle re-applied', 0.75)
	end
end
mainapi:Clean(inputService.InputBegan:Connect(function(inputObj)
	if inputService:GetFocusedTextBox() then return end
	if inputObj.KeyCode ~= Enum.KeyCode.Z and inputObj.KeyCode ~= Enum.KeyCode.Y then return end
	if not (inputService:IsKeyDown(Enum.KeyCode.LeftControl) or inputService:IsKeyDown(Enum.KeyCode.RightControl)) then return end
	if inputObj.KeyCode == Enum.KeyCode.Z then
		mainapi:Undo()
	else
		mainapi:Redo()
	end
end))

local function keybindStart(inputObj)
	if not inputService:GetFocusedTextBox() and (inputObj.KeyCode ~= Enum.KeyCode.Unknown or table.find(whitelist, inputObj.UserInputType)) then
		if table.find(whitelist, inputObj.UserInputType) then
			inputObj = convert(inputObj.UserInputType)
		end

		table.insert(mainapi.HeldKeybinds, inputObj.KeyCode.Name)
		if mainapi.Binding then return end

		if checkKeybinds(mainapi.HeldKeybinds, mainapi.Keybind, inputObj.KeyCode.Name) then
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			for _, v in mainapi.Windows do
				v.Visible = false
			end
			clickgui.Visible = not clickgui.Visible
			tooltip.Visible = false
			mainapi:BlurCheck()
		end

		local toggled = false
		for i, v in mainapi.Modules do
			if checkKeybinds(mainapi.HeldKeybinds, v.Bind, inputObj.KeyCode.Name) then
				toggled = true
				if mainapi.ToggleNotifications.Enabled then
						mainapi:CreateNotification("<b>"..v.Name.."</b>", not v.Enabled and "<font color='#5AFF5A'>Enabled</font>" or "<font color='#FF5A5A'>Disabled</font>", 0.75)
				end
				if mainapi.PushUndo then mainapi:PushUndo(v) end
				v:Toggle(true)
			end
		end
		for _, panel in {mainapi.Legit, mainapi.Kits} do
			for i, v in panel.Modules do
				if v.Bind and checkKeybinds(mainapi.HeldKeybinds, v.Bind, inputObj.KeyCode.Name) then
					if mainapi.ToggleNotifications.Enabled then
						mainapi:CreateNotification("<b>"..v.Name.."</b>", not v.Enabled and "<font color='#5AFF5A'>Enabled</font>" or "<font color='#FF5A5A'>Disabled</font>", 0.75)
					end
					v:Toggle()
				end
			end
		end
		if toggled then
			if mainapi.UpdateTextGUI then mainapi:UpdateTextGUI() end
		end

		for _, v in mainapi.Profiles do
			if checkKeybinds(mainapi.HeldKeybinds, v.Bind, inputObj.KeyCode.Name) and v.Name ~= mainapi.Profile then
				mainapi:Save()
				mainapi:Load(true, v.Name)
				mainapi:Save()
				break
			end
		end
	end
end
local function keybindEnd(inputObj)
	if not inputService:GetFocusedTextBox() and (inputObj.KeyCode ~= Enum.KeyCode.Unknown or table.find(whitelist, inputObj.UserInputType)) then
		if table.find(whitelist, inputObj.UserInputType) then
			inputObj = convert(inputObj.UserInputType)
		end
		if mainapi.Binding then
			if not mainapi.MultiKeybind.Enabled then
				mainapi.HeldKeybinds = {inputObj.KeyCode.Name}
			end
			mainapi.Binding:SetBind(checkKeybinds(mainapi.HeldKeybinds, mainapi.Binding.Bind, inputObj.KeyCode.Name) and {} or mainapi.HeldKeybinds, true)
			mainapi.Binding = nil
			if mainapi.ScheduleSave then mainapi:ScheduleSave() end
		end
	end

	local ind = table.find(mainapi.HeldKeybinds, inputObj.KeyCode.Name)
	if ind then
		table.remove(mainapi.HeldKeybinds, ind)
	end
end
mainapi:Clean(inputService.InputBegan:Connect(keybindStart))

mainapi:Clean(inputService.InputEnded:Connect(function(inputObj)
	if table.find(whitelist, inputObj.UserInputType) then
		inputObj = convert(inputObj.UserInputType)
	end
	if mainapi.ToggleMode.Value == "Held" and not table.find(mainapi.Keybind, ({tostring(inputObj.KeyCode):gsub("Enum.KeyCode.", "")})[1]) then
		keybindStart(inputObj)
	else
		keybindEnd(inputObj)
	end
end))
end)()

;(function()
	mainapi.ErrorLogs = mainapi.ErrorLogs or {}
	mainapi.StartedAt = os.clock()
	local function formatErrors()
		local lines = {}
		for _, entry in mainapi.ErrorLogs do
			table.insert(lines, string.format('[%s] %s%s', entry.Time, entry.Module, entry.Count > 1 and ' (x'..entry.Count..')' or ''))
			table.insert(lines, entry.Message)
		end
		return #lines > 0 and table.concat(lines, '\n') or 'No ElevateV4 errors recorded this session.'
	end
	function mainapi:RecordError(moduleName, message)
		message = tostring(message):gsub('\n+', ' '):sub(1, 600)
		local now, previous = os.clock(), self.ErrorLogs[#self.ErrorLogs]
		if previous and previous.Module == tostring(moduleName or 'ElevateV4') and previous.Message == message and now - previous.At < 5 then
			previous.Count += 1
			previous.At, previous.Time = now, os.date('%H:%M:%S')
			return
		end
		table.insert(self.ErrorLogs, {Module = tostring(moduleName or 'ElevateV4'), Message = message, At = now, Time = os.date('%H:%M:%S'), Count = 1})
		while #self.ErrorLogs > 80 do table.remove(self.ErrorLogs, 1) end
		if self.Telemetry and self.Telemetry.Report then pcall(self.Telemetry.Report, 'module', moduleName, message) end
		if self.ErrorLogWindow and self.ErrorLogWindow.Refresh then self.ErrorLogWindow:Refresh() end
	end
	local function window(name, title, size)
		local frame = Instance.new('Frame')
		frame.Name, frame.Size, frame.Position = name, size, UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2)
		frame.BackgroundColor3, frame.Visible, frame.Parent = uipallet.Main, false, scaledgui
		addBlur(frame); addCorner(frame); addWindowStroke(frame); makeDraggable(frame)
		local heading = Instance.new('TextLabel')
		heading.Size, heading.Position, heading.BackgroundTransparency = UDim2.new(1, -50, 0, 38), UDim2.fromOffset(14, 0), 1
		heading.Text, heading.TextColor3, heading.TextSize, heading.FontFace = title, uipallet.Text, 14, uipallet.FontSemiBold
		heading.TextXAlignment, heading.Parent = Enum.TextXAlignment.Left, frame
		addCloseButton(frame).MouseButton1Click:Connect(function() frame.Visible = false end)
		table.insert(mainapi.Windows, frame)
		return frame
	end
	local diagnostics = window('AetherDiagnostics', 'ElevateV4 Diagnostics', UDim2.fromOffset(520, 390))
	local diagnosticsBody = Instance.new('TextLabel')
	diagnosticsBody.Size, diagnosticsBody.Position, diagnosticsBody.BackgroundTransparency = UDim2.new(1, -28, 1, -96), UDim2.fromOffset(14, 46), 1
	diagnosticsBody.TextXAlignment, diagnosticsBody.TextYAlignment, diagnosticsBody.TextWrapped = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, true
	diagnosticsBody.TextColor3, diagnosticsBody.TextSize, diagnosticsBody.FontFace, diagnosticsBody.Parent = color.Dark(uipallet.Text, 0.13), 12, uipallet.Font, diagnostics
	local copyDiagnostics = Instance.new('TextButton')
	copyDiagnostics.Size, copyDiagnostics.Position = UDim2.fromOffset(132, 28), UDim2.new(1, -146, 1, -38)
	copyDiagnostics.BackgroundColor3, copyDiagnostics.Text, copyDiagnostics.TextColor3 = Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value), 'Copy to clipboard', mainapi:TextColor(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	copyDiagnostics.TextSize, copyDiagnostics.FontFace, copyDiagnostics.Parent = 11, uipallet.Font, diagnostics; addCorner(copyDiagnostics)
	local function connectionCount()
		local count = #(mainapi.Connections or {})
		for _, module in mainapi.Modules do count += #(module.Connections or {}) end
		for _, panel in {mainapi.Legit, mainapi.Kits} do
			if panel then for _, module in panel.Modules do count += #(module.Connections or {}) end end
		end
		return count
	end
	local function diagnosticsText()
		local executor = 'Unknown'
		pcall(function() executor = identifyexecutor and select(1, identifyexecutor()) or executor end)
		local fps = 'Unavailable'
		pcall(function() fps = string.format('%.0f', workspace:GetRealPhysicsFPS()) end)
		local memory = 'Unavailable'
		pcall(function() memory = string.format('%.1f MB', collectgarbage('count') / 1024) end)
		local controllerState = mainapi.Libraries and mainapi.Libraries.entity and mainapi.Libraries.entity.Running and 'entity: ready' or 'entity: unavailable'
		pcall(function()
			local bedwars = getgenv and getgenv().bedwars
			if bedwars then
				controllerState = controllerState..' • Block: '..(bedwars.BlockController and 'ready' or 'missing')..' • Ability: '..(bedwars.AbilityController and 'ready' or 'missing')
			end
		end)
		return table.concat({
			'Executor: '..tostring(executor),
			'Filesystem: '..(type(isfile) == 'function' and type(readfile) == 'function' and type(writefile) == 'function' and 'supported' or 'limited'),
			'HTTP: '..((type(request) == 'function' or type(game.HttpGet) == 'function') and 'supported' or 'unavailable'),
			'setfpscap: '..(type(setfpscap) == 'function' and 'supported' or 'unavailable')..'   Drawing: '..(Drawing and 'supported' or 'unavailable'),
			'Controllers: '..controllerState,
			'Active connections: '..connectionCount()..'   Active hooks: '..tostring(mainapi.ActiveHooks or 0),
			'Performance: '..fps..' physics FPS   '..memory..' Lua memory',
			'Session: '..math.floor(os.clock() - mainapi.StartedAt)..'s   Profile: '..tostring(mainapi.Profile)..'   Version: '..tostring(mainapi.Version),
			'', 'Errors this session: '..#mainapi.ErrorLogs
		}, '\n')
	end
	function mainapi:SetDebugMode(enabled)
		if enabled then diagnostics.Visible = true end
	end
	mainapi.Diagnostics = {
		Open = function()
			diagnosticsBody.Text = diagnosticsText(); diagnostics.Visible = true
		end
	}
	copyDiagnostics.MouseButton1Click:Connect(function()
		if setclipboard then setclipboard(diagnosticsText()); mainapi:CreateNotification('Diagnostics', 'Copied to clipboard.', 4, 'info') end
	end)
	mainapi:Clean(runService.Heartbeat:Connect(function()
		if diagnostics.Visible and mainapi.DebugMode and mainapi.DebugMode.Enabled then diagnosticsBody.Text = diagnosticsText() end
	end))
	local errors = window('AetherErrorLogs', 'ElevateV4 Error Logs', UDim2.fromOffset(620, 390))
	local errorsBody = diagnosticsBody:Clone()
	errorsBody.Size, errorsBody.Position, errorsBody.Parent = UDim2.new(1, -28, 1, -96), UDim2.fromOffset(14, 46), errors
	errorsBody.TextWrapped, errorsBody.TextYAlignment = true, Enum.TextYAlignment.Top
	local copyErrors = copyDiagnostics:Clone()
	copyErrors.Position, copyErrors.Parent = UDim2.new(1, -146, 1, -38), errors
	mainapi.ErrorLogWindow = {
		Open = function(self) self:Refresh(); errors.Visible = true end,
		Refresh = function() errorsBody.Text = formatErrors() end
	}
	copyErrors.MouseButton1Click:Connect(function()
		if setclipboard then setclipboard(formatErrors()); mainapi:CreateNotification('Error Logs', 'Copied to clipboard.', 4, 'info') end
	end)
end)()

return mainapi
