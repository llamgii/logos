Mission = Mission or {}

Mission.active = false
Mission.stage = 'idle'
Mission.data = nil
Mission.targetPed = nil
Mission.chair = nil
Mission.carrying = false
Mission.recording = false
Mission.headbagObj = nil
Mission.weaponProp = nil
Mission.blips = {}
Mission.threads = {}
Mission.targetHandles = Mission.targetHandles or {}
Mission.activePrompt = nil

local notifyTypeMap = {
    primary = 'inform',
    success = 'success',
    error = 'error',
    info = 'inform'
}

local function notify(message, nType, duration)
    local libType = notifyTypeMap[nType or 'primary'] or 'inform'
    if lib and lib.notify then
        lib.notify({
            title = 'Kidnap Contract',
            description = message,
            type = libType,
            duration = duration
        })
        return
    end

    local QBCore = exports['qb-core']:GetCoreObject()
    QBCore.Functions.Notify(message, nType or 'primary', duration or 5000)
end

function Mission.Notify(message, nType, duration)
    notify(message, nType, duration)
end

local function debugPrint(...)
    if not Config.Debug then return end
    print('[QB Kidnap]', ...)
end

local function ensureThread(name, fn)
    Mission.threads[name] = true
    CreateThread(function()
        fn()
        Mission.threads[name] = nil
    end)
end

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

local function loadModel(model)
    if type(model) == 'string' then model = joaat(model) end
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    return model
end

local function cleanEntity(entity)
    if not entity then return end
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

local function detach(entity)
    if not entity or not DoesEntityExist(entity) then return end
    if IsEntityAttached(entity) then
        DetachEntity(entity, true, true)
    end
end

local function showPrompt(key, label, coords, zOffset)
    if lib and lib.showTextUI then
        if Mission.activePrompt ~= key then
            lib.showTextUI(label)
            Mission.activePrompt = key
        end
    else
        DrawText3D(coords.x, coords.y, coords.z + (zOffset or 0.0), label)
    end
end

local function hidePrompt(key)
    if Mission.activePrompt and Mission.activePrompt == key then
        if lib and lib.hideTextUI then
            lib.hideTextUI()
        end
        Mission.activePrompt = nil
    end
end

local function runProgress(label, duration)
    local ms = duration or 2500
    if lib and lib.progressCircle then
        return lib.progressCircle({
            duration = ms,
            label = label,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disable = {
                move = true,
                car = true,
                combat = true
            }
        })
    end
    Wait(ms)
    return true
end

local function createBlip(key, coords, data)
    if Mission.blips[key] then
        RemoveBlip(Mission.blips[key])
    end
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, data.sprite)
    SetBlipColour(blip, data.color)
    SetBlipScale(blip, data.scale)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(data.text)
    EndTextCommandSetBlipName(blip)
    Mission.blips[key] = blip
end

local function removeBlip(key)
    if not Mission.blips[key] then return end
    if DoesBlipExist(Mission.blips[key]) then
        RemoveBlip(Mission.blips[key])
    end
    Mission.blips[key] = nil
end

local function clearAllBlips()
    for key in pairs(Mission.blips) do
        removeBlip(key)
    end
end

local function setPedPassive(ped)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedSeeingRange(ped, 0.0)
    SetPedHearingRange(ped, 0.0)
    SetPedAlertness(ped, 0)
    SetBlockingOfNonTemporaryEvents(ped, true)
end

local function spawnChair(coords)
    local model = loadModel(Config.ChairModel)
    local obj = CreateObject(model, coords.x, coords.y, coords.z - 1.0, true, true, false)
    SetEntityHeading(obj, coords.w)
    FreezeEntityPosition(obj, true)
    return obj
end

local function seatVictimOnChair(ped, chair)
    if not DoesEntityExist(ped) or not DoesEntityExist(chair) then return end
    ClearPedTasksImmediately(ped)
    TaskStartScenarioAtPosition(ped, 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER', GetEntityCoords(chair), GetEntityHeading(chair), 0, true, true)
end

local function attachHeadbag(ped)
    if not DoesEntityExist(ped) then return end
    local model = loadModel(Config.Headbag.prop)
    local obj = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, Config.Headbag.bone), Config.Headbag.attach.x, Config.Headbag.attach.y,
        Config.Headbag.attach.z, Config.Headbag.attach.xr, Config.Headbag.attach.yr, Config.Headbag.attach.zr, false, false, false, false, 2, true)
    Mission.headbagObj = obj
end

local function givePlayerProp()
    if Mission.weaponProp and DoesEntityExist(Mission.weaponProp) then return end
    local propData = Config.Interrogation.prop
    local model = loadModel(propData.model)
    local ped = PlayerPedId()
    local obj = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, propData.bone), propData.attach.x, propData.attach.y, propData.attach.z,
        propData.attach.xr, propData.attach.yr, propData.attach.zr, true, true, false, true, 1, true)
    Mission.weaponProp = obj
end

local function removePlayerProp()
    if Mission.weaponProp and DoesEntityExist(Mission.weaponProp) then
        DeleteEntity(Mission.weaponProp)
    end
    Mission.weaponProp = nil
end

local function bagTargetAnimation(ped)
    local anim = Config.Headbag.anim
    loadAnimDict(anim.dict)
    local player = PlayerPedId()
    TaskPlayAnim(player, anim.dict, anim.name, 4.0, -4.0, anim.duration, 49, 0.0, false, false, false)
    runProgress('Securing captive...', anim.duration)
    attachHeadbag(ped)
end

local function applyVictimAnim(ped)
    local anim = Config.Interrogation.victimAnim
    if not anim or not anim.dict then return end
    loadAnimDict(anim.dict)
    TaskPlayAnim(ped, anim.dict, anim.name, 8.0, -8.0, anim.duration or -1, 1, 0.0, false, false, false)
end

local function followPlayer(ped)
    local player = PlayerPedId()
    TaskFollowToOffsetOfEntity(ped, player, 0.0, -0.5, 0.0, 1.5, -1, 2.0, true)
    SetPedKeepTask(ped, true)
    Mission.carrying = true
end

local function checkTransportStage()
    ensureThread('transport_monitor', function()
        while Mission.active and Mission.stage == 'transport' do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local drop = Mission.data.target.dropoff
            local distance = #(coords - vector3(drop.x, drop.y, drop.z))
            if Mission.targetPed and DoesEntityExist(Mission.targetPed) then
                local pedCoords = GetEntityCoords(Mission.targetPed)
                local escortDist = #(coords - pedCoords)
                if escortDist > 35.0 then
                    Mission:Fail('You lost the captive.')
                    return
                end
            end

            if distance < 30.0 then
                DrawMarker(1, drop.x, drop.y, drop.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.5, 2.5, 1.5, 200, 50, 50, 120, false, true, 2, nil, nil, false)
                if distance < 2.5 then
                    notify('Set them in the chair to begin the interrogation', 'success')
                    Mission:SetStage('setup_interrogation')
                    return
                end
            end
            Wait(250)
        end
    end)
end

local function chairStageMonitor()
    ensureThread('chair_monitor', function()
        while Mission.active and Mission.stage == 'setup_interrogation' do
            if not Mission.targetPed or not DoesEntityExist(Mission.targetPed) then break end
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local chairPos = Mission.data.target.chair
            local dist = #(coords - vector3(chairPos.x, chairPos.y, chairPos.z))

            DrawMarker(1, chairPos.x, chairPos.y, chairPos.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.8, 1.8, 1.2, 120, 120, 200, 120, false, true, 2, nil, nil, false)
            if dist < 2.0 then
                Mission:PromptSeatVictim()
            else
                hidePrompt('seat_victim')
            end
            Wait(0)
        end
        hidePrompt('seat_victim')
    end)
end

local function recordingMonitor()
    ensureThread('recording_monitor', function()
        local start = GetGameTimer()
        local duration = Config.Interrogation.recordingDuration * 1000

        while Mission.recording and Mission.active do
            if GetGameTimer() - start >= duration then
                Mission.recording = false
                removePlayerProp()
                Mission:SetStage('return')
                TriggerServerEvent('qbx_kidnap:server:FinalizeRecording')
                notify('Recording complete. Deliver the footage.', 'success')
                return
            end

            if Config.Interrogation.tortureDamage.enabled and (GetGameTimer() - start) % (Config.Interrogation.tortureDamage.interval * 1000) < 100 then
                ApplyDamageToPed(Mission.targetPed, Config.Interrogation.tortureDamage.amount, false)
            end

            Wait(200)
        end
    end)
end

local function missionTicker()
    ensureThread('mission_hints', function()
        while Mission.active do
            if Mission.targetPed and DoesEntityExist(Mission.targetPed) then
                if IsPedDeadOrDying(Mission.targetPed, true) then
                    Mission:Fail('The captive died. The client is not pleased.')
                    return
                end
            end

            if Mission.stage == 'locate' and Mission.targetPed then
                local coords = GetEntityCoords(Mission.targetPed)
                DrawMarker(20, coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 0, 0, 120, false, true, 2, nil, nil, false)
            elseif Mission.stage == 'interrogate' then
                local coords = Mission.data.target.chair
                DrawMarker(0, coords.x, coords.y, coords.z + 1.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 220, 50, 50, 120, false, true, 2, nil, nil, false)
            end
            Wait(0)
        end
    end)
end

function Mission:Reset(force)
    debugPrint('Reset called', force)
    self.active = false
    self.stage = 'idle'
    self.data = nil
    self.carrying = false
    self.recording = false

    clearAllBlips()

    detach(PlayerPedId())
    removePlayerProp()

    if Mission.RemoveInteractionHandle then
        Mission.RemoveInteractionHandle('victim')
    end

    if self.activePrompt then
        hidePrompt(self.activePrompt)
    end

    if self.targetPed then
        DeletePed(self.targetPed)
        self.targetPed = nil
    end

    if self.chair then
        cleanEntity(self.chair)
        self.chair = nil
    end

    if self.headbagObj then
        cleanEntity(self.headbagObj)
        self.headbagObj = nil
    end

    for name in pairs(self.threads) do
        self.threads[name] = nil
    end

    if force then
        TriggerServerEvent('qbx_kidnap:server:Cleanup')
    end
end

function Mission:SetStage(stage)
    self.stage = stage
    debugPrint('Stage changed', stage)

    if stage == 'setup_interrogation' then
        chairStageMonitor()
    elseif stage == 'return' then
        self:BeginReturnPhase()
    end
end

function Mission:Start(missionData)
    if self.active then
        notify('You already have an active job.', 'error')
        return
    end

    self:Reset()

    self.active = true
    self.data = missionData
    self:SetStage('locate')

    notify('Locate the mark and secure them discreetly.', 'primary', 6500)

    TriggerServerEvent('qbx_kidnap:server:Dispatch', missionData.target.spawn)
    self:SpawnTarget()

    if Config.Blips.victim then
        createBlip('victim', missionData.target.spawn, Config.Blips.victim)
    end

    missionTicker()
end

function Mission:SpawnTarget()
    local target = self.data.target
    loadModel(target.model)
    local ped = CreatePed(4, target.model, target.spawn.x, target.spawn.y, target.spawn.z, target.spawn.w, true, true)
    SetEntityAsMissionEntity(ped, true, true)
    NetworkRegisterEntityAsNetworked(ped)
    local netId = NetworkGetNetworkIdFromEntity(ped)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)
    setPedPassive(ped)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)

    self.targetPed = ped
    Mission.RegisterVictimTarget(ped)
end

function Mission:PrepareTransport()
    if not self.targetPed or not DoesEntityExist(self.targetPed) then return end
    if Mission.RemoveInteractionHandle then
        Mission.RemoveInteractionHandle('victim')
    end
    removeBlip('victim')
    if Config.Blips.interrogate then
        createBlip('interrogate', self.data.target.dropoff, Config.Blips.interrogate)
    end
    ClearPedTasksImmediately(self.targetPed)
    followPlayer(self.targetPed)
    notify('Move the captive to the interrogation site.', 'primary', 6000)
    self:SetStage('transport')
    checkTransportStage()
end

function Mission:PromptSeatVictim()
    local chair = self.data.target.chair
    showPrompt('seat_victim', '[E] Seat captive', chair, 0.6)
    if IsControlJustReleased(0, 38) then
        self:SeatVictim()
    end
end

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (#text) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function Mission:SeatVictim()
    if self.stage ~= 'setup_interrogation' then return end
    if not self.chair then
        self.chair = spawnChair(self.data.target.chair)
    end

    detach(self.targetPed)
    self.carrying = false
    seatVictimOnChair(self.targetPed, self.chair)
    applyVictimAnim(self.targetPed)
    hidePrompt('seat_victim')

    self:SetStage('interrogate')
    removeBlip('interrogate')
    self:BeginInterrogationLoop()
end

function Mission:BeginInterrogationLoop()
    local anim = Config.Interrogation.startAnim
    loadAnimDict(anim.dict)
    TaskPlayAnim(PlayerPedId(), anim.dict, anim.name, 8.0, -8.0, anim.duration, 1, 0.0, false, false, false)
    Wait(anim.duration)
    givePlayerProp()

    local loopAnim = Config.Interrogation.loopAnim
    if loopAnim and loopAnim.dict and loopAnim.name then
        loadAnimDict(loopAnim.dict)
        TaskPlayAnim(PlayerPedId(), loopAnim.dict, loopAnim.name, loopAnim.blend or 8.0, -8.0, -1, 49, 0.0, false, false, false)
    end

    self.recording = true
    self:SetStage('recording')

    notify('Keep the camera rolling...', 'primary', 4000)
    recordingMonitor()
end

function Mission:BeginReturnPhase()
    removePlayerProp()
    self.recording = false

    if Config.Blips.missionStart.enabled then
        createBlip('return', Config.MissionGiver.coords, {
            sprite = Config.Blips.missionStart.sprite,
            color = Config.Blips.missionStart.color,
            scale = Config.Blips.missionStart.scale,
            text = 'Deliver Footage'
        })
    end

    notify('Deliver the video back to the fixer.', 'primary', 5000)
    ensureThread('return_monitor', function()
        while self.active and self.stage == 'return' do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local target = Config.MissionGiver.coords
            local distance = #(coords - vector3(target.x, target.y, target.z))

            if distance < 2.5 then
                showPrompt('deliver_footage', '[E] Hand over footage', target, 1.0)
                if IsControlJustReleased(0, 38) then
                    self:DeliverFootage()
                    return
                end
            else
                hidePrompt('deliver_footage')
            end
            Wait(0)
        end
        hidePrompt('deliver_footage')
    end)
end

function Mission:DeliverFootage()
    if self.stage ~= 'return' then return end
    hidePrompt('deliver_footage')
    TriggerServerEvent('qbx_kidnap:server:DeliverFootage')
end

function Mission:Fail(reason)
    if not self.active then return end
    notify(reason or 'Job failed', 'error', 5500)
    TriggerServerEvent('qbx_kidnap:server:Fail')
    self:Reset()
end

function Mission:Complete()
    notify('Footage delivered. Expect the wire soon.', 'success', 6000)
    self:Reset()
end

RegisterNetEvent('qbx_kidnap:client:HeadbagTarget', function()
    if not Mission.active or Mission.stage ~= 'locate' then return end
    if not Mission.targetPed or not DoesEntityExist(Mission.targetPed) then return end

    bagTargetAnimation(Mission.targetPed)
    Mission:PrepareTransport()
end)

RegisterNetEvent('qbx_kidnap:client:StartRecording', function()
    if not Mission.active or Mission.stage ~= 'interrogate' then return end
    Mission:BeginInterrogationLoop()
end)

RegisterNetEvent('qbx_kidnap:client:RecordingComplete', function()
    Mission:SetStage('return')
end)
