data:extend{
    {
        type="int-setting",
        name="upgrade-modules-max-config-size",
        setting_type="runtime-global",
        default_value=16,
        maximum_value=50,
        minimum_value=2,
    },
    {
        type="int-setting",
        name="upgrade-modules-max-storage-size",
        setting_type="runtime-global",
        default_value=12,
        maximum_value=50,
        minimum_value=1,
    },
    {
        type="bool-setting",
        name="upgrade-modules-break-after-one-occurence",
        setting_type="runtime-global",
        default_value=false
    }
}
