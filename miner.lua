
-- ==========================================
-- MINERO AUTOMATICO CC:ANDROIDs
-- Minecraft 1.20.1 - CC:Androids 1.3.0
-- Direccion: X POSITIVO
-- ==========================================

local android = _G.android

if type(android) ~= "table" then
    print("ERROR: API android no disponible")
    return
end

-- CONFIGURACION
local CONFIG = {
    startX = 2215,
    startY = 32,
    startZ = -802,

    length = 40,
    width = 3,
    height = 3
}

local function report(message)
    print("[MINERO] " .. tostring(message))
end

-- Ejecuta breakBlock con coordenadas.
local function breakAt(x, y, z)
    if type(android.breakBlock) ~= "function" then
        report("ERROR: breakBlock no disponible")
        return false
    end

    if type(android.fuelLevel) == "function" then
        local okFuel, fuel = pcall(android.fuelLevel)

        if not okFuel or type(fuel) ~= "number" then
            report("No se pudo consultar el combustible")
            return false
        end

        if fuel <= 0 then
            report("Sin combustible. Operacion detenida")
            return false
        end
    end

    local ok, result = pcall(
        android.breakBlock,
        x,
        y,
        z
    )

    if not ok then
        report(
            "Error en "
            .. tostring(x) .. ","
            .. tostring(y) .. ","
            .. tostring(z) .. ": "
            .. tostring(result)
        )
        return false
    end

    -- La API indica que algunas funciones devuelven
    -- una tabla cuyo primer valor true significa error.
    if type(result) == "table" and result[1] == true then
        report(
            "Error API en "
            .. tostring(x) .. ","
            .. tostring(y) .. ","
            .. tostring(z)
        )
        return false
    end

    return true
end

local function main()
    report("Inicio de la excavacion")
    report("Direccion: X positivo")
    report(
        "Origen: "
        .. CONFIG.startX .. ","
        .. CONFIG.startY .. ","
        .. CONFIG.startZ
    )

    local halfWidth = math.floor(CONFIG.width / 2)

    for dx = 0, CONFIG.length - 1 do
        local x = CONFIG.startX + dx

        -- Ancho del tunel en el eje Z.
        for dz = -halfWidth, halfWidth do

            -- Altura del tunel en el eje Y.
            for dy = 0, CONFIG.height - 1 do
                local y = CONFIG.startY + dy
                local z = CONFIG.startZ + dz

                local success = breakAt(x, y, z)

                if not success then
                    report("Excavacion detenida")
                    return
                end
            end
        end

        if dx % 5 == 0 then
            report(
                "Progreso: X=" .. tostring(x)
                .. " (" .. tostring(dx + 1)
                .. "/" .. tostring(CONFIG.length) .. ")"
            )
        end
    end

    report("Tunel completado")
    report("Final: X=2254, Y=32, Z=-802")
end

main()
