---Job names must be lower case (top level table key)
---@type table<string, Job>
return {
    ['unemployed'] = {
        label = 'Civilian',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Freelancer',
                payment = 12
            },
        },
    },
    ['police'] = {
        label = 'LSPD',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Cadet',
                payment = 80
            },
            [1] = {
                name = 'Police Officer I',
                payment = 85
            },
            [2] = {
                name = 'Police Officer II',
                payment = 90
            },
            [3] = {
                name = 'Police Officer III',
                payment = 95
            },
            [4] = {
                name = 'Senior Lead Officer – SLO',
                payment = 100
            },
            [5] = {
                name = 'Sergeant I',
                payment = 105
            },
            [6] = {
                name = 'Sergeant II',
                payment = 110
            },
            [7] = {
                name = 'Lieutenant',
                payment = 115
            },
            [8] = {
                name = 'Captain',
                isboss = true,
                bankAuth = true,
                payment = 120
            },
            [9] = {
                name = 'Commander',
                isboss = true,
                bankAuth = true,
                payment = 125
            },
            [10] = {
                name = 'Deputy Chief',
                isboss = true,
                bankAuth = true,
                payment = 130
            },
            [11] = {
                name = 'Assistant Chief',
                isboss = true,
                bankAuth = true,
                payment = 135
            },
            [12] = {
                name = 'Chief of Police',
                isboss = true,
                bankAuth = true,
                payment = 170
            },
        },
    },
    ['sheriff'] = {
        label = 'BCSO',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
        [0] = {
            name = 'DEPUTY SHERIFF TRAINEE',
            payment = 80
        },
        [1] = {
            name = 'DEPUTY SHERIFF',
        payment = 85
        },
        [2] = {
            name = 'SENIOR DEPUTY (deputy bonus I)',
         payment = 90
        },
        [3] = {
            name = 'MASTER DEPUTY(deputy bonus II)',
            payment = 95
        },
        [4] = {
            name = 'SERGEANT',
            payment = 100
        },
        [5] = {
            name = 'LIEUTENANT',
         payment = 105
        },
        [6] = {
            name = 'CAPTAIN',
            isboss = true,
            bankAuth = true,
            payment = 110
        },
        [7] = {
            name = 'AREA COMMANDER',
            isboss = true,
            bankAuth = true,
            payment = 115
        },
        [8] = {
            name = 'DIVISION CHIEF',
            isboss = true,
            bankAuth = true,
            payment = 120
        },
        [9] = {
            name = 'ASSISTANT SHERIFF',
            isboss = true,
            bankAuth = true,
            payment = 125
        },
        [10] = {
            name = 'UNDERSHERIFF',
            isboss = true,
            bankAuth = true,
            payment = 130
        },
        [11] = {
            name = 'SHERIFF',
            isboss = true,
            bankAuth = true,
            payment = 150
            },
        },
    },
    ['lssd'] = {
        label = 'LSSD',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
        [0] = {
            name = 'DEPUTY TRAINEE',
            payment = 80
        },
        [1] = {
            name = 'DEPUTY',
        payment = 85
        },
        [2] = {
            name = 'SENIOR DEPUTY (deputy bonus I)',
         payment = 90
        },
        [3] = {
            name = 'MASTER DEPUTY(deputy bonus II)',
            payment = 95
        },
        [4] = {
            name = 'SERGEANT',
            payment = 100
        },
        [5] = {
            name = 'LIEUTENANT',
         payment = 105
        },
        [6] = {
            name = 'CAPTAIN',
            isboss = true,
            bankAuth = true,
            payment = 110
        },
        [7] = {
            name = 'AREA COMMANDER',
            isboss = true,
            bankAuth = true,
            payment = 115
        },
        [8] = {
            name = 'DIVISION CHIEF',
            isboss = true,
            bankAuth = true,
            payment = 120
        },
        [9] = {
            name = 'CHIEF DEPUTY SHERIFF',
            isboss = true,
            bankAuth = true,
            payment = 125
        },
        [10] = {
            name = 'UNDERSHERIFF',
            isboss = true,
            bankAuth = true,
            payment = 130
        },
        [11] = {
            name = 'SHERIFF',
            isboss = true,
            bankAuth = true,
            payment = 150
            },
        },
    },
    -- ['sahp'] = {
    --     label = 'SAHP',
    --     type = 'leo',
    --     defaultDuty = true,
    --     offDutyPay = false,
    --     grades = {
    --     [0] = {
    --         name = 'Cadet',
    --         payment = 80
    --     },
    --     [1] = {
    --         name = 'Officer',
    --         payment = 90
    --     },
    --     [2] = {
    --         name = 'Sergeant',
    --         isboss = true,
    --         bankAuth = true,
    --         payment = 95
    --     },
    --     [3] = {
    --         name = 'Lieutenant',
    --         isboss = true,
    --         bankAuth = true,
    --         payment = 100
    --     },
    --     [4] = {
    --         name = 'Captain',
    --         isboss = true,
    --         bankAuth = true,
    --         payment = 105
    --     },
    --     [5] = {
    --         name = 'Assistant Chief',
    --         isboss = true,
    --         bankAuth = true,
    --         payment = 115
    --     },
    --     [6] = {
    --         name = 'Chief',
    --         isboss = true,
    --         bankAuth = true,
    --         payment = 120
    --     },
    --     [7] = {
    --         name = 'Assistant Commissioner',
    --         isboss = true,
    --         bankAuth = true,
    --         payment = 130
    --     },
    --     [8] = {
    --         name = 'Deputy Commissioner',
    --         isboss = true,
    --         bankAuth = true,
    --         payment = 140
    --     },
    --     [9] = {
    --         name = 'Commissioner',
    --         isboss = true,
    --         bankAuth = true,
    --         payment = 150
    --         },
    --     },
    -- },
    ['ambulance'] = {
        label = 'EMS',
        type = 'ems',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Trainee',
                payment = 100
            },
            [1] = {
                name = 'Nurse',
                payment = 105
            },
            [2] = {
                name = 'EMT',
                payment = 110
            },
            [3] = {
                name = 'Paramedic',
                payment = 115
            },
            [4] = {
                name = 'Doctor',
                payment = 120
            },
            [5] = {
                name = 'Specialist',
                payment = 125
            },
            [6] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },
    ['realestate'] = {
        label = 'Real Estate',
        type = 'realestate',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Seller',
                payment = 0
            },
            -- [1] = {
            --     name = 'House Sales',
            --     payment = 75
            -- },
            -- [2] = {
            --     name = 'Business Sales',
            --     payment = 100
            -- },
            -- [3] = {
            --     name = 'Broker',
            --     payment = 125
            -- },
            -- [4] = {
            --     name = 'Manager',
            --     isboss = true,
            --     bankAuth = true,
            --     payment = 150
            -- },
        },
    },
    ['cardealer'] = {
        label = 'Vehicle Dealer',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 30
            },
            [1] = {
                name = 'Showroom Sales',
                payment = 35
            },
            [2] = {
                name = 'Business Sales',
                payment = 40
            },
            [3] = {
                name = 'Finance',
                payment = 45
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 50
            },
        },
    },
    ['casino'] = {
        label = 'The Casino',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Dealer',
                payment = 30
            },
            [1] = {
                name = 'Manager',
                isboss = true,
                payment = 35
            },
            [2] = {
                name = 'Owner',
                isboss = true,
                bankAuth = true,
                payment = 40
            },
        },
    },
    ['mechanic'] = {
        label = 'Mechanic',
        type = 'mechanic',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 30
            },
            [1] = {
                name = 'Novice',
                payment = 75
            },
            [2] = {
                name = 'Experienced',
                payment = 100
            },
            [3] = {
                name = 'Advanced',
                payment = 125
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },

    ['doj'] = {
        label = 'Doj',
        type = 'doj',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Lawyer',
                payment = 30
            },
            [1] = {
                name = 'Judge',
                isboss = true,
                payment = 75
            },
            [2] = {
                name = 'Lead Judge',
                isboss = true,
                bankAuth = true,
                payment = 100
            },
        },
    },

    ['reporter'] = {
        label = 'Reporter',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Journalist',
                payment = 30
            },
        },
    },

    ['bean'] = {
        label = 'Bean Coffee',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Bean Employee',
                payment = 0
            },
            [1] = {
                name = 'Bean Boss',
				isboss = true,
                bankAuth = true,
                payment = 0
            },
        },
    },

    ['uwu'] = {
        label = 'Black Coffee',
        defaultDuty = false,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Coffee Employee',
                payment = 0
            },
            [1] = {
                name = 'Coffee Boss',
				isboss = true,
                bankAuth = true,
                payment = 0
            },
        },
    },

    
}
