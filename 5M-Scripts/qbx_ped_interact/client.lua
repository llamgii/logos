local pedEntity

local function spawnPed()
    local model = joaat(Config.Ped.model)
    lib.requestModel(model)

    local coords = Config.Ped.coords
    pedEntity = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)

    SetEntityInvincible(pedEntity, true)
    SetBlockingOfNonTemporaryEvents(pedEntity, true)
    FreezeEntityPosition(pedEntity, true)

    if Config.Ped.scenario then
        TaskStartScenarioInPlace(pedEntity, Config.Ped.scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(pedEntity, {
        {
            label = Config.Target.label,
            icon = Config.Target.icon,
            distance = Config.Target.distance,
            onSelect = function()
                lib.registerContext({
                    id = 'qbx_ped_interact_menu',
                    title = Config.Menu.title,
                    options = {
                        {
                            title = Config.Menu.buttonLabel,
                            description = Config.Menu.description,
                            icon = 'fa-solid fa-bottle-water',
                            onSelect = function()
                                TriggerServerEvent('qbx_ped_interact:giveItem')
                            end,
                        },
                        {
                            title = Config.Menu.ticketLabel,
                            description = 'Receive a street fight ticket.',
                            icon = 'fa-solid fa-ticket',
                            onSelect = function()
                                TriggerServerEvent('qbx_ped_interact:giveTicket')
                            end,
                        },
                    },
                })

                lib.showContext('qbx_ped_interact_menu')
            end,
        }
    })
end

CreateThread(function()
    spawnPed()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    if pedEntity and DoesEntityExist(pedEntity) then
        DeleteEntity(pedEntity)
    end
end)
