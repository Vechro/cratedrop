weaponList = {
    ["appistol"] = "PICKUP_WEAPON_APPISTOL",
    ["stungun"] = "PICKUP_WEAPON_STUNGUN",

    ["microsmg"] = "PICKUP_WEAPON_MICROSMG",
    ["smg"] = "PICKUP_WEAPON_SMG",

    ["gusenbergsweeper"] = "PICKUP_WEAPON_GUSENBERG",
    ["mg"] = "PICKUP_WEAPON_MG",
    ["combatmg"] = "PICKUP_WEAPON_COMBATMG",

    ["pumpshotgun"] = "PICKUP_WEAPON_PUMPSHOTGUN",
    ["sawnoffshotgun"] = "PICKUP_WEAPON_SAWNOFFSHOTGUN",
    ["assaultshotgun"] = "PICKUP_WEAPON_AUTOSHOTGUN",
    ["heavyshotgun"] = "PICKUP_WEAPON_HEAVYSHOTGUN",
    ["bullpupshotgun"] = "PICKUP_WEAPON_BULLPUPSHOTGUN",
    ["sweepershotgun"] = "PICKUP_WEAPON_AUTOSHOTGUN",
    ["doublebarrelshotgun"] = "PICKUP_WEAPON_DBSHOTGUN",
    ["musket"] = "PICKUP_WEAPON_MUSKET",

    ["advancedrifle"] = "PICKUP_WEAPON_ADVANCEDRIFLE",
    ["specialcarbine"] = "PICKUP_WEAPON_SPECIALCARBINE",

    ["minigun"] = "PICKUP_WEAPON_MINIGUN",
    ["rpg"] = "PICKUP_WEAPON_RPG",
    ["railgun"] = "PICKUP_WEAPON_RAILGUN",
    ["grenadelauncher"] = "PICKUP_WEAPON_GRENADELAUNCHER",
    ["compactlauncher"] = "PICKUP_WEAPON_COMPACTLAUNCHER",
    ["hominglauncher"] = "PICKUP_WEAPON_HOMINGLAUNCHER",
    ["fireworklauncher"] = "PICKUP_WEAPON_FIREWORK",

    ["grenade"] = "PICKUP_WEAPON_GRENADE",
    ["pipebomb"] = "PICKUP_WEAPON_PIPEBOMB",
    ["proximitymine"] = "PICKUP_WEAPON_PROXMINE",
    ["stickybomb"] = "PICKUP_WEAPON_STICKYBOMB",
    ["teargas"] = "PICKUP_WEAPON_SMOKEGRENADE",
    ["molotov"] = "PICKUP_WEAPON_MOLOTOV",

    ["sniperrifle"] = "PICKUP_WEAPON_SNIPERRIFLE",
    ["heavysniper"] = "PICKUP_WEAPON_HEAVYSNIPER",
    ["marksmanrifle"] = "PICKUP_WEAPON_MARKSMANRIFLE",
}

-- feel free to expand the weaponList, I can't be bothered to add everything there, format is as follows: ["chat command argument"] = "pickup model name"
-- where I got the model names http://web.archive.org/web/20170909034953/http://gtaforums.com/topic/883160-dlc-weapons-pickup-hashes/

-- the next 16 lines add support for Scammer's Universal Menu, it can be removed if it causes any issues
AddEventHandler("menu:setup", function()
	TriggerEvent("menu:registerModuleMenu", "Crate Drop", function(id)
		local ammoAmounts = { 10, 20, 50, 100, 500, 1000, 9999 }
		for weaponLabel, weaponName in pairs(weaponList) do
			print(weaponLabel)
			TriggerEvent("menu:addModuleSubMenu", id, weaponLabel, function(id)
				for _, ammoAmount in ipairs(ammoAmounts) do
					TriggerEvent("menu:addModuleItem", id, "Ammo: " .. ammoAmount, nil, false, function()
                        TriggerEvent("Cratedrop:Execute", weaponName, ammoAmount)
                        TriggerEvent("menu:hideMenu")
					end)
				end
			end, false)
		end
	end, false)
end)

RegisterCommand("drop", function(source,args,raw)
    if weaponList[args[1]] == nil then
        if tonumber(args[2]) == nil then
            print("Cratedrop failed: weapon and ammo count unrecognized")
        else
            print("Cratedrop failed: weapon unrecognized, ammo count: " .. args[2])
        end
    elseif weaponList[args[1]] ~= nil and tonumber(args[2]) == nil then
        TriggerEvent("Cratedrop:Execute", weaponList[args[1]], 250)
        print("Cratedrop succeeded: weapon: " .. args[1] .. ", ammo count unrecognized, defaulting to 250")
    elseif weaponList[args[1]] ~= nil and tonumber(args[2]) ~= nil then
        TriggerEvent("Cratedrop:Execute", weaponList[args[1]], tonumber(args[2]))
        print("Cratedrop succeeded: weapon: " .. args[1] .. ", ammo count: " .. args[2])
    end
end, false)

RegisterNetEvent("Cratedrop:Execute")
-- make ammo stay within 0 and 9999
AddEventHandler("Cratedrop:Execute", function(weapon, ammo)
    Citizen.CreateThread(function()
        local requiredModels = {"p_cargo_chute_s", "ex_prop_adv_case_sm", "cuban800", "s_m_m_pilot_02", "prop_box_wood02a_pu", "prop_flare_01"} -- parachute, pickup case, plane, pilot, crate, flare

        for i = 1, #requiredModels do -- request the 6 models the script will be using
            RequestModel(GetHashKey(requiredModels[i]))
            while not HasModelLoaded(GetHashKey(requiredModels[i])) do
                Wait(0)
            end
        end

        --[[
        RequestAnimDict("P_cargo_chute_S")
        while not HasAnimDictLoaded("P_cargo_chute_S") do -- wasn't able to get animations working
            Wait(0)
        end
        ]]

        RequestWeaponAsset(GetHashKey("weapon_flare")) -- flare won't spawn later in the script if we don't request it right now
        while not HasWeaponAssetLoaded(GetHashKey("weapon_flare")) do
            Wait(0)
        end

        local playerPed = GetPlayerPed(-1)
        local fx, fy, fz = table.unpack(GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 12.5, 0)) -- location where to drop the crate
        local px, py, pz = table.unpack(GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -400.0, 500.0)) -- location for plane spawning
        local playerHeading = GetEntityHeading(playerPed)

        local aircraft = CreateVehicle(GetHashKey("cuban800"), px, py, pz, playerHeading, true, true) -- spawn the plane
        SetEntityHeading(aircraft, playerHeading) -- the plane spawns behind the plane facing the same direction as the player
        SetVehicleDoorsLocked(aircraft, 2) -- lock the doors because why not?
        FreezeEntityPosition(aircraft, false) -- unnecessary?
        SetEntityDynamic(aircraft, true)
        ActivatePhysics(aircraft)
        SetVehicleForwardSpeed(aircraft, 60.0)
        SetHeliBladesFullSpeed(aircraft) -- works for planes I guess
        SetVehicleEngineOn(aircraft, true, true, false)
        SetVehicleEngineCanDegrade(aircraft, false) -- a ton of natives, not sure how many of these are even necessary, but Rockstar's script used them so ¯\_(ツ)_/¯
        ControlLandingGear(aircraft, 3) -- retract the landing gear
        OpenBombBayDoors(aircraft) -- opens the hatch below the plane for added realism
        SetEntityProofs(aircraft, true, false, true, false, false, false, false, false)

        local pilot = CreatePedInsideVehicle(aircraft, 1, GetHashKey("s_m_m_pilot_02"), -1, true, true) -- put the pilot in the plane
        SetBlockingOfNonTemporaryEvents(pilot, true) -- ignore explosions and other shocking events
        SetPedRandomComponentVariation(pilot, false)
        SetPedKeepTask(pilot, true)
        SetEntityHealth(pilot, 200) -- prob unnecessary
        SetPlaneMinHeightAboveTerrain(aircraft, 50) -- Rockstar uses it, the plane shouldn't dip below the defined altitude
        TaskVehicleDriveToCoord(pilot, aircraft, fx, fy, fz + 200, 60.0, 0, GetHashKey("cuban800"), 262144, 15.0, -1.0); -- to the dropsite, could be replaced with sequencing

        local hx, hy = table.unpack(GetEntityCoords(aircraft))
        while not IsEntityDead(pilot) and not (((fx - 5) < hx) and (hx < (fx + 5)) and ((fy - 5) < hy) and (hy < (fy + 5))) do -- wait for when the plane reaches the coords ± 5
            Wait(0)
            hx, hy = table.unpack(GetEntityCoords(aircraft)) -- update plane coords for the loop
            if IsEntityDead(pilot) then -- I think this will end the script if the pilot dies
                do return end
            end
        end

        if IsEntityDead(pilot) == true then -- I think this will end the script if the pilot dies, no idea how to return works
            do return end
        end

        local cx, cy, cz = table.unpack(GetEntityCoords(aircraft))
        TaskVehicleDriveToCoord(pilot, aircraft, 0, 0, 500, 60.0, 0, GetHashKey("cuban800"), 262144, -1.0, -1.0) -- disposing of the plane like Rockstar does, send it to 0; 0 coords with -1.0 stop range, so the plane won't be able to achieve its task
        SetEntityAsNoLongerNeeded(pilot) -- despawn when out of sight
        SetEntityAsNoLongerNeeded(aircraft)

        local advancedCrate = CreateObject(GetHashKey("prop_box_wood02a_pu"), cx, cy, cz - 5, true, true, true) -- a breakable crate to be spawned directly under the plane, probably could be spawned closer to the plane
        SetEntityLodDist(advancedCrate, 1000) -- so we can see it from the distance
        SetEntityInvincible(advancedCrate, false) -- unnecessary?
        SetActivateObjectPhysicsAsSoonAsItIsUnfrozen(advancedCrate, true)
        SetEntitySomething(advancedCrate, true) -- what is this even? prob unnecessary
        ActivatePhysics(advancedCrate)
        SetDamping(advancedCrate, 2, 0.1) -- no idea but Rockstar uses it
        SetEntityVelocity(advancedCrate, 0.0, 0.0, -0.2) -- I think this makes the crate drop down, not sure if it's needed as many times in the script as I'm using

        local cx, cy, cz = table.unpack(GetEntityCoords(aircraft))
        crateParachute = CreateObject(GetHashKey("p_cargo_chute_s"), cx, cy, cz - 5, true, true, true) -- create the parachute for the crate
        SetEntityLodDist(crateParachute, 1000) -- so we can see it from the distance
        SetActivateObjectPhysicsAsSoonAsItIsUnfrozen(crateParachute, true) -- is this necessary?
        SetEntityVelocity(crateParachute, 0.0, 0.0, -0.2) -- I think this makes the crate drop down, not sure if it's needed as many times in the script as I'm using
        -- PlayEntityAnim(crateParachute, "P_cargo_chute_S_deploy", "P_cargo_chute_S", 1000.0, false, false, false, 0, 0) -- disabled since animations don't work
        -- ForceEntityAiAndAnimationUpdate(crateParachute) -- pointless if animations aren't working

        local weaponInsideCrate = CreateAmbientPickup(GetHashKey(weapon), cx, cy, cz - 5, 0, ammo, GetHashKey("ex_prop_adv_case_sm"), true, true) -- we make the pickup, location doesn't matter too much, we're attaching it later
        SetEntityInvincible(weaponInsideCrate, true) -- could be necessary
        SetActivateObjectPhysicsAsSoonAsItIsUnfrozen(weaponInsideCrate, true)
        ActivatePhysics(weaponInsideCrate)
        SetDisableBreaking(weaponInsideCrate, false) -- prob unnecessary
        SetDamping(weaponInsideCrate, 2, 0.0245) -- no idea but Rockstar uses it
        SetEntityVelocity(weaponInsideCrate, 0.0, 0.0, -0.2) -- I think this makes the crate drop down, not sure if it's needed as many times in the script as I'm using

        local soundID = GetSoundId() -- we need a sound ID for calling the native below, otherwise we won't be able to stop the sound later
        PlaySoundFromEntity(soundID, "Crate_Beeps", weaponInsideCrate, "MP_CRATE_DROP_SOUNDS", true, 0) -- crate beep sound emitted from the pickup

        local blip = AddBlipForEntity(weaponInsideCrate) -- Rockstar did the blip exactly like this
        SetBlipSprite(blip, 351) -- 408 also works, supposedly the same blip but bigger and more detailed?
        SetBlipNameFromTextFile(blip, "AMD_BLIPN")
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 2)
        SetBlipAlpha(blip, 120) -- blip will be semi-transparent

        -- local crateBeacon = StartParticleFxLoopedOnEntity_2("scr_crate_drop_beacon", weaponInsideCrate, 0.0, 0.0, 0.2, 0.0, 0.0, 0.0, 1065353216, 0, 0, 0, 1065353216, 1065353216, 1065353216, 0)--1.0, false, false, false) -- no idea how to make it work, weapon_flare will do for now
        -- SetParticleFxLoopedColour(crateBeacon, 0.8, 0.18, 0.19, false) -- reliant on the line above, Rockstar did it like this

        AttachEntityToEntity(crateParachute, weaponInsideCrate, 0, 0.0, 0.0, 0.1, 0.0, 0.0, 0.0, false, false, false, false, 2, true) -- attach the crate to the pickup
        AttachEntityToEntity(weaponInsideCrate, advancedCrate, 0, 0.0, 0.0, 0.3, 0.0, 0.0, 0.0, false, false, true, false, 2, true) -- attach the pickup to the crate, doing it in any other order makes the crate drop spazz out

        while HasObjectBeenBroken(advancedCrate) == false do -- wait till the crate gets broken (probably on impact), then continue with the script
            Wait(0)
        end

        local jx, jy, jz = table.unpack(GetEntityCoords(crateParachute)) -- we get the parachute coords so we know where to drop the flare
        ShootSingleBulletBetweenCoords(jx, jy, jz, jx, jy + 0.0001, jz - 0.0001, 0, false, GetHashKey("weapon_flare"), 0, true, false, -1.0) -- flare needs to be dropped with coords like that, otherwise it remains static and won't remove itself later
        DetachEntity(crateParachute, true, true) -- detach parachute
        SetEntityCollision(crateParachute, false, true) -- remove collision, pointless right now but would be cool if animations would work and you'll be able to walk through the parachute while it's disappearing
        -- PlayEntityAnim(crateParachute, "P_cargo_chute_S_crumple", "P_cargo_chute_S", 1000.0, false, false, false, 0, 0) -- disabled since animations don't work
        DeleteEntity(crateParachute)
        DetachEntity(weaponInsideCrate) -- will despawn on its own
        SetBlipAlpha(blip, 255) -- make the blip fully visible

        while DoesEntityExist(weaponInsideCrate) do -- wait till the pickup gets picked up, then the script can continue
            Wait(0)
        end

        while DoesObjectOfTypeExistAtCoords(jx, jy, jz, 10.0, GetHashKey("w_am_flare"), true) do
            Wait(0)
            local prop = GetClosestObjectOfType(jx, jy, jz, 10.0, GetHashKey("w_am_flare"), false, false, false)
            RemoveParticleFxFromEntity(prop)
            SetEntityAsMissionEntity(prop, true, true)
            DeleteObject(prop)
        end

        if DoesBlipExist(blip) then -- remove the blip, should get removed when the pickup gets picked up anyway, but isn't a bad idea to make sure of it
            RemoveBlip(blip)
        end

        StopSound(soundID) -- stop the crate beeping sound
        ReleaseSoundId(soundID) -- won't need this sound ID any longer

        for i = 1, #requiredModels do -- tell the engine it's okay to unload the 5 models as we won't need them anymore
            Wait(0)
            SetModelAsNoLongerNeeded(GetHashKey(requiredModels[i]))
        end

        RemoveWeaponAsset(GetHashKey("weapon_flare")) -- unload the flare
    end)
end)