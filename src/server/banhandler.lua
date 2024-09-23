local bannedPlayers = {}

CreateThread(function()
    local bansFile = LoadResourceFile(GetCurrentResourceName(), "src/data/bans.json")
    if bansFile then
        bannedPlayers = json.decode(bansFile)
        if not bannedPlayers or type(bannedPlayers) ~= "table" then
            bannedPlayers = {}
        end
    end
end)

-- [//[ Functions]\\] --
local gBanId = 0
local function generateBanId()
    if gBanId == 0 then
        for k, v in pairs(bannedPlayers) do
            if v["banId"] > gBanId then
                gBanId = v["banId"]
            end
        end
    end
    gBanId = gBanId + 1
    return gBanId
end

local isAlreadyBanned = {}
local function banPlayer(source, reason)
    if (Config.Debugger or false) then
        print("^1BanPlayer(DEBUG)^7 - Source: ^5" .. source .. " ^7- Name: ^5" .. GetPlayerName(source) .. " ^7- Reason: ^5" .. reason)
        return
    end
    if isAlreadyBanned[source] then
        return
    end
    isAlreadyBanned[source] = true

    local banID = generateBanId()
    local banData = {}

    banData["banId"] = tostring(banID)
    banData["name"] = (GetPlayerName(source) or "Unknown")
    banData["datum"] = os.date("%Y-%m-%d %H:%M:%S")
    banData["reason"] = (reason or "No reason provided.")
    banData["identifiers"] = GetPlayerIdentifiers(source)
    banData["userTokens"] = {}
    local numUserTokens = GetNumPlayerTokens(source)
    if numUserTokens ~= 0 then
        for i = 0, numUserTokens - 1 do
            table.insert(banData["userTokens"], GetPlayerToken(source, i))
        end
    end

    bannedPlayers[tostring(banID)] = banData

    SaveResourceFile(GetCurrentResourceName(), "src/data/bans.json", json.encode(bannedPlayers, { indent = true }), -1)
    DropPlayer(source, reason)
    print("^1BanPlayer^7 - Source: ^5" ..source .. " ^7- Name: ^5" .. banData["name"] .. " ^7- Reason: ^5" .. reason)
end

local function checkBan(source)
    local identifiers = GetPlayerIdentifiers(source)
    local numUserTokens = GetNumPlayerTokens(source)

    for _, player in pairs(bannedPlayers) do
        for _, identifier in pairs(player.identifiers) do
            for _, playerIdentifier in pairs(identifiers) do
                if identifier == playerIdentifier then
                    return (player["banId"] or "unkown")
                end
            end
        end

        for _, userToken in pairs(player.userTokens) do
            for i = 0, numUserTokens - 1 do
                if userToken == GetPlayerToken(source, i) then
                    return (player["banId"] or "unkown")
                end
            end
        end
    end

    return false
end

local function blockBan(deferrals, banID, playerName)
    local serverName = Config.ServerName 
    local banData = bannedPlayers[tostring(banID)] or {
        ["reason"] = "No reason provided.",
        ["datum"] = "Unknown"
    }

    local BanblockMessage = {
        ["$schema"] = "http://adaptivecards.io/schemas/adaptive-card.json",
        ["type"] = "AdaptiveCard",
        ["version"] = "1.6",
        ["body"] = {
            -- Server Header
            {
                ["type"] = "TextBlock",
                ["text"] = "• SafeServer | ".. (serverName or "unkown server") .." •",
                ["size"] = "Large",
                ["weight"] = "Bolder",
                ["horizontalAlignment"] = "Center",
                ["spacing"] = "Medium"
            },
            -- Ban notification message
            {
                ["type"] = "TextBlock",
                ["text"] = "You have been banned from playing on • ".. (serverName or "unkown server"),
                ["wrap"] = true,
                ["horizontalAlignment"] = "Center",
                ["spacing"] = "Small"
            },
            {
                ["type"] = "ColumnSet",
                ["horizontalAlignment"] = "Center",
                ["columns"] = {
                    {
                        ["type"] = "Column",
                        ["width"] = "stretch",
                        ["items"] = {
                            {
                                ["type"] = "TextBlock",
                                ["text"] = playerName,
                                ["size"] = "Large",
                                ["weight"] = "Bolder",
                                ["horizontalAlignment"] = "Center"
                            },
                            {
                                ["type"] = "TextBlock",
                                ["text"] = "Banned on: ".. banData["datum"],
                                ["spacing"] = "None",
                                ["isSubtle"] = true,
                                ["wrap"] = true,
                                ["horizontalAlignment"] = "Center"
                            }
                        }
                    }
                },
                ["spacing"] = "Medium"
            },
            {
                ["type"] = "ColumnSet",
                ["horizontalAlignment"] = "Center",
                ["columns"] = {
                    
                    {
                        ["type"] = "Column",
                        ["width"] = "auto",
                        ["items"] = {
                            {
                                ["type"] = "ActionSet",
                                ["actions"] = {
                                    {
                                        ["type"] = "Action.OpenUrl",
                                        ["title"] = "Ban ID: ".. banID 
                                    }
                                }
                            }
                        }
                    },
                    {
                        ["type"] = "Column",
                        ["width"] = "auto",
                        ["items"] = {
                            {
                                ["type"] = "ActionSet",
                                ["actions"] = {
                                    {
                                        ["type"] = "Action.OpenUrl",
                                        ["title"] = "Support",
                                        ["url"] = (Config.SupportDiscord or "https://github.com/snepcnep")  -- Replace with actual more info link
                                    }
                                }
                            }
                        }
                    }
                },
                ["spacing"] = "Medium"
            }
        }
    }
    
    return deferrals.presentCard(BanblockMessage)
end

-- [//[ Events ]\\] --
RegisterNetEvent("playerConnecting", function(playerName, _, deferrals)
    local src = source
    
    deferrals.defer()

    deferrals.update("Checking for bans...")

    Wait(100)

    local banID = checkBan(src)
    if banID then
        blockBan(deferrals, banID, playerName)
        return
    end

    deferrals.done()
end)

RegisterNetEvent("sc-safeServer:banPlayer", function(reason)
    local src = source
    banPlayer(src, reason)
end)

-- [//[ Commands ]\\] --
RegisterCommand("safeServer:unban", function(source, args)
    if source ~= 0 then
        print("This command can only be executed console!")
        return
    end

    local banId = args[1]
    if not banId then
        print("Please provide a ban id!")
        return
    end

    if bannedPlayers[tostring(banId)] then
        local bandata = bannedPlayers[tostring(banId)]
        bannedPlayers[tostring(banId)] = nil
        SaveResourceFile(GetCurrentResourceName(), "src/data/bans.json", json.encode(bannedPlayers, { indent = true }), -1)
        print("Player " .. bandata["name"] .. " has been unbanned!")
    else
        print("This player is not banned!")
    end
end, true)

RegisterCommand("safeServer:baninfo", function(source, args)
    if source ~= 0 then
        print("This command can only be executed console!")
        return
    end

    local banId = args[1]
    if not banId then
        print("Please provide a ban id!")
        return
    end

    if bannedPlayers[tostring(banId)] then
        print(json.encode(bannedPlayers[tostring(banId)], { indent = true }))
    else
        print("This player is not banned!")
    end
end, true)