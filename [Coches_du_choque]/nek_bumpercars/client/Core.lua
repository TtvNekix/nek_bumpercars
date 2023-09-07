cars, received, inRide, tempo, inVeh = {}, false, false, 0, false

local function generateBlip(data)
    blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipDisplay(blip, 6)
    SetBlipAsShortRange(blip, true)
    SetBlipSprite(blip, data.sprite)
    SetBlipColour(blip, data.color)
    SetBlipScale(blip, data.scale)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.label)
    EndTextCommandSetBlipName(blip)
end

local function setTempo(val)
    tempo = val
    CreateThread(function ()
        while tempo > 1 do
            tempo = tempo - 1
            Wait(1000)
        end
    end)
end

local function unlockVehicles()
    CreateThread(function ()
        for k, v in pairs(cars) do
            exports['xsound']:PlayUrlPos(tostring(k), 'https://www.youtube.com/watch?v=g706-S65SVE', 1.0, v.coords.xyz)
            Wait(2000)
            if cfg['unfreezeAllVehicleInRide'] then
                local veh = NetworkGetEntityFromNetworkId(v.id)
                FreezeEntityPosition(veh, false)
                SetVehicleFuelLevel(veh, 100.0)
            else
                if v.rented then
                    local veh = NetworkGetEntityFromNetworkId(v.id)
                    FreezeEntityPosition(veh, false)
                    SetVehicleFuelLevel(veh, 100.0)
                end
            end
        end
    end)
end

local function blockVehicles()
    CreateThread(function ()
        for k, v in pairs(cars) do
            local coords = GetEntityCoords(NetworkGetEntityFromNetworkId(v.id))

            exports['xsound']:PlayUrlPos(tostring(k), 'https://www.youtube.com/watch?v=g706-S65SVE', 1.0, coords)
            Wait(2000)

            local veh = NetworkGetEntityFromNetworkId(v.id)
            FreezeEntityPosition(veh, true)

            if inVeh then
                inVeh = false
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                TaskLeaveVehicle(PlayerPedId(), veh, 64)
            end

            cars[k] = {id = v.id, coords = GetEntityCoords(NetworkGetEntityFromNetworkId(v.id)), price = v.price, rented = false, owner = false}
        end
    end)
end

AddEventHandler('playerSpawned', function()
    Wait(10000)
    TriggerServerEvent('getCars')
end)

RegisterNetEvent('setRide', function (val, time)
    inRide = val

    if inRide then
        unlockVehicles()
    else
        blockVehicles()
    end

    setTempo(time)
end)

local function DrawText3D(coords, text, size, font)
    local vector = type(coords) == "vector3" and coords or vec(coords.x, coords.y, coords.z)

    local camCoords = GetFinalRenderedCamCoord()
    local distance = #(vector - camCoords)

    if not size then
        size = 1
    end
    if not font then
        font = 0
    end

    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0 * scale, 0.55 * scale)
    SetTextFont(font)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(vector.xyz, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function Tokens()
    CreateThread(function()
        coords = cfg['Tokens']['coords']

        while true do
            local msec = 750
            if #(GetEntityCoords(PlayerPedId()) - coords) < 5 then
                msec = 0
                if inRide then
                    DrawText3D(coords, "~g~[E] ~w~Buy Tokens\nTime left to end ride: ".. tempo .." seconds")
                else
                    DrawText3D(coords, "~g~[E] ~w~Buy Tokens\nTime left to start next ride: ".. tempo .." seconds")
                end
                if IsControlJustPressed(0, 38) then
                    local input = lib.inputDialog('Buy Tokens', {{type = 'number', label = 'Number of Tokens', icon = 'hashtag'}})
                    if input and input[1] and input[1] > 0 then
                        TriggerServerEvent('buyTokens', tonumber(input[1]), GetPlayerServerId(PlayerId()))
                    else
                        ESX.ShowNotification("You need to buy 1 or more Tokens")
                    end
                end
            end

            Wait(msec)
        end
    end)
end

local function setInVehicle()
    CreateThread(function ()
        while inVeh do
            DisableControlAction(0, 75, true)
            Wait(0)
        end
    end)
end

local function Vehicles(data)
    CreateThread(function()
        cars = data
        for i=1, #data, 1 do
            local veh = NetworkGetEntityFromNetworkId(data[i].id)
            FreezeEntityPosition(veh, true)
            SetVehicleDoorsLocked(veh, 2)
            SetEntityInvincible(veh, true)
        end

        while true do
            local msec = 750
            for k, v in pairs(cars) do
                if #(GetEntityCoords(PlayerPedId()) - v.coords.xyz) < 2 then
                    msec = 0
                    if not inRide then
                        if v.rented and v.owner == GetPlayerServerId(PlayerId()) then
                            DrawText3D(vec3(v.coords.x, v.coords.y, v.coords.z + 1.0), "~r~Busy\n~g~[E] ~w~Exit Vehicle\nNext ride: "..tempo.." seconds")
                            if IsControlJustPressed(0, 38) then
                                local alert = lib.alertDialog({
                                    header = 'Token System',
                                    content = 'You are not going to receive your tokens back if you exit your vehicle',
                                    centered = true,
                                    cancel = true
                                })

                                if alert == 'confirm' then
                                    v.rented = false
                                    v.owner = false
                                    inVeh = false
                                    TriggerServerEvent('setVehicleOwner', k, v)
                                    TaskLeaveVehicle(PlayerPedId(), GetVehiclePedIsIn(PlayerPedId(), false), 64)
                                end
                            end
                        elseif v.rented then
                            DrawText3D(vec3(v.coords.x, v.coords.y, v.coords.z + 1.0), "~r~Busy")
                        else
                            DrawText3D(vec3(v.coords.x, v.coords.y, v.coords.z + 1.0), "~g~It's not busy \n~w~Price: "..v.price.."\n~g~[E] ~w~Pay for a ride \nNext ride: "..tempo.." seconds")
                            if IsControlJustPressed(0, 38) then
                                ESX.TriggerServerCallback('rent', function (cb)
                                    if cb then
                                        v.rented = true
                                        v.owner = GetPlayerServerId(PlayerId())
                                        inVeh = true
                                        setInVehicle()
                                        ESX.ShowNotification("You have paid for 1 ride on the bumper cars")
                                        local veh = NetworkGetEntityFromNetworkId(v.id)
                                        SetPedIntoVehicle(PlayerPedId(), veh, -1)
                                        TriggerServerEvent('setVehicleOwner', k, v)
                                    else
                                        ESX.ShowNotification("You cant afford that. Buy more tokens.")
                                    end
                                end, v.price)
                            end
                        end
                    end
                end
            end

            Wait(msec)
        end
    end)
end

CreateThread(function ()
    generateBlip(cfg['Blip'])

    while not received do
        ESX.TriggerServerCallback('bumper:getVehicles', function(data)
           if data ~= false then
                received = true
                Vehicles(data)
                Tokens()
            end
        end)
        Wait(1000)
    end
end)