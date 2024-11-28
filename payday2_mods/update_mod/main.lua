-- main.lua

-- Función para ejecutar el script de Python
local function check_for_updates()
    local python_script = ModPath .. "updater/updater.py"
    local result = os.execute("python " .. python_script .. "check_for_updates")
    return result == 0  -- returns true if there are updates available
end

local function download_updates()
    local python_script = ModPath .. "updater/updater.py"
    os.execute("python " .. python_script .. "download_mod")
end

-- Crea el menú de actualización
local function create_update_menu(nodes)
    local menu_id = "mod_updater_menu"
    local menu_title = "Mod Updater"
    local menu_desc = "Check and download mod updates"
    
    MenuHelper:NewMenu(menu_id)
    
    MenuCallbackHandler.check_for_updates_callback = function(self, item)
        if check_for_updates() then
            MenuHelper:ShowDialog("Updates available!", "There are mod updates available. Would you like to download them?", {
                [1] = {
                    text = "Yes",
                    callback = function()
                        download_updates()
                        MenuHelper:ShowDialog("Updates downloaded", "Mod updates have been downloaded. Please restart the game to apply changes.")
                    end
                },
                [2] = {
                    text = "No",
                    is_cancel_button = true
                }
            })
        else
            MenuHelper:ShowDialog("No updates", "No mod updates are available at this time.")
        end
    end
    
    MenuHelper:AddButton({
        id = "check_updates_button",
        title = "Check for Updates",
        desc = "Check if there are any mod updates available",
        callback = "check_for_updates_callback",
        menu_id = menu_id,
        priority = 1
    })
    
    nodes[menu_id] = MenuHelper:BuildMenu(menu_id, {back_callback = "save_settings"})
    MenuHelper:AddMenuItem(nodes["blt_options"], menu_id, "Mod Updater", "Open the Mod Updater menu")
end

Hooks:Add("MenuManagerSetupCustomMenus", "ModUpdaterMenuSetup", function(menu_manager, nodes)
    create_update_menu(nodes)
end)