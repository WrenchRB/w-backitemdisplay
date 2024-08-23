-- Table to store data for each player, indexed by player ID
local PlayersData = {}

-- Table to store attached objects (weapons/items) for each player
local attachedObjects = {}

-- Flag indicating whether the player monitoring loop is active
IsActive = false

-- Function to update player data
-- If playerId is provided, updates data for that specific player
-- Otherwise, replaces all PlayersData with the provided data
function UpdatePlayersData(data, playerId)
    if playerId then
        PlayersData[playerId] = data
    else
        PlayersData = data
    end
end

-- Function to count how many times a player has a specific item
-- Returns the count of the item in the player's inventory
local function playerHasItem(playerId, itemHash)
    local itemCount = 0
    if PlayersData[playerId] then
        for _, item in pairs(PlayersData[playerId]) do
            if GetHashKey(item.name) == itemHash then
                itemCount = itemCount + 1
            end
        end
    end
    return itemCount
end

-- Function to request and load a weapon asset
local function requestWeaponAsset(weaponHash)
    if not HasWeaponAssetLoaded(weaponHash) then
        RequestWeaponAsset(weaponHash)
        while not HasWeaponAssetLoaded(weaponHash) do
            Wait(0) -- Wait until the asset is loaded
        end
    end
end

-- Function to request and load an object asset (for non-weapons)
local function requestObjectAsset(objectHash)
    if not HasModelLoaded(objectHash) then
        RequestModel(objectHash)
        while not HasModelLoaded(objectHash) do
            Wait(0) -- Wait until the model is loaded
        end
    end
end

-- Function to delete an object
local function deleteObject(object)
    SetEntityAsMissionEntity(object, false, true)
    DeleteObject(object)
end

-- Function to attach an object model (weapon or item) to a player's back
local function attachObjectToBack(objectModel, objectHash, playerLoadout, ped, playerId)
    -- Check if the object is a weapon or not
    local isWeapon = IsWeaponValid(objectHash)

    if isWeapon then
        -- If it's a weapon, use the weapon functions
        requestWeaponAsset(objectHash)
        attachedObjects[playerId][objectHash] = {
            hash = objectHash,
            obj = CreateWeaponObject(objectHash, 50, 1.0, 1.0, 1.0, true, 1.0, 0)
        }

        -- Retrieve weapon components and tint index from the player's loadout
        local components, tintIndex = GetWeaponData(playerLoadout, objectHash)

        -- Attach all components to the weapon object
        for _, component in pairs(components) do
            GiveWeaponComponentToWeaponObject(attachedObjects[playerId][objectHash].obj, GetHashKey(component.component))
        end

        -- Set the tint index if available
        if tintIndex then
            SetWeaponObjectTintIndex(attachedObjects[playerId][objectHash].obj, tintIndex)
        end

    else
        -- If it's not a weapon, use the object functions
        requestObjectAsset(objectHash)
        attachedObjects[playerId][objectHash] = {
            hash = objectHash,
            obj = CreateObject(objectHash, 1.0, 1.0, 1.0, false, true, false)
        }
    end

    -- Configure the object properties
    SetEntityAsMissionEntity(attachedObjects[playerId][objectHash].obj, true, false)
    SetEntityCollision(attachedObjects[playerId][objectHash].obj, false, false)

    -- Get the back attachment configuration for the object model
    local backItemConfig = Weapons[objectModel] or Items[objectModel]  -- Check if it's in Weapons or Items table
    
    -- Attach the object to the player's back
    AttachEntityToEntity(
        attachedObjects[playerId][objectHash].obj, -- Entity to attach
        ped, -- Entity to attach to
        GetPedBoneIndex(ped, backItemConfig.back_bone), -- Bone to attach to
        backItemConfig.position.x, -- X offset
        backItemConfig.position.y, -- Y offset
        backItemConfig.position.z, -- Z offset
        backItemConfig.rotation.x, -- X rotation
        backItemConfig.rotation.y, -- Y rotation
        backItemConfig.rotation.z, -- Z rotation
        false, -- p8 (boolean)
        true,  -- p9 (boolean)
        false, -- p10 (boolean)
        true,  -- p11 (boolean)
        false, -- p12 (boolean)
        true   -- p13 (boolean)
    )

    -- Clean up: remove the object or weapon asset to free up memory
    if isWeapon then
        RemoveWeaponAsset(objectHash)
    else
        SetModelAsNoLongerNeeded(objectHash)
    end
end

-- Function to monitor active players and manage object attachments
function MonitorActivePlayers()
    while IsActive do
        local activePlayerIds = {}

        -- Iterate through all active players
        for _, playerId in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(playerId)
            local serverId = GetPlayerServerId(playerId)
            activePlayerIds[serverId] = true

            -- Initialize the attachedObjects table for this server ID if not already
            if not attachedObjects[serverId] then
                attachedObjects[serverId] = {}
            end

            -- Get the player's loadout (list of weapons/items)
            local playerLoadout = PlayersData[serverId]
            if playerLoadout then
                -- Iterate through all defined objects (weapons and items)
                for objectName, _ in pairs(Weapons) do
                    local objectHash = GetHashKey(objectName)
                    -- Check if the player has this object
                    if playerHasItem(serverId, objectHash) > 0 then
                        -- If the object is not already attached or the attached object doesn't exist
                        -- Also ensure the player is not currently holding the object
                        if (not attachedObjects[serverId][objectHash] or not DoesEntityExist(attachedObjects[serverId][objectHash].obj)) 
                           and not (GetSelectedPedWeapon(ped) == objectHash and playerHasItem(serverId, objectHash) == 1) then
                            -- Attach the object to the player's back
                            attachObjectToBack(objectName, objectHash, playerLoadout, ped, serverId)
                        end
                    end
                end
            end

            -- Iterate through the attached objects for this player
            for objectHash, attachedObject in pairs(attachedObjects[serverId]) do
                -- If the player is currently holding this object and only has one instance, or if the player no longer has the object
                if (GetSelectedPedWeapon(ped) == attachedObject.hash and playerHasItem(serverId, attachedObject.hash) == 1) 
                   or playerHasItem(serverId, attachedObject.hash) == 0 then
                    -- Delete the attached object
                    deleteObject(attachedObject.obj)
                    -- Remove the object from the attachedObjects table
                    attachedObjects[serverId][attachedObject.hash] = nil
                else
                    -- Check if the attached object is still attached to the player
                    local attachedEntity = DoesEntityExist(attachedObject.obj) and GetEntityAttachedTo(attachedObject.obj) or 0
                    if attachedEntity == 0 or ped ~= attachedEntity then
                        -- If the object is not attached to the player, delete it
                        deleteObject(attachedObject.obj)
                        -- Remove the object from the attachedObjects table
                        attachedObjects[serverId][attachedObject.hash] = nil
                    end
                end
            end
        end

        -- Clean up attached objects for players who are no longer active
        for serverId, _ in pairs(attachedObjects) do
            if not activePlayerIds[serverId] then
                -- Iterate through all attached objects for the inactive player
                for _, attachedObject in pairs(attachedObjects[serverId]) do
                    if DoesEntityExist(attachedObject.obj) then
                        -- Delete the attached object
                        deleteObject(attachedObject.obj)
                    end
                end
                -- Remove the player's entry from the attachedObjects table
                attachedObjects[serverId] = nil
            end
        end

        -- Wait before the next iteration
        Wait(UpdateTime*1000)
    end
end
