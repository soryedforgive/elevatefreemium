run(function()
	local Reach
	local Range
	local Width
	local Place
	local PlaceRange
	local Break
	local BreakRange
	local original = {}
	local placeOld
	local mineOld = {}
	local INFINITE, MAP, FALLBACK, BREAK_MAX = 99, 3000, 99, 21
	local wrapped = {}

	local function writable(data)
		if not table.isfrozen(data) then return true end
		if not setreadonly then return false end
		setreadonly(data, false)
		return true
	end

	local function placeRange()
		return PlaceRange.Value >= INFINITE and MAP or PlaceRange.Value
	end

	local function wrapFallbacks(enabled)
		local block = bedfight.Block
		if type(block) ~= 'table' then return end
		for _, name in {'GetNextBlockPosInDirection', 'GetPredictedBlockPosInRadius'} do
			local entry = wrapped[name]
			if enabled and not entry and type(block[name]) == 'function' then
				local old = block[name]
				entry = {Old = old}
				if name == 'GetNextBlockPosInDirection' then
					entry.New = function(a, b, c, range, ...)
						return old(a, b, c, Reach.Enabled and type(range) == 'number' and math.min(range, FALLBACK) or range, ...)
					end
				else
					entry.New = function(a, range, ...)
						return old(a, Reach.Enabled and type(range) == 'number' and math.min(range, FALLBACK) or range, ...)
					end
				end
				block[name] = entry.New
				wrapped[name] = entry
			elseif not enabled and entry and block[name] == entry.New then
				block[name] = entry.Old
				wrapped[name] = nil
			end
		end
	end

	local function apply(enabled)
		for name, data in bedfight.SwordsData do
			if type(data) ~= 'table' or not (data.Range and data.HitboxSize) then continue end
			if not writable(data) then continue end
			original[name] = original[name] or {data.Range, data.HitboxSize}
			local range, size = original[name][1], original[name][2]
			if enabled then
				data.Range = Range.Value / 2
				data.HitboxSize = Vector3.new(math.max(size.X, Width.Value), math.max(size.Y, Width.Value), Range.Value)
			else
				data.Range, data.HitboxSize = range, size
			end
		end

		local place = bedfight.BlocksData and bedfight.BlocksData.Default
		if type(place) == 'table' and place.Range and writable(place) then
			placeOld = placeOld or place.Range
			place.Range = enabled and Place.Enabled and placeRange() or placeOld
		end
		wrapFallbacks(enabled and Place.Enabled)
		for name, data in bedfight.MiningData do
			if type(data) == 'table' and data.Range and writable(data) then
				mineOld[name] = mineOld[name] or data.Range
				data.Range = enabled and Break.Enabled and math.min(BreakRange.Value, BREAK_MAX) or mineOld[name]
			end
		end
	end

	local function refresh()
		if Reach.Enabled and BreakRange then
			apply(true)
		end
	end

	Reach = vape.Categories.Combat:CreateModule({
		Name = 'Reach',
		Function = function(callback)
			apply(callback)
		end,
		Tooltip = 'Lets you hit, place and mine from further away'
	})
	Range = Reach:CreateSlider({
		Name = 'Range',
		Min = 10.5,
		Max = 14,
		Default = 14,
		Decimal = 10,
		Suffix = 'studs',
		Function = refresh,
		Tooltip = 'How far away a target can be'
	})
	Width = Reach:CreateSlider({
		Name = 'Width',
		Min = 4,
		Max = 12,
		Default = 4,
		Decimal = 10,
		Suffix = 'studs',
		Function = refresh,
		Tooltip = 'How far from your cursor a swing can land'
	})
	Place = Reach:CreateGroup({
		Name = 'Place',
		Function = function(callback)
			refresh()
		end,
		Tooltip = 'Lets you place blocks from further away'
	})
	PlaceRange = Place:CreateSlider({
		Name = 'Place range',
		Min = 1,
		Max = INFINITE,
		Default = INFINITE,
		Suffix = 'studs',
		Darker = true,
		Format = function(value)
			return value >= INFINITE and 'Infinite' or nil
		end,
		Function = refresh,
		Tooltip = 'How far away a block can be placed'
	})
	Break = Reach:CreateGroup({
		Name = 'Break',
		Function = function(callback)
			refresh()
		end,
		Tooltip = 'Lets you mine from further away'
	})
	BreakRange = Break:CreateSlider({
		Name = 'Break range',
		Min = 18,
		Max = BREAK_MAX,
		Default = BREAK_MAX,
		Decimal = 2,
		Suffix = 'studs',
		Darker = true,
		Function = function(value)
			if value > BREAK_MAX then
				BreakRange:SetValue(BREAK_MAX)
				return
			end
			refresh()
		end,
		Tooltip = 'How far away a block can be mined'
	})
end)
