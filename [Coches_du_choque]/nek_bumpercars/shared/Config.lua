cfg = {}
cfg['Version'] = 1.0 -- DON'T TOUCH THIS

cfg['Blip'] = {
    coords = vec3(-1695.46, -1163.15, 13.00),
    sprite = 647,
    color = 5,
    label = "Bumper Cars",
    scale = 0.7
}

cfg['Time'] = { -- In minutes
    ride = 1,
    wait_between_rides = 1
}

cfg['Tokens'] = {
    price = 10,
    coords = vec3(-1721.11, -1120.60, 14.11)
}

cfg['Model'] = 'superkart' -- Use your own if you want
cfg['unfreezeAllVehicleInRide'] = true -- Unfreeze all bumper cars to get a better experience like real life
cfg['BumperCars'] = {
    [1] = {
        coords = vec4(-1760.11, -1155.91, 13.00, 140.33),
        price = 2
    },
    [2] = {
        coords = vec4(-1768.75, -1165.72, 13.00, 138.53),
        price = 2
    },
}