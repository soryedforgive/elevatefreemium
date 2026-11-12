run(function()
	local MapCleaner
	local Categories
	local KeepCollisions
	local changed = {}
	local generation = 0
	local WORDS = {
		Trees = {'tree', 'trunk', 'branch', 'palm', 'pine', 'birch'},
		Foliage = {'grass', 'bush', 'shrub', 'flower', 'leaf', 'leaves', 'plant', 'vine', 'fern', 'hedge', 'weed', 'foliage', 'ivy'},
		Props = {'prop', 'decor', 'barrel', 'crate', 'lamp', 'lantern', 'sign', 'bench', 'pot', 'vase', 'clutter', 'debris', 'pebble', 'mushroom'}
	}
	local PARTICLES = {ParticleEmitter = true, Trail = true, Beam = true, Fire = true, Smoke = true, Sparkles = true}
	local active = {}

	local function matches(name, words)
		name = name:lower()
		for _, word in words do
			if name:find(word, 1, true) then
				return true
			end
		end
		return false
	end

	local function remember(obj, prop, value)
		local saved = changed[obj]
		if not saved then
			saved = {}
			changed[obj] = saved
		end
		if saved[prop] == nil then
			saved[prop] = obj[prop]
		end
		obj[prop] = value
	end

	local function isCharacter(obj)
		local model = obj:FindFirstAncestorOfClass('Model')
		return model and model:FindFirstChildOfClass('Humanoid') ~= nil
	end

	local collection = cloneref(game:GetService('CollectionService'))

	local function partCategory(part)
		if collection:HasTag(part, 'block') then return end
		local parent = part.Parent
		local model = parent and parent:IsA('Model') and parent or nil
		for _, kind in {'Trees', 'Foliage', 'Props'} do
			if active[kind] and ((model and matches(model.Name, WORDS[kind])) or (kind == 'Foliage' and matches(part.Name, WORDS[kind]))) then
				return kind
			end
		end
	end

	local function consider(obj)
		if changed[obj] then return end
		if obj:IsA('BasePart') then
			if obj:IsA('Terrain') or not partCategory(obj) or isCharacter(obj) then return end
			remember(obj, 'LocalTransparencyModifier', 1)
			if not KeepCollisions.Enabled then
				remember(obj, 'CanCollide', false)
			end
		elseif active.Particles and PARTICLES[obj.ClassName] then
			remember(obj, 'Enabled', false)
		elseif active.Decals and (obj.ClassName == 'Decal' or obj.ClassName == 'Texture') then
			remember(obj, 'Transparency', 1)
		end
	end

	local function restore()
		for obj, saved in changed do
			if obj.Parent then
				for prop, value in saved do
					pcall(function()
						obj[prop] = value
					end)
				end
			end
		end
		table.clear(changed)
	end

	local function scan(gen)
		local list = workspace:GetDescendants()
		local started = os.clock()
		for i = 1, #list do
			if gen ~= generation then return end
			pcall(consider, list[i])
			if os.clock() - started > 0.002 then
				task.wait()
				started = os.clock()
			end
		end
	end

	MapCleaner = vape.Categories.World:CreateModule({
		Name = 'MapCleaner',
		Function = function(callback)
			generation += 1
			if callback then
				table.clear(active)
				for _, v in Categories.Value do
					active[v] = true
				end
				task.spawn(scan, generation)
				MapCleaner:Clean(workspace.DescendantAdded:Connect(function(obj)
					pcall(consider, obj)
				end))
			else
				restore()
			end
		end,
		Tooltip = 'Hides decorative clutter on your screen'
	})
	Categories = MapCleaner:CreateMultiDropdown({
		Name = 'Categories',
		List = {'Trees', 'Foliage', 'Props', 'Particles', 'Decals'},
		Default = {'Foliage', 'Particles'},
		Function = function()
			if MapCleaner.Enabled then
				MapCleaner:Toggle()
				MapCleaner:Toggle()
			end
		end
	})
	KeepCollisions = MapCleaner:CreateToggle({
		Name = 'Keep collisions',
		Default = true,
		Function = function()
			if MapCleaner.Enabled then
				MapCleaner:Toggle()
				MapCleaner:Toggle()
			end
		end,
		Tooltip = 'Hidden objects still block you'
	})
end)
