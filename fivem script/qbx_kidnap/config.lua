Config = {}

Config.Locale = 'en'

-- NPC that assigns kidnapping jobs.
Config.MissionGiver = {
    model = `s_m_m_highsec_01`,
    coords = vector4(169.63, -1004.64, -99.0, 92.89),
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    targetIcon = 'fas fa-user-secret',
    targetLabel = 'Talk to Fixer',
    cooldown = 15 * 60 -- seconds
}

Config.RequiredItems = {
    headbag = 'headbag',
    recorder = 'camera'
}

Config.Reward = {
    money = { account = 'markedbills', amount = 750 },
    items = {
        { name = 'dirty_money', count = 5 }
    }
}

Config.Dispatch = {
    enabled = true,
    code = '10-66',
    message = 'Possible abduction in progress',
    blip = {
        sprite = 161,
        color = 1,
        scale = 1.4,
        timeout = 45
    },
    jobFilter = { 'police', 'sasp', 'bcso' }
}

Config.Interrogation = {
    startAnim = { dict = 'missfbi3_sniping', name = 'fhb_stand_fire', duration = 5000 },
    loopAnim = { dict = 'anim@heists@humane_labs@emp@hack_door', name = 'hack_loop', blend = 8.0 },
    victimAnim = { dict = 'anim@heists@ornate_bank@hostages@' , name = 'ped_b', duration = -1 },
    prop = {
        model = `prop_w_me_wrench`,
        attach = { x = 0.08, y = 0.02, z = -0.02, xr = 90.0, yr = 0.0, zr = 0.0 },
        bone = 57005
    },
    recordingDuration = 45, -- seconds required to complete interrogation recording
    tortureDamage = { enabled = true, interval = 10, amount = 10 }
}

Config.KidnapTargets = {
    {
        spawn = vector4(-623.78, -230.21, 38.06, 267.0),
        model = `a_m_m_business_01`,
        vehicleSpawn = vector4(-615.76, -225.75, 38.06, 87.16),
        chair = vector4(976.34, -2168.11, 30.48, 269.8),
        dropoff = vector4(981.1, -2166.82, 30.48, 180.55)
    },
    {
        spawn = vector4(267.12, -1003.87, 28.36, 183.2),
        model = `a_m_y_business_02`,
        vehicleSpawn = vector4(276.86, -994.21, 28.45, 69.37),
        chair = vector4(997.72, -2123.45, 30.48, 88.41),
        dropoff = vector4(997.69, -2126.99, 30.48, 270.12)
    },
    {
        spawn = vector4(-1272.63, -357.98, 36.9, 87.74),
        model = `a_f_y_business_02`,
        vehicleSpawn = vector4(-1274.38, -350.58, 36.9, 2.0),
        chair = vector4(1001.46, -2155.27, 30.48, 186.35),
        dropoff = vector4(1005.57, -2156.76, 30.48, 357.82)
    }
}

Config.Headbag = {
    anim = { dict = 'mp_arresting', name = 'a_uncuff', duration = 2500 },
    prop = `prop_money_bag_01`,
    attach = { x = 0.0, y = 0.0, z = 0.0, xr = 0.0, yr = 0.0, zr = 0.0 },
    bone = 31086
}

Config.ChairModel = `prop_chair_03`

Config.Blips = {
    missionStart = {
        enabled = true,
        sprite = 480,
        color = 1,
        scale = 0.7,
        text = 'Kidnapping Fixer'
    },
    victim = {
        sprite = 480,
        color = 5,
        scale = 0.7,
        text = 'Kidnap Target'
    },
    interrogate = {
        sprite = 303,
        color = 1,
        scale = 0.65,
        text = 'Interrogation Site'
    }
}

Config.PoliceCallChance = 65

Config.ProgressSounds = {
    start = 'START',
    tick = 'TIMER',
    finish = 'COLLECT'
}

Config.Debug = false
