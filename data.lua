-- data.lua
data:extend{
    {
        type="selection-tool",
        name="upgrade-modules",
        icons={
            {
                icon="__base__/graphics/icons/blueprint.png",
                tint={r=74/255, g=203/255, b=89/255, a=1}
            },
            {
                icon="__base__/graphics/icons/speed-module-2.png",
                tint={r=54/255, g=116/255, b=162/255, a=0.3}
            }
        },
        stack_size=1,
        subgroup="tool",
        order="c[automated-construction]-d[upgrade-modules]",
        flags={"goes-to-quickbar"},
        selection_color={r = 0.2, g = 0.8, b = 0.2, a = 0.2},
        alt_selection_color={r = 0.2, g = 0.8, b = 0.2, a = 0.2},
        selection_mode={"buildable-type"},
        alt_selection_mode={"buildable-type"},
        selection_cursor_box_type="entity",
        alt_selection_cursor_box_type="entity"
    },
    {
        type="recipe",
        name="upgrade-modules",
        enabled=true,
        energy_required=0.1,
        ingredients={},
        result="upgrade-modules"
    },
    {
        type="custom-input",
        name="upgrade-modules-settings",
        key_sequence="Y"
    },
    {
        type="custom-input",
        name="upgrade-modules-icon",
        key_sequence="CONTROL + Y"
    }
}

data:extend{
    {
        type="font",
        name="upgrade-modules-small-font",
        from="default",
        size=14
    }
}

data.raw["gui-style"].default["upgrade-modules-small-button"] = {
    type = "button_style",
    parent = "button_style",
    font = "upgrade-modules-small-font"
}

data.raw["gui-style"].default["upgrade-modules-menu-button"] = {
    type = "button_style",
    parent = "button_style",
    font = "upgrade-modules-small-font"
}
