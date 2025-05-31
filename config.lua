Vx_crafting = Vx_crafting or {}

Vx_crafting.Config = {
    CommandPrefix = "vx_crafting",
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
    ["botanic"] = {
        coords = vector3(7399.91, 7347.83, 15.57),
        heading = 0.0,
        radius = 2.0,
        recipes = {},
        category = "botanic_1",
        blip = {
            sprite = 478,
            color = 4,
            scale = 0.8,
            name = "All Categories Station",
        },
        marker = {
            type = 27,
            coords = vector3(7399.91, 7347.83, 14.57),
            scale = vector3(2.0, 2.0, 1.0),
            color = { 255, 150, 0, 100 },
            drawDistance = 10.0,
        },
        object = {
            model = 'bkr_prop_weed_table_01b',
            freeze = true,
            placeOnGround = true,
            zOffset = -1.9,
        },
    },
}
