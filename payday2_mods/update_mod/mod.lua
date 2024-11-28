local json = require("json") -- Asegúrate de tener una biblioteca JSON para Lua
local http = require("socket.http") -- Asegúrate de tener LuaSocket instalado
local ltn12 = require("ltn12")

local updater = {}

-- Configura estos valores
local GITHUB_USER = "pasaldo"
local GITHUB_REPO = "tu-repositorio"
local GITHUB_BRANCH = "main" -- o "master", dependiendo de tu configuración
local MODS_FOLDER = "mods" -- La carpeta donde están los mods en tu repositorio

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

-- Función para obtener la lista de mods del repositorio
function updater:get_remote_mods()
    local contents = self:github_get("/contents/" .. MODS_FOLDER .. "?ref=" .. GITHUB_BRANCH)
    if not contents then return {} end
    
    local mods = {}
    for _, item in ipairs(contents) do
        if item.type == "dir" then
            local mod_info = self:github_get("/contents/" .. item.path .. "/mod.txt?ref=" .. GITHUB_BRANCH)
            if mod_info then
                local info = json.decode(Base64.decode(mod_info.content))
                table.insert(mods, {name = item.name, version = info.version})
            end
        end
    end
    return mods
end

-- Función para obtener la lista de mods locales
function updater:get_local_mods()
    local mods = {}
    local mod_folder = "mods/"  -- Ajusta esto a la ruta correcta de tus mods
    for folder in io.popen('dir "'..mod_folder..'" /b /ad'):lines() do
        local f = io.open(mod_folder..folder.."/mod.txt", "r")
        if f then
            local content = f:read("*all")
            f:close()
            local info = json.decode(content)
            table.insert(mods, {name = folder, version = info.version})
        end
    end
    return mods
end

-- Función para comparar versiones
function updater:compare_versions(v1, v2)
    local function parse_version(v)
        local major, minor, patch = v:match("(%d+)%.(%d+)%.(%d+)")
        return tonumber(major), tonumber(minor), tonumber(patch)
    end
    
    local m1, n1, p1 = parse_version(v1)
    local m2, n2, p2 = parse_version(v2)
    
    if m1 ~= m2 then return m1 < m2 end
    if n1 ~= n2 then return n1 < n2 end
    return p1 < p2
end

-- Función principal de actualización
function updater:check_and_update()
    local remote_mods = self:get_remote_mods()
    local local_mods = self:get_local_mods()
    
    for _, remote_mod in ipairs(remote_mods) do
        local needs_update = true
        for _, local_mod in ipairs(local_mods) do
            if remote_mod.name == local_mod.name then
                if not self:compare_versions(local_mod.version, remote_mod.version) then
                    needs_update = false
                end
                break
            end
        end
        
        if needs_update then
            self:download_mod(remote_mod)
        end
    end
end

-- Función para descargar un mod
function updater:download_mod(mod)
    print("Descargando " .. mod.name .. " versión " .. mod.version)
    
    local mod_files = self:github_get("/contents/" .. MODS_FOLDER .. "/" .. mod.name .. "?ref=" .. GITHUB_BRANCH)
    if not mod_files then return end
    
    for _, file in ipairs(mod_files) do
        local content = self:github_get("/contents/" .. file.path .. "?ref=" .. GITHUB_BRANCH)
        if content then
            local f = io.open("mods/" .. mod.name .. "/" .. file.name, "wb")
            if f then
                f:write(Base64.decode(content.content))
                f:close()
            end
        end
    end
end

-- Ejecutar el updater cuando se inicia el juego
Hooks:Add("MenuManagerOnOpenMenu", "ModUpdaterCheck", function(menu_manager, menu, index)
    if menu == "menu_main" then
        updater:check_and_update()
    end
end)