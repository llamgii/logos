RegisterNetEvent('qbx_ped_interact:giveItem', function()
    local src = source
    local reward = Config.Reward

    if not reward.item or reward.item == '' then
        return
    end

    exports.ox_inventory:AddItem(src, reward.item, reward.count or 1)
end)
