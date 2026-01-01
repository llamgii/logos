local QBCore = exports['qb-core']:GetCoreObject()

local pedEntity
local targetActive = false
local useOxTarget = false

local function normalizeType(value, fallback)
    local t = value or fallback or 'inform'
    if t == 'primary' then
        return 'info'
    end
    return t
end

local function debugPrint(message)
    if Config.Debug then
        print(('[qb_police_motorpool] %s'):format(message))
    end
end

local function notify(payload, notifType, duration)
    local data = payload

    if type(data) ~= 'table' then
        data = {
            description = tostring(payload),
            type = notifType,
            duration = duration
        }
    end

    data.description = data.description or data.message or data.text or ''
    data.type = normalizeType(data.type, notifType)
    data.title = data.title or Config.NotifyTitle or 'Motor Pool'

    if Config.UseOxLibNotify and lib and lib.notify then
        lib.notify({
            title = data.title,
            description = data.description,
            type = data.type,
            duration = data.duration
        })
    else
        local qbType = data.type == 'inform' and 'primary' or data.type
        QBCore.Functions.Notify(data.description, qbType or 'primary', data.duration)
    end
end

local function loadModel(model)
    local hash = model
    if type(hash) == 'string' then
        hash = joaat(hash)
    end

    if not IsModelInCdimage(hash) then
        debugPrint(('Model %s is not in the game files.'):format(tostring(model)))
        return nil
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(0)
    end
    return hash
end

local function removeTarget()
    if targetActive and pedEntity and DoesEntityExist(pedEntity) and GetResourceState('ox_target') == 'started' then
        exports.ox_target:removeLocalEntity(pedEntity)
    end
    targetActive = false
end

local function registerTarget()
    useOxTarget = Config.UseOxTarget and GetResourceState('ox_target') == 'started'

    if not useOxTarget or not pedEntity or not DoesEntityExist(pedEntity) then
        removeTarget()
        return
    end

    local label = Config.TargetLabel or 'Motor Pool'
    local icon = Config.TargetIcon or 'fa-solid fa-car'

    exports.ox_target:addLocalEntity(pedEntity, {
        {
            name = 'qb_police_motorpool:openMenu',
            icon = icon,
            label = label,
            onSelect = function()
                openVehicleMenu()
            end
        }
    })

    targetActive = true
end

local function spawnMotorpoolPed()
    if pedEntity and DoesEntityExist(pedEntity) then
        removeTarget()
        DeleteEntity(pedEntity)
    end

    local pedConfig = Config.Ped
    local model = loadModel(pedConfig.model)
    if not model then
        return
    end

    local coords = pedConfig.coords
    pedEntity = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityAsMissionEntity(pedEntity, true, true)
    SetEntityCanBeDamaged(pedEntity, false)
    SetBlockingOfNonTemporaryEvents(pedEntity, true)
    FreezeEntityPosition(pedEntity, true)
    SetPedDiesWhenInjured(pedEntity, false)
    SetPedFleeAttributes(pedEntity, 0, false)
    SetPedArmour(pedEntity, 100)
    SetEntityInvincible(pedEntity, true)

    if pedConfig.scenario then
        TaskStartScenarioInPlace(pedEntity, pedConfig.scenario, 0, true)
    end

    SetModelAsNoLongerNeeded(model)
    registerTarget()
    debugPrint('Motor pool ped spawned.')
end

local function DrawText3D(x, y, z, text)
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(screenX, screenY)

    local factor = (string.len(text) / 300)
    DrawRect(screenX, screenY + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 150)
end

function openVehicleMenu()
    if #Config.Vehicles == 0 then
        notify('No vehicles configured.', 'error')
        return
    end

    if Config.UseOxLibMenu and lib and lib.registerContext then
        local menuId = Config.OxLibContextId or 'qb_police_motorpool_menu'
        local options = {}

        for _, vehicle in ipairs(Config.Vehicles) do
            local priceLabel
            if vehicle.price and vehicle.price > 0 then
                priceLabel = ('$%s'):format(vehicle.price)
            else
                priceLabel = 'Free'
            end

            options[#options + 1] = {
                title = vehicle.label,
                description = priceLabel,
                icon = vehicle.icon or Config.TargetIcon or 'car',
                onSelect = function()
                    TriggerServerEvent('qb_police_motorpool:server:attemptPurchase', vehicle.model)
                end
            }
        end

        lib.registerContext({
            id = menuId,
            title = Config.MenuHeader or 'Motor Pool',
            options = options
        })

        lib.showContext(menuId)
        return
    end

    if GetResourceState('qb-menu') == 'started' then
        local menu = {
            {
                header = Config.MenuHeader or 'Motor Pool',
                isMenuHeader = true
            }
        }

        for _, vehicle in ipairs(Config.Vehicles) do
            local priceLabel
            if vehicle.price and vehicle.price > 0 then
                priceLabel = ('$%s'):format(vehicle.price)
            else
                priceLabel = 'Free'
            end

            menu[#menu + 1] = {
                header = ('%s [%s]'):format(vehicle.label, priceLabel),
                params = {
                    event = 'qb_police_motorpool:client:selectedVehicle',
                    args = vehicle.model
                }
            }
        end

        menu[#menu + 1] = {
            header = 'Close',
            params = { event = 'qb-menu:closeMenu' }
        }

        exports['qb-menu']:openMenu(menu)
    else
        debugPrint('Menu resource not running, defaulting to first vehicle.')
        local vehicle = Config.Vehicles[1]
        if vehicle then
            TriggerServerEvent('qb_police_motorpool:server:attemptPurchase', vehicle.model)
        else
            notify('No vehicles configured.', 'error')
        end
    end
end

RegisterNetEvent('qb_police_motorpool:client:selectedVehicle', function(model)
    TriggerServerEvent('qb_police_motorpool:server:attemptPurchase', model)
end)

RegisterNetEvent('qb_police_motorpool:client:notify', function(data)
    if type(data) ~= 'table' then
        notify(data or 'Notification')
        return
    end

    data.description = data.description or data.message or data.text
    notify(data, data.type or 'inform')
end)

RegisterNetEvent('qb_police_motorpool:client:spawnVehicle', function(data)
    local spawn = Config.VehicleSpawn
    if not spawn then
        notify('No vehicle spawn configured.', 'error')
        return
    end

    QBCore.Functions.SpawnVehicle(data.model, function(vehicle)
        SetVehicleModKit(vehicle, 0)
        SetVehicleNumberPlateText(vehicle, data.plate or 'MOTOR')
        SetEntityHeading(vehicle, spawn.w)
        SetVehicleFuelLevel(vehicle, 100.0)
        SetVehicleDirtLevel(vehicle, 0.0)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

        if Config.UseKeys ~= false then
            local keysResource = Config.KeysResource or 'qb-vehiclekeys'
            if keysResource ~= '' and GetResourceState(keysResource) == 'started' then
                local eventName = keysResource .. ':client:SetOwner'
                TriggerEvent(eventName, data.plate)
            elseif GetResourceState('qb-vehiclekeys') == 'started' then
                TriggerEvent('qb-vehiclekeys:client:SetOwner', data.plate)
            elseif GetResourceState('vehiclekeys') == 'started' then
                TriggerEvent('vehiclekeys:client:SetOwner', data.plate)
            end
        end

        SetVehicleEngineOn(vehicle, true, true, true)
        notify({
            description = data.message or 'Vehicle issued. Drive safe!',
            type = 'success',
            title = Config.NotifyTitle or 'Motor Pool'
        })

        local props = QBCore.Functions.GetVehicleProperties(vehicle)
        if props then
            props.plate = data.plate or GetVehicleNumberPlateText(vehicle)
            TriggerServerEvent('qb_police_motorpool:server:storeVehicle', props, {
                model = data.model,
                plate = props.plate,
                garage = data.garage,
                label = data.label
            })
        end
    end, spawn, true)
end)

CreateThread(function()
    spawnMotorpoolPed()

    while true do
        local sleep = 1000

        if Config.UseOxTarget then
            local state = GetResourceState('ox_target')
            if state == 'started' then
                if pedEntity and DoesEntityExist(pedEntity) and not targetActive then
                    registerTarget()
                end
            elseif targetActive then
                removeTarget()
            end
        end

        if pedEntity and DoesEntityExist(pedEntity) then
            if Config.UseOxTarget and GetResourceState('ox_target') == 'started' then
                sleep = 1000
            else
                local pedCoords = GetEntityCoords(pedEntity)
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(playerCoords - pedCoords)

                if distance <= (Config.InteractDistance or 2.0) then
                    sleep = 0
                    DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z + (Config.DrawTextOffset or 1.05), Config.InteractText or 'Press [E] to interact')

                    if IsControlJustReleased(0, 38) then
                        openVehicleMenu()
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(500)
    spawnMotorpoolPed()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if pedEntity and DoesEntityExist(pedEntity) then
        removeTarget()
        DeleteEntity(pedEntity)
    end
end)
