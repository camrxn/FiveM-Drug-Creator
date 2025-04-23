local Zones = {}
local harvesting = false
local currentHarvestZone = nil

math.randomseed(GetGameTimer())
RegisterNetEvent('cm-drugcreator:syncZones', function(data)
    Zones = data or {}
end)

CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local playerData = ESX.GetPlayerData()

        for name, zone in pairs(Zones) do
            local dist = #(coords - vector3(zone.x, zone.y, zone.z))

            local canSee = not zone.job or (playerData.job and playerData.job.name == zone.job)

            if canSee and dist < 25.0 then
                DrawMarker(1, zone.x, zone.y, zone.z - 1.0, 0.0, 0.0, 0.0, 0, 0, 0,
                           1.5, 1.5, 1.0, 0, 0, 255, 132, false, true, 2, false, nil, nil, false)
            end

            if canSee and dist < 1.5 then
                if not harvesting then
                    ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ to collect " .. zone.label)
                    if IsControlJustReleased(0, 38) then
                        harvesting = true
                        currentHarvestZone = name
                        TriggerEvent("cm-drugcreator:startHarvest", name)
                    end
                else
                    if currentHarvestZone == name then
                        ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ again to stop collecting " .. zone.label)
                        if IsControlJustReleased(0, 38) then
                            harvesting = false
                            lib.notify({ title = "Harvesting", description = "Stopped harvesting.", type = "info" })
                        end
                    end
                end
            end
        end
    end
end)

RegisterNetEvent("cm-drugcreator:startHarvest", function(name)
    local zone = Zones[name]
    if not zone then harvesting = false return end

    CreateThread(function()
        while harvesting do
            local cancelled = lib.progressCircle({
                duration = 5000,
                label = "Harvesting " .. zone.label,
                position = 'bottom',
                useWhileDead = false,
                canCancel = false,
                disable = {
                    move = true,
                    car = true,
                    combat = true
                },
                anim = {
    dict = "random@mugging1",
    clip = "pickup_low"
}
            })

            TriggerServerEvent("cm-drugcreator:harvestDrug", name)

            Wait(150)

            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local dist = #(pos - vector3(zone.x, zone.y, zone.z))
            if dist > 2.0 then
                harvesting = false
                lib.notify({ title = "Harvesting", description = "You walked too far away.", type = "warning" })
                break
            end
        end
    end)
end)