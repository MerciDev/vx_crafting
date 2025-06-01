Vx_crafting = Vx_crafting or {}

Vx_crafting.Config = {
    CommandPrefix = "vx_crafting:",
    InteractionCooldown = 1000,
    InventorySystem = "ox_inventory",
    ProgressBar = {
        TimePerItem = 2000,
        CancelKey = 73,
    },
    NotificationSystem = "ox_lib",
    NotificationDuration = 5000,
    DebugMode = false,
    UseDrawText3D = false,
}

Vx_crafting.CraftingPoints = {
    ["botanic_1"] = {
        name = "Laboratorio de Drogas",
        coords = vector3(7399.91, 7347.83, 15.57),
        heading = 0.0,
        radius = 2.0,
        recipes = {},
        category = "botanic_1",
        blip = {
            sprite = 469,
            color = 4,
            scale = 0.8,
            name = "Isla Botánica",
        },
        marker = {
            type = 27,
            coords = vector3(7399.91, 7347.83, 14.57),
            scale = vector3(2.0, 2.0, 1.0),
            color = { 255, 150, 0, 100 },
            drawDistance = 5.0,
        },
        object = {
            model = 'bkr_prop_weed_table_01b',
            freeze = true,
            placeOnGround = true,
            zOffset = -1.9,
        },
    },
    ["drugs_1"] = {
        name = "Mezclador Botánico",
        coords = vector3(5068.8, -4593.0, 2.9),
        heading = 70.0,
        radius = 2.0,
        recipes = {},
        category = "drugs_1",
        marker = {
            type = 27,
            coords = vector3(5068.8, -4593.0, 1.9),
            scale = vector3(2.0, 2.0, 1.0),
            color = { 255, 150, 0, 100 },
            drawDistance = 5.0,
        },
        object = {
            model = 'v_ret_ml_tablea',
            freeze = true,
            placeOnGround = true,
            zOffset = 0.7,
        },
    },
}
