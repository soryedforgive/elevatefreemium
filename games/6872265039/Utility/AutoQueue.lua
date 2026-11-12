run(function()
    local AutoQueue
    local Mode
    local Resume
    local Delay
    local Notify

    local STATE_FILE = 'ElevateV4/profiles/autowin.json'

    local function readState()
        if not isfile or not isfile(STATE_FILE) then return nil end
        local ok, data = pcall(function()
            return httpService:JSONDecode(readfile(STATE_FILE))
        end)
        if ok and type(data) == 'table' then return data end
        return nil
    end

    local function queueList()
        local list = {'From AutoWin', 'Random'}
        pcall(function()
            local ids = {}
            for id, meta in bedwars.QueueMeta do
                if not meta.disabled and not meta.voiceChatOnly then
                    table.insert(ids, id)
                end
            end
            table.sort(ids)
            for _, id in ipairs(ids) do
                table.insert(list, id)
            end
        end)
        return list
    end

    local function randomMode()
        local modes = {}
        pcall(function()
            for id, meta in bedwars.QueueMeta do
                if not meta.disabled and not meta.voiceChatOnly and not meta.rankCategory then
                    table.insert(modes, id)
                end
            end
        end)
        if #modes == 0 then return nil end
        return modes[math.random(1, #modes)]
    end

    local function resolveMode()
        local wanted = Mode.Value
        if wanted == 'From AutoWin' then
            local state = readState()
            wanted = state and state.queue or 'Random'
            if wanted == 'Current' then
                wanted = (state and state.fallback) or 'Random'
            end
        end
        if wanted == 'Random' or wanted == nil then
            return randomMode()
        end
        return wanted
    end

    local function canQueue()
        local ok, allowed = pcall(function()
            local state = bedwars.Store:getState()
            if state.Game and state.Game.customMatch then return false end
            if not state.Party or not state.Party.leader then return false end
            if state.Party.leader.userId ~= lplr.UserId then return false end
            return state.Party.queueState == 0
        end)
        return ok and allowed
    end

    AutoQueue = vape.Categories.Utility:CreateModule({
        Name = 'AutoQueue',
        Function = function(callback)
            if callback then
                AutoQueue:Clean(task.spawn(function()
                    task.wait(Delay.Value)
                    while AutoQueue.Enabled do
                        if canQueue() then
                            local mode = resolveMode()
                            if mode then
                                if Notify.Enabled then
                                    notif('AutoQueue', 'Queueing for '..tostring(mode), 4)
                                end
                                pcall(function()
                                    bedwars.QueueController:joinQueue(mode)
                                end)
                                task.wait(8)
                            else
                                task.wait(2)
                            end
                        else
                            task.wait(2)
                        end
                    end
                end))
            end
        end,
        Tooltip = 'Queues for a match from the lobby'
    })
    Mode = AutoQueue:CreateDropdown({
        Name = 'Gamemode',
        List = queueList(),
        Tooltip = 'Which queue to join'
    })
    Delay = AutoQueue:CreateSlider({
        Name = 'Queue delay',
        Min = 1,
        Max = 30,
        Default = 5,
        Suffix = ' seconds',
        Tooltip = 'How long to wait in the lobby before queueing'
    })
    Resume = AutoQueue:CreateToggle({
        Name = 'Resume from AutoWin',
        Default = true,
        Tooltip = 'Keeps queueing if AutoWin was on when you left the match'
    })
    Notify = AutoQueue:CreateToggle({
        Name = 'Notifications',
        Default = true,
        Tooltip = 'Tells you which mode is being queued'
    })

    task.delay(6, function()
        if not Resume.Enabled or AutoQueue.Enabled then return end
        local state = readState()
        if state and state.enabled and state.resume then
            if Notify.Enabled then
                notif('AutoQueue', 'AutoWin was running - queueing the next match', 6)
            end
            AutoQueue:Toggle()
        end
    end)
end)
