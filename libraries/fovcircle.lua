
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))

local circles = {}
local connection
local module = {}

function module.Center()
	if inputService.TouchEnabled and not inputService.MouseEnabled then
		local camera = workspace.CurrentCamera
		return camera and camera.ViewportSize / 2 or Vector2.zero
	end
	return inputService:GetMouseLocation()
end
function module.ContainsPoint(position, radius, center)
	local camera = workspace.CurrentCamera
	if not camera or typeof(position) ~= 'Vector3' then return false, math.huge end
	local point, onScreen = camera:WorldToViewportPoint(position)
	if not onScreen or point.Z <= 0 then return false, math.huge end
	center = typeof(center) == 'Vector2' and center or module.Center()
	local distance = (Vector2.new(point.X, point.Y) - center).Magnitude
	return distance <= (tonumber(radius) or 0), distance
end

function module.ContainsEntity(entity, radius, center)
	local root = type(entity) == 'table' and entity.RootPart
	if not root or not root.Parent then return false, math.huge end
	return module.ContainsPoint(root.Position, radius, center)
end

local function call(getter, fallback)
	if type(getter) ~= 'function' then
		return fallback
	end
	local ok, value = pcall(getter)
	if ok and value ~= nil then
		return value
	end
	return fallback
end

local handle = {}
handle.__index = handle

function handle:Destroy()
	table.remove(circles, table.find(circles, self) or (#circles + 1))
	self.Destroyed = true
	pcall(function()
		if self.Frame then
			self.Frame:Destroy()
		end
	end)
	self.Frame = nil
	if #circles == 0 and connection then
		pcall(function()
			connection:Disconnect()
		end)
		connection = nil
	end
end

function handle:Update()
	local frame = self.Frame
	if not frame or self.Destroyed then
		return
	end
	local options = self.Options
	if not call(options.Visible, false) then
		frame.Visible = false
		return
	end
	local radius = tonumber(call(options.Radius, 0)) or 0
	if radius <= 0 then
		frame.Visible = false
		return
	end
	local position = call(options.Position, nil)
	if typeof(position) ~= 'Vector2' then
		position = module.Center()
	end
	frame.Position = UDim2.fromOffset(position.X, position.Y)
	frame.Size = UDim2.fromOffset(radius * 2, radius * 2)

	local colour = call(options.Colour, Color3.new(1, 1, 1))
	local transparency = math.clamp(tonumber(call(options.Transparency, 0)) or 0, 0, 1)
	local filled = call(options.Filled, false) and true or false
	frame.BackgroundColor3 = colour
	frame.BackgroundTransparency = filled and transparency or 1

	local stroke = self.Stroke
	if stroke then
		stroke.Color = colour
		stroke.Thickness = math.clamp(tonumber(call(options.Thickness, 1)) or 1, 0.5, 12)
		stroke.Transparency = filled and 1 or transparency
	end
	frame.Visible = true
end

function handle:SetParent(parent)
	local frame = self.Frame
	if not frame or not parent then
		return
	end
	frame.Parent = parent
end

function module.New(options)
	options = options or {}
	local frame = Instance.new('Frame')
	frame.Name = (options.Name or 'FOVCircle')..'Circle'
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ZIndex = options.ZIndex or 5

	local stroke = Instance.new('UIStroke')
	stroke.Thickness = 1
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Parent = frame

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame

	local self = setmetatable({
		Frame = frame,
		Stroke = stroke,
		Options = options
	}, handle)

	frame.Parent = options.Parent or (shared.vape and shared.vape.gui) or nil
	table.insert(circles, self)
	self:Update()

	if not connection then
		connection = runService.RenderStepped:Connect(function()
			for index = #circles, 1, -1 do
				local circle = circles[index]
				if circle.Destroyed or not circle.Frame or not circle.Frame.Parent then
					circle.Destroyed = true
					circle.Frame = nil
					table.remove(circles, index)
				end
			end
			for _, circle in circles do
				circle:Update()
			end
			if #circles == 0 and connection then
				connection:Disconnect()
				connection = nil
			end
		end)
	end

	return self
end

return module
