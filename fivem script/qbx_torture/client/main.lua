local QBCore = exports['qb-core']:GetCoreObject()

local currentSession
local currentRole
local attachedProp
local startCoords

local chairEntities = {}

local PlayerData = {}

local function updatePlayerData()
    PlayerData = QBCore.Functions.GetPlayerData()
end

updatePlayerData()

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    updatePlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if not PlayerData then
        PlayerData = {}
    end
    PlayerData.job = job
end)

local function isAuthorised()
    local job = PlayerData and PlayerData.job
    if not job then return false end

    local threshold = Config.AllowedJobs[job.name]
    if not threshold then return false end

    local grade = job.grade and (job.grade.level or job.grade)
    grade = grade or 0

    return grade >= threshold
end

local function notify(description, nType)
    lib.notify({
        title = 'Interrogation',
        description = description,
        type = nType or 'inform'
    })
end

local function unloadAnimation(dict)
    if dict and HasAnimDictLoaded(dict) then
        RemoveAnimDict(dict)
    end
end

local function loadAnimation(dict)
    if not dict then return true end
    return lib.requestAnimDict(dict, 5000)
end

local function loadModel(model)
    if type(model) == 'string' then
        model = joaat(model)
    end
    return lib.requestModel(model, 5000) and model or nil
end

local function clearProp()
    if attachedProp and DoesEntityExist(attachedProp) then
        DeleteObject(attachedProp)
    end
    attachedProp = nil
end

local function attachPropToPed(ped, data)
    if not ped or not data then return end

    local model = loadModel(data.model)
    if not model then
        notify('Failed to load torture prop.', 'error')
        return
    end

    local coords = GetEntityCoords(ped)
    attachedProp = CreateObject(model, coords.x, coords.y, coords.z + 0.2, true, true, false)
    if not attachedProp then return end

    local boneIndex = GetPedBoneIndex(ped, data.bone or 0)
    local pos = data.pos or vec3(0.0, 0.0, 0.0)
    local rot = data.rot or vec3(0.0, 0.0, 0.0)

    AttachEntityToEntity(
        attachedProp,
        ped,
        boneIndex,
        pos.x, pos.y, pos.z,
        rot.x, rot.y, rot.z,
        false, false, false, false, 2, true
    )
end

local function deleteChair(sessionId)
    local chair = chairEntities[sessionId]
    if not chair then return end

    if chair.entity and DoesEntityExist(chair.entity) then
        DeleteObject(chair.entity)
    end

    chairEntities[sessionId] = nil
end

local function calculateOffsetPosition(coords, heading, offset)
    if not offset then
        return coords
    end

    local rad = math.rad(heading)
    local sinH = math.sin(rad)
    local cosH = math.cos(rad)

    local x = coords.x + (offset.x * cosH - offset.y * sinH)
    local y = coords.y + (offset.x * sinH + offset.y * cosH)
    local z = coords.z + offset.z

    return vec3(x, y, z)
end

local function spawnChairForSession(sessionId)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local chairCfg = Config.Chair or {}

    local placement = calculateOffsetPosition(coords, heading, chairCfg.offset or vec3(1.0, 0.0, 0.0))
    local foundGround, groundZ = GetGroundZFor_3dCoord(placement.x, placement.y, placement.z + 1.0, false)
    if foundGround then
        placement = vec3(placement.x, placement.y, groundZ)
    end

    local model = loadModel(chairCfg.model or `prop_chair_01a`)
    if not model then
        notify('Impossible de charger la chaise.', 'error')
        return
    end

    local chair = CreateObject(model, placement.x, placement.y, placement.z, true, true, false)
    if not chair or chair == 0 then
        notify('Creation de la chaise echouee.', 'error')
        return
    end

    local chairHeading = heading + 180.0

    SetEntityHeading(chair, chairHeading)
    PlaceObjectOnGroundProperly(chair)
    FreezeEntityPosition(chair, true)
    SetEntityInvincible(chair, true)

    local netId = NetworkGetNetworkIdFromEntity(chair)
    if netId == 0 then
        DeleteObject(chair)
        notify('Impossible de synchroniser la chaise.', 'error')
        return
    end

    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, false)

    chairEntities[sessionId] = {
        entity = chair,
        owner = true,
        heading = chairHeading
    }

    local seatOffset = chairCfg.seatOffset or vec3(0.0, 0.0, 0.0)
    local seatCoords = vec3(
        placement.x + seatOffset.x,
        placement.y + seatOffset.y,
        placement.z + seatOffset.z
    )

    return netId, seatCoords, chairHeading
end

local function playParticleEffect(effectData, ped)
    if not effectData or not ped then return end

    local coords = GetEntityCoords(ped)
    local offset = effectData.offset or vec3(0.0, 0.0, 0.0)
    local heading = GetEntityHeading(ped)

    if not lib.requestNamedPtfxAsset(effectData.asset) then return end
    UseParticleFxAssetNextCall(effectData.asset)
    local fx = StartParticleFxLoopedAtCoord(
        effectData.effect,
        coords.x + offset.x,
        coords.y + offset.y,
        coords.z + offset.z,
        0.0,
        0.0,
        heading,
        1.0,
        false,
        false,
        false,
        false
    )

    if fx ~= 0 then
        CreateThread(function()
            Wait(1500)
            StopParticleFxLooped(fx, false)
        end)
    end
end

local function cancelSession(reason, sessionId)
    local sid = sessionId or currentSession
    if sid then
        TriggerServerEvent('qb-torture:server:cancel', sid, reason or 'cancelled')
    end
end

local function resetState()
    local ped = PlayerPedId()

    ClearPedTasks(ped)
    clearProp()
    if currentSession then
        deleteChair(currentSession)
    end
    FreezeEntityPosition(ped, false)

    currentSession = nil
    currentRole = nil
    startCoords = nil
end

local function buildMenu(targetServerId)
    local options = {}
    for actionName, actionData in pairs(Config.Actions) do
        options[#options + 1] = {
            title = actionData.label or actionName,
            description = actionData.description,
            icon = actionData.icon,
            event = 'qb-torture:client:selectAction',
            args = {
                action = actionName,
                target = targetServerId
            }
        }
    end

    if #options == 0 then
        notify('No torture actions configured.', 'error')
        return
    end

    lib.registerContext({
        id = 'qb_torture_actions',
        title = 'Torture Actions',
        options = options
    })

    lib.showContext('qb_torture_actions')
end

local function validateTarget(entity)
    if not entity or entity == 0 then return false end
    if not isAuthorised() then return false end

    local player = NetworkGetPlayerIndexFromPed(entity)
    if player == -1 then return false end

    local serverId = GetPlayerServerId(player)
    if serverId == GetPlayerServerId(PlayerId()) then
        return false
    end

    return serverId
end

RegisterNetEvent('qb-torture:client:selectAction', function(data)
    if not data or not data.target or not data.action then return end
    if currentSession then
        notify('You are already busy.', 'error')
        return
    end

    TriggerServerEvent('qb-torture:server:start', data.target, data.action)
end)

RegisterNetEvent('qb-torture:client:notify', notify)

RegisterNetEvent('qb-torture:client:prepareChair', function(data)
    if not data or not data.session then return end
    if currentSession then
        cancelSession('busy', data.session)
        return
    end

    currentSession = data.session
    currentRole = 'attacker'

    local netId, seatCoords, heading = spawnChairForSession(data.session)
    if not netId or not seatCoords or not heading then
        cancelSession('chair_failed', data.session)
        return
    end

    local ped = PlayerPedId()
    local baton = joaat('weapon_nightstick')

    if not HasPedGotWeapon(ped, baton, false) then
        GiveWeaponToPed(ped, baton, 1, false, true)
    end

    SetCurrentPedWeapon(ped, baton, true)

    notify('Chaise installee. La cible va etre immobilisee.', 'inform')

    TriggerServerEvent('qb-torture:server:chairReady', data.session, netId, {
        x = seatCoords.x,
        y = seatCoords.y,
        z = seatCoords.z
    }, heading)
end)

RegisterNetEvent('qb-torture:client:seatVictim', function(data)
    if not data or not data.session or not data.netId or not data.seat then return end

    if currentSession and currentSession ~= data.session then
        cancelSession('busy', data.session)
        return
    end

    currentSession = data.session
    currentRole = 'victim'

    local ped = PlayerPedId()
    local seat = vec3(data.seat.x, data.seat.y, data.seat.z)
    local heading = data.heading or GetEntityHeading(ped)

    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, true)
    SetEntityCoordsNoOffset(ped, seat.x, seat.y, seat.z, false, false, false)
    SetEntityHeading(ped, heading)
    Wait(200)
    TaskStartScenarioAtPosition(ped, 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER', seat.x, seat.y, seat.z, heading, 0, true, true)

    startCoords = seat

    notify('Vous etes immobilise sur la chaise.', 'error')

    local sessionId = data.session
    CreateThread(function()
        while currentSession == sessionId do
            local currentCoords = GetEntityCoords(PlayerPedId())
            if #(currentCoords - seat) > 1.5 then
                cancelSession('victim_moved', sessionId)
                break
            end

            if not IsPedUsingScenario(PlayerPedId(), 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER') then
                TaskStartScenarioAtPosition(PlayerPedId(), 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER', seat.x, seat.y, seat.z, heading, 0, true, true)
            end

            Wait(2000)
        end
    end)
end)

RegisterNetEvent('qb-torture:client:release', function(data)
    local sessionId = data and data.session or currentSession
    if sessionId and chairEntities[sessionId] then
        deleteChair(sessionId)
    end

    if data and data.session and currentSession and data.session ~= currentSession then
        return
    end

    resetState()

    if data and data.reason == 'released' then
        notify('Interrogatoire termine.', 'inform')
    else
        notify('Sequence interrompue.', 'error')
    end
end)

RegisterNetEvent('qb-torture:client:start', function(payload)
    if not payload or not payload.session then
        cancelSession('invalid')
        return
    end

    if currentSession then
        cancelSession('busy', payload.session)
        return
    end

    local action = Config.Actions[payload.action]
    if not action then
        cancelSession('invalid_action', payload.session)
        return
    end

    local partner = payload.partner and GetPlayerFromServerId(payload.partner) or -1
    if partner == -1 then
        cancelSession('missing_partner', payload.session)
        return
    end

    local ped = PlayerPedId()
    local partnerPed = GetPlayerPed(partner)

    if #(GetEntityCoords(ped) - GetEntityCoords(partnerPed)) > Config.CancelDistance then
        cancelSession('distance', payload.session)
        return
    end

    currentRole = payload.role

    if payload.role == 'victim' then
        FreezeEntityPosition(ped, true)
    end

    TaskTurnPedToFaceEntity(ped, partnerPed, 1000)

    if payload.role == 'attacker' and action.attackerAnim and loadAnimation(action.attackerAnim.dict) then
        TaskPlayAnim(
            ped,
            action.attackerAnim.dict,
            action.attackerAnim.clip or 'enter',
            8.0,
            -8.0,
            -1,
            action.attackerAnim.flag or 1,
            0.0,
            false,
            false,
            false
        )
        if action.prop then
            attachPropToPed(ped, action.prop)
        end
    elseif payload.role == 'victim' and action.victimAnim and loadAnimation(action.victimAnim.dict) then
        TaskPlayAnim(
            ped,
            action.victimAnim.dict,
            action.victimAnim.clip or 'idle',
            4.0,
            -4.0,
            -1,
            action.victimAnim.flag or 1,
            0.0,
            false,
            false,
            false
        )
    end

    currentSession = payload.session
    startCoords = GetEntityCoords(ped)

    if payload.role == 'attacker' then
        CreateThread(function()
            local sessionId = payload.session
            local progress = lib.progressCircle({
                label = action.label or 'Action',
                duration = action.duration or 5000,
                position = 'middle',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    combat = true,
                    car = true
                }
            })

            if not progress then
                cancelSession('cancelled', sessionId)
                return
            end

            TriggerServerEvent('qb-torture:server:complete', sessionId)
        end)
    else
        CreateThread(function()
            local sessionId = payload.session
            while currentSession == payload.session do
                local pedCoords = GetEntityCoords(PlayerPedId())
                if #(pedCoords - startCoords) > Config.CancelDistance then
                    cancelSession('victim_moved', sessionId)
                    break
                end
                Wait(500)
            end
        end)
    end
end)

RegisterNetEvent('qb-torture:client:complete', function(payload)
    if not payload or payload.session ~= currentSession then
        return
    end

    local action = Config.Actions[payload.action]
    if action then
        if action.damage and action.damage > 0 and payload.role == 'victim' then
            local ped = PlayerPedId()
            local health = GetEntityHealth(ped)
            SetEntityHealth(ped, math.max(0, health - action.damage))
        end

        if action.stress and action.stress > 0 and payload.role == 'victim' then
            TriggerServerEvent('hud:server:GainStress', action.stress)
        end

        if action.particle and payload.role == 'attacker' then
            playParticleEffect(action.particle, PlayerPedId())
        end
    end

    resetState()
    FreezeEntityPosition(PlayerPedId(), false)
end)

RegisterNetEvent('qb-torture:client:stop', function(payload)
    if not payload or payload.session ~= currentSession then
        return
    end

    notify('Torture sequence cancelled.', 'error')
    resetState()
    FreezeEntityPosition(PlayerPedId(), false)
end)

CreateThread(function()
    -- wait for target to initialise properly
    Wait(1000)
    exports.ox_target:addGlobalPlayer({
        {
            name = 'qb_torture_action',
            icon = 'fa-solid fa-user-ninja',
            label = 'Initiate Interrogation',
            distance = 2.0,
            canInteract = function(entity)
                return validateTarget(entity)
            end,
            onSelect = function(data)
                local serverId = validateTarget(data.entity)
                if not serverId then
                    return notify('Target unavailable.', 'error')
                end
                buildMenu(serverId)
            end
        }
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    exports.ox_target:removeGlobalPlayer('qb_torture_action')
    for sessionId in pairs(chairEntities) do
        deleteChair(sessionId)
    end
    resetState()
end)
