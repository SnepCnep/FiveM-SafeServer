local isServerSide = IsDuplicityVersion()
local isClientSide = not isServerSide

if isServerSide then
    local registeredProtEvents = {}

    local _RegisterNetEvent = RegisterNetEvent
    local _RegisterServerEvent = RegisterServerEvent

    _RegisterNetEvent("sc-safeServer:request:eventNames", function(eventName)
        if eventName ~= GetCurrentResourceName() and eventName ~= "all" then
            return 
        end
        
        local res = GetInvokingResource()
        if not res then
            return
        end

        TriggerEvent("sc-safeServer:receive:eventNames", registeredProtEvents)
    end)

    ---@diagnostic disable-next-line: duplicate-set-field
    _G.RegisterNetEvent = function(eventName, ...)
        _RegisterNetEvent(eventName, ...)
        table.insert(registeredProtEvents, eventName)
    end

    ---@diagnostic disable-next-line: duplicate-set-field
    _G.RegisterServerEvent = function(eventName, ...)
        _RegisterServerEvent(eventName, ...)
        table.insert(registeredProtEvents, eventName)
    end
end

if isClientSide then
    local core

    CreateThread(function()
        repeat
            Wait(10)
        until GetResourceState("sc-safeServer") == "started" or GetResourceState("sc-safeServer") == "missing"

        local success, err = pcall(function()
            core = exports["sc-safeServer"]:init()
        end)
    end)

    local _TriggerServerEvent = TriggerServerEvent

    ---@diagnostic disable-next-line: duplicate-set-field
    _G.TriggerServerEvent = function(eventName, ...)
        local success, err

        if not core or not core.safeServerTrigger then
            success, err = pcall(function()
                core = exports["sc-safeServer"]:init()
            end)
        end

        if core and core.safeServerTrigger then
            core.safeServerTrigger(eventName)
        end

        _TriggerServerEvent(eventName, ...)
    end

    local _CreateObject = CreateObject
    local _CreatePed = CreatePed
    local _CreateVehicle = CreateVehicle

    ---@diagnostic disable-next-line: duplicate-set-field
    _G.CreateObject = function(modelHash, x, y, z, isNetwork, thisScriptCheck)
        local ent = _CreateObject(modelHash, x, y, z, isNetwork, thisScriptCheck)
        if ent ~= 0 and core and core.safeCreateProps then
            core.safeCreateProps(ent)
        end
        return ent
    end

    ---@diagnostic disable-next-line: duplicate-set-field
    _G.CreatePed = function(pedType, modelHash, x, y, z, heading, isNetwork, thisScriptCheck)
        local ent = _CreatePed(pedType, modelHash, x, y, z, heading, isNetwork, thisScriptCheck)
        if ent ~= 0 and core and core.safeCreatePeds then
            core.safeCreatePeds(ent)
        end
        return ent
    end

    ---@diagnostic disable-next-line: duplicate-set-field
    _G.CreateVehicle = function(modelHash, x, y, z, heading, isNetwork, thisScriptCheck)
        local ent = _CreateVehicle(modelHash, x, y, z, heading, isNetwork, thisScriptCheck)
        if ent ~= 0 and core and core.safeCreateVehicles then
            core.safeCreateVehicles(ent)
        end
        return ent
    end
end