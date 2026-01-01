local QBCore = exports['qb-core']:GetCoreObject()

local KidnapSessions = {}
local DriverSessions = {}
local SpawnCooldowns = {}
local KidnapCooldowns = {}

local function notifyPlayer(src, message, nType, duration)
    TriggerClientEvent('qb_vehiclekidnap:client:Notify', src, message, nType, duration)
end

local function hasCooldown(cooldowns, key, duration)
    local last = cooldowns[key]
    if not last then return false end
    return (os.time() - last) < duration
end

local function setCooldown(cooldowns, key)
    cooldowns[key] = os.time()
end

local function clearKidnap(driver, target)
    if target and KidnapSessions[target] then
        KidnapSessions[target] = nil
    end
    if driver and DriverSessions[driver] then
        DriverSessions[driver] = nil
    end
end

local function findClosestPlayer(sourcePed, sourceId)
    local players = QBCore.Functions.GetPlayers()
    local closestDist, closestPlayer
    local sourceCoords = GetEntityCoords(sourcePed)

    for i = 1, #players do
        local targetId = players[i]
        if targetId ~= sourceId then
            local targetPed = GetPlayerPed(targetId)
            if DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local dist = #(sourceCoords - targetCoords)
                if not closestDist or dist < closestDist then
                    closestDist = dist
                    closestPlayer = targetId
                end
            end
        end
    end

    return closestPlayer, closestDist
end

local function vehicleIsClear(coords, radius)
    local vehicles = GetAllVehicles()
    if not vehicles then return true end
    local origin = vector3(coords.x, coords.y, coords.z)

    for i = 1, #vehicles do
        local veh = vehicles[i]
        if DoesEntityExist(veh) then
            local vehCoords = GetEntityCoords(veh)
            if #(vehCoords - origin) <= radius then
                return false
            end
        end
    end

    return true
end

RegisterNetEvent('qb_vehiclekidnap:server:RequestVan', function()
    local src = source
    local ped = GetPlayerPed(src)
    if not DoesEntityExist(ped) then return end

    if hasCooldown(SpawnCooldowns, src, 60) then
        notifyPlayer(src, 'Let the supplier restock a van first.', 'error')
        return
    end

    local spawnCfg = Config.VehicleSpawn
    local coords = spawnCfg.coords

    if not vehicleIsClear(coords, spawnCfg.minClearance or 3.0) then
        notifyPlayer(src, 'Move the old van out of the way.', 'error')
        return
    end

    local vehicle = CreateVehicle(Config.VehicleHash, coords.x, coords.y, coords.z, coords.w, true, true)
    if not vehicle or vehicle == 0 then
        notifyPlayer(src, 'Unable to source a van right now.', 'error')
        return
    end

    SetVehicleOnGroundProperly(vehicle)
    SetVehicleColours(vehicle, 0, 0)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleNumberPlateText(vehicle, ('KID%s'):format(math.random(1111, 9999)))

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerClientEvent('qb_vehiclekidnap:client:ReceiveVan', src, netId, GetVehicleNumberPlateText(vehicle))

    setCooldown(SpawnCooldowns, src)
end)

QBCore.Commands.Add('kidnap', 'Kidnap nearest player into your van trunk', {}, false, function(source)
    local driverPed = GetPlayerPed(source)
    if not DoesEntityExist(driverPed) then return end

    if hasCooldown(KidnapCooldowns, source, Config.KidnapCooldown) then
        notifyPlayer(source, Config.Messages.cooldown, 'error')
        return
    end

    local vehicle = GetVehiclePedIsIn(driverPed, false)
    if vehicle == 0 then
        notifyPlayer(source, Config.Messages.needVehicle, 'error')
        return
    end

    if GetPedInVehicleSeat(vehicle, -1) ~= driverPed then
        notifyPlayer(source, Config.Messages.needVehicle, 'error')
        return
    end

    if GetEntityModel(vehicle) ~= Config.VehicleHash then
        notifyPlayer(source, Config.Messages.needVehicle, 'error')
        return
    end

    local vehicleNet = NetworkGetNetworkIdFromEntity(vehicle)

    for targetId, session in pairs(KidnapSessions) do
        if session.vehicle == vehicleNet then
            notifyPlayer(source, Config.Messages.trunkFull, 'error')
            return
        end
    end

    local targetId, distance = findClosestPlayer(driverPed, source)
    if not targetId or not distance or distance > Config.KidnapRange then
        notifyPlayer(source, Config.Messages.noTarget, 'error')
        return
    end

    if KidnapSessions[targetId] then
        notifyPlayer(source, Config.Messages.alreadyKidnapping, 'error')
        return
    end

    local targetPed = GetPlayerPed(targetId)
    if not DoesEntityExist(targetPed) then
        notifyPlayer(source, Config.Messages.noTarget, 'error')
        return
    end

    if GetVehiclePedIsIn(targetPed, false) ~= 0 then
        notifyPlayer(source, Config.Messages.targetOccupied, 'error')
        return
    end

    KidnapSessions[targetId] = {
        driver = source,
        vehicle = vehicleNet,
        stage = 'pending'
    }
    DriverSessions[source] = targetId

    setCooldown(KidnapCooldowns, source)

    notifyPlayer(source, Config.Messages.kidnapping, 'inform')
    TriggerClientEvent('qb_vehiclekidnap:client:BeginKidnap', source, targetId, vehicleNet)
end)

RegisterNetEvent('qb_vehiclekidnap:server:FinalizeKidnap', function(targetId, vehicleNet)
    local src = source
    local session = KidnapSessions[targetId]
    if not session or session.driver ~= src then
        return
    end

    if session.vehicle ~= vehicleNet then
        notifyPlayer(src, 'The target slipped away.', 'error')
        clearKidnap(src, targetId)
        TriggerClientEvent('qb_vehiclekidnap:client:CleanupHelper', src)
        return
    end

    session.stage = 'active'
    TriggerClientEvent('qb_vehiclekidnap:client:GetKidnapped', targetId, vehicleNet)
    SetTimeout(5000, function()
        TriggerClientEvent('qb_vehiclekidnap:client:CleanupHelper', src)
    end)
end)

local function releaseTarget(driver, targetId, notify)
    if not driver then return end
    local session = targetId and KidnapSessions[targetId]
    if not session or session.driver ~= driver then
        notifyPlayer(driver, 'No captive to release.', 'error')
        return
    end

    TriggerClientEvent('qb_vehiclekidnap:client:Release', targetId)
    TriggerClientEvent('qb_vehiclekidnap:client:CleanupHelper', driver)
    clearKidnap(driver, targetId)

    if notify then
        notifyPlayer(driver, 'You released the captive.', 'success')
    end
end

QBCore.Commands.Add(Config.ReleaseCommand, 'Release the person in your trunk', {}, false, function(source)
    local targetId = DriverSessions[source]
    if not targetId then
        notifyPlayer(source, 'No captive to release.', 'error')
        return
    end
    releaseTarget(source, targetId, true)
end)

RegisterNetEvent('qb_vehiclekidnap:server:FailKidnap', function()
    local src = source
    local session = KidnapSessions[src]
    if not session then return end

    local driver = session.driver
    if driver then
        notifyPlayer(driver, 'Kidnapping failed.', 'error')
        TriggerClientEvent('qb_vehiclekidnap:client:CleanupHelper', driver)
    end
    clearKidnap(driver, src)
end)

AddEventHandler('playerDropped', function()
    local src = source

    if DriverSessions[src] then
        local targetId = DriverSessions[src]
        TriggerClientEvent('qb_vehiclekidnap:client:Release', targetId)
        TriggerClientEvent('qb_vehiclekidnap:client:CleanupHelper', src)
        clearKidnap(src, targetId)
    end

    if KidnapSessions[src] then
        local driver = KidnapSessions[src].driver
        if driver then
            notifyPlayer(driver, 'Your captive vanished.', 'error')
            TriggerClientEvent('qb_vehiclekidnap:client:CleanupHelper', driver)
            clearKidnap(driver, src)
        end
    end
end)
