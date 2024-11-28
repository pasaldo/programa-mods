local json = require("json") -- Asegúrate de tener una biblioteca JSON para Lua
local http = require("socket.http") -- Asegúrate de tener LuaSocket instalado
local ltn12 = require("ltn12")

local updater = {}

-- Configura estos valores
local GITHUB_USER = "pasaldo"
local GITHUB_REPO = "programa-mods"
local GITHUB_BRANCH = "main" -- o "master", dependiendo de tu configuración
local MODS_JSON_PATH = "mods.json" -- La ruta al archivo JSON con la lista de mods

-- Función para hacer una petición GET a la API de GitHub
function updater:github_get(path)
    local response = {}
    local request, code = http.request {
        url = "https://api.github.com/repos/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. path,
        method = "GET",
        headers = {
            ["User-Agent"] = "Payday2-ModUpdater"
        },
        sink = ltn12.sink.table(response)
    }
    
    if code ~= 200 then
        return nil
    end
    
    return json.decode(table.concat(response))
end

-- Función para leer el archivo JSON local
function updater:read_local_json()
    local file = io.open(MODS_JSON_PATH, "r")
    if not file then
        return nil
    end
    local content = file:read("*all")
    file:close()
    return json.decode(content)
end

-- Función para obtener la lista de mods del repositorio
function updater:get_remote_mods()
    local mods_json = self:github_get("/contents/" .. MODS_JSON_PATH .. "?ref=" .. GITHUB_BRANCH)
    if not mods_json then return {} end
    
    local mods_content = Base64.decode(mods_json.content)
    return json.decode(mods_content)
end

-- Función para obtener la lista de mods locales
function updater:get_local_mods()
    return self:read_local_json() or {}
end

-- Función para comparar mods
function updater:compare_mods(local_mods, remote_mods)
    local mods_to_update = {}
    for _, remote_mod in ipairs(remote_mods) do
        local found = false
        for _, local_mod in ipairs(local_mods) do
            if remote_mod.name == local_mod.name then
                found = true
                break
            end
        end
        if not found then
            table.insert(mods_to_update, remote_mod)
        end
    end
    return mods_to_update
end

-- Función principal de actualización
function updater:check_and_update()
    local remote_mods = self:get_remote_mods()
    local local_mods = self:get_local_mods()
    
    local mods_to_update = self:compare_mods(local_mods, remote_mods)
    
    for _, mod in ipairs(mods_to_update) do
        self:download_mod(mod)
    end
    
    -- Actualizar el archivo JSON local con la nueva lista de mods
    local file = io.open(MODS_JSON_PATH, "w")
    if file then
        file:write(json.encode(remote_mods))
        file:close()
    end
end

-- Función para descargar un mod
function updater:download_mod(mod)
    print("Descargando " .. mod.name)
    
    -- Aquí deberías implementar la lógica para descargar el mod
    -- Esto dependerá de cómo estén organizados tus mods en el repositorio
    
    -- Ejemplo:
    -- local mod_files = self:github_get("/contents/mods/" .. mod.name .. "?ref=" .. GITHUB_BRANCH)
    -- if mod_files then
    --     for _, file in ipairs(mod_files) do
    --         -- Descargar cada archivo del mod
    --     end
    -- end
end

-- Ejecutar el updater cuando se inicia el juego
Hooks:Add("MenuManagerOnOpenMenu", "ModUpdaterCheck", function(menu_manager, menu, index)
    if menu == "menu_main" then
        updater:check_and_update()
    end
end)