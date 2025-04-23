local function sendZonesToAllClients()
    exports.oxmysql:query('SELECT * FROM drug_items', {}, function(results)
        local zones = {}
        for _, drug in pairs(results) do
            zones[drug.name] = {
                label = drug.label,
                job = drug.job,
                amount = drug.amount,
                x = drug.harvest_x,
                y = drug.harvest_y,
                z = drug.harvest_z
            }
        end
        TriggerClientEvent('cm-drugcreator:syncZones', -1, zones)
    end)
end

ESX.RegisterCommand('drugcreator', 'admin', function(xPlayer, args, showError)
    TriggerClientEvent('cm-drugcreator:openMenu', xPlayer.source)
end, true)

ESX.RegisterCommand('drugs', 'admin', function(xPlayer, args, showError)
    exports.oxmysql:query('SELECT * FROM drug_items', {}, function(results)
        TriggerClientEvent('cm-drugcreator:openDrugListMenu', xPlayer.source, results)
    end)
end, true)

RegisterNetEvent('cm-drugcreator:saveDrug', function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    exports.oxmysql:insert(
        'INSERT INTO drug_items (name, label, amount, x, y, z, harvest_x, harvest_y, harvest_z, job, speed, health, armor, stamina) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            data.name, data.label, data.amount,
            data.coords.x, data.coords.y, data.coords.z,
            data.harvest.x, data.harvest.y, data.harvest.z,
            data.job, data.speed, data.health, data.armor, data.stamina
        },
        function(id)
            sendZonesToAllClients()
            TriggerClientEvent('esx:showNotification', src, "Drug" .. data.label .. "created and saved.")
        end
    )
end)

RegisterNetEvent('cm-drugcreator:deleteDrug', function(name)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    exports.oxmysql:update('DELETE FROM drug_items WHERE name = ?', { name }, function(rowsChanged)
        if rowsChanged > 0 then
            sendZonesToAllClients()
            TriggerClientEvent('esx:showNotification', src, "Drug" .. name .. "deleted.")
        end
    end)
end)

RegisterNetEvent('cm-drugcreator:harvestDrug', function(name)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    exports.oxmysql:query('SELECT * FROM drug_items WHERE name = ?', { name }, function(result)
        if result and result[1] then
            local drug = result[1]
            local amount = tonumber(drug.amount) or 1
            xPlayer.addInventoryItem(name, amount)
            TriggerClientEvent('esx:showNotification', src, ('You collected %s x%s'):format(drug.label, amount))
        end
    end)
end)

AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        Wait(2000)
        sendZonesToAllClients()
    end
end)
RegisterNetEvent('cm-drugcreator:updateDrug', function(name, data)
    exports.oxmysql:update(
        'UPDATE drug_items SET amount = ?, job = ?, harvest_x = ?, harvest_y = ?, harvest_z = ?, speed = ?, health = ?, armor = ?, stamina = ? WHERE name = ?',
        {data.amount, data.job, data.coords.x, data.coords.y, data.coords.z, data.speed, data.health, data.armor, data.stamina, name},
        function(rows)
            sendZonesToAllClients()
        end
    )
end)


-- Register all drugs as usable items and forward to client
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        exports.oxmysql:query('SELECT name FROM drug_items', {}, function(results)
            for _, row in pairs(results) do
                ESX.RegisterUsableItem(row.name, function(source)
                    TriggerEvent('cm-drugcreator:useDrugServer', source, row.name)
                end)
            end
        end)
    end
end)

RegisterNetEvent('cm-drugcreator:useDrugServer', function(source, drugName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    exports.oxmysql:query('SELECT * FROM drug_items WHERE name = ?', { drugName }, function(result)
        if result and result[1] then
            xPlayer.removeInventoryItem(drugName, 1)
            TriggerClientEvent('cm-drugcreator:useDrugEffects', source, result[1])
        end
    end)
end)
