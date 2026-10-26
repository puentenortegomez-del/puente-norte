local androidApi = rawget(_G, "android")

local function report(message)
    message = tostring(message)
    if type(androidApi) == "table" and type(androidApi.sendChatMessage) == "function" then
        local ok, err = pcall(androidApi.sendChatMessage, message)
        if ok then return true end
        print("No se pudo enviar al chat: " .. tostring(err))
    else
        print("API android no disponible; aviso: " .. message)
    end
    return false
end

local function callApi(action, fn, ...)
    if type(fn) ~= "function" then
        report("No existe android." .. action .. "; ejecuta el programa en la terminal del Android.")
        return false
    end
    local ok, first, second = pcall(fn, ...)
    if not ok then
        report(action .. " fallo: " .. tostring(first))
        return false
    end
    if first == true then
        report(action .. " fallo: " .. tostring(second or "error sin detalle"))
        return false
    end
    return true, first, second
end

local function handIsOccupied()
    local ok, name, count = callApi("getHandInfo", androidApi and androidApi.getHandInfo, "right")
    if not ok then return nil end
    if type(count) == "number" then return count > 0 end
    return name ~= nil and name ~= false and name ~= "air" and name ~= "Air"
end

local function getStashItemName(index)
    local ok, first, second = callApi("getSlotInfo", androidApi and androidApi.getSlotInfo, index)
    if not ok then return nil, false end
    if first == "empty" or first == nil then return nil, true end
    if first == false then return second, true end
    return first, true
end

local function stashHeldItem()
    local occupied = handIsOccupied()
    if occupied == nil then return false end
    if not occupied then return true end

    for slot = 0, 8 do
        local name, valid = getStashItemName(slot)
        if not valid then return false end
        if name == nil or name == "" then
            return callApi("storeItem", androidApi and androidApi.storeItem, slot)
        end
    end
    report("No hay espacio libre en el inventario del Android para guardar lo que tiene en la mano.")
    return false
end

local function findStashSlot(fragment)
    for slot = 0, 8 do
        local name, valid = getStashItemName(slot)
        if not valid then return nil end
        if name and string.find(string.lower(tostring(name)), fragment, 1, true) then
            return slot
        end
    end
    return nil
end

local function autoRefuel()
    local ok, fuel = callApi("fuelLevel", androidApi and androidApi.fuelLevel)
    if not ok then return false end
    if type(fuel) ~= "number" then
        report("android.fuelLevel() no devolvio un numero.")
        return false
    end
    if fuel >= 10 then return true end

    if not stashHeldItem() then return false end
    local redstoneSlot = findStashSlot("redstone")
    if redstoneSlot ~= nil then
        if not callApi("equipSlot", androidApi and androidApi.equipSlot, redstoneSlot) then return false end
    else
        if not callApi("pickup", androidApi and androidApi.pickup, "minecraft:redstone") then
            report("Combustible bajo y no encontre redstone en el inventario ni en el suelo.")
            return false
        end
    end

    local handOk, _, redstoneCount = callApi("getHandInfo", androidApi and androidApi.getHandInfo, "right")
    if not handOk or type(redstoneCount) ~= "number" or redstoneCount < 1 then
        report("No pude leer la cantidad de redstone equipada para recargar.")
        return false
    end
    if not callApi("refuel", androidApi and androidApi.refuel, redstoneCount) then return false end
    return stashHeldItem()
end

local oreTypes = {
    "minecraft:coal_ore", "minecraft:deepslate_coal_ore",
    "minecraft:iron_ore", "minecraft:deepslate_iron_ore",
    "minecraft:copper_ore", "minecraft:deepslate_copper_ore",
    "minecraft:gold_ore", "minecraft:deepslate_gold_ore",
    "minecraft:redstone_ore", "minecraft:deepslate_redstone_ore",
    "minecraft:lapis_ore", "minecraft:deepslate_lapis_ore",
    "minecraft:diamond_ore", "minecraft:deepslate_diamond_ore",
    "minecraft:emerald_ore", "minecraft:deepslate_emerald_ore",
    "minecraft:ancient_debris"
}

local function equipTorch()
    if not stashHeldItem() then return false end
    local torchSlot = findStashSlot("torch")
    if torchSlot ~= nil then
        return callApi("equipSlot", androidApi and androidApi.equipSlot, torchSlot)
    end
    return callApi("pickup", androidApi and androidApi.pickup, "minecraft:torch")
end

local function mineOre(oreType)
    local ok, blocks = callApi("getBlocksOfType", androidApi and androidApi.getBlocksOfType, oreType)
    if not ok then return false end
    if type(blocks) ~= "table" then return true end

    for _, block in ipairs(blocks) do
        if not autoRefuel() then return false end
        if not callApi("breakBlock", androidApi and androidApi.breakBlock, block.x, block.y, block.z) then return false end
        if not equipTorch() then return false end
        if not callApi("useBlock", androidApi and androidApi.useBlock, block.x, block.y - 1, block.z) then return false end
    end
    return true
end

local function distanceSquared(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

local function findNearestChest()
    local ok, chests = callApi("getBlocksOfType", androidApi and androidApi.getBlocksOfType, "minecraft:chest")
    if not ok then return nil end
    if type(chests) ~= "table" or #chests == 0 then return nil end

    local selfOk, selfInfo = callApi("getSelf", androidApi and androidApi.getSelf)
    if not selfOk or type(selfInfo) ~= "table" then return nil end
    local origin = {x = selfInfo.posX, y = selfInfo.posY, z = selfInfo.posZ}
    local nearest, bestDistance
    for _, chest in ipairs(chests) do
        local distance = distanceSquared(origin, chest)
        if bestDistance == nil or distance < bestDistance then
            nearest, bestDistance = chest, distance
        end
    end
    return nearest
end

local function findEmptyChestSlot(chest)
    local ok, info = callApi("getContainerInfo", androidApi and androidApi.getContainerInfo, chest.x, chest.y, chest.z)
    if not ok or type(info) ~= "table" then return nil end
    if info.locked then
        report("El cofre mas cercano esta bloqueado.")
        return nil
    end
    local slots = info.slots
    if type(slots) ~= "table" then return nil end
    for index, item in ipairs(slots) do
        local name = type(item) == "table" and item[1] or nil
        local count = type(item) == "table" and item[2] or nil
        if count == 0 or name == nil or name == "Air" or name == "air" or name == "empty" then
            return index - 1
        end
    end
    return nil
end

local function isProtectedSupply(itemName)
    local name = string.lower(tostring(itemName or ""))
    local protected = {
        "pickaxe", "axe", "shovel", "hoe", "sword", "wrench",
        "torch", "redstone"
    }
    for _, fragment in ipairs(protected) do
        if string.find(name, fragment, 1, true) then return true end
    end
    return false
end

local function depositLoot()
    local chest = findNearestChest()
    if not chest then
        report("No encontré un cofre visible cerca para depositar el botín.")
        return false
    end

    for slot = 0, 8 do
        local itemName, valid = getStashItemName(slot)
        if not valid then return false end
        if itemName and not isProtectedSupply(itemName) then
            local emptySlot = findEmptyChestSlot(chest)
            if emptySlot ~= nil then
                -- Mover al cofre: asumiendo que storeItem o similar puede usarse para transferir
                -- Este paso puede variar según la API; se deja un ejemplo básico:
                if not callApi("transferToChest", androidApi and androidApi.transferToChest, chest.x, chest.y, chest.z, slot, emptySlot) then
                    report("Fallo al transferir item al cofre.")
                    return false
                end
            else
                report("No hay ranuras vacías en el cofre cercano.")
                return false
            end
        end
    end
    return true
end
