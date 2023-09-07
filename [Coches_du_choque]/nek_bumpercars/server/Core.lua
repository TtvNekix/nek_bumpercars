carsSpawned, inRide = {}, true

local function rideLoop()
    CreateThread(function ()
        while true do
            if inRide then
                inRide = false
                TriggerClientEvent('setRide', -1, inRide, cfg['Time']['wait_between_rides'] * 60)
                Wait(cfg['Time']['wait_between_rides'] * 60 * 1000)
            else
                inRide = true
                TriggerClientEvent('setRide', -1, inRide, cfg['Time']['ride'] * 60)
                Wait(cfg['Time']['ride'] * 60 * 1000)
            end

            Wait(0)
        end
    end)
end

local function startVehicles()
    if #carsSpawned <= 0 then
        local Properties = {plate = "NEKIX"}
        for k, v in pairs(cfg['BumperCars']) do
            ESX.OneSync.SpawnVehicle(cfg['Model'], vec3(v.coords.x, v.coords.y, v.coords.z - 1.0), v.coords.w, Properties, function (nId)
                Wait(100)
                local Vehicle = NetworkGetEntityFromNetworkId(nId)
                local Exists = DoesEntityExist(Vehicle)
                if Exists then
                    carsSpawned[#carsSpawned+1] = {id = nId, coords = v.coords, price = v.price, rented = false, owner = false}
                end
            end)
        end

        rideLoop()
    end
end

local function getTokens(c, src)
    local xPlayer = ESX.GetPlayerFromId(src)
    local item = xPlayer.getInventoryItem('tokens').count

    if item >= c then
        xPlayer.removeInventoryItem('tokens', c)
        return true
    else
        return false
    end
end

RegisterNetEvent('setVehicleOwner', function (key, value)
    carsSpawned[key] = value
end)

AddEventHandler('onResourceStop', function ()
    if #carsSpawned <= 0 then return end
    for k, v in pairs(carsSpawned) do
        DeleteEntity(NetworkGetEntityFromNetworkId(carsSpawned[k].id))
    end
end)

RegisterNetEvent('buyTokens', function (cant, src)
    local xPlayer = ESX.GetPlayerFromId(src)
    local m, b = xPlayer.getMoney(), xPlayer.getAccount('bank').money

    if m >= cant * cfg['Tokens']['price'] then
        xPlayer.removeAccountMoney('money', cant * cfg['Tokens']['price'])
        xPlayer.addInventoryItem('tokens', cant)
        xPlayer.showNotification("You buy "..cant.. " for "..cant * cfg['Tokens']['price'].."$")
    elseif b >= cant * cfg['Tokens']['price'] then
        xPlayer.removeAccountMoney('bank', cant * cfg['Tokens']['price'])
        xPlayer.addInventoryItem('tokens', cant)
        xPlayer.showNotification("You buy "..cant.. " for "..cant * cfg['Tokens']['price'].."$")
    else
        xPlayer.showNotification("You can't afford that")
    end
end)

RegisterCommand('bumper', function (src)
    if ESX.GetPlayerFromId(src).getGroup() == 'admin' then
        startVehicles()
    end
end, false)

RegisterNetEvent('getCars', function ()
    startVehicles()
end)

ESX.RegisterServerCallback('rent', function(src, cb, quant)
   cb(getTokens(quant, src))
end)

ESX.RegisterServerCallback('bumper:getVehicles', function(src, cb)
    cb(#carsSpawned > 0 and carsSpawned or false)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        function checkVersion(error, latestVersion, headers)
			local currentVersion = cfg['Version']
            local name = "[^4nek_bumpercars^7]"
            Citizen.Wait(2000)
            
			if tonumber(currentVersion) < tonumber(latestVersion) then
				print(name .. " ^1is outdated.\nCurrent version: ^8" .. currentVersion .. "\nNewest version: ^2" .. latestVersion .. "\n^3Update^7: https://github.com/TtvNekix/nek_bumpercars")
			else
				print(name .. " is updated.")
			end
		end
	
		PerformHttpRequest("https://raw.githubusercontent.com/TtvNekix/bumperchecker/main/version", checkVersion, "GET")
    end
end)