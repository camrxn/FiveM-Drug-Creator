local harvestCoords = nil


RegisterNetEvent('cm-drugcreator:openMenu', function()
    local input = lib.inputDialog('Drug Creator V1', {
        { type = "input", label = "Drug Name (item id)", placeholder = "opium" },
        { type = "input", label = "Label", placeholder = "Opium" },
        { type = "number", label = "Harvest Amount", placeholder = "5" },
        { type = "input", label = "Job Restriction (blank = public)", placeholder = "ballas, police" },
        { type = "number", label = "Speed Multiplier (max 1.49)", default = 1.0 },
        { type = "number", label = "Health Boost (max 100)", default = 0 },
        { type = "number", label = "Armor Boost (max 100)", default = 0 },
        { type = "number", label = "Stamina Boost (max 1.5)", default = 0.0 }
    })
    if not input then return end

    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('cm-drugcreator:saveDrug', {
        name = input[1],
        label = input[2],
        amount = input[3],
        job = input[4] ~= "" and input[4] or nil,
        speed = tonumber(input[5]) > 1.49 and 1.49 or tonumber(input[5]),
        health = math.min(input[6], 100),
        armor = math.min(input[7], 100),
        stamina = math.min(input[8], 1.5),
        coords = coords,
        harvest = { x = coords.x, y = coords.y, z = coords.z }
    })
end)









RegisterNetEvent('cm-drugcreator:openDrugListMenu', function(drugs)
    for i = 1, #drugs do
        local drug = drugs[i]
        local submenu_id = 'drug_sub_' .. drug.name

        lib.registerContext({
            id = submenu_id,
            title = ('Edit %s'):format(drug.label),
            options = {
                {
                    title = 'Edit Properties',
                    onSelect = function()
                        local edit = lib.inputDialog(('Edit: %s'):format(drug.name), {
                            {type = "number", label = "Harvest Amount", default = tonumber(drug.amount)},
                            {type = "input", label = "Job Restriction", default = drug.job or ""},
                            {type = "checkbox", label = "Update Location?", checked = false},
                            {type = "number", label = "Speed (max 1.49)", default = tonumber(drug.speed) or 1.0},
                            {type = "number", label = "Health (max 100)", default = drug.health or 0},
                            {type = "number", label = "Armor (max 100)", default = drug.armor or 0},
                            {type = "number", label = "Stamina (max 1.5)", default = drug.stamina or 0}
                        })
                        if not edit then return end

                        local coords = vector3(drug.harvest_x, drug.harvest_y, drug.harvest_z)
                        if edit[3] then coords = GetEntityCoords(PlayerPedId()) end

                        TriggerServerEvent("cm-drugcreator:updateDrug", drug.name, {
                            amount = tonumber(edit[1]),
                            job = edit[2] ~= "" and edit[2] or nil,
                            coords = coords,
                            speed = tonumber(edit[4]) > 1.49 and 1.49 or tonumber(edit[4]),
                            health = math.min(edit[5], 100),
                            armor = math.min(edit[6], 100),
                            stamina = math.min(edit[7], 1.5)
                        })
                    end
                },
                {
                    title = 'Delete Drug',
                    icon = 'trash',
                    iconColor = 'red',
                    onSelect = function()
                        TriggerServerEvent('cm-drugcreator:deleteDrug', drug.name)
                        lib.notify({ title = "Deleted", description = drug.label .. " removed", type = "error" })
                    end
                }
            }
        })
    end

    local menu = {}
    for i = 1, #drugs do
        local drug = drugs[i]
        local submenu_id = 'drug_sub_' .. drug.name

        menu[#menu + 1] = {
            title = ('%s (%s)'):format(drug.label, drug.name),
            description = ('Amount: %s | Job: %s'):format(drug.amount or "1", drug.job or "Everyone"),
            icon = "leaf",
            onSelect = function()
                lib.showContext(submenu_id)
            end
        }
    end

    lib.registerContext({
        id = 'drug_list_menu',
        title = 'Drug Editor',
        options = menu
    })

    lib.showContext('drug_list_menu')
end)



RegisterNetEvent('cm-drugcreator:useDrugEffects', function(drug)
    local ped = PlayerPedId()

    -- Animation: simulate pill usage
    local dict = "mp_suicide"
    local anim = "pill"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, 2500, 49, 0, false, false, false)

    -- Apply effects after anim
    Wait(100)

    if drug.health and tonumber(drug.health) > 0 then
        local newHealth = math.min(200, GetEntityHealth(ped) + drug.health)
        SetEntityHealth(ped, newHealth)
    end

    if drug.armor and tonumber(drug.armor) > 0 then
        local newArmor = math.min(100, GetPedArmour(ped) + drug.armor)
        SetPedArmour(ped, newArmor)
    end

    if drug.stamina and tonumber(drug.stamina) > 0 then
        RestorePlayerStamina(PlayerId(), drug.stamina)
    end

    if drug.speed and tonumber(drug.speed) > 1.0 then
        local multiplier = math.min(drug.speed, 1.49)
        SetRunSprintMultiplierForPlayer(PlayerId(), multiplier)
        SetPedMoveRateOverride(PlayerId(), multiplier)
        Wait(90000)
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    lib.notify({
        title = drug.label or 'Drug Creator',
        description = drug.notify_expire or ('The effects of ' .. (drug.label or 'the drug') .. ' have worn off.'),
        type = 'inform'
    })
        SetPedMoveRateOverride(PlayerId(), 1.0)
    end

    lib.notify({
        title = drug.label or 'Drug Creator',
        description = drug.notify_use or ('You used ' .. (drug.label or 'a drug')),
        type = 'inform'
    })
end)
