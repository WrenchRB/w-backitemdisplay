RegisterCommand("test", function (source)
    local identifier
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        identifier = xPlayer.identifier
    elseif QBCore then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        identifier = xPlayer.PlayerData.citizenid
    end
    local response = exports['codem-inventory']:GetInventory(identifier, source)
    print(json.encode(response, {indent=true}))
end)
