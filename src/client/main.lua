-- [[ INIT ]] --
local loaded = 0
Init = {
    loaded = false
}

CreateThread(function()
    repeat
        Wait(50)
    until NetworkIsPlayerActive(PlayerId())

    Wait(5000)

    Init.loaded = true
    loaded = GetGameTimer()
end)

exports("init", function()
    return Init
end)

-- [[ Server Events Protection ]] --
local TriggeredServerEvents = {}
Init.safeServerTrigger = function(eventName)
    if not TriggeredServerEvents[eventName] then
        TriggeredServerEvents[eventName] = 0
    end
    TriggeredServerEvents[eventName] += 1
end

RegisterNetEvent("sc-safeServer:check:event", function(eventName, parameters)
    if TriggeredServerEvents[eventName] and TriggeredServerEvents[eventName] > 0 then
        TriggeredServerEvents[eventName] -= 1
    else
        if Init.loaded and (GetGameTimer() - loaded) > 30000 then
            if parameters and #parameters < 1 then
                TriggerServerEvent("sc-safeServer:banPlayer", "Try to trigger event: " .. eventName .. " with parameters: " .. parameters)
            else
                TriggerServerEvent("sc-safeServer:banPlayer", "Try to trigger event: " .. eventName)
            end
        end
    end
end)
