local pedEntities = {}

local function registerPedTarget(entity)
    exports.ox_target:addLocalEntity(entity, {
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

local function spawnPed(pedConfig)
    local model = joaat(pedConfig.model)
    lib.requestModel(model)

    local coords = pedConfig.coords
    local pedEntity = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)

    SetEntityInvincible(pedEntity, true)
    SetBlockingOfNonTemporaryEvents(pedEntity, true)
    FreezeEntityPosition(pedEntity, true)

    if pedConfig.scenario then
        TaskStartScenarioInPlace(pedEntity, pedConfig.scenario, 0, true)
    end

    registerPedTarget(pedEntity)
    table.insert(pedEntities, pedEntity)
end

CreateThread(function()
    for _, pedConfig in ipairs(Config.Peds) do
        spawnPed(pedConfig)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end

    for _, pedEntity in ipairs(pedEntities) do
        if DoesEntityExist(pedEntity) then
            DeleteEntity(pedEntity)
        end
    end
end)
