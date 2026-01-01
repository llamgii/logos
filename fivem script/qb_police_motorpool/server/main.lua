local QBCore = exports['qb-core']:GetCoreObject()

local vehiclesByModel = {}

local function debugPrint(message)
    if Config.Debug then
        print(('[qb_police_motorpool] %s'):format(message))
    end
end

local function dbInsert(query, params)
    local oxmysqlReady = GetResourceState('oxmysql') == 'started'

    if oxmysqlReady and exports.oxmysql and exports.oxmysql.insert then
        exports.oxmysql:insert(query, params)
        return true
    end

    if MySQL and MySQL.insert then
        MySQL.insert(query, params)
        return true
    end

    if MySQL and MySQL.Async and MySQL.Async.execute then
        MySQL.Async.execute(query, params)
        return true
    end

    debugPrint('No SQL handler available; vehicle ownership not persisted.')
    return false
end

local function refreshVehicleLookup()
    vehiclesByModel = {}
    for _, vehicle in ipairs(Config.Vehicles) do
        if vehicle.model then
            vehiclesByModel[vehicle.model] = vehicle
        end
    end
end

local function generatePlate()
    local prefix = (Config.PlatePrefix or 'LSPD'):upper()
    local numeric = QBCore.Shared.RandomInt(2)
    local alpha = QBCore.Shared.RandomStr(2)
    local plate = (prefix .. numeric .. alpha):upper()
    return string.sub(plate, 1, 8)
end

local function hasRequiredGrade(player)
    local job = player.PlayerData.job
    if not job or job.name ~= Config.JobName then
        return false, 'You are not allowed to use this service.'
    end

    local gradeLevel = job.grade and (job.grade.level or job.grade) or 0
    local required = Config.MinGrade or 0
    if gradeLevel < required then
        return false, ('You need grade %s or higher.'):format(required)
    end

    return true
end

local function getPlayerLicense(player)
    local metadata = player.PlayerData.metadata or {}
    return player.PlayerData.license
        or metadata.license
        or metadata.licence
        or ('cid:' .. tostring(player.PlayerData.citizenid))
end

local function persistVehicle(player, vehicleData, plate, props)
    if type(props) ~= 'table' then return end

    local garage = (vehicleData and vehicleData.garage) or Config.DefaultGarage or 'police'
    local license = getPlayerLicense(player)
    local citizenid = player.PlayerData.citizenid
    local modelName = vehicleData and vehicleData.model or props.model
    local hash = props.model or (modelName and joaat(modelName)) or 0
    local fuel = props.fuelLevel or props.fuel or 100.0
    local engine = props.engineHealth or 1000.0
    local body = props.bodyHealth or props.body or 1000.0

    plate = string.upper(plate)

    props.plate = plate
    props.fuelLevel = fuel
    props.engineHealth = engine
    props.bodyHealth = body

    local query = [[
        INSERT INTO player_vehicles
            (license, citizenid, vehicle, hash, mods, plate, garage, state, depotprice, fuel, engine, body)
        VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            mods = VALUES(mods),
            garage = VALUES(garage),
            state = VALUES(state),
            depotprice = VALUES(depotprice),
            fuel = VALUES(fuel),
            engine = VALUES(engine),
            body = VALUES(body)
    ]]

    local success = dbInsert(query, {
        license,
        citizenid,
        modelName,
        hash,
        json.encode(props),
        plate,
        garage,
        0,
        0,
        fuel,
        engine,
        body
    })

    if success then
        debugPrint(('Persisted %s (%s) for %s in garage %s'):format(modelName or 'unknown', plate, citizenid, garage))
    end
end

RegisterNetEvent('qb_police_motorpool:server:attemptPurchase', function(model)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local vehicleData = vehiclesByModel[model]
    if not vehicleData then
        debugPrint(('Model %s not configured.'):format(tostring(model)))
        TriggerClientEvent('qb_police_motorpool:client:notify', src, {
            message = 'Vehicle unavailable.',
            type = 'error',
            title = Config.NotifyTitle or 'Motor Pool',
            icon = vehicleData and vehicleData.icon or Config.TargetIcon
        })
        return
    end

    local allowed, reason = hasRequiredGrade(player)
    if not allowed then
        TriggerClientEvent('qb_police_motorpool:client:notify', src, {
            message = reason or 'Access denied.',
            type = 'error',
            title = Config.NotifyTitle or 'Motor Pool',
            icon = vehicleData and vehicleData.icon or Config.TargetIcon
        })
        return
    end

    local price = vehicleData.price or 0
    local account = vehicleData.account or Config.MoneyAccount or 'bank'
    if price > 0 then
        if player.Functions.GetMoney(account) < price then
            TriggerClientEvent('qb_police_motorpool:client:notify', src, {
                message = 'Not enough money.',
                type = 'error',
                title = Config.NotifyTitle or 'Motor Pool',
                icon = vehicleData and vehicleData.icon or Config.TargetIcon
            })
            return
        end
        player.Functions.RemoveMoney(account, price, 'police-motorpool-purchase')
        TriggerClientEvent('qb_police_motorpool:client:notify', src, {
            message = ('$%s paid from %s.'):format(price, account),
            type = 'inform',
            title = Config.NotifyTitle or 'Motor Pool',
            icon = vehicleData and vehicleData.icon or Config.TargetIcon
        })
    end

    local plate = generatePlate()
    debugPrint(('Issuing %s (%s) to %s'):format(vehicleData.model, plate, player.PlayerData.citizenid))

    TriggerClientEvent('qb_police_motorpool:client:spawnVehicle', src, {
        model = vehicleData.model,
        plate = plate,
        label = vehicleData.label,
        price = price,
        garage = vehicleData.garage or Config.DefaultGarage,
        message = vehicleData.successMessage or ('%s ready for duty.'):format(vehicleData.label or vehicleData.model),
        icon = vehicleData.icon or Config.TargetIcon
    })
end)

RegisterNetEvent('qb_police_motorpool:server:storeVehicle', function(props, data)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    if type(props) ~= 'table' or type(data) ~= 'table' then return end

    local vehicleData = vehiclesByModel[data.model]
    if not vehicleData then
        debugPrint(('Store request rejected: %s not configured.'):format(tostring(data.model)))
        return
    end

    local allowed = hasRequiredGrade(player)
    if not allowed then
        debugPrint(('Store request rejected: %s lacks grade.'):format(player.PlayerData.citizenid))
        return
    end

    local plate = (data.plate or props.plate or generatePlate()):upper()
    persistVehicle(player, vehicleData, plate, props)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    refreshVehicleLookup()
    debugPrint('Resource start: vehicle cache initialized.')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    vehiclesByModel = {}
end)

refreshVehicleLookup()
