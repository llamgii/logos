local Config = {
    tick = 2000, -- milliseconds between sweeps
    skipPedTypes = { -- ped types to leave alone (cops/army/security)
        [6] = true,  -- cop
        [27] = true, -- swat
        [29] = true, -- army
    },
    skipModels = {
        [`s_m_m_security_01`] = true,
        [`s_m_m_armoured_01`] = true,
    },
    relationshipGroups = {
        'PLAYER',
        'CIVMALE',
        'CIVFEMALE',
        'GANG_1',
        'GANG_2',
        'GANG_9',
        'GANG_10',
        'FIREMAN',
        'MEDIC',
        'SECURITY_GUARD',
    },
}

local function setFriendlyRelationships()
    for _, g1 in ipairs(Config.relationshipGroups) do
        local hash1 = GetHashKey(g1)
        for _, g2 in ipairs(Config.relationshipGroups) do
            local hash2 = GetHashKey(g2)
            SetRelationshipBetweenGroups(1, hash1, hash2) -- 1 = Respect
            SetRelationshipBetweenGroups(1, hash2, hash1)
        end
    end
end

local function calmPed(ped)
    RemoveAllPedWeapons(ped, true)
    SetPedSeeingRange(ped, 0.0)
    SetPedHearingRange(ped, 0.0)
    SetPedAlertness(ped, 0)
    SetPedCombatAbility(ped, 0)
    SetPedAccuracy(ped, 0)
    SetPedCombatAttributes(ped, 17, false)  -- no fighting armed peds when unarmed
    SetPedCombatAttributes(ped, 0, false) -- no vehicle usage in combat
    SetCanAttackFriendly(ped, true, true)
    ClearPedTasks(ped)
end

CreateThread(function()
    setFriendlyRelationships()

    while true do
        local peds = GetGamePool('CPed')

        for i = 1, #peds do
            local ped = peds[i]

            if not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) then
                local pedType = GetPedType(ped)
                local model = GetEntityModel(ped)

                if not Config.skipPedTypes[pedType] and not Config.skipModels[model] then
                    if IsPedArmed(ped, 4) or IsPedShooting(ped) then
                        calmPed(ped)
                    end
                end
            end
        end

        Wait(Config.tick)
    end
end)

