if IsDuplicityVersion() then
    local datas,deactivePlayers = {}, {}
    local isQb = GetResourceState('qb-core') == 'started'
    local isESX = GetResourceState('es_extended') == 'started'
    local isOxInventory = GetResourceState('ox_inventory') == 'started'
    local isCodemInventory = GetResourceState('codem-inventory') == 'started' -- not working yet
    if isQb then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif isESX then
        ESX = exports['es_extended']:getSharedObject() -- OG Fivem Framework <3
    end
    if UseGtaDefault then
        isQb, isESX, isOxInventory, isCodemInventory = false, false, false, false
    end

    -- Function to get weapons from a player's inventory
    function GetWeaponsFromPlayer(xPlayer)
        local weapons = {}
        if isOxInventory then
            local searchItems = {}
            for name, _ in pairs(Items) do
                table.insert(searchItems, name)
            end
            for name, _ in pairs(Weapons) do
                table.insert(searchItems, name)
            end
            weapons = exports.ox_inventory:Search(xPlayer, 'slots', searchItems, nil)
        elseif isCodemInventory then
            local identifier, source
            if isQb then
                identifier = xPlayer.PlayerData.citizenid
                source = xPlayer.PlayerData.source
            elseif isESX then
                identifier = xPlayer.identifier
                source = xPlayer.source
            end
            weapons = exports['codem-inventory']:GetInventory(identifier, source)
        elseif isQb then
            for _, v in pairs(xPlayer.PlayerData.items) do
                if v.type == "weapon" or ItemBack then
                    table.insert(weapons, v)
                end
            end
        elseif isESX then
            weapons = xPlayer.loadout
            if ItemBack then
                for _, v in pairs(xPlayer.inventory) do
                    table.insert(weapons, v)
                end
            end
        end

        return weapons
    end

    -- Event to update the player's weapons data on the server
    RegisterNetEvent("w-backitemdisplay:updatePlayer", function(data, remove)
        local source = source
        if remove ~= nil then
            if remove then
                deactivePlayers[source] = true
            elseif deactivePlayers[source] then
                deactivePlayers[source] = nil
            end
        end
        if deactivePlayers[source] then
            datas[source] = {}
            TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, {}, source)
            return
        end
        if isOxInventory then
            local xPlayer = source -- using source as player ID in ox_inventory
            local weapons = GetWeaponsFromPlayer(xPlayer)
            datas[xPlayer] = weapons
            TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, weapons, xPlayer)
        elseif isQb then
            local source = source
            local xPlayer = QBCore.Functions.GetPlayer(source)
            local weapons = GetWeaponsFromPlayer(xPlayer)
            datas[xPlayer.PlayerData.source] = weapons
            TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, weapons, xPlayer.PlayerData.source)
        elseif isESX then
            local source = source
            local xPlayer = ESX.GetPlayerFromId(source)
            local weapons = GetWeaponsFromPlayer(xPlayer)
            datas[xPlayer.source] = weapons
            TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, weapons, xPlayer.source)
        else
            local source = source
            datas[source] = data
            TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, data, source)
        end
    end)

    -- Event handler for when a player loads into the server
    AddEventHandler("QBCore:Server:PlayerLoaded", function(xPlayer)
        if isOxInventory then
            local xPlayer = xPlayer.PlayerData.source -- using source as player ID in ox_inventory
            local weapons = GetWeaponsFromPlayer(xPlayer)
            datas[xPlayer] = weapons
            TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, weapons, xPlayer)
        else
            local weapons = GetWeaponsFromPlayer(xPlayer)
            datas[xPlayer.PlayerData.source] = weapons
            TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, datas)
        end
    end)
    AddEventHandler("esx:playerLoaded", function(_, xPlayer)
        if isOxInventory then
            local xPlayer = xPlayer.source -- using source as player ID in ox_inventory
            local weapons = GetWeaponsFromPlayer(xPlayer)
            datas[xPlayer] = weapons
            TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, weapons, xPlayer)
        else
            local weapons = GetWeaponsFromPlayer(xPlayer)
            datas[xPlayer.source] = weapons
            TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, datas)
        end
    end)

    -- Thread for handle script restart
    Citizen.CreateThread(function()
        Wait(2000)
        for _, id in ipairs(GetPlayers()) do
            id = tonumber(id)
            if isQb then
                local xPlayer = QBCore.Functions.GetPlayer(id)
                local weapons = GetWeaponsFromPlayer(xPlayer)
                datas[xPlayer.PlayerData.source] = weapons
                TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, weapons, xPlayer.PlayerData.source)
            elseif isESX then
                local xPlayer = ESX.GetPlayerFromId(id)
                local weapons = GetWeaponsFromPlayer(xPlayer)
                datas[xPlayer.source] = weapons
                TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, weapons, xPlayer.source)
            end
        end
        TriggerClientEvent("w-backitemdisplay:updatePlayers", -1, datas)
        TriggerClientEvent("w-backitemdisplay:forceStart", -1)
    end)
else
    local isQb = GetResourceState('qb-core') == 'started'
    local isESX = GetResourceState('es_extended') == 'started'
    local isOxInventory = GetResourceState('ox_inventory') == 'started'
    local isCodemInventory = GetResourceState('codem-inventory') == 'started'
    if UseGtaDefault then
        isQb, isESX, isOxInventory, isCodemInventory = false, false, false, false
    end
    local OxItems, WeaponsData
    if isOxInventory then
        OxItems = exports.ox_inventory:Items()
    elseif isESX then
        ESX = exports['es_extended']:getSharedObject() -- OG Fivem Framework <3
    else
        WeaponsData = json.decode(LoadResourceFile(GetCurrentResourceName(), 'data.json'))
        Citizen.CreateThread(function ()
            IsActive = true
            Citizen.CreateThread(MonitorActivePlayers)
            while true do
                local ped = PlayerPedId()
                local weapons = {}
                for _, v in pairs(WeaponsData) do
                    local model = GetHashKey(v.HashKey)
                    if HasPedGotWeapon(ped, GetHashKey(v.HashKey)) then
                        local componnets = {}
                        local camos = {}
                        for _, v2 in pairs(v.Components) do
                            local c_model = GetHashKey(v2.HashKey)
                            if HasPedGotWeaponComponent(ped, model, c_model) then
                                table.insert(componnets, {component = c_model})
                                if string.find(string.lower(v2.HashKey), "camo") then
                                    camos[v2.HashKey] = GetPedWeaponLiveryColor(ped, model, v2.HashKey)
                                end
                            end
                        end
                        table.insert(weapons,{
                            name = v.HashKey,
                            tint = GetPedWeaponTintIndex(ped, model),
                            componnets = componnets,
                            camos = camos,
                        })
                    end
                end
                TriggerServerEvent("w-backitemdisplay:updatePlayer", weapons)
                Wait(1000)
            end
        end)
    end
    
    -- Event to update the player's inventory on the client side
    RegisterNetEvent("inventory:client:UpdatePlayerInventory", function()
        TriggerServerEvent("w-backitemdisplay:updatePlayer")
    end)
    RegisterNetEvent("esx:addInventoryItem", function()
        TriggerServerEvent("weaponOnBack:updatePlayer")
    end)
    RegisterNetEvent("esx:removeInventoryItem", function()
        TriggerServerEvent("weaponOnBack:updatePlayer")
    end)
    RegisterNetEvent("esx:addWeapon", function() -- old esx
        TriggerServerEvent("weaponOnBack:updatePlayer") 
    end)
    RegisterNetEvent("esx:addWeaponComponent", function()
        TriggerServerEvent("weaponOnBack:updatePlayer")
    end)
    RegisterNetEvent("esx:setWeaponAmmo", function()  -- old esx
        TriggerServerEvent("weaponOnBack:updatePlayer")
    end)
    RegisterNetEvent("esx:setWeaponTint", function()
        TriggerServerEvent("weaponOnBack:updatePlayer")
    end)
    RegisterNetEvent("esx:removeWeapon", function()  -- old esx
        TriggerServerEvent("weaponOnBack:updatePlayer")
    end)
    RegisterNetEvent("esx:removeWeaponComponent", function()
        TriggerServerEvent("weaponOnBack:updatePlayer")
    end)
    AddEventHandler('ox_inventory:updateInventory', function()
        TriggerServerEvent("weaponOnBack:updatePlayer")
    end)
    AddEventHandler('ox_inventory:updateWeaponComponent', function()
        TriggerServerEvent("weaponOnBack:updatePlayer")
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

    -- Event handler for resource restart
    RegisterNetEvent("w-backitemdisplay:forceStart", function()
        IsActive = true
        MonitorActivePlayers() -- Function to monitor active players
    end)

    -- Event handler for when a player loads into the client
    RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
        IsActive = true
        MonitorActivePlayers() -- Function to monitor active players
    end)

    -- Function to get weapon data such as components and tint from the player's loadout
    function GetWeaponData(playerLoadout, weaponHash)
        local components, tempComponents, camos = {}, {}, {}
        local tintIndex = nil
        if isOxInventory then
            for _, weapon in ipairs(playerLoadout) do
                if GetHashKey(weapon.name) == weaponHash and weapon.metadata then
                    tempComponents = weapon.metadata.components or {}
                    tintIndex = weapon.metadata.tint
                    break
                end
            end	
            for _, v in ipairs(tempComponents) do
                local components = OxItems[v].client.component
                for _, v2 in ipairs(components) do
                    table.insert(components, {component = v2})
                end
			end
        elseif isCodemInventory then
            -- next update
        elseif isQb then
            for _, weapon in ipairs(playerLoadout) do
                if GetHashKey(weapon.name) == weaponHash then
                    components = weapon.info.attachments or {}
                    tintIndex = weapon.info.tint

                    -- Override tintIndex if additional info is provided(old qb core edits)
                    if weapon.tintIndex then
                        tintIndex = weapon.tintIndex
                    elseif weapon.info.tintIndex then
                        tintIndex = weapon.info.tintIndex
                    end
                    break
                end
            end
        elseif isESX then
            local name
            for _, weapon in ipairs(playerLoadout) do
                if GetHashKey(weapon.name) == weaponHash then
                    name = weapon.name
                    tempComponents = weapon.components or {}
                    tintIndex = weapon.tintIndex
                    break
                end
            end
            for _, v in ipairs(tempComponents) do
				local component = ESX.GetWeaponComponent(name, v)
                table.insert(components, {component = component.hash})
			end
        else
            for _, weapon in pairs(playerLoadout) do
                if GetHashKey(weapon.name) == weaponHash then
                    components = weapon.componnets or {}
                    tintIndex = weapon.tint
                    camos = weapon.camos
                    break
                end
            end
        end

        return components, tintIndex, camos
    end
end
