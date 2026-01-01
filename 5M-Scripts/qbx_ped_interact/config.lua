Config = {}

Config.Peds = {
    {
        model = 'a_m_y_business_01',
        coords = vec4(-1827.97, -1246.83, 13.45, 321.11),
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    },
    {
        model = 'a_m_y_business_01',
        coords = vec4(232.1, -903.73, 30.69, 56.87),
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    },
    {
        model = 'a_m_y_business_01',
        coords = vec4(-273.69, -1919.68, 29.95, 317.12),
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    },
Config.Ped = {
    model = 'a_m_y_business_01',
    coords = vec4(-1827.97, -1246.83, 13.45, 321.11),
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
}

Config.Target = {
    label = 'Talk to Clerk',
    icon = 'fa-solid fa-comment',
    distance = 2.0,
}

Config.Reward = {
    item = 'water',
    count = 1,
}

Config.Ticket = {
    item = 'streetfight_ticket',
    count = 1,
}

Config.PoliceJobName = 'police'

Config.RefuseNotification = {
    description = "We're sorry, we are not dealing with Police officers.",
    type = 'error',
}

Config.AlreadyTicketNotification = {
    description = 'You already took the ticket.',
    type = 'error',
}

Config.Menu = {
    title = 'Corner Store Clerk',
    description = 'Need something? I can give you a bottle of water.',
    buttonLabel = 'Get Water',
    ticketLabel = 'Get Streetfight Ticket',
}
