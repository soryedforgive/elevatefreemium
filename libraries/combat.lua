
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService('Players'))
local lplr = playersService.LocalPlayer

local COMBAT_WINDOW = 3

local combat = {
	Window = COMBAT_WINDOW,
	Started = false,
	LastDamageAt = nil,
	ClearedAt = nil,
	Connections = {},
}

local function clearedNow()
	return combat.ClearedAt ~= nil and (tick() - combat.ClearedAt) < combat.Window
end
function combat:IsInCombat()
	if clearedNow() then
		return false
	end
	return self.LastDamageAt ~= nil and (tick() - self.LastDamageAt) < self.Window
end
function combat:TimeSinceDamage()
	if self.LastDamageAt == nil then
		return nil
	end
	return tick() - self.LastDamageAt
end
function combat:TimeLeft()
	if not self:IsInCombat() then
		return 0
	end
	return math.max(self.Window - (tick() - self.LastDamageAt), 0)
end
function combat:Reset()
	self.LastDamageAt = nil
	self.ClearedAt = tick()
end

local function onDamage(damageTable)
	if type(damageTable) ~= 'table' or damageTable.entityInstance ~= lplr.Character then
		return
	end
	if clearedNow() then
		return
	end
	combat.LastDamageAt = tick()
end

local function onDeath(deathTable)
	if type(deathTable) == 'table' and deathTable.entityInstance ~= lplr.Character then
		return
	end
	combat:Reset()
end

function combat:Start()
	if self.Started then
		return self
	end
	self.Started = true

	local vape = shared.vape
	local vapeEvents = getgenv().vapeEvents
	local function track(connection)
		if not connection then
			return
		end
		table.insert(self.Connections, connection)
		if vape and type(vape.Clean) == 'function' then
			vape:Clean(connection)
		end
	end

	if vapeEvents then
		track(vapeEvents.EntityDamageEvent.Event:Connect(onDamage))
		track(vapeEvents.EntityDeathEvent.Event:Connect(onDeath))
	end
	track(lplr.CharacterAdded:Connect(function()
		self:Reset()
	end))
	track(lplr.CharacterRemoving:Connect(function()
		self:Reset()
	end))

	return self
end

function combat:Stop()
	self.Started = false
	for _, connection in self.Connections do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(self.Connections)
	self.LastDamageAt = nil
	self.ClearedAt = nil
end

combat:Start()

return combat
