run(function()
	local AutoBalloon
	local FallSpeed
	local PopAboveLand
	local ITEM = 'Balloon'
	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Exclude
	rayCheck.RespectCanCollide = true

	local function count()
		local amount = lplr:FindFirstChild('BalloonsAmount')
		return amount and amount.Value or 0
	end

	AutoBalloon = vape.Categories.Utility:CreateModule({
		Name = 'AutoBalloon',
		Function = function(callback)
			if callback then
				local nextDeploy = 0
				repeat
					if entitylib.isAlive then
						local root = bodyRoot()
						rayCheck.FilterDescendantsInstances = {workspace:FindFirstChild('PlayersContainer') or lplr.Character, gameCamera}
						local ground = workspace:Raycast(root.Position, Vector3.new(0, -400, 0), rayCheck)
						if ground then
							if PopAboveLand.Enabled and count() > 0 and entitylib.character.Humanoid.FloorMaterial == Enum.Material.Air then
								fireRemote('PopBalloon')
								task.wait(0.15)
							end
						elseif root.AssemblyLinearVelocity.Y < -FallSpeed.Value and count() < 3 and (store.inventory[ITEM] or 0) > 0 and tick() >= nextDeploy then
							nextDeploy = tick() + 0.12
							equipServer(ITEM, 'AutoBalloon')
							fireRemote('DeployBalloon', ITEM)
							task.delay(0.5, syncTool, 'AutoBalloon')
						end
					end
					task.wait(0.05)
				until not AutoBalloon.Enabled
			else
				syncTool('AutoBalloon')
			end
		end,
		Tooltip = 'Blows up your balloons when you fall into the void'
	})
	FallSpeed = AutoBalloon:CreateSlider({
		Name = 'Fall speed',
		Min = 5,
		Max = 150,
		Default = 30,
		Suffix = 'studs a second',
		Tooltip = 'How fast you must be falling before it acts'
	})
	PopAboveLand = AutoBalloon:CreateToggle({
		Name = 'Pop when above land',
		Tooltip = 'Pops the balloons as soon as there is ground underneath you again'
	})
end)
