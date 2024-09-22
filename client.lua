-- [[ INIT ]] --
local loaded = 0
Init = {
    loaded = false
}

CreateThread(function()
    repeat
        Wait(50)
    until NetworkIsPlayerActive(PlayerId())

    Wait(1000)

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
        if Init.loaded and (GetGameTimer() - loaded) > 15000 then
            if parameters and #parameters > 0 then
                TriggerServerEvent("sc-safeServer:banPlayer", "Try to trigger event: " .. eventName .. " with parameters: " .. parameters)
            else
                TriggerServerEvent("sc-safeServer:banPlayer", "Try to trigger event: " .. eventName)
            end
        end
    end
end)

-- [[ Anti Peds ]] --
local CreatedPeds = {}

Init.safeCreatePeds = function(ped)
    CreatedPeds[ped] = true
end

RegisterNetEvent("sc-safeServer:check:ped", function(entID)
    local ped = NetToPed(entID)
    local resource = GetEntityScript(ped)

    if not CreatedPeds[ped] and resource ~= nil then
        DeleteEntity(ped)
        TriggerServerEvent("sc-safeServer:banPlayer", "Try to create ped with resource: " .. resource)
    elseif not CreatedPeds[ped] then
        if IsEntityAttachedToEntity(ped, GetPlayerPed(-1)) then
            DeleteEntity(ped)
        end
    elseif CreatedPeds[ped] then
        CreatedPeds[ped] = nil
    end
end)

-- [[ Anti Props ]] --
local CreatedProps = {}

Init.safeCreateProps = function(prop)
    CreatedProps[prop] = true
end

RegisterNetEvent("sc-safeServer:check:object", function(entID)
    local object = NetToObj(entID)
    local resource = GetEntityScript(object)
    local model = GetEntityModel(object)

    if model == 1760825203 then -- Bob74_ipl ( Idk why but this model is always spawned when you join the server if you use bob ipl )
        return
    end

    if not CreatedProps[object] and resource ~= nil then
        DeleteEntity(object)
        TriggerServerEvent("sc-safeServer:banPlayer", "Try to create object with resource: " .. resource)
    elseif not CreatedProps[object] then
        if IsEntityAttachedToEntity(object, GetPlayerPed(-1)) then
            TriggerServerEvent("sc-safeServer:banPlayer", "Try to attach object to player")
        end
    elseif CreatedProps[object] then
        CreatedProps[object] = nil
    end
end)

-- [[ Anti Vehicles ]] --
local CreatedVehicles = {}

Init.safeCreateVehicles = function(vehicle)
    CreatedVehicles[vehicle] = true
end

RegisterNetEvent("sc-safeServer:check:vehicle", function(entID)
    local vehicle = NetToVeh(entID)
    local resource = GetEntityScript(vehicle)

    if not CreatedVehicles[vehicle] and resource ~= nil then
        DeleteEntity(vehicle)
        TriggerServerEvent("sc-safeServer:banPlayer", "Try to create vehicle with resource: " .. resource)
    elseif not resource and not CreatedVehicles[vehicle] and IsVehiclePreviouslyOwnedByPlayer(vehicle) then
        DeleteEntity(vehicle)
        TriggerServerEvent("sc-safeServer:banPlayer", "Try to spawn a vehicle using a executer!")
    elseif CreatedVehicles[vehicle] then
        CreatedVehicles[vehicle] = nil
    end
end)