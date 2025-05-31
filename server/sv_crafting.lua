local QBCore = exports['qb-core']:GetCoreObject()
local CraftingRecipes = {}
local PlayerCraftingStatus = {}

local function DebugPrint(...)
    if Vx_crafting.Config.DebugMode then
        print(...)
    end
end

local function hasValue(tbl, val)
    for _, value in ipairs(tbl) do
        if value == val then
            return true
        end
    end
    return false
end

local function TriggerNotification(source, message, type)
    if Vx_crafting.Config.NotificationSystem == "ox_lib" then
        TriggerClientEvent('ox_lib:notify', source, {
            description = message,
            type = type,
            duration = Vx_crafting.Config.NotificationDuration,
        })
    else
        TriggerClientEvent('QBCore:Notify', source, message, type)
    end
end

local function LoadCraftingRecipes()
    local recipesJson = LoadResourceFile(GetCurrentResourceName(), "shared/crafting_recipes.json")
    if recipesJson then
        CraftingRecipes = json.decode(recipesJson)
        if not CraftingRecipes then
            DebugPrint("^1[vx_crafting]^7 Error al decodificar crafting_recipes.json en el servidor.")
            CraftingRecipes = {}
        end
    else
        DebugPrint("^1[vx_crafting]^7 crafting_recipes.json no encontrado o está vacío en el servidor.")
        CraftingRecipes = {}
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LoadCraftingRecipes()
        DebugPrint("^2[vx_crafting]^7 Recetas de crafteo cargadas en el servidor.")
        DebugPrint(string.format(
            "^5[vx_crafting - SERVER DEBUG]^7 Contenido de Vx_crafting.CraftingPoints en el servidor: %s",
            json.encode(Vx_crafting.CraftingPoints)))
    end
end)

local function GetPlayerKnownRecipes(citizenid)
    local knownRecipes = {}
    DebugPrint(string.format("^5[vx_crafting - SERVER DEBUG]^7 Intentando obtener recetas para citizenid: %s", citizenid))
    local result = MySQL.Sync.fetchAll('SELECT recipe_id FROM player_crafting_recipes WHERE citizenid = ?', { citizenid })

    if result then
        DebugPrint(string.format("^5[vx_crafting - SERVER DEBUG]^7 Resultado de DB crudo para %s: %s", citizenid,
            json.encode(result)))
        for _, v in ipairs(result) do
            if v.recipe_id then
                table.insert(knownRecipes, v.recipe_id)
            else
                DebugPrint(string.format(
                    "^1[vx_crafting - SERVER DEBUG]^7 Advertencia: recipe_id nulo encontrado en el resultado de DB para citizenid %s: %s",
                    citizenid, json.encode(v)))
            end
        end
    else
        DebugPrint(string.format("^1[vx_crafting - SERVER DEBUG]^7 No se obtuvieron resultados de DB para citizenid: %s",
            citizenid))
    end
    DebugPrint(string.format("^2[vx_crafting - SERVER]^7 Recetas conocidas para %s (de DB): %s", citizenid,
        json.encode(knownRecipes)))
    return knownRecipes
end

QBCore.Functions.CreateCallback('vx_crafting:server:getKnownRecipes', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player and Player.PlayerData and Player.PlayerData.citizenid then
        local knownRecipes = GetPlayerKnownRecipes(Player.PlayerData.citizenid)
        cb(knownRecipes)
    else
        DebugPrint(string.format(
            "^1[vx_crafting - SERVER DEBUG]^7 Callback 'getKnownRecipes' llamado sin PlayerData o citizenid válido para source: %s",
            source))
        cb({})
    end
end)

RegisterNetEvent('vx_crafting:server:craftItem', function(recipeId, craftingPointId, quantity)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    DebugPrint(string.format(
        "^5[vx_crafting - SERVER DEBUG]^7 Solicitud de crafteo recibida: recipeId=%s, craftingPointId=%s, quantity=%s, source=%s",
        recipeId, craftingPointId, quantity, src))

    if not Player then
        DebugPrint(string.format("^1[vx_crafting]^7 Error: Jugador no encontrado para craftear (ID: %s).", src))
        return
    end

    local recipe = CraftingRecipes[recipeId]
    if not recipe then
        TriggerNotification(src, 'Receta no encontrada.', 'error')
        return
    end

    local craftingPoint = Vx_crafting.CraftingPoints[craftingPointId]
    if not craftingPoint then
        DebugPrint(string.format(
            "^1[vx_crafting - SERVER DEBUG]^7 ERROR: Punto de crafteo '%s' NO ENCONTRADO en Vx_crafting.CraftingPoints.",
            craftingPointId))
        TriggerNotification(src, 'Punto de crafteo inválido.', 'error')
        return
    end

    local recipeAvailableAtPoint = false
    local allowAllRecipesAtStation = false
    local allowAllCategoriesAtStation = false

    if craftingPoint.recipes and hasValue(craftingPoint.recipes, "all") then
        allowAllRecipesAtStation = true
    end
    if craftingPoint.category == "all" then
        allowAllCategoriesAtStation = true
    end

    if allowAllRecipesAtStation then
        recipeAvailableAtPoint = true
    elseif allowAllCategoriesAtStation and recipe.category then
        recipeAvailableAtPoint = true
    else
        if craftingPoint.recipes and hasValue(craftingPoint.recipes, recipeId) then
            recipeAvailableAtPoint = true
        end
        if craftingPoint.category and recipe.category == craftingPoint.category then
            recipeAvailableAtPoint = true
        end
    end

    if not recipeAvailableAtPoint then
        TriggerNotification(src, 'Esta receta no se puede craftear aquí.', 'error')
        return
    end

    local knownRecipes = GetPlayerKnownRecipes(Player.PlayerData.citizenid)
    local playerKnowsRecipe = false
    for _, knownId in ipairs(knownRecipes) do
        if knownId == recipeId then
            playerKnowsRecipe = true
            break
        end
    end

    if not playerKnowsRecipe then
        TriggerNotification(src, 'No conoces esta receta.', 'error')
        return
    end

    PlayerCraftingStatus[src] = {
        isCrafting = true,
        recipeId = recipeId,
        totalQuantity = quantity,
        currentCrafted = 0,
        cancelled = false
    }

    CreateThread(function()
        local currentInventorySystem = Vx_crafting.Config.InventorySystem
        if currentInventorySystem == "ox_inventory" and not exports['ox_inventory'] then
            DebugPrint(
                "^1[vx_crafting]^7 Error: ox_inventory no está exportado en el servidor. Usando QB-Core por defecto para este crafteo.")
            currentInventorySystem = "qbcore"
        end

        local overallCraftingCancelled = false
        local animationData = recipe.animation or {}

        local me_start = recipe.me_start or nil
        local do_start = recipe.do_start or nil
        local repeat_start = recipe.repeat_start or false
        local me_end = recipe.me_end or nil
        local do_end = recipe.do_end or nil
        local repeat_end = recipe.repeat_end or false

        local freezePlayer = recipe.freezePlayer or false

        TriggerClientEvent('vx_crafting:client:syncPlayCraftingAnimation', -1, src, animationData, freezePlayer)

        for i = 1, quantity do
            local hasAllIngredients = true
            local ingredientsToRemove = {}

            if currentInventorySystem == "ox_inventory" then
                for _, ingredient in ipairs(recipe.ingredients) do
                    local itemCount = exports['ox_inventory']:GetItemCount(src, ingredient.name)
                    if not itemCount or itemCount < ingredient.amount then
                        hasAllIngredients = false
                        TriggerNotification(src,
                            string.format('Te faltan %sx %s para craftear %s.', ingredient.amount,
                                ingredient.label or ingredient.name, recipe.name), 'error')
                        break
                    end
                    table.insert(ingredientsToRemove, { name = ingredient.name, amount = ingredient.amount, 
                        consumable = ingredient.consumable, consumable_on_init = ingredient.consumable_on_init })
                end
            else
                for _, ingredient in ipairs(recipe.ingredients) do
                    local hasItem = Player.Functions.HasItem(ingredient.name, ingredient.amount)
                    if not hasItem then
                        hasAllIngredients = false
                        TriggerNotification(src,
                            string.format('Te faltan %sx %s para craftear %s.', ingredient.amount,
                                ingredient.label or ingredient.name, recipe.name), 'error')
                        break
                    end
                    table.insert(ingredientsToRemove, { name = ingredient.name, amount = ingredient.amount })
                end
            end

            if not hasAllIngredients then
                overallCraftingCancelled = true
                TriggerNotification(src, 'Ingredientes insuficientes para continuar crafteando.', 'error')
                break
            end

            if currentInventorySystem == "ox_inventory" then
                for _, itemData in ipairs(ingredientsToRemove) do
                    if itemData.consumable and itemData.consumable_on_init then
                        exports['ox_inventory']:RemoveItem(src, itemData.name, itemData.amount)
                    end
                end
            else
                for _, itemData in ipairs(ingredientsToRemove) do
                    if itemData.consumable and itemData.consumable_on_init then
                        Player.Functions.RemoveItem(itemData.name, itemData.amount)
                    end
                end
            end

            if not PlayerCraftingStatus[src] or PlayerCraftingStatus[src].cancelled then
                overallCraftingCancelled = true
                break
            end

            TriggerClientEvent('vx_crafting:client:triggerMeDoStart', src, i, quantity, me_start, do_start, repeat_start,
                Player.PlayerData.name, recipe.name, recipe.category)

            local itemCraftedSuccessfully = lib.callback.await(
                'vx_crafting:client:startSingleItemCrafting',
                src,
                recipe.name,
                i,
                quantity,
                recipe.craftingTime or Vx_crafting.Config.ProgressBar.TimePerItem,
                animationData,
                freezePlayer
            )

            if not itemCraftedSuccessfully then
                overallCraftingCancelled = true
                break
            end

            if currentInventorySystem == "ox_inventory" then
                for _, itemData in ipairs(ingredientsToRemove) do
                    if itemData.consumable and not itemData.consumable_on_init then
                        exports['ox_inventory']:RemoveItem(src, itemData.name, itemData.amount)
                    end
                end
            else
                for _, itemData in ipairs(ingredientsToRemove) do
                    if itemData.consumable and not itemData.consumable_on_init then
                        Player.Functions.RemoveItem(itemData.name, itemData.amount)
                    end
                end
            end

            TriggerClientEvent('vx_crafting:client:triggerMeDoEnd', src, i, quantity, me_end, do_end, repeat_end,
                Player.PlayerData.name, recipe.name, recipe.category)

            if currentInventorySystem == "ox_inventory" then
                exports['ox_inventory']:AddItem(src, recipe.output.name, recipe.output.amount)
            else
                Player.Functions.AddItem(recipe.output.name, recipe.output.amount)
            end

            PlayerCraftingStatus[src].currentCrafted = i
        end

        TriggerClientEvent('vx_crafting:client:syncStopCraftingAnimation', -1, src, animationData)

        if overallCraftingCancelled then
            TriggerClientEvent('vx_crafting:client:craftingCancelled', src)
        else
            TriggerClientEvent('vx_crafting:client:craftingFinished', src)
        end
        PlayerCraftingStatus[src] = nil
    end)
end)

RegisterNetEvent('vx_crafting:server:cancelCrafting', function()
    local src = source
    if PlayerCraftingStatus[src] then
        PlayerCraftingStatus[src].cancelled = true
        DebugPrint(string.format("^2[vx_crafting]^7 Crafteo de %s cancelado por el jugador %s.",
            PlayerCraftingStatus[src].recipeId, src))
        local recipe = CraftingRecipes[PlayerCraftingStatus[src].recipeId]
        if recipe then
            TriggerClientEvent('vx_crafting:client:syncStopCraftingAnimation', -1, src, recipe.animation)
        end
    end
end)

function LearnRecipe(source, playerId, recipeId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then
        DebugPrint(string.format("^1[vx_crafting]^7 Error: Jugador no encontrado para aprender receta (ID: %s).", source))
        return false
    end

    local citizenid = Player.PlayerData.citizenid
    if not citizenid then
        DebugPrint("^1[vx_crafting]^7 Error: CitizenID no encontrado para el jugador.")
        return false
    end

    local recipe = CraftingRecipes[recipeId]
    if not recipe then
        TriggerNotification(source, 'La receta especificada no existe.', 'error')
        return false
    end

    MySQL.Async.execute(
        'INSERT IGNORE INTO player_crafting_recipes (citizenid, recipe_id) VALUES (?, ?)',
        { citizenid, recipeId },
        function(rowsAffected)
            if rowsAffected > 0 then
                TriggerNotification(source,
                    string.format('¡Has aprendido la receta para %s!', recipe.name), 'success')
                QBCore.Functions.TriggerCallback('vx_crafting:server:getKnownRecipes', function(updatedKnownRecipes)
                    TriggerClientEvent('vx_crafting:client:setKnownRecipes', source, updatedKnownRecipes)
                end, source)
                DebugPrint(string.format("^2[vx_crafting]^7 %s ha aprendido la receta: %s", citizenid, recipeId))
            else
                TriggerNotification(source, string.format('Ya conoces la receta para %s.', recipe.name),
                    'info')
            end
        end
    )
    return true
end

exports('LearnRecipe', LearnRecipe)

RegisterCommand(Vx_crafting.Config.CommandPrefix .. 'learn', function(source, args, rawCommand)
    if source == 0 then
        DebugPrint("Este comando solo puede ser usado en el juego.")
        return
    end
    local playerId = args[1]
    local recipeId = args[2]
    if not recipeId then
        TriggerNotification(source, 'Uso: /' .. Vx_crafting.Config.CommandPrefix .. 'learn' ..' [player_id] [recipe_id]', 'error')
        return
    end
    LearnRecipe(source, playerId,  recipeId)
end, true)
