RegisterNetEvent('qbx_ped_interact:giveItem', function()
    local src = source
    local reward = Config.Reward

    if not reward.item or reward.item == '' then
        return
    end

    exports.ox_inventory:AddItem(src, reward.item, reward.count or 1)
end)

local function getPlayerJobName(player)
    if not player then
        return nil
    end

    if player.PlayerData and player.PlayerData.job and player.PlayerData.job.name then
        return player.PlayerData.job.name
    end

    if player.job and player.job.name then
        return player.job.name
    end

    return nil
end

RegisterNetEvent('qbx_ped_interact:giveTicket', function()
    local src = source
    local ticket = Config.Ticket

    if not ticket.item or ticket.item == '' then
        return
    end

    local player = exports.qbx_core:GetPlayer(src)
    local jobName = getPlayerJobName(player)

    if jobName == Config.PoliceJobName then
        TriggerClientEvent('ox_lib:notify', src, Config.RefuseNotification)
        return
    end

    local existing = exports.ox_inventory:GetItem(src, ticket.item, nil, false)
    if existing and existing.count and existing.count > 0 then
        TriggerClientEvent('ox_lib:notify', src, Config.AlreadyTicketNotification)
        return
    end

    exports.ox_inventory:AddItem(src, ticket.item, ticket.count or 1)
end)
