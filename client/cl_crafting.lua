local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local IsUIOpen = false
local CurrentCraftingPoint = nil
local CraftingRecipes = {}
local spawnedObjects = {}

local currentCraftingProgress = nil
local isCraftingActive = false
local activeOxTextUIId = false -- Variable para almacenar la referencia a ox_lib textUI
local lastTextContent = ""   -- Para evitar actualizaciones innecesarias de ox_lib textUI

local function DebugPrint(...)
    if Vx_crafting.Config.DebugMode then
        print(...)
    end
end

local function GetKeybindFromControl(controlId)
    local success, result = pcall(function()
        return lib.input.getControlName(controlId)
    end)

    if success and result and result ~= "" then
        return result
    else
        local keyMap = {
            [73] = 'X',
        }
        return keyMap[controlId] or tostring(controlId)
    end
end

local function hasValue(tbl, val)
    for _, valueInTbl in ipairs(tbl) do
        if valueInTbl == val then
            return true
        end
    end
    return false
end

local function TriggerNotification(message, type)
    if Vx_crafting.Config.NotificationSystem == "ox_lib" then
        lib.notify({
            description = message,
            type = type,
            duration = Vx_crafting.Config.NotificationDuration,
        })
    else
        QBCore.Functions.Notify(message, type)
    end
end

local function LoadCraftingRecipes()
    local recipesJson = LoadResourceFile(GetCurrentResourceName(), "shared/crafting_recipes.json")
    if recipesJson then
        CraftingRecipes = json.decode(recipesJson)
        if not CraftingRecipes then
            DebugPrint("^1[vx_crafting]^7 Error al decodificar crafting_recipes.json")
            CraftingRecipes = {}
        end
    else
        DebugPrint("^1[vx_crafting]^7 crafting_recipes.json no encontrado o está vacío.")
        CraftingRecipes = {}
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LoadCraftingRecipes()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

local function OpenCraftingUI(craftingPointId)
    if IsUIOpen then return end

    if isCraftingActive then
        TriggerNotification('Ya estás crafteando algo. Espera a que termine o cancela.', 'error')
        return
    end

    DebugPrint(string.format("^5[vx_crafting - CLIENT DEBUG]^7 Abriendo UI para el punto de crafteo: %s", craftingPointId))

    local craftingPoint = Vx_crafting.CraftingPoints[craftingPointId]
    if not craftingPoint then
        DebugPrint(string.format(
        "^1[vx_crafting]^7 Punto de crafteo '%s' no encontrado en la configuración del cliente.", craftingPointId))
        return
    end

    CurrentCraftingPoint = craftingPointId
    DebugPrint(string.format("^2[vx_crafting - CLIENT DEBUG]^7 Punto de crafteo encontrado: %s",
        json.encode(CurrentCraftingPoint)))
    IsUIOpen = true
    SetNuiFocus(true, true)

    QBCore.Functions.TriggerCallback('vx_crafting:server:getKnownRecipes', function(playerKnownRecipes)
        playerKnownRecipes = playerKnownRecipes or {}
        DebugPrint(string.format("^2[vx_crafting - CLIENT DEBUG]^7 Recetas conocidas (recibidas del servidor): %s",
            json.encode(playerKnownRecipes)))

        local recipesForStation = {}
        local allowAllRecipesAtStation = false
        local allowAllCategoriesAtStation = false

        if craftingPoint.recipes and hasValue(craftingPoint.recipes, "all") then
            allowAllRecipesAtStation = true
        end
        if craftingPoint.category == "all" then
            allowAllCategoriesAtStation = true
        end

        for recipeId, recipeData in pairs(CraftingRecipes) do
            local canCraftHere = false

            if allowAllRecipesAtStation then
                canCraftHere = true
            elseif allowAllCategoriesAtStation and recipeData.category then
                canCraftHere = true
            else
                if craftingPoint.recipes and hasValue(craftingPoint.recipes, recipeId) then
                    canCraftHere = true
                end
                if craftingPoint.category and recipeData.category == craftingPoint.category then
                    canCraftHere = true
                end
            end

            if canCraftHere then
                recipesForStation[recipeId] = recipeData
            end
        end

        local knownRecipesInStation = {}
        for id, recipe in pairs(recipesForStation) do
            if hasValue(playerKnownRecipes, id) then
                knownRecipesInStation[id] = recipe
            end
        end

        SendNuiMessage(json.encode({
            type = 'openCraftingUI',
            recipes = knownRecipesInStation,
            knownRecipes = playerKnownRecipes
        }))
    end)
end

local function CloseCraftingUI()
    if not IsUIOpen then return end
    IsUIOpen = false
    SetNuiFocus(false, false)
    SendNuiMessage(json.encode({ type = 'closeCraftingUI' }))
end

RegisterNuiCallback('closeUI', function(data, cb)
    CloseCraftingUI()
    cb(true)
end)

RegisterNuiCallback('craftItem', function(data, cb)
    local recipeId = data.recipeId
    local quantity = data.quantity or 1
    if not recipeId then
        cb({ success = false, message = "Recipe ID no proporcionado." })
        return
    end
    DebugPrint(string.format("^2[vx_crafting - CLIENT DEBUG]^7 Punto de crafteo encontrado: %s",
        json.encode(CurrentCraftingPoint)))
    if not CurrentCraftingPoint then
        cb({ success = false, message = "No estás en un punto de crafteo válido." })
        return
    end
    local recipe = CraftingRecipes[recipeId]
    if not recipe then
        cb({ success = false, message = "Receta no encontrada." })
        return
    end

    if isCraftingActive then
        TriggerNotification('Ya estás crafteando algo. Espera a que termine o cancela.', 'error')
        cb({ success = false, message = "Ya estás crafteando algo." })
        return
    end

    isCraftingActive = true
    TriggerServerEvent('vx_crafting:server:craftItem', recipeId, CurrentCraftingPoint, quantity)
    cb({ success = true, message = "Solicitud de crafteo enviada al servidor." })
end)

RegisterNuiCallback('cancelCrafting', function(data, cb)
    if currentCraftingProgress then
        lib.cancelProgressBar()
        currentCraftingProgress = nil
    end
    if activeOxTextUIId then
        lib.hideTextUI(activeOxTextUIId)
        activeOxTextUIId = nil
        lastTextContent = ""
    end
    TriggerServerEvent('vx_crafting:server:cancelCrafting')
    cb(true)
end)

lib.callback.register('vx_crafting:client:startSingleItemCrafting',
    function(recipeName, currentItemIndex, totalItems, timePerItem, animationData, freezePlayer)
        SetNuiFocus(false, false)

        local ped = PlayerPedId()

        if freezePlayer then
            FreezeEntityPosition(ped, true)
        end

        if animationData and animationData.dict and animationData.anim then
            RequestAnimDict(animationData.dict)
            while not HasAnimDictLoaded(animationData.dict) do
                Wait(0)
            end
            TaskPlayAnim(ped, animationData.dict, animationData.anim, 8.0, -8.0, -1, 49, 0, false, false, false)
        end

        if activeOxTextUIId then
            lib.hideTextUI(activeOxTextUIId)
            activeOxTextUIId = nil
            lastTextContent = ""
        end

        local currentTextUI = lib.showTextUI(
        string.format('Pulsa %s para cancelar - Ítems restantes: %d/%d',
            GetKeybindFromControl(Vx_crafting.Config.ProgressBar.CancelKey), currentItemIndex, totalItems), {
            position = 'bottom-center',
            style = {
                color = 'white',
                borderRadius = '10px',
            }
        })

        local progressBarOptions = {
            duration = timePerItem,
            label = string.format('Crafteando %s', recipeName),
            canCancel = true,
            control = Vx_crafting.Config.ProgressBar.CancelKey,
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false,
                sprint = true,
            },
        }

        local completedSuccessfully = lib.progressBar(progressBarOptions)

        if animationData and animationData.dict and animationData.anim then
            StopAnimTask(ped, animationData.dict, animationData.anim, 1.0)
        end
        FreezeEntityPosition(ped, false)

        currentCraftingProgress = nil

        return completedSuccessfully
    end)

RegisterNetEvent('vx_crafting:client:syncPlayCraftingAnimation', function(targetPlayerId, animationData, freezePlayer)
    local localPlayerId = PlayerId()
    if targetPlayerId == localPlayerId then
        return
    end

    local targetPed = GetPlayerPed(targetPlayerId)
    if DoesEntityExist(targetPed) then
        if freezePlayer then
            FreezeEntityPosition(targetPed, true)
        end

        if animationData and animationData.dict and animationData.anim then
            RequestAnimDict(animationData.dict)
            while not HasAnimDictLoaded(animationData.dict) do
                Wait(0)
            end
            TaskPlayAnim(targetPed, animationData.dict, animationData.anim, 8.0, -8.0, -1, 49, 0, false, false, false)
        end
    end
end)

RegisterNetEvent('vx_crafting:client:syncStopCraftingAnimation', function(targetPlayerId, animationData)
    local localPlayerId = PlayerId()
    if targetPlayerId == localPlayerId then
        return
    end

    local targetPed = GetPlayerPed(targetPlayerId)
    if DoesEntityExist(targetPed) then
        if animationData and animationData.dict and animationData.anim then
            StopAnimTask(targetPed, animationData.dict, animationData.anim, 1.0)
        end
        FreezeEntityPosition(targetPed, false)
    end
end)

local function ReplacePlaceholders(text, currentItemIndex, totalItems, recipeName, category, playerName)
    text = string.gsub(text, "%%quantity%%", tostring(totalItems))
    text = string.gsub(text, "%%name%%", tostring(recipeName))
    text = string.gsub(text, "%%current_item%%", tostring(currentItemIndex))
    text = string.gsub(text, "%%total_items%%", tostring(totalItems))
    text = string.gsub(text, "%%player_name%%", tostring(playerName))
    return text
end

RegisterNetEvent('vx_crafting:client:triggerMeDoStart',
    function(currentItemIndex, totalItems, me_start, do_start, repeat_start, playerName, recipeName, category)
        if me_start or do_start then
            if currentItemIndex == 1 or (currentItemIndex > 1 and repeat_start) then
                Wait(300)
                local processed_me = ReplacePlaceholders(me_start or "", currentItemIndex, totalItems, recipeName,
                    category, playerName)
                local processed_do = ReplacePlaceholders(do_start or "", currentItemIndex, totalItems, recipeName,
                    category, playerName)

                if me_start then
                    ExecuteCommand('me ' .. processed_me)
                    Wait(100)
                end
                if do_start then
                    ExecuteCommand('do ' .. processed_do)
                    Wait(100)
                end
            end
        end
    end)

RegisterNetEvent('vx_crafting:client:triggerMeDoEnd',
    function(currentItemIndex, totalItems, me_end, do_end, repeat_end, playerName, recipeName, category)
        if me_end or do_end then
            if repeat_end or (currentItemIndex == totalItems) then
                Wait(200)
                local processed_me = ReplacePlaceholders(me_end or "", currentItemIndex, totalItems, recipeName, category,
                    playerName)
                local processed_do = ReplacePlaceholders(do_end or "", currentItemIndex, totalItems, recipeName, category,
                    playerName)

                if me_end then
                    ExecuteCommand('me ' .. processed_me)
                    Wait(100)
                end
                if do_end then
                    ExecuteCommand('do ' .. processed_do)
                    Wait(100)
                end
            end
        end
    end)

RegisterNetEvent('vx_crafting:client:craftingFinished', function()
    isCraftingActive = false
    if activeOxTextUIId then
        lib.hideTextUI(activeOxTextUIId)
        activeOxTextUIId = nil
        lastTextContent = ""
    end
    TriggerNotification('Crafteo completado.', 'success')
end)

RegisterNetEvent('vx_crafting:client:craftingCancelled', function()
    isCraftingActive = false
    if activeOxTextUIId then
        lib.hideTextUI(activeOxTextUIId)
        activeOxTextUIId = nil
        lastTextContent = ""
    end
    TriggerNotification('Crafteo cancelado.', 'info')
end)

RegisterCommand(Vx_crafting.Config.CommandPrefix .. "ui", function(source, args, rawCommand)
    local craftingPointId = args[1]
    if craftingPointId then
        OpenCraftingUI(craftingPointId)
    else
        OpenCraftingUI("main_crafting_station")
    end
end, false)

local function DrawText3D(coords, text)
    local x, y, z = coords.x, coords.y, coords.z
    local camCoords = GetGameplayCamCoords()
    local dist = #(camCoords - coords)
    if dist > 30.0 then return end
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scaleX = scale * fov * 0.5
    local scaleY = scale * fov * 0.5
    SetTextScale(scaleX, scaleY)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z + 0.5, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

local function LoadAndCreateObject(point)
    local modelHash = GetHashKey(point.object.model)

    if not IsModelInCdimage(modelHash) then
        DebugPrint(string.format(
        "^1[vx_crafting]^7 Error: El modelo '%s' (hash: %s) NO existe en los archivos del juego para el punto de crafteo %s. Verifica el nombre del modelo o el hash.",
            point.object.model, modelHash, point.id))
        return nil
    end
    if not IsModelValid(modelHash) then
        DebugPrint(string.format(
        "^1[vx_crafting]^7 Error: El modelo '%s' (hash: %s) NO es un modelo válido para el punto de crafteo %s. Podría estar corrupto o no ser un prop.",
            point.object.model, modelHash, point.id))
        return nil
    end

    RequestModel(modelHash)
    local timeout = 10000
    local startTime = GetGameTimer()
    while not HasModelLoaded(modelHash) do
        Wait(100)
        if (GetGameTimer() - startTime) > timeout then
            DebugPrint(string.format(
            "^1[vx_crafting]^7 Error: El modelo '%s' (hash: %s) no se cargó a tiempo para el punto de crafteo %s. Asegúrate de que esté correctamente streameado y no sea demasiado grande.",
                point.object.model, modelHash, point.id))
            return nil
        end
    end

    local obj = CreateObject(modelHash, point.coords.x, point.coords.y, point.coords.z, false, false, false)
    FreezeEntityPosition(obj, point.object.freeze)
    SetEntityHeading(obj, point.heading)
    SetEntityAsMissionEntity(obj, true, true)

    if point.object.placeOnGround then
        local success, groundZ = GetGroundZFor_3dCoord(point.coords.x, point.coords.y, point.coords.z + 1.0, false)
        if success then
            local minDim, maxDim = GetModelDimensions(modelHash)
            local objectHeight = maxDim.z - minDim.z
            local finalZ = groundZ + (point.object.zOffset or 0.0)

            SetEntityCoords(obj, point.coords.x, point.coords.y, finalZ, false, false, false, false)
        else
            DebugPrint(string.format(
            "^3[vx_crafting - WARNING]^7 No se pudo encontrar el suelo para el objeto %s (hash: %s) en %s. Se usará la coordenada Z original.",
                point.object.model, modelHash, json.encode(point.coords)))
        end
    end

    SetEntityVisible(obj, true, false)

    DebugPrint(string.format("^2[vx_crafting - CLIENT DEBUG]^7 Objeto creado en el punto de crafteo %s: %s (hash: %s)",
        point.id, point.object.model, modelHash))
    return obj
end

CreateThread(function()
    while not QBCore.Functions.GetPlayerData() do
        Wait(100)
    end
    for id, point in pairs(Vx_crafting.CraftingPoints) do
        point.id = id
        if point.blip then
            local blip = AddBlipForCoord(point.coords.x, point.coords.y, point.coords.z)
            SetBlipSprite(blip, point.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, point.blip.scale)
            SetBlipColour(blip, point.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(point.blip.name)
            EndTextCommandSetBlipName(blip)
        end
        if point.object then
            local obj = LoadAndCreateObject(point)
            if obj then
                table.insert(spawnedObjects, obj)
            end
        end
    end
end)

CreateThread(function()
    local closestPointInRangeId = nil
    local textToShow = "~g~[E]~w~ para Craftear"

    while true do
        local sleepTime = 500
        local playerCoords = GetEntityCoords(PlayerPedId())
        local foundClosestPointThisTick = nil
        local minDist = math.huge

        for id, point in pairs(Vx_crafting.CraftingPoints) do
            local dist = #(playerCoords - point.coords)
            if point.marker and dist < point.marker.drawDistance then
                DrawMarker(point.marker.type, point.marker.coords.x, point.marker.coords.y, point.marker.coords.z, 0.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, point.marker.scale.x, point.marker.scale.y, point.marker.scale.z,
                    point.marker.color[1], point.marker.color[2], point.marker.color[3], point.marker.color[4], false,
                    true, 2, false, nil, nil, false)
                sleepTime = 0
            end

            if dist < point.radius then
                sleepTime = 0
                if dist < minDist then
                    minDist = dist
                    foundClosestPointThisTick = id
                end
            end
        end

        if Vx_crafting.Config.UseDrawText3D then
            if activeOxTextUIId then
                lib.hideTextUI()
                activeOxTextUIId = nil
                lastTextContent = ""
            end
            if foundClosestPointThisTick then
                DrawText3D(Vx_crafting.CraftingPoints[foundClosestPointThisTick].coords, textToShow)
            end
        else
            if foundClosestPointThisTick then
                if not activeOxTextUIId and not isCraftingActive then
                    lib.showTextUI('[E] - Craftear', {
                        position = "left-center",
                        icon = 'hand',
                        style = {
                            borderRadius = "10px",
                            backgroundColor = '#48BB78',
                            color = 'white'
                        }
                    })
                    activeOxTextUIId = true
                end
            else
                if activeOxTextUIId then
                    lib.hideTextUI()
                    activeOxTextUIId = false
                end
            end
        end

        if foundClosestPointThisTick and IsControlJustReleased(0, 38) and not IsUIOpen then
            if activeOxTextUIId then
                lib.hideTextUI()
                activeOxTextUIId = false
            end
            OpenCraftingUI(foundClosestPointThisTick)
        end

        Wait(sleepTime)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, obj in ipairs(spawnedObjects) do
            if DoesEntityExist(obj) then
                DeleteObject(obj)
            end
        end
        if activeOxTextUIId then
            lib.hideTextUI(activeOxTextUIId)
            activeOxTextUIId = nil
            lastTextContent = ""
        end
    end
end)
