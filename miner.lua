-- Lua script for CC-Androids: Mine ores, place torches, deposit loot in nearest chest, and report failures

-- Helper function to check API call results
local function checkResult(result, action)
    if result[1] then
        -- result[1] is true when the call failed, result[2] contains error message
        sendChatMessage(action .. " failed: " .. tostring(result[2]))
        return false
    end
    return true
end

-- Auto‑refuel with redstone when fuel is low
local fuelChecksSinceRefuel = 0
local fuelApiWarningSent = false

local function stashHeldItem()
    local ok, hand = pcall(getHandInfo, "right")
    if not ok then
        sendChatMessage("No se pudo revisar la mano: " .. tostring(hand))
        return false
    end

    local itemName = type(hand) == "table" and hand[1] or hand
    if itemName == nil or itemName == false or itemName == "air" or itemName == "minecraft:air" then
        return true
    end

    for slot = 0, 8 do
        local slotOk, slotInfo = pcall(getSlotInfo, slot)
        if not slotOk then
            sendChatMessage("No se pudo revisar el slot " .. slot .. ": " .. tostring(slotInfo))
            return false
        end
        if slotInfo == false or slotInfo == nil or slotInfo == "air" or slotInfo == "minecraft:air" then
            local storeOk, result = pcall(storeItem, slot)
            if not storeOk then
                sendChatMessage("No se pudo guardar el objeto de la mano: " .. tostring(result))
                return false
            end
            return checkResult(result, "storeItem")
        end
    end

    sendChatMessage("No hay slots libres para guardar el objeto de la mano.")
    return false
end

local function autoRefuel()
    local shouldRefuel

    if type(fuelLevel) == "function" then
        local ok, fuel = pcall(fuelLevel)
        if not ok or type(fuel) ~= "number" then
            sendChatMessage("No se pudo consultar el combustible: " .. tostring(fuel))
            return false
        end
        shouldRefuel = fuel < 10
    else
        -- Some CC-Androids versions omit fuelLevel(). In that case, refuel
        -- conservatively at startup and then every four mining operations.
        fuelChecksSinceRefuel = fuelChecksSinceRefuel + 1
        shouldRefuel = fuelChecksSinceRefuel == 1 or fuelChecksSinceRefuel >= 4
        if not fuelApiWarningSent then
            sendChatMessage("Aviso: fuelLevel() no esta disponible; usare recarga periodica con redstone.")
            fuelApiWarningSent = true
        end
    end

    if shouldRefuel then
        if not stashHeldItem() then return false end
        local ok, result = pcall(pickup, "minecraft:redstone")
        if not ok then
            sendChatMessage("No se pudo recoger redstone: " .. tostring(result))
            return false
        end
        if not checkResult(result, "pickup redstone") then return false end

        ok, result = pcall(refuel)
        if not ok then
            sendChatMessage("Fallo al recargar combustible: " .. tostring(result))
            return false
        end
        if not checkResult(result, "refuel") then return false end

        fuelChecksSinceRefuel = 0
    end
    return true
end

-- List of ore types to mine
local oreTypes = {
    "minecraft:iron_ore",
    "minecraft:gold_ore",
    "minecraft:diamond_ore",
    "minecraft:emerald_ore",
    "minecraft:lapis_ore",
    "minecraft:coal_ore",
    "minecraft:netherite_ore",
    "minecraft:deepslate_iron_ore",
    "minecraft:deepslate_gold_ore",
    "minecraft:deepslate_diamond_ore",
    "minecraft:deepslate_emerald_ore",
    "minecraft:deepslate_lapis_ore",
    "minecraft:deepslate_coal_ore"
}

-- Function to mine all ores of a given type
local function mineOre(type)
    local blocks = getBlocksOfType(type)
    if not blocks or #blocks == 0 then
        return true -- nothing to mine
    end
    for _, b in ipairs(blocks) do
        if not autoRefuel() then return false end
        if not checkResult(breakBlock(b.x, b.y, b.z), "breakBlock") then return false end
        local torchPos = {x = b.x, y = b.y - 1, z = b.z}
        -- Preserve the current hand item instead of dropping it.
        if not stashHeldItem() then return false end
        if not checkResult(pickup("minecraft:torch"), "pickup torch") then return false end
        if not checkResult(useBlock(torchPos.x, torchPos.y, torchPos.z), "useBlock torch") then return false end
    end
    return true
end

-- Function to deposit all loot into the nearest chest
local function depositLoot()
    local chests = getBlocksOfType("minecraft:chest")
    if not chests or #chests == 0 then
        sendChatMessage("No chest found to deposit loot.")
        return false
    end
    local chest = chests[1]
    for slot = 0, 8 do
        local info = getSlotInfo(slot)
        if info and info ~= false then
            local hand = getHandInfo("right")
            if hand and hand[1] ~= "air" then
                if not checkResult(dropItem(), "dropItem") then return false end
            end
            if not checkResult(equipSlot(slot), "equipSlot") then return false end
            if not checkResult(storeHeldItemInContainer(chest.x, chest.y, chest.z, slot), "storeHeldItemInContainer") then return false end
        end
    end
    return true
end

-- Main execution
if not autoRefuel() then return end
if not mineOre("minecraft:iron_ore") then return end
if not mineOre("minecraft:gold_ore") then return end
if not mineOre("minecraft:diamond_ore") then return end
if not mineOre("minecraft:emerald_ore") then return end
if not mineOre("minecraft:lapis_ore") then return end
if not mineOre("minecraft:coal_ore") then return end
if not mineOre("minecraft:netherite_ore") then return end
if not mineOre("minecraft:deepslate_iron_ore") then return end
if not mineOre("minecraft:deepslate_gold_ore") then return end
if not mineOre("minecraft:deepslate_diamond_ore") then return end
if not mineOre("minecraft:deepslate_emerald_ore") then return end
if not mineOre("minecraft:deepslate_lapis_ore") then return end
if not mineOre("minecraft:deepslate_coal_ore") then return end

-- After mining, deposit loot
if not depositLoot() then return end

sendChatMessage("Mining and loot deposit completed.")
