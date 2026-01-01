Config = {}

-- Banking System Selection
Config.BankingSystem = "renewed-banking"  -- Options: "dw-banking", "qb-banking", "renewed-banking"

-- Target Sysytem Selection
Config.TargetSystem = "ox_target"  -- Options: "qb-target", "ox_target"

-- Job Application System Settings
Config.EnableApplicationSystem = true  -- Set to false to disable job application system


-- Management access locations
Config.Locations = {
    ["police"] = {
        label = "Police Department",
        logoImage = "police.png",
        locations = {
            {
                coords = vector3(462.0910, -985.5402, 30.7281), -- Main Police Station
                width = 1.0,
                length = 1.0,
                heading = 175.6379,
                minZ = 30.0,
                maxZ = 31.0,
            },
        }
    },
    ["doj"] = {
        label = "DOJ",
        logoImage = "doj.png",
        locations = {
            {
                coords = vector3(-527.5515, -189.1223, 43.3659), -- Main Police Station
                width = 1.0,
                length = 1.0,
                heading = 119.0196,
                minZ = 30.0,
                maxZ = 31.0,
            },
        }
    },
    ["ambulance"] = {
        label = "EMS Department",
        logoImage = "ems.png",
        locations = {
            {
                coords = vector3(340.2706, -591.2374, 43.2840), -- Main Hospital
                width = 1.0,
                length = 1.0,
                heading = 73.9076,
                minZ = 43.0,
                maxZ = 44.0,
            },
        }
    },
    ["mechanic"] = {
        label = "Mechanic Shop",
        logoImage = "mechanic.png",
        locations = {
            {
                coords = vector3(-196.27, -1315.8, 31.3), -- Mechanic Shop
                width = 1.0,
                length = 1.0,
                heading = 11.0948,
                minZ = 25.0,
                maxZ = 26.0,
            }
        }
    },
        ["casino"] = {
        label = "casino management",
        logoImage = "mechanic.png",
        locations = {
            {
                coords = vector3(934.11, 38.22, 75.89), 
                width = 1.0,
                length = 1.0,
                heading = 11.0948,
                minZ = 25.0,
                maxZ = 26.0,
            }
        }
    },
        ["uwu"] = {
        label = "bean mangment",
        logoImage = "mechanic.png",
        locations = {
            {
                coords = vector3(126.64, -1035.47, 29.28), 
                width = 1.0,
                length = 1.0,
                heading = 11.0948,
                minZ = 25.0,
                maxZ = 26.0,
            }
        }
    },
    ["bahama"] = {
        label = "Bahama managment",
        logoImage = "mechanic.png",
        locations = {
            {
                coords = vec3(-1372.03, -629.22, 30.32), 
                width = 1.0,
                length = 1.0,
                heading = 11.0948,
                minZ = 25.0,
                maxZ = 26.0,
            }
        }
    },



    -- Add more jobs as needed
}

Config.ApplicationPoints = {
    ["police"] = {
        coords = vector3(441.2918, -981.9130, 30.6896),  -- Near the police station
        width = 1.0,
        length = 1.0,
        heading = 271.4635,
        minZ = 30.0,
        maxZ = 31.0,
        label = "Police Application"
    },
    ["ambulance"] = {
        coords = vector3(312.0804, -592.7656, 43.2841),  -- Near the hospital
        width = 1.0,
        length = 1.0,
        heading = 162.4223,
        minZ = 43.0,
        maxZ = 44.0,
        label = "EMS Application"
    },
    ["mechanic"] = {
        coords = vector3(145.7924, -3014.7466, 7.0409),  -- Near the mechanic shop
        width = 1.0,
        length = 1.0,
        heading = 1.1337,
        minZ = 25.0,
        maxZ = 26.0,
        label = "Mechanic Application"
    },
    -- Add more points as needed
}

-- Define application form questions (these will be shown in the application form)
Config.ApplicationQuestions = {
    ["police"] = {
        {
            question = "Why do you want to join the Police Department?",
            type = "text",
            required = true,
            min = 1,
            max = 1024
        },
        {
            question = "Do you have any previous law enforcement experience?",
            type = "select",
            options = {"Yes", "No"},
            required = true
        },
        {
            question = "How many years of experience do you have?",
            type = "number",
            required = false,
            min = 0,
            max = 50
        },
        {
            question = "How would you handle a high-stress situation?",
            type = "text",
            required = true,
            min = 1,
            max = 1024
        }
    },
}

-- Default settings
Config.DefaultSettings = {
    darkMode = true,
    showAnimations = true,
    compactView = false,
    notificationSound = "default",
    themeColor = "blue",
    refreshInterval = 60,
    showPlaytime = true,
    showLocation = true
}
