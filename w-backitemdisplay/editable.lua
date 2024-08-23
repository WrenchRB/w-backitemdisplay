if IsDuplicityVersion() then
    local datas = {} 
    QBCore = exports['qb-core']:GetCoreObject()

    -- Function to get weapons from a player's inventory
    function GetWeaponsFromPlayer(xPlayer)
        local weapons = {}
        for _, v in pairs(xPlayer.PlayerData.items) do
            if v.type == "weapon" or ItemBack then
                table.insert(weapons, v)
            end
        end
        return weapons
    end

    -- Event to update the player's weapons data on the server
    RegisterNetEvent("w-backitemdisplay:updatePlayer", function()
        local source = source
        local xPlayer = QBCore.Functions.GetPlayer(source)
        local weapons = GetWeaponsFromPlayer(xPlayer)
        datas[xPlayer.PlayerData.source] = weapons
        TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, weapons, xPlayer.PlayerData.source)
    end)

    -- Event handler for when a player loads into the server
    AddEventHandler("QBCore:Server:PlayerLoaded", function(xPlayer)
        local weapons = GetWeaponsFromPlayer(xPlayer)
        datas[xPlayer.PlayerData.source] = weapons
        TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, datas)
    end)

else

    -- Event to update the player's inventory on the client side
    RegisterNetEvent("inventory:client:UpdatePlayerInventory", function()
        TriggerServerEvent("w-backitemdisplay:updatePlayer")
    end)

    -- Event to update players' weapons data on the client side
    RegisterNetEvent("w-backitemdisplay:updatePlayers", function(data, playerId)
        if playerId then
            UpdatePlayersData(data, playerId) -- Update data for a specific player
        else
            UpdatePlayersData(data) -- Replace all data
        end
    end)

    -- Event handler for when a player unloads from the client
    RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
        IsActive = nil
    end)

    -- Event handler for when a player loads into the client
    RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
        IsActive = true
        MonitorActivePlayers() -- Function to monitor active players
    end)

    -- Function to get weapon data such as components and tint from the player's loadout
    function GetWeaponData(playerLoadout, weaponHash)
        local components = {}
        local tintIndex = nil

        for _, weapon in ipairs(playerLoadout) do
            if GetHashKey(weapon.name) == weaponHash then
                components = weapon.info.attachments or {}
                tintIndex = weapon.tintIndex

                -- Override tintIndex if additional info is provided
                if weapon.info.tint then
                    tintIndex = weapon.info.tint
                elseif weapon.info.tintIndex then
                    tintIndex = weapon.info.tintIndex
                end
                break
            end
        end

        return components, tintIndex
    end
end
