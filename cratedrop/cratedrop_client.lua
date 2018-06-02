weaponList = {
    ["minigun"] = "PICKUP_WEAPON_MINIGUN",
    ["rpg"] = "PICKUP_WEAPON_RPG",
    ["railgun"] = "PICKUP_WEAPON_RAILGUN",
    ["sniper"] = "PICKUP_WEAPON_SNIPERRIFLE",
    ["wrench"] = "PICKUP_WEAPON_WRENCH",
}

-- feel free to expand the weaponList, I can't be bothered to add everything there, format is as follows: ["chat command argument"] = "pickup model name"
-- http://web.archive.org/web/20170909034953/http://gtaforums.com/topic/883160-dlc-weapons-pickup-hashes/

-- The next 15 lines add support for Scammer's Universal Menu, it can be removed if it causes issues
AddEventHandler("menu:setup", function()
	TriggerEvent("menu:registerModuleMenu", "Crate Drop", function(id)
		local ammoAmounts = { 10, 20, 50, 100, 500, 1000, 9999 }
		for weaponLabel, weaponName in pairs(weaponList) do
			print(weaponLabel)
			TriggerEvent("menu:addModuleSubMenu", id, weaponLabel, function(id)
				for _, ammoAmount in ipairs(ammoAmounts) do
					TriggerEvent("menu:addModuleItem", id, "Ammo: " .. ammoAmount, nil, false, function()
						TriggerEvent("Cratedrop:Execute", weaponName, ammoAmount)
					end)
				end
			end, false)
		end
	end, false)
end)

RegisterCommand("drop", function(source,args,raw)
    if weaponList[args[1]] == nil then
        if tonumber(args[2]) == nil then
            print("cratedrop failed: weapon and ammo count unrecognized")
        else
            print("cratedrop failed: weapon unrecognized, ammo count: " .. args[2])
        end
    elseif weaponList[args[1]] ~= nil and tonumber(args[2]) == nil then
        TriggerEvent("Cratedrop:Execute", args[1], 250)
        print("cratedrop succeeded: weapon: " .. args[1] .. ", ammo count unrecognized, defaulting to 250")
    elseif weaponList[args[1]] ~= nil and tonumber(args[2]) ~= nil then
        TriggerEvent("Cratedrop:Execute", args[1], tonumber(args[2]))
        print("cratedrop succeeded: weapon: " .. args[1] .. ", ammo count: " .. args[2])
    end
end, false)

RegisterNetEvent("Cratedrop:Execute")

AddEventHandler("Cratedrop:Execute", function(weapon, ammo)
    Citizen.CreateThread(function()
        local requiredModels = {"p_cargo_chute_s", "ex_prop_adv_case_sm", "cuban800", "s_m_m_pilot_02", "prop_box_wood02a_pu"}

        for i = 1, #requiredModels do
            RequestModel(GetHashKey(requiredModels[i]))
            while not HasModelLoaded(GetHashKey(requiredModels[i])) do
                Wait(0)
            end
        end

        --[[

        local requiredPtfx = {"scr_crate_drop_flare", "scr_crate_drop_smoke"}

        for i = 1, #requiredPtfx do
            RequestNamedPtfxAsset(GetHashKey(requiredPtfx[i])) -- script gets stuck if attempted to load
            while not HasNamedPtfxAssetLoaded(GetHashKey(requiredPtfx[i])) do
                Wait(100)
            end
        end

        UseParticleFxAssetNextCall("scr_crate_drop_flare")
        UseParticleFxAssetNextCall("scr_crate_drop_smoke")

        RequestAnimDict("P_cargo_chute_S")
        while not HasAnimDictLoaded("P_cargo_chute_S") do -- wasn't able to get animations working
            Wait(0)
        end

        ]]

        RequestWeaponAsset(GetHashKey("weapon_flare"))
        while not HasWeaponAssetLoaded(GetHashKey("weapon_flare")) do
            Wait(0)
        end

        local playerPed = GetPlayerPed(-1)
        local fx, fy, fz = table.unpack(GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 12.5, 0))
        local px, py, pz = table.unpack(GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -400.0, 500.0))
        local playerHeading = GetEntityHeading(playerPed)

        aircraft = CreateVehicle(GetHashKey("cuban800"), px, py, pz, playerHeading, true, true)
        SetEntityHeading(aircraft, playerHeading)
        SetVehicleDoorsLocked(aircraft, 2)
        FreezeEntityPosition(aircraft, false)
        SetEntityDynamic(aircraft, true)
        ActivatePhysics(aircraft)
        SetVehicleForwardSpeed(aircraft, 60.0)
        SetHeliBladesFullSpeed(aircraft)
        SetVehicleEngineOn(aircraft, true, true, false)
        SetVehicleEngineCanDegrade(aircraft, false)
        ControlLandingGear(aircraft, 3)
        OpenBombBayDoors(aircraft)
        SetEntityProofs(aircraft, true, false, true, false, false, false, false, false)

        pilot = CreatePedInsideVehicle(aircraft, 1, GetHashKey("s_m_m_pilot_02"), -1, true, true)
        SetBlockingOfNonTemporaryEvents(pilot, true)
        SetPedRandomComponentVariation(pilot, false)
        SetPedKeepTask(pilot, true)
        SetEntityHealth(pilot, 200)
        SetPlaneMinHeightAboveTerrain(aircraft, 50)
        TaskVehicleDriveToCoord(pilot, aircraft, fx, fy, fz + 200, 60.0, 0, GetHashKey("cuban800"), 262144, 15.0, -1.0);

        local hx, hy = table.unpack(GetEntityCoords(aircraft))
        while not IsEntityDead(pilot) and not (((fx - 5) < hx) and (hx < (fx + 5)) and ((fy - 5) < hy) and (hy < (fy + 5))) do
            Wait(0)
            hx, hy = table.unpack(GetEntityCoords(aircraft))
        end

        if IsEntityDead(pilot) == true then 
            do return end
        end

        cx, cy, cz = table.unpack(GetEntityCoords(aircraft))
        TaskVehicleDriveToCoord(pilot, aircraft, 0, 0, 500, 60.0, 0, GetHashKey("cuban800"), 262144, -1.0, -1.0)
        SetEntityAsNoLongerNeeded(pilot)
        SetEntityAsNoLongerNeeded(aircraft)

        advancedCrate = CreateObject(GetHashKey("prop_box_wood02a_pu"), cx, cy, cz - 5, true, true, true)
        SetEntityLodDist(advancedCrate, 1000)
        SetEntityInvincible(advancedCrate, false)
        SetActivateObjectPhysicsAsSoonAsItIsUnfrozen(advancedCrate, true)
        SetEntitySomething(advancedCrate, true)
        ActivatePhysics(advancedCrate)
        SetDamping(advancedCrate, 2, 0.1)
        SetEntityVelocity(advancedCrate, 0.0, 0.0, -0.2)

        cx, cy, cz = table.unpack(GetEntityCoords(aircraft))
        crateParachute = CreateObject(GetHashKey("p_cargo_chute_s"), cx, cy, cz - 5, true, true, true)
        SetEntityLodDist(crateParachute, 1000)
        SetActivateObjectPhysicsAsSoonAsItIsUnfrozen(crateParachute, true)
        SetEntityVelocity(crateParachute, 0.0, 0.0, -0.2)
        -- PlayEntityAnim(crateParachute, "P_cargo_chute_S_deploy", "P_cargo_chute_S", 1000.0, false, false, false, 0, 0) -- disabled since animations don't work
        -- ForceEntityAiAndAnimationUpdate(crateParachute) -- pointless if animations aren't working

        weaponInsideCrate = CreateAmbientPickup(GetHashKey(weaponList[weapon]), cx, cy, cz - 5, 0, ammo, GetHashKey("ex_prop_adv_case_sm"), true, true)
        SetEntityInvincible(weaponInsideCrate, true)
        SetActivateObjectPhysicsAsSoonAsItIsUnfrozen(weaponInsideCrate, true)
        ActivatePhysics(weaponInsideCrate)
        SetDisableBreaking(weaponInsideCrate, false)
        SetDamping(weaponInsideCrate, 2, 0.0245)
        SetEntityVelocity(weaponInsideCrate, 0.0, 0.0, -0.2)

        soundID = GetSoundId()
        PlaySoundFromEntity(soundID, "Crate_Beeps", weaponInsideCrate, "MP_CRATE_DROP_SOUNDS", true, 0)

        local blip = AddBlipForEntity(weaponInsideCrate)
        SetBlipSprite(blip, 351) -- or 408
        SetBlipNameFromTextFile(blip, "AMD_BLIPN")
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 2)
        SetBlipAlpha(blip, 120)

        -- crateBeacon = StartParticleFxLoopedOnEntity_2("scr_crate_drop_beacon", weaponInsideCrate, 0.0, 0.0, 0.2, 0.0, 0.0, 0.0, 1.0, false, false, false) -- no idea how to make it work, weapon_flare will do for now
        -- SetParticleFxLoopedColour(crateBeacon, 0.8, 0.18, 0.19, false)

        AttachEntityToEntity(crateParachute, weaponInsideCrate, 0, 0.0, 0.0, 0.1, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        AttachEntityToEntity(weaponInsideCrate, advancedCrate, 0, 0.0, 0.0, 0.3, 0.0, 0.0, 0.0, false, false, true, false, 2, true)

        while HasObjectBeenBroken(advancedCrate) == false do
            Wait(0)
        end

        local jx, jy, jz = table.unpack(GetEntityCoords(crateParachute))
        ShootSingleBulletBetweenCoords(jx, jy, jz, jx, jy + 0.0001, jz - 0.0001, 0, false, GetHashKey("weapon_flare"), 0, true, false, -1.0)
        DetachEntity(crateParachute, true, true)
        SetEntityCollision(crateParachute, false, true)
        -- PlayEntityAnim(crateParachute, "P_cargo_chute_S_crumple", "P_cargo_chute_S", 1000.0, false, false, false, 0, 0) -- disabled since animations don't work
        DeleteEntity(crateParachute)
        DetachEntity(weaponInsideCrate)
        SetBlipAlpha(blip, 255)

        while DoesEntityExist(weaponInsideCrate) do
            Wait(0)
        end

        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end

        StopSound(soundID)
        ReleaseSoundId(soundID)

        for i = 1, #requiredModels do
            Wait(0)
            SetModelAsNoLongerNeeded(GetHashKey(requiredModels[i]))
        end

        RemoveWeaponAsset(GetHashKey("weapon_flare"))
    end)
end)
