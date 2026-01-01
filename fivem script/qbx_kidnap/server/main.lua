local QBCore = exports['qb-core']:GetCoreObject()

local ActiveMissions = {}
local BusyTargets = {}
local Cooldowns = {}

local function debugPrint(...)
    if not Config.Debug then return end
    print('[QB Kidnap:Server]', ...)
end

local function getPlayer(source)
    return QBCore.Functions.GetPlayer(source)
end

local function canStartMission(src, player)
    if ActiveMissions[src] then
        TriggerClientEvent('qbx_kidnap:client:MissionDenied', src, 'Finish the job you already started.')
        return false
    end

    local cid = player.PlayerData.citizenid
    local last = Cooldowns[cid]
    if last and (os.time() - last) < Config.MissionGiver.cooldown then
        local remaining = Config.MissionGiver.cooldown - (os.time() - last)
        TriggerClientEvent('qbx_kidnap:client:MissionDenied', src, ('Come back in %s seconds.'):format(remaining))
        return false
    end

    return true
end

local function pickTarget()
    local available = {}
    for index, entry in ipairs(Config.KidnapTargets) do
        if not BusyTargets[index] then
            available[#available + 1] = { index = index, data = entry }
        end
    end

    if #available == 0 then return nil end
    local chosen = available[math.random(1, #available)]
    BusyTargets[chosen.index] = true
    return chosen.index, chosen.data
end

local function releaseTarget(index)
    if not index then return end
    BusyTargets[index] = nil
end

local function notifyPolice(coords)
    if not Config.Dispatch.enabled then return end
    if GetResourceState('qbx_dispatch') == 'started' then
        TriggerEvent('qbx_dispatch:server:notify', {
            code = Config.Dispatch.code,
            message = Config.Dispatch.message,
            coords = coords,
            jobFilter = Config.Dispatch.jobFilter,
            blip = Config.Dispatch.blip
        })
        return
    end

    if GetResourceState('ps-dispatch') == 'started' then
        exports['ps-dispatch']:CustomAlert({
            coords = vec3(coords.x, coords.y, coords.z),
            code = Config.Dispatch.code,
            message = Config.Dispatch.message,
            radius = 35.0,
            sprite = Config.Dispatch.blip.sprite,
            color = Config.Dispatch.blip.color
        })
        return
    end

    debugPrint('Dispatch resource not found, skipping alert')
end

local function serialiseVector4(vec)
    return { x = vec.x, y = vec.y, z = vec.z, w = vec.w }
end

local function serialiseTarget(target)
    return {
        spawn = serialiseVector4(target.spawn),
        vehicleSpawn = serialiseVector4(target.vehicleSpawn),
        chair = serialiseVector4(target.chair),
        dropoff = serialiseVector4(target.dropoff),
        model = target.model
    }
end

RegisterNetEvent('qbx_kidnap:server:RequestMission', function()
    local src = source
    local player = getPlayer(src)
    if not player then return end

    if not canStartMission(src, player) then return end

    local index, target = pickTarget()
    if not index then
        TriggerClientEvent('qbx_kidnap:client:MissionDenied', src, 'No work available.')
        return
    end

    local headbag = player.Functions.GetItemByName(Config.RequiredItems.headbag)
    if not headbag or headbag.amount <= 0 then
        TriggerClientEvent('qbx_kidnap:client:MissionDenied', src, 'Bring a headbag before you ask for work.')
        releaseTarget(index)
        return
    end

    local recorder = player.Functions.GetItemByName(Config.RequiredItems.recorder)
    if not recorder or recorder.amount <= 0 then
        TriggerClientEvent('qbx_kidnap:client:MissionDenied', src, 'You need recording equipment for this job.')
        releaseTarget(index)
        return
    end

    local mission = {
        index = index,
        stage = 'locate',
        target = serialiseTarget(target),
        started = os.time()
    }

    ActiveMissions[src] = mission
    Cooldowns[player.PlayerData.citizenid] = os.time()

    TriggerClientEvent('qbx_kidnap:client:StartMission', src, mission)
end)

RegisterNetEvent('qbx_kidnap:server:Dispatch', function(coords)
    if math.random(100) <= Config.PoliceCallChance then
        notifyPolice(coords)
    end
end)

RegisterNetEvent('qbx_kidnap:server:TryHeadbag', function(netId)
    local src = source
    local mission = ActiveMissions[src]
    if not mission or mission.stage ~= 'locate' then return end

    local player = getPlayer(src)
    if not player then return end

    local invItem = player.Functions.GetItemByName(Config.RequiredItems.headbag)
    if not invItem then
        TriggerClientEvent('qbx_kidnap:client:MissionDenied', src, 'You need a headbag to do that.')
        return
    end

    if invItem.amount <= 0 then
        TriggerClientEvent('qbx_kidnap:client:MissionDenied', src, 'You ran out of bags.')
        return
    end

    player.Functions.RemoveItem(Config.RequiredItems.headbag, 1)
    if QBCore.Shared and QBCore.Shared.Items and QBCore.Shared.Items[Config.RequiredItems.headbag] then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.RequiredItems.headbag], 'remove')
    end

    mission.stage = 'transport'
    TriggerClientEvent('qbx_kidnap:client:HeadbagSuccess', src)
end)

RegisterNetEvent('qbx_kidnap:server:FinalizeRecording', function()
    local src = source
    local mission = ActiveMissions[src]
    if not mission then return end

    mission.stage = 'return'
    TriggerClientEvent('qbx_kidnap:client:RecordingComplete', src)
end)

RegisterNetEvent('qbx_kidnap:server:DeliverFootage', function()
    local src = source
    local mission = ActiveMissions[src]
    if not mission or mission.stage ~= 'return' then return end

    local player = getPlayer(src)
    if not player then return end

    local reward = Config.Reward
    if reward.money then
        player.Functions.AddMoney(reward.money.account, reward.money.amount, 'kidnap-mission')
    end

    if reward.items then
        for _, item in ipairs(reward.items) do
            player.Functions.AddItem(item.name, item.count or 1)
            if QBCore.Shared and QBCore.Shared.Items and QBCore.Shared.Items[item.name] then
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item.name], 'add')
            end
        end
    end

    TriggerClientEvent('qbx_kidnap:client:CompleteMission', src)
    releaseTarget(mission.index)
    ActiveMissions[src] = nil
end)

RegisterNetEvent('qbx_kidnap:server:Fail', function()
    local src = source
    local mission = ActiveMissions[src]
    if not mission then return end
    releaseTarget(mission.index)
    ActiveMissions[src] = nil
end)

RegisterNetEvent('qbx_kidnap:server:Cleanup', function()
    local src = source
    local mission = ActiveMissions[src]
    if not mission then return end
    releaseTarget(mission.index)
    ActiveMissions[src] = nil
end)

AddEventHandler('playerDropped', function()
    local src = source
    local mission = ActiveMissions[src]
    if mission then
        releaseTarget(mission.index)
        ActiveMissions[src] = nil
    end
end)
