local QBCore = exports['qb-core']:GetCoreObject()

local ActiveSessions = {}
local PlayerSession = {}

local function sendCancel(sessionId, reason)
    local session = ActiveSessions[sessionId]
    if not session then return end

    local payload = {
        session = sessionId,
        action = session.action,
        reason = reason or 'cancelled'
    }

    if session.mode == 'chair' then
        if session.attacker then
            TriggerClientEvent('qb-torture:client:release', session.attacker, payload)
        end
        if session.target then
            TriggerClientEvent('qb-torture:client:release', session.target, payload)
        end
    else
        if session.attacker then
            TriggerClientEvent('qb-torture:client:stop', session.attacker, payload)
        end
        if session.target then
            TriggerClientEvent('qb-torture:client:stop', session.target, payload)
        end
    end
end

local function cleanupSession(sessionId)
    local session = ActiveSessions[sessionId]
    if not session then return end

    if session.attacker then
        PlayerSession[session.attacker] = nil
    end

    if session.target then
        PlayerSession[session.target] = nil
    end

    ActiveSessions[sessionId] = nil
end

local function isAuthorised(player)
    if not player then return false, 'missing_player' end

    local job = player.PlayerData.job
    if not job then return false, 'no_job' end

    local threshold = Config.AllowedJobs[job.name]
    if not threshold then return false, 'job_not_allowed' end

    local grade = job.grade and (job.grade.level or job.grade)
    grade = grade or 0

    if grade < threshold then
        return false, 'job_grade_low'
    end

    if Config.RequireItem.enable then
        local item = player.Functions.GetItemByName(Config.RequireItem.name)
        if not item or item.amount < Config.RequireItem.amount then
            return false, 'missing_item'
        end
    end

    return true
end

QBCore.Commands.Add('torture', 'Place a nearby player in the interrogation chair.', {
    { name = 'id', help = 'Server ID of the player' }
}, false, function(source, args)
    local src = source
    local targetId = tonumber(args[1])

    if not targetId then
        TriggerClientEvent('qb-torture:client:notify', src, 'Usage: /torture [ID]', 'error')
        return
    end

    if targetId == src then
        TriggerClientEvent('qb-torture:client:notify', src, 'You cannot target yourself.', 'error')
        return
    end

    local attacker = QBCore.Functions.GetPlayer(src)
    local victim = QBCore.Functions.GetPlayer(targetId)

    if not victim then
        TriggerClientEvent('qb-torture:client:notify', src, 'Target unavailable.', 'error')
        return
    end

    if PlayerSession[src] then
        TriggerClientEvent('qb-torture:client:notify', src, 'You are already busy.', 'error')
        return
    end

    if PlayerSession[targetId] then
        TriggerClientEvent('qb-torture:client:notify', src, 'Target is already restrained.', 'error')
        return
    end

    local authorised, reason = isAuthorised(attacker)
    if not authorised then
        if reason == 'missing_item' then
            TriggerClientEvent('qb-torture:client:notify', src, ('You need %s.'):format(Config.RequireItem.name), 'error')
        else
            TriggerClientEvent('qb-torture:client:notify', src, 'You are not authorised to do that.', 'error')
        end
        return
    end

    local attackerPed = GetPlayerPed(src)
    local victimPed = GetPlayerPed(targetId)

    if attackerPed == 0 or victimPed == 0 then
        TriggerClientEvent('qb-torture:client:notify', src, 'Target unavailable.', 'error')
        return
    end

    local attackerCoords = GetEntityCoords(attackerPed)
    local victimCoords = GetEntityCoords(victimPed)

    local maxDistance = (Config.Chair and Config.Chair.distance) or 3.0
    if #(attackerCoords - victimCoords) > maxDistance then
        TriggerClientEvent('qb-torture:client:notify', src, 'Target is too far away.', 'error')
        return
    end

    local sessionId = ('chair:%d:%d'):format(src, os.time())

    ActiveSessions[sessionId] = {
        attacker = src,
        target = targetId,
        action = 'chair',
        mode = 'chair'
    }

    PlayerSession[src] = sessionId
    PlayerSession[targetId] = sessionId

    if Config.RequireItem.enable and Config.RequireItem.removeOnUse then
        attacker.Functions.RemoveItem(Config.RequireItem.name, Config.RequireItem.amount)
    end

    TriggerClientEvent('qb-torture:client:prepareChair', src, {
        session = sessionId
    })

    TriggerClientEvent('qb-torture:client:notify', targetId, 'You are being restrained.', 'error')
end)

QBCore.Commands.Add('untorture', 'Release the current interrogation chair session.', {}, false, function(source)
    local src = source
    local sessionId = PlayerSession[src]
    if not sessionId then
        TriggerClientEvent('qb-torture:client:notify', src, 'No active interrogation to release.', 'error')
        return
    end

    local session = ActiveSessions[sessionId]
    if not session or session.mode ~= 'chair' or session.attacker ~= src then
        TriggerClientEvent('qb-torture:client:notify', src, 'You do not control a chair session.', 'error')
        return
    end

    sendCancel(sessionId, 'released')
    cleanupSession(sessionId)
end)

RegisterNetEvent('qb-torture:server:chairReady', function(sessionId, netId, seat, heading)
    local src = source
    local session = ActiveSessions[sessionId]
    if not session or session.mode ~= 'chair' then return end

    if session.attacker ~= src then
        return
    end

    if not netId or netId == 0 or type(seat) ~= 'table' or seat.x == nil or seat.y == nil or seat.z == nil then
        TriggerClientEvent('qb-torture:client:notify', src, 'Chair setup failed.', 'error')
        sendCancel(sessionId, 'chair_failed')
        cleanupSession(sessionId)
        return
    end

    local victim = QBCore.Functions.GetPlayer(session.target)
    if not victim then
        TriggerClientEvent('qb-torture:client:notify', src, 'Target unavailable.', 'error')
        sendCancel(sessionId, 'player_left')
        cleanupSession(sessionId)
        return
    end

    local seatData = {
        x = seat.x,
        y = seat.y,
        z = seat.z
    }

    session.chair = {
        netId = netId,
        seat = seatData,
        heading = heading or 0.0
    }

    TriggerClientEvent('qb-torture:client:seatVictim', session.target, {
        session = sessionId,
        netId = netId,
        seat = seatData,
        heading = heading
    })
end)

RegisterNetEvent('qb-torture:server:start', function(targetId, action)
    local src = source
    local attacker = QBCore.Functions.GetPlayer(src)
    local victim = QBCore.Functions.GetPlayer(targetId)

    if src == targetId or not victim then
        TriggerClientEvent('qb-torture:client:notify', src, 'Target unavailable.', 'error')
        return
    end

    if PlayerSession[src] or PlayerSession[targetId] then
        TriggerClientEvent('qb-torture:client:notify', src, 'Someone is already busy.', 'error')
        return
    end

    local actionData = Config.Actions[action]
    if not actionData then
        TriggerClientEvent('qb-torture:client:notify', src, 'Invalid action selected.', 'error')
        return
    end

    local authorised, reason = isAuthorised(attacker)
    if not authorised then
        if reason == 'missing_item' then
            TriggerClientEvent('qb-torture:client:notify', src, ('You need %s.'):format(Config.RequireItem.name), 'error')
        else
            TriggerClientEvent('qb-torture:client:notify', src, 'You are not authorised to do that.', 'error')
        end
        return
    end

    local sessionId = ('%d:%d'):format(src, os.time())

    ActiveSessions[sessionId] = {
        attacker = src,
        target = targetId,
        action = action
    }

    PlayerSession[src] = sessionId
    PlayerSession[targetId] = sessionId

    if Config.RequireItem.enable and Config.RequireItem.removeOnUse then
        attacker.Functions.RemoveItem(Config.RequireItem.name, Config.RequireItem.amount)
    end

    TriggerClientEvent('qb-torture:client:start', src, {
        session = sessionId,
        action = action,
        partner = targetId,
        role = 'attacker'
    })

    TriggerClientEvent('qb-torture:client:start', targetId, {
        session = sessionId,
        action = action,
        partner = src,
        role = 'victim'
    })
end)

RegisterNetEvent('qb-torture:server:complete', function(sessionId)
    local src = source
    local session = ActiveSessions[sessionId]
    if not session then return end

    if session.mode == 'chair' then
        return
    end

    if session.attacker ~= src then
        return
    end

    TriggerClientEvent('qb-torture:client:complete', session.attacker, {
        session = sessionId,
        action = session.action,
        role = 'attacker'
    })

    TriggerClientEvent('qb-torture:client:complete', session.target, {
        session = sessionId,
        action = session.action,
        role = 'victim'
    })

    cleanupSession(sessionId)
end)

RegisterNetEvent('qb-torture:server:cancel', function(sessionId, reason)
    local src = source
    local session = ActiveSessions[sessionId]
    if not session then return end

    if src ~= 0 and session.attacker ~= src and session.target ~= src then
        return
    end

    sendCancel(sessionId, reason)
    cleanupSession(sessionId)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local sessionId = PlayerSession[src]
    if not sessionId then return end
    local session = ActiveSessions[sessionId]
    if not session then return end

    sendCancel(sessionId, 'player_left')
    cleanupSession(sessionId)
end)
