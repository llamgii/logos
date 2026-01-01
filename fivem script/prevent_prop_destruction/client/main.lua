Config = Config or {}

local protectedHashes = {}
local trackedEntities = {}
local positionTolerance = Config.PositionTolerance or 0.05
local rotationTolerance = Config.RotationTolerance or 1.0

local function addProtectedHash(hash, label)
    if hash then
        protectedHashes[hash] = label or hash
    end
end

if Config and Config.ProtectedModels then
    for _, entry in ipairs(Config.ProtectedModels) do
        if type(entry) == 'string' then
            addProtectedHash(GetHashKey(entry), entry)
        elseif type(entry) == 'number' then
            addProtectedHash(entry, entry)
        end
    end
end

local function debugPrint(...)
    if Config.Debug then
        print('[prevent_prop_destruction]', ...)
    end
end

local function ensureControl(entity)
    if not Config.EnsureNetworkControl or NetworkHasControlOfEntity(entity) then
        return true
    end

    NetworkRequestControlOfEntity(entity)
    local tries = 0

    while not NetworkHasControlOfEntity(entity) and tries < 15 do
        Wait(0)
        NetworkRequestControlOfEntity(entity)
        tries = tries + 1
    end

    return NetworkHasControlOfEntity(entity)
end

local function protectEntity(entity)
    if not DoesEntityExist(entity) then
        return
    end

    if Config.MakeMissionEntity and not IsEntityAMissionEntity(entity) then
        SetEntityAsMissionEntity(entity, true, true)
    end

    if not ensureControl(entity) then
        debugPrint('Failed to take control of entity', entity)
    end

    SetEntityInvincible(entity, true)
    SetEntityCanBeDamaged(entity, false)
    if Config.ApplyStrongProofs then
        SetEntityProofs(entity, true, true, true, true, true, true, true, true)
    end

    SetEntityLoadCollisionFlag(entity, true)
    SetEntityCollision(entity, true, true)
    SetEntityDynamic(entity, false)
    ActivatePhysics(entity)
    SetEntityVelocity(entity, 0.0, 0.0, 0.0)

    if Config.FreezeProtectedProps then
        FreezeEntityPosition(entity, true)
    end

    local health = GetEntityHealth(entity)
    if health > 0 then
        SetEntityHealth(entity, math.max(health, 1000))
    end
end

local function handleEntity(entity)
    if not DoesEntityExist(entity) then
        return
    end

    if GetEntityType(entity) ~= 3 then
        return
    end

    local model = GetEntityModel(entity)
    if protectedHashes[model] then
        local data = trackedEntities[entity]
        if not data then
            data = {
                coords = GetEntityCoords(entity),
                rotation = GetEntityRotation(entity, 2),
                freezeApplied = false
            }
            trackedEntities[entity] = data
        end

        protectEntity(entity)

        if Config.FreezeProtectedProps and not data.freezeApplied then
            FreezeEntityPosition(entity, true)
            data.freezeApplied = true
        end

        if Config.RestorePosition then
            local coords = GetEntityCoords(entity)
            local dx = coords.x - data.coords.x
            local dy = coords.y - data.coords.y
            local dz = coords.z - data.coords.z
            local distanceSquared = (dx * dx) + (dy * dy) + (dz * dz)
            if distanceSquared > (positionTolerance * positionTolerance) then
                debugPrint('Restoring position for entity', entity)
                SetEntityCoordsNoOffset(entity, data.coords.x, data.coords.y, data.coords.z, false, false, false)
                SetEntityVelocity(entity, 0.0, 0.0, 0.0)
            end
        end

        if Config.RestoreRotation then
            local rotation = GetEntityRotation(entity, 2)
            local rx = math.abs(rotation.x - data.rotation.x)
            local ry = math.abs(rotation.y - data.rotation.y)
            local rz = math.abs(rotation.z - data.rotation.z)
            if rx > rotationTolerance or ry > rotationTolerance or rz > rotationTolerance then
                debugPrint('Restoring rotation for entity', entity)
                SetEntityRotation(entity, data.rotation.x, data.rotation.y, data.rotation.z, 2, true)
            end
        end
    end
end

CreateThread(function()
    local interval = Config.CheckInterval or 5000

    while true do
        local objects = GetGamePool('CObject')
        for _, obj in ipairs(objects) do
            handleEntity(obj)
        end

        for entity, data in pairs(trackedEntities) do
            if not DoesEntityExist(entity) or GetEntityType(entity) ~= 3 then
                trackedEntities[entity] = nil
            end
        end

        Wait(interval)
    end
end)

AddEventHandler('gameEventTriggered', function(eventName, data)
    if eventName ~= 'CEventNetworkEntityDamage' then
        return
    end

    local victim = data[1]
    if victim and DoesEntityExist(victim) then
        handleEntity(victim)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    for entity, data in pairs(trackedEntities) do
        if DoesEntityExist(entity) then
            if data.freezeApplied then
                FreezeEntityPosition(entity, false)
            end
            SetEntityInvincible(entity, false)
            SetEntityCanBeDamaged(entity, true)
            if Config.ApplyStrongProofs then
                SetEntityProofs(entity, false, false, false, false, false, false, false, false)
            end
        end
    end
end)
