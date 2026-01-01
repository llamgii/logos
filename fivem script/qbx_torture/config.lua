Config = Config or {}

Config.Locale = 'en'

Config.AllowedJobs = {
    police = 2,
    sheriff = 2
}

Config.RequireItem = {
    enable = false,
    name = 'torturekit',
    amount = 1,
    removeOnUse = false
}

Config.CancelDistance = 4.0

Config.Chair = {
    model = `prop_chair_01a`,
    offset = vec3(1.0, 0.0, 0.0),
    seatOffset = vec3(0.0, -0.05, 0.5),
    distance = 2.5
}

Config.Actions = {
    shock = {
        label = 'Electric Shock',
        icon = 'bolt',
        description = 'Deliver a painful electric shock. Causes moderate damage and stress.',
        duration = 6000,
        attackerAnim = { dict = 'anim@gangops@facility@servers@', clip = 'hotwire', flag = 49 },
        victimAnim = { dict = 'mp_arresting', clip = 'idle', flag = 33 },
        damage = 15,
        stress = 12,
        prop = {
            model = `prop_tool_torch`,
            bone = 57005,
            pos = vec3(0.12, 0.03, -0.02),
            rot = vec3(90.0, 0.0, 100.0)
        },
        particle = {
            asset = 'core',
            effect = 'ent_dst_electrical',
            offset = vec3(0.0, 0.0, -0.1)
        }
    },
    burn = {
        label = 'Cigarette Burn',
        icon = 'fire',
        description = 'Press a lit cigarette into the victim. Increases stress sharply.',
        duration = 4500,
        attackerAnim = { dict = 'switch@trevor@smoking_meth', clip = 'trev_smoking_meth_loop', flag = 49 },
        victimAnim = { dict = 'mp_arresting', clip = 'idle', flag = 33 },
        damage = 8,
        stress = 18,
        prop = {
            model = `ng_proc_cigarette01a`,
            bone = 57005,
            pos = vec3(0.02, 0.0, 0.0),
            rot = vec3(0.0, 0.0, 180.0)
        }
    }
}
