run(function()
	local Disguise
	local Mode
	local IDBox
	local Generation: number = 0
	local Disguised: Model?
	local AppliedKey: string?
	local HeadMesh: {Head: MeshPart, Copy: MeshPart}?
	local EmoteRecord: {[string]: any}?
	local Connections: {RBXScriptConnection} = {}
	local Cloned: {[Instance]: boolean} = {}
	local Stashed: {[Instance]: Instance} = {}
	local Colors: {[BasePart]: Color3} = {}
	local Animations: {[Animation]: string} = {}
	local UserIds: {[string]: number} = {}
	local Descriptions: {[number]: HumanoidDescription} = {}
	local Appearance: {string} = {'Accoutrement', 'Clothing', 'ShirtGraphic', 'BodyColors'}
	local Inherited: {string} = {'HeightScale', 'WidthScale', 'DepthScale', 'HeadScale', 'BodyTypeScale', 'ProportionScale', 'Torso', 'LeftArm', 'RightArm', 'LeftLeg', 'RightLeg'}
	local ApplyMethods: {string} = {'ApplyDescriptionResetAsync', 'ApplyDescriptionReset', 'ApplyDescriptionAsync', 'ApplyDescription', 'ApplyDescriptionClientServer'}

	local function IsAppearance(Object: Instance): boolean
		if Object:GetAttribute('InvItem') ~= nil or Object:GetAttribute('ArmorSlot') ~= nil or Object:GetAttribute('IsBackpack') ~= nil then
			return false
		end

		for _, ClassName: string in Appearance do
			if Object:IsA(ClassName) then
				return true
			end
		end

		return false
	end

	local function Hide(Object: Instance)
		local Parent: Instance? = Object.Parent
		if Cloned[Object] or not Parent then
			return
		end

		Stashed[Object] = Parent
		task.defer(function()
			if Stashed[Object] ~= Parent then
				return
			end

			if Object.Parent == Parent then
				pcall(function()
					Object.Parent = nil
				end)
			else
				Stashed[Object] = nil
			end
		end)
	end

	local function CopyMesh(Target: MeshPart, Source: MeshPart): boolean
		return pcall(function()
			Target:ApplyMesh(Source)
		end) or pcall(function()
			Target.MeshId = Source.MeshId
		end)
	end

	local function Reset(Revert: boolean)
		Generation += 1
		Disguised = nil
		AppliedKey = nil

		for _, v: RBXScriptConnection in Connections do
			v:Disconnect()
		end
		table.clear(Connections)

		if Revert then
			for Object: Instance in Cloned do
				Object:Destroy()
			end

			for Object: Instance, Parent: Instance in Stashed do
				pcall(function()
					Object.Parent = Parent
				end)
			end

			for Part: BasePart, Color: Color3 in Colors do
				if Part.Parent then
					Part.Color = Color
				end
			end

			if HeadMesh and HeadMesh.Head.Parent then
				CopyMesh(HeadMesh.Head, HeadMesh.Copy)
			end

			if EmoteRecord then
				pcall(function()
					EmoteRecord.Description.JumpAnimation = EmoteRecord.JumpAnimation
					EmoteRecord.Description:SetEmotes(EmoteRecord.Emotes)
					EmoteRecord.Description:SetEquippedEmotes(EmoteRecord.Equipped)
				end)
			end

			for Target: Animation, AnimationId: string in Animations do
				Target.AnimationId = AnimationId
			end
		end

		if HeadMesh then
			HeadMesh.Copy:Destroy()
		end

		HeadMesh = nil
		EmoteRecord = nil
		table.clear(Cloned)
		table.clear(Stashed)
		table.clear(Colors)
		table.clear(Animations)
	end

	local function ResolveUserId(Text: string): number?
		local Name: string = (Text:gsub('[%s@]', ''))
		if Name == '' then
			return 239702688
		end

		if Name:match('^%d+$') then
			return tonumber(Name)
		end

		local Key: string = Name:lower()
		if not UserIds[Key] then
			local Success, UserId = pcall(function()
				return playersService:GetUserIdFromNameAsync(Name)
			end)

			if Success and UserId then
				UserIds[Key] = UserId
			end
		end

		return UserIds[Key]
	end

	local function GetDescription(UserId: number): HumanoidDescription?
		if not Descriptions[UserId] then
			for i: number = 1, 3 do
				local Success, Description = pcall(function()
					return playersService:GetHumanoidDescriptionFromUserId(UserId)
				end)

				if Success and Description then
					Descriptions[UserId] = Description
					break
				end

				if i < 3 then
					task.wait(1)
				end
			end
		end

		return Descriptions[UserId] and Descriptions[UserId]:Clone()
	end

	local function ApplyDescription(Target: Humanoid, Description: HumanoidDescription): boolean
		local Result: boolean?
		task.spawn(function()
			for _, Method: string in ApplyMethods do
				if pcall(function()
					Target[Method](Target, Description)
				end) then
					Result = true
					return
				end
			end

			Result = false
		end)

		local Deadline: number = tick() + 10
		while Result == nil and tick() < Deadline do
			task.wait(0.1)
		end

		return Result == true
	end

	local function DisguiseCharacter(Ent, Current: number)
		local UserId: number? = ResolveUserId(IDBox.Value)
		if Current ~= Generation then
			return
		end

		if not UserId then
			notif('Disguise', `Could not find the user {IDBox.Value}`, 5, 'warning')
			return
		end

		local Deadline: number = tick() + 5
		while not lplr:HasAppearanceLoaded() and tick() < Deadline do
			task.wait(0.1)
		end

		local Description: HumanoidDescription? = GetDescription(UserId)
		local Character: Model = Ent.Character
		if Current ~= Generation or not Character.Parent then
			if Description then
				Description:Destroy()
			end

			return
		end

		if not Description then
			notif('Disguise', `Could not load the avatar of user {UserId}`, 5, 'warning')
			return
		end

		local Original: HumanoidDescription? = Ent.Humanoid:FindFirstChildOfClass('HumanoidDescription')
		if Original then
			for _, Property: string in Inherited do
				Description[Property] = Original[Property]
			end
		end

		local Archivable: boolean = Character.Archivable
		Character.Archivable = true
		local Clone: Model? = Character:Clone()
		Character.Archivable = Archivable
		if not Clone then
			Description:Destroy()
			notif('Disguise', 'Could not copy your character', 5, 'warning')
			return
		end

		local Objects: {Instance} = Clone:GetDescendants()
		table.insert(Objects, Clone)
		for _, v: Instance in Objects do
			for _, Tag: string in v:GetTags() do
				v:RemoveTag(Tag)
			end

			if v:IsA('LuaSourceContainer') then
				v:Destroy()
			elseif v:IsA('BasePart') and v.Parent == Clone then
				v.CanCollide = false
				v.CanQuery = false
				v.CanTouch = false
				v.Anchored = v.Name == 'HumanoidRootPart'
			end
		end

		local CloneHumanoid: Humanoid? = Clone:FindFirstChildOfClass('Humanoid')
		if CloneHumanoid then
			CloneHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end

		Clone.Name = 'DisguiseRig'
		Clone:PivotTo(Clone:GetPivot() + Vector3.new(0, 1000, 0))
		Clone.Parent = workspace

		local Applied: boolean = CloneHumanoid ~= nil and ApplyDescription(CloneHumanoid, Description)
		if not Applied and Current == Generation then
			notif('Disguise', `Could not apply the avatar of user {UserId}`, 5, 'warning')
		end

		local Head: BasePart? = Ent.Head
		if not Applied or Current ~= Generation or not Character.Parent or not (Head and Head.Parent) then
			Clone:Destroy()
			Description:Destroy()
			return
		end

		table.insert(Connections, Character.ChildAdded:Connect(function(Child: Instance)
			if IsAppearance(Child) then
				Hide(Child)
			end
		end))

		for _, Child: Instance in Character:GetChildren() do
			if IsAppearance(Child) then
				Hide(Child)
			elseif Child:IsA('BasePart') and Child.Name ~= 'HumanoidRootPart' then
				Colors[Child] = Child.Color
			end
		end

		for _, Child: Instance in Clone:GetChildren() do
			if not IsAppearance(Child) then
				continue
			end

			for _, v: Instance in Child:GetDescendants() do
				if v:IsA('Weld') and v.Part1 and v.Part1.Parent == Clone then
					v.Part1 = Character:FindFirstChild(v.Part1.Name)
				elseif v:IsA('RigidConstraint') and v.Attachment1 and v.Attachment1.Parent and v.Attachment1.Parent.Parent == Clone then
					local Part: Instance? = Character:FindFirstChild(v.Attachment1.Parent.Name)
					v.Attachment1 = Part and Part:FindFirstChild(v.Attachment1.Name)
				end
			end

			Cloned[Child] = true
			Child.Parent = Character
		end

		local CloneHead: Instance? = Clone:FindFirstChild('Head')
		local Face: Instance? = Head:FindFirstChild('face')
		local CloneFace: Instance? = CloneHead and CloneHead:FindFirstChild('face')

		table.insert(Connections, Head.ChildAdded:Connect(function(Child: Instance)
			if Child:IsA('Decal') and Child.Name == 'face' then
				Hide(Child)
			end
		end))

		if Face then
			Hide(Face)
		end

		if CloneFace then
			Cloned[CloneFace] = true
			CloneFace.Parent = Head
		end

		if CloneHead and CloneHead:IsA('MeshPart') and Head:IsA('MeshPart') and not Head:FindFirstChild('FaceControls') then
			local Copied, Copy = pcall(Head.Clone, Head)
			Copy = Copied and Copy or nil
			if Copy and CopyMesh(Head, CloneHead) then
				Copy:ClearAllChildren()
				HeadMesh = {Head = Head, Copy = Copy}

				for _, v: Instance in Head:GetChildren() do
					if v:IsA('SurfaceAppearance') then
						Hide(v)
					end
				end

				for _, v: Instance in CloneHead:GetChildren() do
					if v:IsA('SurfaceAppearance') then
						Cloned[v] = true
						v.Parent = Head
					end
				end
			elseif Copy then
				Copy:Destroy()
			end
		end

		if Original then
			pcall(function()
				local Record = {
					Description = Original,
					Emotes = Original:GetEmotes(),
					Equipped = Original:GetEquippedEmotes(),
					JumpAnimation = Original.JumpAnimation
				}

				EmoteRecord = Record
				Original.JumpAnimation = Description.JumpAnimation
				Original:SetEmotes(Description:GetEmotes())
				Original:SetEquippedEmotes(Description:GetEquippedEmotes())
			end)
		end

		Clone:Destroy()
		Description:Destroy()
	end

	local function DisguiseAnimation(Ent, Current: number)
		local BundleId: number? = IDBox.Value == '' and 43 or tonumber(IDBox.Value)
		if not BundleId then
			notif('Disguise', 'Animation mode takes an animation pack bundle ID', 5, 'warning')
			return
		end

		local Success, Data = pcall(function()
			return marketplaceService:GetProductInfo(BundleId, Enum.InfoType.Bundle)
		end)

		local Animate: Instance? = Ent.Character:FindFirstChild('Animate')
		if Current ~= Generation then
			return
		end

		if not Success or type(Data) ~= 'table' then
			notif('Disguise', `Could not load bundle {BundleId}`, 5, 'warning')
			return
		end

		if Data.BundleType ~= 'AvatarAnimations' then
			notif('Disguise', "that's not an animation pack", 5, 'warning')
			return
		end

		if not Animate then
			notif('Disguise', 'Your character has no Animate script to change', 5, 'warning')
			return
		end

		for _, Item: any in Data.Items or {} do
			if type(Item) ~= 'table' or type(Item.Name) ~= 'string' then
				continue
			end

			local Words: {string} = Item.Name:split(' ')
			local Folder: Instance? = Animate:FindFirstChild(Words[#Words]:lower())
			local Target: Animation? = Folder and Folder:FindFirstChildWhichIsA('Animation')
			if not Target then
				continue
			end

			local Loaded, Objects = pcall(function()
				return game:GetObjects(`rbxassetid://{Item.Id}`)
			end)

			local Source: Animation? = Loaded and type(Objects) == 'table' and Objects[1] and Objects[1]:FindFirstChildWhichIsA('Animation', true)
			if Current ~= Generation then
				return
			end

			if Source then
				Animations[Target] = Animations[Target] or Target.AnimationId
				Target.AnimationId = Source.AnimationId
			end
		end
	end

	local function LocalAdded(Ent)
		if vape.ThreadFix then
			setthreadidentity(8)
		end

		local Key: string = `{Mode.Value}:{IDBox.Value}`
		if Ent.Character == Disguised and Key == AppliedKey then
			return
		end

		Reset(Ent.Character == Disguised)
		Disguised = Ent.Character
		AppliedKey = Key

		if Mode.Value == 'Character' then
			DisguiseCharacter(Ent, Generation)
		else
			DisguiseAnimation(Ent, Generation)
		end
	end

	Disguise = vape.Categories.Legit:CreateModule({
		Name = 'Disguise',
		Category = 'Game',
		Function = function(Callback: boolean)
			if vape.ThreadFix then
				setthreadidentity(8)
			end

			if Callback then
				Disguise:Clean(entitylib.Events.LocalAdded:Connect(LocalAdded))
				if entitylib.isAlive then
					task.spawn(LocalAdded, entitylib.character)
				end
			else
				Reset(true)
			end
		end,
		Tooltip = 'Makes you look like another player or use other animations'
	})

	Mode = Disguise:CreateDropdown({
		Name = 'Mode',
		List = {'Character', 'Animation'},
		Function = function()
			if Disguise.Enabled then
				Disguise:Toggle()
				Disguise:Toggle()
			end
		end
	})
	IDBox = Disguise:CreateTextBox({
		Name = 'Disguise',
		Placeholder = 'User ID, username or bundle ID',
		Function = function(Enter: boolean)
			if Enter and Disguise.Enabled then
				Disguise:Toggle()
				Disguise:Toggle()
			end
		end
	})
end)
