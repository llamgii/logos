local QBCore = exports['qb-core']:GetCoreObject()

local supplierPed, supplierBlip
local helperPed
local kidnappedState = {
    active = false,
    vehicle = nil,
    net = nil,
    originalHeading = nil
}

local hasOxTarget = GetResourceState('ox_target') == 'started'

local function loadModel(model)
    if type(model) == 'string' then model = joaat(model) end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    return model
end

local function loadAnimation(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

local function ensureSupplierPed()
    if supplierPed and DoesEntityExist(supplierPed) then return end
    local cfg = Config.SupplierPed
    local model = loadModel(cfg.model)
    local coords = cfg.coords

    supplierPed = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetBlockingOfNonTemporaryEvents(supplierPed, true)
    SetEntityInvincible(supplierPed, true)
    FreezeEntityPosition(supplierPed, true)

    if cfg.scenario then
        TaskStartScenarioInPlace(supplierPed, cfg.scenario, 0, true)
    end

    if cfg.blip and cfg.blip.enabled then
        supplierBlip = AddBlipForEntity(supplierPed)
        SetBlipSprite(supplierBlip, cfg.blip.sprite)
        SetBlipColour(supplierBlip, cfg.blip.colour)
        SetBlipScale(supplierBlip, cfg.blip.scale)
        SetBlipAsShortRange(supplierBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(cfg.blip.text)
        EndTextCommandSetBlipName(supplierBlip)
    end

    if hasOxTarget then
        exports.ox_target:addLocalEntity(supplierPed, {
            {
                name = 'kidnap_supplier_request',
                icon = 'fa-solid fa-van-shuttle',
                label = cfg.oxTargetLabel,
                distance = 2.0,
                onSelect = function()
                    TriggerServerEvent('qb_vehiclekidnap:server:RequestVan')
                end
            }
        })
    else
        lib.print.error('[qb_vehiclekidnap] ox_target not running. Supplier uses fallback prompt.')
        CreateThread(function()
            while DoesEntityExist(supplierPed) do
                local playerPed = PlayerPedId()
                local coordsPed = GetEntityCoords(playerPed)
                local pedCoords = GetEntityCoords(supplierPed)
                local dist = #(coordsPed - pedCoords)
                if dist < 2.0 then
                    lib.showTextUI('[E] ' .. Config.SupplierPed.oxTargetLabel)
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('qb_vehiclekidnap:server:RequestVan')
                        Wait(1000)
                    end
                else
                    lib.hideTextUI()
                end
                Wait(0)
            end
            lib.hideTextUI()
        end)
    end
end

local function cleanupSupplierPed()
    if supplierBlip and DoesBlipExist(supplierBlip) then
        RemoveBlip(supplierBlip)
        supplierBlip = nil
    end

    if supplierPed and DoesEntityExist(supplierPed) then
        DeletePed(supplierPed)
        supplierPed = nil
    end
end

local function notify(message, nType, duration)
    lib.notify({
        title = 'Kidnapper',
        description = message,
        type = nType or 'inform',
        duration = duration or 5000
    })
end

RegisterNetEvent('qb_vehiclekidnap:client:Notify', function(message, nType, duration)
    notify(message, nType, duration)
end)

local function spawnHelper(vehicle, targetId)
    if helperPed and DoesEntityExist(helperPed) then
        DeletePed(helperPed)
        helperPed = nil
    end

    local model = loadModel(Config.HelperPedModel)
    local vehCoords = GetEntityCoords(vehicle)
    local spawnCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -2.5, 0.0)

    helperPed = CreatePed(4, model, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(vehicle), true, true)
    SetEntityAsMissionEntity(helperPed, true, true)
    SetPedFleeAttributes(helperPed, 0, false)
    SetPedCombatAttributes(helperPed, 46, true)
    SetPedCanRagdoll(helperPed, false)
    SetPedKeepTask(helperPed, true)

    local helperAnim = Config.Animations.helper
    if helperAnim and helperAnim.dict then
        loadAnimation(helperAnim.dict)
        TaskPlayAnim(helperPed, helperAnim.dict, helperAnim.anim or 'idle', 8.0, -8.0, -1, 1, 0.0, false, false, false)
    end

    CreateThread(function()
        local playerId = GetPlayerFromServerId(targetId)
        local targetPed = playerId and GetPlayerPed(playerId) or 0
        local attempts = 0

        while helperPed and DoesEntityExist(helperPed) and attempts < 40 do
            if targetPed ~= 0 and DoesEntityExist(targetPed) then
                TaskGoToEntity(helperPed, targetPed, -1, Config.HelperApproachDistance, 1.0, 0, 0)
            else
                TaskGoStraightToCoord(helperPed, vehCoords.x, vehCoords.y - 2.5, vehCoords.z, 1.0, -1, GetEntityHeading(vehicle), 0.0)
            end
            Wait(500)
            attempts = attempts + 1
        end
    end)
end

local function cleanupHelper()
    if helperPed and DoesEntityExist(helperPed) then
        DeletePed(helperPed)
    end
    helperPed = nil
end

local function disableControlsLoop()
    CreateThread(function()
        while kidnappedState.active do
            DisableControlAction(0, 75, true) -- exit vehicle
            DisableControlAction(0, 23, true) -- enter vehicle
            DisableControlAction(0, 24, true) -- attack
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 21, true) -- sprint
            DisableControlAction(0, 22, true) -- jump
            Wait(0)
        end
    end)
end

local function attachToTrunk(vehicle)
    local ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    SetEntityCollision(ped, false, true)
    FreezeEntityPosition(ped, true)

    local offset = Config.TrunkAttach.offset
    local rot = Config.TrunkAttach.rotation
    local bone = Config.TrunkAttach.bone

    AttachEntityToEntity(ped, vehicle, bone, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, false, false, false, false, 2, true)
    kidnappedState.vehicle = vehicle
    kidnappedState.net = NetworkGetNetworkIdFromEntity(vehicle)
    kidnappedState.originalHeading = GetEntityHeading(ped)
    kidnappedState.active = true

    disableControlsLoop()
end

local function detachFromTrunk()
    if not kidnappedState.active then return end
    local ped = PlayerPedId()
    if IsEntityAttached(ped) then
        DetachEntity(ped, true, true)
    end

    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)

    local vehicle = kidnappedState.vehicle
    if vehicle and DoesEntityExist(vehicle) then
        local releaseCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -4.0, 0.0)
        SetEntityCoords(ped, releaseCoords.x, releaseCoords.y, releaseCoords.z)
        SetEntityHeading(ped, kidnappedState.originalHeading or GetEntityHeading(vehicle))
    end

    kidnappedState = {
        active = false,
        vehicle = nil,
        net = nil,
        originalHeading = nil
    }
end

local function openTrunk(vehicle)
    SetVehicleDoorOpen(vehicle, 2, false, false)
    SetVehicleDoorOpen(vehicle, 3, false, false)
end

local function closeTrunk(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return end
    SetVehicleDoorShut(vehicle, 2, false)
    SetVehicleDoorShut(vehicle, 3, false)
end

RegisterNetEvent('qb_vehiclekidnap:client:ReceiveVan', function(netId, plate)
    notify(Config.Messages.gettingVan, 'inform', 3000)

    local timeout = 0
    local vehicle
    while timeout < 50 do
        vehicle = NetToVeh(netId)
        if DoesEntityExist(vehicle) then break end
        Wait(100)
        timeout = timeout + 1
    end

    if not vehicle or not DoesEntityExist(vehicle) then
        notify('Something went wrong with the van spawn.', 'error')
        return
    end

    SetVehicleOnGroundProperly(vehicle)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleRadioEnabled(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleNumberPlateText(vehicle, plate)

    local ped = PlayerPedId()
    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    if GetResourceState('vehiclekeys') == 'started' or GetResourceState('qb-vehiclekeys') == 'started' then
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
        TriggerEvent('qb-vehiclekeys:client:AddKeys', plate)
    end

    notify(Config.Messages.vanReady, 'success', 4000)
end)

RegisterNetEvent('qb_vehiclekidnap:client:BeginKidnap', function(targetId, vehicleNet)
    local vehicle = NetToVeh(vehicleNet)
    if not vehicle or not DoesEntityExist(vehicle) then
        notify('Vehicle not found for kidnapping.', 'error')
        return
    end

    spawnHelper(vehicle, targetId)
    openTrunk(vehicle)

    if Config.Progress and lib and lib.progressCircle then
        lib.progressCircle({
            duration = Config.Progress.duration,
            label = Config.Progress.label,
            useWhileDead = false,
            canCancel = false,
            disable = {
                move = true,
                car = false,
                mouse = false,
                combat = true
            }
        })
    else
        Wait(Config.Progress.duration or 4000)
    end

    TriggerServerEvent('qb_vehiclekidnap:server:FinalizeKidnap', targetId, vehicleNet)
end)

RegisterNetEvent('qb_vehiclekidnap:client:GetKidnapped', function(vehicleNet)
    if kidnappedState.active then
        notify(Config.Messages.trunkFull, 'error')
        return
    end

    local vehicle = NetToVeh(vehicleNet)
    local attempts = 0
    while attempts < 40 and (not vehicle or not DoesEntityExist(vehicle)) do
        vehicle = NetToVeh(vehicleNet)
        attempts = attempts + 1
        Wait(100)
    end

    if not vehicle or not DoesEntityExist(vehicle) then
        notify('Lost track of the van.', 'error')
        TriggerServerEvent('qb_vehiclekidnap:server:FailKidnap')
        return
    end

    openTrunk(vehicle)

    local victimAnim = Config.Animations.victim
    if victimAnim and victimAnim.dict then
        loadAnimation(victimAnim.dict)
        TaskPlayAnim(PlayerPedId(), victimAnim.dict, victimAnim.anim or 'idle', 8.0, -8.0, -1, 33, 0.0, false, false, false)
    end

    attachToTrunk(vehicle)
    notify(Config.Messages.kidnapping, 'inform', 3500)
end)

RegisterNetEvent('qb_vehiclekidnap:client:Release', function()
    local vehicle = kidnappedState.vehicle
    detachFromTrunk()
    closeTrunk(vehicle)
    notify('You are free.', 'success', 3000)
end)

RegisterNetEvent('qb_vehiclekidnap:client:CleanupHelper', function()
    cleanupHelper()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    ensureSupplierPed()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    detachFromTrunk()
    cleanupHelper()
    cleanupSupplierPed()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', ensureSupplierPed)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', cleanupSupplierPed)
