Config = {}

Config.Locale = 'en'

Config.VehicleModel = 'burrito3'
Config.VehicleHash = 2551651283 -- burrito3

Config.HelperPedModel = `s_m_y_blackops_01`

Config.SupplierPed = {
    model = `s_m_m_highsec_01`,
    coords = vector4(448.87, -973.24, 30.69, 90.0),
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    oxTargetLabel = 'Request Kidnap Van',
    blip = {
        enabled = true,
        sprite = 67,
        colour = 1,
        scale = 0.75,
        text = 'Shady Supplier'
    }
}

Config.VehicleSpawn = {
    coords = vector4(443.61, -982.42, 25.7, 90.0),
    minClearance = 3.0
}

Config.KidnapRange = 4.0
Config.KidnapCooldown = 45 -- seconds

Config.TrunkAttach = {
    bone = 0,
    offset = vector3(0.0, -2.2, -0.45),
    rotation = vector3(0.0, 0.0, 0.0)
}

Config.KidnapDuration = 5000
Config.HelperApproachDistance = 1.3

Config.ReleaseCommand = 'releasekidnap'

Config.Animations = {
    helper = { dict = 'anim@melee@small_wpn@streamed_core', anim = 'taunt_short' },
    victim = { dict = 'missfbi3_sniping', anim = 'play_dead_idle' }
}

Config.Progress = {
    label = 'Kidnapping target...',
    duration = 4250
}

Config.Messages = {
    needVehicle = 'You need to be driving the kidnapping van.',
    alreadyKidnapping = 'You already have someone in the trunk.',
    noTarget = 'No one close enough to snatch.',
    targetOccupied = 'Target is in a vehicle.',
    cooldown = 'Slow down, you just pulled someone.',
    gettingVan = 'Delivery incoming...',
    vanReady = 'The van is ready. Do not crash it.',
    kidnapping = 'Helper is handling the target...',
    trunkFull = 'Someone is already in the trunk.'
}
