local QBCore = exports['qb-core']:GetCoreObject()

Mission = Mission or {}

local missionGiverPed
local missionBlip

local function debugPrint(...)
    if not Config.Debug then return end
    print('[QB Kidnap]', ...)
end

local function loadModel(model)
    if type(model) == 'string' then model = joaat(model) end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    return model
end

local function setupMissionGiver()
    local data = Config.MissionGiver
    if missionGiverPed and DoesEntityExist(missionGiverPed) then
        return
    end

    local model = loadModel(data.model)
    missionGiverPed = CreatePed(0, model, data.coords.x, data.coords.y, data.coords.z - 1.0, data.coords.w, false, true)
    SetEntityHeading(missionGiverPed, data.coords.w)
    FreezeEntityPosition(missionGiverPed, true)
    SetEntityInvincible(missionGiverPed, true)
    SetBlockingOfNonTemporaryEvents(missionGiverPed, true)

    if data.scenario then
        TaskStartScenarioInPlace(missionGiverPed, data.scenario, 0, true)
    end

    if Config.Blips.missionStart.enabled then
        missionBlip = AddBlipForEntity(missionGiverPed)
        SetBlipSprite(missionBlip, Config.Blips.missionStart.sprite)
        SetBlipColour(missionBlip, Config.Blips.missionStart.color)
        SetBlipScale(missionBlip, Config.Blips.missionStart.scale)
        SetBlipAsShortRange(missionBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Blips.missionStart.text)
        EndTextCommandSetBlipName(missionBlip)
    end

    Mission.RegisterFixerTarget(missionGiverPed)
    debugPrint('Mission giver spawned')
end

local function cleanupMissionGiver()
    if missionGiverPed and DoesEntityExist(missionGiverPed) then
        DeletePed(missionGiverPed)
        missionGiverPed = nil
    end
    if Mission.RemoveInteractionHandle then
        Mission.RemoveInteractionHandle('fixer')
    end

    if missionBlip and DoesBlipExist(missionBlip) then
        RemoveBlip(missionBlip)
        missionBlip = nil
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CreateThread(setupMissionGiver)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Mission:Reset(true)
    cleanupMissionGiver()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateThread(setupMissionGiver)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Mission:Reset(true)
    cleanupMissionGiver()
end)

RegisterNetEvent('qbx_kidnap:client:StartMission', function(missionData)
    Mission:Start(missionData)
end)

RegisterNetEvent('qbx_kidnap:client:AbortMission', function(reason)
    Mission:Fail(reason or 'Mission aborted')
end)

RegisterNetEvent('qbx_kidnap:client:CompleteMission', function()
    Mission:Complete()
end)

exports('HasActiveMission', function()
    return Mission.active
end)
