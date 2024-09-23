CreateThread(function()
    while not GetResourceState("sc-safeServer") == "started" do
        Wait(500)
    end

    TriggerEvent("sc-safeServer:request:eventNames", "all")
end)

---@diagnostic disable-next-line: lowercase-global
_print = print
function print(message)
    if not message or type(message) ~= "string" then
        _print("^7[^5ANTICHEAT^7] ^4- ^7Invalid message^7")
        return
    end
    _print("^7[^5ANTICHEAT^7] ^4- ^7" .. message .. "^7")
end

-- [[ Server Events Protection ]] --
RegisterNetEvent("onResourceStart", function(res)
    if res == "sc-safeServer" then
        return
    end
    
    TriggerEvent("sc-safeServer:request:eventNames", res)
end)

local defaultWhitelistedEvents = {
    "__cfx_internal:commandFallback",
    "_chat:messageEntered"
}

for _, eventName in ipairs(defaultWhitelistedEvents) do
    Config.WhiteListedEvents[eventName] = true
end

local registeredEvents = {}
RegisterNetEvent("sc-safeServer:receive:eventNames", function(eventNames)
    if eventNames and #eventNames == 0 then
        return
    end

    local res = GetInvokingResource()
    if not res then
        return
    end

    for _, eventName in pairs(eventNames) do
        if not registeredEvents[eventName] and not Config.WhiteListedEvents[eventName] then
            registeredEvents[eventName] = true
            RegisterNetEvent(eventName, function(...)
                if not source then
                    return
                end

                local parameters = json.encode({...}) or "[]"
                TriggerClientEvent("sc-safeServer:check:event", source, eventName, parameters)
            end)
        end
    end
end)

-- [[ Anti Entitys ]] --
AddEventHandler('entityCreated', function(entity)
    if not DoesEntityExist(entity) then
        return
    end
    
    local id = NetworkGetEntityOwner(entity)
    local entID = NetworkGetNetworkIdFromEntity(entity)
    local entitytype = GetEntityType(entity)

    if entitytype == 1 then
        ---@diagnostic disable-next-line: cast-local-type
        entitytype = "ped"
    elseif entitytype == 2 then
        ---@diagnostic disable-next-line: cast-local-type
        entitytype = "vehicle"
    elseif entitytype == 3 then
        ---@diagnostic disable-next-line: cast-local-type
        entitytype = "object"
    end
    
    TriggerClientEvent("sc-safeServer:check:".. entitytype, id, entID)
    print("^1Entity: ^3" .. entitytype .. " ^1| ID: ^3" .. entID .. " ^1| Owner: ^3" .. id .. "^0")
end)

-- [//[In/Un-stallers]\\] --
local function isResourceAScript(resourceName)
    return true -- Check if the resource has client_scripts or client_script
end

local function installResource(resourceName)
    if isResourceAScript(resourceName) then
        local currentResource = "@" .. GetCurrentResourceName() .. "/init.lua"
        local currentResourceMatch = currentResource:gsub("-", "%%-")
        local resourcePath = GetResourcePath(resourceName)
        if resourcePath ~= nil then
            local fxmanifestFile = LoadResourceFile(resourceName, "fxmanifest.lua")
            if fxmanifestFile then
                fxmanifestFile = tostring(fxmanifestFile)
                local sharedScript = fxmanifestFile:match("shared_script '" .. currentResourceMatch .. "'\n")
                if not sharedScript then
                    fxmanifestFile = "shared_script '" .. currentResource .. "'\n" .. fxmanifestFile
                    SaveResourceFile(resourceName, "fxmanifest.lua", fxmanifestFile, -1)
                    return true
                end
            else
                local __resourceFile = LoadResourceFile(resourceName, "__resource.lua")
                if __resourceFile then
                    __resourceFile = tostring(__resourceFile)
                    local sharedScript = __resourceFile:match("shared_script '" .. currentResourceMatch .. "'\n")
                    if not sharedScript then
                        __resourceFile = "shared_script '" .. currentResource .. "'\n" .. __resourceFile
                        SaveResourceFile(resourceName, "__resource.lua", __resourceFile, -1)
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function uninstallResource(resourceName)
    local currentResource = "@" .. GetCurrentResourceName() .. "/init.lua"
    local currentResourceMatch = currentResource:gsub("-", "%%-")
    local resourcePath = GetResourcePath(resourceName)
    if resourcePath ~= nil then
        local fxmanifestFile = LoadResourceFile(resourceName, "fxmanifest.lua")
        if fxmanifestFile then
            fxmanifestFile = tostring(fxmanifestFile)
            local sharedScript = fxmanifestFile:match("shared_script '" .. currentResourceMatch .. "'\n")
            if sharedScript then
                fxmanifestFile = fxmanifestFile:gsub("shared_script '" .. currentResourceMatch .. "'\n", "")
                SaveResourceFile(resourceName, "fxmanifest.lua", fxmanifestFile, -1)
                return true
            end
        else
            local __resourceFile = LoadResourceFile(resourceName, "__resource.lua")
            if __resourceFile then
                __resourceFile = tostring(__resourceFile)
                local sharedScript = __resourceFile:match("shared_script '" .. currentResourceMatch .. "'\n")
                if sharedScript then
                    __resourceFile = __resourceFile:gsub("shared_script '" .. currentResourceMatch .. "'\n", "")
                    SaveResourceFile(resourceName, "__resource.lua", __resourceFile, -1)
                    return true
                end
            end
        end
    end

    return false
end

RegisterCommand("safeServer:install", function(source, args)
    if source ~= 0 then
        return
    end

    if args[1] then
        if GetResourceState(args[1]) == "missing" then
            print("^1Resource: ^3" .. args[1] .. " ^1Dont exists or cant be found!^0")
            return
        end
        if Config.WhitelistedResource[args[1]] then
            print("^1Resource: ^3" .. args[1] .. " ^1is whitelisted and cannot be installed.^0")
            return
        end
        if args[1] == GetCurrentResourceName() then
            print("^1Resource: ^3" .. args[1] .. " ^1is the current resource and cannot be installed.^0")
            return
        end
        if installResource(args[1]) then
            print("^2installed Resource: ^3" .. args[1] .. " ^2successfully!^0")
        else
            print("^1Resource: ^3" .. args[1] .. " ^1is already installed.^0")
        end
        return
    end

    local resCount = GetNumResources()
    for i = 0, resCount - 1 do
        local resource = GetResourceByFindIndex(i)
        if not Config.WhitelistedResource[resource] and resource ~= GetCurrentResourceName() then
            if installResource(resource) then
                print("^2Installed Resource: ^3" .. resource .. " ^2successfully!^0")
            end
        end
    end
    print("^2Please restart the server to complete the installation.^0")
end, false)

RegisterCommand("safeServer:uninstall", function(source, args)
    if source ~= 0 then
        return
    end
    if args[1] then
        if GetResourceState(args[1]) == "missing" then
            print("^1Resource: ^3" .. args[1] .. " ^1Dont exists or cant be found!^0")
            return
        end

        if args[1] == GetCurrentResourceName() then
            print("^1Resource: ^3" .. args[1] .. " ^1is the current resource and cannot be uninstalled.^0")
            return
        end
        if uninstallResource(args[1]) then
            print("^2Uninstalled Resource: ^3" .. args[1] .. " ^2successfully!^0")
        else
            print("^1Resource: ^3" .. args[1] .. " ^1is already uninstalled.^0")
        end
        return
    end

    local resCount = GetNumResources()
    for i = 0, resCount - 1 do
        local resource = GetResourceByFindIndex(i)
        if uninstallResource(resource) then
            print("^1Uninstalled Resource: ^3" .. resource .. " ^1successfully!^0")
        end
    end
    print("^1Please restart the server to complete the uninstallation.^0")
end, false)
