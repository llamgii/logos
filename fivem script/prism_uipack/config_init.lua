-- shared file used to retrieve config values
-- used by our version of ox_target to retrieve the primary color

RegisterNuiCallback('getConfig', function(data, cb)
    cb({
        primaryColor = GetConvar('prism:primaryColor', '#c96f25ff'),
        notificationDuration = GetConvarInt('prism:notificationDuration', 3000),
        progressCancelKey = GetConvar('prism:progressCancelKey', 'X'),
        targetIcon = GetConvar('prism:targetIcon', 'fas fa-share')
    })
end)

RegisterNuiCallback('getConfigValue', function(property, cb)
    if not property then return end

    local propertyValue = GetConvar(("prism:%s"):format(property), '')
    cb(propertyValue)
end)