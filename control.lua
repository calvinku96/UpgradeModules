-- control.lua
-- Based on https://mods.factorio.com/mods/Klonan/upgrade-planner
require("mod-gui")

local function global_init()
    local names = {"config", "config-tmp", "storage"}
    for k, val in pairs(names) do
        global[val] = global[val] or {}
    end
end

-- Remove invalid items
local function get_config_item(player, index, fromto)
    local item_set = global["config-tmp"][player.name][index]
    if (not global["config-tmp"][player.name])
            or item_set == nil
            or item_set[fromto] == "" then
        return nil
    elseif (not game.item_prototypes[item_set[fromto]]) 
            or (not game.item_prototypes[item_set[fromto]].valid) then
        gui_remove(player, index)
        return nil
    else
        return game.item_prototypes[item_set[fromto]].name
    end
end

local function deepcopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for k, v in next, orig, nil do
            copy[deepcopy(k)] = deepcopy(v)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function count_keys(hashmap)
    local result = 0
    for k, v in pairs(hashmap) do
        result = result + 1
    end
    return result
end

-- GUI
local function gui_init(player)
    local gui_names = {
        {"top", "upgrade-modules-config-button"},
        {"left", "upgrade-modules-config-frame"},
        {"left", "upgrade-modules-storage-frame"}
    }
    for k, v in pairs(gui_names) do
        if player.gui[v[1]][v[2]] then
            player.gui[v[1]][v[2]].destroy()
        end
    end

    local flow = mod_gui.get_button_flow(player)
    if not flow["upgrade-modules-config-button"] then
        local button = flow.add{
            type="sprite-button",
            name="upgrade-modules-config-button",
            style=mod_gui.button_style,
            sprite="item/upgrade-modules",
            tooltip={"upgrade-modules-button-tooltip"}
        }
        button.style.visible = true
    end
end

local function gui_toggle_frame(player)
    local flow = mod_gui.get_frame_flow(player)
    local frame = flow["upgrade-modules-config-frame"]
    local storage_frame = flow["upgrade-modules-storage-frame"]
    if frame then
        -- Close frame if open
        frame.destroy()
        if storage_frame then storage_frame.destroy() end
        global["config-tmp"][player.name] = nil
        return
    else
        -- Copy config to config-tmp
        -- config is the saved configuration
        -- config-tmp is the configuration shown in gui
        -- config-tmp is copied to config when saved
        -- config-tmp is deleted when gui is closed
        global["config"][player.name] = global["config"][player.name] or {}
        global["config-tmp"][player.name] = deepcopy(global["config"][player.name])

        -- Build Gui: Config Frame
        frame = flow.add{
            type="frame",
            caption={"upgrade-modules-config-frame-title"},
            name="upgrade-modules-config-frame",
            direction="vertical"
        }
        local error_label = frame.add{
            type="label",
            name="upgrade-modules-config-error-label"
        }
        error_label.style.minimal_width = 200
        local ruleset_grid = frame.add{
            type="table",
            colspan=6,
            name="upgrade-modules-ruleset-grid",
            style="slot_table_style"
        }
        ruleset_grid.add{
            type="label",
            name="upgrade-modules-config-header-from-left",
            caption={"upgrade-modules-config-header-from"}
        }
        ruleset_grid.add{
            type="label",
            name="upgrade-modules-config-header-to-left",
            caption={"upgrade-modules-config-header-to"}
        }
        ruleset_grid.add{
            type="label",
            name="upgrade-modules-config-header-clear-left",
            caption={"upgrade-modules-config-clear", ""}
        }
        ruleset_grid.add{
            type="label",
            name="upgrade-modules-config-header-from-right",
            caption={"upgrade-modules-config-header-from"}
        }
        ruleset_grid.add{
            type="label",
            name="upgrade-modules-config-header-to-right",
            caption={"upgrade-modules-config-header-to"}
        }
        ruleset_grid.add{
            type="label",
            name="upgrade-modules-config-header-clear-right",
            caption={"upgrade-modules-config-clear", ""}
        }

        for i=1,settings.global["upgrade-modules-max-config-size"].value do
            for k, v in pairs{"from", "to"} do
                local config_item = get_config_item(player, i, v)
                if config_item then
                    local tooltip = game.item_prototypes[config_item].localised_name
                else
                    local tooltip = nil
                end
                local element = ruleset_grid.add{
                    type="choose-elem-button",
                    name="upgrade-modules-"..v.."-"..i,
                    style="slot_button_style",
                    elem_type="item",
                    tooltip=tooltip
                }
                element.elem_value = config_item
            end
            ruleset_grid.add{
                type="sprite-button",
                name="upgrade-modules-clear-"..i,
                style="red_slot_button_style",
                sprite="utility/remove",
                tooltip={"upgrade-modules-config-clear", ""}
            }
        end

        local button_grid = frame.add{
            type="table",
            colspan=2,
            name="upgrade-modules-button-grid"
        }
        button_grid.add{
            type="button",
            name="upgrade-modules-apply",
            caption={"upgrade-modules-config-button-apply"},
            style=mod_gui.button_style
        }
        button_grid.add{
            type="button",
            name="upgrade-modules-clear-all",
            caption={"upgrade-modules-config-button-clear-all"},
            style=mod_gui.button_style
        }

        -- Build Gui: Storage Frame
        local storage_frame = flow.add{
            type="frame",
            name="upgrade-modules-storage-frame",
            caption={"upgrade-modules-storage-frame-title"},
            direction="vertical"
        }
        local storage_frame_error_label = storage_frame.add{
            type="label",
            name="upgrade-modules-storage-error-label"
        }
        storage_frame_error_label.style.minimal_width = 200

        local storage_frame_buttons = storage_frame.add{
            type="table",
            colspan=3,
            name="upgrade-modules-storage-buttons"
        }
        storage_frame_buttons.add{
            type="label",
            caption={"upgrade-modules-storage-name-label"},
            name="upgrade-modules-storage-name-label"
        }
        storage_frame_buttons.add{
            type="textfield",
            text="",
            name="upgrade-modules-storage-name"
        }
        storage_frame_buttons.add{
            type="button",
            caption={"upgrade-modules-storage-store"},
            name="upgrade-modules-storage-store",
            style="upgrade-modules-small-button"
        }

        local storage_grid = storage_frame.add{
            type="table",
            colspan=3,
            name="upgrade-modules-storage-grid"
        }
        if global["storage"][player.name] then
            local i = 1
            for key, val in pairs(global["storage"][player.name]) do
                storage_grid.add{
                    type="label",
                    caption=key.."        ",
                    name="upgrade-modules-storage-entry-"..i
                }
                storage_grid.add{
                    type="button",
                    caption={"upgrade-modules-storage-restore"},
                    name="upgrade-modules-restore-"..i,
                    style="upgrade-modules-small-button"
                }
                storage_grid.add{
                    type="button",
                    caption={"upgrade-modules-storage-remove"},
                    name="upgrade-modules-remove-"..i,
                    style="upgrade-modules-small-button"
                }
                i = i + 1
            end
        end
    end
end

local function gui_config_save(player)
    local config_tmp = global["config-tmp"][player.name]
    if config_tmp then
        for k, v in pairs(config_tmp) do
            if v.from == nil or v.to == nil then
                config_tmp[k] = nil
            end
        end
        global["config"][player.name] = deepcopy(config_tmp)
    end
end

local function gui_config_clear(player)
    local frame = mod_gui.get_frame_flow(player)["upgrade-modules-config-frame"]
    if not frame then return end

    local ruleset_grid = frame["upgrade-modules-ruleset-grid"]
    for i=1,settings.global["upgrade-modules-max-config-size"].value do
        global["config-tmp"][player.name][i] = nil
        ruleset_grid["upgrade-modules-from-"..i].elem_value = nil
        ruleset_grid["upgrade-modules-to-"..i].elem_value = nil
    end
end

local function gui_display_message(frame, message)
    local label_name
    if frame.name == "upgrade-modules-config-frame" then
        label_name = "upgrade-modules-config-error-label"
    elseif frame.name == "upgrade-modules-storage-frame" then
        label_name = "upgrade-modules-storage-error-label"
    else
        return
    end
    local error_label = frame[label_name]
    if not error_label then return end
    error_label.caption = message
end

local function gui_config_set_rule(player, fromto, index, element)
    local name = element.elem_value
    local frame = mod_gui.get_frame_flow(player)["upgrade-modules-config-frame"]
    local ruleset_grid = frame["upgrade-modules-ruleset-grid"]
    local ruleset_key = "upgrade-modules-"..fromto.."-"..index
    if not frame or not global["config-tmp"][player.name] then return end

    if not name then
        ruleset_grid[ruleset_key].tooltip = ""
        global["config-tmp"][player.name][index][fromto] = nil
    elseif game.item_prototypes[name].type ~= "module" then
        -- Must be modules
        gui_display_message(frame, {"upgrade-modules-item-not-module"})
        element.elem_value = nil
    else
        if not global["config-tmp"][player.name][index] then
            global["config-tmp"][player.name][index] = {}
        end
        global["config-tmp"][player.name][index][fromto] = name
        ruleset_grid[ruleset_key].tooltip = game.item_prototypes[name].localised_name
    end
end

local function gui_config_clear_rule(player, index)
    local frame = mod_gui.get_frame_flow(player)["upgrade-modules-config-frame"]
    if not frame or not global["config-tmp"][player.name] then return end
    gui_display_message(frame, "")
    local ruleset_grid = frame["upgrade-modules-ruleset-grid"]
    global["config-tmp"][player.name][index] = nil
    ruleset_grid["upgrade-modules-from-"..index].elem_value = nil
    ruleset_grid["upgrade-modules-from-"..index].tooltip = ""
    ruleset_grid["upgrade-modules-to-"..index].elem_value = nil
    ruleset_grid["upgrade-modules-to-"..index].tooltip = ""
end

local function gui_storage_store(player)
    global["storage"][player.name] = global["storage"][player.name] or {}

    local frame = mod_gui.get_frame_flow(player)["upgrade-modules-storage-frame"]
    if not frame then return end

    local textfield = frame["upgrade-modules-storage-buttons"]["upgrade-modules-storage-name"]
    local name = string.match(textfield.text, "^%s*(.-)%s*$")
    local grid = frame["upgrade-modules-storage-grid"]
    local index = count_keys(global["storage"][player.name])

    if not name or name == "" then
        gui_display_message(frame, {"upgrade-modules-storage-name-not-set"})
    elseif global["storage"][player.name][name] then
        gui_display_message(frame, {"upgrade-modules-storage-name-in-use"})
    elseif index > settings.global["upgrade-modules-max-storage-size"].value then
        gui_display_message(frame, {"upgrade-modules-storage-too-many"})
    else
        global["storage"][player.name][name] = deepcopy(global["config"][player.name])
        grid.add{
            type="label",
            caption=name.."        ",
            name="upgrade-planner-storage-entry-"..index
        }
        grid.add{
            type="button",
            caption={"upgrade-modules-storage-restore"},
            name="upgrade-modules-restore-"..index,
            style="upgrade-modules-small-button"
        }
        grid.add{
            type="button",
            caption={"upgrade-modules-storage-remove"},
            name="upgrade-modules-remove-"..index,
            style="upgrade-modules-small-button"
        }
        gui_display_message(frame, "")
        textfield.text = ""
    end
end

local function gui_storage_restore(player, index)
    local flow = mod_gui.get_frame_flow(player)
    local config_frame = flow["upgrade-modules-config-frame"]
    local storage_frame = flow["upgrade-modules-storage-frame"]
    if not config_frame or not storage_frame then return end

    local storage_grid = storage_frame["upgrade-modules-storage-grid"]
    local storage_entry = storage_grid["upgrade-modules-storage-entry-"..index]
    if not storage_entry then return end

    local name = string.match(storage_entry.caption, "^%s*(.-)%s*$")
    if not global["storage"][player.name] or not global["storage"][player.name][name] then return end

    local ruleset_grid = config_frame["upgrade-modules-ruleset-grid"]
    global["config-tmp"][player.name] = deepcopy(global["storage"][player.name][name])
    for i=1,settings.global["upgrade-modules-max-config-size"].value do
        ruleset_grid["upgrade-modules-from-"..i].elem_value = get_config_item(player, i, "from")
        ruleset_grid["upgrade-modules-to-"..i].elem_value = get_config_item(player, i, "to")
    end
    gui_display_message(storage_frame, "")
end

local function gui_storage_remove(player, index)
    if not global["storage"][player.name] then return end

    local frame = mod_gui.get_frame_flow(player)["upgrade-modules-storage-frame"]
    if not frame then return end

    local grid = frame["upgrade-modules-storage-grid"]
    local label = grid["upgrade-modules-storage-entry-"..index]
    local btn_restore = grid["upgrade-modules-restore-"..index]
    local btn_remove = grid["upgrade-modules-remove-"..index]

    if not label or not btn_restore or not btn_remove then return end
    local name = string.match(label.caption, "^%s*(.-)%s*$")
    label.destroy()
    btn_restore.destroy()
    btn_remove.destroy()

    global["storage"][player.name][name] = nil
    gui_display_message(frame, "")
end

-- Gui Interactions
script.on_event(
    defines.events.on_gui_click,
    function(event)
        local elem = event.element.name
        local player = game.players[event.player_index]

        if elem == "upgrade-modules-config-button" then
            gui_toggle_frame(player)
        elseif elem == "upgrade-modules-apply" then
            gui_config_save(player)
        elseif elem == "upgrade-modules-clear-all" then
            gui_config_clear(player)
        elseif elem == "upgrade-modules-storage-store" then
            gui_storage_store(player)
        else
            local action, index = string.match(elem, "upgrade%-modules%-(%a+)%-(%d+)")
            if action and index then
                if action == "restore" then
                    gui_storage_restore(player, tonumber(index))
                elseif action == "remove" then
                    gui_storage_remove(player, tonumber(index))
                elseif action == "clear" then
                    gui_config_clear_rule(player, tonumber(index))
                end
            end
        end
    end
)

script.on_event(
    defines.events.on_gui_elem_changed,
    function(event)
        local element = event.element
        local player = game.players[event.player_index]
        local fromto, index = string.match(element.name, "upgrade%-modules%-(%a+)%-(%d+)")
        if fromto and index then
            if fromto == "from" or fromto == "to" then
                gui_config_set_rule(player, fromto, tonumber(index), element)
            end
        end
    end
)

script.on_init(
    function()
        global_init()
        for k, player in pairs(game.players) do
            gui_init(player)
        end
    end
)

-- Main upgrade module function
script.on_event(
    defines.events.on_player_selected_area,
    function(event)
        local player = game.players[event.player_index]
        local config = global["config"][player.name]
        local swapped
        if event.item ~= "upgrade-modules" then return end
        for k1, entity in pairs(event.entities) do
            swapped = false
            local module_inventory = entity.get_module_inventory()
            if entity.get_module_inventory() ~= nil then
                for k2, v in pairs(config) do
                    if settings.global["upgrade-modules-break-after-one-occurence"].value then
                        if swapped then break end
                    end
                    if v.from ~= v.to then
                        for module, count in pairs(module_inventory.get_contents()) do
                            if module == v.from then
                                if player.can_reach_entity(entity) then
                                    local removed_count = math.min(count, player.get_item_count(v.to))
                                    if removed_count > 0 then
                                        swapped = true
                                        module_inventory.remove{name=v.from, count=removed_count}
                                        player.remove_item{name=v.to, count=removed_count}
                                        module_inventory.insert{name=v.to, count=removed_count}
                                        player.insert{name=v.from, count=removed_count}
                                    end
                                    if removed_count < count then
                                        player.surface.create_entity{name="flying-text", position={entity.position.x-1.3, entity.position.y-0.5}, text={"upgrade-modules-insufficient-items"}, color={r=1, g=0.6, b=0.6}}
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
)

script.on_configuration_changed(
    function(data)
        if not data or not data.mod_changes then
            return 
        end
        if data.mod_changes["upgrade-modules"] then
            for k, player in pairs(game.players) do
                gui_init(player)
            end
        end
    end
)

script.on_event(
    defines.events.on_player_joined_game,
    function(event)
        gui_init(game.players[event.player_index])
    end
)

script.on_event(
    "upgrade-modules-settings",
    function(event)
        gui_toggle_frame(game.players[event.player_index])
    end
)

script.on_event(
    "upgrade-modules-icon",
    function(event)
        local player = game.players[event.player_index]
        local frame_flow = mod_gui.get_frame_flow(player)
        local button_flow = mod_gui.get_button_flow(player)
        if button_flow["upgrade-modules-config-button"] then
            button_flow["upgrade-modules-config-button"].style.visible = not button_flow["upgrade-modules-config-button"].style.visible
        end
    end
)
