Config = {}

Config.Debug = false
Config.JobName = 'police'
Config.MinGrade = 12
Config.MoneyAccount = 'bank'
Config.MenuHeader = 'LSPD Motor Pool'
Config.InteractText = '~g~E~w~ - Access the motor pool'
Config.InteractDistance = 2.0
Config.DrawTextOffset = 1.05
Config.UseKeys = true
Config.KeysResource = 'qb-vehiclekeys'
Config.PlatePrefix = 'LSPD'
Config.UseOxTarget = true
Config.TargetLabel = 'Access Motor Pool'
Config.TargetIcon = 'fa-solid fa-car'
Config.UseOxLibMenu = true
Config.OxLibContextId = 'qb_police_motorpool_menu'
Config.UseOxLibNotify = true
Config.NotifyTitle = 'Motor Pool'
Config.DefaultGarage = 'mrpd'

Config.Ped = {
    model = 's_m_y_cop_01',
    coords = vector4(451.71, -974.09, 25.7, 175.03),
    scenario = 'WORLD_HUMAN_CLIPBOARD'
}

Config.VehicleSpawn = vector4(445.46, -986.21, 25.7, 268.81)

Config.Vehicles = {
    {
        label = 'Dinka Blista',
        model = 'blista',
        price = 5000,
        garage = 'mrpd',
        description = 'Compact patrol unit issued to supervisors',
        icon = 'car-side'
    }
}
