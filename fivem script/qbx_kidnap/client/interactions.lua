local hasOxTarget = GetResourceState('ox_target') == 'started'
local oxTarget = hasOxTarget and exports['ox_target'] or nil

if not hasOxTarget then
    print('[QB Kidnap] ox_target not found. Falling back to key prompts.')
end

Mission = Mission or {}
Mission.targetHandles = Mission.targetHandles or {}
Mission.fallbackThreads = Mission.fallbackThreads or {}

local function removeHandle(key)
    if not Mission.targetHandles then return end
    local handle = Mission.targetHandles[key]
    if handle and hasOxTarget then
        pcall(function()
            oxTarget:removeLocalEntity(handle)
        end)
    end
    Mission.targetHandles[key] = nil
end

function Mission.RemoveInteractionHandle(key)
    removeHandle(key)
end

function Mission.ClearInteractionHandles()
    if not Mission.targetHandles then return end
    for key in pairs(Mission.targetHandles) do
        removeHandle(key)
    end
end

local function registerFixerFallback(ped)
    if Mission.fallbackThreads.fixer then return end
    Mission.fallbackThreads.fixer = true

    CreateThread(function()
        local range = 2.0
        while DoesEntityExist(ped) do
            local coords = GetEntityCoords(ped)
            local player = PlayerPedId()
            local pCoords = GetEntityCoords(player)
            local dist = #(coords - pCoords)

            if dist < range then
                local label
                if Mission.active and Mission.stage == 'return' then
                    label = '[E] Deliver footage'
                elseif Mission.active then
                    label = 'Fixer is busy...'
                else
                    label = '[E] Request work'
                end

                DrawText3D(coords.x, coords.y, coords.z + 1.0, label)

                if not Mission.active and IsControlJustReleased(0, 38) then
                    TriggerServerEvent('qbx_kidnap:server:RequestMission')
                    Wait(500)
                elseif Mission.active and Mission.stage == 'return' and IsControlJustReleased(0, 38) then
                    Mission:DeliverFootage()
                    Wait(500)
                end
            end
            Wait(0)
        end

        Mission.fallbackThreads.fixer = nil
    end)
end

local function registerVictimFallback(ped)
    if Mission.fallbackThreads.victim then return end
    Mission.fallbackThreads.victim = true

    CreateThread(function()
        while Mission.active and DoesEntityExist(ped) do
            local player = PlayerPedId()
            local coords = GetEntityCoords(player)
            local targetCoords = GetEntityCoords(ped)
            local dist = #(coords - targetCoords)
            if Mission.stage == 'locate' and dist < 2.0 then
                DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + 1.0, '[E] Bag target')
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent('qbx_kidnap:server:TryHeadbag', NetworkGetNetworkIdFromEntity(ped))
                    Wait(1000)
                end
            end
            Wait(0)
        end

        Mission.fallbackThreads.victim = nil
    end)
end

function Mission.RegisterFixerTarget(ped)
    removeHandle('fixer')

    if hasOxTarget and ped then
        Mission.targetHandles.fixer = oxTarget:addLocalEntity(ped, {
            {
                name = 'kidnap_request_job',
                icon = 'fa-solid fa-user-secret',
                label = Config.MissionGiver.targetLabel,
                distance = 2.0,
                canInteract = function(_, distance)
                    return distance <= 2.0 and not Mission.active
                end,
                onSelect = function()
                    TriggerServerEvent('qbx_kidnap:server:RequestMission')
                end
            },
            {
                name = 'kidnap_deliver_video',
                icon = 'fa-solid fa-video',
                label = 'Deliver Footage',
                distance = 2.0,
                canInteract = function(_, distance)
                    return distance <= 2.0 and Mission.active and Mission.stage == 'return'
                end,
                onSelect = function()
                    Mission:DeliverFootage()
                end
            }
        })
        return
    end

    registerFixerFallback(ped)
end

function Mission.RegisterVictimTarget(ped)
    removeHandle('victim')

    if hasOxTarget and ped then
        Mission.targetHandles.victim = oxTarget:addLocalEntity(ped, {
            {
                name = 'kidnap_bag_target',
                icon = 'fa-solid fa-mask',
                label = 'Bag Target',
                distance = 2.0,
                canInteract = function(entity, distance)
                    return distance <= 2.0 and Mission.active and Mission.stage == 'locate' and entity == Mission.targetPed
                end,
                onSelect = function(data)
                    local entity = data and data.entity or ped
                    TriggerServerEvent('qbx_kidnap:server:TryHeadbag', NetworkGetNetworkIdFromEntity(entity))
                end
            }
        })
        return
    end

    registerVictimFallback(ped)
end

RegisterNetEvent('qbx_kidnap:client:MissionDenied', function(msg)
    Mission.Notify(msg or 'Fixer has nothing for you right now.', 'error')
end)

RegisterNetEvent('qbx_kidnap:client:UseRecorder', function()
    if not Mission.active or Mission.stage ~= 'interrogate' then return end
    Mission:BeginInterrogationLoop()
end)

RegisterNetEvent('qbx_kidnap:client:HeadbagSuccess', function()
    TriggerEvent('qbx_kidnap:client:HeadbagTarget')
end)
