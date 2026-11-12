run(function()
    local Fullbright
    local Mode
    local oldsettings = {}
    local wanted = {
        Ambient = Color3.new(1, 1, 1),
        OutdoorAmbient = Color3.new(1, 1, 1),
        Brightness = 3
    }

    local function apply()
        for prop, value in wanted do
            if lightingService[prop] ~= value then
                lightingService[prop] = value
            end
        end
    end

    Fullbright = vape.Categories.Render:CreateModule({
        Name = 'Fullbright',
        Function = function(callback)
            if callback then
                if Mode.Value == 'Lighting' then
                    for prop in wanted do
                        oldsettings[prop] = lightingService[prop]
                        Fullbright:Clean(lightingService:GetPropertyChangedSignal(prop):Connect(function()
                            local current = lightingService[prop]
                            if current == wanted[prop] then return end
                            oldsettings[prop] = current
                            lightingService[prop] = wanted[prop]
                        end))
                    end
                    apply()
                else
                    local inst = Instance.new('PointLight')
                    inst.Range = 1000
                    Fullbright:Clean(inst)

                    repeat
                        inst.Parent = entitylib.isAlive and entitylib.character.RootPart or nil
                        task.wait(0.1)
                    until not Fullbright.Enabled
                end
            else
                for i, v in oldsettings do
                    lightingService[i] = v
                end
                table.clear(oldsettings)
            end
        end,
        Tooltip = 'Brightens the world around you'
    })
    Mode = Fullbright:CreateDropdown({
        Name = 'Mode',
        List = {'Lighting', 'PointLight'},
        Function = function()
            if Fullbright.Enabled then
                Fullbright:Toggle()
                Fullbright:Toggle()
            end
        end,
        Tooltip = 'Lighting - brightens the whole world\nPointLight - a light that follows your character'
    })
end)
