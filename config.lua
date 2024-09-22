Config = {}

Config.WhitelistedResource = {
    ["monitor"] = true
}

Config.WhiteListedEvents = {
    [""] = true
}

Config.BanFunction = false
-- Config.BanFunction = function(source, reason)
--     DropPlayer(source, reason)
--     print("Player ".. source .." has been banned for reason: " .. reason)
-- end